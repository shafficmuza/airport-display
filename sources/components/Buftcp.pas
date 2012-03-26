unit Buftcp; {Buffered TCP/IP Client and Server Components}
{--------    ©Copr 96-07 Omar Reis --v1.0  24/10/96  --------}
// Historico:
//  v 1.1 9/9/97 adicionei evento OnReadyToSend em cascata
//  ago07: Om: adicionei mais info na msg Tcpcli Queue Full


interface
uses
  SysUtils, WinTypes, WinProcs, Messages,
  Classes,
  ObjQueu, {TObjQueue}
  Winsock,
  SockCmp; {TTCPCli}

const
  bBuftcpDesconectaOnQueueFull:boolean=false; // ago07: Om: se estourar a queue do TBufTcpcli, desconecta a coisa

type
  TPacTCP=Class(TObject)
  private
    L:integer;
    P:PChar;
  public
    Constructor Create(aP:PChar;aL:integer);
    Destructor Destroy; override;
    Function   Detach(var aL:integer):Pchar;
    Procedure  Realoc(aP:PChar;aL:integer);
    Property   Size:integer read L;
  end;

  TBufTCPCli=class(TTCPCli)
  private
    PacQueue:TObjQueue;
    Function GetQueuePacketCount:LongInt;
    Function GetQueueEmpty:Boolean;
  protected
    fBTCReadyToSendData:TNotifyEvent;
  public
    procedure   ResumeSendingData(Sender: TObject);
    procedure   FlushQueue;
    Constructor Create(AOwner: TComponent); override;
    Destructor  Destroy;                    override;
    Function    SendData(aBuff:PChar;aLen:integer):integer; override;
    procedure   Paint; override;
    Property    QueuePacketCount:LongInt read GetQueuePacketCount;
    Property    QueueEmpty:Boolean read GetQueueEmpty;
{    Procedure   Depura(texto:string);}
{    Procedure   DumpBuf(P:PChar; Len:integer);}
  published
    Property OnReadyToSendData:TNotifyEvent read fBTCReadyToSendData write fBTCReadyToSendData;
  end;

  TBufTCPSrv=class(TTCPSrv)
  private
    PacQueues:Array[1..MAXCLIENTS] of TObjQueue;
  protected
    fBTSReadyToSendData:TServerNotify;
    fQueueEnded:TServerNotify;
    Function  GetQueuePacketCount(index:integer):LongInt;
    Function  GetQueueEmpty(index:integer):boolean;
    procedure ResumeSendingData(Sender: TObject;ClientID:integer);
    Procedure SocketClosed(aClientID:integer); override;
    Procedure ClientAccepted(aClientID:integer;aIP:LongWord;aAddr:String); override;
  public
    fPacBufferSize:integer;       //tamanho da fila de pacotes armazenados (def=2000)

    Constructor Create(AOwner: TComponent); override;
    Destructor  Destroy;                    override;
    Function    SendData(ClientID:integer;aBuff:PChar;aLen:integer):integer; override;
    procedure   Paint; override;
    procedure   FlushQueue(aClientID:integer);
    Property    QueuePacketCount[index:integer]:LongInt read GetQueuePacketCount;
    Property    QueueEmpty[Index:integer]:Boolean       read GetQueueEmpty;
  published
    Property    OnReadyToSendData:TServerNotify read fBTSReadyToSendData write fBTSReadyToSendData;
    Property    OnQueueEnded:TServerNotify      read fQueueEnded write fQueueEnded;
  end;

procedure Register;

implementation {------------------------------}

{------------------- TPCharObj. -------------------}
{TObject q encapsula um pacote TCP}
Constructor TPacTCP.Create(aP:PChar;aL:integer);
begin
  inherited Create;
  L:=aL;
  GetMem(P,L);
  Move(aP^,P^,L);
end;

Destructor TPacTCP.Destroy;
begin
  if Assigned(P) then begin FreeMem(P,L); P:=Nil; end;
  inherited Destroy;
end;

{Se der detach no Pchar, nao esquecer depois de dar um FreeMem(P,L)}
Function  TPacTCP.Detach(var aL:integer):Pchar;
begin
  Result:=P;
  P:=Nil;
  aL:=L;
  L:=0;
end;

Procedure  TPacTCP.Realoc(aP:PChar;aL:integer);
begin
  if Assigned(P) then begin FreeMem(P,L); P:=Nil; end;
  L:=aL;
  GetMem(P,L);
  Move(aP^,P^,L);
end;

{---------------- TBufTCPCli. ----------------------}
Constructor TBufTCPCli.Create(AOwner: TComponent);
begin
  Inherited Create(aOwner);
  PacQueue:=TObjQueue.Create(nil);
  PacQueue.BufferSize:=8192;
  FOnReadyToSendData:=ResumeSendingData;
  fBTCReadyToSendData:=nil;
end;

Destructor  TBufTCPCli.Destroy;
begin
  PacQueue.Free;
  Inherited Destroy;
end;

procedure TBufTCPCli.Paint; {Write 'TCPCli' at design time only}
begin
  if (csDesigning in ComponentState) then
    Canvas.TextOut(5,5,'TCPBufCli');
end;

Function TBufTCPCli.SendData(aBuff:PChar;aLen:integer):integer;
var aPac:TPacTCP;   aL:integer;
begin
  if PacQueue.Empty then
    begin {fila vazia, manda direto}
      aL:=inherited SendData(aBuff,aLen);
      {estava aL:=send(ClientSocket,aBuff,aLen,0);}
      {if (aL<0) then aL:=0;}
      if aL<aLen then  {Ops, nao foi tudo, poe o resto na fila}
        begin
          aPac:=TPacTCP.Create(@aBuff[aL],aLen-aL);
          PacQueue.PutObj(aPac);
        end;
    end
    else begin  {tem coisa na fila, bota este no final da fila}
      aPac:=TPacTCP.Create(aBuff,aLen);
      if PacQueue.Full then  //ops. no space on queue
        begin
          if bBuftcpDesconectaOnQueueFull then
            begin
              FlushQueue;
              StopClient;
            end
            else raise Exception.Create('TCPCli Queue Full: '+GetRemoteHostName); //ago07: adicionei o host name
        end;
      PacQueue.PutObj(aPac);
    end;
  Result:=aLen; { sinaliza que foi tudo }
end;

procedure TBufTCPCli.ResumeSendingData(Sender: TObject);
var aPac:TPacTCP; aL,L:integer; P:PChar;
begin
  while not PacQueue.Empty do
    begin
      aPac:=TPacTCP(PacQueue.PeekNextObj); {pega ptr do prox pacote}
      P:=aPac.Detach(L);                   {detacha dados}
      {$IFDEF WIN32}
      aL:=send(ClientSocket,P^,L,0);  {send data.}
      {$ELSE WIN32}
      aL:=send(ClientSocket,P,L,0);  {send data.}
      {$ENDIF WIN32}
      if aL<0 then aL:=0;
      if aL<L then   {Ops, nao foi tudo, poe o resto na fila}
        begin
          aPac.Realoc(@P[aL],L-aL); {devolve o resto do pacote}
          break;                    {sai do while}
        end
        else begin {ok, foi todo o pacote}
          aPac:=TPacTCP(PacQueue.GetObj); {retira pacote já usado da fila}
          aPac.Free;                      {detona}
        end;
      if L>0 then FreeMem(P,L); {apos uso, desaloca pchar detachado de aPac}
    end;
  if Assigned(fBTCReadyToSendData) and PacQueue.Empty
    then fBTCReadyToSendData(Self);
end;

Function TBufTCPCli.GetQueuePacketCount:LongInt;
begin
  Result:=PacQueue.Count;
end;

Function TBufTCPCli.GetQueueEmpty:Boolean;
begin
  Result:=PacQueue.Empty;
end;

procedure TBufTCPCli.FlushQueue;
begin
  if Assigned(PacQueue) then PacQueue.Flush;
end;

{---------------- TBufTCPSrv. ----------------------}
Constructor TBufTCPSrv.Create(AOwner: TComponent);
begin
  Inherited Create(aOwner);
  FillChar(PacQueues,SizeOf(PacQueues),#0);
  FOnReadyToSendData:=ResumeSendingData;
  fBTSReadyToSendData:=nil;
  fPacBufferSize:=2000; //default=até 2000 pacotes em fila
end;

Destructor  TBufTCPSrv.Destroy;
var i:integer;
begin
  for i:=1 to MAXCLIENTS do if Assigned(PacQueues[i]) then PacQueues[i].Free;
  Inherited Destroy;
end;

Procedure TBufTCPSrv.SocketClosed(aClientID:integer);
begin
  inherited SocketClosed(aClientID); {ancestral gera evento}
  if Assigned(PacQueues[aClientID]) then
    begin
      PacQueues[aClientID].Free;
      PacQueues[aClientID]:=Nil;
    end;
end;

Procedure TBufTCPSrv.ClientAccepted(aClientID:integer;aIP:LongWord;aAddr:String);
begin
  if not Assigned(PacQueues[aClientID]) then
    begin
      PacQueues[aClientID]:=TObjQueue.Create(nil);
      PacQueues[aClientID].BufferSize:=fPacBufferSize;    //armazena até 2000 pacotes em cada fila
    end;
  inherited ClientAccepted(aClientID,aIP,aAddr);
end;

procedure TBufTCPSrv.Paint; {Write 'TCPCli' at design time only}
begin
  if (csDesigning in ComponentState) then
    Canvas.TextOut(5,5,'TCPBufSrv');
end;

Function TBufTCPSrv.SendData(ClientID:integer;aBuff:PChar;aLen:integer):integer;
var aPac:TPacTCP;   aL:integer;
begin
  Result:=0;
  if not Assigned(PacQueues[ClientID]) then exit;
  if PacQueues[ClientID].Empty then
    begin {fila vazia, manda direto}
      aL:=inherited SendData(ClientID,aBuff,aLen);
      if aL<aLen then  {Ops, nao foi tudo, poe o resto na fila}
        begin
          aPac:=TPacTCP.Create(@aBuff[aL],aLen-aL);
          PacQueues[ClientID].PutObj(aPac);
        end;
    end
    else begin  {tem coisa na fila, bota este no final da fila}
      aPac:=TPacTCP.Create(aBuff,aLen);
      if PacQueues[ClientID].Full then
        raise Exception.Create('TCPSrv Queue Full');
      PacQueues[ClientID].PutObj(aPac);
    end;
  Result:=aLen; {sinaliza que foi tudo}
end;

procedure TBufTCPSrv.FlushQueue(aClientID:integer);
begin
  if Assigned(PacQueues[aClientID]) then PacQueues[aClientID].Flush;
end;

procedure TBufTCPSrv.ResumeSendingData(Sender: TObject;ClientID:integer);
var aPac:TPacTCP; aL,L:integer; P:PChar;
begin
  if Assigned(PacQueues[ClientID]) then
    begin
      while Assigned(PacQueues[ClientID]) and (not PacQueues[ClientID].Empty) do
        begin
          aPac:=TPacTCP(PacQueues[ClientID].PeekNextObj); {pega ptr do prox pacote}
          P:=aPac.Detach(L);                              {detacha dados}
          aL:=inherited SendData(ClientID,P,L);
          if aL<L then   {Ops, nao foi tudo, poe o resto na fila}
            begin
              aPac.Realoc(@P[aL],L-aL); {devolve o resto do pacote, sem remove-lo da fila}
              break; {sai do while}
            end
            else begin {ok, foi todo o pacote}
              aPac:=TPacTCP(PacQueues[ClientID].GetObj); {retira pacote já usado da fila}
              aPac.Free;                      {detona-lho}
            end;
          if (L>0) then FreeMem(P,L);
          if Assigned(fQueueEnded) and PacQueues[ClientID].Empty then
            fQueueEnded(Self,ClientID); {acabou a queue. Notifica usr}
          {Este evento pode eventualmente chamar CloseClient(), que desaloca a fila do cliente.
           Por isso e' importante verificar a cada passo se Assigned(PacQueues[ClientID])}
        end;
      {Se fila vazia, gera evento pra frente}
      if Assigned(fBTSReadyToSendData) and Assigned(PacQueues[ClientID])
        and (PacQueues[ClientID].Empty) then
          fBTSReadyToSendData(Self,ClientID);
    end;
end;

Function  TBufTCPSrv.GetQueueEmpty(index:integer):boolean;
begin
  if Assigned(PacQueues[index]) then
    Result:=PacQueues[index].Empty
    else Result:=TRUE;
end;

Function TBufTCPSrv.GetQueuePacketCount(index:integer):LongInt;
begin
  if Assigned(PacQueues[index]) then
    Result:=PacQueues[index].Count
    else Result:=-1;
end;

(*Procedure TBufTCPCli.Depura (texto: string);
var T:TextFile;
begin
  AssignFile (T, 'c:\t128.txt');
  try
    Append (T);
  except
    Rewrite (T);
  end;
  WriteLn (T, texto);
  CloseFile (T);
end;
*)
(*Procedure TBufTCPCli.DumpBuf(P:PChar; Len:integer);
var T:TextFile;i:integer;StrDmp:string;
begin
  AssignFile (T, 'c:\t128.txt');
  try
    Append (T);
  except
    Rewrite (T);
  end;
  StrDmp:='';
  for i:= 0 to Len -1 do
  begin
    StrDmp := StrDmp + IntToHex (integer(P[i]), 4) + ' ';
    if (i > 0) and ((i mod 10) = 0) then
    begin
      WriteLn (T, StrDmp);
      StrDmp := '';
    end;
  end;
  if Length (StrDmp) > 0 then
    WriteLn (T, StrDmp);
  CloseFile (T);
end;
*)

{---------------------------------------------}
procedure Register;
begin
  RegisterComponents('Omar', [TBufTCPCli,TBufTCPSrv]);
end;

end.


unit SockCmp; { TCP/IP (WinSock) components for Delphi - ©Copr. 1995 Omar F. Reis }
{------------------  Ver 2.0 20/2/98  ---------------------}
// Historico:
//   ago09:Om: alteração no erro de DNS. Não gera mais exception (só msg de status)

{$INCLUDE OmVerDefines.inc}

interface
uses
  WinTypes, WinProcs, Classes, SysUtils,
  Messages,Controls,
  Dialogs,
  Base64,            {Base64Encode()}
  {$IFDEF VER5UP} // Delphi 5
  typinfo,
  {$ELSE VER5UP}
  DsgnIntf,      {EPropertyError}
  {$ENDIF VER5UP}
  Winsock;

type
  Char40=Array[0..39] of char;
{$IFDEF WIN32}
{Compatibilidade c/ Winsock 32}
  sockaddr_in=TSockAddrIn;
  WSADATA=TWSADATA;
  sockaddr=TSockAddr;
{$ENDIF WIN32}

{$IFDEF VER100} {LongWord nao tinha no Delphi 3}
  LongWord=LongInt;
{$ENDIF VER100}

const
  INV_SOCK=$FFFF;         {=Winsock.dll's INVALID_SOCKET}
  INADDR_NONE=$FFFFFFFF;  {Invalid address}
  MAXCLIENTS=2000;        {para Srv. aceita até 1000 conexoes simultaneas !}
{Async Messages}
  WM_HOST_BY_NAME=WM_USER+103;
  WM_SERVICE_BY_NAME=WM_USER+104;
  WM_CLIENT_SELECT=WM_USER+101;
  WM_SERVER_SELECT=WM_USER+102;
  TIMEOUTSECS=10;     {number of secs. for client connect time out}

type
  TTcpCmpState=(IDLE,WSASTARTED,CONNECTING,CONNECTED);
{-------TTCPComponent - abstract ancestral for TCPClient and TCPServer --}
{WinSock async msg receivers must be windows. In this case, a CustomControl}
  TTCPComponent=class(TCustomControl)
  Private
  Protected
    Remote_Host:Thostent;
    Remote_Addr:sockaddr_in;
    WSAData : WSADATA;        {Winsock data}
    {fields}
    FServerPort:word;   {Port # for the service}
    FAutoStart:Boolean; {if TRUE, connect on creation (run time only)}
    FServiceName,
    FProtoName:Char40;  {Service and protocol names}
    FTcpState:TTcpCmpState;
    {!!!CAP}
    ProxyBuff:Array[0..1059] of char; {era def no stack. Tirei pra economizar stack}
    ProxyStr:String;                  {tb era dinamica.}
    {!!!CAP}

    Procedure Abort(const Msg:String); {Fatal error}
    Procedure Error(const Msg:String);
    Function  GetServicePort:Boolean;
    {access methods}
    Procedure SetServiceName(Value:String);
    Function  GetServiceName:String;
    Procedure SetProtoName(Value:String);
    Function  GetProtoName:String;
    Function  StartUp:Boolean;
    procedure CleanUp;
  Public
    Constructor Create(AOwner: TComponent); override;
    Destructor  Destroy;                     override;
    Function    InAddrStrToInt(aAddr:String):LongWord;
  Published
    Property AutoStart  :boolean read FAutoStart write FAutoStart default FALSE;
    Property ServiceName:String  read GetServiceName write SetServiceName;
    Property ProtoName  :String  read GetProtoName   write SetProtoName;
    Property ServerPort :word    read FServerPort    write FServerPort default 0;
    Property TcpState:TTcpCmpState read FTcpState;
  end;
{-----  Server Component  --------------------------------------}

{ TServerNotify-Server is multi client. Notifications must include de
  client ID, so the user's event handler knows wich client generated it.}
  TServerNotify=Procedure(Sender:TObject;ClientID:integer) of Object;
  TServerAcceptNotify=Procedure(Sender:TObject;ClientID:integer;aIP:LongWord;aAddr:String) of Object;

  TTCPSrv=class(TTCPComponent)
  Private
    NumClients:integer;
    ServerSocket:tSOCKET;     {to listen client connect requests}
    ClientSockets:Array [1..MAXCLIENTS] of tSOCKET; {actual data xchg sockets}
    fClientIPs:Array [1..MAXCLIENTS] of longInt;
    {fields}
    Procedure CloseServerSocket; {Close server socket, if open}
    Procedure CloseClientSocket(aClientID:integer);
    Function  CreateServerSocket:Boolean;
    Function  BindToSocket:Boolean;
    Function  ListenToSocket:Boolean;
    Function  Socket2Client(aSocket:tSocket):integer;
    Function  GetFreeClientSocket:integer; {returns an unused client socket, if any}
    Procedure SetNumClients;
    {async tcp messages}
    Procedure WMClientSelect(var Msg: TMessage); message WM_CLIENT_SELECT;
    Procedure WMServerSelect(var Msg: TMessage); message WM_SERVER_SELECT;
    {access methods}
  Protected
    {socket events}
    FOnStopSending    :TServerNotify;
    FOnReadyToSendData:TServerNotify;
    FOnDataReceived   :TServerNotify;
    FOnCloseSocket    :TServerNotify;
    FOnClientAccept   :TServerAcceptNotify;
    FOnSendError      :TServerNotify;
    procedure Paint; override;
    Procedure SocketClosed(aClientID:integer); virtual;
    Procedure ClientAccepted(aClientID:integer;aIP:LongWord;aAddr:String); virtual;
  Public
    ClientsHiMark:integer;      {Max de sockets de cliente abertos}
    Constructor Create(AOwner: TComponent); override;
    Destructor  Destroy;                    override;
    Procedure   Loaded;                     override;
    Function    StartServer:boolean;
    Procedure   StopServer;
    Procedure   CloseClient(aCliID:integer);
    {data exchange methods}
    Function    RecvData(aCliID:integer;aBuff:PChar;aLen:integer):integer; virtual;
    Function    SendData(aCliID:integer;aBuff:PChar;aLen:integer):integer; virtual;
    Procedure   SendDataAll(aBuff:PChar;aLen:integer);
    Function    GetClientSocket(aClientID:integer):tSocket;

    Function    ClienteConectado(aClientID:integer):boolean;
    function    GetIPStr(aClientID:integer): String; //retorna IP na forma numerica (como inteiro, nao como a.c.d)
  Published
    Property OnStopSending :TServerNotify read FOnStopSending  write FOnStopSending;
    Property OnReadyToSendData:TServerNotify read FOnReadyToSendData write FOnReadyToSendData;
    Property OnDataReceived:TServerNotify read FOnDataReceived write FOnDataReceived;
    Property OnCloseSocket :TServerNotify read FOnCloseSocket  write FOnCloseSocket;
    Property OnClientAccept:TServerAcceptNotify read FOnClientAccept write FOnClientAccept;
    Property OnSendError   :TServerNotify read FOnSendError    write FOnSendError;
  end;

{-----  Client Component  ------------------------------------}
  {Timeout count notification}
  TTimeOutNotify=Procedure(Sender:TObject;SecsLeft:integer) of Object;
  {Client connect status}
  TConnectStatus=(DNS_QUERY,HOST_NOT_FOUND,HOST_FOUND,HOST_CONNECTED,CLOSED,SOCKS_ERROR);
  TConnectStatusNotify=Procedure(Sender:TObject;aStatus:TConnectStatus) of Object;

  TTCPCli = class(TTCPComponent)
  Private
    fHndTskDNSAssync:THandle;
    fResolvendoDNSAssync:Boolean;
    fUsaDNSAssincrono:boolean;
    procedure CantFindHostError;
  Protected
    ClientSocket:tSOCKET;
    TimeOutCnt:integer;
    {socket events}
    FOnStopSending:TNotifyEvent;
    FOnReadyToSendData:TNotifyEvent;
    FOnDataReceived:TNotifyEvent;
    FOnCloseSocket:TNotifyEvent;
    FOnConnect:TNotifyEvent;
    FOnConnectTimeoutCount:TTimeOutNotify;
    FOnConnectTimeout:TNotifyEvent;
    FOnSendError:TNotifyEvent;
    FOnConnectStatus:TConnectStatusNotify;
    {fields}
    FRemoteHostName:Char40;
    FServiceName:Char40;
    FProtoName:Char40;
    FTimeOutSecs:integer;
{!!!CAP}
    fEstadoHttpProxy:integer;
    fUsaHttpProxy:boolean;

    FFinalHostName:Char40; {Final host e porta usados pelo proxy http e pelo proxy socks}
    FFinalPort:word;
    fHttpProxyAuth:String;    {tipo: user:password --> 'mcaixeta:caixeta'}
    fProxyAuthResult:integer; {resultado da autenticacao no proxy}

{!!!CAP}
    fUsaSocks:boolean; {TRUE Se é um socks client}
    fSocksUser:String;
    fEstadoSocks:integer;

    procedure Paint; override;
    Procedure CloseClientSocket;   {Close client socket, if open}
    Function  GetRemoteHostAddrAssincrono:integer;
    Function  GetRemoteHostAddrBlocante:integer;
    Function  CreateClientSocket:Boolean;
    Function  ConnectToServer:Boolean;
    function  GetFinalHostIP:String;

    Procedure WMClientSelect(var Msg:TMessage); message WM_CLIENT_SELECT;
    Procedure WMTimer(var Msg: TMessage);      message WM_TIMER;
    Procedure WMHostByName(var Msg: TMessage); message WM_HOST_BY_NAME;
    {access methods}
    Procedure SetRemoteHostName(Value:String);
    Function  GetRemoteHostName:String;
    {!!!CAP}
    Procedure SetFinalHostName(Value:String);
    Function  GetFinalHostName:String;
    {!!!CAP}
    Procedure Loaded; override;
  Public
    Constructor Create(AOwner: TComponent); override;
    Destructor  Destroy;                    override;
    Function    StartClient:boolean; virtual; {TRUE if connect request ok. Wait for OnConnect}
    Procedure   StopClient;          virtual;
    {data exchange methods}
    Function  RecvData(aBuff:PChar;aLen:integer):integer; virtual;
    Function  SendData(aBuff:PChar;aLen:integer):integer; virtual;
  Published
    Property OnStopSending   :TNotifyEvent  read FOnStopSending     write FOnStopSending;
    Property OnReadyToSendData:TNotifyEvent read FOnReadyToSendData write FOnReadyToSendData;
    Property OnDataReceived  :TNotifyEvent  read FOnDataReceived    write FOnDataReceived;
    Property OnCloseSocket   :TNotifyEvent  read FOnCloseSocket     write FOnCloseSocket;
    Property OnConnect       :TNotifyEvent  read FOnConnect         write FOnConnect;
    Property OnConnectTimeout:TNotifyEvent  read FOnConnectTimeout  write FOnConnectTimeout;
    Property OnSendError     :TNotifyEvent  read FOnSendError       write FOnSendError;
    Property OnConnectStatus :TConnectStatusNotify read FOnConnectStatus write FOnConnectStatus;
    Property OnConnectTimeoutCount:TTimeOutNotify
        read FOnConnectTimeoutCount write FOnConnectTimeoutCount;
    Property RemoteHostName:String       read GetRemoteHostName write SetRemoteHostName;
    {!!!CAP}
    Property FinalHostName:String  read GetFinalHostName write SetFinalHostName;
    Property FinalPort :word       read FFinalPort write FFinalPort default 0;

    Property Proxy :boolean      read fUsaHttpProxy write fUsaHttpProxy default FALSE;
    Property SocksClient:boolean read fUsaSocks  write fUsaSocks   default FALSE;
    Property SocksUser:String    read fSocksUser write fSocksUser;
    {!!!CAP}
    Property TimeOutSecs   :integer read FTimeOutSecs write FTimeOutSecs;
    Property ProxyAuthStr:String read fHttpProxyAuth write fHttpProxyAuth;
    Property UsaDNSAssincrono:boolean read fUsaDNSAssincrono write fUsaDNSAssincrono default TRUE;
  end;

Procedure Register;

implementation {====================================================}

const {Error messages}
  sWSAStartupError='Erro em WSAStartup(). Verifique WinSock.DLL';
  sCleanUpError='Erro em WSACleanup()';
  sServProtoNameError='Serviço ou protocolo inválido';
  sGetServByNameError='Nome de serviço inválido. Verifique o arquivo SERVICES.';
  sCantFindHost1='Impossível achar host ';
  sCantFindHost2=#13#10'Verifique o DNS.';
    {#10#13+'Deve conter uma linha: eolsrv  <end IP>';}
  sRemoteHostNmInvalid='Nome do host inválido';
  sCantCreateClientSocket='Impossível criar socket de Cliente';
  sErrorOnConnectCmd='Erro no comando Connect()';
  sCantCreateServerSocket='Impossível criar socket do Servidor ';
  sErrorBindCmd='Já tem um servidor escutando nesta porta.';
  sCabecalhoSocksInvalido='Cabeçalho Socks Inválido:';
  sConexaoSocksRejeitada='Conexão socks rejeitada:';
(*
  sWSAStartupError='Error on WSAStartup(). Check WinSock.DLL';
  sCleanUpError='Error on WSACleanup()';
  sServProtoNameError='Service or protocol name invalid';
  sGetServByNameError='GetServByName(). Check SERVICES file';
  sCantFindHost='Can''t find host. Check HOSTS file';
  sRemoteHostNmInvalid='Remote Host Name invalid';
  sCantCreateClientSocket='Can''t Create Client Socket';
  sErrorOnConnectCmd='Error on Connect() command';
  sCantCreateServerSocket='Can''t Create Server Socket.';
  sErrorBindCmd='Error:Bind command'; {enghish} *)

{------------------------- TTCPComponent. --------------------------}
Constructor TTCPComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(0,0,100,30);
  StrCopy(FServiceName,'');
  StrCopy(FProtoName,'tcp'); {Default protocol='tcp'}
  FServerPort:=0;
  FTcpState:=IDLE;
  FAutoStart:=FALSE;
end;

Destructor  TTCPComponent.Destroy;
begin
  inherited Destroy;
end;

Function TTCPComponent.StartUp:Boolean;
var VerReqd : word;
begin
  Result:=TRUE;
  if FTcpState=IDLE then {don't startup twice}
    begin
      VerReqd:=$0101;  {Require ver 1.1 of Winsock.dll}
      {$IFDEF WIN32}
      Result:=WSAStartup(VerReqd,WSAData)=0;
      {$ELSE WIN32}
      Result:=WSAStartup(VerReqd,@WSAData)=0;
      {$ENDIF WIN32}
      if Result then FTcpState:=WSASTARTED
       else Abort(sWSAStartupError);
    end;
end;

procedure TTCPComponent.CleanUp;
begin
  if (FTcpState<>IDLE) then {called StartUp, cleanup}
    if (WSACleanup<>0) then MessageBeep(0);
    {era Error(sCleanUpError);}
  FTcpState:=IDLE;
end;

{fatal error}
Procedure TTCPComponent.Abort(const Msg:String);
begin

  Raise Exception.Create(Msg);
  CleanUp; //teste
end;

Procedure TTCPComponent.Error(const Msg:String);
begin
  MessageDlg(Msg,mtError,[mbOk],0);
end;

Procedure TTCPComponent.SetServiceName(Value:String);
begin StrPCopy(FServiceName,Value); end;

Function  TTCPComponent.GetServiceName:String;
begin Result:=StrPas(FServiceName); end;

Procedure TTCPComponent.SetProtoName(Value:String);
begin StrPCopy(FProtoName,Value); end;

Function  TTCPComponent.GetProtoName:String;
begin Result:=StrPas(FProtoName); end;

Function TTCPComponent.GetServicePort:Boolean;
var  pSE : pServEnt;
begin
  if FServerPort=0 then
    begin {If 0, search SERVICES. for the specified service port}
      FServerPort:=0; {0=error}
      if (StrLen(FServiceName)=0) or (StrLen(FProtoName)=0)
         then raise EPropertyError.Create(sServProtoNameError);
      pSE:=getservbyname(FServiceName,FProtoName);
      if pSE = nil then
        begin
          Error(sGetServByNameError);
          Result:=FALSE;
        end
        else begin
          FServerPort:=htons(pSE^.s_port);
          Result:=TRUE;
        end;
    end
    else Result:=TRUE; {if<>0, accept user port number.} 
end;

{Addr String --> LongWord (Network order). If error in aAddr, returns 0}
Function TTCPComponent.InAddrStrToInt(aAddr:String):LongWord;
var A:Array[0..20] of char;
begin
  StrPCopy(A,aAddr);
  Result:=LongWord(inet_addr(A));
  if Result=INADDR_NONE then Result:=0;
end;

{-------------------------- TTCPSrv. ----------------------------}
Constructor TTCPSrv.Create(AOwner: TComponent);
var i:integer;
begin
  inherited Create(AOwner);
  for i:=1 to MAXCLIENTS do
    begin
      ClientSockets[i]:=INV_SOCK;
      fClientIPs[i]:=0;
    end;

  ServerSocket:=INV_SOCK;
  NumClients:=0;
  ClientsHiMark:=0;
end;

Destructor TTCPSrv.Destroy;
begin
  FOnCloseSocket:=Nil; {reset event handler, so closing form won't be called}
  StopServer;
  CleanUp;
  inherited Destroy;
end;

procedure TTCPSrv.Loaded;
begin
  inherited Loaded;
  if (not (csDesigning in ComponentState)) and
    FAutoStart then StartServer; {Auto start Server at run time}
end;

procedure TTCPSrv.Paint; {Make it visible at design time}
begin
  if (csDesigning in ComponentState) then
    Canvas.TextOut(5,5,'TCPSrv');
end;

Function TTCPSrv.StartServer:boolean;
begin
  if (FTcpState=IDLE) or (FTcpState=WSASTARTED) then
    begin
      Result:=(StartUp and GetServicePort and CreateServerSocket
      and BindToSocket and ListenToSocket);
      if Result then FTcpState:=CONNECTED;
      {Listen accepted. No CONNECTING here}
    end
    else Result:=FALSE;
end;

Procedure TTCPSrv.StopServer;
var i,rc:integer;
begin
  for i:=1 to ClientsHiMark do if ClientSockets[i]<>INV_SOCK then
    begin
      rc:=CloseSocket(ClientSockets[i]);   {Close all client sockets}
      if rc=SOCKET_ERROR then rc:=WSAGetLastError; {??}
      ClientSockets[i]:=INV_SOCK;
      fClientIPs[i]:=0;
    end;
  CloseServerSocket; {..if open}
  CleanUp;           {teste 23/8/96}
end;

(* procedure ShowWinSockInfo;
begin
  Write('Winsock Version found: ');
  Writeln(lobyte(myWSAData.wVersion),'.',lobyte(myWSAData.wHighVersion));
  S := StrPas(myWSAData.szDescription);
  Writeln('Description=',S);
  S := StrPas(myWSAData.szSystemStatus);
  Writeln('SystemStatus=',S);
  Writeln('MaxSockets=',word(myWSAData.iMaxSockets));
  Writeln('MaxUdpDg=',word(myWSAData.iMaxUdpDg));
  Write('VendorInfo= ');
    if myWSAData.lpVendorInfo <> NIL then begin
      writeln(myWSAData.lpVendorInfo);
    end else writeln('NULL');
  Write('Local Hostname=');
  if (gethostname(@CharArray,255) <> 0) then Error('GetHostName')
    else writeln(CharArray);
end; *)

Function TTCPSrv.CreateServerSocket:Boolean;
begin
  ServerSocket:=socket(PF_INET,SOCK_STREAM,IPPROTO_IP);
  If ServerSocket=INVALID_SOCKET then
    begin
      CreateServerSocket:=FALSE;
      Abort(sCantCreateServerSocket);
    end
    else CreateServerSocket:=TRUE;
end;

Procedure TTCPSrv.CloseServerSocket; {Close server socket, if open}
var rc:integer;
begin
  if ServerSocket<>INV_SOCK then
    begin
      rc:=CloseSocket(ServerSocket);
      {FTcpState:=WSASTARTED;}
    end;
  ServerSocket:=INV_SOCK;
end;

{Close a client socket}
Procedure TTCPSrv.CloseClientSocket(aClientID:integer);
var rc:integer; aSocket:tSOCKET;
begin
  aSocket:=ClientSockets[aClientID];
  if aSocket<>INV_SOCK then
    begin
      rc:=CloseSocket(aSocket);
      if rc=SOCKET_ERROR then
        begin
          rc:=WSAGetLastError;
          if (rc=WSAENOTSOCK) then {???};
        end;
      ClientSockets[aClientID]:=INV_SOCK;
      fClientIPs[aClientID]:=0;
      SetNumClients;
    end;
  SocketClosed(aClientID);
end;

Procedure TTCPSrv.SocketClosed(aClientID:integer);
begin
  if Assigned(FOnCloseSocket) then FOnCloseSocket(Self,aClientID);
end;

{aqui Remote_addr já contem endereco IP do host remoto}
Function TTCPSrv.BindToSocket:Boolean;
begin
  Remote_addr.sin_family := PF_INET;          {completa Remote_addr}
  Remote_addr.sin_port :=htons(FServerPort);
  Remote_addr.sin_addr.s_addr:=INADDR_ANY;
  if bind(ServerSocket,sockaddr(Remote_Addr),SizeOf(Remote_Addr))<>0 then
    begin
      CloseServerSocket;
      BindToSocket:=FALSE;
      Abort(sErrorBindCmd);
    end
    else BindToSocket:=TRUE;
end;

Function TTCPSrv.ListenToSocket:Boolean;
var rc : integer;
begin
  rc:=listen(ServerSocket,5);
  if rc>0 then Error('Listen');
  rc:=rc+WSAAsyncSelect(ServerSocket,Handle,WM_SERVER_SELECT,FD_ACCEPT); {req async accept}
  if rc>0 then
  begin
    CloseServerSocket;
    ListenToSocket:=FALSE;
    Abort('WSAAsyncSelect:Accept');
  end
  else ListenToSocket:=TRUE;
end;

{returns an unused client socket, if any}
Function TTCPSrv.GetFreeClientSocket:integer;
var i:integer;
begin
  GetFreeClientSocket:=0;      {0=invalid}
  for i:=1 to MAXCLIENTS do
    if ClientSockets[i]=INV_SOCK then
      begin
        GetFreeClientSocket:=i;
        if i>ClientsHiMark then
          ClientsHiMark:=i; {marca maximo de sockets abertos}
        exit;
      end;
end;

{Update the number of connected clients label}
Procedure TTCPSrv.SetNumClients;
var i:integer;
begin
  NumClients:=0;
  for i:=1 to ClientsHiMark do
    if ClientSockets[i]<>INV_SOCK then inc(NumClients); {# of active sockets}
end;

Function TTCPSrv.Socket2Client(aSocket:tSocket):integer;
var i:integer;
begin
  Socket2Client:=0;            {0=invalid}
  for i:=1 to ClientsHiMark do
    if ClientSockets[i]=aSocket then
      begin Socket2Client:=i; exit; end;
end;

Function TTCPSrv.ClienteConectado(aClientID:integer):boolean;
begin
  Result:=(ClientSockets[aClientID]<>INV_SOCK);
end;

Function TTCPSrv.GetClientSocket(aClientID:integer):tSocket;
begin
  Result:=ClientSockets[aClientID];
end;

{Message handler for async socket events}
Procedure TTCPSrv.WMClientSelect(var Msg: TMessage);
var rc:integer; aSocket:tSOCKET; aClientID:integer;
begin
  aSocket:=Msg.wParam;
  aClientID:=Socket2Client(aSocket); {convert socket # --> client ID}
  if aClientID=0 then exit;          {Invalid client socket, exit}
  rc:=WSAGetSelectError(Msg.lParam); {Error code}
  case Loword(Msg.lParam) of
    FD_WRITE: begin {Ready to send data}
      if (rc<>0) then Error('Erro:FD_WRITE')
        else if Assigned(FOnReadyToSendData) then
            FOnReadyToSendData(Self,aClientID);
    end;
    FD_READ : begin {data received}
      if (rc<>0) then Error('Erro: FD_READ')
        else if Assigned(FOnDataReceived) then FOnDataReceived(Self,aClientID);
    end;
    FD_CLOSE:
      begin
        {!!!CAP 26/08/97}
        if Assigned(FOnDataReceived) then {Pode ainda ter dados para ler}
          FOnDataReceived(Self,aClientID);
        {/!!!CAP}

        FTcpState:=WSASTARTED;        {return to stoped}
        CloseClientSocket(aClientID); {close client socket}
      end;
  end;   {case lParam}
end;

{Public method to forcefully disconnect a client}
Procedure TTCPSrv.CloseClient(aCliID:integer);
begin
  {Sleep (1000);}  //CAP ???
  CloseClientSocket(aCliID);
end;

{Receive data. returns bytes read count (or SOCKET_ERROR)}
Function TTCPSrv.RecvData(aCliID:integer;aBuff:PChar;aLen:integer):integer;
var aSocket:tSOCKET; actualL:integer;
begin
  aSocket:=ClientSockets[aCliID];
  if aSocket=INV_SOCK then RecvData:=SOCKET_ERROR
    else begin
      {$IFDEF WIN32}
      actualL:=recv(aSocket,aBuff^,aLen,0);
      {$ELSE WIN32}
      actualL:=recv(aSocket,aBuff,aLen,0);
      {$ENDIF WIN32}
      if actualL=SOCKET_ERROR then actualL:=0;
      RecvData:=actualL;
    end;
end;

{returns bytes sent count (or SOCKET_ERROR)}
Function TTCPSrv.SendData(aCliID:integer;aBuff:PChar;aLen:integer):integer;
var aSocket:tSOCKET; rc,actualL:integer;
begin
  aSocket:=ClientSockets[aCliID];
  if aSocket=INV_SOCK then Result:=0 {SOCKET_ERROR}  {invalid socket??}
    else begin
      {$IFDEF WIN32}
      actualL:=send(aSocket,aBuff^,aLen,0);  {send data}
      {$ELSE WIN32}
      actualL:=send(aSocket,aBuff,aLen,0);  {send data}
      {$ENDIF WIN32}
      if actualL=SOCKET_ERROR then
        begin
          rc:=WSAGetLastError;
          if (rc=WSAEWOULDBLOCK) then      {expected result if client buff full}
             if Assigned(FOnStopSending) then FOnStopSending(Self,aCliID) {stop}
               else if Assigned(FOnSendError) then FOnSendError(Self,aCliID);
          actualL:=0;                      {sent 0 bytes}
        end;
      Result:=actualL;
    end;
end;

{Send the same data to all current clients}
Procedure TTCPSrv.SendDataAll(aBuff:PChar;aLen:integer);
var i:integer; aSocket:tSOCKET; aL:integer;
begin
  for i:=1 to ClientsHiMark do
    begin
      aSocket:=ClientSockets[i];
      aL:=0;  //para remover compiler warning
      if aSocket<>INV_SOCK then
        {$IFDEF WIN32}
        aL:=send(aSocket,aBuff^,aLen,0);
        {$ELSE WIN32}
        aL:=send(aSocket,aBuff,aLen,0);
        {$ENDIF WIN32}
      if aL=SOCKET_ERROR then aL:=0;    {Sent 0 bytes}
    end;
end;

{Server receives a client connect request}
Procedure TTCPSrv.WMServerSelect(var Msg: TMessage);
var aClientID:integer; aLen:integer; aAddr:sockaddr; AcceptSocket:tSOCKET;
    IPAd:LongWord; StIPAd:String[20];
begin
  if (WSAGetSelectError(Msg.lparam)<>0) then Error('SERVER_SELECT')
    else begin
      aLen :=SizeOf(aAddr);
      aAddr:=SockAddr(Remote_Addr);
      aClientID:=GetFreeClientSocket; {pega primeiro socket livre que houver}
      if (aClientID=0) then exit;     {too many clients}
      {$IFDEF WIN32}
      AcceptSocket:=accept(ServerSocket,@aAddr,@aLen);
      {$ELSE WIN32}
      AcceptSocket:=accept(ServerSocket,@aAddr,@aLen);
      {$ENDIF WIN32}
      if AcceptSocket=INV_SOCK then Error('AcceptSocket')
        else begin
          WSAAsyncSelect(AcceptSocket,Handle,WM_CLIENT_SELECT,
             FD_READ or FD_WRITE or FD_CLOSE);
          ClientSockets[aClientID]:=AcceptSocket;
          SetNumClients;
          IPAd:=sockaddr_in(aAddr).sin_addr.S_addr;
          fClientIPs[aClientID]:=IPAd;
          StIPAd:=StrPas(inet_ntoa(sockaddr_in(aAddr).sin_addr));
          ClientAccepted(aClientID,IPAd,StIPAd);
        end;
   end;
end;

Procedure TTCPSrv.ClientAccepted(aClientID:integer;aIP:LongWord;aAddr:String);
begin
  if Assigned(FOnClientAccept) then FOnClientAccept(Self,aClientID,aIP,aAddr);
end;

function TTCPSrv.GetIPStr(aClientID:integer):String;
begin
  Result:=IntToStr(fClientIPs[aClientID]);
end;

{-------------------------- TTCPCli. ----------------------------}
Constructor TTCPCli.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  StrCopy(FRemoteHostName,'');
  TimeOutCnt:=0;
  ClientSocket:=INV_SOCK;
  FTimeOutSecs:=0;
{!!!CAP}
  fUsaHttpProxy:=FALSE;
  StrCopy(FFinalHostName,'');
  FFinalPort:=0;
{!!!CAP}
  fHttpProxyAuth:=''; {String de autenticacao no httpProxy}

  fUsaSocks:=FALSE;
  fSocksUser:='TCP';
  fEstadoSocks:=0;
  fUsaDNSAssincrono:=TRUE;
end;

Destructor TTCPCli.Destroy;
begin
  FOnCloseSocket:=Nil; {reset event handler, so closing form won't be called}
  StopClient;
  CleanUp;
  inherited Destroy;
end;

procedure TTCPCli.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in ComponentState) and
    FAutoStart then StartClient; {Auto start Client at run time}
end;

procedure TTCPCli.Paint; {Write 'TCPCli' at design time only}
begin
  if (csDesigning in ComponentState) then
    Canvas.TextOut(5,5,'TCPCli');
end;

Function TTCPCli.StartClient:Boolean; {Connect with remote server}
var Ok:Boolean;  res:integer;
begin
  Result:=FALSE;
  {Dont accept StartClient during CONNECTING or CONNECTED}
  if (FTcpState=IDLE) or (FTcpState=WSASTARTED) then
    begin
      Ok:=StartUp; {initialize Winsock}
      if Ok then
        begin
          if fUsaDNSAssincrono then res:=GetRemoteHostAddrAssincrono {DNS Query}
            else res:=GetRemoteHostAddrBlocante;
          case res of
            -1: Result:=FALSE; {erro na resolucao}
            0 : Result:=TRUE;  {esta resolvendo nome assincronamente...}
            1 : begin          {era numero IP ou resolveu por blocante}
                  Ok:=GetServicePort;
                  if Ok then Ok:=CreateClientSocket;
                  if Ok then Ok:=ConnectToServer; {make connection request}
                  if Ok then FTcpState:=CONNECTING; {ok? wait for host answer}
                  Result:=Ok;
                end;
          end;
        end; {if ok}
    end;
end;

Procedure TTCPCli.CantFindHostError;
var S:String;
begin
  S:=sCantFindHost1+StrPas(FRemoteHostName)+sCantFindHost2;
  Abort(S);
end;

Procedure TTCPCli.StopClient;
begin
  if TimeOutCnt>0 then {Stop timeout timer}
    begin
      KillTimer(Handle,0);
      TimeOutCnt:=0;
    end;
  if fResolvendoDNSAssync then
  begin
    WSACancelAsyncRequest(fHndTskDNSAssync); {Cancel pending Async request}
    fResolvendoDNSAssync:=FALSE;
    if Assigned(FOnConnectStatus) then //ago09:
      begin
        FOnConnectStatus(Self,HOST_NOT_FOUND); {name query failed}
        CleanUp;
      end
      else CantFindHostError;
  end;
  CloseClientSocket;
end;

Procedure TTCPCli.SetRemoteHostName(Value:String);
begin StrPCopy(FRemoteHostName,Value); end;

Function  TTCPCli.GetRemoteHostName:String;
begin Result:=StrPas(FRemoteHostName); end;

{!!!CAP}
Procedure TTCPCli.SetFinalHostName(Value:String);
begin StrPCopy(FFinalHostName,Value); end;

Function  TTCPCli.GetFinalHostName:String;
begin Result:=StrPas(FFinalHostName); end;
{!!!CAP}

{Versao sincrona foi substituida em 6/98}
Function TTCPCli.GetRemoteHostAddrBlocante:integer; {-1=erro, 1=resolvido}
var aAddr:LongWord; h_addr:PChar; aRemote_Host:Phostent;
begin
  Result:=-1;
  if (StrLen(FRemoteHostName)=0) then
    begin
      raise EPropertyError.Create(sRemoteHostNmInvalid);
      exit;
    end;
  if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,DNS_QUERY);
  {notify begin of DNS query}
  {A synchronous (blocking) query was used here. An async method
   would be better. But since DNS is usually relatively fast
   and is available in most cases, it's ok. Winsock will timeout
   anyway if dns fails.}
  aAddr:=LongWord(inet_addr(FRemoteHostName)); {Converte se expresso em forma numerica}
  if (aAddr=INADDR_NONE) then
    begin {endereco em forma de nome de host, resolve por DNS}
      aRemote_Host:=gethostbyname(FRemoteHostName); {resolve name}
      if aRemote_Host=Nil then      {host not found}
        begin
          if Assigned(FOnConnectStatus) then
            begin
              FOnConnectStatus(Self,HOST_NOT_FOUND); {name query failed}
              CleanUp;
            end
            else CantFindHostError; {abort calls cleanup}
        end
        else begin
          h_addr:=aRemote_Host^.h_addr_list^;
          Remote_addr.sin_addr.S_un_b.s_b1:=h_addr[0]; {Copia os 4 bytes do IP}
          Remote_addr.sin_addr.S_un_b.s_b2:=h_addr[1];
          Remote_addr.sin_addr.S_un_b.s_b3:=h_addr[2];
          Remote_addr.sin_addr.S_un_b.s_b4:=h_addr[3];
          if Assigned(FOnConnectStatus) then
            FOnConnectStatus(Self,HOST_FOUND); {notify success}
          {aRemote_Host^.h_addr:=Remote_Host^.h_addr_list^;}
          Result:=1;
        end;
    end
    else begin {endereco em forma numerica. copia}
      Remote_addr.sin_addr.S_addr:=aAddr;
      if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,HOST_FOUND); {notify success}
      Result:=1;
    end;
end;

(* Async GetRemoteHost()*)
Procedure TTCPCli.WMHostByName(var Msg:TMessage);
var h_addr:PChar; Ok:Bool;
begin
  if TimeOutCnt>0 then {Stop timeout timer}
    begin
      KillTimer(Handle,0);
      TimeOutCnt:=0;
    end;
  fResolvendoDNSAssync:=FALSE;
  if Msg.lParamHi = 0 then
  begin
    h_addr:=Remote_Host.h_addr_list^;
    Remote_addr.sin_addr.S_un_b.s_b1:=h_addr[0]; {Copia os 4 bytes do IP}
    Remote_addr.sin_addr.S_un_b.s_b2:=h_addr[1];
    Remote_addr.sin_addr.S_un_b.s_b3:=h_addr[2];
    Remote_addr.sin_addr.S_un_b.s_b4:=h_addr[3];
    if Assigned(FOnConnectStatus) then
      FOnConnectStatus(Self,HOST_FOUND); {notify success}
    Ok:= GetServicePort;
    if Ok then Ok:=CreateClientSocket;
    if Ok then Ok:=ConnectToServer; {make connection request}
    if Ok then
      FTcpState:=CONNECTING {ok? wait for host answer}
    else
      CloseClientSocket;
  end
  else begin
    if Assigned(FOnConnectStatus) then
    begin
      FOnConnectStatus(Self,HOST_NOT_FOUND); {name query failed}
      CleanUp;
    end
    else CantFindHostError; {abort calls cleanup}
  end;
end;

{Versao asyncrona de GetRemoteHostAddr}
Function TTCPCli.GetRemoteHostAddrAssincrono:integer; {-1=erro,0=resolvendo, 1=resolvido}
var aAddr:LongWord;
begin
  Result:=-1;
  if (StrLen(FRemoteHostName)=0) then
    begin
      raise EPropertyError.Create(sRemoteHostNmInvalid);
      exit;
    end;
  if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,DNS_QUERY);
  aAddr:=LongWord(inet_addr(FRemoteHostName)); {Converte se expresso em forma numerica}
  if (aAddr=INADDR_NONE) then
  begin
    fHndTskDNSAssync:=WSAAsyncGetHostByName(Handle,WM_HOST_BY_NAME,FRemoteHostName,
        PChar(@Remote_Host),MAXGETHOSTSTRUCT);
    if fHndTskDNSAssync=0 then
    begin
      Result:=-1;
      exit;  {Error on WSAAsyncGetHostByName()}
    end;
    fResolvendoDNSAssync:=TRUE;
    TimeOutCnt:=FTimeOutSecs;
    if TimeOutCnt>0 then
      SetTimer(Handle,0,1000,nil);    {Start connect timeout count}
    Result:=0;
  end
  else begin
    Remote_addr.sin_addr.S_addr:=aAddr;
    if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,HOST_FOUND); {notify success}
    Result:=1;
  end;
end;

Function TTCPCli.CreateClientSocket:Boolean;
begin
  CreateClientSocket:=FALSE;
  ClientSocket:=socket(PF_INET,SOCK_STREAM,IPPROTO_IP);
  If ClientSocket=INVALID_SOCKET then Abort(sCantCreateClientSocket)
    else begin
      if WSAAsyncSelect(ClientSocket,Handle,WM_CLIENT_SELECT,FD_CONNECT)<>0 then
        Abort('WSAAsyncSelect:FD_CONNECT')
          else CreateClientSocket:=TRUE;
    end;
end;

Procedure TTCPCli.CloseClientSocket; {Close server socket, if open}
var rc:integer;
begin
  if (ClientSocket<>INV_SOCK) and (ClientSocket<>INVALID_SOCKET) then
    begin
      rc:=CloseSocket(ClientSocket);
      if rc=SOCKET_ERROR then
        begin
          rc:=WSAGetLastError;
          if (rc=WSAENOTSOCK) then {??};
        end;
    end;
  ClientSocket:=INV_SOCK;
  if (FTcpState=CONNECTING) or (FTcpState=CONNECTED) then
    FTcpState:=WSASTARTED;
  if Assigned(FOnCloseSocket) then FOnCloseSocket(Self);
end;

Function TTCPCli.ConnectToServer:boolean;
var rc:integer; 
begin
  Remote_addr.sin_family:=PF_INET;
  Remote_addr.sin_port:=htons(FServerPort);
  rc:=connect(ClientSocket,sockaddr(Remote_Addr),SizeOf(Remote_Addr));
  if (rc=SOCKET_ERROR) then
    begin
      rc:=WSAGetLastError;
      if (rc<>WSAEWOULDBLOCK) then {WSAEWOULDBLOCK is the expected result}
        begin
          CloseClientSocket;       {some other error, close socket}
          ConnectToServer:=FALSE;
          Abort(sErrorOnConnectCmd);
          exit;
        end;
    end;
  TimeOutCnt:=FTimeOutSecs;
  if TimeOutCnt>0 then
     SetTimer(Handle,0,1000,nil);    {Start connect timeout count}
  ConnectToServer:=TRUE;           {Connect request completed}
end;

Procedure TTCPCli.WMTimer(var Msg: TMessage);
begin
  if (TimeOutCnt>0) then Dec(TimeOutCnt);
  if TimeOutCnt=0 then
    begin
      KillTimer(Handle,0);
      if fResolvendoDNSAssync then
      begin
        WSACancelAsyncRequest(fHndTskDNSAssync); {Cancel pending Async request}
        fResolvendoDNSAssync:=FALSE;
        if Assigned(FOnConnectStatus) then //ago09:
          begin
            FOnConnectStatus(Self,HOST_NOT_FOUND); {name query failed}
            CleanUp;
          end
          else CantFindHostError;
      end
      else begin
        CloseClientSocket;
        FTcpState:=WSASTARTED;
        if Assigned(FOnConnectTimeout) then FOnConnectTimeout(Self);
      end;
    end
    else if Assigned(FOnConnectTimeoutCount) then FOnConnectTimeoutCount(Self,TimeOutCnt);
      //else MessageBeep(0); {So bipa se usr nao capturou evento}
end;

{retorna IPO (tipo 200|246|189|31 ) se conseguir resolver nome ou '' se nao conseguir}
const
  SocksDPassaNome=#0+#0+#0+#1; {Se ret este IP invalido, cliente nao tem DNS. Passa o nome pro server}

function TTCPCli.GetFinalHostIP:String;
var aAddr:LongWord; h_addr:PChar; i,err:integer; Proxy_Host:Phostent;
begin
  Result:='';
  if (StrLen(FFinalHostName)=0) then
    begin
      raise EPropertyError.Create('nome de host final invalido');
      exit;
    end;
  Proxy_Host:=Nil;
  aAddr:=LongWord(inet_addr(FFinalHostName)); {Converte se expresso em forma numerica}
  if (aAddr=INADDR_NONE) then
    begin {endereco em forma de nome de host, resolve por DNS}
      Proxy_Host:=gethostbyname(FFinalHostName); {resolve name}
      if Proxy_Host=Nil then  {host not found}
        begin
          err:=WSAGetLastError;
          if err=WSANO_DATA then {Em testes no Win95, WSANO_DATA é retornado se nao tem DNS}
            begin
              Result:=SocksDPassaNome;
              exit;
            end
            else begin {WSAHOST_NOT_FOUND - Tem DNS mas o FFinalHostName nao foi encontrado}
              if Assigned(FOnConnectStatus) then
                begin
                 FOnConnectStatus(Self,HOST_NOT_FOUND); {name query failed}
                 CleanUp;
                end
                else Abort('Nome Host final invalido'); {abort calls cleanup}
            end;
        end
        else begin
          h_addr:=Proxy_Host^.h_addr_list^;
          Result:='';
          for i:=0 to 3 do Result:=Result+h_addr[i];  {Copia os 4 bytes do IP}
        end;
    end
    else begin {endereco em forma numerica. copia}
      h_addr:=PChar(@aAddr);
      Result:='';
      for i:=0 to 3 do Result:=Result+h_addr[i];  {Copia os 4 bytes do IP}
    end;
end;

const
  CRLF=#13#10;

Procedure TTCPCli.WMClientSelect(var Msg: TMessage);
var aSocket:tSOCKET; c,L,rc:integer; Ok:Boolean; ch:Char;
    aFinalHostIP:String[4];
{!!!CAP}
{Buff:array[0..1059] of char; S:String;}
{Om: Tirei a linha acima para evitar tanto uso do stack. Substitui por
 ProxyBuff e ProxyStr, vars membro do componente}
begin
  aSocket:=Msg.wParam;
  rc:=WSAGetSelectError(Msg.lParam); {Error code}
  case Loword(Msg.lParam) of
    FD_CONNECT: if rc=0 then
    begin
      if TimeOutCnt>0 then KillTimer(Handle,0);  {Stop timeout timer}
      TimeOutCnt:=0;
      Ok:=WSAAsyncSelect(ClientSocket,Handle,WM_CLIENT_SELECT,FD_WRITE or FD_READ or FD_CLOSE)=0;
      if Ok then
        begin
          if Assigned(FOnConnect) then FOnConnect(Self); {notify user}
          FTcpState:=CONNECTED;
          {!!!CAP}
          if fUsaHttpProxy then
            begin
              fEstadoHttpProxy:=1;
              fProxyAuthResult:=0;
            end
            else fEstadoHttpProxy:=0;
          {!!!CAP}
          if fUsaSocks then fEstadoSocks:=1 else fEstadoSocks:=0;

          if Assigned(FOnConnectStatus) then
            FOnConnectStatus(Self,HOST_CONNECTED); {notify begin of DNS query}
        end
        else Abort('WSAAsyncSelect');
    end;
    FD_WRITE: begin {Ready to send data}
          {!!!CAP}
      if (WSAGetSelectError(Msg.lparam)<>0) then Error('Erro:FD_WRITE')
        else begin
          if (fEstadoHttpProxy=1) then
          begin
             ProxyStr:='CONNECT '+GetFinalHostName+':'+IntToStr(fFinalPort)+' HTTP/1.0'+CRLF+
              'User-Agent: TCPCli/1.0'+CRLF+
              'Host: '+GetFinalHostName+CRLF+
              'Proxy-Connection: Keep-Alive'+CRLF;
             {OFR 26/8/97 - authenticacao basica no servidor proxy}
             if (fHttpProxyAuth<>'') then
               ProxyStr:=ProxyStr+'Proxy-Authorization: Basic '+Base64Encode(fHttpProxyAuth)+CRLF;
             {/OFR}
             ProxyStr:=ProxyStr+CRLF;     {Linha vazia p/ terminar header p/ proxy}
             StrPCopy (ProxyBuff,ProxyStr);
             c := StrLen (ProxyBuff);
             L:= SendData(ProxyBuff,c);
             if (L<c) then
               raise Exception.Create('não foram todos os bytes do cabecalho http proxy');
          end
          else if (fEstadoSocks=1) then
          begin
            {Manda cabecalho socks para servidor. a descricao do Sock pode ser encontrada
            em: ftp://ftp.nec.com/pub/socks/socks4/SOCKS4.protocol
               |VN|CD|DSTPORT|    DSTIP      | USERID             |NULL|
            ex: 4  1   0 80    200 246 189 31  98 97 122 117 99 97 0 (www.tecepe.com.br)}
             aFinalHostIP:=GetFinalHostIP;
             if (aFinalHostIP<>'') then
               begin
                 ProxyStr:=#4+#1+Chr(Hi(fFinalPort))+Chr(Lo(fFinalPort))+aFinalHostIP+fSocksUser+#0;
                 {se nao foi possivel resolver nome localmente, a versao 4a do protocolo socks
                 especifica passar o nome a diante para o servidor, para que ele resolva, como segue}
                 if aFinalHostIP=SocksDPassaNome then ProxyStr:=ProxyStr+FFinalHostName+#0;
                 c:=Length(ProxyStr);
                 Move(ProxyStr[1],ProxyBuff[0],c);
                 L:=SendData(ProxyBuff,c);
                 if (L<c) then raise Exception.Create('não foram todos os bytes do cabecalho socks');
               end
               else CloseClientSocket; {Host nao encontrado, desiste}
          end
          else if Assigned(FOnReadyToSendData) then FOnReadyToSendData(Self);
        end;
    end;
    FD_READ : begin {data received}
      {!!!CAP}
      if (fEstadoHttpProxy>0) then {>0 significa que em transacao de proxy http}
        begin
          c:=1024;
          L:=RecvData(ProxyBuff,c);
          for c:=0 to L do
            begin
              //a resposta do proxy é do tipo:
              // HTTP/1.1 200 Connection established  #13#10
              // Proxy-Agent: AnalogX Proxy #13#10
              // #13#10
              case fEstadoHttpProxy of
                1: begin ProxyStr:=ProxyBuff[c]; Inc(fEstadoHttpProxy); end;
                2..4,8: begin ProxyStr:=ProxyStr+ProxyBuff[c]; Inc(fEstadoHttpProxy); end; { Le o texto 'HTTP'}
                5: if ProxyBuff[c]<>' ' then Inc(fEstadoHttpProxy);
                6: if ProxyBuff[c] =' ' then Inc(fEstadoHttpProxy);
                7: if ProxyBuff[c]<>' ' then
                    begin Inc(fEstadoHttpProxy); ProxyStr:=ProxyStr+ProxyBuff[c]; end;
                9: begin
                     ProxyStr:=ProxyStr+ProxyBuff[c];
                     if CompareStr(ProxyStr, 'HTTP200')=0 then
                       begin
                         Inc(fEstadoHttpProxy);
                         fProxyAuthResult:=0;
                       end
                       else begin
                         if CompareStr(ProxyStr, 'HTTP407')=0 then
                           begin
                             Inc(fEstadoHttpProxy);
                             fProxyAuthResult:=1;
                           end
                           else fEstadoHttpProxy:=-1;
                       end;
                   end;
                10: begin if ProxyBuff[c]=#10 then Inc (fEstadoHttpProxy) end; {aguarda duplo LF}
                11: if ProxyBuff[c]=#10 then {chegou duplo LF}
                      begin
                        if fProxyAuthResult>0 then
                        begin
                          if (fHttpProxyAuth='') then //x (ProxyUser = nil) or (ProxyPass = nil) then
                            fEstadoHttpProxy:= -1
                           else begin
                             fEstadoHttpProxy:= 1000;
                             //aqui deveria mostrar dlg de autenticacao no proxy
                             Raise Exception.Create('Erro na autenticação no proxy http');
                             (*
                             AuthentDlg.ShowModal;
                             AuthentDlg.Usuario.GetTextBuf (Buff, 100);
                             ProxyUser^ := StrPas (Buff);
                             if Length (ProxyUser^) > 0 then
                             begin
                               AuthentDlg.Password.GetTextBuf (Buff, 100);
                               ProxyPass^ := StrPas (Buff);
                               StopClient;
                               StartClient;
                             end
                             else
                               ProxyConectando := -1; *)
                           end;
                        end
                        else fEstadoHttpProxy := 0; {sinaliza fim da transacao com http proxy}
                      end
                      else begin
                        if ProxyBuff[c]<>#13 then Dec(fEstadoHttpProxy);
                      end;
              end; {case}
            end; {for}
          if (fEstadoHttpProxy<0) then Exception.Create('Erro na conexao com proxy');
          if (fEstadoHttpProxy=0) and 
            Assigned(FOnReadyToSendData) then FOnReadyToSendData(Self); {gera evento p/ cliente mandar pau}
        end  {if fEstadoHttpProxy > 0 ..}
        else if (fEstadoSocks>0) then {>0 significa que em transacao de com srv Socks}
        begin
          { Resposta do srv Socks tem o formato:
             1    2     3   4    5    6    7    8
           +----+----+----+----+----+----+----+----+
           | VN | CD | DSTPORT |      DSTIP        |
           onde VN=0, CD deve ser 90 para acesso granted}
          c:=1024;
          L:=RecvData(ProxyBuff,c);
          for c:=0 to L-1 do
            begin
              ch:=ProxyBuff[c];
              case fEstadoSocks of
                1: if (ch<>#0) then    {VN deve ser 0 na resposta do srv}
                     begin
                       fEstadoSocks:=0;
                       if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,SOCKS_ERROR);
                       CloseClientSocket;
                     end;
                2: if (ch<>#90) then {CD deve ser 90}
                     begin
                       fEstadoSocks:=0;
                       if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,SOCKS_ERROR);
                       CloseClientSocket;
                     end;
                {ignora os outros bytes do cabecalho (DstPort e DstIP)}
              end;
              inc(fEstadoSocks);
              if (fEstadoSocks>=9) then
                begin
                  fEstadoSocks:=0; {sinaliza fim da transacao com srv socks}
                  if Assigned(FOnReadyToSendData) then FOnReadyToSendData(Self); {gera evento para cliente mandar pau}
                  break;
                end;
            end; {for c..}
        end  {if (fEstadoSocks>0)}
        else begin {(fEstadoHttpProxy=0) e (fEstadoSocks=0). Trata dados recebidos chamando o evento}
          if (WSAGetSelectError(Msg.lparam)<>0) then Error('Erro: FD_READ')
            else if Assigned(FOnDataReceived) then FOnDataReceived(Self);
        end;
    end;
    FD_CLOSE:
      begin
        {!!!CAP 26/08/97}
        if Assigned(FOnDataReceived) then FOnDataReceived(Self); {Pode ainda ter dados para ler}
        {/!!!CAP}
        FTcpState:=WSASTARTED;
        if Assigned(FOnConnectStatus) then FOnConnectStatus(Self,CLOSED);  {notify begin of DNS query}
        CloseClientSocket;                {remote (server) closed the socket}
      end;
  end;   {case lParam}
end;

{returns bytes read count (or SOCKET_ERROR)}
Function TTCPCli.RecvData(aBuff:PChar;aLen:integer):integer;
var actualL:integer;
begin
  {$IFDEF WIN32}
  actualL:=recv(ClientSocket,aBuff^,aLen,0);
  {$ELSE WIN32}
  actualL:=recv(ClientSocket,aBuff,aLen,0);
  {$ENDIF WIN32}
  if actualL=SOCKET_ERROR then actualL:=0;
  RecvData:=actualL;
end;

{returns bytes sent count}
Function TTCPCli.SendData(aBuff:PChar;aLen:integer):integer;
var aL,rc:integer;
begin
  if ClientSocket=INV_SOCK then
    Result:=0 {SOCKET_ERROR}  {invalid socket}
    else begin
      {$IFDEF WIN32}
      aL:=send(ClientSocket,aBuff^,aLen,0);  {send data.}
      {$ELSE WIN32}
      aL:=send(ClientSocket,aBuff,aLen,0);  {send data.}
      {$ENDIF WIN32}
      if aL=SOCKET_ERROR then {An error ocurred durinf send}
        begin
          rc:=WSAGetLastError;
          if (rc=WSAEWOULDBLOCK) then   {expected result if buffer full}
             if Assigned(FOnStopSending) then FOnStopSending(Self)
               else if Assigned(FOnSendError) then FOnSendError(Self);
          aL:=0;   {Sent 0 bytes}
        end;
      Result:=aL;
    end;
end;

{--------------- Register the components -----------------}
Procedure Register;
begin
  RegisterComponents('Omar',[TTCPSrv,TTCPCli]);
end;

end.

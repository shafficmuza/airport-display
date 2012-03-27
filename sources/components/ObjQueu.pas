unit Objqueu;  {Object Queue Component}
{©Copr 1996 Omar F. Reis}

{$INCLUDE OmVerDefines.inc}

interface
uses
  SysUtils, WinTypes, WinProcs, Messages, Classes,
  {$IFDEF VER5UP} // Delphi 5+
  typinfo;
  {$ELSE VER5UP}
  DsgnIntf;      {EPropertyError}
  {$ENDIF VER5UP}

const
  MAXPOINTERS=16380;

type
  {Array de objectos}
  PObjBuffer=^TObjBuffer;
  TObjBuffer=Array[0..MAXPOINTERS-1] of TObject;

  TObjQueue=class(TComponent)
  private
    Buffer:PObjBuffer;
    Head,Tail:integer;    {Head=onde vai entrar o proximo, Tail=Proximo a sair}
    {fields}
    FBufferSize:LongInt;   {numero de objectos}
    FOnBufferOk :TNotifyEvent;
    FOnBufferOverflow:TNotifyEvent;
    fOwnObjects:boolean;
    {access methods}
    Procedure SetBufferSize(Value:LongInt);
    Function  GetCount:integer; {Number of bytes available}
    {private methods}
    Procedure DisposeBuffer;
    Procedure AllocBuffer;     {Alllocate buffer at run time}
    Procedure IncTail;         {advance Tail}
    function GetEmpty:Boolean;
    Function GetFull:Boolean;
    function GetNotEmpty:Boolean;
  protected
  public
    Constructor Create(AOwner:TComponent); override;
    Destructor  Destroy;                   override;
    Procedure   PutObj(O:TObject);         virtual;
    Function    GetObj:TObject;            virtual;
    Function    PeekNextObj:TObject;       virtual; {Pega obj, mas sem tomar posse}
    Procedure   Flush;                     virtual;
  published
    Property Count:integer read GetCount;
    Property BufferSize:LongInt read FBufferSize write SetBufferSize;
    Property OnBufferOverflow:TNotifyEvent read FOnBufferOverflow write FOnBufferOverflow;
    Property Empty:boolean read GetEmpty;
    Property NotEmpty:boolean read GetNotEmpty;
    Property Full:boolean read GetFull;
    Property OwnObjects:Boolean read fOwnObjects write fOwnObjects default TRUE;
  end;

  THugeObjQueue=class(TComponent)
  private
    QueueList:TList;
    fOwnObjects:boolean;
    Procedure SetOwnObjects(Value:Boolean);
  public
    Constructor Create(AOwner:TComponent); override;
    Destructor  Destroy;                   override;
    Procedure   PutObj(O:TObject);         virtual;
    Function    GetObj:TObject;            virtual;
    Function    PeekNextObj:TObject;       virtual; {Pega obj, mas sem tomar posse}
    Function    Count:LongInt;
    Property    OwnObjects:Boolean read fOwnObjects write SetOwnObjects default TRUE;
    Function    QueueCount:Integer;
  end;

procedure Register;

implementation

uses
  Debug;

procedure Register;
begin
  RegisterComponents('Omar', [TObjQueue,THugeObjQueue]);
end;

{------------------------ TObjQueue. ------------------------------}

const
  InObj:integer=0;
  OutObj:integer=0;

Constructor TObjQueue.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  Buffer:=Nil;
  FBufferSize:=0;
  Head:=0;
  Tail:=0;
  OwnObjects:=TRUE;
end;

Destructor  TObjQueue.Destroy;
begin
  DisposeBuffer;
  inherited Destroy;
end;

Procedure TObjQueue.DisposeBuffer;
var i:integer;
begin
  if Assigned(Buffer) then
    begin
      if fOwnObjects then for i:=0 to FBufferSize-1 do
        if Assigned(Buffer^[i]) then Buffer^[i].Free; {desaloca os objetos}
      FreeMem(Buffer,FBufferSize*SizeOf(TObject));
    end;
  Buffer:=Nil;
end;

Procedure TObjQueue.AllocBuffer;
var Sz:word;
begin
  Sz:=FBufferSize*SizeOf(TObject);
  GetMem(Buffer,Sz);
  FillChar(Buffer^,Sz,#0);
  Head:=0;
  Tail:=0;
end;

Function  TObjQueue.GetCount:integer;
begin
  Result:=Head-Tail;
  if Result<0 then Result:=FBufferSize+Result;
end;

Procedure TObjQueue.PutObj(O:TObject);
var OldObj:TObject;
begin
  if not Assigned(Buffer) then
    raise Exception.Create('No buffer available');
  OldObj:=Buffer^[Head];    {Salva obj antigo no head}
  Buffer^[Head]:=O;         {Poe o novo}
  inc(Head);                {avanca head}
  if Head>=FBufferSize then Head:=0; {deu a volta?}
  if (Head=Tail) then         {Head=Tail after PutObj-->overflow}
    begin
      IncTail; {avanca tail}
      if Assigned(FOnBufferOverflow) then FOnBufferOverflow(Self);
      if fOwnObjects and Assigned(OldObj) then
        OldObj.Free;     {destroy obj sobrescrito}
    end;
  //inc(InObj); //TESTE
  //MostraIntVar(1,InObj);
end;

{Flush buffer contents, disposing any objects}
Procedure TObjQueue.Flush;
var i:integer;
begin
  if Assigned(Buffer) then for i:=0 to FBufferSize-1 do
    if Assigned(Buffer^[i]) then
      begin
        if fOwnObjects then Buffer^[i].Free; {desaloca os objetos}
        Buffer^[i]:=Nil;
      end;
  Tail:=0;
  Head:=0;
end;

Procedure TObjQueue.IncTail;
begin
  inc(Tail);
  if Tail>=FBufferSize then Tail:=0;
end;

{Pega ptr do Obj sem remove-lo da fila}
Function  TObjQueue.PeekNextObj:TObject;
begin
  if (Tail<>Head) then Result:=Buffer^[Tail]
    else Result:=Nil;
end;


Function  TObjQueue.GetObj:TObject;
begin
  Result:=Nil;
  if (Tail<>Head) then
    begin
      Result:=Buffer^[Tail]; {Give Obj to the caller}
      Buffer^[Tail]:=Nil;    {Set it to nil, so it won't be disposed in a flush()}
      IncTail;
      //inc(OutObj); //TESTE
      //MostraIntVar(2,OutObj);
    end;
end;

{Note:This action will destroy current buffer contents}
Procedure TObjQueue.SetBufferSize(Value:LongInt);
begin
  if Value<>FBufferSize then
    begin
      if (Value>MAXPOINTERS) or (Value<=100) then
        raise EPropertyError.Create('Fila deve conter entre 100 e 16380 e objetos');
      DisposeBuffer;     {Destroy old buffer}
      FBufferSize:=Value;
      AllocBuffer;
    end;
end;

function TObjQueue.GetEmpty:Boolean;
begin
  Result:=(Tail=Head);
end;

function TObjQueue.GetNotEmpty:Boolean;
begin
  Result:=(Tail<>Head);
end;

Function TObjQueue.GetFull:Boolean;
begin
  Result:=(Count>=FBufferSize-1);
end;

{--------------------- THugeObjQueue. ---------------------------}

Constructor THugeObjQueue.Create(AOwner:TComponent);
var aQueue:TObjQueue;
begin
  inherited Create(AOwner);
  QueueList:=TList.Create;
  aQueue:=TObjQueue.Create(Self); {Make 1st Queue. Always keep at least one Queue}
  aQueue.BufferSize:=MAXPOINTERS;
  aQueue.OwnObjects:=fOwnObjects;
  QueueList.Add(aQueue);
  fOwnObjects:=TRUE;
end;

Destructor THugeObjQueue.Destroy;
var i:integer;
begin
  for i:=0 to QueueList.Count-1 do TObjQueue(QueueList.Items[i]).Free;
  QueueList.Free;
  inherited Destroy;
end;

Procedure THugeObjQueue.PutObj(O:TObject);
var aQueue:TObjQueue;
begin
  aQueue:=TObjQueue(QueueList.Last);
  if (aQueue.Count>=MAXPOINTERS-1) then {Last Queue full, make a new one and Add to the List}
    begin
      aQueue:=TObjQueue.Create(Self);
      aQueue.BufferSize:=MAXPOINTERS;
      aQueue.OwnObjects:=fOwnObjects;
      QueueList.Add(aQueue);
    end;
  aQueue.PutObj(O);
end;

Function  THugeObjQueue.GetObj:TObject;
var aQueue:TObjQueue;
begin
  Result:=Nil;
  aQueue:=TObjQueue(QueueList.First);
  {If Queue[0] is empty, dispose and go to the next, if any}
  if (aQueue.Count=0) and (QueueList.Count>1) then
    begin
      aQueue.Free;          {dispose empty Queue }
      QueueList.Delete(0);
      aQueue:=TObjQueue(QueueList.First); {get next Items[0]}
    end;
  Result:=aQueue.GetObj;
end;

Function  THugeObjQueue.PeekNextObj:TObject;
var aQueue:TObjQueue;
begin
  Result:=Nil;
  aQueue:=TObjQueue(QueueList.First);
  {If Queue[0] is empty, dispose and go to the next, if any}
  while (aQueue.Count=0) and (QueueList.Count>1) do
    begin
      aQueue.Free;
      QueueList.Delete(0);  {delete Items[0]}
      aQueue:=TObjQueue(QueueList.First); {pega novo Items[0]}
    end;
  Result:=aQueue.PeekNextObj;
end;

Function  THugeObjQueue.Count:LongInt;
var i:integer; C:LongInt;
begin
  C:=0; {Sum all Counts}
  For i:=0 to QueueList.Count-1 do
    C:=C+TObjQueue(QueueList.Items[i]).Count;
  Result:=C;
end;

{Return number of Queues}
Function  THugeObjQueue.QueueCount:Integer;
begin
  Result:=QueueList.Count;
end;

Procedure THugeObjQueue.SetOwnObjects(Value:Boolean);
var i:integer;
begin
  if Value<>fOwnObjects then
    begin
      For i:=0 to QueueList.Count-1 do
        TObjQueue(QueueList.Items[i]).OwnObjects:=Value;
      fOwnObjects:=Value;
    end;
end;

end.


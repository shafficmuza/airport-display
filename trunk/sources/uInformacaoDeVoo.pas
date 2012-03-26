Unit uInformacaoDeVoo;  //bancos de dados internos do airport display
// (c)copr 2002-2008 Omar Reis
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/


interface

uses
  Classes,SysUtils,Dialogs,Windows;

var
  Locais:TStringList=nil;
  CodStatus:TStringList=nil;
  Airlines:TStringList=nil;
  ExcluirAirlines:TStringList=nil;
  ExcluirStatus:TStringList=nil;
  DestaqueStatus:TStringList=nil;

type
  TFlighType=(ftArrival,ftDeparture);
  TSIVVendorType=(svNone, svSolari, svInfraero);

  TInformacaoDeVoo=class
  private
    fAirLine: String;
    fVoo:     String;
    fDestino,
    fOrigem:    String;
    fEstimatedTime:     String;
    fSomeTime:     String;
    fStatus:  String;
    fEscala1: String;
    fEscala2: String;
    fEscala3: String;
    fEscala4: String;
    fGate:    String;
    fEsteira: string;

    fIndexVoo: integer;
    fFlighType: TFlighType;
    fIxNoDisplayVirtual: integer;
    FVisivel: boolean;
    fDestacado: boolean;
    fStatusMsgEng: String;
    fStatusMsgPor: String;
    fVooParceria:TInformacaoDeVoo;
    fBox: string;
    fMatricula:String;
    fCheckin1:String;
    fCheckin2:String;

    procedure SetAirLine(const Value: String);
    procedure SetEscala1(const Value: String);
    procedure SetEscala2(const Value: String);
    procedure SetEscala4(const Value: String);
    procedure SetEstimatedTime(const Value: String);
    procedure SetfEscala3(const Value: String);
    procedure SetGate(const Value: String);
    procedure SetIndexVoo(const Value: integer);
    procedure SetDestino(const Value: String);
    procedure SetSomeTime(const Value: String);
    procedure SetVoo(const Value: String);
    procedure SetFlighType(const Value: TFlighType);
    procedure SetOrigem(const Value: String);
    procedure SetVisivel(const Value: boolean);
    procedure SetStatus(const Value: String);
    procedure SetStatusMsgEng(const Value: String);
    procedure SetStatusMsgPor(const Value: String);
    procedure SetEsteira(const Value: string);
    procedure SetBox(const Value: string);
    procedure SetCheckin1(const Value: string);
    procedure SetCheckin2(const Value: string);
    procedure SetMatricula(const Value: string);
  public
    Changed:boolean;
    SIVVendor:TSIVVendorType;
    Constructor Create;
    Destructor  Destroy;   override;
    Procedure   ClearVoo;
    function    GetAsString:String;
    function    GetVooParceria:TInformacaoDeVoo;
    procedure   SetVooParceria(aVooParc:TInformacaoDeVoo);
    function    GetLinhaCheckins:String;

    Property    IndexVoo:integer     read fIndexVoo    write SetIndexVoo;   //indice do voo no bd interno
    Property    FlighType:TFlighType read fFlighType   write SetFlighType;
    Property    IxNoDisplayVirtual:integer  read fIxNoDisplayVirtual write fIxNoDisplayVirtual;  //indice do voo no display (-1=invisivel)

    Property    AirLine: String      read fAirLine     write SetAirLine;    //campos
    Property    Voo:     String      read fVoo         write SetVoo;
    Property    Destino: String      read fDestino     write SetDestino;
    Property    Origem:  String      read fOrigem      write SetOrigem;
    Property    Escala1: String      read fEscala1     write SetEscala1;
    Property    Escala2: String      read fEscala2     write SetEscala2;
    Property    Escala3: String      read fEscala3     write SetfEscala3;
    Property    Escala4: String      read fEscala4     write SetEscala4;
    Property    SomeTime:String      read fSomeTime    write SetSomeTime;  //ST na infraero TODO: O que que é isso ?
    Property    EstimatedTime:String read fEstimatedTime write SetEstimatedTime;
    Property    Gate:    String      read fGate        write SetGate;
    Property    Box:     string      read fBox         write SetBox;
    Property    Checkin1:string      read fCheckin1    write SetCheckin1;
    Property    Checkin2:string      read fCheckin2    write SetCheckin2;
    Property    Matricula:string     read fMatricula   write SetMatricula;
    Property    Esteira: string      read fEsteira     write SetEsteira;
    Property    StatusCode:  String  read fStatus      write SetStatus;
    Property    StatusMsgPor:String  read fStatusMsgPor write SetStatusMsgPor;
    Property    StatusMsgEng:String  read fStatusMsgEng write SetStatusMsgEng;
    Property    VooParceria:TInformacaoDeVoo read fVooParceria;
    Property    Visivel:boolean      read fVisivel     write fVisivel;
    Property    Destacado:boolean    read fDestacado   write fDestacado;
  end;

  // TVooDeferedUpdate salva voos alterados, para serem exibidos depois com deferimento, um por vez
  TVooDeferedUpdate=class
    NVooDisplayReal:integer;  //num de voo no display real
    Voo:TInformacaoDeVoo;
  end;

  TListVooDeferedUpdate=class(TList)
    Procedure AddVooAlterado(aNVoo:integer; aVoo:TInformacaoDeVoo);                       //..se ainda não estava
    function  GetVooParaAtualizacao(var aNVoo:integer; var aVoo:TInformacaoDeVoo):boolean;
  end;

function CodLocal2Local(const aCodigo:String; aVoo:TInformacaoDeVoo):String;   //ret nome da cidade por extenso
function CodStatus2Status(const aCodigo:String):String; //ret tipo 'Cancelado|Cancelled'
//filtros
function AirlineExcluida(const aCodigo:String):boolean; //ret
function StatusExcluido(const aCodigo:String):boolean;
function StatusDestacado(const aCodigo:String):boolean;

implementation

procedure ExcluiComentariosEVazios(aSL:TStringList);
var i:integer; S:String;
begin
  for i:=aSL.Count-1 downto 0 do
    begin
      S:=Trim(aSL.Strings[i]);
      if (S='') or (S[1]=';') then aSL.Delete(i)
        else begin
          if (S<>aSL.Strings[i]) then aSL.Strings[i]:=S; //garante que trimado
        end;
    end;
end;

Procedure LoadTabelasDeCodigos;

  Procedure ErroNaLeituraDe(const aArq:String);
  begin MessageDlg('Erro na leitura de '+aArq, mtInformation,[mbOk], 0); end;

begin {LoadTabelasDeCodigos}
  try
    Locais.LoadFromFile('locais.txt');
    Locais.Duplicates:=dupIgnore;
    Locais.Sorted:=TRUE;
  except
    ErroNaLeituraDe('locais.txt');
  end;

  try
    CodStatus.LoadFromFile('status.txt');
    CodStatus.Duplicates:=dupIgnore;
    CodStatus.Sorted:=TRUE;
  except
    ErroNaLeituraDe('status.txt');
  end;

  try
    Airlines.LoadFromFile('airlines.txt');
    Airlines.Duplicates:=dupIgnore;
    Airlines.Sorted:=TRUE;
  except
    ErroNaLeituraDe('airlines.txt');
  end;

  try
    ExcluirAirlines.LoadFromFile('excluir.txt');
    ExcluirAirlines.Duplicates:=dupIgnore;
    ExcluirAirlines.Sorted:=TRUE;
    ExcluiComentariosEVazios(ExcluirAirlines);
  except
    ErroNaLeituraDe('excluir.txt');
  end;

  try
    ExcluirStatus.LoadFromFile('excluirstatus.txt');
    ExcluirStatus.Duplicates:=dupIgnore;
    ExcluirStatus.Sorted:=TRUE;
    ExcluiComentariosEVazios(ExcluirStatus);
  except
    ErroNaLeituraDe('excluirstatus.txt');
  end;

  try
    DestaqueStatus.LoadFromFile('destaquestatus.txt');
    DestaqueStatus.Duplicates:=dupIgnore;
    DestaqueStatus.Sorted:=TRUE;
    ExcluiComentariosEVazios(DestaqueStatus);
  except
    ErroNaLeituraDe('destaquestatus.txt');
  end;
end;

//converte local em cidade para Solari
function CodLocal2Local(const aCodigo:String; aVoo:TInformacaoDeVoo ):String;
begin
  if aVoo.SIVVendor=svSolari then //Solari tem que traduzir o nome do local
    begin
      Result:=Locais.Values[aCodigo];
      if (Result='') then Result:=aCodigo;
    end
    else Result:=aCodigo; //infraero já entrega o codigo trafuzido
end;

function CodStatus2Status(const aCodigo:String):String;
begin
  Result:=CodStatus.Values[aCodigo];
  if Result='' then Result:=aCodigo;
end;

function AirlineExcluida(const aCodigo:String):boolean; //ret
var ix:integer;
begin
  Result:=ExcluirAirlines.Find(aCodigo,ix);
end;

function StatusExcluido(const aCodigo:String):boolean;
var ix:integer;
begin
  Result:=ExcluirStatus.Find(aCodigo,ix);
end;

function StatusDestacado(const aCodigo:String):boolean;
var ix:integer;
begin
  Result:=DestaqueStatus.Find(aCodigo,ix);
end;

{ TInformacaoDeVoo }

constructor TInformacaoDeVoo.Create;
begin
  inherited;
  fIndexVoo:=0;
  ClearVoo;
  fIxNoDisplayVirtual:=-1;   //-1 = nao visivel
  fVisivel:=FALSE;
  fDestacado:=FALSE;
  SIVVendor:=svNone;
end;

procedure TInformacaoDeVoo.ClearVoo;
begin
  fAirLine:='';
  fEstimatedTime:='';
  fSomeTime:='';
  fStatus:='';
  fStatusMsgEng:='';
  fStatusMsgPor:='';
  fGate:='';
  fBox:='';
  fCheckin1:='';
  fCheckin2:='';
  fEsteira:=' ';
  fVoo:='';
  fDestino:='';
  fEscala1:='';
  fEscala2:='';
  fEscala3:='';
  fEscala4:='';
  Changed:=FALSE;
  fVooParceria:=nil;
  SIVVendor:=svNone;
end;

function  TInformacaoDeVoo.GetAsString:String;
var escalas:string;
begin
  escalas:='';
  if fEscala1<>'' then escalas:=fEscala1;
  if fEscala2<>'' then begin if escalas<>'' then escalas:=escalas+'/'; escalas:=escalas+fEscala2; end;
  if fEscala3<>'' then begin if escalas<>'' then escalas:=escalas+'/'; escalas:=escalas+fEscala3; end;
  if fEscala4<>'' then begin if escalas<>'' then escalas:=escalas+'/'; escalas:=escalas+fEscala4; end;

  Result:=fAirLine+' '+fVoo+
    ' to:'+fDestino+
    ' est:'+fEstimatedTime+
    ' gate:'+fGate+
    ' box:'+fBox+
    ' checkin1:'+fCheckin1+
    ' checkin2:'+fCheckin2+
    ' esc:'+escalas+
    ' est:'+fEsteira+
    ' st:'+fStatus;  //TODO: melhorar esse report...
  if Assigned(fVooParceria) then
    Result:=Result+' parc:'+fVooParceria.AirLine;
end;


destructor TInformacaoDeVoo.Destroy;
begin
  inherited;
end;

procedure TInformacaoDeVoo.SetAirLine(const Value: String);
begin
  if (fAirLine<>Value) then
    begin
      Changed:=TRUE;
      fAirLine := Value;
    end;
end;

procedure TInformacaoDeVoo.SetEscala1(const Value: String);
begin
  if (fEscala1<>Value) then
    begin
      Changed:=true;
      fEscala1 := Value;
    end;
end;

procedure TInformacaoDeVoo.SetEscala2(const Value: String);
begin
  if (fEscala2<>Value) then
    begin
      Changed:=true;
      fEscala2 := Value;
    end;
end;

procedure TInformacaoDeVoo.SetEscala4(const Value: String);
begin
  if (fEscala4<>Value) then
    begin
      Changed:=true;
      fEscala4 := Value;
    end;
end;

procedure TInformacaoDeVoo.SetEstimatedTime(const Value: String);
begin
  if (fEstimatedTime<>Value) then
    begin
      Changed:=true;
      fEstimatedTime := Value;
    end;
end;

procedure TInformacaoDeVoo.SetfEscala3(const Value: String);
begin
  if (fEscala3<>Value) then
    begin
      Changed:=true;
      fEscala3 := Value;
    end;
end;

procedure TInformacaoDeVoo.SetFlighType(const Value: TFlighType);
begin
  if (fFlighType<>Value) then
    begin
      Changed:=true;
      fFlighType := Value;
    end;
end;

procedure TInformacaoDeVoo.SetGate(const Value: String);
begin
  if (fGate<>Value) then
    begin
      Changed:=true;
      fGate := Value;
    end;
end;

procedure TInformacaoDeVoo.SetIndexVoo(const Value: integer);
begin
  if (fIndexVoo<>Value) then
    begin
      Changed:=true;
      fIndexVoo := Value;
    end;
end;

procedure TInformacaoDeVoo.SetOrigem(const Value: String);
begin
  if (fOrigem<>Value) then
    begin
      Changed:=true;
      fOrigem := Value;
    end;
end;

procedure TInformacaoDeVoo.SetDestino(const Value: String);
begin
  if (fDestino<>Value) then
    begin
      Changed:=true;
      fDestino := Value;
    end;
end;

procedure TInformacaoDeVoo.SetSomeTime(const Value: String);
begin
  if (fSomeTime<>Value) then
    begin
      Changed:=true;
      fSomeTime := Value;
    end;
end;

procedure TInformacaoDeVoo.SetVoo(const Value: String);
begin
  if (fVoo<>Value) then
    begin
      Changed:=true;
      fVoo := Value;
    end;
end;

procedure TInformacaoDeVoo.SetVisivel(const Value: boolean);
begin
  if (FVisivel<>Value) then
    begin
      FVisivel := Value;
      //Changed:=true;   //precisa ??
    end;
end;

procedure TInformacaoDeVoo.SetStatus(const Value: String);
begin
  if (fStatus<>Value ) then
    begin
      fStatus := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetStatusMsgEng(const Value: String);
begin
  if (fStatusMsgEng<>Value) then
    begin
      fStatusMsgEng := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetStatusMsgPor(const Value: String);
begin
  if (fStatusMsgPor<>Value) then
    begin
      fStatusMsgPor := Value;
      Changed:=true;
    end;
end;

function TInformacaoDeVoo.GetVooParceria: TInformacaoDeVoo;
begin
  Result:=fVooParceria;
end;

procedure TInformacaoDeVoo.SetVooParceria(aVooParc: TInformacaoDeVoo);
begin
  if (fVooParceria<>aVooParc) then
    begin
      fVooParceria:=aVooParc;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetEsteira(const Value: string);
begin
  if (fEsteira<>Value) then
    begin
      fEsteira := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetBox(const Value: string);
begin
  if (fBox<>value) then
    begin
      fBox := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetCheckin1(const Value: string);
begin
  if (fCheckin1<>Value) then
    begin
      fCheckin1 := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetCheckin2(const Value: string);
begin
  if (fCheckin2<>Value) then
    begin
      fCheckin2 := Value;
      Changed:=true;
    end;
end;

procedure TInformacaoDeVoo.SetMatricula(const Value: string);
begin
  if (fMatricula<>Value) then
    begin
      fMatricula := Value;
      Changed:=true;
    end;
end;



function TInformacaoDeVoo.GetLinhaCheckins: String;
var LetraTerminal1,NumCheckin1,NumCheckin2:String;
begin
  Result:='';
  if (fCheckin1<>'') then
    begin
      LetraTerminal1:=fCheckin1[1];
      NumCheckin1:=Copy(fCheckin1,2,2);
    end;
  if (fCheckin2<>'') then
    begin
      NumCheckin2:=Copy(fCheckin2,2,2);
    end;
  if (fCheckin1<>'') or (fCheckin2<>'') then
    begin
      Result:='Check-in Asa '+LetraTerminal1+' '+NumCheckin1+' '+NumCheckin2;  //tipo 'Checkin Asa A 35/42'
    end;
end;

{ TListVooDeferedUpdate }

procedure TListVooDeferedUpdate.AddVooAlterado(aNVoo: integer; aVoo: TInformacaoDeVoo);
var aVDU:TVooDeferedUpdate; i:integer;
begin
  //ve se já estava na lista
  for i:=0 to Count-1 do
    begin
      aVDU:=TVooDeferedUpdate(Items[i]);
      if Assigned(aVoo) and (aVDU.Voo=aVoo) and (aVDU.NVooDisplayReal=aNVoo) then exit;     // se já estava não põe duas vezes
    end;
  //se aqui, ainda não está. põe..
  aVDU:=TVooDeferedUpdate.Create;
  aVDU.Voo:=aVoo;
  aVDU.NVooDisplayReal:=aNVoo;
  Insert(0,aVDU); //fila tipo FIFO (last in first out)
end;

function TListVooDeferedUpdate.GetVooParaAtualizacao(var aNVoo: integer; var aVoo: TInformacaoDeVoo): boolean;
var aVDU:TVooDeferedUpdate;
begin
  result:=false;
  if Count>0 then
    begin
      aVDU:=TVooDeferedUpdate(Items[Count-1]); //pega ultimo. Fila tipo FIFO (last in first out)
      Delete(Count-1);
      aNVoo := aVDU.NVooDisplayReal;
      aVoo  := aVDU.Voo;
      aVDU.Free;
      result:=true;
    end;
end;

initialization
  Locais:=TStringList.Create;
  CodStatus:=TStringList.Create;
  Airlines:=TStringList.Create;
  ExcluirAirlines:=TStringList.Create;
  ExcluirStatus:=TStringList.Create;
  DestaqueStatus:=TStringList.Create;
  LoadTabelasDeCodigos;
end.


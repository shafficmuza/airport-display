unit HttpSrv2;   //HttpSrv component (versão 2) ©Copr 97-08 Omar Reis
// main object: THttpSrvCmpNew (the server)
// Esse componente web server é surpreendentemente funcional e confiável.
// Usado no ppesweb, para servir xmls, ZIDs, paginas pessoais web etc
// Suplantou o HttpSrv (HttpSrvC.pas) original em funcionalidade e escalabilidade
//   - este componente é totalmente asyncrono. Nenhum methodo deve travar (no syncronous sql queries)...
//   - uma aplicação pode interferir no resultado de um pedido de varias formas:
//      1- Tratando o beforeDispatch //??é isso mesmo... checar..
//      2- criando um action e tratando o execute
//      3- Tratando o OnRequest (isso pega todos os requests não atendido por actions
//      4- Se o OnRequest não tratar, pode opcionalmente, localizar no sistema de arquivos (file server com cache)
//  Programa de testes desse componente em \dpr32\lixo\httplixo.dpr !!

//------------------------------------------------------------------
// Histórico:
//  Data    ver  Autor   Descricao
//  12/9/97  1.0 Om  Versao inicial
//  27/07/00 1.1 Om  Corrigi bug em PostField, fazendo o httpDecode() somente no valor do campo
//  mar08:       Om: mexi alguma coisa....
//  mai08:       Om: adição de cache de arquivos, keep-alive etc
//  set08:       Om: restabeleci funcionamento quebrado em mai08: (multiplos sendstringlists() sucessivos no mesmo response)
//  dez08:       Om: Evento OnLogHit
//  abr10:       Om: inclui DEFINE pra lingua das mensagens
//  fev11:       Om: Some comments and identations. Added Uri2ActionName()
//  mar11:       Om: added Context.bUsing_UPE_auth
//  fev11:       Om: Alteração na ordem da auth ( 1-UPE 2-basic auth )
//  mar11:       Om: Correção na parte de data do cache..
//------------------------------------------------------------------

interface

uses
  WinTypes,WinProcs,Classes,SysUtils,
  Controls,Forms,ExtCtrls,
  Debug,
  SockCmp,
  Base64,
  Buftcp,
  OmHttpSrvCache;  //mai08

{$DEFINE ENGLISH_ERROR_MESSAGES}  //lingua das mensagens de erro do servidor http ( en ou pt )

const
  TAMSENDBUFFER=10000;
  sErroOcorreu ='<h3>Um erro ocorreu</h3>';
  sContact     ='Contacte ';
  sHttpResponseVersion='HTTP/1.0';  // 'HTTP/1.0' ou 'HTTP/1.1'
  CRLF=#13#10;


type
  // estado de um contexto de um http request
  TEstadoHttp=( ehRECVHEADER, ehRECVENTITYBODY, ehSENDRESPONSE, ehRECICLED ); //estado de um contexto http
  THttpMethod=(hmGET, hmPOST, hmAny, hmHead);

  // Contem o contexto de uma transacao http com um cliente
  // os contextos contem dados do request e da response. São atachados a conexões no Accept

  THttpSrvCmpNew=class; //forward def

  THttpContext=Class(TObject)
  private
    fParentServer:THttpSrvCmpNew; //servidor parent desse contxt
    fCriationTime:TDateTime;
    fEstado:TEstadoHttp;
    RcvLinha:String;
    ReqContentLenght:integer;
    fAuthUser,fAuthPassword:String[30];
    fEntityBodyPtr:integer;
    fbUsing_UPE_auth:boolean;  //using query string embedded authentication (UPE) ?

    Procedure ParseAuthentication;
    Function  GetAuthUser:String;
    Function  GetAuthPassword:String;
    Function  GetCookie:String;
    Procedure SetCookie(Value:String);
    Function  GetContentType:String;
    Procedure SetContentType(Value:String);
    Function  GetSeconds:integer;
    procedure ResetContext;
    function  IsHttp11: boolean;
    procedure ParseAuthEmbeddedInQueryString;
  protected
    fRespHeaderSent:Boolean;
    Function CheckRequestHeaders:Boolean;
    {access methods}
    Procedure InitResponseHeaderOk;
  public
    {state vars}
    fBrowserRequestKeepAlive:boolean; //Om: mai08: indica se browser solicitou manter a conexão aberta pra mais transações
    fRequestsServed:integer;          //Contagem de requests servidor por este contexto (e por essa conexão) por keep-alive
    {Request fields}
    HttpRequestVersion:String;        //'HTTP/1.0' ou 'HTTP/1.1' Om: mai08:
    CompleteURI  :String;             // contem URI + QueryString
    URI          :String;             //So a parte antes do '?' (se houver)
    QueryString  :String;             // a parte da uri depois do ?
    IPAddr       :String;             // numeric format
    Method       :String;             // GET, POST etc
    Extension    :String;             // mai08:Om: file extension tipo '.xml' ou '.htm'
    ReqReferer   :String;             // dez08: referer pra log
    ReqUserAgent :String;             //        browser id
    ReqFirstLine :String;             //        complete http request line [0] tipo 'GET /omar?PARM=value HTTP/1.0'
    {Response}
    fTotalizaContentLengthDeStrings:boolean;
    RespContentLenght:integer;
    RespContentType:String;
    RespCookie:String;    // cookie que enviado na response
    RespStatus:integer;
    NoCache:boolean;
    KeepOpen:boolean;     // Se true, mantem conexao aberta apos tratamento do Request
    ObjectPtr:TObject;    // ObjectPtr serve para associar um objeto ao contexto (usado apenas pelo usuário do componente)
    {header sets}
    RequestHeader:TStringList;
    ResponseHeader:TStringList;
    {EntityBody}
    EntityBody:PChar;         //entity body (aka post fields). Alocado dinameicamente
    EntityBodySz:integer;     //tamanho da mem alocada em EntityBody
    StrEntityBody:String;     //EntityBody (PostFields) no formato String

    IfModifiedSince:String;   //conteudo do request header 'if modified since'
    LastModified:TDateTime;   //conteudo do request header 'last modified'

    fLogEnvio:TStringList;    //jan 05 - [opcional] salva o response header e os dados do content (se for texto. Stream não salva..)

    Constructor Create(aParent:THttpSrvCmpNew);
    Destructor  Destroy; override;
    Function    GetRequestField(const aFieldName:String):String;
    Function    GetQueryField(const aFieldName:String):String;
    Function    GetCookieField(const aFieldName:String):String;
    Function    GetPostField(const aFieldName:String):String;
    Function    GetInputField(const aFieldName:String):String;
    function    IsXML: boolean;      //true se extensão da URI for '.xml'
    procedure   AddCookie(const aCookie:String);
    procedure   AtivaLogEnvio;                    //ativa log de todos os strings enviados. Chamar antes de um SendStrings p.e.
    function    AsCombinedLogFormatLine:String;   //web log line in COMBINED format (analog analiser can read this)

    Property    Seconds:integer     read GetSeconds;                  // segundos desde a criação
    Property    Estado:TEstadoHttp  read fEstado;                     // ehRECVHEADER, ehRECVENTITYBODY, ehSENDRESPONSE, ehRECICLED
    Property    Cookie:String       read GetCookie write SetCookie;
    Property    ContentType:String  read GetContentType write SetContentType;  // tipo 'text/html'
    Property    AuthUser:String     read GetAuthUser;                          // basic authentication (request fields)
    Property    AuthPassword:String read GetAuthPassword;
    Property    bUsing_UPE_auth:boolean read fbUsing_UPE_auth; 
  end;

  THttpActionItem=class;

  // coleção de actions implementados pela app
  THttpActionItems=class(TCollection)
  private
    fHttpSrv:THttpSrvCmpNew;
    function  GetActionItem(Index: Integer): THttpActionItem;
    procedure SetActionItem(Index: Integer; Value: THttpActionItem);
  protected
    function  GetAttrCount: Integer; override;
    function  GetAttr(Index: Integer): string; override;
    function  GetItemAttr(Index, ItemIndex: Integer): string; override;
    function  GetOwner: TPersistent; override;
    procedure SetItemName(Item:TCollectionItem); override;
  public
    constructor Create(aHttpSrv:THttpSrvCmpNew;ItemClass:TCollectionItemClass);
    function Add:THttpActionItem;
    property HttpSrv: THttpSrvCmpNew read fHttpSrv;
    property Items[Index: Integer]:THttpActionItem read GetActionItem write SetActionItem; default;
  end;

  THTTPMethodCall=procedure(Sender:TObject; ClientID:integer; Context:THttpContext; var Handled: Boolean) of object;

  THttpActionItem=class(TCollectionItem)
  private
    FOnAction:THTTPMethodCall;
    FPathInfo:string;
    FName: string;
    procedure SetOnAction(Value: THTTPMethodCall);
  public
    constructor Create(Collection: TCollection); override;
    destructor  Destroy; override;
    procedure   AssignTo(Dest: TPersistent); override;
    function    GetDisplayName: string; override;
    procedure   SetDisplayName(const Value: string); override;
  published
    property Name:string read GetDisplayName write SetDisplayName;
    property PathInfo:string read FPathInfo write FPathInfo;
    property OnAction:THTTPMethodCall read FOnAction write SetOnAction;
  end;

  THttpSrvNotify=Procedure (Sender:TObject; ClientID:integer; Context:THttpContext) of Object;

  THttpSrvExceptionText=procedure(Sender:TObject; var Text:String) of object;

  // the web server component - compacto e sincronizado
  THttpSrvCmpNew = class(TComponent)
  private
    fTCPSrv:TBufTCPSrv;
    fExceptionText:THttpSrvExceptionText;
    fOnHttpRequest:THTTPMethodCall; //era THttpSrvNotify;
    fOnHttpAccept :THttpSrvNotify;
    fOnHttpClose  :TServerNotify;
    fEmailWebMaster:String;
    fOnBeforeHttpRequest:THTTPMethodCall;
    fContexts:Array[1..MAXCLIENTS] of THttpContext;
    fClientTimeOut:integer; {seconds for timeout}
    fTimeoutTimer:TTimer;
    fSendBuffer:Array[0..TAMSENDBUFFER] of char;
    fServerName:String;
    fActions:THttpActionItems;
    fServeFiles:Boolean;
    fRootFileDirectory:String;
    fMaxEntityBodySize:integer; // Max tamanho de conteudo em posts ( -1 = sem limite (default) )
    fCache:TOmHttpSrvCache;     // cache de arquivos
    fKeepConectionsAlive: boolean;
    fOnHttpDispatchEnd: TServerNotify;
    fbKeepConnAlive: boolean;
    fDefaultFileName: string;
    fbUseCachedForFiles: boolean;
    fOnLogHit: THttpSrvNotify;     // mai08: Om: cache de arquivos

    Function  GetServerPort:integer;
    Procedure SetServerPort(Value:integer);
    Function  GetStarted:Boolean;
    Procedure SetStarted(Value:Boolean);
    Procedure SetClientTimeOut(Value:integer);
    function  GetContext(index:integer):THttpContext;
    function  GetClientsHighMark:integer;
    function  GetContextCount:integer;
    function  GetAction(Index: Integer): THttpActionItem;
    procedure SetActions(Value: THttpActionItems);
    function  ActionByURI(const AName: string): THttpActionItem;
    Procedure DispatchRequest(ClientID:integer);
    Procedure ServeFileStream(ClientID:integer);
    Procedure HttpSrvHandleException(ClientID:integer);
    procedure SetKeepConectionsAlive(const Value: boolean);
    procedure CheckFinishRequest(ClientID: integer);
    function  GetFileCacheRunning: boolean;
    procedure SetFileCacheRunning(const Value: boolean);
  protected
    Procedure HttpTimeoutTimer(Sender:TObject);
    Procedure HttpDataReceived(Sender:TObject;ClientID:integer);
    Procedure HttpCloseSocket(Sender:TObject;ClientID:integer);
    Procedure HttpClientAccept(Sender:TObject;ClientID:integer;aIP:LongWord;aAddr:String);
    Procedure HttpQueueEnd(Sender:TObject;ClientID:integer);
    Procedure InternalSendString(ClientID:integer;const aLinha:String);
  public
    Hits:integer;
    Errors:integer;
    CountUseCached304:integer;
    CountFilesServed:integer;

    Constructor Create(aOwner:TComponent); override;
    Destructor  Destroy;                   override;
    Procedure   SendErrorResponse(ClientID:integer;Code:integer);
    Procedure   SendErrorMessage(ClientID:integer;Code:integer;const aMsg:String);
    Procedure   SendErrorMessageWithContentType(ClientID:integer;Code:integer;const aContentType,aMsg:String);
    Procedure   GotoLocation(ClientID:integer;const aLocation:String);
    Procedure   SendString(ClientID:integer;const aLinha:String);
    Procedure   SendStream(ClientID:integer;aStream:TStream;const aContentType:String);
    Procedure   SendStringList(ClientID:integer;SL:TStringList);
    Procedure   SendStrings(ClientID:integer;SL:TStrings);
    Procedure   DoCloseClient(ClientID:integer);
    Procedure   ClearServerStatistics;
    //cache  fns
    function    GetCacheFileCount: integer;
    function    GetCacheMemorySize:integer;
    procedure   ClearCache;
    function    Uri2ActionName(const aUri:String):String; //case sensitive

    Property    ClientsHighMark:integer              read GetClientsHighMark;
    Property    Contexts[index:integer]:THttpContext read GetContext;
    Property    Count:integer                        read GetContextCount;
    property    Action[Index: Integer]: THttpActionItem read GetAction;
    Property    CacheFileCount:integer               read GetCacheFileCount;
    Property    KeepConectionsAlive:boolean read fKeepConectionsAlive write SetKeepConectionsAlive; //mai08: otimização keep alive
  published
    Property ServerPort:integer read GetServerPort write SetServerPort;
    Property Started:boolean    read GetStarted    write SetStarted;
    Property ClientTimeOut:integer read fClientTimeOut write SetClientTimeOut;
    Property ServerName:String  read fServerName   write fServerName;  {ex: 'www.tecepe.com.br'}
    {Envents}
    Property OnBeforeHttpRequest:THTTPMethodCall read fOnBeforeHttpRequest write fOnBeforeHttpRequest;
    Property OnHttpRequest:THTTPMethodCall       read fOnHttpRequest       write fOnHttpRequest;
    Property OnHttpAccept :THttpSrvNotify        read fOnHttpAccept        write fOnHttpAccept;
    Property OnHttpClose:TServerNotify           read fOnHttpClose         write fOnHttpClose;
    Property OnLogHit:THttpSrvNotify             read fOnLogHit            write fOnLogHit; //web logger

    Property OnHttpDispatchEnd:TServerNotify read fOnHttpDispatchEnd write fOnHttpDispatchEnd;  //mai08:Om:
    Property OnExceptionText:THttpSrvExceptionText read fExceptionText write fExceptionText;
    property Actions: THttpActionItems read fActions            write SetActions;
    // ServeFiles:boolean indica se servidor deve servir arquivos (aposto a servir apenas aplicações do usr)
    // isso serve para integrar aplicações e arquivos de media no mesmo servidor (como requer o JavaScript) 
    Property ServeFiles:boolean        read fServeFiles         write fServeFiles default FALSE;
    Property RootFileDirectory:String  read fRootFileDirectory  write fRootFileDirectory;
    Property EmailWebMaster:String     read fEmailWebMaster     write fEmailWebMaster;
    Property MaxEntityBodySize:integer read fMaxEntityBodySize  write fMaxEntityBodySize default -1; //default -1 = tam ilimitado
    Property DefaultFileName:string    read fDefaultFileName    write fDefaultFileName;     //for files only.. tipo 'default.htm'
    Property Option_KeepConnectionsAlive:boolean read fbKeepConnAlive     write fbKeepConnAlive     default false;
    Property Option_UseCachedForFiles:boolean    read fbUseCachedForFiles write fbUseCachedForFiles default true;
    Property Option_FileCacheRunning:boolean      read GetFileCacheRunning write SetFileCacheRunning default true;
  end;

procedure Register;

//Procedure SetaShortMonthNamesEmIngles; //obsoleto. Implementei data em ingles em OmFormataDataHTTP()
function  OmHTTPEncode(const AStr: String): String; //mesmo que HttpApp.pas
function  OmHTTPDecode(const AStr: String):String;
Function  OmFormataDataHTTP(aD:TDateTime):String; //tem que ser em ingles pro Nokia WAP Gateway aceitar !

implementation {----------------------------------------}

Function GetURIExtension(const aURI:String):String;  //baseado em SysUtils.pas ExtractFileExt() ex: '/dir/omar.xml?parm1=val1'  --> '.xml'
var i:integer;
begin
  i:=LastDelimiter(':/.',aURI);  //pega ultima ocorrencia de um dos chars em ':/.'
  if (i>0) and (aURI[i] = '.') then Result:=Copy(aURI,i,MaxInt) //se for um pto, copia extenção
    else Result := '';
end;

{Fns extraidas de HTTPApp.pas}

function OmHTTPDecode(const AStr: String):String;
var Sp,Rp,Cp:PChar;
begin
  SetLength(Result,Length(AStr));
  Sp:=PChar(AStr);
  Rp:=PChar(Result);
  while Sp^<>#0 do
  begin
    if not (Sp^ in ['+','%']) then Rp^:=Sp^
    else if Sp^='+' then Rp^:=' '
    else begin
      inc(Sp);
      if Sp^='%' then Rp^:='%'
      else begin
        Cp := Sp;
        Inc(Sp);
        Rp^:=Chr(StrToInt(Format('$%s%s',[Cp^, Sp^])));
      end;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  SetLength(Result,Rp-PChar(Result));
end;

function OmHTTPEncode(const AStr: String): String;
const NoConversion = ['A'..'Z','a'..'z','*','@','.','_','-'];
var Sp,Rp:PChar;
begin
  SetLength(Result,Length(AStr)*3);
  Sp := PChar(AStr);
  Rp := PChar(Result);
  while Sp^ <> #0 do
  begin
    if Sp^ in NoConversion then Rp^ := Sp^
    else
      if Sp^ = ' ' then Rp^ := '+'
      else begin
        FormatBuf(Rp^, 3, '%%%.2x', 6, [Ord(Sp^)]);
        Inc(Rp,2);
      end;
    Inc(Rp);
    Inc(Sp);
  end;
  SetLength(Result,Rp-PChar(Result));
end;

const
  ctHTML='text/html';
  ctTXT ='text/plain';
  ctGIF ='image/gif';
  ctJPG ='image/jpeg';
  ctZIP ='application/x-zip-compressed';
  ctBIN ='application/octet-stream';
  DefaultServerName:String='Server: TecepeSrv/2.0';

type
  THttpErrCodeRec=record
    EC:integer;
    Reason:String[50];
  end;

const
  MAXERRCODES=15;
  HttpErrCodes:Array[1..MAXERRCODES] of THttpErrCodeRec=(
  {$IFDEF ENGLISH_ERROR_MESSAGES}
  (EC:200 ; Reason:'OK'),                           //en messages
  (EC:201 ; Reason:'Created'),
  (EC:202 ; Reason:'Accepted'),
  (EC:204 ; Reason:'No Content'),
  (EC:301 ; Reason:'Moved Permanently'),
  (EC:302 ; Reason:'Moved Temporarily'),
  (EC:304 ; Reason:'Not Modified'),
  (EC:400 ; Reason:'Bad Request'),
  (EC:401 ; Reason:'Unauthorized'),
  (EC:403 ; Reason:'Forbidden'),
  (EC:404 ; Reason:'Document Not Found'),
  (EC:500 ; Reason:'Internal Server Error'),
  (EC:501 ; Reason:'Not Implemented'),
  (EC:502 ; Reason:'Bad Gateway'),
  (EC:503 ; Reason:'Service Unavailable'));
  {$ELSE ENGLISH_ERROR_MESSAGES}
  (EC:200 ; Reason:'OK'),                           //pt messages
  (EC:201 ; Reason:'Criado'),
  (EC:202 ; Reason:'Aceito'),
  (EC:204 ; Reason:'Sem conteúdo'),
  (EC:301 ; Reason:'Mudou Permanentemente'),
  (EC:302 ; Reason:'Mudou Temporariamente'),
  (EC:304 ; Reason:'Não Modificado'),
  (EC:400 ; Reason:'Pedido inválido'),
  (EC:401 ; Reason:'Não autorizado'),
  (EC:403 ; Reason:'Acesso negado'),
  (EC:404 ; Reason:'Documento não Encontrado'),
  (EC:500 ; Reason:'Erro Interno do Servidor'),
  (EC:501 ; Reason:'Não Implementado'),
  (EC:502 ; Reason:'Gateway Inválido'),
  (EC:503 ; Reason:'Serviço não disponível'));
  {$ENDIF ENGLISH_ERROR_MESSAGES}

function GetErrorMessage(Code:integer):String; //isso retorna tipo '200 OK' ou '404 Document Not Found'
var i:integer;
begin
  for i:=1 to MAXERRCODES do if Code=HttpErrCodes[i].EC then
    begin
      Result:=IntToStr(Code)+' '+HttpErrCodes[i].Reason;
      exit;
    end;
  Result:='Código Inválido: '+IntToStr(Code);
end;

const MonthNames:Array[1..12] of String=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

function MonthToInt(const aMonth:String):integer;
var i:integer;
begin
  for i:=1 to 12 do
    if (aMonth=MonthNames[i]) then
      begin
        Result:=i;
        exit;
      end;
  Result:=0; //0=invalid month..
end;

// mar11: extraído da rfc2616
// HTTP applications have historically allowed three different formats for the
// representation of date/time stamps:
//   Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
//   Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
//   Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format
Function OmDecodeHTTPDateStr(const aDtStr:String):TDatetime;
var SL:TStringList; aToken:String; c:char; i,dd,mm,yy,hh,nn,ss:integer;
const Separators=[',',' ',':','-'];
begin
  Result:=0;  //=invalid
  SL:=TStringList.Create;
  aToken:='';
  for i:=1 to Length(aDtStr) do //parse date into string list
    begin
      c:=aDtStr[i];
      if (c in Separators) and (aToken<>'') then //separators
        begin
          SL.Add(aToken); //add token
          aToken:='';
        end
        else aToken:=aToken+c; //token char. Add.
    end;
  if (aToken<>'') then SL.Add(aToken); //add last token

  //   0    1  2   3   4  5  6   7
  // 'Sun, 06 Nov 1994 08:49:37 GMT'
  // 'Sunday, 06-Nov-94 08:49:37 GMT'
  //  format 3 ignored...
  if (SL.Count>=7) then
    begin
      //ignore day of week in SL.Strings[0]
      dd:=StrToIntDef(SL.Strings[1],-1);
      mm:=MonthToInt (SL.Strings[2]);
      yy:=StrToIntDef(SL.Strings[3],-1);
      if (yy>=0) and (yy<100) then // 2 digit year
        begin
          if (yy<50) then yy:=yy+2000 else yy:=yy+1900;
        end;
      hh:=StrToIntDef(SL.Strings[4],-1);
      nn:=StrToIntDef(SL.Strings[5],-1);
      ss:=StrToIntDef(SL.Strings[6],-1);
      //ignore 'GMT' token in SL.Strings[7]
      if (dd>0) and (mm>0) and (yy>0) and (hh>-1) and (nn>-1) and (ss>-1) then //sanity test
        Result := EncodeDate(yy,mm,dd)+EncodeTime(hh,nn,ss,00);
    end;
  SL.Free;
end;

// Poe data no formato requerido pelo protocolo http}
// 'Wed, 01 Dec 2004 13:45:52 GMT';  //ret igual ao formato de data do IIS
Function OmFormataDataHTTP(aD:TDateTime):String; //tem que ser em ingles pro Nokia WAP Gateway aceitar !
var DS:integer; aMes:string; d,m,y:word;

   function Int2StrDD(k:integer):String; //formata int em str com no minimo 2 digitos
   begin
     Result:=IntToStr(k);
     if Length(Result)=1 then Result:='0'+Result;
   end;

begin
  DecodeDate(aD,y,m,d);
  DS:=DayOfWeek(aD);
  case DS of
    1: Result:='Sun';
    2: Result:='Mon';
    3: Result:='Tue';
    4: Result:='Wed';
    5: Result:='Thu';
    6: Result:='Fri';
    7: Result:='Sat';
  else Result:='???';
  end;

  case m of
   1: aMes:='Jan';
   2: aMes:='Feb';
   3: aMes:='Mar';
   4: aMes:='Apr';
   5: aMes:='May';
   6: aMes:='Jun';
   7: aMes:='Jul';
   8: aMes:='Aug';
   9: aMes:='Sep';
  10: aMes:='Oct';
  11: aMes:='Nov';
  12: aMes:='Dec';
  else aMes:='???';
  end;

  Result:=Result+', '+Int2StrDD(d)+' '+aMes+' '+IntToStr(y)+' '+FormatDateTime('hh:nn:ss',aD)+' GMT';
  //era Result:=FormatDateTime('ddd, dd-mmm-yyyy hh:mm:ss "GMT"',aD)
end;

//Gambiarra pra porra do Nokia Gateway funcionar (só aceita datas em ingles)
Procedure SetaShortMonthNamesEmIngles;
begin
  ShortMonthNames[ 1]:='Jan';
  ShortMonthNames[ 2]:='Feb';
  ShortMonthNames[ 3]:='Mar';
  ShortMonthNames[ 4]:='Apr';
  ShortMonthNames[ 5]:='May';
  ShortMonthNames[ 6]:='Jun';
  ShortMonthNames[ 7]:='Jul';
  ShortMonthNames[ 8]:='Aug';
  ShortMonthNames[ 9]:='Sep';
  ShortMonthNames[10]:='Oct';
  ShortMonthNames[11]:='Nov';
  ShortMonthNames[12]:='Dec';

  ShortDayNames[1]:='Sun';
  ShortDayNames[2]:='Mon';
  ShortDayNames[3]:='Tue';
  ShortDayNames[4]:='Wed';
  ShortDayNames[5]:='Thu';
  ShortDayNames[6]:='Fri';
  ShortDayNames[7]:='Sat';
end;

Function ParseString(const S:String):TStringList;  //parseia S usando ' ' como separador
var i,l:integer; aSL:TStringList; aPalavra:String; C:Char;
begin
  L:=Length(S);
  aSL:=TStringList.create; {Cria lista de palavras}
  aSL.clear;
  //SetLength(aPalavra,1000);
  aPalavra:='';
  for i:=1 to L do
    begin
      C:=S[i];
      if (C<=' ') then {é espaço, separador ou outro caracter qquer}
        begin
          if (aPalavra<>'') then aSL.Add(aPalavra);
          aPalavra:='';
        end
        else aPalavra:=aPalavra+C; {Letra, soma na palavra}
    end;
  if (aPalavra<>'') and (Length(aPalavra)>2) then aSL.Add(aPalavra); {ultima palavra}
  Result:=aSL;
end;

{ THttpActionItem }

constructor THttpActionItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
end;

destructor THttpActionItem.Destroy;
begin
  inherited Destroy;
end;

procedure THttpActionItem.AssignTo(Dest: TPersistent);
begin
  if Dest is THttpActionItem then
  begin
    if Assigned(Collection) then Collection.BeginUpdate;
    try
      with THttpActionItem(Dest) do
      begin
        PathInfo := Self.PathInfo;
      end;
    finally
      if Assigned(Collection) then Collection.EndUpdate;
    end;
  end else inherited AssignTo(Dest);
end;

function THttpActionItem.GetDisplayName: string;
begin
  Result:=FName;
end;

procedure THttpActionItem.SetDisplayName(const Value: string);
var  I: Integer; Action: THttpActionItem;
begin
  if Value<>FName then
  begin
    if Collection<>nil then
      for I := 0 to Collection.Count - 1 do
      begin
        Action:=THttpActionItems(Collection).Items[I];
        if (Action <> Self) and (Action is THttpActionItem) and
          (Value=Action.Name) then
            raise Exception.Create('Duplicate Action name');
      end;
    FName := Value;
    Changed(False);
  end;
end;

procedure THttpActionItem.SetOnAction(Value: THTTPMethodCall);
begin
  FOnAction:=Value;
  Changed(False);
end;

{ THttpActionItems }

constructor THttpActionItems.Create(aHttpSrv:THttpSrvCmpNew;ItemClass:TCollectionItemClass);
begin
  inherited Create(ItemClass);
  fHttpSrv:=aHttpSrv;
end;

function THttpActionItems.Add: THTTPActionItem;
begin
  Result:=THTTPActionItem(inherited Add);
end;

function THttpActionItems.GetActionItem(Index: Integer): THTTPActionItem;
begin
  Result := THTTPActionItem(inherited Items[Index]);
end;

function THttpActionItems.GetAttrCount: Integer;
begin
  Result := 2;
end;

function THttpActionItems.GetAttr(Index: Integer): string;
begin
  case Index of
    0: Result:='Name';
    1: Result:='URI';
  else
    Result := '';
  end;
end;

function THttpActionItems.GetItemAttr(Index, ItemIndex: Integer): string;
begin
  case Index of
    0: Result := Items[ItemIndex].Name;
    1: Result := Items[ItemIndex].PathInfo;
  else
    Result := '';
  end;
end;

function THttpActionItems.GetOwner: TPersistent;
begin
  Result := fHttpSrv;
end;

procedure THttpActionItems.SetActionItem(Index: Integer; Value: THTTPActionItem);
begin
  Items[Index].Assign(Value);
end;

procedure THttpActionItems.SetItemName(Item: TCollectionItem);
var
  I, J: Integer;
  ItemName: string;
  CurItem: THTTPActionItem;
begin
  J := 1;
  while True do
  begin
    ItemName := Format('HttpMethod%d', [J]);
    I := 0;
    while I < Count do
    begin
      CurItem := Items[I] as THTTPActionItem;
      if (CurItem <> Item) and (CompareText(CurItem.Name, ItemName) = 0) then
      begin
        Inc(J);
        Break;
      end;
      Inc(I);
    end;
    if I >= Count then
    begin
      (Item as THTTPActionItem).Name := ItemName;
      Break;
    end;
  end;
end;

{------------  THttpContext. }
Constructor THttpContext.Create(aParent:THttpSrvCmpNew);
begin
  inherited Create;
  fParentServer:=aParent;
  RequestHeader :=TStringList.Create;
  ResponseHeader:=TStringList.Create;
  IPAddr :='';
  ResetContext;    //resset das vars
  KeepOpen:=FALSE;
  fRequestsServed:=0; //contagem de requests servidos por este contexto
end;

// esse ResetContext serve tanto para conexoes novas (no accept) ou recicladas por mecanismo de keep-open
Procedure THttpContext.ResetContext;
begin
  URI:='';
  Extension:='';
  RequestHeader.Clear;
  ResponseHeader.Clear;
  CompleteURI:='';
  QueryString:='';
  RcvLinha   :='';
  fEstado:=ehRECVHEADER;
  Cookie :='';
  //IPAddr :=''; //mantem IP para conexões Keep-Alive (recicled)
  Method :='';
  RespContentLenght:=0;
  RespStatus   :=0;
  ReqReferer   :='';
  ReqUserAgent :='';
  ReqFirstLine :='';

  fTotalizaContentLengthDeStrings:=true; //default é totalizar length das paginas, pra mandar usando keep-alive
  // mas em casos de multiplos stringlists mandados em sequencia não totaliza pois a totalizaçao
  // requer o conhecimento completo do response antes de começar e mandar
  RespContentType:=ctHTML;  //html=default context type
  RespCookie:='';
  // dont mess with KeepOpen here
  ObjectPtr:=nil;
  fRespHeaderSent:=FALSE;
  fCriationTime:=Now;
  fAuthUser:='*';           {* = não inicializado - é o popular anonimo, que não apresentou credenciais via basic auth}
  fAuthPassword:='*';
  fbUsing_UPE_auth:=false;
  EntityBody:=nil;
  StrEntityBody:='';
  NoCache:=FALSE;
  if Assigned(fLogEnvio) then //resseta log
    begin
      fLogEnvio.Free;
      fLogEnvio:=nil;
    end;
  IfModifiedSince:='';
  LastModified:=0;         //0=nunca
  HttpRequestVersion:='';  //Om: mai08:
  fBrowserRequestKeepAlive:=false;
end;

Destructor  THttpContext.Destroy;
begin
  if Assigned(EntityBody) and (EntityBodySz>0) then FreeMem(EntityBody,EntityBodySz); //desaloca entity body (post fields)
  if Assigned(fLogEnvio) then fLogEnvio.Free;

  RequestHeader.Free;
  RequestHeader:=nil;
  ResponseHeader.Free;
  ResponseHeader:=nil;

  inherited Destroy;
end;

//passar aFieldName em minusculas
Function THttpContext.GetRequestField(const aFieldName:String):String;
var S:String; i,p,L:integer; FN:String[50];
begin
  Result:=''; {Not found}
  for i:=0 to RequestHeader.Count-1 do
    begin
      S:=RequestHeader.Strings[i];
      if S='' then exit;        {Fim do header, sai}
      p:=Pos(':',S);
      if (p>0) then    {Se tem ':', pega o que vem antes ie o nome do campo}
        begin
          L:=Length(S);
          FN:=Lowercase(Copy(S,1,p-1));
          inc(p);      {proximo char apos o ':'}
          if (FN=aFieldName) then
            begin
              while (S[p]=' ') and (p<L) do inc(p);  {Pula espacos no inicio do valor}
              Result:=Copy(S,p,L-p+1);               //retorna valor
              exit;
            end;
        end;
    end;
end;

// GetQueryField() é case sensitive!
Function THttpContext.GetQueryField(const aFieldName:String):String;
var p:integer; aField:String; C:Char;
begin
  Result:='';
  if (QueryString='') then exit;     {no QueryStr}
  aField:=aFieldName+'=';
  p:=Pos(aField,QueryString);
  if p>0 then
    begin
      inc(p,Length(aField));
      While p<=Length(QueryString) do
        begin
          C:=QueryString[p];
          if C='&' then break else Result:=Result+C;  //pega ate o final ou ate achar um '&'
          inc(p);
        end;
    end;
end;

Function  THttpContext.GetPostField(const aFieldName:String):String;
var p:integer; aField,aValue:String; C:Char;
begin
  Result:='';
  if (Lowercase(ContentType)<>'application/x-www-form-urlencoded') then exit;    //?
  if (StrEntityBody='') and Assigned(EntityBody) and (EntityBodySz>0) then
    begin
      //Copia de PChar p/ String. Isso é feito aqui se há demanda pelos PostFields
      SetString(StrEntityBody,EntityBody,EntityBodySz);
      //DecodedEntityBody:=HttpDecode(DecodedEntityBody); isso tava dando poblema se valor continha '&'. Tive q fazer o decode apena no valor do campo
      FreeMem(EntityBody,EntityBodySz); //Uma vez copiado, não há necessidade de manter o PChar, desaloca
      EntityBody:=nil;
    end;
  Result:='';
  if (StrEntityBody='') then exit;  {no StrEntityBody}
  //StrEntityBody do tipo 'Campo1=sdfgdsfgsdf&Campo2=sdfsdfsdf&Campo3=sdfsdfsdf'
  aField:=aFieldName+'=';         //forma nome do campo p/ localiza-lo
  p:=Pos(aField,StrEntityBody);   //Procura campo
  if p>0 then                     //achou campo. Pega valor
    begin
      inc(p,Length(aField));      //localiza no inicio do valor, pulando nome do campo
      aValue:='';
      While p<=Length(StrEntityBody) do
        begin
          C:=StrEntityBody[p];
          if (C='&') then break    //terminou campo
            else aValue:=aValue+C; //nop, adiciona char
          inc(p);                  //avança
        end;
      Result:=OmHttpDecode(aValue);  //faz decode do valor
    end;
end;

//GetInputField chama GetPostField(). Se nao tiver, chama GetQueryField
Function  THttpContext.GetInputField(const aFieldName:String):String;
begin
  Result:=GetPostField(aFieldName);
  if Result='' then Result:=GetQueryField(aFieldName);
end;

procedure THttpContext.AddCookie(const aCookie: String); {aCookie do tipo 'CookieName=CookieValue'}
begin
  if (aCookie<>'') then
    begin
      if RespCookie<>'' then RespCookie:=RespCookie+',';
      RespCookie:=RespCookie+aCookie;
    end;
end;

Procedure THttpContext.AtivaLogEnvio;
begin
  if Assigned(fLogEnvio) then fLogEnvio.Free; //desaloca anterior
  fLogEnvio:=TStringList.Create;
end;


//tipo: 'dd/Mmm/yyyy:hh:nn:ss -0300'
Function FormatDatetimeForLog(aD:TDateTime):String; //tem que ser em ingles pro Nokia WAP Gateway aceitar !
var aMes:string; d,m,y:word;

   function Int2StrDD(k:integer):String; //formata int em str com no minimo 2 digitos
   begin
     Result:=IntToStr(k);
     if Length(Result)=1 then Result:='0'+Result;
   end;

begin
  DecodeDate(aD,y,m,d);
  case m of
   1: aMes:='Jan';
   2: aMes:='Feb';
   3: aMes:='Mar';
   4: aMes:='Apr';
   5: aMes:='May';
   6: aMes:='Jun';
   7: aMes:='Jul';
   8: aMes:='Aug';
   9: aMes:='Sep';
  10: aMes:='Oct';
  11: aMes:='Nov';
  12: aMes:='Dec';
  else
    aMes:='???';
  end;
  Result:=Int2StrDD(d)+'/'+aMes+'/'+IntToStr(y)+':'+FormatDateTime('hh:nn:ss',aD)+' -0300';
end;

// Combined log format: ver http://httpd.apache.org/docs/1.3/logs.html#combined
// cliid - user [dd/Mmm/yyyy:hh:nn:ss -0300] "GET /apache_pb.gif HTTP/1.0" status len "referer" "useragent"
// 127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326 "http://www.example.com/start.html" "Mozilla/4.08 [en] (Win98; I ;Nav)"
function  THttpContext.AsCombinedLogFormatLine:String;
var aIP,aUser:string;
begin
  aIP  :=Trim(IPAddr); if aIP='' then aIP:='-';
  aUser:=Trim(AuthUser);
  if (aUser='*') or (aUser='') then aUser:='-'; //esse * do ppesweb é o anonimo
  Result:=aIP+' - '+aUser+' ['+
     FormatDatetimeForLog(Now)+'] '+
     '"'+ReqFirstLine+'" '+
     IntToStr(RespStatus)+' '+
     IntToStr(RespContentLenght)+' "'+
     ReqReferer+'" "'+
     ReqUserAgent+'"';
end;

Function  THttpContext.GetCookieField(const aFieldName:String):String;
var aCookie,aField:String; p:integer; C:Char;
begin
  Result:='';
  aCookie:=GetCookie;
  if Cookie='' then exit;
  aField:=aFieldName+'=';  //procura nome do campo dentro do cookie
  p:=Pos(aField,aCookie);
  if p>0 then
    begin
      inc(p,Length(aField)); //pula campo
      While p<=Length(aCookie) do
        begin
          C:=aCookie[p];
          if C in [',',';'] then break //, ou ; --> acabou esse cookie
            else Result:=Result+C;
          inc(p);
        end;
    end;
end;

Function  THttpContext.GetCookie:String;
begin
  Result:=GetRequestField('cookie');
end;

Procedure THttpContext.SetCookie(Value:String);
begin
  RespCookie:=Value;
end;

Function  THttpContext.GetContentType:String;
begin
  Result:=GetRequestField('content-type');
end;

Procedure THttpContext.SetContentType(Value:String);
begin
  RespContentType:=Value;
end;

Procedure THttpContext.InitResponseHeaderOk;
var sD:string;
begin
  RespStatus:=200; //save resp status
  ResponseHeader.Add(sHttpResponseVersion+' 200 Ok'); //esse server é 1.0 (for now)
  ResponseHeader.Add(DefaultServerName);
  sD:=OmFormataDataHTTP(Now);
  ResponseHeader.Add('Date: '+sD);
  if (RespContentType<>'') then
    ResponseHeader.Add('Content-Type: '+RespContentType);
  //ResponseHeader.Add('Allow-ranges: bytes');
  ResponseHeader.Add('Accept-ranges: bytes');
  if (RespContentLenght<>0) then
    ResponseHeader.Add('Content-Length: '+IntToStr(RespContentLenght));
  if (RespCookie<>'') then  ResponseHeader.Add('Set-Cookie: '+RespCookie);
  if NoCache then  //uma pá de coisa pra prevenir o cache
    begin
      ResponseHeader.Add('Pragma: no-cache');
      ResponseHeader.Add('Cache-Control: no-cache, must-revalidate');    //mar08:
      ResponseHeader.Add('Expires: '+sD);
      ResponseHeader.Add('Last-Modified: '+sD);
    end;
  if fParentServer.fbKeepConnAlive and    //if server police agrees to keep connection..
   fBrowserRequestKeepAlive and    //..browser wants it..
   (RespContentLenght>0) then      //..resp length of previous request was informed (i.e. not a chat style app)
     begin
       ResponseHeader.Add('Connection: keep-alive');  //ok to keep conn alive (for now)
       ResponseHeader.Add('Cache-control: private');  //cada browser faça seu cache. proxies não...
     end;
  if LastModified<>0 then
    ResponseHeader.Add('Last-modified: '+OmFormataDataHTTP(LastModified) );
end;

Function THttpContext.IsHttp11:boolean; //ret true se browser solicitou usando http 1.1 (most cases)
begin
  Result:=(CompareText(HttpRequestVersion,'HTTP/1.1')=0);
end;

Function THttpContext.IsXML:boolean;
begin
  Result:=(Extension='.xml');
end;

// CheckRequestHeaders() é chamado logo após receber o cabeçalho http completo.
// Essa fn checa a validate do cabeçalho e quebra a 1a linha, preenchendo method, URI, QueryStr etc.
// Tambem seta fEstado para ehRECVENTITYBODY no caso de POST (i.e. content-length>0)
Function THttpContext.CheckRequestHeaders:Boolean;
var S:String; SL:TStringList; p:integer; bConnKeep,bConnClose:boolean; aFirstLine:String;
begin
  Result:=FALSE;
  if (RequestHeader.Count>=1) then {Request tem que ter pelo menos 1a linha}
    begin
      aFirstLine:=Trim( RequestHeader.Strings[0] );
      ReqFirstLine :=aFirstLine;  //salva

      if (aFirstLine<>'') then //linha inicial do request
        begin
          SL:=ParseString(aFirstLine);   //1a linha tipo 'GET /xpto.htm?field=value HTTP/1.0'. ParseString() usa ' ' como separador
          if (SL.Count>2) then           //quebra 1a linha do cabeçalho (normalmente tem 3 partes)
            begin
              Method:=Uppercase(SL.Strings[0]); // 'GET' ou 'POST'
              URI:=SL.Strings[1];               // tipo '/xpto.htm?parm1=val1'
              CompleteURI:=URI;                 // salva URL completa
              p:=Pos('?',URI);                  // Query Str vem depois do ?, se houver
              if (p>0) then
                begin
                  QueryString:=OmHTTPDecode(Copy(URI,p+1,Length(URI))); {'field=value' list}
                  URI:=Copy(URI,1,p-1);                               {salva URI sem Query str}
                end
                else QueryString:='';                           //no queryStr
              Extension := Lowercase( GetURIExtension(URI) );   //tipo '.xml'
              HttpRequestVersion:=SL.Strings[2];                //tipo 'HTTP/1.0' ou 'HTTP/1.1'
              Result:=TRUE;                                     //sinaliza q request preenche o padrao http minimo
            end
            else; {Nao esta' no formato GET URL}
          SL.Free;
        end;
    end;
  // faz pre-tratamento do request
  S:=GetRequestField('content-length'); //Ve se tem entity body
  ReqContentLenght:=StrToIntDef(S,0);   //salva tamanho do EntityBody
  if (ReqContentLenght>0) then
    begin
      fEstado:=ehRECVENTITYBODY;         {sim, seta estado para esperar EntityBody}
      EntityBodySz:=ReqContentLenght;    {Salva tamanho da bagaça}
      GetMem(EntityBody,EntityBodySz);   {aloca memoria para receber o entitybody (i.e. os post fields)}
      fEntityBodyPtr:=0;
    end;

  S:=GetRequestField('referer');    //Ve se tem entity body
  ReqReferer:=Trim(S);

  S:=GetRequestField('user-agent');
  ReqUserAgent :=S;

  S:=GetRequestField('connection');
  bConnKeep  := (CompareText(S,'keep-alive')=0);
  bConnClose := (CompareText(S,'close')=0);
  // no http 1.1 as conexões são keep-alive por default (a menos que tenha um 'connection: close' )
  // no http 1.0 as conexões são close (a menos que tenha um 'connection: keep-alive')
  if IsHttp11 then fBrowserRequestKeepAlive:=not bConnClose  // fBrowserRequestKeepAlive= true in most cases
    else fBrowserRequestKeepAlive:=bConnKeep;

  S:=GetRequestField('if-modified-since'); //Ve se tem header if-modified-since
  if (S<>'') then IfModifiedSince:=S;
end;

Function THttpContext.GetSeconds:integer;
begin
  Result:=Trunc((Now-fCriationTime)*24*3600);
end;

Procedure THttpContext.ParseAuthentication; //parse basic authentication header
var Auth:String; p:integer;
begin
  Auth:=GetRequestField('authorization');
  if (Auth<>'') then
    begin
      p:=Pos('basic',lowercase(Auth)); {Tira o 'basic ' (colocado p/ parecer com o http)}
      if p>0 then
        begin
          inc(p,5); {Pula o 'basic'}
          Auth:= Trim(Copy(Auth,p,MAXINT));
          Auth:= Base64Decode(Auth);    {decodifica para obter 'user:password'}
          p:=Pos(':',Auth);
          if p>0 then
            begin
              fAuthUser:=Copy(Auth,1,p-1);
              fAuthPassword:=Copy(Auth,p+1,MAXINT);
            end;
        end;
    end; {/Auth<>''}
end;

// dez08: (  !Casuismo ahead: Search for special QueryString embedded authentication parameters
//  This is one qs value with format '&UPE=b21hcjpwcw=='    //Base64(user:password)'
//  This means that component user cannot use this parm name !
Procedure THttpContext.ParseAuthEmbeddedInQueryString;
var Auth:String; p:integer;
begin
  Auth:=Trim(GetQueryField('UPE'));  //stands for 'User Password Enfoque' ou 'User Password Embedded'  
  if (Auth<>'') then
    begin
      Auth:= Base64Decode(Auth);     //decodifica para obter 'user:password'
      p:=Pos(':',Auth);
      if p>0 then
        begin
          fAuthUser     :=Copy(Auth,1,p-1);
          fAuthPassword :=Copy(Auth,p+1,MAXINT);
          fbUsing_UPE_auth:=true; //sinaliza que usando UPE auth
        end;
    end;      {/Auth<>''}
end;

Function  THttpContext.GetAuthUser:String;
begin
  //on demand parse of basic auth params
  //fev11: passei a fazer o parse da UPE antes da basic authentication ( ou seja, se tem UPE ignora a basic auth )
  if (fAuthUser='*') then ParseAuthEmbeddedInQueryString; //search for 'UPE' special parameter in qs
  if (fAuthUser='*') then ParseAuthentication;  //aqui o parse das credenciais é "on demand"
  Result := fAuthUser;
end;

Function  THttpContext.GetAuthPassword:String;
begin
  //fev11: passei a fazer o parse da UPE antes da basic authentication ( ou seja, se tem UPE ignora a basic auth )
  if fAuthPassword='*' then ParseAuthEmbeddedInQueryString; //search for 'UPE' special parameter in qs
  if fAuthPassword='*' then ParseAuthentication;
  Result:=fAuthPassword;
end;

{------------------ THttpSrvCmpNew. }
Constructor THttpSrvCmpNew.Create(aOwner:TComponent);
begin
  inherited Create(aOwner);
  fOnHttpRequest:=nil;
  fOnHttpAccept:=nil;
  fOnHttpClose:=nil;
  fOnLogHit:=nil;
  fOnBeforeHttpRequest:=nil;
  fExceptionText:=nil;
  fOnHttpDispatchEnd:=nil;

  FillChar(fContexts,SizeOf(fContexts),#0);
  fClientTimeOut:=100;          {100 seconds for timeout}

  fTimeoutTimer:=TTimer.Create(nil); //era Self);
  fTimeoutTimer.Enabled:=FALSE;
  fTimeoutTimer.Interval:=5000; {frequency of timeout checks = 5 seg}
  fTimeoutTimer.OnTimer:=HttpTimeoutTimer;

  fTCPSrv:=TBufTCPSrv.Create(nil); //era Self);
  // O TBufTCPSrv do servidor http é um componente tcpip buferizado
  // o default tamanho da fila de cada conexão é 2000 pacotes
  fTCPSrv.Parent:=TWinControl(aOwner);
  fTCPSrv.Top:=-100;         //põe cmponente visual fora de vista
  fTCPSrv.ServerPort:=80;    {Default}
  fTCPSrv.AutoStart:=FALSE;
  //hook tcp events
  fTCPSrv.OnDataReceived:=HttpDataReceived;
  fTCPSrv.OnCloseSocket:=HttpCloseSocket;
  fTCPSrv.OnClientAccept:=HttpClientAccept;
  fTCPSrv.OnQueueEnded:=HttpQueueEnd;
  //fTimeoutTimer.Enabled:=TRUE; //mai 04 - começou a dar pau no D7 !
  fServerName:=DefaultServerName;

  Hits   :=0;
  Errors :=0;
  CountUseCached304:=0;
  CountFilesServed:=0;

  fActions:=THttpActionItems.Create(Self,THttpActionItem);
  fServeFiles:=FALSE;
  fRootFileDirectory:='';
  fEmailWebMaster:='';
  fMaxEntityBodySize:=-1; //default -1 = ilimitado
  fKeepConectionsAlive := false; //default é não manter connections alive (for now..)

  fCache :=nil;
  //cache em testes (para desabibitar, é só comentar a linha abx)
  fCache :=TOmHttpSrvCache.Create;    //mai08:Om: adicionei cache de files

  fbKeepConnAlive:=false;
  fbUseCachedForFiles:=true;
  fDefaultFileName:='default.htm';     // mai08: Om: nome default pra files...
end;

Destructor THttpSrvCmpNew.Destroy;
var i:integer;
begin
  fTimeoutTimer.Enabled:=false;
  fTimeoutTimer.OnTimer:=Nil;
  //tirei pois estava dando erro (na terminacao o fTCPSrv é destruido antes de chegar aqui...)
  //for i:=1 to fTCPSrv.ClientsHiMark do
  for i:=1 to MAXCLIENTS do            //free all contexts
    if Assigned(fContexts[i]) then fContexts[i].Free;
  //fTCPSrv.StopServer;
  fTimeoutTimer.Free;
  {fTCPSrv.Free;} //isso começou a dar erro no D7 !
  fActions.Free;

  if Assigned(fCache) then fCache.Free;

  inherited Destroy;
end;

//cada 5 segs dispara esse handler
Procedure THttpSrvCmpNew.HttpTimeoutTimer(Sender:TObject);
var i:integer;
begin
  for i:=1 to fTCPSrv.ClientsHiMark do            //checa todos os contextos existentes
    if Assigned(fContexts[i])                     //   Se contexto ativo ..
      and (fContexts[i].Seconds>fClientTimeOut)   //.. e passou um tempão ..
      and (not fContexts[i].KeepOpen)             //.. e não mantem conexoes abertas após envio..
      and fTCPSrv.QueueEmpty[i] then              //.. e já mandou todo buffer..
        fTcpSrv.CloseClient(i);                   //.. fecha a conexão.
end;

function THttpSrvCmpNew.GetContext(index:integer):THttpContext;
begin
  if (index>0) and (index<=fTCPSrv.ClientsHiMark) then //sanity test
    Result:=fContexts[index]
    else Result:=Nil;
end;

function  THttpSrvCmpNew.GetClientsHighMark:integer;
begin
  Result:=fTCPSrv.ClientsHiMark;
end;

function  THttpSrvCmpNew.GetContextCount:integer; //count active contexts
var i,NC,N:integer;
begin
  N:=0;
  NC:=GetClientsHighMark;
  if NC>MAXCLIENTS then NC:=MAXCLIENTS;
  for i:=1 to NC do if Assigned(fContexts[i]) then inc(N);
  Result:=N;
end;

Procedure THttpSrvCmpNew.SetClientTimeOut(Value:integer);
begin
  if (Value<>fClientTimeOut) then
    begin
      fClientTimeOut:=Value;
      //fTimeoutTimer.Enabled:=(fClientTimeOut<>0); {0 --> never timeout}
    end;
end;

Function THttpSrvCmpNew.GetStarted:Boolean;
begin
  Result:=(fTCPSrv.TcpState=CONNECTED);
end;

Procedure THttpSrvCmpNew.SetStarted(Value:Boolean);
begin
  if Value<>Started then
    begin
      if Value then
        begin
          fTimeoutTimer.Enabled:=TRUE;
          fTCPSrv.StartServer;
        end
        else begin
          fTimeoutTimer.Enabled:=FALSE;
          fTCPSrv.StopServer;
        end;
    end;
end;

Function THttpSrvCmpNew.GetServerPort:integer;
begin
  Result:=fTCPSrv.ServerPort;
end;

Procedure THttpSrvCmpNew.SetServerPort(Value:integer);
var wasstarted:Boolean;
begin
  if Value<>ServerPort then //change server port!
    begin
      wasstarted:=Started;
      if wasstarted then fTCPSrv.StopServer;
      fTCPSrv.ServerPort:=Value;
      if wasstarted then fTCPSrv.StartServer; //restar
    end;
end;

// todos os sends de string do componente passam por aqui (envio de headers e de textos (htm,txt,xml etc)
// adiciona um CRLF no final
Procedure THttpSrvCmpNew.InternalSendString(ClientID:integer;const aLinha:String);
var L:integer; S:String;
begin
  with fContexts[ClientID] do if Assigned(fLogEnvio) then
    fLogEnvio.Add(aLinha);   //salva em fLogEnvio todos os strings enviados (response header e content)
  S:=aLinha+CRLF;
  L:=Length(S);
  fTCPSrv.SendData(ClientID,PChar(S),L);
end;

Procedure THttpSrvCmpNew.SendString(ClientID:integer; const aLinha:String);
var i:integer;
begin
  with fContexts[ClientID] do if (fEstado=ehSENDRESPONSE) and (not fRespHeaderSent) then
    begin
      if (ResponseHeader.Count=0) then
        InitResponseHeaderOk;    {No header yet, prepare a Ok header}
      for i:=0 to ResponseHeader.Count-1 do
        InternalSendString(ClientID,ResponseHeader.Strings[i]);
      InternalSendString(ClientID,''); {Sinaliza fim do resp header}
      fRespHeaderSent:=TRUE;
    end;
  InternalSendString(ClientID,aLinha);
end;

// SendStream manda o stream de uma vez (usando a bufferizaçao do ButTcpSrv)
Procedure THttpSrvCmpNew.SendStream( ClientID:integer; aStream:TStream; const aContentType:String);
var i,L:integer; CLen:integer;
begin
  CLen:=aStream.Size;
  with fContexts[ClientID] do
   if (fEstado=ehSENDRESPONSE) and (not fRespHeaderSent) then
    begin
      if (aContentType<>'') then RespContentType:=aContentType;
      RespContentLenght:=CLen;
      if (ResponseHeader.Count=0) then
        InitResponseHeaderOk;          {No header, prepare a Ok header}
      for i:=0 to ResponseHeader.Count-1 do
        InternalSendString(ClientID,ResponseHeader.Strings[i]);
      InternalSendString(ClientID,''); {Sinaliza fim do resp header}
      fRespHeaderSent:=TRUE;
    end;
  i:=0;
  aStream.Position:=0;     //rewind
  while (i<CLen) do
    begin
      L:=(CLen-i);
      if (L>TAMSENDBUFFER) then L:=TAMSENDBUFFER;  //manda max de 10k por vez
      if L>0 then
        begin
          L:=aStream.Read(fSendBuffer,L);
          if L>0 then fTCPSrv.SendData(ClientID,fSendBuffer,L); //o tcpSrv buferiza se necessario (i.e. isso não trava)
          inc(i,L);
        end;
    end;
end;

Procedure  THttpSrvCmpNew.SendStringList(ClientID:integer;SL:TStringList);
begin
  SendStrings(ClientID,SL);
end;

// set08: Pra poder usar multiplos SendStrings() no mesmo
//        response, deve antes fazer context.fTotalizaContentLengthDeStrings:=false
Procedure  THttpSrvCmpNew.SendStrings(ClientID:integer;SL:TStrings);
var i:integer; L:integer;
begin
  //se fTotalizaContentLengthDeStrings falso, não calcula o content length
  //aí pode mandar varios SendStrings() no mesmo response (neste caso não vai content-length no resonse header)
  if fContexts[ClientID].fTotalizaContentLengthDeStrings then
    begin
      L:=0;  //mai08: calcula content lenght antes de mandar
      for i:=0 to SL.Count-1 do inc(L,Length(SL.Strings[i])+2); //calcula tamanho do content (+2=crlf)
      // set08:Om: soma os content lengths..
      fContexts[ClientID].RespContentLenght:=L;
    end;
  //manda a coisa, linha por linha
  for i:=0 to SL.Count-1 do
    SendString(ClientID,SL.Strings[i]); //o primeiro SendString() dispara o envio do response header
    //por isso não dá pra ter multiplos SendStringList
end;

//fechamento forçado da conexão pelo usuário (evitar chamar isso, pois é intempestivo)
Procedure THttpSrvCmpNew.DoCloseClient(ClientID:integer);
begin
  fTCPSrv.CloseClient(ClientID);
end;

//chamado após um request ser atendido, essa proc verifica se terminou o envio do response
//se terminou, toma as ações necessárias
Procedure THttpSrvCmpNew.CheckFinishRequest(ClientID:integer);
var aContext:THttpContext; bClose:boolean;
begin
  if fTCPSrv.QueueEmpty[ClientID] then
    begin
      bClose:=true;  //default é fechar conexão após satisfazer request
      if Assigned(fContexts[ClientID]) then
        begin
          aContext:=fContexts[ClientID];
          if (aContext.fEstado=ehRECICLED) then exit; //não finaliza o request duas vezes, sai

          if fbKeepConnAlive and                      //if server police agrees to keep connection..
             aContext.fBrowserRequestKeepAlive and    //..browser wants it..
             (aContext.RespContentLenght>0) then      //..resp length of previous request was informed (i.e. not a chat style app)
            begin
                    //MostraPCharVar(10,pchar(aContext.CompleteURI)); //teste
              aContext.fEstado:=ehRECICLED; // indica que conexão e contexto reciclados
              // Posteriormente o dataReceived do prox request deve reciclar o contexto
              // TODO: Verificar se fRequestsServed atingiu o maximo permitido pelo srv
              //       Essa coisa de Keep-Alive deve ter um numero maximo de reciclagens, pra resistir a ataque tipo DOS
              bClose:=false;                // sai sem desconectar
            end;
        end;
      if bClose then                   //fecha a connexão (isso destroi o conexto tb)
        fTCPSrv.CloseClient(ClientID); //se já foi tudo no buffer interno do tcp/ip, já pode fechar
      //contexto aqui está nil
    end;
end;

Procedure THttpSrvCmpNew.GotoLocation(ClientID:integer;const aLocation:String);
var S:String; L:integer;
begin
  if Assigned(fContexts[ClientID]) then  fContexts[ClientID].RespStatus:=302; //save resp status

  InternalSendString(ClientID,sHttpResponseVersion+' 302 Moved');
  InternalSendString(ClientID,'Date: '+OmFormataDataHTTP(Now));
  InternalSendString(ClientID,fServerName);
  InternalSendString(ClientID,'Location: '+aLocation);
  InternalSendString(ClientID,'Content-type: text/html');
  if Assigned(fContexts[ClientID]) and (fContexts[ClientID].RespCookie<>'') then
    InternalSendString(ClientID,'Set-Cookie: '+fContexts[ClientID].RespCookie);
  S:='<html><body><h2>Clique <a href="'+aLocation+'">aqui</a></h2></body></html>'; {formata resposta html, just in case}
  L:=Length(S)+2;
  fContexts[ClientID].RespContentLenght:=L;
  InternalSendString(ClientID,'Content-Length: '+IntToStr(L));
  InternalSendString(ClientID,''); {Linha vazia p/ terminar response header}
  InternalSendString(ClientID,S);  //manda html de redirect
  CheckFinishRequest(ClientID);
end;

Procedure THttpSrvCmpNew.SendErrorMessageWithContentType(ClientID:integer;Code:integer;const aContentType,aMsg:String);
var S:String; p,L,i:integer;
begin
  inc(Errors);
  S:=GetErrorMessage(Code);
  if Assigned(fContexts[ClientID]) then  fContexts[ClientID].RespStatus:=Code; //save resp status
  InternalSendString(ClientID,sHttpResponseVersion+' '+S);
  InternalSendString(ClientID,'Date: '+OmFormataDataHTTP(Now));
  InternalSendString(ClientID,fServerName);
  InternalSendString(ClientID,'Allow-ranges: bytes');
  InternalSendString(ClientID,'Accept-ranges: bytes');
  InternalSendString(ClientID,'Content-type: '+aContentType);

  if Assigned(fContexts[ClientID]) then
    with fContexts[ClientID].ResponseHeader do
      for i:=0 to Count-1 do InternalSendString(ClientID,Strings[i]);

  p:=Pos('<',aMsg);          //ve se usr mandou a mensagem ja em html >> pegadinha: se não tiver '<', o metodo insere formatação html
  if p>0 then S:=aMsg
    else S:='<html><body><h2>'+aMsg+'</h2></body></html>'; {Monta response p/ poder calcular o length}
  L:=Length(S)+2;
  fContexts[ClientID].RespContentLenght:=L;
  InternalSendString(ClientID,'Content-Length: '+IntToStr(L));
  InternalSendString(ClientID,''); {Linha vazia p/ terminar response header}
  InternalSendString(ClientID,S);  {Manda response}
  CheckFinishRequest(ClientID);
end;

Procedure THttpSrvCmpNew.SendErrorMessage(ClientID:integer; Code:integer;const aMsg:String);
var S:String; p,L:integer;
begin
  if (Code>=400) then inc(Errors); //sé é erro se for 400 ou 500  (200 é ok e 300 é redirect ou use cached)
  S:=GetErrorMessage(Code);
  if Assigned(fContexts[ClientID]) then  fContexts[ClientID].RespStatus:=Code; //save resp status
  InternalSendString(ClientID,sHttpResponseVersion+' '+S);
  InternalSendString(ClientID,'Date: '+OmFormataDataHTTP(Now));
  InternalSendString(ClientID,fServerName);
  InternalSendString(ClientID,'Allow-ranges: bytes');
  InternalSendString(ClientID,'Accept-ranges: bytes');
  InternalSendString(ClientID,'Content-type: text/html');
  p:=Pos('<',aMsg);       //ve se usr mandou a mensagem já em html
  if p>0 then S:=aMsg
    else S:='<html><body><h2>'+aMsg+'</h2></body></html>'; {Monta response p/ poder calcular o length}
  L:=Length(S)+2;
  fContexts[ClientID].RespContentLenght:=L;
  InternalSendString(ClientID,'Content-Length: '+IntToStr(L));
  InternalSendString(ClientID,''); //Linha vazia p/ terminar response header
  InternalSendString(ClientID,S);  //Manda response
  CheckFinishRequest(ClientID);    //se já foi tudo no buffer interno do tcp/ip, já pode fechar
end;

Procedure THttpSrvCmpNew.SendErrorResponse(ClientID:integer;Code:integer);
var S:String; i,L:integer;
begin
  inc(Errors);
  S:=GetErrorMessage(Code);
  if Assigned(fContexts[ClientID]) then  fContexts[ClientID].RespStatus:=Code; //save resp status
  InternalSendString(ClientID,sHttpResponseVersion+' '+S);
  InternalSendString(ClientID,'Date: '+OmFormataDataHTTP(Now));
  InternalSendString(ClientID,fServerName);
  InternalSendString(ClientID,'Allow-ranges: bytes');
  InternalSendString(ClientID,'Accept-ranges: bytes');
  InternalSendString(ClientID,'Content-type: text/html');
  {Manda extra headers, se houver}
  if Assigned(fContexts[ClientID]) then
    with fContexts[ClientID].ResponseHeader do
      for i:=0 to Count-1 do InternalSendString(ClientID,Strings[i]);
  S:='<html><body><h2>'+S+'</h2>'; {Monta response p/ poder calcular o lenght}
  if (Code=404) then
    S:=S+'Documento '+fContexts[ClientID].URI+' não encontrado<p>';
  S:=S+'</body></html>';
  {'not found in this server<p>');}
  L:=Length(S)+2;
  fContexts[ClientID].RespContentLenght:=L;
  InternalSendString(ClientID,'Content-Length: '+IntToStr(L));
  InternalSendString(ClientID,''); {Linha vazia p/ terminar response header}
  InternalSendString(ClientID,S);
  CheckFinishRequest(ClientID);  //se já foi tudo no buffer interno do tcp/ip, já pode fechar
end;

// ActionByURI() é case sensitive !!
function THttpSrvCmpNew.ActionByURI(const AName: string): THttpActionItem;     // AName tipo '/help' ou '/index.html'
var I:Integer;
begin
  for I:=0 to fActions.Count-1 do   // Watch: busca linear nos actions (unsuitable for large number of actions)
    begin
      Result:=fActions[I];
      if (AName=Result.FPathInfo) then Exit;    // uri match, found it!
    end;
  Result:=nil;
end;

function    THttpSrvCmpNew.Uri2ActionName(const aUri:String):String; //case sensitive fev11:Om:
var aAction:THttpActionItem;
begin
  aAction:=ActionByURI(aUri);
  if Assigned(aAction) then Result:=aAction.Name
    else Result:='';           // '' = not an action..
end;


// habilitar somente em casos controlados
// - this is a security check point!!
// # Certificar se os servidores de arquivos estão
//   fechados, ou pelo menos bem configurados.
// ServeFileStream deve satisfazer o request (se arq não existir ou outro problema, deve retornar erro ao usr)
Procedure THttpSrvCmpNew.ServeFileStream(ClientID:integer);
var S:TFileStream; aFileNm,aContentType:String;  i,p1,p2,p3:integer; ms:TMemoryStream;
    aDateTime,aClientFileDt,aLocalFileDt:TDatetime;
begin
  if (fRootFileDirectory='') then SendErrorMessage(ClientID,500,'Root Directory not set')
    else begin
      aFileNm:=fContexts[ClientID].URI;
      //sanity test no request - Checa coisas perigosas na uri
      //  .. pode ser tentativa de escalar a estrutura de diretorios do servidor
      p1:=Pos('..',aFileNm);    // "/../../...." não né...
      p2:=Pos('*',aFileNm);     //wildcards tb são inaceitaveis em nome de arquivo
      p3:=Pos('?',aFileNm);
      if (p1>0) or (p2>0) or (p3>0) then
        begin
          //acesso negado, pois poderia acessar partes nao permitidas com
          //coisas do tipo '../../../autoexec.bat
          SendErrorResponse(ClientID,403);
          exit;
        end;
      //troca barras do unix para DOS
      for i:=1 to length(aFileNm) do if aFileNm[i]='/' then aFileNm[i]:='\';  {/ UNIX--> \ DOS}

      //se dir termina com '\' e filename começa por '\', tira uma delas...
      if (fRootFileDirectory<>'') and (aFileNm<>'') and
         (fRootFileDirectory[Length(fRootFileDirectory)]='\') and
         (aFileNm[1]='\') then Delete(aFileNm,1,1);

      // Trabalha com o nome do arquivo em lowercase
      aFileNm:=Lowercase(fRootFileDirectory+aFileNm);      // forma nome do arquivo target
      if (aFileNm<>'') and (aFileNm[Length(aFileNm)]='\') then aFileNm:= aFileNm+fDefaultFileName; // tipo 'c:\srv\htdocs\index.htm'
      aLocalFileDt  := OmFileDatetime(aFileNm);            // always get disk file date/time

      if (fContexts[ClientID].IfModifiedSince<>'') and  //se client especifica que já tem versão desse arq no cache..
         fbUseCachedForFiles then                       //..verifica data pra ver se versão é
        begin
          aClientFileDt := OmDecodeHTTPDateStr(fContexts[ClientID].IfModifiedSince); //returns 0 if date invalid

          if (aClientFileDt>0) and (aLocalFileDt>0) and (aClientFileDt>=aLocalFileDt) then
            begin
              //  MostraPCharVar(1,pchar(aFileNm+': '+fContexts[ClientID].IfModifiedSince)); //teste
              SendErrorMessage(ClientID, 304, 'Not modified. Use cached version.');
              inc(CountUseCached304);
              exit;
            end;
        end;

      if Assigned(fCache) then //busca no cache de arquivos em memoria
        begin
          ms:=fCache.Get_Add_File(aFileNm,aLocalFileDt,aDateTime,aContentType);  //pega no cache (ret nil se não tiver no cache nem o arquivo
          // se for arquivo novo, adiciona no cache
          if Assigned(ms) then
            begin
              try
                fContexts[ClientID].LastModified  := aDateTime; //return date of file modification
                SendStream(ClientID,ms,aContentType);           //send it
                inc(CountFilesServed);
              finally;
                ms.Position:=0; //rewind, but dont free!
              end;
            end
            else begin
              SendErrorResponse(ClientID,404);
            end;
        end
        else begin  //no cache present (open and serve the file)
          try
            S:=TFileStream.Create(aFileNm,fmOpenRead); //isso gera exception, se tiver problema
          except
            SendErrorResponse(ClientID,404); //not found..
            exit;
          end;
          try //se aqui, conseguiu abrir arq
            fContexts[ClientID].LastModified:=aLocalFileDt; //gambiarra. O cache pega a data real do arquivo
            //retorna stream. File2ContentType determina o mime type, em bd estatico
            SendStream(ClientID,S,File2ContentType(aFileNm)); //send it
            inc(CountFilesServed);
          finally;
            S.Free;
          end;
        end;

    end;
end;

Procedure THttpSrvCmpNew.HttpSrvHandleException(ClientID:integer);
var E:Exception; Texto:String; TextHandled:boolean;
begin
  TextHandled:=FALSE;
  E:=Exception(ExceptObject);
  if Assigned(fExceptionText) then
    begin
      Texto:='';
      fExceptionText(Self,Texto); //ve se o mano quer criar um texto proprio para o erro
      TextHandled:=(Texto<>'');
      if TextHandled then   //SendErrorMessage(ClientID,500,Texto); //isso gera um erro 500 em caso de except...
        SendString(ClientID,Texto);
    end;
  if not TextHandled then
    begin
      Texto:='<html><body>'+sErroOcorreu+'<p>'+E.Message+'<p>';
      if fEmailWebMaster<>'' then Texto:=Texto+sContact+'<font size=-1><a href="mailto:'+
        fEmailWebMaster+'">'+fEmailWebMaster+'</a></font><p>';
      Texto:=Texto+'</body></html>';
      //SendErrorMessage(ClientID,500,Texto); //O erro 500 e problema no IE5, que mostra uma mensagem feia a beça!
      SendString(ClientID,Texto);
    end;
  if Assigned(Application.OnException) then Application.OnException(Self,E);
end;

Procedure THttpSrvCmpNew.DispatchRequest(ClientID:integer);
var Action:THttpActionItem; Handled:boolean;

   function _ContextAvailable:boolean;
   begin Result := Assigned(fContexts[ClientID]) end;

begin
  with fContexts[ClientID] do
    begin
      fEstado:=ehSENDRESPONSE;
      Handled:=FALSE;
      //começa a chamar handlers [eventualmente] criados pelo usuário do componente

      //evento BeforeHttpRequest - permite ao usr inspecionar o request (ex: URI e outros cabeçalhos) antes do tratamento
      //o usr pode optar por servir o request (ex: em verificaçao de authenticação quando o cara não apresentou credenciais suficientes)
      if Assigned(fOnBeforeHttpRequest) then
        begin
          fOnBeforeHttpRequest(self, ClientID, fContexts[ClientID], Handled); //normally used for authentication
          // Nota: Eventos podem chamar CloseClient, que destrui o contexto.
          // !!!!  Daqui pra frente, checa Contexto[] usando _ContextAvailable a cada passo !!!!
        end;

      //procura na coleção de actions
      if (not Handled) and _ContextAvailable then
        begin
          Action:= ActionByURI(fContexts[ClientID].URI);
          if Assigned(Action) and Assigned(Action.OnAction) then
            begin
              try
                Action.OnAction(Self,ClientID,fContexts[ClientID],Handled);
              except
                HttpSrvHandleException(ClientID);
                Handled:=TRUE;
              end;
            end;
        end;
      //default action do servidor ( OnHttpRequest )
      if (not Handled) and  Assigned(fOnHttpRequest) and _ContextAvailable then
        begin
          try
            fOnHttpRequest(self,ClientID,fContexts[ClientID],Handled);
          except
            HttpSrvHandleException(ClientID);
          end;
          if not Assigned(fContexts[ClientID]) then exit;   //checa contexto, que pode ter ido embora
        end;
      //not handled yet. May be its a file
      if (not Handled) and fServeFiles and _ContextAvailable then
        begin
          ServeFileStream(ClientID); //isso manda 404, se não achar
          Handled:=TRUE;
        end;
      //it is a 404 - not found..
      if (not Handled) and _ContextAvailable then SendErrorResponse(ClientID,404); {not found}
      if Assigned(fOnHttpDispatchEnd) then fOnHttpDispatchEnd(Self,ClientID);
    end; {with Context..}
end;

Procedure THttpSrvCmpNew.HttpDataReceived(Sender:TObject;ClientID:integer);
var S:Array[0..1000] of char; C:Char; i,L:integer; bDispatchRequest,bHeadersOk:Boolean; S1:String;
begin
  if Assigned(fContexts[ClientID]) then with fContexts[ClientID] do
    begin
      L:=1000;                 //recebe bytes
      L:=fTCPSrv.RecvData(ClientID,S,L);
      if (L>0) then  //aqui as vezes vem um HttpDataReceived sem data nenhuma. Acho que significa que o browser mandou fechar..
        begin
            if (fEstado=ehRECICLED) then //conexão reciclada por mecanismo de keep-alive
              begin
                inc(Hits);
                ResetContext;            //resseta contexto, mantendo apenas o IPAddr

                inc(fRequestsServed);    //incrementa requests served neste contexto ()
                fEstado:=ehRECVHEADER;   //prepara para receber novo header
                      MostraIntVar(12,fRequestsServed); //teste
                //aqui gera evento de accept, apesar de ser uma reciclagem de conexão (keep alive)
                if Assigned(fOnHttpAccept) then fOnHttpAccept(Self,ClientID,fContexts[ClientID]); //
                //MessageBeep(0);          //teste
              end;

            for i:=0 to L-1 do
              begin
                bDispatchRequest:=FALSE; // isso é usado pra sinalizar se request header recebido..
                // .. (no caso de post, entity boby também)
                C:=S[i];                 //para cada caracter recebido..
                Case fEstado of
                  ehRECVHEADER:
                    begin
                      case C of
                        #13:;  //ignora CRs
                        #10: if (RcvLinha='') then {Linha vazia sinaliza final do request header, trata cabeçalho}
                           begin
                             //verifica cabeçalho http completado, com dados do request
                             bHeadersOk:=CheckRequestHeaders; //isso checa e já preenche method, URI, QueryStr etc
                                   //MostraPCharVar(11,pchar(CompleteURI)); //teste
                             if bHeadersOk then               //cabeçalho recebido ok
                               begin
                                 if (fEstado<>ehRECVENTITYBODY) then //sem entity body --> é GET, processa request
                                   begin
                                      bDispatchRequest:=TRUE;
                                      //break;
                                   end {terminou header, trata}
                                   else begin    {se ehRECVENTITYBODY, continua recebendo os post fields}
                                     //verifica se usr nao esta tentando uploadar um troço gigante...
                                     if (fMaxEntityBodySize>0) and (EntityBodySz>fMaxEntityBodySize) then
                                       begin
                                         S1:='Conteudo grande demais ('+IntToStr(EntityBodySz)+' bytes).<br>'+
                                           'Máximo aceito para upload '+IntToStr(fMaxEntityBodySize)+' bytes';
                                         SendErrorMessage(ClientID,400,S); //isso nao está produzindo a msgs correta no browser
                                         //break;
                                       end;
                                   end;
                               end
                               else begin {cabeçalho http inválido, sinaliza erro}
                                 //SendErrorResponse(ClientID,400);
                                 SendErrorMessage(ClientID,400,'Cabeçalho http inválido');
                                 //break;
                               end;
                           end
                           else begin   {mais uma linha de header,adiciona}
                             RequestHeader.Add(RcvLinha);
                             RcvLinha:='';
                           end;
                      else
                        RcvLinha:=RcvLinha+C; {outros caracteres, adiciona}
                      end;
                    end; {ehRECVHEADER:}
                  ehRECVENTITYBODY:
                    begin
                      EntityBody[fEntityBodyPtr]:=C;
                      inc(fEntityBodyPtr);
                      if fEntityBodyPtr>=EntityBodySz then {terminou entitybody, trata request}
                        begin
                          bDispatchRequest:=TRUE;
                          //break;
                        end;
                    end; {ehRECVENTITYBODY:}
                else
                  //break; {outros estados, ignora os caracteres ??}
                end;  // /case fEstado
                //ve se trata...
                if bDispatchRequest then //se request (e eventual entity body) recebidos, trata pedido
                  begin
                    // se aqui, Context.RequestHeader está preenchido e pronto para tratamento
                    DispatchRequest(ClientID);          //trata request recebido
                    if Assigned(fContexts[ClientID]) and (not fContexts[ClientID].KeepOpen) then  {???}
                      CheckFinishRequest(ClientID);     //se já foi tudo no buffer interno do tcp/ip, já pode fechar
                  end;
              end;  // /for i...
        end;  // /if L>0
    end;
end;

// handler de fTCPSrv.OnCloseSocket
Procedure THttpSrvCmpNew.HttpCloseSocket(Sender:TObject;ClientID:integer);
begin
  if Assigned(fContexts[ClientID]) then
    begin
      if Assigned(fContexts[ClientID].fLogEnvio) then
        fContexts[ClientID].fLogEnvio.Add('>>conn '+IntToStr(ClientID)+' fechada');   //salva em fLogEnvio todos os strings enviados (response header e content)
      if Assigned(fOnLogHit) then
        fOnLogHit(Self,ClientID,fContexts[ClientID]);
    end;

  if Assigned(fOnHttpClose) then fOnHttpClose(Self,ClientID);
  //mai08: Om: passei a detonar o contexto APÓS o fOnHttpClose(), pra ter ainda o contexto no evento (antes detonava antes)
  if Assigned(fContexts[ClientID]) then
    begin
      fContexts[ClientID].Free;
      fContexts[ClientID]:=Nil;
    end;
end;

//handler de fTCPSrv.OnQueueEnded. Chamado quando a queue de saida de um contexto termina...
// isso permite a finalização do request
Procedure THttpSrvCmpNew.HttpQueueEnd(Sender:TObject;ClientID:integer);
begin
  if Assigned(fContexts[ClientID]) and (not fContexts[ClientID].KeepOpen) then
    fTcpSrv.CloseClient(ClientID); //se enviou todo buffer do servidor, já pode fechar
end;

//handler de fTCPSrv.OnClientAccept. Chamado antes de ler qquer coisa do request ...
Procedure THttpSrvCmpNew.HttpClientAccept(Sender:TObject;ClientID:integer; aIP:LongWord; aAddr:String);
begin
  if Assigned(fContexts[ClientID]) then {não deveria acontecer ?? em todo caso, desaloca}
    begin
      fContexts[ClientID].Free;
      fContexts[ClientID]:=Nil;
    end;
  fContexts[ClientID]:=THttpContext.Create(self);
  fContexts[ClientID].IPAddr:=aAddr;  //salva IP do client dessa conexão no context
  inc(Hits);                          //compute a hit
  if Assigned(fOnHttpAccept) then fOnHttpAccept(Self,ClientID,fContexts[ClientID]); //repassa evento
end;

function  THttpSrvCmpNew.GetAction(Index: Integer): THttpActionItem;
begin
  Result:=fActions[Index];
end;

procedure THttpSrvCmpNew.SetActions(Value: THttpActionItems);
begin
  FActions.Assign(Value);
end;

procedure THttpSrvCmpNew.ClearServerStatistics;
begin
  //zera counters
  Hits:=0;
  Errors:=0;
  CountUseCached304 := 0;
  CountFilesServed  := 0;
end;

function THttpSrvCmpNew.GetCacheFileCount: integer;
begin
  if Assigned(fCache) then Result:=fCache.Count
    else Result:=0;
end;

function THttpSrvCmpNew.GetCacheMemorySize: integer;
begin
  if Assigned(fCache) then Result:=fCache.GetCacheMemorySize
    else Result:=0;
end;

procedure THttpSrvCmpNew.ClearCache;
begin
  if Assigned(fCache) then fCache.ClearCache;
end;

procedure THttpSrvCmpNew.SetKeepConectionsAlive(const Value: boolean);
begin
  if (value<>fKeepConectionsAlive) then
    begin
      fKeepConectionsAlive := Value;
      //TODO: ressetar conexoes mantidas, se fKeepConectionsAlive passou a falso
    end;
end;

{-------------------------------------------}

procedure Register;
begin
  RegisterComponents('Omar', [THttpSrvCmpNew]);
end;


function THttpSrvCmpNew.GetFileCacheRunning: boolean;
begin
  Result:=Assigned(fCache);
end;

procedure THttpSrvCmpNew.SetFileCacheRunning(const Value: boolean);
begin
  if (Value<>Assigned(fCache)) then
    begin
      if Value then
        begin
          if not Assigned(fCache) then
            fCache:=TOmHttpSrvCache.Create;
        end
        else begin
          if Assigned(fCache) then
            fCache.Free;
          fCache:=nil;
        end;
    end;
end;

end.

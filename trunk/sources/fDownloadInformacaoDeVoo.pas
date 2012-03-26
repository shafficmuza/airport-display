Unit fDownloadInformacaoDeVoo; // AirportDisplay - (c)copr. 02-12 Omar Reis   //
//-------------------------//                                              //
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/
// Controle do display de informacao de voo                                   //
// Essa unit faz os downloads, administra os voos e controla o layout do AD   //
// tres units contem os displays (a parte visivel da aplicacao):              //
//   fAirportDisplay - Form com 25 linhas                                     //
//   fDisplayPortao  - Form para portao de embarque                           //
//   fGLAirportDisplay - Form GLScene (3D)                                    //
//----------------------------------------------------------------------------//

{..$DEFINE PAINEL_3D}

interface
uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls,
  JPEG,               //TJPEGImage
  ComCtrls, Grids, Spin,
  ThreadHttpDownload,
  HtmlParser,
  HtmlUtils,     {TTableNodeParser}
  StdCtrls,
  uInformacaoDeVoo, //TInformacaoDeVoo
  strToken,
  HttpSrv2,
  StateBox;

const
  MAXVOOS=100;              //banco de dados tem até 100 voos (5 paginas infraero) e o display tem 50 (2 paginas).
  //MAXPAGINASINFRAERO=5;   //num max de paginas baixadas
  //Mas alguns voos infraero podem ser inivisiveis
  VerStr='(c)Omar Reis';    // <--------- versao
  sHtmlTitle='<h2>Airport Display</h2>';

  bEhAirportDisplay:boolean=true; //se true é o AD, se false é o AMC

type
  TFormAirportDisplayControl = class(TForm)
    PageControl1: TPageControl;
    TabConfig: TTabSheet;
    TabMonitor: TTabSheet;
    Monitor: TMemo;
    BClearMonitor: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    EdHost: TEdit;
    EdFileName: TEdit;
    EdPath: TEdit;
    Label4: TLabel;
    EdQualPagina: TSpinEdit;
    RGTipoPagina: TRadioGroup;
    BDownloadPaginaInfraero: TButton;
    Bevel1: TBevel;
    BDownloadNow: TButton;
    LStatus: TLabel;
    LOperation: TLabel;
    PanelGridTop: TPanel;
    Panel2: TPanel;
    StringGrid1: TStringGrid;
    ProgressBar1: TProgressBar;
    CBAtualizaStringGrid: TCheckBox;
    TimerAutomacao: TTimer;
    Label7: TLabel;
    Bevel2: TBevel;
    Label5: TLabel;
    Label6: TLabel;
    CBAtualizacaoAutomatica: TCheckBox;
    EdSegundos: TSpinEdit;
    Bevel3: TBevel;
    Bevel4: TBevel;
    CBServidorHttpAtivado: TCheckBox;
    Label8: TLabel;
    Label9: TLabel;
    EdPortaHttp: TSpinEdit;
    Label10: TLabel;
    HttpSrv: THttpSrvCmpNew;
    Label11: TLabel;
    LIniciadoEm: TLabel;
    Label12: TLabel;
    LNDownloads: TLabel;
    Label13: TLabel;
    LNAtualizacoes: TLabel;
    Label14: TLabel;
    LNErrosDownload: TLabel;
    ConfigStateBox: TStateBox;
    BSalvaConfiguracao: TButton;
    BCarregaCnf: TButton;
    CBBeepOnMonitorMessage: TCheckBox;
    TabDisplay: TTabSheet;
    CBComTitulo: TCheckBox;
    Label15: TLabel;
    EdDisplayFormX: TSpinEdit;
    Label16: TLabel;
    Bevel5: TBevel;
    EdDisplayFormY: TSpinEdit;
    Label17: TLabel;
    Label18: TLabel;
    BSetPosicao: TButton;
    Bevel6: TBevel;
    Label19: TLabel;
    CBScreenSaverAtivado: TCheckBox;
    Label20: TLabel;
    Label21: TLabel;
    EdScreenSaverDas: TEdit;
    EdScreenSaverAte: TEdit;
    Label22: TLabel;
    Bevel7: TBevel;
    CBDemagnetizadorAtivado: TCheckBox;
    Label23: TLabel;
    EdDemagnetizadorSecs: TEdit;
    Label24: TLabel;
    EdDemagnetizadorMin: TEdit;
    Label25: TLabel;
    Label26: TLabel;
    CBStopFlappingIfFallingBehind: TCheckBox;
    BForcaRenderizacao: TButton;
    CBMostraCabecalho: TCheckBox;
    CBRefresherAtivado: TCheckBox;
    CBSomenteVoosDoPortao: TCheckBox;
    Bevel8: TBevel;
    TabFiltros: TTabSheet;
    CBSomenteAirline: TCheckBox;
    Label27: TLabel;
    EdAirline: TEdit;
    Label28: TLabel;
    Bevel9: TBevel;
    Label29: TLabel;
    EdNumLinhas: TSpinEdit;
    BSetNumLinhas: TButton;
    CBStatusVisible: TCheckBox;
    Label30: TLabel;
    EdMaxPaginasInfraero: TSpinEdit;
    CBComSom: TCheckBox;
    RGQualBancoDeDados: TRadioGroup;
    Label31: TLabel;
    EdPortaServidor: TSpinEdit;
    Label32: TLabel;
    Label33: TLabel;
    EdHttpUsername: TEdit;
    Label34: TLabel;
    EdHttpPW: TEdit;
    HttpServerStateBox: TStateBox;
    TabScreenSaver: TTabSheet;
    CBMostraReflexo: TCheckBox;
    CBCoresAlternadas: TCheckBox;
    EdNomePortao: TEdit;
    BRenderizaVoos: TButton;
    Bevel10: TBevel;
    Label35: TLabel;
    CBChecaSeOffline: TCheckBox;
    Label36: TLabel;
    EdMinutosOffline: TSpinEdit;
    Label37: TLabel;
    Label38: TLabel;
    LStatusOffline: TLabel;
    CBMostraLinksDeParceria: TCheckBox;
    cbBaggageClaim: TCheckBox;
    cbSomenteStatus: TCheckBox;
    EdSomenteStatus: TEdit;
    cbSomenteEsteira: TCheckBox;
    EdSomenteEsteira: TEdit;
    Button2: TButton;
    Button1: TButton;
    cbEsteiraPatio: TCheckBox;
    cbVooNaoComecePor: TCheckBox;
    edVooNaoComecePor: TEdit;
    rgInternacionallDomestico: TRadioGroup;
    cbAtualizacoesEmCascata: TCheckBox;
    TimerAtualizaEmCascata: TTimer;
    LFilaDeferimento: TLabel;
    Label39: TLabel;
    cbExcluiAirline: TCheckBox;
    EdExcluiAirline: TEdit;
    TimerVoosParceria: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure BDownloadNowClick(Sender: TObject);
    procedure BClearMonitorClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BDownloadPaginaInfraeroClick(Sender: TObject);
    procedure CBAtualizacaoAutomaticaClick(Sender: TObject);
    procedure TimerAutomacaoTimer(Sender: TObject);
    procedure RGTipoPaginaClick(Sender: TObject);
    procedure CBServidorHttpAtivadoClick(Sender: TObject);
    procedure HttpSrvActions0Action(Sender: TObject; ClientID: Integer; Context: THttpContext; var Handled: Boolean);
    procedure BSalvaConfiguracaoClick(Sender: TObject);
    procedure BCarregaCnfClick(Sender: TObject);
    procedure CBComTituloClick(Sender: TObject);
    procedure GetLoadMetabaseAction(Sender: TObject; ClientID: Integer;  Context: THttpContext; var Handled: Boolean);
    procedure BSetPosicaoClick(Sender: TObject);
    procedure EdQualPaginaChange(Sender: TObject);
    procedure CBDemagnetizadorAtivadoClick(Sender: TObject);
    procedure CBStopFlappingIfFallingBehindClick(Sender: TObject);
    procedure BForcaRenderizacaoClick(Sender: TObject);
    procedure CBMostraCabecalhoClick(Sender: TObject);
    procedure BSetNumLinhasClick(Sender: TObject);
    procedure CBStatusVisibleClick(Sender: TObject);
    procedure CBComSomClick(Sender: TObject);
    procedure GetFormUploadCNFAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure PostFormUploadCNFAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure GetStatusAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure GetImageAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure GetConfiguracaoAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure HttpSrvBeforeHttpRequest(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure GetIndexAction(Sender: TObject; ClientID: Integer;
      Context: THttpContext; var Handled: Boolean);
    procedure CBMostraReflexoClick(Sender: TObject);
    procedure CBCoresAlternadasClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BRenderizaVoosClick(Sender: TObject);
    procedure GetDisplayVirtual(Sender: TObject; ClientID: Integer; Context: THttpContext; var Handled: Boolean);
    procedure EdNumLinhasChange(Sender: TObject);
    procedure cbBaggageClaimClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure cbEsteiraPatioClick(Sender: TObject);
    procedure cbAtualizacoesEmCascataClick(Sender: TObject);
    procedure TimerAtualizaEmCascataTimer(Sender: TObject);
  private
    fThreadDownloadInfo:TThreadHttpDownloadComWinInet; //thread de download de informacao de voo
    fHost: string;
    fHostPort:integer;
    fWebPath:  String;
    fPageName: String;  // nome da pag contendo as infos
    fCarregandoSettings:boolean;

    fIxTopFlight:integer;  //voo no topo do display
    fVoos:Array[0..MAXVOOS-1] of TInformacaoDeVoo; //isso contem todos os voos da pagina da infraero

    fNumDownloads:integer;
    fNumAtualizacoes:integer;
    fNErrosDownload:integer;

    fIxPagHtmlSolari:integer;       //indice da pagina Solari (1 a 4)
    fNextDesmagnetization:TDateTime;

    fHoraLastRefresh:TDateTime;
    fHoraLastDownloadOk:TDateTime;

    fVoosDeferedUpdate:TListVooDeferedUpdate;

    Procedure AlocaVoos;
    Procedure DestroeVoos;

    procedure DLIProgress(Sender: TObject; Perc:integer);
    procedure DLIMessage(Sender: TObject; const Text:String);
    procedure DLIOnTerminate(Sender: TObject);
    procedure TransformaBCloseEmFecha;
    procedure GetFromControls;
    procedure MonitorAddMessage(const S: String);
    function  ParseHtmlPageInformacaoDeVoo:boolean;  //true se parse ok (i.e. encontrou a tabela de voos)
    procedure AtualizaVoosSolari(aTNP: TTableNodeParser);
    function  AtualizaVooInfraeroSIIV(N:integer; aST:TStringTokenizer):boolean;  //true se mudou alguma coisa no voo
    //Procedure DoVooModificado(ixv:integer; aVoo:TInformacaoDeVoo);
    procedure UpdateLabelsEstatisticas;
    procedure ADOnException(Sender: TObject; E: Exception);
    procedure ClearVoos;
    function  ScreenSaving: boolean;
    procedure ChecaVoosEmParceria;
    procedure ChecaDesmagnetizador;
    procedure ChecaFlapRefresher;
    function  Grab_AD_JPEG: TJPEGImage;
    function  UsaFormAirportDisplay: boolean;
    function  UsaFormGLAirportDisplay: boolean;
    procedure RenderVoos;
    procedure VerificaVisibilidade_Voo(aVoo: TInformacaoDeVoo); //aplica filtros
    procedure ReposicionaVoosNoDisplayVirtual;
    procedure RenderizaVoosNoDisplayReal(bChangedOnly:boolean);
    procedure ChecaSeOffline;
  public
    procedure BeginDownload;
    procedure MostraFormDeDisplay;

    procedure ForcaPagina(aPageNumber: string); // '1' ou '2'
    procedure TogglePagina;

    //Property  SerieName:String read fPageName write fPageName;
    function  GetActiveDisplayPage: TForm; //retorna form exibido
    function  EhPartidas:boolean;
  end;

var
  FormAirportDisplayControl: TFormAirportDisplayControl;

implementation

uses
  OmFlapLabel,       {bStopFlappingIfFallingBehind}
  fAirPortDisplay,   {TFormAirportDisplay}
  HttpMult,          {TMultipartHttpContent}
  fADScreenSaver,
  {$IFDEF PAINEL_3D}
  fGLAirportDisplay, {TFormGLAirportDisplay}
  OmGLFLapLabels,    //EnableGlobalGLFlapLabelTimer
  {$ENDIF PAINEL_3D}
  fDisplayPortao;    {TFormDisplayPortao}

{$R *.DFM}

{ TFormDownloadInfoVoo }
procedure TFormAirportDisplayControl.FormCreate(Sender: TObject);
begin
  Application.OnException:=ADOnException; {coloca o monitor como console de exceptions}
  fIxPagHtmlSolari:=0;

  LIniciadoEm.Caption:=FormatDateTime('dd/mm/yy hh:nn',Now);
  fNumDownloads:=0;
  fNumAtualizacoes:=0;
  fNErrosDownload:=0;

  fVoosDeferedUpdate:=TListVooDeferedUpdate.Create; //lista de voos em defered update

  fHost:='';
  fHostPort:=80;
  fPageName:='';
  fWebPath:='';
  fThreadDownloadInfo:=nil;
  fCarregandoSettings:=FALSE;
  fIxTopFlight:=0;
  AlocaVoos;
  PageControl1.ActivePage:=TabConfig;
  fNextDesmagnetization:=Now+10/60/24; //default=proxima desmagnetizacao daqui a 10 min
  fHoraLastRefresh:=Now;
  fHoraLastDownloadOk:=0;  //=never
  BCarregaCnfClick(nil);   //carrega configuracoes do ini
end;

procedure TFormAirportDisplayControl.FormDestroy(Sender: TObject);
var T:TDateTime;
const DezSegs=10/3600/24;
begin
  if Assigned(fThreadDownloadInfo) then //ainda está fazendo um download
    begin
      fThreadDownloadInfo.CancelaDownload;
      T:=now;
      while Assigned(fThreadDownloadInfo) and (Now-T<DezSegs) do Application.ProcessMessages; //espera termino do thread
    end;
  //DestroeVoos;
end;

//handler de erros do Airport Display
procedure TFormAirportDisplayControl.ADOnException(Sender: TObject; E: Exception);
begin
  MonitorAddMessage(e.Message);  //aqui poderia logar tb no event viewer, para acesso remoto...
  if CBBeepOnMonitorMessage.Checked then MessageBeep(0);
end;

procedure TFormAirportDisplayControl.DLIProgress(Sender: TObject; Perc:integer);
begin
  ProgressBar1.Position:=Perc;
  LStatus.Caption:='baixando '+fPageName;
end;

procedure TFormAirportDisplayControl.DLIMessage(Sender: TObject; const Text:String);
begin
  LStatus.Caption:=Text;
end;

procedure TFormAirportDisplayControl.BeginDownload;
var aURL: String;
const crlf=#13#10;
begin
  fThreadDownloadInfo:=TThreadHttpDownloadComWinInet.Create;
  with fThreadDownloadInfo do
    begin
      HostName:=fHost;            // 'www.enfoque.com.br';
      HostPort:=fHostPort;        // normalmente 80
      URI:=fWebPath+fPageName;    // '/infraero/'+'VSTAFF.031.HTML'
      aURL:=HostName+URI;
      //AuthString:=Lowercase(TcpCliHttpAuthStr); //tipo 'mcaixeta:caixeta'
      OnMessage:=DLIMessage;
      OnProgress:=DLIProgress;
      OnTerminate:=DLIOnTerminate;
      Resume;                 //inicia download
    end;
  LStatus.Caption:='baixando '+fPageName;
  ProgressBar1.Visible:=TRUE;
  ProgressBar1.Position:=0;
  LOperation.Caption:='arquivo '+aURL;
end;

procedure TFormAirportDisplayControl.TransformaBCloseEmFecha;
begin
  ProgressBar1.Visible:=FALSE;
end;

// atualiza display de voos, apos o parse de uma pagina html. aTNP traz a tabela html já parseada
procedure TFormAirportDisplayControl.AtualizaVoosSolari(aTNP:TTableNodeParser);
var aVooTop,ixv,r:integer; bPartidas:boolean; aVoo:TInformacaoDeVoo;
    iTipoDeBancoDeDados:integer; bAlgumVooChanged:boolean; 

  Procedure UpdateVooSolari;
  begin
    aVoo:=fVoos[ixv];
    aVoo.Changed:=FALSE; // a setagem dos campos individuais altera o campo changed dos voos (se mudou)
    aVoo.SIVVendor:=svSolari;
    with aVoo do if bPartidas then //partidas - vstaff.041.html ( partidas domesticas )
      begin
        //jul07: Alterei do SIV Solari Congonhas para SIV Solari Guarulhos
        IndexVoo:=ixv;  FlighType:=ftDeparture;
        AirLine:=       aTNP.Cells[2,r];   Voo:=     trim(aTNP.Cells[3,r]);   Destino:=  aTNP.Cells[4,r];
        Origem:='';                        Escala1:= aTNP.Cells[5,r];   Escala2:=  aTNP.Cells[6,r];
        Escala3:=       aTNP.Cells[7,r];   Escala4:= aTNP.Cells[8,r];   SomeTime:= aTNP.Cells[9,r];
        EstimatedTime:= aTNP.Cells[10,r];
        Matricula:=     Trim(aTNP.Cells[14,r]);
        Box :=          Trim(aTNP.Cells[15,r]);
        //fev08: pega checkins
        Checkin1 :=     Trim(aTNP.Cells[16,r]);
        Checkin2 :=     Trim(aTNP.Cells[17,r]);
        Gate:=          Trim(aTNP.Cells[19,r]);     //pega Por
        StatusCode:=    aTNP.Cells[20,r];
        Destacado:=StatusDestacado(StatusCode);
      end
      else begin                   //chegadas - vstaff.031.html ( chegadas domesticas )
        //jul07: Alterei do SIV Solari Congonhas para SIV Solari Guarulhos
        IndexVoo:=ixv;  FlighType:=ftArrival;
        AirLine:=       aTNP.Cells[2,r];   Voo:=     trim(aTNP.Cells[3,r]);   Origem:=   aTNP.Cells[4,r];
        Destino:='';                       Escala1:= aTNP.Cells[5,r];   Escala2:=  aTNP.Cells[6,r];
        Escala3:=       aTNP.Cells[7,r];   Escala4:= aTNP.Cells[8,r];   SomeTime:= aTNP.Cells[9,r];
        EstimatedTime:= aTNP.Cells[10,r];
        Box :=          Trim(aTNP.Cells[15,r]);
        Esteira:=       Trim(aTNP.Cells[16,r]);  //Esteira é coluna 'Est'
        //if (aEsteira<>'') then Esteira:=aEsteira[1] else Esteira:=' ';    //pega só a primeira letra da esteira no Solari CGN
        Gate:=          Trim(aTNP.Cells[1,r]);  //Box não é 'Box'! pega o 'Des' (em GRU é o tps)
        StatusCode:=    aTNP.Cells[18,r];
        Destacado:=StatusDestacado(StatusCode);
      end;
    if aVoo.Changed then bAlgumVooChanged:=TRUE;
  end;

  Procedure UpdateVooInfraero_obsoleto;
  begin
    aVoo:=fVoos[ixv];
    aVoo.Changed:=FALSE; // a setagem dos campos individuais altera o campo changed dos voos
    aVoo.SIVVendor:=svInfraero;

    with aVoo do if bPartidas then
      begin         //partidas
        IndexVoo:=ixv;  FlighType:=ftDeparture;
        AirLine:=       aTNP.Cells[1,r];   Voo:=     aTNP.Cells[2,r];   Destino:=  aTNP.Cells[10,r];
        Origem:='';                        Escala1:= aTNP.Cells[11,r];  Escala2:=  aTNP.Cells[12,r];
        Escala3:=       aTNP.Cells[13,r];   Escala4:= aTNP.Cells[4,r];  SomeTime:= aTNP.Cells[3,r];
        EstimatedTime:= aTNP.Cells[4,r];    Gate:=Trim(aTNP.Cells[7,r]);
        StatusCode:='';     StatusMsgPor:=aTNP.Cells[5,r];  StatusMsgEng:=aTNP.Cells[6,r];
        Destacado:=StatusDestacado(StatusCode);
      end
      else begin   //chegadas
        IndexVoo:=ixv;  FlighType:=ftArrival;
        AirLine:=       aTNP.Cells[1,r];   Voo:=     aTNP.Cells[2,r];   Origem:=   aTNP.Cells[11,r];
        Destino:='';                       Escala1:= aTNP.Cells[12,r];  Escala2:=  aTNP.Cells[13,r];
        Escala3:=       aTNP.Cells[14,r];  Escala4:= '';                SomeTime:= aTNP.Cells[3,r];
        EstimatedTime:= aTNP.Cells[4,r];   Gate:=Trim(aTNP.Cells[5,r]);
        StatusCode:='';     StatusMsgPor:=aTNP.Cells[6,r];  StatusMsgEng:=aTNP.Cells[7,r];
        Destacado:=(aTNP.Cells[7,r]='False');
      end;
    if aVoo.Changed then bAlgumVooChanged:=TRUE;
  end; 

begin {AtualizaVoosSolari}
  //ve quais os voos que estao nesta pag html (pega o top)
  aVooTop:=0;
  iTipoDeBancoDeDados:=RGQualBancoDeDados.ItemIndex;
  case iTipoDeBancoDeDados of //pode ser o SIV da Solari (atraves do NET2000 ou o SIIV da Infraero)
      0: begin     // Solari NET2000
            case fIxPagHtmlSolari of
              0,1: aVooTop:=0;        //de acordo com a pagina downloadada, pega ..
              2: aVooTop:=20;         //..voos em posicoes multiplas de 20 (como no html da Solari)
              3: aVooTop:=40;
              4: aVooTop:=60;
              5: aVooTop:=80;
            else
              exit;
            end;
         end;
      1: begin          // Infraero SIIV (usando servidor intermediário)
           aVooTop:=0;  // SIIV tem uma pagina só, em txt
         end;
  else
    exit;
  end;
  //faz update dos campos dos voos em fVoos[]
  bPartidas:=(RGTipoPagina.ItemIndex in [1,2]); //partidas ou chegadas ?
  bAlgumVooChanged:=FALSE;
  for r:=1 to aTNP.RowCount-1 do //pula a 1a linha (r=0), que tem os cabeçalhos da tabela
    begin
      ixv:=aVooTop+r-1;          //indice do voo no banco de dados interno
      if (ixv>=0) and (ixv<MAXVOOS) then
        begin
          case iTipoDeBancoDeDados of
            0: UpdateVooSolari;
            1: UpdateVooInfraero_obsoleto;
          end;
        end
    end;
  //se mudou algum campo de algum voo, renderiza display virtual e real (mezzo forza bruta questo...)
  if bAlgumVooChanged then
    begin
      ReposicionaVoosNoDisplayVirtual;                       //renderiza display virtual
      //era RenderizaVoosNoDisplayReal({bChangedOnly=}TRUE)
      //isso falhava quando um voo não se alterava, mas mudava de lugar no display virtual
      RenderizaVoosNoDisplayReal({bChangedOnly=} false); //renderiza todos !
    end;
end;

function Tira2pontosDeHora(const S:String):String;  //  '10:32' --> '1032'
var p:integer;
begin
  Result:=Trim(S);
  p:=Pos(':',Result);
  if p>0 then Delete(Result,p,1);
end;

// N num do voo ( 0..MAXVOOS-1)
// St: Stringtokenizer com os items[]
function TFormAirportDisplayControl.AtualizaVooInfraeroSIIV(N:integer; aST:TStringTokenizer):boolean; //jun07
var aEscalas,aObs,aEsteira:String; aSTEscalas:TStringTokenizer; NE,i,p:integer; bPartidas:boolean; aVoo:TInformacaoDeVoo;
begin {AtualizaVooInfraeroSIIV}
  //ve quais os voos que estao nesta pag html (pega o top)
  Result:=false;
  //faz update dos campos dos voos em fVoos[]
  bPartidas:=(RGTipoPagina.ItemIndex in [1,2]); //partidas ou chegadas ?
  aVoo:=fVoos[N];
  aVoo.SIVVendor:=svInfraero;
  aVoo.Changed:=FALSE; // a setagem dos campos individuais altera o campo changed dos voos
  if CBAtualizaStringGrid.Checked then
    begin
      if (N>StringGrid1.RowCount) then StringGrid1.RowCount:=N+1;
      if (aST.Count>StringGrid1.ColCount) then StringGrid1.ColCount:=aST.Count+1;
      StringGrid1.Cells[0,N+1]:=IntToStr(N);
      for i:=0 to aST.Count-1 do
        StringGrid1.Cells[i+1,N+1]:=aST.Items[i]; //preeenche grid com dados do table parser
    end;

  with aVoo do if bPartidas then
    begin         //partidas
      //            0    1               2                             3     4     5    6  7                    8
      //partidas: 'GLO;1642;Manaus/Fortaleza/São Luis/Belém/Santarém;08:50;09:03;Norte;14;EMI;Embarque Imediato/Now Boarding;'
      //ou seja:    0:Sigla do Vôo; 1:Número Vôo; 2:Destino/Escalas;3:STD;4:ETD;5:Sala;6:Portão;7:Sigla Situação;8:Observação/Remarks;
      IndexVoo:=N;  FlighType:=ftDeparture;
      AirLine := aST.Items[0];
      Voo     := aST.Items[1];
      aEscalas:= aST.Items[2]; //aEscalas tipo 'Manaus/Fortaleza/São Luis/Belém/Santarém'
      aSTEscalas:=TStringTokenizer.Create(nil,aEscalas,'/');
      try                     //     0       1        2       3       4
        NE:=aSTEscalas.Count; // 'Manaus/Fortaleza/São Luis/Belém/Santarém' (NE=5)
        for i:=0 to 4 do  //destino e 4 escalas vem tudo junto
          begin
             case i of
               0: if (i<NE) then Destino:=aSTEscalas.Items[i] else Destino:='';
               1: if (i<NE) then Escala1:=aSTEscalas.Items[i] else Escala1:='';
               2: if (i<NE) then Escala2:=aSTEscalas.Items[i] else Escala2:='';
               3: if (i<NE) then Escala3:=aSTEscalas.Items[i] else Escala3:='';
               4: if (i<NE) then Escala4:=aSTEscalas.Items[i] else Escala4:='';
             end;
          end;
      finally
        aSTEscalas.Free;
      end;
      Origem:=''; //partida não tem origem, limpa
      SomeTime      :=Tira2pontosDeHora(aST.Items[3]); //TODO: isso está certo ?
      EstimatedTime :=Tira2pontosDeHora(aST.Items[4]);
      // :=Trim(aST.Items[5]);     //e a sala não usa ?
      Gate          :=Trim(aST.Items[6]);
      StatusCode    :=Trim(aST.Items[7]);
      aObs:=aST.Items[8];
      p:=Pos('/',aObs);
      if (p>0) then
        begin
          StatusMsgPor:=Copy(aObs,1,p-1);
          StatusMsgEng:=Copy(aObs,p+1,MAXINT);
        end
        else begin // isso não pode...
          StatusMsgPor:=aObs;
          StatusMsgEng:='';
        end;
      Destacado:=StatusDestacado(StatusCode);
    end
    else begin   //chegadas
      //            0    1     2       3     4   5   6    7             8
      //chegadas: 'GLO;1642;Salvador;08:25;08:33;6;Norte;PSD;Aeronave no Pátio/Landed;'
      //ou seja:  0:Sigla do Vôo; 1:Número Vôo; 2:Origem/Escalas;3:STA;4:ETA;5:Esteira;6:Sala;7:Sigla Situação;8:Observação/Remarks;
      IndexVoo:=N;  FlighType:=ftArrival;
      AirLine := aST.Items[0];
      Voo     := aST.Items[1];
      aEscalas:= aST.Items[2]; //aEscalas tipo 'Manaus/Fortaleza/São Luis/Belém/Santarém'
      aSTEscalas:=TStringTokenizer.Create(nil,aEscalas,'/');
      try                     //     0       1        2       3       4
        NE:=aSTEscalas.Count; // 'Manaus/Fortaleza/São Luis/Belém/Santarém' (NE=5)
        for i:=0 to 4 do  //destino e 4 escalas vem tudo junto
          begin
             case i of
               0: if (i<NE) then Origem:=aSTEscalas.Items[i]  else Origem:='';
               1: if (i<NE) then Escala1:=aSTEscalas.Items[i] else Escala1:='';
               2: if (i<NE) then Escala2:=aSTEscalas.Items[i] else Escala2:='';
               3: if (i<NE) then Escala3:=aSTEscalas.Items[i] else Escala3:='';
               4: if (i<NE) then Escala4:=aSTEscalas.Items[i] else Escala4:='';
             end;
          end;
      finally
        aSTEscalas.Free;
      end;
      Destino:=''; //partida não tem origem, limpa
      SomeTime      :=Tira2pontosDeHora(aST.Items[3]); //TODO: isso está certo ?
      EstimatedTime :=Tira2pontosDeHora(aST.Items[4]);
      // :=Trim(aST.Items[5]);      //e a sala não usa ?
      aEsteira      :=Trim(aST.Items[5]);  //Esteira é coluna 'Est'
      if (aEsteira<>'') then Esteira:=aEsteira[1] else Esteira:=' '; //isso fica no SIIV ?
      Gate          :=Trim(aST.Items[6]);                            //gate é sala no SIIV ?
      StatusCode    :=Trim(aST.Items[7]);
      aObs:=aST.Items[8];
      p:=Pos('/',aObs);
      if (p>0) then
        begin
          StatusMsgPor:=Copy(aObs,1,p-1);
          StatusMsgEng:=Copy(aObs,p+1,MAXINT);
        end
        else begin    // isso não pode...
          StatusMsgPor:=aObs;
          StatusMsgEng:='';
        end;
      Destacado:=StatusDestacado(StatusCode);
    end;
  Result:=aVoo.Changed;
  //se mudou algum campo de algum voo, renderiza display virtual e real (mezzo forza bruta questo...)
end;

function TFormAirportDisplayControl.ParseHtmlPageInformacaoDeVoo:boolean; //true se parse ok (i.e. encontrou a tabela de voos)
var aTL:TTagNodeList; aHtmlParser:THtmlParser; aTable:TTagNode;
    aTNP:TTableNodeParser; i,r,c:integer; S,aTexto:String; aTableName:String;
    ast:TStringTokenizer; SL:TStringList; bAlgumVooChanged:boolean;
begin
   Result:=FALSE;
   //pega texto recebido via http
   C:=fThreadDownloadInfo.Stream.Size;
   if (C>0) then
      begin
       SetLength(aTexto,C);
       fThreadDownloadInfo.Stream.Position:=0;
       fThreadDownloadInfo.Stream.ReadBuffer(aTexto[1],C);
      end
      else begin
        MonitorAddMessage('Sem conteúdo');
        exit;
      end;
   //aTexto contem texto baixado
   case RGQualBancoDeDados.ItemIndex of //pode ser o SIV da Solari (atraves do NET2000 ou o SIIV da Infraero)
     0: begin //Solari
          aHtmlParser:=THtmlParser.Create(nil);
          aTL:=TTagNodeList.Create;
          try
            aHtmlParser.Parse(aTexto);                                  //parse do HTML.
            aHtmlParser.Tree.GetTags('table',aTL);                      //pega lista linear com todos os tags
            aTableName:='NET2000';                                      //vtaff da Solari contem tabela 'NET2000'
            aTable:=aTL.FindTagByParam('table','NAME',aTableName);      //Acha a tabela com parametro 'NAME=NET2000'
            if Assigned(aTable) then  //achou, pega os conteudos das celulas
              begin
                aTNP:=TTableNodeParser.Create;
                try
                  aTNP.ParseNode(aTable); //pega as celulas da pagina
                  //mostra a tabela no grid, se opcao setada
                  if CBAtualizaStringGrid.Checked then
                    begin
                      StringGrid1.RowCount:=aTNP.RowCount;
                      StringGrid1.ColCount:=aTNP.ColCount;
                      for r:=0 to aTNP.RowCount-1 do for c:=0 to aTNP.ColCount-1 do
                        StringGrid1.Cells[c,r]:=aTNP.Cells[c,r]; //preeenche grid com dados do table parser
                    end;
                  AtualizaVoosSolari(aTNP);  //isso remove os campos dos voos da tabela
                  Result:=TRUE;              //se aqui, tabela de voos foi parseada e está ok
                finally
                  aTNP.Free;
                end;
              end
              else MonitorAddMessage('tabela de voos não encontrada');
          finally
            aTL.Free;
            aHtmlParser.Free;
          end;
        end;  // /Solari
     1: begin  // jun07: adaptação p/ SIIV 2007
         aST:=TStringTokenizer.Create(nil,'',';');
         SL:=TStringList.Create;
         SL.Text:=aTexto;
         bAlgumVooChanged:=false;
         for i:=0 to SL.Count-1 do
           begin
             S:=Trim(SL.Strings[i]); //pega linha com um voo
             if (S='') then continue;
             aST.Str:=S;
             //S tipo da infraero (as of jun/07)
             //partidas: 'GLO;1642;Manaus/Fortaleza/São Luis/Belém/Santarém;08:50;09:03;Norte;14;EMI;Embarque Imediato/Now Boarding;'
             //chegadas: 'GLO;1642;Salvador;08:25;08:33;6;Norte;PSD;Aeronave no Pátio/Landed;'
             if (aST.Count>=9) then //min de 9 campos
               if AtualizaVooInfraeroSIIV(i,aST) then
                 bAlgumVooChanged:=true;
           end;
          if bAlgumVooChanged then
            begin
              ReposicionaVoosNoDisplayVirtual;                       //renderiza display virtual
              //era RenderizaVoosNoDisplayReal({bChangedOnly=}TRUE)
              //isso falhava quando um voo não se alterava, mas mudava de lugar no display virtual
              RenderizaVoosNoDisplayReal({bChangedOnly=} false); //renderiza todos !
            end;
          Result:=TRUE;              //se aqui, tabela de voos foi parseada e está ok
        end; //  /SIIV 2007
   end;  // /case
end;

procedure TFormAirportDisplayControl.DLIOnTerminate(Sender: TObject);
var ok:boolean;
begin
  if Assigned(fThreadDownloadInfo.Stream) and (fThreadDownloadInfo.HttpStatus=200) then
    begin
      LStatus.Caption:='Download completo';      //HttpStatus=200 indica sucesso
      inc(fNumDownloads);
      try
        ok:=ParseHtmlPageInformacaoDeVoo;
        if ok then fHoraLastDownloadOk:=now;   //salva hora do ultimo download ok
      except
        MonitorAddMessage('Erro no parse da pagina');
      end;
    end
    else begin
      if fThreadDownloadInfo.MessageText<>'' then LStatus.Caption:=fThreadDownloadInfo.MessageText
        else LStatus.Caption:='Http Status: '+IntToStr(fThreadDownloadInfo.HttpStatus);
      inc(fNErrosDownload);
      MonitorAddMessage(LStatus.Caption);
    end;
  UpdateLabelsEstatisticas;
  LOperation.Caption:='';
  fThreadDownloadInfo:=nil;
  TransformaBCloseEmFecha;
end;

procedure TFormAirportDisplayControl.UpdateLabelsEstatisticas;
begin
  LNDownloads.Caption:=IntToStr(fNumDownloads);
  LNAtualizacoes.Caption:=IntToStr( fNumAtualizacoes);
  LNErrosDownload.Caption:=IntToStr(fNErrosDownload);
end;

procedure TFormAirportDisplayControl.MonitorAddMessage(const S:String);
begin
  Monitor.Lines.Add(TimeToStr(Time)+':'+S);
  while Monitor.Lines.Count>100 do Monitor.Lines.Delete(0); //apaga a mais antiga, deixando só as 20 ultimas
end;

procedure TFormAirportDisplayControl.BDownloadNowClick(Sender: TObject);
begin
  if not Assigned(fThreadDownloadInfo) then //so mantem um download por vez
    begin
      GetFromControls;
      BeginDownload;
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.GetFromControls;
begin
  fHost    :=EdHost.Text;
  fHostPort:=EdPortaServidor.Value;
  fPageName:=EdFileName.text;
  fWebPath :=EdPath.text;
end;

procedure TFormAirportDisplayControl.BClearMonitorClick(Sender: TObject);
begin
  Monitor.Lines.Clear;
end;

procedure TFormAirportDisplayControl.AlocaVoos;  //cria os registros de voo
var i:integer;
begin
  for i:=0 to MAXVOOS-1 do
    fVoos[i]:=TInformacaoDeVoo.Create;
end;

procedure TFormAirportDisplayControl.DestroeVoos;
var i:integer;
begin
  for i:=0 to MAXVOOS-1 do fVoos[i].Free;
end;

procedure TFormAirportDisplayControl.BDownloadPaginaInfraeroClick(Sender: TObject);
var Pg:integer;
begin
  Pg:=0; //invalido
  case RGQualBancoDeDados.ItemIndex of //pode ser o SIV da Solari (atraves do NET2000 ou o SIIV da Infraero)
    0: begin  // Solari NET2000
         Case RGTipoPagina.ItemIndex of
           0: Pg:=30; //chegadas  --> pgs 'VSTAFF.031.HTML' a 'VSTAFF.040.HTML'
           1: Pg:=40; //partidas  --> pgs 'VSTAFF.041.HTML' a 'VSTAFF.050.HTML'
           2: Pg:=40; //partidas  --> pgs 'VSTAFF.041.HTML' a 'VSTAFF.050.HTML'
           3: Pg:=30; //chegadas  3D -->
         end;
         // Ago07: nos internacionais temos:
         //chegadas  --> pgs 'VSTAFF.011.HTML' a 'VSTAFF.020.HTML'
         //partidas  --> pgs 'VSTAFF.021.HTML' a 'VSTAFF.030.HTML'
         if (rgInternacionallDomestico.ItemIndex=1) and (Pg>0) then //Internacional subtrai 200 do num da pagina
           dec(Pg,20);
         Pg:=Pg+fIxPagHtmlSolari;
         EdFilename.text:='VSTAFF.0'+IntToStr(Pg)+'.HTML'; 
       end;
    1: begin // Infraero SIIV (usando servidor intermediário)
         Case RGTipoPagina.ItemIndex of
           0: EdFilename.text:='Siiv_T_Chegadas.txt';        //chegadas
           1: EdFilename.text:='Siiv_T_Partidas.txt';        //partidas
           2: EdFilename.text:='Siiv_T_Partidas.txt';        //partidas
           3: EdFilename.text:='Siiv_T_chegadas.txt';        //chegadas 3D
         end;
       end;
  end;
  BDownloadNowClick(nil); //inicia o download
end;

procedure TFormAirportDisplayControl.CBAtualizacaoAutomaticaClick(Sender: TObject);
begin
  if CBAtualizacaoAutomatica.Checked then
    begin
      TimerAutomacao.Interval:=EdSegundos.Value*1000;
    end;
  TimerAutomacao.Enabled:=CBAtualizacaoAutomatica.Checked;
end;

//Ret true se mostando screen saver. A fn tb ativa e desativa o screen saver
function TFormAirportDisplayControl.ScreenSaving:boolean;
var HoraIni,HoraFim:TDateTime;
begin
  Result:=FALSE;
  if CBScreenSaverAtivado.Checked then
    begin
      try HoraIni:=StrToTime(EdScreenSaverDas.Text); except HoraIni:=1; end;
      try HoraFim:=StrToTime(EdScreenSaverAte.Text); except HoraFim:=0; end;
      Result:=(Time>HoraIni) or (Time<HoraFim);
      FormADScreenSaver.Visible:=Result;
    end;
end;

procedure TFormAirportDisplayControl.CBDemagnetizadorAtivadoClick(Sender: TObject);
var Minutos:integer;
begin
  Minutos:=StrToIntDef(EdDemagnetizadorMin.text,10);
  if Minutos<=0 then Minutos:=1;            //nao permite intervalo zero minutos
  fNextDesmagnetization:=Now+Minutos/60/24; //proxima desmagnetizacao daqui a 10 min
end;

// jul/02 - Estava ficando uns lixos em alguns flaps em momentos de pouca atividade.
// A razao nao foi determinada. Sei que os flaps podem ficar com lixo se funcionando ocultados
// atraz de outras janelas, mas nao deveria acontecer em condicoes normais de operação.
// Essa rotina temporizada faz periodicamente a renderizacao completa dos flaps,
// para garantir que está tudo ok. É um "work around"....
procedure TFormAirportDisplayControl.ChecaFlapRefresher;
var T:TDateTime;
const DezMinutos=10/24/60;
begin
  T:=Now;
  if  CBRefresherAtivado.Checked and (T-fHoraLastRefresh>DezMinutos) then
    begin
      ForcaRenderizacaoDosFlaps;
      fHoraLastRefresh:=T;
    end;
end;

procedure TFormAirportDisplayControl.ChecaDesmagnetizador;
var Minutos,Segundos:integer;
begin
  if CBDemagnetizadorAtivado.Checked and (Now>fNextDesmagnetization) then
    begin
      Segundos:=StrToIntDef(EdDemagnetizadorSecs.text,2);
      Minutos:=StrToIntDef(EdDemagnetizadorMin.text,10);
      if Minutos<=0 then Minutos:=1;            //nao permite intervalo zero minutos
      fNextDesmagnetization:=Now+Minutos/60/24; //proxima desmagnetizacao daqui a 10 min

      FormADScreenSaver.Desmagnetiza(Segundos);
    end;
end;

// Se ficar sem fazer download por muito tempo, a informação fica desatualizada.
// Essa checagem limpa o display de voo, mostrando que a coisa está parada.
procedure TFormAirportDisplayControl.ChecaSeOffline;
var MinutosOffline:integer;
begin
  if CBChecaSeOffline.Checked then
    begin
      MinutosOffline:=trunc((Now-fHoraLastDownloadOk)*60*24);
      if (MinutosOffline>=EdMinutosOffline.Value) then //..está offline há muito tempo !
        begin
          ClearVoos;   //isso limpa todos os campos de todos os voos
          RenderVoos;  //isso verifica a visibilidade dos voos e renderiza no display real, limpando a tela
          LStatusOffline.Caption:='offline';
        end
        else LStatusOffline.Caption:='online';
    end;
end;

procedure TFormAirportDisplayControl.TimerAutomacaoTimer(Sender: TObject); //a cada 15 seg
begin
  if not ScreenSaving then //se no screen saver, nao downloada informacao
    begin
      if not Assigned(fThreadDownloadInfo) then              //download proxima proxima
        begin
          //avança num da pagina
          fIxPagHtmlSolari:=fIxPagHtmlSolari+1;              //avança antes de downloadar (no caso da Solari, que tem várias paginas)
          if (fIxPagHtmlSolari>EdMaxPaginasInfraero.Value) then
            fIxPagHtmlSolari:=1;    //carrega só 3 paginas
          BDownloadPaginaInfraeroClick(nil);                 //dispara download
        end;
      ChecaDesmagnetizador;
      ChecaFlapRefresher;
      ChecaSeOffline;
    end;
end;

function TFormAirportDisplayControl.UsaFormAirportDisplay:boolean;
begin
  Result:=RGTipoPagina.ItemIndex in [0,1]; //telas de partidas e chegadas com multiplos voos
  //o index 2 é a sala de portão, que está em outro Form
end;

function TFormAirportDisplayControl.UsaFormGLAirportDisplay:boolean;
begin
  Result:=RGTipoPagina.ItemIndex in [3]; //telas de partidas e chegadas com multiplos voos em OpenGL
  //o index 2 é a sala de portão, que está em outro Form
end;

procedure TFormAirportDisplayControl.RGTipoPaginaClick(Sender: TObject);
var bDepartures:boolean; bEhAMC:boolean;
begin
  case RGTipoPagina.ItemIndex of
    0,1: if Assigned(FormAirportDisplay) then //paginas com multiplos voos
           begin
             bDepartures:=(RGTipoPagina.ItemIndex=1);
             FormAirportDisplay.EhDepartures:=bDepartures;
             if bEhAirportDisplay then   //No AMC não mostra nada (deixa o Autobrowser fazer o embed e mostrar)
               FormAirportDisplay.Visible:=TRUE;
             if Assigned(FormDisplayPortao) then FormDisplayPortao.Visible:=FALSE;
             {$IFDEF PAINEL_3D}
             if Assigned(FormGLAirportDisplay) then FormGLAirportDisplay.Visible:=FALSE;
             {$ENDIF PAINEL_3D}
             EnableGlobalFlapLabelTimer(true);  //(start/stop flap timers (pára flaps não visiveis)
             {$IFDEF PAINEL_3D}
             EnableGlobalGLFlapLabelTimer(false);
             {$ENDIF PAINEL_3D}
           end;
    2:   if Assigned(FormDisplayPortao) then //TODO - Pagina de portão com apenas um voo
           begin
             if bEhAirportDisplay then
               FormDisplayPortao.Visible:=TRUE;
             if Assigned(FormAirportDisplay) then FormAirportDisplay.Visible:=FALSE;
             {$IFDEF PAINEL_3D}
             if Assigned(FormGLAirportDisplay) then FormGLAirportDisplay.Visible:=FALSE;
             {$ENDIF PAINEL_3D}
             EnableGlobalFlapLabelTimer(true);  //(start/stop flap timers (pára flaps não visiveis)
             {$IFDEF PAINEL_3D}
             EnableGlobalGLFlapLabelTimer(false);
             {$ENDIF PAINEL_3D}
           end;
    3:  begin
          //esse cria on demand, para não usar coisa em testes na ver de produção
          {$IFDEF PAINEL_3D}
          if not Assigned(FormGLAirportDisplay) then
            FormGLAirportDisplay:=TFormGLAirportDisplay.Create(Application);
          if Assigned(FormGLAirportDisplay) then //paginas com multiplos voos em OpenGL
             begin
               bDepartures:=true; //TODO: implementar chegadas
               //FormGLAirportDisplay.EhDepartures:=bDepartures;
               if bEhAirportDisplay then
                 FormGLAirportDisplay.Visible:=TRUE;
               if Assigned(FormDisplayPortao) then FormDisplayPortao.Visible:=FALSE;
               if Assigned(FormAirportDisplay) then FormAirportDisplay.Visible:=FALSE;
               EnableGlobalGLFlapLabelTimer(true);  //(start/stop flap timers (pára flaps não visiveis)
               EnableGlobalFlapLabelTimer(false);
             end;
         {$ENDIF PAINEL_3D}
        end;
  end;
end;

Procedure TFormAirportDisplayControl.RenderVoos; //forca a atualizacao de todos os voos..
var N,ND,i:integer; aVoo: TInformacaoDeVoo;
begin
  ReposicionaVoosNoDisplayVirtual;                     //renderiza display virtual
  RenderizaVoosNoDisplayReal({bChangedOnly=}FALSE);    //e no real (TODOS !)
end;

//reposiciona os voos no display virtual desde o inicio.
Procedure TFormAirportDisplayControl.ReposicionaVoosNoDisplayVirtual;
var N,ND,i:integer; aVoo,aVooAnt:TInformacaoDeVoo; bMudouDeLugar:boolean;
begin
  N:=0;  //N =posicao no display virtual (de 0 a MAXVOOS-1)
  ND:=0; //ND=posicao no display real
  aVooAnt:=nil;
  for i:=0 to MAXVOOS-1 do   //começa desde o inicio...
    begin
      aVoo:=fVoos[i];
      VerificaVisibilidade_Voo(aVoo); //aplica filtro
      //fev08: tira visibilidade do segundo voo de parceria (só o primeiro aparece)
      //depois, na hora de renderizar, se tiver parceria usa SubTexts
      if aVoo.Visivel and Assigned(aVooAnt) and (aVoo.Matricula<>'') and (aVoo.Matricula=aVooAnt.Matricula) then  //fev08: era: Assigned(aV) and (aVoo.Voo=aV.Voo);
        begin
          aVoo.Visivel:=false;
        end;
      if aVoo.Visivel then   //se voo visivel, adiciona no display virtual
        begin
          aVoo.IxNoDisplayVirtual:=N;                //reposiciona no virtual
          inc(N);
        end
        else aVoo.IxNoDisplayVirtual:=-1; //se voo invisivel, -1
      aVooAnt:=aVoo;
    end;
  ChecaVoosEmParceria;   //verifica se tem parcerias entre os voos
end;

//Ve se é status preferencial em display de portao (LAC=LastCAll e NBD=NowBorDing)
function EhStatusPreferencialPortao(aVoo:TInformacaoDeVoo):boolean;
begin
  Result:=Assigned(aVoo) and ((aVoo.StatusCode='LAC') or (aVoo.StatusCode='NBD'));
end;

//tendo os voos devidamente posicionados no display virtual,
//renderiza-os no display real...
procedure TFormAirportDisplayControl.RenderizaVoosNoDisplayReal(bChangedOnly:boolean);
var N,ND,i,NLastVisible:integer; aVoo,aVooPortao:TInformacaoDeVoo; bRenderizaEsse:boolean;
begin
  N:=0;  //N =posicao no display virtual (de 0 a MAXVOOS-1)
  ND:=0; //ND=posicao no display real (de acordo com a pagina exibida)
  NLastVisible:=-1;
  aVooPortao:=nil;        //o voo mostrado no display de portao, se for o caso
  //era: for i:=0 to MAXVOOS-1 do   //começa desde o inicio...
  for i:=MAXVOOS-1 downto 0 do   //começa de trás pra frente ...
    begin
      aVoo:=fVoos[i];
      N:=aVoo.IxNoDisplayVirtual;
      if (aVoo.Visivel and (N>=0) and (N>NLastVisible)) then NLastVisible:=N; //salva pos no display virtual do ultimo voo visivel (max)
      //renderiza voo
      if bChangedOnly then bRenderizaEsse:=aVoo.Changed
        else bRenderizaEsse:=TRUE;          //render all
      if bRenderizaEsse and aVoo.Visivel and (N>=0) then   //se voo visivel, renderiza no display real
        begin
          //aqui usava um bMudouDeLugar  de lugar que eu tirei. O que pode acontecer é ter
          //renderizacao redundante. Isso abunda mas não prejudica (espero...)
          ND:=N-fIxTopFlight;   //calc posicao no display real (0..24), de acordo com a pagina sendo mostrada

          if UsaFormAirportDisplay and Assigned(FormAirportDisplay) then //.. o voo está visivel no display
            begin
              if (ND>=0) and (ND<MAXLINEMANAGERS) then
                begin
                  if cbAtualizacoesEmCascata.Checked then fVoosDeferedUpdate.AddVooAlterado(ND,aVoo)
                    else FormAirportDisplay.SetInfoVoo(ND,aVoo);  //atualiza no display real direto
                end;
            end
            {$IFDEF PAINEL_3D}
            else if UsaFormGLAirportDisplay and Assigned(FormGLAirportDisplay) then //display 3D
            begin
              if (ND>=0) and (ND<MAXLINEMANAGERS) then
                begin
                  if cbAtualizacoesEmCascata.Checked then fVoosDeferedUpdate.AddVooAlterado(ND,aVoo)
                    else FormGLAirportDisplay.SetInfoVoo(ND,aVoo);  //atualiza no display real
                end;
            end
            {$ENDIF PAINEL_3D}
            else begin //display de portao
              if ND=0 then aVooPortao:=aVoo   //inicializa aVooPortao com o primeiro voo que tiver na lista (voo 0)
                else begin                    //se o voo nao tiver status preferencial e algum outro tiver, usa o outro
                  if (not EhStatusPreferencialPortao(aVooPortao)) and EhStatusPreferencialPortao(aVoo) then
                    aVooPortao:=aVoo;
                end;
            end;
        end;
    end;

  //nov/04 - O display de portao tem uma logica propria. A princípio, é mostrado o voo indice 0 (o topo da lista)
  //mas se esse voo nao tiver um status preferencial (LAC ou NBD) e algum outro tiver, entra o outro
  if (not UsaFormAirportDisplay) and
    {$IFDEF PAINEL_3D}
    (not UsaFormGLAirportDisplay) and
    {$ENDIF PAINEL_3D}
    Assigned(FormDisplayPortao) then
    begin
      FormDisplayPortao.SetInfoVoo(0,aVooPortao);   //atualiza no display de portão
    end;

  //Aqui pode ter que apagar algum voo velho no display virtual, se num de voos visiveis < 50 (2 paginas)
  //Aqui N aponta 1 depois do ultimo voo visivel
  ND:=NLastVisible+1-fIxTopFlight;    //calc posicao no display real (0..24), de acordo com a pagina sendo mostrada


  if UsaFormAirportDisplay and Assigned(FormAirportDisplay) then
    for i:=ND to MAXLINEMANAGERS-1 do   //renderiza voos vazios para agagar velharias no fim do display real (i.e. até completar 25 linhas)
      begin
        if (i>=0) then
          begin
            if cbAtualizacoesEmCascata.Checked then fVoosDeferedUpdate.AddVooAlterado(i,nil)
              else FormAirportDisplay.SetInfoVoo(i,nil);  //isso limpa display
          end;
      end;

  {$IFDEF PAINEL_3D}
  if UsaFormGLAirportDisplay and Assigned(FormGLAirportDisplay) then
    for i:=ND to MAXLINEMANAGERS-1 do   //renderiza voos vazios para agagar velharias no fim do display real (i.e. até completar 25 linhas)
      begin
        if (i>=0) then
          begin
            if cbAtualizacoesEmCascata.Checked then fVoosDeferedUpdate.AddVooAlterado(i,nil)
              else FormGLAirportDisplay.SetInfoVoo(i,nil);  //isso limpa display
          end;
      end;
  {$ENDIF PAINEL_3D}
end;

procedure TFormAirportDisplayControl.TimerAtualizaEmCascataTimer(Sender: TObject);
var ND:integer; aVoo:TInformacaoDeVoo;
begin
  LFilaDeferimento.Caption:=IntToStr(fVoosDeferedUpdate.Count);
  if fVoosDeferedUpdate.GetVooParaAtualizacao(ND,aVoo) then
    begin
      if UsaFormAirportDisplay and Assigned(FormAirportDisplay) then //.. o voo está visivel no display
        begin
          FormAirportDisplay.SetInfoVoo(ND,aVoo);  //atualiza no display real direto
        end
        {$IFDEF PAINEL_3D}
        else if UsaFormGLAirportDisplay and Assigned(FormGLAirportDisplay) then //display 3D
        begin
          FormGLAirportDisplay.SetInfoVoo(ND,aVoo);  //atualiza no display real
        end;
        {$ENDIF PAINEL_3D}
    end;
end;

//chamar com os voos já posicionados no display virtual
//estabelece as parcerias entre voos
procedure TFormAirportDisplayControl.ChecaVoosEmParceria;
var i:integer; aVoo,aVooAnt1,aVooAnt2,aVooAnt3:TInformacaoDeVoo;

  function  TemParceriaCom_aVoo(aV:TInformacaoDeVoo):boolean;
  begin
    //fev08: a parceria se estabelece pela Matricula igual (i.e. o mesmo avião)
    Result:= {aVoo.Visivel and}  //comentado fev08: verifica parceria mesmo que voo invisivel
       Assigned(aV) and (aVoo.Matricula<>'') and (aVoo.Matricula=aV.Matricula);  //fev08: era: Assigned(aV) and (aVoo.Voo=aV.Voo);
    //alterei para usar a matricula do avião como criterio de parceria
    if Result then    //seta parceria reciproca (mesmo numero de voo)
      begin
        aV.SetVooParceria(aVoo);  // seta parceria..
        aVoo.SetVooParceria(aV);  // ..reciproca.
      end;
  end;

begin  //ChecaVoosEmParceria
  //verifica parcerias de voos (2 voos com mesmo numero e companhias diferentes)
  aVooAnt1:=nil;      //gambiarra... os voos em parceria podem nao ser contiguos na tabela (infraero !)
  aVooAnt2:=nil;
  aVooAnt3:=nil;

  for i:=0 to MAXVOOS-1 do   //começa desde o inicio...
    begin
      aVoo:=fVoos[i];
      if TemParceriaCom_aVoo(aVooAnt1) or TemParceriaCom_aVoo(aVooAnt2) or  TemParceriaCom_aVoo(aVooAnt3) then
        begin
          //nada, a fn TemParceriaCom_aVoo já seta a parceria
        end
        else aVoo.SetVooParceria(nil); //este nao tem parceria (por enquanto)
      //salva anteriores
      aVooAnt3:=aVooAnt2;
      aVooAnt2:=aVooAnt1;
      aVooAnt1:=aVoo;
    end;
end;

//Alguns voos na tabela html vem vazios....
function VooVazio(aVoo: TInformacaoDeVoo):boolean;
begin
  Result:=(Trim(aVoo.AirLine)='');
end;

//seta var aVoo.Visivel, de acordo com o cj de filtros.
Procedure TFormAirportDisplayControl.VerificaVisibilidade_Voo(aVoo: TInformacaoDeVoo);
var bVooVisivel:boolean; p:integer; C:Char;
begin
  //aplica filtros de visibilidade no voo (filtros em arquivos de exclusao)
  bVooVisivel:=(not AirlineExcluida(aVoo.AirLine)) and  //alguns airlines nao sao visiveis (ex: 'HEL' de helicoptero)
    (not StatusExcluido(aVoo.StatusCode)) and (not VooVazio(aVoo));
  //aplica filtros contidos no form

  if bVooVisivel and CBSomenteVoosDoPortao.Checked then   //ago/04-Era CBSomenteVoosDaSala.
    bVooVisivel:=(aVoo.Gate=EdNomePortao.Text);

  if bVooVisivel and CBSomenteAirline.Checked then
    bVooVisivel:=(CompareText(aVoo.AirLine,EdAirline.Text)=0);

  if bVooVisivel and cbExcluiAirline.Checked then
    bVooVisivel:= not (CompareText(aVoo.AirLine,EdExcluiAirline.Text)=0);

  if bVooVisivel and CBSomenteStatus.Checked then
    begin
      p:=Pos(aVoo.StatusCode,EdSomenteStatus.Text); // EdSomenteStatus.Text pode ser do tipo 'PAT,LAN'
      bVooVisivel:=(p>0);
    end;

  if bVooVisivel and CBSomenteEsteira.Checked then
    bVooVisivel:=(CompareText(aVoo.Esteira,EdSomenteEsteira.Text)=0);

  if bVooVisivel and cbVooNaoComecePor.Checked and (aVoo.Voo<>'') then //Ago07: filtro pra guarulhos
    begin
      C:=aVoo.Voo[1];                   //pega 1o digito do voo
      p:=Pos(C,edVooNaoComecePor.Text); //vê se voo começa por alguma letra do filtro ( p.e. voos começados por 'C' é cargueiro, não aparece )
      bVooVisivel:=(p<=0);              //voo é visivel se não começar com as letra do filtro
    end;

  aVoo.Visivel:=bVooVisivel;                       //seta nova visibilidade do voo
end;

// Voo modificado desde o ultimo download. Atualiza no display...
// Aqui sao aplicados os filtros
(* procedure TFormAirportDisplayControl.DoVooModificado(ixv: integer; aVoo: TInformacaoDeVoo);
var N,ND:integer; bVooVisivel,bVooVisivelAnt:boolean;
begin
  bVooVisivelAnt:=(aVoo.IxNoDisplayVirtual>=0);    //salva como estava antes
  VerificaVisibilidade_Voo(aVoo);
  bVooVisivel:=aVoo.Visivel;

  if (bVooVisivel<>bVooVisivelAnt) then       //se mudou a visibilidade, tem que reposicionar todos os voos abaixo (inclusive esse)
    ReposicionaVoosNoDisplayVirtual;

  N:=aVoo.IxNoDisplayVirtual;
  ND:=N-fIxTopFlight;                              //calc posicao no display real (0..24), de acordo com a pagina mostrada
  if UsaFormAirportDisplay and Assigned(FormAirportDisplay) then //.. o voo está visivel no display real
    begin
      if (ND>=0) and (ND<MAXLINEMANAGERS) then
        begin
          FormAirportDisplay.SetInfoVoo(ND,aVoo);
          inc(fNumAtualizacoes);
        end;
    end
    else if Assigned(FormDisplayPortao) then
      begin
        if (ND=0) then
          begin
            FormDisplayPortao.SetInfoVoo(ND,aVoo);  // atualiza no display de portão (só o voo 0 é que pararece
            inc(fNumAtualizacoes);
          end;
      end;
end; *)

procedure TFormAirportDisplayControl.CBServidorHttpAtivadoClick(Sender: TObject);
var bStarted:boolean;
begin
  //durante o carregamento dos settings, nao habilita o servidor htto, pois
  //a porta pode ainda nao ter sido especificada. Faz isso no final do carregamento...
  if not fCarregandoSettings then
    begin
      bStarted:=CBServidorHttpAtivado.Checked;
      if bStarted then
        begin
          MonitorAddMessage('Srv Http iniciado');
          HttpSrv.ServerPort:=EdPortaHttp.Value;
        end
        else MonitorAddMessage('Srv Http terminado');
      try
        HttpSrv.Started:=bStarted; //isso pode gerar exception, se já existe servidor na porta
      except
        MonitorAddMessage('Já tem um servidor http na porta');
      end;
    end;
end;

// action '/'
procedure TFormAirportDisplayControl.HttpSrvActions0Action(Sender: TObject; ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var S:String; i:integer;
begin
   HttpSrv.SendString(ClientID,'<html><body>');
   HttpSrv.SendString(ClientID,sHtmlTitle); //'<h2>Airport Display</h2>
   HttpSrv.SendString(ClientID,VerStr+'<p>');
   HttpSrv.SendString(ClientID,'iniciado em '+LIniciadoEm.Caption+'<p>');

   HttpSrv.SendString(ClientID,'Num de downloads:'+IntToStr(fNumDownloads)+'<p>');
   HttpSrv.SendString(ClientID,'Num de erros de download:'+IntToStr(fNErrosDownload)+'<p>');
   HttpSrv.SendString(ClientID,'Num de atualizações:'+IntToStr(fNumAtualizacoes)+'<p>');

   HttpSrv.SendString(ClientID,'Monitor ------------------------ <p>');
   S:='';
   for i:=0 to Monitor.Lines.Count do
     S:=S+Monitor.Lines.Strings[i]+'<p>';
   HttpSrv.SendString(ClientID,S);
   HttpSrv.SendString(ClientID,'/Monitor ------------------------ <p>');
   HttpSrv.SendString(ClientID,'</body></html>');
   Handled:=TRUE;
end;

procedure TFormAirportDisplayControl.BSalvaConfiguracaoClick(Sender: TObject);
begin
  ConfigStateBox.WriteStateToIni;
  HttpServerStateBox.WriteStateToIni;  //salva cnf de http em separado, para nao entrar no sistema de configuracao remota
end;

procedure TFormAirportDisplayControl.BCarregaCnfClick(Sender: TObject);
begin
  fCarregandoSettings:=TRUE;
  try
    ConfigStateBox.ReadStateFromIni;
    HttpServerStateBox.ReadStateFromIni;
    fCarregandoSettings:=FALSE;
    CBServidorHttpAtivadoClick(nil); //após carregamento da porta, pode iniciar o http (se especificado)
    BSetPosicaoClick(nil);           //ajusta posicao do display.
    BSetNumLinhasClick(nil);         //ajusta num de linhas
    //Nota: A linha acima nao funciona no 2000. Por isso coloquei outro no FormShow do display
  finally
    fCarregandoSettings:=FALSE;
  end;
end;

procedure TFormAirportDisplayControl.CBComTituloClick(Sender: TObject);
var aForm:TForm;
begin
  aForm:=nil;
  Case RGTipoPagina.ItemIndex of
    0,1: aForm:=FormAirportDisplay;
    2:   aForm:=FormDisplayPortao;
    {$IFDEF PAINEL_3D}
    3:   aForm:=FormGLAirportDisplay;
    {$ENDIF PAINEL_3D}
  end;
  if Assigned(aForm) then
    if CBComTitulo.Checked then aForm.BorderStyle:=bsSizeable
      else aForm.BorderStyle:=bsNone;  //controla a borda do display
end;

// /loadmetabase - comando http para recarregar metabase
procedure TFormAirportDisplayControl.GetLoadMetabaseAction(Sender: TObject; ClientID:Integer; Context: THttpContext; var Handled: Boolean);
begin
  BCarregaCnfClick(nil); //isso carrega a conf

  HttpSrv.SendString(ClientID,'<html><body>');
  HttpSrv.SendString(ClientID,sHtmlTitle); // '<h2>Airport Display</h2>'
  HttpSrv.SendString(ClientID,VerStr+'<p>');
  HttpSrv.SendString(ClientID,'Configuração recarregada<p>');
  HttpSrv.SendString(ClientID,'</body></html>');
  Handled:=TRUE;
end;

procedure TFormAirportDisplayControl.BSetPosicaoClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      FormAirportDisplay.Left:=EdDisplayFormX.Value;
      FormAirportDisplay.Top:=EdDisplayFormY.Value;
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.ClearVoos;
var i:integer;
begin
  for i:=0 to MAXVOOS-1 do fVoos[i].ClearVoo;
end;

procedure TFormAirportDisplayControl.ForcaPagina(aPageNumber:string);  // '1' ou '2'
var aPag:integer; changed:boolean;
begin
  aPag:=StrToIntDef(aPageNumber,0);
  if (aPag=0) then exit;
  changed:=false;
  case aPag of
    1: begin
         changed:=(fIxTopFlight<>0);
         fIxTopFlight:=0;
       end;
    2: begin
         changed:=(fIxTopFlight<>EdNumLinhas.Value);
         fIxTopFlight:=EdNumLinhas.Value; //era 25; dava bug quando abria a pag 2 com menos de 25 linhas
       end;
  end;
  if changed then //só renderiza se mudou
    begin
     Case RGTipoPagina.ItemIndex of
       0,1:if Assigned(FormAirportDisplay) then
             begin
               FormAirportDisplay.LNUmPagina.Caption:='Página '+aPageNumber;
               FormAirportDisplay.StartPiscadaHoracertaPagina; //pisca parada
             end;
       2: ;
       {$IFDEF PAINEL_3D}
       3: if Assigned(FormGLAirportDisplay) then
             begin
               FormGLAirportDisplay.fPaginaFlap.Caption:='Página '+aPageNumber;
             end;
       {$ENDIF PAINEL_3D}
     end;
     RenderVoos; //renderiza flaps forçado
    end;
end;

procedure TFormAirportDisplayControl.TogglePagina;
begin
  if fIxTopFlight=0 then ForcaPagina('2')  //muda pagina exibida, para simular transição
    else ForcaPagina('1');
end;

function TFormAirportDisplayControl.GetActiveDisplayPage:TForm;
begin
  Result:=nil;
  case RGTipoPagina.ItemIndex of
    0,1: Result:=FormAirportDisplay;    //paginas com multiplos voos
    2:   Result:=FormDisplayPortao;
    {$IFDEF PAINEL_3D}
    3:   Result:=FormGLAirportDisplay;
    {$ENDIF PAINEL_3D}
  end;
end;

function  TFormAirportDisplayControl.EhPartidas:boolean;
begin
  Result:=(RGTipoPagina.ItemIndex in [1,2]);
end;

procedure TFormAirportDisplayControl.EdQualPaginaChange(Sender: TObject);
begin
  case EdQualPagina.Value of
    1: fIxTopFlight:=0;
    2: fIxTopFlight:=EdNumLinhas.Value; //era 25; dava bug quando abria a pag 2 com menos de 25 linhas
  end;

  if Assigned(FormAirportDisplay) then
    FormAirportDisplay.LNUmPagina.Caption:='Página '+IntToStr(EdQualPagina.Value);

  ClearVoos;
end;

procedure TFormAirportDisplayControl.EdNumLinhasChange(Sender: TObject);
begin
  EdQualPaginaChange(Sender); //isso atualiza fIxTopFlight, caso essa seja a pag 2 
end;

procedure TFormAirportDisplayControl.CBStopFlappingIfFallingBehindClick(Sender: TObject);
begin
  bStopFlappingIfFallingBehind:=CBStopFlappingIfFallingBehind.Checked;
  if bStopFlappingIfFallingBehind then bRenderizacaoCompleta:=TRUE;
end;

procedure TFormAirportDisplayControl.BForcaRenderizacaoClick(Sender: TObject);
begin
  ForcaRenderizacaoDosFlaps;
end;

procedure TFormAirportDisplayControl.CBMostraCabecalhoClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    FormAirportDisplay.MostraCabecalhos:=CBMostraCabecalho.Checked;
end;

procedure TFormAirportDisplayControl.BSetNumLinhasClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      FormAirportDisplay.SetNumLinhas(EdNumLinhas.Value);
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.CBStatusVisibleClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      FormAirportDisplay.SetStatusVisible(CBStatusVisible.Checked);
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.CBComSomClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    FormAirportDisplay.fSoundActivated:=CBComSom.Checked;

  {$IFDEF PAINEL_3D}
  if Assigned(FormGLAirportDisplay) then
    FormGLAirportDisplay.fSoundActivated:=CBComSom.Checked;
  {$ENDIF PAINEL_3D}
end;

procedure TFormAirportDisplayControl.GetFormUploadCNFAction(Sender: TObject;        // /formuplcnf
  ClientID: Integer; Context: THttpContext; var Handled: Boolean);
begin
  HttpSrv.SendString(ClientID,
    '<HTML><HEAD><TITLE>Upload de configuração AirportDisplay</TITLE></HEAD><BODY>'+CRLF+
    '<FORM ENCTYPE="multipart/form-data" METHOD=POST ACTION="/postuplcnf">'+CRLF+
    '<PRE>Arquivo de configuração: <INPUT TYPE=FILE NAME="upl-file" SIZE=40>'+CRLF+
    '<INPUT TYPE=SUBMIT VALUE="Upload Now">'+CRLF+
    '</PRE></FORM><HR>'+CRLF+
    '</BODY></HTML>');
  Handled:=TRUE;
end;

//o upload do arquivo a partir do explorer vem como:

Procedure TrocaFileNames(const aFile1,aFile2:String);
const sTempFilename='tmpfilename.ini';
begin
  if FileExists(aFile1) and FileExists(aFile2) then
    begin
      if FileExists(sTempFilename) then DeleteFile(sTempFilename);
      RenameFile(aFile1,sTempFilename);
      RenameFile(aFile2,aFile1);
      RenameFile(sTempFilename,aFile2);
    end;
end;

// O UPLOAD DE ARQUIVOS DE CONFIGURACAO é feito via http,
// em metodo compativel com o IE (isto é, a configuracao
// pode ser feita via IE). O ADControler faz os Uploads
// da mesma maneira, conforme exemplo abaixo:
(*
Context.ContentType='multipart/form-data; boundary=---------------------------7d33473a70354'

Context.EntityBody=
-----------------------------7d33473a70354
Content-Disposition: form-data; name="upl-file"; filename="D:\dpr32\flapflap\teste.ini"
Content-Type: application/octet-stream

[FormAirportDisplayControl_State]
EdHost=10.0.101.123
EdFileName=chegadas.htm
EdPath=/
EdQualPagina=1
RGTipoPagina=0
EdSegundos=10
CBAtualizacaoAutomatica=1
EdPortaHttp=8000
CBServidorHttpAtivado=1
CBBeepOnMonitorMessage=1
CBComTitulo=0
EdDisplayFormX=0
EdDisplayFormY=0
EdScreenSaverDas=23:00
EdScreenSaverAte=06:00
CBScreenSaverAtivado=0
EdDemagnetizadorSecs=3
EdDemagnetizadorMin=10
CBDemagnetizadorAtivado=1
CBStopFlappingIfFallingBehind=0
CBMostraCabecalho=1
CBRefresherAtivado=1
CBSomenteVoosDaSala=0
EdNumDaSala=1
CBSomenteAirline=0
EdAirline=TAM
EdNumLinhas=25
CBStatusVisible=1
EdMaxPaginasInfraero=3
CBComSom=0
EdPortaServidor=8080
RGQualBancoDeDados=1

-----------------------------7d33473a70354--
*)
procedure TFormAirportDisplayControl.PostFormUploadCNFAction(Sender: TObject; ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var S,sResultado:String; hm:TMultipartHttpContent; aPart:THttpPart; St:TFileStream; p:integer;
const cBound='boundary=';  sOldCnfFile='AirportDisplay.bak';
begin
  S:=Context.ContentType; //tipo: 'multipart/form-data; boundary=---------------------------7ce25884e0'
  p:=Pos(cBound,Lowercase(S));
  if (p>0) then
    begin
      hm:=TMultipartHttpContent.Create;
      hm.Boundary:=Copy(S,p+Length(cBound),Length(S));
      hm.EntityBody:=Context.EntityBody;
      hm.EntityBodySz:=Context.EntityBodySz;
      hm.ParseEntityBody;
      sResultado:='nada';
      if (hm.Parts.Count>=1) then //pega a 1a parte (é a do arquivo)
        begin
          aPart:=THttpPart(hm.Parts.Objects[0]);
          if (aPart.ContentSize>0) then
            begin
              St:=TFileStream.Create(sOldCnfFile,fmCreate);
              // TODO: sanity test no arquivo recebido
              St.Write(PChar(aPart.Content)^,aPart.ContentSize);
              St.Free;
              TrocaFileNames(sOldCnfFile,'AirportDisplay.ini');   //troca a CNF velha pela nova. A velha permanece como 'AirportDisplay.bak'
              BCarregaCnfClick(nil);                              //carrega configuração nova e poe pra rodar...
              sResultado:='Configuração atualizada';
            end;
        end;
      hm.Free;
    end;
  HttpSrv.SendString(ClientID,'<html>Upload: '+sResultado+'<br></html>');
  Handled:=TRUE;
end;

// /status
procedure TFormAirportDisplayControl.GetStatusAction(Sender: TObject; ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var Segs:integer;
begin
  Context.ContentType:='text/plain';
  HttpSrv.SendString(ClientID,'AirportDisplay'); //'<h2>Airport Display</h2>
  HttpSrv.SendString(ClientID,VerStr);
  HttpSrv.SendString(ClientID,'NumDown=' +IntToStr(fNumDownloads));
  HttpSrv.SendString(ClientID,'NumErros='+IntToStr(fNErrosDownload));
  HttpSrv.SendString(ClientID,'NumAtu='  +IntToStr(fNumAtualizacoes));
  if fHoraLastDownloadOk=0 then Segs:=-1  //=never
    else Segs:=Round((Now-fHoraLastDownloadOk)*3600*24); //segundos desde ultimo DL ok
  HttpSrv.SendString(ClientID,'LastDLOk='+IntToStr(Segs));
  Handled:=TRUE;
end;

function TFormAirportDisplayControl.Grab_AD_JPEG:TJPEGImage;
var hADForm: THandle; wDC: HDC; SrcRect: TRect; aBMP: TBitmap;
begin
  Result:=nil;
  aBMP:=TBitmap.Create;
  try
    with aBMP do
      begin
        hADForm:=FormAirportDisplay.Handle;
        SetForegroundWindow(hADForm);                                //make sure the thing is updated
        RedrawWindow(hADForm, nil, 0, RDW_INVALIDATE+RDW_UPDATENOW);
        GetWindowRect(hADForm, SrcRect);
        Width := SrcRect.Right-SrcRect.Left;
        Height := SrcRect.Bottom-SrcRect.Top;
        wDC := GetWindowDC(hADForm);
        try
          BitBlt(Canvas.Handle,0,0,Width,Height,wDC,0,0,SRCCOPY);
          Result:=TJPEGImage.Create;
          Result.CompressionQuality:=30;
          Result.Assign(aBMP);
        finally
          ReleaseDC(hADForm, wDC);
        end;
      end;
  finally
    aBMP.Free;
  end;
end;

procedure TFormAirportDisplayControl.GetImageAction(Sender: TObject;ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var aJPEG:TJPEGImage; st:TMemoryStream;
begin
  aJPEG:=Grab_AD_JPEG;
  if Assigned(aJPEG) then
    begin
      //aJPEG.Scale:=jsHalf;
      st:=TMemoryStream.Create;
      try
        aJPEG.SaveToStream(st);
        aJPEG.Free;
        st.Position:=0;
        HttpSrv.SendStream(ClientID,st,'image/jpeg');
      finally
        st.Free;
      end;
    end
    else HttpSrv.SendErrorMessage(ClientID,500,'<html><body>Erro interno<p></body></html>'); //server error
  handled:=TRUE;
end;

// /cnf  - retorna estado dos components do StateBox na forma de um INI
procedure TFormAirportDisplayControl.GetConfiguracaoAction(Sender: TObject;
  ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var S:String;
begin
  Context.ContentType:='text/plain';
  S:=ConfigStateBox.GetInifileText;
  HttpSrv.SendString(ClientID,S);
  handled:=TRUE;
end;

procedure TFormAirportDisplayControl.HttpSrvBeforeHttpRequest(Sender: TObject; ClientID: Integer;
  Context: THttpContext; var Handled: Boolean);
var aHttpUsername:String;
begin
  aHttpUsername:=Trim(EdHttpUserName.Text);
  if (aHttpUsername<>'') then                   // se authenticação requerida.... verifica
    begin
      if not ( (CompareText(Context.AuthUser,aHttpUsername)=0)     //verifica a autenticacao
        and (CompareText(Context.AuthPassword,EdHttpPW.Text)=0) ) then
          begin
            Context.ResponseHeader.Add('WWW-Authenticate: Basic real="AirportDisplay"');
            HttpSrv.SendErrorResponse(ClientID,401); {authorization required}
            Handled:=TRUE;
          end;
    end;
end;

procedure TFormAirportDisplayControl.GetIndexAction(Sender: TObject;
  ClientID: Integer; Context: THttpContext; var Handled: Boolean);
begin
  Context.ContentType:='text/html';
  HttpSrv.SendString(ClientID,'<html><body><b>AirportDisplay</b><br>');
  HttpSrv.SendString(ClientID,VerStr+'<br>');
  HttpSrv.SendString(ClientID,'<br>');
  HttpSrv.SendString(ClientID,'<a href="/image">mostra imagem</a><br>');
  HttpSrv.SendString(ClientID,'<a href="/cnf">mostra config</a><br>');
  HttpSrv.SendString(ClientID,'<a href="/formuplcnf">upload de config</a><br>');
  HttpSrv.SendString(ClientID,'<a href="/status">status do display</a><br>');
  HttpSrv.SendString(ClientID,'</body></html>');
  Handled:=TRUE;
end;

procedure TFormAirportDisplayControl.CBMostraReflexoClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      FormAirportDisplay.SetaReflexos(CBMostraReflexo.Checked);
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.CBCoresAlternadasClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      FormAirportDisplay.SetaCoresAlternadas(CBCoresAlternadas.Checked);
    end
    else MessageBeep(0);
end;

procedure TFormAirportDisplayControl.MostraFormDeDisplay;
begin
  RGTipoPaginaClick(nil);  //isso mostra o form de display em uso nesta configuracao
end;

procedure TFormAirportDisplayControl.FormClose(Sender: TObject; var Action:TCloseAction);
begin
  Action:= caHide;
end;

procedure TFormAirportDisplayControl.BRenderizaVoosClick(Sender: TObject);
begin
  RenderVoos;
end;

procedure TFormAirportDisplayControl.GetDisplayVirtual(Sender: TObject;
  ClientID: Integer; Context: THttpContext; var Handled: Boolean);
var S:String; N,ND,i:integer; aVoo: TInformacaoDeVoo;
begin
  HttpSrv.SendString(ClientID,'<html><body>display virtual<p><pre>');
  ReposicionaVoosNoDisplayVirtual;
  for i:=0 to MAXVOOS-1 do   //começa desde o inicio...
    begin
      aVoo:=fVoos[i];
      N:=aVoo.IxNoDisplayVirtual;                //reposiciona no virtual
      if aVoo.Visivel and (N>=0) then
        begin
          S:=Format('%2d',[N])+' '+aVoo.GetAsString;
          HttpSrv.SendString(ClientID,S);
        end;
    end;

  HttpSrv.SendString(ClientID,'</pre></body></html>');
  Handled:=TRUE;
end;

procedure TFormAirportDisplayControl.cbBaggageClaimClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      if cbBaggageClaim.Checked then FormAirportDisplay.EhBaggageClaim:=true
        else begin
          MessageBeep(0);  //ops, o layout bagage claim é irreversivel, reinicie
          MessageDlg('Salve a configuração e reinicie.',mtConfirmation, [mbOk], 0);
        end;
    end;
end;

procedure TFormAirportDisplayControl.cbEsteiraPatioClick(Sender: TObject);
begin
  if Assigned(FormAirportDisplay) then
    begin
      if cbEsteiraPatio.Checked then FormAirportDisplay.EhEsteiraPatio:=true
        else begin
          MessageBeep(0);
          MessageDlg('Salve a configuração e reinicie.',mtConfirmation, [mbOk], 0);
        end;
    end;
end;


procedure TFormAirportDisplayControl.Button1Click(Sender: TObject);
begin
  ForcaPagina('1');
end;

procedure TFormAirportDisplayControl.Button2Click(Sender: TObject);
begin
  ForcaPagina('2');
end;

procedure TFormAirportDisplayControl.cbAtualizacoesEmCascataClick(Sender: TObject);
begin
  TimerAtualizaEmCascata.Enabled := cbAtualizacoesEmCascata.Checked;
end;

initialization
  //
finalization
  //
end.


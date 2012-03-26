unit fAirportDisplay; // AirportDisplay - (c)copr. 02-12 Omar Reis
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/
//   - display de chegadas/partidas
//   - videowall version ( splitado do principal em 2006 na mudança de CGH para GRU )

interface

uses
  Windows, Messages, SysUtils, Classes,
  Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Menus, jpeg, ActnList,
  Debug,
  OmFlapLabel,
  uInformacaoDeVoo, {TInformacaoDeVoo}
  OmColorFader,
  AnimateBear,
  uThreadFlapSounder,
  AnimGlob;

{..$DEFINE SIMULACAO}

const
  MAXLINEMANAGERS=25;    // Max de 25 linhas no display real
  TOPLINETOP=48;         // Top default da 1a linha (com cabeçalho)
  //strings
  sDepartures='Partidas / Departures';
  sParaTo='para / to';
  sArrivals='Chegadas / Arrivals';
  sDeFrom='de / from';
  sSala='sala';
  sPortao='portão';
  sDesemb='desemb';
  sEsteira='esteira';
  // global settings  (bad practice)
  bSoh5Linhas: boolean=false;
  bLayout1360x768:boolean=false;  //i.e. video wall

type
  TFlightLineManager=class
  private
    fVisible: boolean;
    fEhBaggageClaim: boolean;
    fEhEsteiraPatio: boolean;
    procedure SetVisible(const Value: boolean);
    procedure SetEhBaggageClaim(const Value: boolean);
    procedure SetLayoutBaggageClaim;
    procedure ForceClear2;
    procedure SetEhEsteiraPatio(const Value: boolean);
  public
    fFlapAir:        TFlapLabel;
    //fFlapFlight:     TFlapLabel;

    fFlapFlight1:    TFlapLabel;
    fFlapFlight2:    TFlapLabel;
    fFlapFlight3:    TFlapLabel;
    fFlapFlight4:    TFlapLabel;
    fFlapFlight5:    TFlapLabel;

    fFlapCidadeFrom: TFlapLabel;
    fFlapDeHH:       TFlapLabel;
    fFlapDeH:        TFlapLabel;
    fFlapDeMM:       TFlapLabel;
    fFlapDeM:        TFlapLabel;
    fFlapEscala:     TFlapLabel;
    fFlapParaHH:     TFlapLabel;
    fFlapParaH:      TFlapLabel;
    fFlapParaMM:     TFlapLabel;
    fFlapParaM:      TFlapLabel;
    fFlapStatus:     TFlapLabel;
    fFlapGateC:      TFlapLabel;
    fFlapGateD:      TFlapLabel;
    fFlapGateU:      TFlapLabel;
    fLed:            TGTAnimated;
    fLed2:           TGTAnimated;

    fBevelVooParceria: TBevel;  //link de parceria é uma linha vertical q linka dois voos

    fLab1:TLabel;      //labels com ':'
    fLab2:TLabel;
    fVoo:TInformacaoDeVoo;

    Constructor Create;
    Destructor  Destroy; override;
    function    Clone:TFlightLineManager;
    Procedure   SetTops(aTop:integer);
    procedure   ForceClear;
    Procedure   SetFonts(aFont:TFont);
    Procedure   SetBackColors(aColor:TColor);

    Procedure   SetReflexos(value:boolean);
    Procedure   SetCoresAlternadas(value:boolean);
    Procedure   RenderCaptions;

    Property    Visible:boolean        read fVisible        write SetVisible;
    Property    EhBaggageClaim:boolean read fEhBaggageClaim write SetEhBaggageClaim;
    Property    EhEsteiraPatio:boolean read fEhEsteiraPatio write SetEhEsteiraPatio;
  end;

  TADLayoutManager=class
  private
  public
    fSizeDefault:boolean;
    Constructor Create;
    Procedure   AdjustLineLayout(aLine:TFlightLineManager; k:double);
  end;

  TADPlotGridMode=(gmNone,gmVideoWall1360x768,gm800x600);

  TFormAirportDisplay = class(TForm)
    FlapCidadeFrom: TFlapLabel;
    LOrigemDestino: TLabel;
    LHHora: TLabel;
    FlapDeHH: TFlapLabel;
    FlapDeH: TFlapLabel;
    FlapDeMM: TFlapLabel;
    FlapDeM: TFlapLabel;
    Lab1: TLabel;
    Timer1: TTimer;
    LHVoo: TLabel;
    FlapEscala: TFlapLabel;
    LHEscalas: TLabel;
    FlapParaHH: TFlapLabel;
    FlapParaH: TFlapLabel;
    FlapParaMM: TFlapLabel;
    FlapParaM: TFlapLabel;
    Lab2: TLabel;
    LabObservacao: TLabel;
    FlapStatus: TFlapLabel;
    LHAirline: TLabel;
    FlapAir: TFlapLabel;
    FlapFlight1: TFlapLabel;
    FlapFlight2: TFlapLabel;
    FlapFlight3: TFlapLabel;
    FlapFlight4: TFlapLabel;
    LDirecao: TLabel;
    Menu: TPopupMenu;
    Fonte1: TMenuItem;
    DisplayFontDlg: TFontDialog;
    N1: TMenuItem;
    Termina1: TMenuItem;
    LinhaCentral1: TMenuItem;
    LHSala: TLabel;
    FlapGateC: TFlapLabel;
    LHoraCerta: TLabel;
    OmColorFader1: TOmColorFader;
    LData: TLabel;
    ColorDlg: TColorDialog;
    Cordefundo1: TMenuItem;
    Cordoslabels1: TMenuItem;
    LHPrev: TLabel;
    LHConf: TLabel;
    Som1: TMenuItem;
    Slideshow1: TMenuItem;
    N2: TMenuItem;
    Configuracao1: TMenuItem;
    Sobre1: TMenuItem;
    LNumPagina: TLabel;
    Led1: TGTAnimated;
    Image1: TImage;
    PanelCabecalhos: TPanel;
    FlapGateD: TFlapLabel;
    FlapGateU: TFlapLabel;
    BevelVooParceria: TBevel;
    Image2: TImage;
    Led2: TGTAnimated;
    FlapFlight5: TFlapLabel;
    ABActionList: TActionList;
    ActToggleCursor: TAction;
    ActMudaPagina: TAction;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Fonte1Click(Sender: TObject);
    procedure LinhaCentral1Click(Sender: TObject);
    procedure OmColorFader1ColorChange(Sender: TObject; aColor: TColor);
    procedure Cordefundo1Click(Sender: TObject);
    procedure Cordoslabels1Click(Sender: TObject);
    procedure Som1Click(Sender: TObject);
    procedure Slideshow1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Termina1Click(Sender: TObject);
    procedure Configuracao1Click(Sender: TObject);
    procedure Sobre1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure ActToggleCursorExecute(Sender: TObject);
    procedure ActMudaPaginaExecute(Sender: TObject);
  private
    fLayoutManager:TADLayoutManager; //gerenciador de linhas

    fEhDepartures: boolean;
    fEhBaggageClaim: boolean;
    fSounderThread:TThreadFlapSounder;
    fADPlotGridMode:TADPlotGridMode;
    fEhEsteiraPatio: boolean;
    fCursorVisivel:boolean;  //controle da visib do cursor do mouse

    procedure RandomizeFlightLine(N: integer);
    procedure SetDisplayFonts(aFont: TFont);
    procedure NextSlide;
    procedure SetEhDepartures(const Value: boolean);
    function  GetMostraCabecalhos: boolean;
    procedure SetMostraCabecalhos(const Value: boolean);
    procedure AjustaTops;
    procedure AdjustHeaderControls(k: double);
    procedure SetEhBaggageClaim(const Value: boolean);
    procedure CorrectFlapPosParaVideoWall;
    procedure SetEhEsteiraPatio(const Value: boolean);
    procedure AjustaDimensoesDaJanela;
    procedure SetHeaderControlPositions;
  public
    fSoundActivated: boolean;
    //fFlapSoundStatus:integer; //0=none 1=tup 2=trup //obsoleto
    Lines: Array[0..MAXLINEMANAGERS-1] of TFlightLineManager;
    fNumLinhas:integer;

    Procedure SetSoundStatus(aStatus:integer); //obsoleta
    procedure SetInfoVoo(N:integer; aVoo:TInformacaoDeVoo); //evento de updates
    procedure SetNumLinhas(N: integer);
    procedure SetStatusVisible(bVisible: boolean);
    procedure FasterMessageLoop;
    procedure StartPiscadaHoracertaPagina;

    Procedure SetaReflexos(value:boolean);
    Procedure SetaCoresAlternadas(value:boolean);

    Property  EhDepartures:boolean   read fEhDepartures   write SetEhDepartures;
    property  EhBaggageClaim:boolean read fEhBaggageClaim write SetEhBaggageClaim;
    Property  EhEsteiraPatio:boolean read fEhEsteiraPatio write SetEhEsteiraPatio;

    Property  MostraCabecalhos:boolean read GetMostraCabecalhos write SetMostraCabecalhos;
  end;

var
  FormAirportDisplay: TFormAirportDisplay;

implementation //---------------------------// // // // // // / / / / / / / / / /// /// /// ///

uses
  fDownloadInformacaoDeVoo,   {FormAirportDisplayControl}
  fADSplash,
  
  MMSystem; {PlaySound()}

{$R *.DFM}

{$IFDEF SIMULACAO}
const
  MAXCIDADES=30;
  Cidades: Array[0..MAXCIDADES-1] of String =(
    'SÃO PAULO',
    'RIO DE JANEIRO',
    'TOKIO',
    'NEW YORK',
    'BELO HORIZONTE',
    'VARGINHA',
    'PIRACICABA',
    'SALVADOR',
    'FLORIANOPOLIS',
    'LONDRES',
    'GENEBRA',
    'RECIFE',
    'PORTO ALEGRE',
    'FORTALEZA',
    'BRASÍLIA',
    'RIBERÂO PRETO',
    'NOVA DELHI',
    'BUENOS AIRES',
    'MIAMI',
    'ORLANDO',
    'LOS ANGELES',
    'LAS VEGAS',
    'CHICAGO',
    'SANTIAGO',
    'CAIRO',
    'MOSCOU',
    'PARIS',
    'TEGUCIGALPA',
    'I COMANDATUBA',
    'VITÓRIA');

  MAXSTATUS=4;
  Statuses: Array[0..MAXSTATUS-1] of String =(
    'atrasado',
    'aterrisou',
    'embarque imediato',
    'última chamada');
{$ENDIF SIMULACAO}

// set07:Om: hack obtido em http://tecnobyte.com.br/dica2.html#dica49
//           TODO: isso tem repetido em fAutoBrowser.pas
function My_MouseShowCursor(const Show: boolean): boolean;
var
  I: integer;
begin
  I := ShowCursor(LongBool(true));
  if Show then begin
    Result := I >= 0;
    while I < 0 do begin
      Result := ShowCursor(LongBool(true)) >= 0;
      Inc(I);
    end;
  end else begin
    Result := I < 0;
    while I >= 0 do begin
      Result := ShowCursor(LongBool(false)) < 0;
      Dec(I);
    end;
  end;
end;


function TemParametro(const aParm:String):boolean;
var i:integer;
begin
  Result:=FALSE;
  for i:=1 to ParamCount do if CompareText(ParamStr(i),aParm)=0 then
    begin Result:=TRUE; exit; end;
end;

Procedure LoadAirlineLogos(aFlapLabel:TFlapLabel);
var i:integer; aAirline:String;
begin
  try
    for i:=0 to Airlines.Count-1 do
      begin
        aAirline:=Airlines.Strings[i];
        if bLayout1360x768 then
          begin
            LoadFlapBitmapFile('AIRLINE',aAirline,aAirline+'_VW.BMP',aFlapLabel); //carrega bmp da cia na lista global do  flapflap
          end
          else begin
            LoadFlapBitmapFile('AIRLINE',aAirline,aAirline+'.BMP'   ,aFlapLabel); 
          end;
      end;
  except
    MessageDlg('Erro no carregamento de '+aAirline+'.bmp', mtInformation,[mbOk], 0);
  end;
end;

procedure ChangeControlPositionAndWidth(aControl:TControl; k:double);
var aFL:TFlapLabel;
begin
  aControl.Left:=Trunc(aControl.Left*k);
  aControl.Width:=Trunc(aControl.Width*k);
  if (aControl is TFlapLabel) then
    begin
      aFL:=TFlapLabel(aControl);
      if k<1 then
        begin
          aFL.Height:=20;
          aFL.FontTop:=-1;
        end
        else begin
          aFL.Height:=24;
          aFL.FontTop:=-3;
        end;
    end;
end;

{ TFlightLineManager }

constructor TFlightLineManager.Create;
begin
  inherited;
  fVisible:=TRUE;
  fEhBaggageClaim:=false;
end;

destructor TFlightLineManager.Destroy;
begin
  //nao destroi componentes pois eles pertencem ao Form
  inherited;
end;

function TFlightLineManager.Clone: TFlightLineManager;
begin
  //Profiler_Profile(0);
  Result:=TFlightLineManager.Create;

  //Profiler_Profile(1);
  Result.fFlapAir:=          fFlapAir.Clone;
  //Profiler_Profile(2);
  Result.fFlapFlight1:=      fFlapFlight1.Clone;
  //Profiler_Profile(3);
  Result.fFlapFlight2:=      fFlapFlight2.Clone;
  //Profiler_Profile(4);
  Result.fFlapFlight3:=      fFlapFlight3.Clone;
  //Profiler_Profile(5);
  Result.fFlapFlight4:=      fFlapFlight4.Clone;
  //Profiler_Profile(6);
  Result.fFlapFlight5:=      fFlapFlight5.Clone;

  Result.fFlapCidadeFrom:=   fFlapCidadeFrom.Clone;
  //Profiler_Profile(7);
  Result.fFlapDeHH:=         fFlapDeHH.Clone;
  //Profiler_Profile(8);
  Result.fFlapDeH:=          fFlapDeH.Clone;
  //Profiler_Profile(9);
  Result.fFlapDeMM:=         fFlapDeMM.Clone;
  //Profiler_Profile(10);
  Result.fFlapDeM:=          fFlapDeM.Clone;
  //Profiler_Profile(11);
  Result.fFlapEscala:=       fFlapEscala.Clone;
  //Profiler_Profile(12);
  Result.fFlapParaHH:=       fFlapParaHH.Clone;
  //Profiler_Profile(13);
  Result.fFlapParaH:=        fFlapParaH.Clone;
  //Profiler_Profile(14);
  Result.fFlapParaMM:=       fFlapParaMM.Clone;
  //Profiler_Profile(15);
  Result.fFlapParaM:=        fFlapParaM.Clone;
  //Profiler_Profile(16);
  Result.fFlapStatus:=       fFlapStatus.Clone;
  //Profiler_Profile(17);
  Result.fFlapGateC:=        fFlapGateC.Clone;
  Result.fFlapGateD:=        fFlapGateD.Clone;
  Result.fFlapGateU:=        fFlapGateU.Clone;

  //Profiler_Profile(18);
  Result.fLed:=              fLed.Clone;
  Result.fLed2:=             fLed2.Clone;

  Result.fVoo:=nil;

  //Profiler_Profile(19);
  //Clona o Bevel de parcerias
  Result.fBevelVooParceria       := TBevel.Create(fBevelVooParceria.Parent);
  Result.fBevelVooParceria.Parent:=fBevelVooParceria.Parent;
  Result.fBevelVooParceria.Left  :=fBevelVooParceria.Left;
  //Top = 54
  Result.fBevelVooParceria.Width :=fBevelVooParceria.Width;
  Result.fBevelVooParceria.Height:=fBevelVooParceria.Height;
  Result.fBevelVooParceria.Shape := bsLeftLine;
  Result.fBevelVooParceria.Style := bsRaised;

  Result.fLab1:=TLabel.Create(fLab1.Owner);      //labels com ':'
  //Profiler_Profile(20);
  Result.fLab1.Parent     := fLab1.Parent;
  //Profiler_Profile(21);
  Result.fLab1.Width      := fLab1.Width;
  //Profiler_Profile(22);
  Result.fLab1.Height     := fLab1.Height;
  //Profiler_Profile(23);
  Result.fLab1.Top        := fLab1.Top;
  //Profiler_Profile(24);
  Result.fLab1.Left       := fLab1.Left;
  //Profiler_Profile(25);
  Result.fLab1.Font.Assign(fLab1.Font);
  //Profiler_Profile(26);
  Result.fLab1.Caption    := fLab1.Caption;
  //Profiler_Profile(27);

  Result.fLab2:=TLabel.Create(fLab2.Owner);      //labels com ':'
  //Profiler_Profile(28);
  Result.fLab2.Parent     := fLab2.Parent;
  //Profiler_Profile(29);
  Result.fLab2.Width      := fLab2.Width;
  //Profiler_Profile(30);
  Result.fLab2.Height     := fLab2.Height;
  //Profiler_Profile(31);
  Result.fLab2.Top        := fLab2.Top;
  //Profiler_Profile(32);
  Result.fLab2.Left       := fLab2.Left;
  //Profiler_Profile(33);
  Result.fLab2.Font.Assign(fLab2.Font);
  //Profiler_Profile(34);
  Result.fLab2.Caption    := fLab2.Caption;
  //Profiler_Profile(35);
  Result.fLab1.SendToBack;
  Result.fLab2.SendToBack;
end;

procedure TFormAirportDisplay.SetDisplayFonts(aFont:TFont);
var i:integer;
begin
  for i:=0 to MAXLINEMANAGERS-1 do //cria os outros line managers
    Lines[i].SetFonts(aFont);
end;

procedure TFormAirportDisplay.Fonte1Click(Sender: TObject);
var i:integer;
begin
  DisplayFontDlg.Font.Assign(Lines[0].fFlapCidadeFrom.Font); //pega fonte default
  if DisplayFontDlg.Execute then
    begin
      SetDisplayFonts(DisplayFontDlg.Font);
      FlapLabels_RebuildTextBMPs;
      for i:=0 to MAXLINEMANAGERS-1 do       //inicializa as linhas
        Lines[i].RenderCaptions;
    end;
end;

procedure TFlightLineManager.SetTops(aTop: integer);
begin
  if fEhBaggageClaim then
    begin
      if bLayout1360x768 then fFlapAir.Top:=aTop
        else fFlapAir.Top:=aTop+7;   //o logo da airline, como é mais baixinho, fica p/ bx
    end
    else begin
      if bSoh5Linhas then fFlapAir.Top:=aTop+5 //só 5 linhas (para atingir o tam de letra especificado pelos caras do aeroporto
        else fFlapAir.Top:=aTop;
    end;

  fFlapFlight1.Top:=aTop;
  fFlapFlight2.Top:=aTop;
  fFlapFlight3.Top:=aTop;
  fFlapFlight4.Top:=aTop;
  fFlapFlight5.Top:=aTop;

  fFlapCidadeFrom.Top:=aTop;
  fFlapDeHH.Top:=aTop;
  fFlapDeH.Top:=aTop;
  fFlapDeMM.Top:=aTop;
  fFlapDeM.Top:=aTop;
  fFlapEscala.Top:=aTop;
  fFlapParaHH.Top:=aTop;
  fFlapParaH.Top:=aTop;
  fFlapParaMM.Top:=aTop;
  fFlapParaM.Top:=aTop;
  fFlapStatus.Top:=aTop;
  fFlapGateC.Top:=aTop;
  fFlapGateD.Top:=aTop;
  fFlapGateU.Top:=aTop;

  fLed.Top :=aTop+8;    //era fLed.Top:=aTop+12;
  fLed2.Top:=aTop+8;   //    fLed2.Top:=aTop+12;

  fBevelVooParceria.Top:=fFlapFlight1.Top+fFlapFlight1.Height div 2;
  fBevelVooParceria.Height:=fFlapFlight1.Height;

  if fEhBaggageClaim then
    begin
      fLab1.Top:=aTop;
      fLab2.Top:=aTop;
    end
    else begin
      fLab1.Top:=aTop+12;
      fLab2.Top:=aTop+12;
    end;
end;

procedure TFlightLineManager.ForceClear;
begin
  fFlapAir.Caption:=' ';
  fFlapFlight1.Caption:=' ';
  fFlapFlight2.Caption:=' ';
  fFlapFlight3.Caption:=' ';
  fFlapFlight4.Caption:=' ';
  fFlapFlight5.Caption:=' ';

  fFlapCidadeFrom.Caption:=' ';
  fFlapDeHH.Caption:=' ';
  fFlapDeH.Caption:=' ';
  fFlapDeMM.Caption:=' ';
  fFlapDeM.Caption:=' ';
  fFlapEscala.Caption:=' ';
  fFlapEscala.Subtexts.Clear;
  fFlapParaHH.Caption:=' ';
  fFlapParaH.Caption:=' ';
  fFlapParaMM.Caption:=' ';
  fFlapParaM.Caption:=' ';
  fFlapStatus.Caption:=' ';
  fFlapStatus.Subtexts.Clear;

  fFlapGateC.Caption:=' ';
  fFlapGateD.Caption:=' ';
  fFlapGateU.Caption:=' ';

  fLed.Play:=FALSE;
  fLed2.Play:=FALSE;

  fLed.Frame:=0;
  fLed2.Frame:=0;

  fVoo:=nil;
  fBevelVooParceria.Visible:=FALSE; //default é link de parceria invisivel
end;

procedure TFlightLineManager.ForceClear2; //clear com dois espacos, para forçar mudanca mesmo nos cvazios
begin
  fFlapAir.Caption:='  ';
  fFlapFlight1.Caption:='  ';
  fFlapFlight2.Caption:='  ';
  fFlapFlight3.Caption:='  ';
  fFlapFlight4.Caption:='  ';
  fFlapFlight5.Caption:='  ';

  fFlapCidadeFrom.Caption:='  ';
  fFlapDeHH.Caption:='  ';
  fFlapDeH.Caption:='  ';
  fFlapDeMM.Caption:='  ';
  fFlapDeM.Caption:='  ';
  fFlapEscala.Caption:='  ';
  fFlapEscala.Subtexts.Clear;
  fFlapParaHH.Caption:='  ';
  fFlapParaH.Caption:='  ';
  fFlapParaMM.Caption:='  ';
  fFlapParaM.Caption:='  ';
  fFlapStatus.Caption:='  ';

  fFlapGateC.Caption:='  ';
  fFlapGateD.Caption:='  ';
  fFlapGateU.Caption:='  ';

  fLed.Play:=FALSE;
  fLed.Frame:=0;
  fLed2.Play:=FALSE;
  fLed2.Frame:=0;

  fVoo:=nil;
  fBevelVooParceria.Visible:=FALSE; //default é link de parceria invisivel
end;


procedure TFlightLineManager.SetFonts(aFont: TFont);
begin
  fFlapAir.Font.Assign(aFont);
  fFlapFlight1.Font.Assign(aFont);
  fFlapFlight2.Font.Assign(aFont);
  fFlapFlight3.Font.Assign(aFont);
  fFlapFlight4.Font.Assign(aFont);
  fFlapFlight5.Font.Assign(aFont);

  fFlapCidadeFrom.Font.Assign(aFont);
  fFlapDeHH.Font.Assign(aFont);
  fFlapDeH.Font.Assign(aFont);
  fFlapDeMM.Font.Assign(aFont);
  fFlapDeM.Font.Assign(aFont);
  fFlapEscala.Font.Assign(aFont);
  fFlapParaHH.Font.Assign(aFont);
  fFlapParaH.Font.Assign(aFont);
  fFlapParaMM.Font.Assign(aFont);
  fFlapParaM.Font.Assign(aFont);
  fFlapStatus.Font.Assign(aFont);
  fFlapGateC.Font.Assign(aFont);
  fFlapGateD.Font.Assign(aFont);
  fFlapGateU.Font.Assign(aFont);
end;

procedure TFlightLineManager.SetBackColors(aColor: TColor);
begin
  fFlapAir.Backcolor:=aColor;
  fFlapFlight1.Backcolor:=aColor;
  fFlapFlight2.Backcolor:=aColor;
  fFlapFlight3.Backcolor:=aColor;
  fFlapFlight4.Backcolor:=aColor;
  fFlapFlight5.Backcolor:=aColor;

  fFlapCidadeFrom.Backcolor:=aColor;
  fFlapDeHH.Backcolor:=aColor;
  fFlapDeH.Backcolor:=aColor;
  fFlapDeMM.Backcolor:=aColor;
  fFlapDeM.Backcolor:=aColor;
  fFlapEscala.Backcolor:=aColor;
  fFlapParaHH.Backcolor:=aColor;
  fFlapParaH.Backcolor:=aColor;
  fFlapParaMM.Backcolor:=aColor;
  fFlapParaM.Backcolor:=aColor;
  fFlapStatus.Backcolor:=aColor;
  fFlapGateC.Backcolor:=aColor;
  fFlapGateD.Backcolor:=aColor;
  fFlapGateU.Backcolor:=aColor;
end;

procedure TFlightLineManager.RenderCaptions;
begin
  fFlapAir.RenderCaption;
  fFlapFlight1.RenderCaption;
  fFlapFlight2.RenderCaption;
  fFlapFlight3.RenderCaption;
  fFlapFlight4.RenderCaption;
  fFlapFlight5.RenderCaption;

  fFlapCidadeFrom.RenderCaption;
  fFlapDeHH.RenderCaption;
  fFlapDeH.RenderCaption;
  fFlapDeMM.RenderCaption;
  fFlapDeM.RenderCaption;
  fFlapEscala.RenderCaption;
  fFlapParaHH.RenderCaption;
  fFlapParaH.RenderCaption;
  fFlapParaMM.RenderCaption;
  fFlapParaM.RenderCaption;
  fFlapStatus.RenderCaption;
  fFlapGateC.RenderCaption;
  fFlapGateD.RenderCaption;
  fFlapGateU.RenderCaption;
end;

procedure TFlightLineManager.SetVisible(const Value: boolean);
begin
  if (fVisible<>Value) then
    begin
      fVisible := Value;
      fFlapAir.Visible:=fVisible;
      fFlapFlight1.Visible:=fVisible;
      fFlapFlight2.Visible:=fVisible;
      fFlapFlight3.Visible:=fVisible;
      fFlapFlight4.Visible:=fVisible;
      fFlapFlight5.Visible:=fVisible;

      fFlapCidadeFrom.Visible:=fVisible;
      fFlapDeHH.Visible:=fVisible;
      fFlapDeH.Visible:=fVisible;
      fFlapDeMM.Visible:=fVisible;
      fFlapDeM.Visible:=fVisible;
      fFlapEscala.Visible:=fVisible;
      fFlapParaHH.Visible:=fVisible;
      fFlapParaH.Visible:=fVisible;
      fFlapParaMM.Visible:=fVisible;
      fFlapParaM.Visible:=fVisible;
      fFlapStatus.Visible:=fVisible;

      fFlapGateC.Visible:=fVisible;
      fFlapGateD.Visible:=fVisible;
      fFlapGateU.Visible:=fVisible;

      fLed.Visible:=fVisible;
      fLed2.Visible:=fVisible;
      //fBevelVooParceria.Visible:=false;
      fLab1.Visible:=fVisible;
      fLab2.Visible:=fVisible;
    end;
end;

procedure TFlightLineManager.SetCoresAlternadas(value: boolean);
const aBackColor2=$00404040; //cor alternativa
//era const aBackColor2=$001e0000;       //cor alternativa
begin
  if value then
    begin
      fFlapFlight1.     BackColor2:=aBackColor2; //teste
      fFlapFlight2.     BackColor2:=aBackColor2;
      fFlapFlight3.     BackColor2:=aBackColor2;
      fFlapFlight4.     BackColor2:=aBackColor2;
      fFlapFlight5.     BackColor2:=aBackColor2;

      fFlapCidadeFrom.  BackColor2:=aBackColor2;
      fFlapDeHH.        BackColor2:=aBackColor2;
      fFlapDeH.         BackColor2:=aBackColor2;
      fFlapDeMM.        BackColor2:=aBackColor2;
      fFlapDeM.         BackColor2:=aBackColor2;
      fFlapEscala.      BackColor2:=aBackColor2;
      fFlapParaHH.      BackColor2:=aBackColor2;
      fFlapParaH.       BackColor2:=aBackColor2;
      fFlapParaMM.      BackColor2:=aBackColor2;
      fFlapParaM.       BackColor2:=aBackColor2;
      fFlapStatus.      BackColor2:=aBackColor2;
      fFlapGateC.       BackColor2:=aBackColor2;
      fFlapGateD.       BackColor2:=aBackColor2;
      fFlapGateU.       BackColor2:=aBackColor2;
    end;

  fFlapFlight1.     UseBackColor2:=value;
  fFlapFlight2.     UseBackColor2:=value;
  fFlapFlight3.     UseBackColor2:=value;
  fFlapFlight4.     UseBackColor2:=value;
  fFlapFlight5.     UseBackColor2:=value;

  fFlapCidadeFrom.  UseBackColor2:=value;
  fFlapDeHH.        UseBackColor2:=value;
  fFlapDeH.         UseBackColor2:=value;
  fFlapDeMM.        UseBackColor2:=value;
  fFlapDeM.         UseBackColor2:=value;
  fFlapEscala.      UseBackColor2:=value;
  fFlapParaHH.      UseBackColor2:=value;
  fFlapParaH.       UseBackColor2:=value;
  fFlapParaMM.      UseBackColor2:=value;
  fFlapParaM.       UseBackColor2:=value;
  fFlapStatus.      UseBackColor2:=value;
  fFlapGateC.       UseBackColor2:=value;
  fFlapGateD.       UseBackColor2:=value;
  fFlapGateU.       UseBackColor2:=value;
end;

procedure TFlightLineManager.SetReflexos(value: boolean);
begin
  fFlapAir.         ComReflexo:=value;
  fFlapFlight1.     ComReflexo:=value;
  fFlapFlight2.     ComReflexo:=value;
  fFlapFlight3.     ComReflexo:=value;
  fFlapFlight4.     ComReflexo:=value;
  fFlapFlight5.     ComReflexo:=value;

  fFlapCidadeFrom.  ComReflexo:=value;
  fFlapDeHH.        ComReflexo:=value;
  fFlapDeH.         ComReflexo:=value;
  fFlapDeMM.        ComReflexo:=value;
  fFlapDeM.         ComReflexo:=value;
  fFlapEscala.      ComReflexo:=value;
  fFlapParaHH.      ComReflexo:=value;
  fFlapParaH.       ComReflexo:=value;
  fFlapParaMM.      ComReflexo:=value;
  fFlapParaM.       ComReflexo:=value;
  fFlapStatus.      ComReflexo:=value;
  fFlapGateC.       ComReflexo:=value;
  fFlapGateD.       ComReflexo:=value;
  fFlapGateU.       ComReflexo:=value;
end;

procedure TFlightLineManager.SetLayoutBaggageClaim; //..de uma linha (irreversivel)
var aFont:TFont; x:integer; cd1,cd2:TColor;
const
  hBaggageClaimFlaps=38;
  wDigitoBC=20;
begin
  //cria fonte especial para o bagage claim
  aFont:=TFont.Create;
  aFont.Color:= $00D0D0D0; //clSilver;
  aFont.Size:=24;          //no outro é 13
  aFont.Name := 'Arial Narrow';
  aFont.Style := [fsBold];

  with fFlapAir do begin
    Left := 3;
    if bLayout1360x768 then Top := 45
      else Top := 45+5;
    FontTop := 0;
    bLinhaCentral:=true;
  end;

  //cd1:=$88411F; //azul marinho escuro
  //cd2:=$7B1603; //azul marinho escuro mais claro
  cd2:=$683635;
  cd1:=$78402F;

  if bLayout1360x768 then x:=110
    else x:=70;
  with fFlapFlight1 do begin
    Left := x;
    Top := 45;
    BackColor:=cd1; BackColor2:=cd2;
    Width := wDigitoBC;
    x:=Left+Width+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapFlight2 do begin
    Left := x;
    Top := 45;
    BackColor:=cd1; BackColor2:=cd2;
    Width := wDigitoBC;
    x:=Left+Width+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapFlight3 do begin
    Left := x;
    Top := 45;
    BackColor:=cd1; BackColor2:=cd2;
    Width := wDigitoBC;
    x:=Left+Width+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapFlight4 do begin
    Left := x;
    Top := 45;
    BackColor:=cd1; BackColor2:=cd2;
    Width := wDigitoBC;
    x:=Left+Width+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapFlight5 do begin
    Left := x;
    Top := 45;
    BackColor:=cd1; BackColor2:=cd2;
    Width := wDigitoBC;
    x:=Left+Width+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;

  // escala acumula função de escalas e cidade from (economiza espaço)
  with fFlapEscala do begin
    if bLayout1360x768 then
      begin
        Left := 224;
        Width:= 280;
      end
      else begin
        Left := 165;
        Width := 300;
      end;
    Top := 45;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  // hora 1
  if bLayout1360x768 then x:=518 //??
    else x:=508;
  with fFlapDeHH do begin
    Left := x;
    Top := 45   ;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapDeH do begin;
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fLab1 do begin
    Left := x;
    Top := 44;
    Width := 6;
    x:=Left+6+2;
    Height := 19;
    Font.Assign(aFont);
  end;
  with fFlapDeMM do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapDeM do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  //----
  if bLayout1360x768 then x:=630 //??
    else x:=650;
  with fFlapParaHH do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapParaH do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fLab2 do begin
    Left := x;
    Top := 44;
    Width := 6;
    x:=Left+6+2;
    Height := 19;
    Font.Assign(aFont);
  end;
  with fFlapParaMM do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  with fFlapParaM do begin
    Left := x;
    Top := 45;
    Width := wDigitoBC;
    x:=Left+wDigitoBC+2;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;
  //  no baggage claim apenas um dos campos do gate é visivel (o fFlapGateD)
  //  esse cara é usado pra mostrar a letra da esteira...
  with fFlapGateD do begin //a letra da esteira vai aqui
    Left := x+15;
    Top := 45;
    Width := 40;
    Height := hBaggageClaimFlaps;
    FontTop := 1;
    bLinhaCentral:=true;
    Font.Assign(aFont);
  end;

  aFont.Free;
end;

procedure TFlightLineManager.SetEhBaggageClaim(const Value: boolean);
begin
  if (fEhBaggageClaim<>value) then
    begin
      fEhBaggageClaim := Value;
      if fEhBaggageClaim then //seta layout de bc
        begin
          fFlapGateC.Visible:=false;        // nota: no bagage claim são visiveis:
          fFlapGateU.Visible:=false;        //  - Airline, num voo, escalas, Gate(só o digito D)
          fFlapGateD.Visible:=fVisible;     //    e Status (sem led)
          fFlapGateD.GroupName:='LETRAS';
          fFlapStatus.Visible:=false;
          fFlapCidadeFrom.Visible:=false;   //fica só o de escalas, que acumula funcoes de cidadefrom e escalas
          fLed.Visible:=false;
          fLed2.Visible:=false;
          SetLayoutBaggageClaim;            //isso reposiciona as paradas
        end
        else begin //a volta para EhBaggageClaim=false não funciona. tem q reiniciar...
          fFlapGateC.Visible      :=fVisible;
          fFlapGateU.Visible      :=fVisible;
          fFlapCidadeFrom.Visible :=fVisible;
          fFlapGateD.GroupName:='DIGITOS';
          fFlapStatus.Visible:=fVisible;
          fLed.Visible:=fVisible;
          fLed2.Visible:=fVisible;
          //TODO: Voltar p/ LO original
        end;
    end;
end;

procedure TFlightLineManager.SetEhEsteiraPatio(const Value: boolean);
begin
  if (fEhEsteiraPatio<>Value) then
    begin
      fEhEsteiraPatio := Value;
      //TODO: não implementado nesta versao de video wall
    end;
end;

{ TADLayoutManager }

constructor TADLayoutManager.Create;
begin
  inherited Create;
  fSizeDefault:=TRUE;
end;

//aumenta posicao e largura dos controles em K%
Procedure TADLayoutManager.AdjustLineLayout(aLine:TFlightLineManager; k:double);
begin
  //ChangeControlPositionAndWidth(aLine.fFlapAir,k); //nao altera tamanho do BMP da companhia
  ChangeControlPositionAndWidth(aLine.fFlapFlight1,k);
  ChangeControlPositionAndWidth(aLine.fFlapFlight2,k);
  ChangeControlPositionAndWidth(aLine.fFlapFlight3,k);
  ChangeControlPositionAndWidth(aLine.fFlapFlight4,k);
  ChangeControlPositionAndWidth(aLine.fFlapFlight5,k);

  ChangeControlPositionAndWidth(aLine.fFlapCidadeFrom,k);
  ChangeControlPositionAndWidth(aLine.fFlapDeHH,k);
  ChangeControlPositionAndWidth(aLine.fFlapDeH,k);
  ChangeControlPositionAndWidth(aLine.fFlapDeMM,k);
  ChangeControlPositionAndWidth(aLine.fFlapDeM,k);
  ChangeControlPositionAndWidth(aLine.fFlapEscala,k);
  ChangeControlPositionAndWidth(aLine.fFlapParaHH,k);
  ChangeControlPositionAndWidth(aLine.fFlapParaH,k);
  ChangeControlPositionAndWidth(aLine.fFlapParaMM,k);
  ChangeControlPositionAndWidth(aLine.fFlapParaM,k);
  ChangeControlPositionAndWidth(aLine.fFlapStatus,k);
  ChangeControlPositionAndWidth(aLine.fFlapGateC,k);
  ChangeControlPositionAndWidth(aLine.fFlapGateD,k);
  ChangeControlPositionAndWidth(aLine.fFlapGateU,k);

  ChangeControlPositionAndWidth(aLine.fLed,k);
  ChangeControlPositionAndWidth(aLine.fLed2,k);

  //fBevelVooParceria ??
  ChangeControlPositionAndWidth(aLine.fLab1,k);
  ChangeControlPositionAndWidth(aLine.fLab2,k);
end;

{ TFormAirportDisplay }

procedure TFormAirportDisplay.FormCreate(Sender: TObject);
var i,aTop,incr:integer; aLM:TFlightLineManager;
begin
  bSoh5Linhas:=TemParametro('5L'); //parm global

  fEhDepartures := TRUE;    //default é departures
  fEhBaggageClaim:=false;   //default é não ser BC
  fEhEsteiraPatio:=false;
  fADPlotGridMode:=gmNone;  //default = no grid
  //fFlapSoundStatus:=0;      //none
  LData.Caption:=FormatDateTime('dd/mmm/yy',Date);
  //TODO
  Randomize;

  bLayout1360x768:=true;             //default é formato videowall (1360x768)
  CorrectFlapPosParaVideoWall;       //converte de 800x600 para 1360x768

  LoadAirlineLogos(FlapAir);

  fLayoutManager:=TADLayoutManager.Create;

  aLM:=TFlightLineManager.Create;
  aLM.fFlapAir:=        FlapAir;
  aLM.fFlapFlight1:=    FlapFlight1;
  aLM.fFlapFlight2:=    FlapFlight2;
  aLM.fFlapFlight3:=    FlapFlight3;
  aLM.fFlapFlight4:=    FlapFlight4;
  aLM.fFlapFlight5:=    FlapFlight5;

  aLM.fFlapCidadeFrom:= FlapCidadeFrom;
  aLM.fFlapDeHH:=       FlapDeHH;
  aLM.fFlapDeH:=        FlapDeH;
  aLM.fFlapDeMM:=       FlapDeMM;
  aLM.fFlapDeM:=        FlapDeM;
  aLM.fFlapEscala:=     FlapEscala;
  aLM.fFlapParaHH:=     FlapParaHH;
  aLM.fFlapParaH:=      FlapParaH;
  aLM.fFlapParaMM:=     FlapParaMM;
  aLM.fFlapParaM:=      FlapParaM;
  aLM.fFlapStatus:=     FlapStatus;

  aLM.fFlapGateC:=      FlapGateC;
  aLM.fFlapGateD:=      FlapGateD;
  aLM.fFlapGateU:=      FlapGateU;

  aLM.fLed:=            Led1;
  aLM.fLed2:=           Led2;

  aLM.fBevelVooParceria:=BevelVooParceria;
  aLM.fVoo:=nil;
  aLM.fLab1:=           Lab1;
  aLM.fLab2:=           Lab2;

  Lines[0]:=aLM;

  aTop:=FlapCidadeFrom.Top;
  incr:=FlapCidadeFrom.Height+2; //espaço entre as linhas
  inc(aTop,incr);

  {$IFNDEF SIMULACAO}
  aLM.ForceClear;       //limpa flaps da linha com ''
  {$ENDIF SIMULACAO}

  //Profiler_Start;
  //TheProfiler.fProfilerAtivo:=FALSE;

  fNumLinhas:=MAXLINEMANAGERS;

  for i:=1 to MAXLINEMANAGERS-1 do //cria os outros line managers
    begin
      //if i=24 then TheProfiler.fProfilerAtivo:=TRUE;
      Lines[i]:=aLM.Clone;       //com base no designed...
      Lines[i].SetTops(aTop);    //ajusta a pos da linha na vertical
     {$IFNDEF SIMULACAO}
      Lines[i].ForceClear; //limpa flaps da linha com ''
     {$ENDIF SIMULACAO}
      inc(aTop,incr);
    end;
  //Profiler_End;

  for i:=0 to MAXLINEMANAGERS-1 do                //inicializa as linhas
    RandomizeFlightLine(i);
  //força tamanho da janela p/ 1360x768 (default = videowall)
  ClientWidth:=1360;
  ClientHeight:=768;

  SetaCoresAlternadas(TRUE); //teste set/04 - força cores alternadas (not an option anymore)
  //start sound system
  fSoundActivated:=FALSE;
  fSounderThread:=TThreadFlapSounder.Create;

  My_MouseShowCursor(false); //??
  fCursorVisivel:=false;
end;

// essa fn reajusta o display de 800x600 para o videowall de 1360x780, usado no videowall
// - o design original no DFM foi mantido inicialmente em 800x600
// - os reajustes de posição são meio na galega (e irreversiveis, tem q reiniciar :(
procedure TFormAirportDisplay.CorrectFlapPosParaVideoWall;
var kl,kc:double; CaptionFontRec: TLogFont; aFont:TFont;
    aFontSize, aFontlWidth, aFontTop, aCtrlHeightIncr:integer; bSo5Linhas:boolean;

  //reposiciona um controle
  Procedure DoReposicionaControl(aControl:TControl; bCalcWidth, bCalcHeight:boolean);
  begin
    aControl.Left  :=Trunc(aControl.Left*kc);
    if bCalcWidth  then aControl.Width :=Round(aControl.Width*kc);
    if bCalcHeight then aControl.Height:=Round(aControl.Height*kl);
    if (aControl is TFlapLabel) then
      begin
        TFlapLabel(aControl).FontTop:=aFontTop;
        TFlapLabel(aControl).Font.Assign(aFont);
        //TFlapLabel(aControl).Font.Size:=34; //TFlapLabel(aControl).Font.Size+10; //empirico
        //TFlapLabel(aControl).Font.Name:='STEELFISH';
        //TFlapLabel(aControl).Font.Style:=[];
        aControl.Height:=aControl.Height+aCtrlHeightIncr;
      end;
  end;

begin {CorrectFlapPosParaVideoWall}
  bSo5Linhas:=false;                        //??
  //calcula consts de redimensionamento de layout de 800x600 para 1360/768
  kc:=1360/800;
  kl:=768/600;

  if bSoh5Linhas then  //só 5 linhas (para atingir o tam de letra especificado pelos caras do aeroporto
    begin
      aFontSize:=44;
      aFontlWidth:=-11;
      aFontTop:=-8;
      aCtrlHeightIncr:=22;
    end
    else begin //a melhor opção (na minha opinião)
      aFontSize:=31;    //era 34       //valores derivados "empiricamente", p/ funcionamento com 18 linhas
      aFontlWidth:=-11;
      aFontTop:=-8;
      aCtrlHeightIncr:=11;
    end;

  //repos headers
  //DoReposicionaControl(LData          ,true,false );
  //DoReposicionaControl(LHoraCerta     ,true,false );
  //DoReposicionaControl(Image2         ,true,false );

  aFont:=TFont.Create;
  aFont.Assign(FlapCidadeFrom.Font);
  aFont.Size:=aFontSize;
  aFont.Style:=[];

  GetObject(aFont.Handle,SizeOf(CaptionFontRec), @CaptionFontRec);
  CaptionFontRec.lfWidth:=aFontlWidth; //faz mais estreita que o normal
  aFont.Handle:=CreateFontIndirect(CaptionFontRec);

  //ReposicionaControl(LNumPagina     ,true,true );
  DoReposicionaControl(LHVoo          ,true,true );
  DoReposicionaControl(LOrigemDestino ,true,true );
  DoReposicionaControl(LHEscalas      ,true,true );
  DoReposicionaControl(LHPrev         ,true,true );
  DoReposicionaControl(LHConf         ,true,true );
  DoReposicionaControl(LHSala         ,true,true );
  DoReposicionaControl(LabObservacao  ,true,true );
  DoReposicionaControl(LHHora         ,true,true );

  //linha de voos
  DoReposicionaControl( FlapAir       ,false,false );


  FlapAir.Width:=100; //flap de airlines tem que ter as dimensoes dos BMPs de VideoWall (100x26)
  FlapAir.Height:=40;
  if bSo5Linhas then FlapAir.Top:=FlapAir.Top+10;

  DoReposicionaControl( FlapFlight1 ,true,true);      FlapFlight1.Width:=FlapFlight1.Width-1;
  DoReposicionaControl( FlapFlight2 ,true,true);      FlapFlight2.Width:=FlapFlight2.Width-1;
  DoReposicionaControl( FlapFlight3 ,true,true);      FlapFlight3.Width:=FlapFlight3.Width-1;
  DoReposicionaControl( FlapFlight4 ,true,true);      FlapFlight4.Width:=FlapFlight4.Width-1;
  DoReposicionaControl( FlapFlight5 ,true,true);      FlapFlight5.Width:=FlapFlight5.Width-1;

  DoReposicionaControl( FlapCidadeFrom ,true,true);
  DoReposicionaControl( FlapDeHH       ,true,true);   FlapDeHH   .Width:=FlapDeHH   .Width-1;
  DoReposicionaControl( FlapDeH        ,true,true);   FlapDeH    .Width:=FlapDeH    .Width-1;
  DoReposicionaControl( FlapDeMM       ,true,true);   FlapDeMM   .Width:=FlapDeMM   .Width-1;
  DoReposicionaControl( FlapDeM        ,true,true);   FlapDeM    .Width:=FlapDeM    .Width-1;
  DoReposicionaControl( FlapEscala     ,true,true);
  DoReposicionaControl( FlapParaHH     ,true,true);   FlapParaHH .Width:=FlapParaHH .Width-1;
  DoReposicionaControl( FlapParaH      ,true,true);   FlapParaH  .Width:=FlapParaH  .Width-1;
  DoReposicionaControl( FlapParaMM     ,true,true);   FlapParaMM .Width:=FlapParaMM .Width-1;
  DoReposicionaControl( FlapParaM      ,true,true);   FlapParaM  .Width:=FlapParaM  .Width-1;
  DoReposicionaControl( FlapStatus     ,true,true);

  DoReposicionaControl( FlapGateC      ,true,true);   FlapGateC  .Width:=FlapGateC  .Width-1;
  DoReposicionaControl( FlapGateD      ,true,true);   FlapGateD  .Width:=FlapGateD  .Width-1;
  DoReposicionaControl( FlapGateU      ,true,true);   FlapGateU  .Width:=FlapGateU  .Width-1;
  DoReposicionaControl( Led1           ,false,false); //não redimensiona tamanho dos Leds (ferra a animação)
  DoReposicionaControl( Led2           ,false,false); //não redimensiona tamanho dos Leds (ferra a animação)
  DoReposicionaControl( Lab1           ,true,true);
  DoReposicionaControl( Lab2           ,true,true);
end;

procedure TFormAirportDisplay.RandomizeFlightLine(N:integer);
var aCidade:String; H,M,aFlight:String[10]; aLM:TFlightLineManager;
begin
  {$IFDEF SIMULACAO}
  aLM:=Lines[N]; //pega uma linha aleatoria

  aCidade:=Cidades[Random(MAXCIDADES)];
  aLM.fFlapCidadeFrom.Caption:=aCidade;

  aCidade:=Cidades[Random(MAXCIDADES)];
  if Random(10)>5 then aCidade:=' ';

  aLM.fFlapEscala.Caption:=aCidade;

  if Airlines.Count>0 then
  aLM.fFlapAir.Caption:=Airlines.Strings[Random(Airlines.Count)];

  H:=IntToStr(Random(24)); if Length(H)=1 then H:=' '+H; //hora
  aLM.fFlapDeHH.Caption:=H[1];
  aLM.fFlapDeH.Caption:=H[2];
  M:=IntToStr(Random(60)); if Length(M)=1 then M:='0'+M; //minutos
  aLM.fFlapDeMM.Caption:=M[1];
  aLM.fFlapDeM.Caption:=M[2];

  H:=IntToStr(Random(24)); if Length(H)=1 then H:=' '+H; //hora
  aLM.fFlapParaHH.Caption:=H[1];
  aLM.fFlapParaH.Caption:=H[2];
  M:=IntToStr(Random(60)); if Length(M)=1 then M:='0'+M; //minutos
  aLM.fFlapParaMM.Caption:=M[1];
  aLM.fFlapParaM.Caption:=M[2];

  aFlight:=IntToStr(Random(2000));
  while (Length(aFlight)<5) do aFlight:=' '+aFlight;

  aLM.fFlapFlight1.Caption:=aFlight[1];
  aLM.fFlapFlight2.Caption:=aFlight[2];
  aLM.fFlapFlight3.Caption:=aFlight[3];
  aLM.fFlapFlight4.Caption:=aFlight[4];
  aLM.fFlapFlight5.Caption:=aFlight[5];

  aLM.fFlapStatus.Caption:=Statuses[Random(MAXSTATUS)];

  aLM.fFlapGateC.Caption:=IntToStr(Random(4)+1);
  aLM.fFlapGateD.Caption:=IntToStr(Random(4)+1);
  aLM.fFlapGateU.Caption:=IntToStr(Random(4)+1);

  //info de debug
  //LnumFlapEntries.Caption:=intToStr(numFlapEntries);
  //LtotBMPs.Caption:=intToStr(totBMPs);
  {$ENDIF SIMULACAO}
end;

const
  ContTicks:integer=0;
  SlideCount:integer=0;
  bFlapNext:boolean=FALSE;
  SlideDir:string='c:\'; // \\Passoca\MAXTOR\slides\';

procedure TFormAirportDisplay.NextSlide;
var i:integer; sc:string; aBMP:TBitmap;  aJPeg:TJPEGImage; aFN:String;
begin
  FlapLabels_SlideshowTick;
  if bFlapNext then
    begin
      bFlapNext:=FALSE;
      for i:=0 to Random(2) do
        RandomizeFlightLine(Random(MAXLINEMANAGERS)); //..randomiza umas linhas
    end;

  if CountFlapping>0 then
    begin
      inc(SlideCount);
      sc:=IntToStr(SlideCount);
      while Length(sc)<4 do sc:='0'+sc;
      MostraPCharVar(1,Pchar(sc));
      //Save slide
      aBMP:=TBitmap.create;
      Form2BMPCapture(Self,aBMP);
      aJPeg:=TJPEGImage.Create;
      aJPeg.Assign(aBMP);
      aBMP.Free;
      aFN:=SlideDir+'AD'+sc+'.jpg';
      try
        aJPeg.SaveToFile(aFN);
      except
        MessageDlg('Erro no salvamento de '+aFN, mtInformation,[mbOk], 0);
      end;
      aJPeg.Free;
    end
    else begin
      bFlapNext:=TRUE;
      MessageBeep(0);
    end;
end;

procedure TFormAirportDisplay.Timer1Timer(Sender: TObject);
var i:integer; S:String;
begin
  inc(ContTicks);
  if fSoundActivated then
    begin
      //MostraIntVar(1,CountFlapping);
      if CountFlapping=0 then fSounderThread.PlayState:=psSilent
        else if CountFlapping<16 then  fSounderThread.PlayState:=psTap //tap..tap..
        else if CountFlapping<32 then  fSounderThread.PlayState:=psTup //tup..tup..tup..tup..
         else fSounderThread.PlayState:=psTrup;                        //trup..trup..trup..trup..
      // trecho abaixo obsoleto. Substituido em mar/06
      //if CountFlapping=0 then SetSoundStatus(0)       //para som
      //  else if CountFlapping<6 then SetSoundStatus(1)  //tup..tup..tup..tup..
      //  else SetSoundStatus(2);                         //trup..trup..trup..trup..
    end;

  //a cada 10 segundos faz algumas operacoes periodicas
  if (not bBuildingSlideShow) and (ContTicks mod 80=0 ) then //cada 8 segs..
    begin
        {$IFDEF SIMULACAO}
        for i:=0 to Random(2) do
          RandomizeFlightLine(Random(MAXLINEMANAGERS)); //..randomiza umas linhas
        {$ENDIF SIMULACAO}
        S:=FormatDateTime('hh:nn',Time);                //ajusta hora certa
        if (S<>LHoraCerta.Caption) then
          begin
           LHoraCerta.Caption:=S;
           StartPiscadaHoracertaPagina;   //isso invoca OmColorFader1.Start
          end;
     end;
  if (ContTicks mod 1000=0) then //..a cada 100 seg atualiza a data, pois isso vai ficar ligado dias...
    LData.Caption:=FormatDateTime('dd/mmm/yy',Date);
end;

procedure TFormAirportDisplay.LinhaCentral1Click(Sender: TObject);
var i:integer;
begin
  for i:=0 to MAXLINEMANAGERS-1 do //cria os outros line managers
    with Lines[i] do
        begin
          fFlapAir.bLinhaCentral        :=not fFlapAir.bLinhaCentral       ;
          fFlapFlight1.bLinhaCentral    :=not fFlapFlight1.bLinhaCentral   ;
          fFlapFlight2.bLinhaCentral    :=not fFlapFlight2.bLinhaCentral   ;
          fFlapFlight3.bLinhaCentral    :=not fFlapFlight3.bLinhaCentral   ;
          fFlapFlight4.bLinhaCentral    :=not fFlapFlight4.bLinhaCentral   ;
          fFlapFlight5.bLinhaCentral    :=not fFlapFlight5.bLinhaCentral   ;

          fFlapCidadeFrom.bLinhaCentral :=not fFlapCidadeFrom.bLinhaCentral;
          fFlapDeHH.bLinhaCentral       :=not fFlapDeHH.bLinhaCentral      ;
          fFlapDeH.bLinhaCentral        :=not fFlapDeH.bLinhaCentral       ;
          fFlapDeMM.bLinhaCentral       :=not fFlapDeMM.bLinhaCentral      ;
          fFlapDeM.bLinhaCentral        :=not fFlapDeM.bLinhaCentral       ;
          fFlapEscala.bLinhaCentral     :=not fFlapEscala.bLinhaCentral  ;
          fFlapParaHH.bLinhaCentral     :=not fFlapParaHH.bLinhaCentral    ;
          fFlapParaH.bLinhaCentral      :=not fFlapParaH.bLinhaCentral     ;
          fFlapParaMM.bLinhaCentral     :=not fFlapParaMM.bLinhaCentral    ;;
          fFlapParaM.bLinhaCentral      :=not fFlapParaM.bLinhaCentral     ;
          fFlapStatus.bLinhaCentral     :=not fFlapStatus.bLinhaCentral    ;
          fFlapGateC.bLinhaCentral      :=not fFlapGateC.bLinhaCentral ;
          fFlapGateD.bLinhaCentral      :=not fFlapGateD.bLinhaCentral ;
          fFlapGateU.bLinhaCentral      :=not fFlapGateU.bLinhaCentral ;
        end;
  FlapLabels_RebuildTextBMPs;
  for i:=0 to MAXLINEMANAGERS-1 do       //inicializa as linhas
    Lines[i].RenderCaptions;
end;

procedure TFormAirportDisplay.StartPiscadaHoracertaPagina;
begin
  LHoraCerta.Transparent:=false; //começa fade da hora certa. Isso pisca atualização.
  LNumPagina.Transparent:=false;
  OmColorFader1.Start;
end;

procedure TFormAirportDisplay.OmColorFader1ColorChange(Sender: TObject;  aColor: TColor);
begin
  LHoraCerta.Color:=aColor;   //seta cor do fader
  LNumPagina.Color:=aColor;

  if (aColor=OmColorFader1.FinalColor) then //quando parado, deixa labels transparentes
    begin
      LHoraCerta.Transparent:=true;
      LNumPagina.Transparent:=true;
    end;
end;

procedure TFormAirportDisplay.Cordefundo1Click(Sender: TObject);
begin
  ColorDlg.Color:=Color;
  if ColorDlg.Execute then
    Color:=ColorDlg.Color;
end;

procedure TFormAirportDisplay.Cordoslabels1Click(Sender: TObject);
var i:integer; aColor:TColor;
begin
  ColorDlg.Color:=Lines[0].fFlapCidadeFrom.BackColor;
  if ColorDlg.Execute then
    begin
      aColor:=ColorDlg.Color;
      for i:=0 to MAXLINEMANAGERS-1 do       //inicializa as linhas
        Lines[i].SetBackColors(aColor);
      FlapLabels_RebuildTextBMPs;
      for i:=0 to MAXLINEMANAGERS-1 do       //inicializa as linhas
        Lines[i].RenderCaptions;
    end;
end;

procedure TFormAirportDisplay.SetSoundStatus(aStatus: integer);

  //DoPlay obsoleto
  Procedure DoPlay(const aWavFile:String);
  var PlayFlags:dword;
  begin
    if aWavFile<>'' then
      begin
        //PlaySound(nil,{hInstance} 0,SND_PURGE);              //pára som anterior, se houver
        //Application.ProcessMessages;
        PlayFlags:=SND_ASYNC or SND_FILENAME or SND_LOOP;                //repete em loop //tirei o 'or SND_NOSTOP'
        PlaySound(PChar(aWavFile),{hInstance} 0,PlayFlags);
      end;
  end;

begin
  (* Obsoleto
  if (fFlapSoundStatus<>aStatus) then
    begin
      case aStatus of
        0: PlaySound(nil,{hInstance} 0,SND_PURGE);
        1: DoPlay('tup.wav');
        2: DoPlay('trup.wav');
      end;
      fFlapSoundStatus:=aStatus;
    end;
  *)
end;

procedure TFormAirportDisplay.Som1Click(Sender: TObject);
begin
  fSoundActivated:=not fSoundActivated;
  if not fSoundActivated then SetSoundStatus(0); //desativa som
end;

procedure TFormAirportDisplay.Slideshow1Click(Sender: TObject);
begin
  bBuildingSlideShow:=not bBuildingSlideShow;
  if bBuildingSlideShow then
    begin
      WindowState := wsNormal;
      BorderStyle := bsSizeable;
      SlideDir:= InputBox('Diretorio', 'Entre diretorio (com \ no final !)', SlideDir);
      ClientWidth  := 800;
      ClientHeight := 600;
    end;
end;

procedure TFormAirportDisplay.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if bBuildingSlideShow then
    NextSlide;
end;

procedure TFormAirportDisplay.Termina1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFormAirportDisplay.SetEhDepartures(const Value: boolean);
begin
  if fEhDepartures <> Value then
    begin
      fEhDepartures := Value;
      if fEhDepartures then
        begin
          LDirecao.Caption:=sDepartures;
          LOrigemDestino.Caption:=sParaTo;
          LHSala.Caption:=sPortao; //ago/04- era :=sSala;
        end
        else begin
          LDirecao.Caption:=sArrivals;
          LOrigemDestino.Caption:=sDeFrom;
          LHSala.Caption:=sDesemb;
        end;
    end;
end;

procedure TFormAirportDisplay.Configuracao1Click(Sender: TObject);
begin
  FormAirportDisplayControl.Show;
end;

//se aVoo=nil, limpa tudo, se assigned, atualiza display
//evento de atualizacao de voo
procedure TFormAirportDisplay.SetInfoVoo(N:integer; aVoo:TInformacaoDeVoo);
var aCidade,aCidadeFrom,aHora,aCheckin:String; H,M,aFlight,aFlight2,aGate:String[10];
    aLM, aLMant:TFlightLineManager;
    aStatus,aStatusP,aStatusI:String[50];
    aEscalas:TStringList; p:integer;
begin
  if (N>fNumLinhas) then exit; //ignora modificacoes em linha invisiveis....
  aLM:=Lines[N]; //pega a linha
  aLM.fVoo:=aVoo;

  if (N=0) then aLMant:=nil else aLMant:=Lines[N-1]; //pega proxima linha (p/ controle de parcerias)

  if not Assigned(aVoo) then
    begin
      aLM.ForceClear;
      exit;
    end;

  if (aVoo.FlighType=ftArrival) then
    aCidadeFrom:=CodLocal2Local(aVoo.Origem,aVoo)        //arrivals --> Cidade=Origem
    else aCidadeFrom:=CodLocal2Local(aVoo.Destino,aVoo); //departures --> Cidade=Destino

  aLM.fFlapEscala.Subtexts.Clear;

  if fEhBaggageClaim then aLM.fFlapEscala.Subtexts.Add(aCidadeFrom) //no bagageclaim, a escala incorpora a origem
    else aLM.fFlapCidadeFrom.Caption:=aCidadeFrom;

  aCidade:=aVoo.Escala1;    //escala 1...
  aCidade:=CodLocal2Local(aCidade,aVoo);
  if (aCidade<>'') then
    begin
      aLM.fFlapEscala.Subtexts.Add(aCidade);
      aCidade:=aVoo.Escala2;     //escala 2....
      aCidade:=CodLocal2Local(aCidade,aVoo);
      if aCidade<>'' then
        begin
          aLM.fFlapEscala.Subtexts.Add(aCidade);
          aCidade:=aVoo.Escala3;  //escala 3
          aCidade:=CodLocal2Local(aCidade,aVoo);
          if aCidade<>'' then
            begin
              aLM.fFlapEscala.Subtexts.Add(aCidade);
              aCidade:=aVoo.Escala4;
              aCidade:=CodLocal2Local(aCidade,aVoo);
              if aCidade<>'' then aLM.fFlapEscala.Subtexts.Add(aCidade);
            end;
          aLM.fFlapEscala.Subtexts.Add(' '); //se tem duas ou mais escalas, insere um campo vazio no final
        end;
    end
    else begin //sem escalas..
      aLM.fFlapEscala.Caption:='';
    end;

  if Assigned(aVoo.VooParceria) then
    begin
      aLM.fFlapAir.Caption:='';   //teste
      aLM.fFlapAir.SubtextTicks:=140;
      aLM.fFlapAir.Subtexts.Add(aVoo.AirLine);
      aLM.fFlapAir.Subtexts.Add(aVoo.VooParceria.AirLine);
    end
    else begin
      aLM.fFlapAir.SubtextTicks:=0;
      aLM.fFlapAir.Caption:=aVoo.AirLine;
    end;

  H:=IntToStr(Random(24)); if Length(H)=1 then H:=' '+H; //hora

  aHora:=aVoo.SomeTime;       //tipo '1235'
  while Length(aHora)<4 do aHora:=' '+aHora;
  H:=Copy(aHora,1,2); M:=Copy(aHora,3,2);
  // if H[1]='0' then H[1]:=' '; //Out07: tirei isso para satisfazer os caras de GRU, que preferem a "hora militar"

  aLM.fFlapDeHH.Caption:=H[1]; aLM.fFlapDeH.Caption:=H[2];
  aLM.fFlapDeMM.Caption:=M[1]; aLM.fFlapDeM.Caption:=M[2];

  aHora:=aVoo.EstimatedTime;         //tipo '1235'
  while Length(aHora)<4 do aHora:=' '+aHora;
  H:=Copy(aHora,1,2); M:=Copy(aHora,3,2);
  // if H[1]='0' then H[1]:=' ';    //Out07: tirei isso para satisfazer os caras de GRU, que preferem a "hora militar"

  aLM.fFlapParaHH.Caption:=H[1];   aLM.fFlapParaH.Caption:=H[2];
  aLM.fFlapParaMM.Caption:=M[1];   aLM.fFlapParaM.Caption:=M[2];

  aFlight:=aVoo.Voo;
  while Length(aFlight)<5 do aFlight:='0'+aFlight; //minimo de 4 digitos  ( set07 - por solicitaçao de Guarulhos, voltei os zeros a esquerda . era ' ' )
  //if aFlight[1]='0' then aFlight[1]:=' ';          //tira o zero a esquerda
  p:=Length(aFlight);
  if (p>5) then aFlight:=Copy(aFlight,p-5+1,5);    //pega só os ultimos 5 digitos
  // ( ignora o 5 digito, que passou a ser usado por Congonhas em jul/04 mas ñ tem que aparecer )

  if Assigned(aVoo.VooParceria) then 
    begin
      aFlight2:=aVoo.VooParceria.Voo;
      while Length(aFlight2)<5 do aFlight2:='0'+aFlight2; //minimo de 4 digitos  ( set07 - por solicitaçao de Guarulhos, voltei os zeros a esquerda . era ' ' )
      //if aFlight[1]='0' then aFlight[1]:=' ';          //tira o zero a esquerda
      p:=Length(aFlight2);
      if (p>5) then aFlight2:=Copy(aFlight2,p-5+1,5);    //pega só os ultimos 5 digitos
      // ( ignora o 5 digito, que passou a ser usado por Congonhas em jul/04 mas ñ tem que aparecer )
      aLM.fFlapFlight1.Caption:='';
      aLM.fFlapFlight2.Caption:='';
      aLM.fFlapFlight3.Caption:='';
      aLM.fFlapFlight4.Caption:='';
      aLM.fFlapFlight5.Caption:='';

      aLM.fFlapFlight1.SubtextTicks:=140;
      aLM.fFlapFlight1.Subtexts.Add(aFlight[1]);
      aLM.fFlapFlight1.Subtexts.Add(aFlight2[1]);

      aLM.fFlapFlight2.SubtextTicks:=140;
      aLM.fFlapFlight2.Subtexts.Add(aFlight[2]);
      aLM.fFlapFlight2.Subtexts.Add(aFlight2[2]);

      aLM.fFlapFlight3.SubtextTicks:=140;
      aLM.fFlapFlight3.Subtexts.Add(aFlight[3]);
      aLM.fFlapFlight3.Subtexts.Add(aFlight2[3]);

      aLM.fFlapFlight4.SubtextTicks:=140;
      aLM.fFlapFlight4.Subtexts.Add(aFlight[4]);
      aLM.fFlapFlight4.Subtexts.Add(aFlight2[4]);

      aLM.fFlapFlight5.SubtextTicks:=140;
      aLM.fFlapFlight5.Subtexts.Add(aFlight[5]);
      aLM.fFlapFlight5.Subtexts.Add(aFlight2[5]);
    end
    else begin
      aLM.fFlapFlight1.SubtextTicks:=0;
      aLM.fFlapFlight1.Caption:=aFlight[1];
      aLM.fFlapFlight2.SubtextTicks:=0;
      aLM.fFlapFlight2.Caption:=aFlight[2];
      aLM.fFlapFlight3.SubtextTicks:=0;
      aLM.fFlapFlight3.Caption:=aFlight[3];
      aLM.fFlapFlight4.SubtextTicks:=0;
      aLM.fFlapFlight4.Caption:=aFlight[4];
      aLM.fFlapFlight5.SubtextTicks:=0;
      aLM.fFlapFlight5.Caption:=aFlight[5];
    end;



  aGate:=Trim(aVoo.Gate); //pegando Emb

  while Length(aGate)<3 do aGate:=' '+aGate;

  if fEhBaggageClaim then
    begin
      aLM.fFlapGateD.Caption:=aVoo.Esteira; //TODO: isso passou de char para string (em GRU a esteira tem 2 digitos)
    end
    else begin
      aLM.fFlapGateC.Caption:=aGate[1];
      aLM.fFlapGateD.Caption:=aGate[2];
      aLM.fFlapGateU.Caption:=aGate[3];
    end;

  aStatus:=aVoo.StatusCode; //pega codigo de 3 letras do StatusCode (no caso da Solari)
  if aStatus<>'' then
    begin
      aStatusP:=CodStatus2Status(aStatus); //ret tipo 'Aterrisou|Landed'
      aStatusI:='';
      p:=Pos('|',aStatusP);
      if p>0 then
        begin
          aStatusI:=Copy(aStatusP,p+1,MAXINT);
          aStatusP:=Copy(aStatusP,1,p-1);
        end;
    end
    else begin //No caso da Infraero, o SIIV já manda a coisa traduzida
      aStatusI:=aVoo.StatusMsgEng;
      aStatusP:=aVoo.StatusMsgPor;
    end;

  if aVoo.Destacado then
    begin
      aLM.fLed.SyncStart;
      aLM.fLed2.SyncStart;
    end
    else begin
      aLM.fLed.Play:=FALSE; aLM.fLed.Frame:=0;
      aLM.fLed2.Play:=FALSE; aLM.fLed2.Frame:=0;
    end;

  aLM.fFlapStatus.Subtexts.Clear;
  if (aStatusP<>'') then aLM.fFlapStatus.Subtexts.Add(aStatusP);
  if (aStatusI<>'') then aLM.fFlapStatus.Subtexts.Add(aStatusI);

  if FormAirportDisplayControl.EhPartidas then   // somente mostra checkins na tela de partidas
    begin
      aCheckin:=aVoo.GetLinhaCheckins;
      aLM.fFlapStatus.Subtexts.Add(aCheckin);
    end;

  if FormAirportDisplayControl.CBMostraLinksDeParceria.Checked then
    begin
      if Assigned(aLMant) and Assigned(aLMant.fVoo) and (aLMant.fVoo.Voo=aVoo.Voo) then
        aLMant.fBevelVooParceria.Visible:=TRUE;
    end;
  aLM.fBevelVooParceria.Visible:=false;

  aLM.fFlapStatus.Caption:=aStatusP;
end;

procedure TFormAirportDisplay.Sobre1Click(Sender: TObject);
begin
  FormAirportDisplaySplash := TFormAirportDisplaySplash.Create(nil);
  FormAirportDisplaySplash.ShowModal;
  FormAirportDisplaySplash.Free;
  FormAirportDisplaySplash:=nil;
end;

procedure TFormAirportDisplay.FormShow(Sender: TObject);
begin
  FormAirportDisplayControl.BSetPosicaoClick(nil); //seta posicao pelo controle, just in case
end;

function TFormAirportDisplay.GetMostraCabecalhos: boolean;
begin
  Result:=PanelCabecalhos.Visible;
end;

// AjustaTops reajusta posição y das linhas. Sistema automatico de distribuição na vertical. Depende de:
//  - Se PanelCabecalhos.Visible mostra cabeçalho
//  - Numero de linhas
//  - Se videowall, tem que alinhar com o topo dos paineis, pra não cortar linha no meio (bagage claim é mostrado em video unico)
procedure TFormAirportDisplay.AjustaTops;
var i,h,fh,aTop,incr:integer;
begin
  h:=FlapCidadeFrom.Height; //pega altura de 1 flap padrao
  fh:=Height;               //isso pega altura da janela (768 ou 600)

  if PanelCabecalhos.Visible then aTop:=TOPLINETOP  //abre espaço no topo pro cabeçalho
    else aTop:=1;

  dec(fh,aTop);

  incr:=fh div fNumLinhas; //calcula incremento de uma linha para outra, de acordo com num de linhas visiveis
  if (fNumLinhas<=14) then inc(aTop,incr div 3); //se poucas linhas, espaça mais a primeira do cabeçalho

  for i:=0 to fNumLinhas-1 do
    begin
      if not fEhBaggageClaim then //somente as telas de chegada´/partida são em modo video wall (BC não)
        begin
          if (aTop<256) and (aTop+30>256) then aTop:=256+1; //ajusta p/ nao cair na divisao de plasmas do VW
          if (aTop<512) and (aTop+30>512) then aTop:=512+1;
        end;
      Lines[i].SetTops(aTop);      //ajusta a pos da linha na vertical
      Lines[i].fBevelVooParceria.Height:=incr;
      inc(aTop,incr);
    end;
end;

procedure TFormAirportDisplay.SetMostraCabecalhos(const Value: boolean);
begin
  PanelCabecalhos.Visible:=Value;
  AjustaTops;            //reajusta posição y das linhas
end;

Procedure TFormAirportDisplay.SetNumLinhas(N:integer);
var i,aTop,incr:integer;
begin
  if (fNumLinhas<>N) then
    begin
      fNumLinhas:=N;  //ajusta num de linhas visiveis
      for i:=0 to MAXLINEMANAGERS-1 do Lines[i].Visible:=(i<N); //seta visibilidade das linhas
      AjustaTops;
    end;
end;

Procedure TFormAirportDisplay.SetHeaderControlPositions; //.. de acordo com layout usado
begin
  if fEhBaggageClaim then
    begin
      //LHVoo
      //LOrigemDestino
      //LHEscalas
      //LHPrev
      //LHConf
      //LHSala
      //LabObservacao
      //LHHora
      LDirecao.Left    :=LDirecao.Left   -300;
      LNumPagina.Left  :=LNumPagina.Left -550;
      LData.Left       :=LData.Left      -550;
      LHoraCerta.Left  :=LHoraCerta.Left -550;
      Image2.Left      :=Image2.Left     -550;
   end
   else begin
      LDirecao.Left    :=LDirecao.Left   +300;
      LNumPagina.Left  :=LNumPagina.Left +200;
      LData.Left       :=LData.Left      +200;
      LHoraCerta.Left  :=LHoraCerta.Left +200;
      Image2.Left      :=Image2.Left     +200;
   end;
end;

Procedure TFormAirportDisplay.AdjustHeaderControls(k:double);
begin
  ChangeControlPositionAndWidth(LHVoo,k);
  ChangeControlPositionAndWidth(LOrigemDestino,k);
  ChangeControlPositionAndWidth(LHEscalas,k);
  ChangeControlPositionAndWidth(LHPrev,k);
  ChangeControlPositionAndWidth(LHConf,k);
  ChangeControlPositionAndWidth(LHSala,k);
  ChangeControlPositionAndWidth(LabObservacao,k);
  ChangeControlPositionAndWidth(LHHora,k);
  //if (k<1) then LNumPagina.Left:=400 //move o num da pagina, para nao interferir com LHHora
  //  else LNumPagina.Left:=386;
end;

// ajusta visibilidade do campo de status (e leds associados)
Procedure TFormAirportDisplay.SetStatusVisible(bVisible:boolean);
var i:integer; aFont:TFont; k:double; iVisible:boolean;
begin
  if (bVisible<>fLayoutManager.fSizeDefault) then //se mudou, altera layout
    begin
      LHHora.Visible:=bVisible;  //quando sem status, some com o hora/time, para nao interferir com o relogio
      fLayoutManager.fSizeDefault:=bVisible;
      if bVisible then k:=1/1.2 else k:=1.2;  //cte de alteracao de tamanho
      LabObservacao.Visible:=bVisible;
      aFont:=TFont.Create;
      aFont.Assign(FlapCidadeFrom.Font);
      if bVisible then aFont.Size:=13
        else aFont.Size:=18;
      for i:=0 to MAXLINEMANAGERS-1 do
        begin
          iVisible:=bVisible and (i<fNumLinhas);            //ve se bVisible e se linha i visivel
          Lines[i].fFlapStatus.Visible :=iVisible;
          Lines[i].fLed.Visible        :=iVisible;
          Lines[i].fLed2.Visible       :=iVisible;
          //if not iVisible then Lines[i].fBevelVooParceria.Visible:=false;
          fLayoutManager.AdjustLineLayout(Lines[i],k);
        end;
      SetDisplayFonts(aFont);
      FlapLabels_RebuildTextBMPs;
      for i:=0 to fNumLinhas-1 do Lines[i].RenderCaptions;      //inicializa as linhas
      aFont.Free;
      AdjustHeaderControls(k); //repositiona Labels no header
    end;
end;

procedure TFormAirportDisplay.FasterMessageLoop;
var Msg:TMsg;
begin
  Show;
  while true do
    try
      if PeekMessage(Msg,0,0,0,PM_REMOVE) then
        begin
          if Msg.message=WM_QUIT then break;
          TranslateMessage(Msg);
          DIspatchMessage(Msg);
        end;
    except
      Application.HandleException(Self);
    end;
end;


procedure TFormAirportDisplay.SetaCoresAlternadas(value: boolean);
var i:integer;
begin
  for i:=0 to fNumLinhas-1 do
    begin
      if (i mod 2=0) then  //só as pares...
        Lines[i].SetCoresAlternadas(value);
    end;
end;

procedure TFormAirportDisplay.SetaReflexos(value: boolean);
var i:integer;
begin
  for i:=0 to fNumLinhas-1 do
    begin
      Lines[i].SetReflexos(value);
    end;
end;

procedure TFormAirportDisplay.AjustaDimensoesDaJanela;
begin
  if fEhBaggageClaim then
    begin
      ClientWidth:=800;   //bagaggeclaim é 800x600
      ClientHeight:=600;
    end
    else begin
      ClientWidth:=1360;  //default é videowall (1360x768)
      ClientHeight:=768;
    end;
end;

procedure TFormAirportDisplay.SetEhBaggageClaim(const Value: boolean);
var i,aTop,incr:integer;
begin
  if (fEhBaggageClaim<>Value) then
    begin
      fEhBaggageClaim:=Value;
      AjustaDimensoesDaJanela;  //ajusta tamanho da janela do display
      // -modo videowall (default) 1360x768
      // -modo baggage claim 800x600
      for i:=0 to MAXLINEMANAGERS-1 do
        Lines[i].EhBaggageClaim:=fEhBaggageClaim;   //isso altera o layout

      if fEhBaggageClaim then
        begin
          //ajusta posicao dos headers. Isso saiu por experimentacao e erro !!
          LHSala.Caption:=sEsteira;
          LHEscalas.Visible:=false; //Left:=FlapEscala.Left+50;
          LHPrev.Left:=FlapDeH.Left;
          LHConf.Left:=FlapParaH.Left;
          LHSala.Left:=FlapGateD.Left-15;

          LabObservacao.Visible:=false;
          LHHora.Visible:=false;
          LNumPagina.Caption:='Esteira/Belt';
          //LNumPagina.Left:=LNumPagina.Left-150;
          //--
          FlapLabels_ClearTextBMPs;

          FlapLabels_RebuildTextBMPs;
          for i:=0 to MAXLINEMANAGERS-1 do
            begin
              Lines[i].RenderCaptions;      //inicializa as linhas
              Lines[i].ForceClear2;
            end;
        end
        else begin
          if fEhDepartures then LHSala.Caption:=sPortao
              else LHSala.Caption:=sDesemb;
          //TODO: voltar ao status anterior do AD
        end;
      AjustaTops;
      SetHeaderControlPositions;
    end;
end;

procedure TFormAirportDisplay.FormDestroy(Sender: TObject);
begin
  fSounderThread.Terminate;
  //fSounderThread.Free;
end;

procedure TFormAirportDisplay.FormPaint(Sender: TObject);
begin
  case fADPlotGridMode of
    gmNone:;
    gmVideoWall1360x768: with Canvas do  //grid 3x3 do vw (res 1360x768)
    begin
      Pen.Color:=clGray;
      MoveTo( 0 , 256);        LineTo( 1360 , 256);
      MoveTo( 0 , 512);        LineTo( 1360 , 512);
      MoveTo( 453,0);          LineTo( 453 ,   768);
      MoveTo( 906,0);          LineTo( 906 ,   768);
    end;
    gm800x600: with Canvas do
    begin
      Pen.Color:=clGray;
      MoveTo( 800,0);         LineTo( 800 ,   600);
      MoveTo( 0,600);         LineTo( 800 ,   600);
    end;
  end;
end;

procedure TFormAirportDisplay.Image1Click(Sender: TObject);
begin
  case fADPlotGridMode of
    gmNone:              fADPlotGridMode:=gmVideoWall1360x768;
    gmVideoWall1360x768: fADPlotGridMode:=gm800x600;
    gm800x600:           fADPlotGridMode:=gmNone;
  end;
  Invalidate;
end;

procedure TFormAirportDisplay.SetEhEsteiraPatio(const Value: boolean);
begin
  if (fEhEsteiraPatio<>Value) then
    begin
      fEhEsteiraPatio := Value;
      //TODO: ainda não implementado nesta versao de videowall
    end;
end;

procedure TFormAirportDisplay.ActToggleCursorExecute(Sender: TObject);
begin
  if fCursorVisivel then    // toggle na verdade...
    begin
      My_MouseShowCursor(false); //??
      fCursorVisivel:=false;
    end
    else begin
      My_MouseShowCursor(true); //??
      fCursorVisivel:=true;
    end;
end;

procedure TFormAirportDisplay.ActMudaPaginaExecute(Sender: TObject);
begin
  FormAirportDisplayControl.TogglePagina;
end;

end.

Unit OmColorFader;  {Muda gradualmente de uma cor pra outra, em intervalos de 100 ms}
// (c)copr 2002-2008 Omar Reis
interface

uses
  Classes,sysutils, Windows,Graphics,extctrls,debug;

Type
  TColorChangeNotify=procedure(Sender:TObject; aColor:TColor) of object;

  //TOmColorFader usa um timer global. O Timer.Interval é fixo (100 ms). O timer é enabled/disabled pelos faders, conforme necessario
  TOmColorFader=class(TComponent)
  private
    fFinalColor: TColor;
    fInitialColor: TColor;

    fRIncr,fGIncr,fBIncr:double;  //incrementos R, G e B
    fR,fG,fB:double;              //cor corrente (R,G e B)
    fState:integer;
    fSteps: integer;
    fOnColorChange: TColorChangeNotify;

    procedure SetFinalColor(const Value: TColor);
    procedure SetInitialColor(const Value: TColor);
    procedure CalcIncrementos;
    procedure SetSteps(const Value: integer);
    procedure SetColorToInitial;
    function  GetCurrentColor: TColor;
    function  GetIsActive: boolean;
  protected
    Procedure ColorFaderTimerTick(Sender:TObject);
  public
    Constructor Create(aOwner:TComponent); override;
    Destructor  Destroy;                   override;
    Procedure   Start;

    Property    State:integer read fState;
    Property    CurrentColor:TColor read GetCurrentColor;
    Property    IsActive:boolean read GetIsActive;
  published
    Property InitialColor:TColor read fInitialColor write SetInitialColor; //cor inicial
    Property FinalColor  :TColor read fFinalColor   write SetFinalColor;   //cor final
    Property Steps:integer       read fSteps        write SetSteps;        //num de passos de 100 ms entre uma cor e outra
    Property OnColorChange:TColorChangeNotify       read fOnColorChange write fOnColorChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Omar', [TOmColorFader]);
end;

type
  TGlobalColorFaderTimer=Class //timer global dos ColorFaders
  private
    fTimer:TTimer;
    fList:TList;
    Procedure  GlobalTimeHit(Sender:TObject);
    function   GetCount:integer;
    function   GetInterval:cardinal;
    Procedure  SetInterval(value:cardinal);
  public
    Constructor Create;
    Destructor  Destroy; Override;

    Property    Timer:TTimer read fTimer;
    Procedure   AddColorFader(aColorFader:TOmColorFader);
    Procedure   DelColorFader(aColorFader:TOmColorFader);
    Procedure   UpdateEnabled;

    Property    Count:integer    read GetCount;
    Property    Interval:cardinal read GetInterval write SetInterval;
  end;

const
  GlobalColorFaderTimer:TGlobalColorFaderTimer=nil;

{ TGlobalColorFaderTimer }
Constructor TGlobalColorFaderTimer.Create;
begin
  inherited;
  fTimer:=TTimer.Create(nil);
  fTimer.Enabled:=FALSE;
  fTimer.Interval:=100;
  fTimer.OnTimer:=GlobalTimeHit;
  fList:=TList.Create;
end;

Destructor  TGlobalColorFaderTimer.Destroy;
begin
  fTimer.Free;
  fList.Free;
  inherited;
end;

Procedure   TGlobalColorFaderTimer.AddColorFader(aColorFader:TOmColorFader);
begin
  fList.Add(aColorFader);
end;

Procedure   TGlobalColorFaderTimer.DelColorFader(aColorFader:TOmColorFader);
begin
  fList.Remove(aColorFader);
end;

Procedure   TGlobalColorFaderTimer.GlobalTimeHit(Sender:TObject);
var i:integer;
begin
  for i:=0 to fList.Count-1 do
    TOmColorFader(fList.Items[i]).ColorFaderTimerTick(Self);
end;

function   TGlobalColorFaderTimer.GetCount:integer;
begin Result:=fList.Count; end;

function   TGlobalColorFaderTimer.GetInterval:cardinal;
begin Result:=fTimer.Interval; end;

Procedure  TGlobalColorFaderTimer.SetInterval(value:cardinal);
begin
  if (value<>fTimer.Interval) then
    begin
      fTimer.Interval:=value;
      fTimer.Enabled:=(value<>0);
    end;
end;

procedure TGlobalColorFaderTimer.UpdateEnabled;
var i:integer; bEnabled:boolean;
begin
  bEnabled:=FALSE;
  for i:=0 to fList.Count-1 do if TOmColorFader(fList.Items[i]).IsActive then
    begin
      bEnabled:=TRUE;
      break;
    end;
  fTimer.Enabled:=bEnabled;
end;

{ TOmColorFader }

constructor TOmColorFader.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fState:=0;
  fSteps:=10;
  fInitialColor:=clBlack;
  fFinalColor:=clWhite;
  CalcIncrementos;
  fOnColorChange:=nil;

  if not Assigned(GlobalColorFaderTimer) then GlobalColorFaderTimer:=TGlobalColorFaderTimer.Create;
  GlobalColorFaderTimer.AddColorFader(Self); //adiciona ao timer global
end;

destructor TOmColorFader.Destroy;
begin
  GlobalColorFaderTimer.DelColorFader(Self);
  if (GlobalColorFaderTimer.Count=0) then
    begin
      GlobalColorFaderTimer.Free;
      GlobalColorFaderTimer:=nil;
    end;
  inherited;
end;

procedure TOmColorFader.ColorFaderTimerTick(Sender: TObject);
var aColor:TColor;
begin
  if (fState>0) then //fader ativo, calcula proxima cor (ignora ticks se State=0)
    begin
      if Assigned(fOnColorChange) then
        begin
          fR:=fR+fRIncr; fG:=fG+fGIncr; fB:=fB+fBIncr; //calcula proxima cor intermediaria
          aColor:=GetCurrentColor;
          fOnColorChange(Self,aColor);
        end;
      dec(fState);
      if (fState=0) then GlobalColorFaderTimer.UpdateEnabled; //verifica se timer global precisa ficar pulsando...
    end;
end;

//isso garante a cor certa no ultimo State, sem problemas de arredondamento
function TOmColorFader.GetCurrentColor: TColor;
begin
  if (fState>1) then Result:=RGB(Trunc(fR),Trunc(fG),Trunc(fB)) //cor intermediaria...
    else Result:=fFinalColor;                                   //se fader parado, sempre na cor final
end;

procedure TOmColorFader.SetColorToInitial;
begin
  fR:=GetRValue(fInitialColor);
  fG:=GetGValue(fInitialColor);
  fB:=GetBValue(fInitialColor);
end;

procedure TOmColorFader.CalcIncrementos;
var ri,gi,bi,rf,gf,bf:double;
begin
  ri:=GetRValue(fInitialColor);  gi:=GetGValue(fInitialColor); bi:=GetBValue(fInitialColor);
  rf:=GetRValue(fFinalColor);    gf:=GetGValue(fFinalColor);   bf:=GetBValue(fFinalColor);
  fRIncr:=(rf-ri)/fSteps;        fGIncr:=(gf-gi)/fSteps;       fBIncr:=(bf-bi)/fSteps;
end;

procedure TOmColorFader.SetFinalColor(const Value: TColor);
begin
  if fFinalColor<>Value then
    begin
      fFinalColor := Value;
      CalcIncrementos;
    end;
end;

procedure TOmColorFader.SetInitialColor(const Value: TColor);
begin
  if fInitialColor<>Value then
    begin
      fInitialColor := Value;
      CalcIncrementos;
    end;
end;

procedure TOmColorFader.Start;
begin
  fState:=fSteps;       //vai pro 1o passo
  SetColorToInitial;    //vai para cor inicial
  GlobalColorFaderTimer.Timer.Enabled:=TRUE; //starta timer global, just in case
end;

procedure TOmColorFader.SetSteps(const Value: integer);
begin
  if fSteps<>Value then
    begin
      if Value<1 then Raise Exception.Create('Steps tem que ser > 0');
      fSteps := Value;
      CalcIncrementos;
    end;
end;

function TOmColorFader.GetIsActive: boolean;
begin
  Result:=(fState>0);
end;

end.


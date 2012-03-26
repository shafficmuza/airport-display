unit AnimGlob; {Derivado de animate.pas - Só que usa um timer global}
{Fiz este componente para usar no ticker, sem ter que ficar criando um
 monte de timers. O timer global é destruido quando a contagem de TGTAnimateds
 for a zero. Para manter um timer permanente, criar um TGTAnimated no inicio
 e mante-lo ate o final do programa}
 
interface
uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, StdCtrls, ExtCtrls;

type
  //GTAnimated é um animated com timer global (1 só para todos os animateds
  TGTAnimated = class(TGraphicControl)
  private
    FBitMap : TBitmap;
    FFrameCount : integer;
    FFrame : Integer;
    FInterval : integer;
    FLoop : boolean;
    FReverse : boolean;
    FPlay : boolean;
    FTransparentColor : TColor;
    FOnChangeFrame : TNotifyEvent;
    procedure SetFrame(Value : Integer);
    procedure SetInterval(Value : integer);
    procedure SetBitMap(Value : TBitMap);
    procedure SetPlay(Onn : boolean);
    procedure SetTransparentColor(Value : TColor);
  protected
    procedure Paint; override;
    procedure TimeHit;   //chamado pelo timer global
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   PaintToCanvas(aCanvas:TCanvas);
    Procedure   Assign(Source:TPersistent); override;
    function    Clone:TGTAnimated;
    Procedure   SyncStart;
  published
    property Interval : integer read FInterval write SetInterval;
    {Note: FrameCount must precede Frame in order for initialization to be correct}
    property FrameCount : integer read FFrameCount write FFrameCount default 1;
    property Frame : Integer read FFrame write SetFrame;
    property BitMap : TBitMap read FBitMap write SetBitMap;
    property Play : boolean read FPlay write SetPlay;
    property Reverse: boolean read FReverse write FReverse;
    property Loop: boolean read FLoop write FLoop default True;
    property TransparentColor : TColor read FTransparentColor
             write SetTransparentColor default -1;
    property Height default 30;
    property Width default 30;
    property OnChangeFrame: TNotifyEvent read FOnChangeFrame
                            write FOnChangeFrame;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property Visible;
  end;

procedure Register;

implementation {--------------------------------}

const
  GlobalTickCount:integer=0;

{--------------- TGlobalAnimatedTimer.}
type
  TGlobalAnimatedTimer=Class
  private
    fTimer:TTimer;
    fList:TList;
    Procedure  GlobalTimeHit(Sender:TObject);
    function   GetCount:integer;
    function   GetInterval:integer;
    Procedure  SetInterval(value:integer);
  public
    Constructor Create;
    Destructor  Destroy; Override;
    Procedure   AddAnimated(aAnimated:TGTAnimated);
    Procedure   DelAnimated(aAnimated:TGTAnimated);

    Property    Count:integer    read GetCount;
    Property    Interval:integer read GetInterval write SetInterval;
  end;

const
  GlobalAnimatedTimer:TGlobalAnimatedTimer=nil;

Constructor TGlobalAnimatedTimer.Create;
begin
  inherited;
  fTimer:=TTimer.Create(nil);
  fTimer.Enabled:=FALSE;
  fTimer.Interval:=0;
  fTimer.OnTimer:=GlobalTimeHit;
  fList:=TList.Create;
end;

Destructor  TGlobalAnimatedTimer.Destroy;
begin
  fTimer.Free;
  fList.Free;
  inherited;
end;

Procedure   TGlobalAnimatedTimer.AddAnimated(aAnimated:TGTAnimated);
begin
  fList.Add(aAnimated);
end;

Procedure   TGlobalAnimatedTimer.DelAnimated(aAnimated:TGTAnimated);
begin
  fList.Remove(aAnimated);
end;

Procedure   TGlobalAnimatedTimer.GlobalTimeHit(Sender:TObject);
var i:integer;
begin
  inc(GlobalTickCount);
  for i:=0 to fList.Count-1 do
    TGTAnimated(fList.Items[i]).TimeHit;
end;

function   TGlobalAnimatedTimer.GetCount:integer;
begin Result:=fList.Count; end;

function   TGlobalAnimatedTimer.GetInterval:integer;
begin Result:=fTimer.Interval; end;

Procedure  TGlobalAnimatedTimer.SetInterval(value:integer);
begin
  if value<>fTimer.Interval then
    begin
      fTimer.Interval:=value;
      fTimer.Enabled:=(value<>0);
    end;
end;

{----------------- TGTAnimated.}
constructor TGTAnimated.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 30;
  Height := 30;
  FBitMap := TBitMap.Create;
  FrameCount := 1;
  ControlStyle := ControlStyle +[csOpaque];
  FLoop := True;
  FTransparentColor := -1;
  if not Assigned(GlobalAnimatedTimer) then GlobalAnimatedTimer:=TGlobalAnimatedTimer.Create;
  GlobalAnimatedTimer.AddAnimated(Self);
end;

destructor TGTAnimated.Destroy;
begin
  GlobalAnimatedTimer.DelAnimated(Self);
  if GlobalAnimatedTimer.Count=0 then
    begin
      GlobalAnimatedTimer.Free;
      GlobalAnimatedTimer:=nil;
    end;
  FBitMap.Free;
  inherited Destroy;
end;

procedure TGTAnimated.SetBitMap(Value : TBitMap);
begin
FBitMap.Assign(Value);
Height := FBitMap.Height;
if Height = 0 then Height := 30;  {so something will display}
end;

procedure TGTAnimated.SetInterval(Value : Integer);
begin
if Value<>fInterval  then
  begin
    GlobalAnimatedTimer.Interval:=Value; //o timer global tem sempre o ultimo intervalo setado (???)
    FInterval := Value;
  end;
end;

procedure TGTAnimated.SetPlay(Onn : boolean);
begin
  if Onn <> FPlay then
    FPlay := Onn;
end;

procedure TGTAnimated.SetFrame(Value : Integer);
var
  Temp : Integer;
begin
if Value < 0 then
  Temp := FFrameCount - 1
else
  Temp := Value Mod FFrameCount;
if Temp <> FFrame then
  begin
  FFrame := Temp;
  if Assigned(FOnChangeFrame) then FOnChangeFrame(Self);
  Invalidate;
  end;
end;

procedure TGTAnimated.SetTransparentColor(Value : TColor);
begin
if Value <> FTransparentColor then
  begin
  FTransparentColor := Value;
  Invalidate;
  end;
end;

Procedure TGTAnimated.Assign(Source:TPersistent);
begin
  if Source is TGTAnimated then
    begin
      Bitmap.Assign(TGTAnimated(Source).Bitmap);
      Interval:=TGTAnimated(Source).Interval;
      Height:=TGTAnimated(Source).Height;
      Width:=TGTAnimated(Source).Width;
      FrameCount:=TGTAnimated(Source).FrameCount;
      Frame:=TGTAnimated(Source).Frame;
      Play:=TGTAnimated(Source).Play;
      Reverse:=TGTAnimated(Source).Reverse;
      Loop:=TGTAnimated(Source).Loop;
      TransparentColor:=TGTAnimated(Source).TransparentColor;
    end
    else inherited;
end;

function  TGTAnimated.Clone:TGTAnimated;
begin
  Result:=TGTAnimated.Create(Owner);
  Result.Parent     := Parent;
  Result.Top        := Top;
  Result.Left       := Left;
  Result.Width      := Width;
  Result.Height     := Height;
  Result.Bitmap.Assign(Bitmap);
  Result.Interval   :=Interval;
  Result.FrameCount :=FrameCount;
  Result.Frame := Frame;
  Result.Reverse:=Reverse;
end;

//Começa a animar de tal maneira que todas as animacoes fiquem sincronizadas
Procedure   TGTAnimated.SyncStart;
begin
  Frame:=(GlobalTickCount mod FrameCount);
  Play:=TRUE;
end;

procedure TGTAnimated.TimeHit;

  procedure ChkStop;
  begin if not FLoop then FPlay := False; end;

begin
  if not fPlay then exit;
  if FReverse then
    begin
      Frame := Frame-1;
      if FFrame = 0 then ChkStop;
    end
    else begin
      Frame := Frame+1;
      if FFrame = FrameCount-1 then ChkStop;
    end;
end;

procedure TGTAnimated.Paint;
begin
  PaintToCanvas(Canvas);
end;

//adicionei para permitir Paint para um canvas arbitrário
procedure TGTAnimated.PaintToCanvas(aCanvas:TCanvas);
var
  ARect, BRect : TRect;
  X : Integer;
  Tmp : TBitMap;
begin
ARect := Rect(0,0,Width,Height);
if FBitMap.Height > 0 then
  begin
  X := Width*FFrame;
  BRect := Rect(X,0, X+Width, Height);
  if (FTransparentColor >= 0) and (FTransparentColor <= $7FFFFFFF) then
    begin    {draw on Tmp bitmap to eliminate flicker}
    Tmp := TBitmap.Create;
    Tmp.Height := FBitMap.Height;
    Tmp.Width := FBitMap.Width;
    Tmp.Canvas.Brush.Color := Color;
    Tmp.Canvas.BrushCopy(ARect, FBitmap, BRect, FTransparentColor);
    aCanvas.CopyRect(ARect, Tmp.Canvas, ARect);
    Tmp.Free;
    end
  else  {can draw direct}
    aCanvas.CopyRect(ARect, FBitmap.Canvas, BRect);
  end
else
  begin   {fill with something}
  aCanvas.Brush.Color := clWhite;
  aCanvas.FillRect(BoundsRect);
  end;
if csDesigning in ComponentState then
  begin    {to add visibility when designing}
  aCanvas.Pen.Style := psDash;
  aCanvas.Brush.Style := bsClear;
  aCanvas.Rectangle(0, 0, Width, Height);
  end;
end;

procedure Register;
begin
  RegisterComponents('Omar', [TGTAnimated]);
end;

end.

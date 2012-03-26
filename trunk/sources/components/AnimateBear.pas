unit AnimateBear; {Era animate.pas - mudei pois estava dando conflito de nomes}
{O 'bear' é pq este componente foi achado em www.pbear.com}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, StdCtrls, ExtCtrls;

type
  TAnimatedOrientation=(aoHORIZONTAL,aoVERTICAL);

  TAnimated = class(TGraphicControl)
  private
    FBitMap : TBitmap;
    FFrameCount : integer;
    FFrame : Integer;
    Timer : TTimer;
    FInterval : integer;
    FLoop : boolean;
    FReverse : boolean;
    FPlay : boolean;
    FTransparentColor : TColor;
    FOnChangeFrame : TNotifyEvent;
    fOrientation: TAnimatedOrientation; //orientation of BMP
    procedure SetFrame(Value : Integer);
    procedure SetInterval(Value : integer);
    procedure SetBitMap(Value : TBitMap);
    procedure SetPlay(Onn : boolean);
    procedure SetTransparentColor(Value : TColor);
  protected
    procedure Paint; override;
    procedure TimeHit(Sender : TObject);
    Procedure Assign(Source:TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   PaintToCanvas(aCanvas:TCanvas);
    function    Clone:TAnimated;
  published
    property Interval : integer read FInterval write SetInterval;
    {Note: FrameCount must precede Frame in order for initialization to be correct}
    property FrameCount : integer read FFrameCount write FFrameCount default 1;
    property Frame : Integer read FFrame write SetFrame;
    property BitMap : TBitMap read FBitMap write SetBitMap;
    property Play : boolean read FPlay write SetPlay;
    property Reverse: boolean read FReverse write FReverse;
    property Loop: boolean read FLoop write FLoop default True;
    property TransparentColor : TColor read FTransparentColor write SetTransparentColor default -1;
    Property Orientation:TAnimatedOrientation read fOrientation write fOrientation default aoHORIZONTAL; //Om: orientation of BMP

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

implementation

constructor TAnimated.Create(AOwner: TComponent);
begin
inherited Create(AOwner);
Width := 30;
Height := 30;
FBitMap := TBitMap.Create;
FrameCount := 1;
ControlStyle := ControlStyle +[csOpaque];
FLoop := True;
FTransparentColor := -1;
fOrientation:=aoHORIZONTAL; //orientation of BMP
end;

destructor TAnimated.Destroy;
begin
Timer.Free;
FBitMap.Free;
inherited Destroy;
end;

procedure TAnimated.SetBitMap(Value : TBitMap);
begin
  FBitMap.Assign(Value);
  //pela dimensao maior do BMP, ajusta orientacao
  if (FBitMap.Height>FBitMap.Width)  then
    begin
      fOrientation:=aoVERTICAL;
      Width:= FBitMap.Width;
      if Width=0 then Width:=30;
    end
    else begin
      fOrientation:=aoHORIZONTAL;
      Height := FBitMap.Height;
      if Height = 0 then Height := 30;  {so something will display}
    end;
end;

procedure TAnimated.SetInterval(Value : Integer);
begin
if Value <> FInterval then
  begin
  Timer.Free;
  Timer := Nil;
  if FPlay and (Value > 0) then
    begin
    Timer := TTimer.Create(Self);
    Timer.Interval := Value;
    Timer.OnTimer := TimeHit;
    end;
  FInterval := Value;
  end;
end;

procedure TAnimated.SetPlay(Onn : boolean);
begin
if Onn <> FPlay then
  begin
  FPlay := Onn;
  if not Onn then
    begin
    Timer.Free;
    Timer := Nil;
    end
  else if FInterval > 0 then
    begin
    Timer := TTimer.Create(Self);
    Timer.Interval := FInterval;
    Timer.OnTimer := TimeHit;
    end;
  end;
end;

procedure TAnimated.SetFrame(Value : Integer);
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

procedure TAnimated.SetTransparentColor(Value : TColor);
begin
if Value <> FTransparentColor then
  begin
  FTransparentColor := Value;
  Invalidate;
  end;
end;

Procedure TAnimated.Assign(Source:TPersistent);
begin
  if Source is TAnimated then
    begin
      Bitmap.Assign(TAnimated(Source).Bitmap);
      Interval:=TAnimated(Source).Interval;
      Height:=TAnimated(Source).Height;
      Width:=TAnimated(Source).Width;
      FrameCount:=TAnimated(Source).FrameCount;
      Frame:=TAnimated(Source).Frame;
      Play:=TAnimated(Source).Play;
      Reverse:=TAnimated(Source).Reverse;
      Loop:=TAnimated(Source).Loop;
      TransparentColor:=TAnimated(Source).TransparentColor;
    end
    else inherited;
end;

procedure TAnimated.TimeHit(Sender : TObject);
  procedure ChkStop;
  begin
  if not FLoop then
    begin
    FPlay := False;
    Timer.Free;
    Timer := Nil;
    end;
  end;

begin
if FReverse then
  begin
  Frame := Frame-1;
  if FFrame = 0 then ChkStop;
  end
else
  begin
  Frame := Frame+1;
  if FFrame = FrameCount-1 then ChkStop;
  end;
end;

procedure TAnimated.Paint;
begin
  PaintToCanvas(Canvas);
end;

function  TAnimated.Clone:TAnimated;
begin
  Result:=TAnimated.Create(Owner);
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

//adicionei para permitir Paint para um canvas arbitrário
procedure TAnimated.PaintToCanvas(aCanvas:TCanvas);
var
  ARect, BRect : TRect;
  X,Y : Integer;
  Tmp : TBitMap;
begin
ARect := Rect(0,0,Width,Height);
if (FBitMap.Height > 0) and (FBitMap.Width > 0) then
  begin
    case fOrientation of
      aoHORIZONTAL: begin X :=Width*FFrame; Y:=0;  end;
      aoVERTICAL:   begin X :=0; Y:=Height*FFrame; end;
    end;
    BRect := Rect(X,Y, X+Width,Y+Height);
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
      else aCanvas.CopyRect(ARect, FBitmap.Canvas, BRect); {can draw direct}
  end
  else begin   {fill with something}
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
  RegisterComponents('Omar', [TAnimated]);
end;

end.

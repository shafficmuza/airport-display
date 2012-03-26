Unit OmFlapLabel; {airport style Flap label}
{ (c)copr 2002 Omar F Reis <omar@tecepe.com.br> }

// Nota 18/4/02 - Para evitar ter que buscar o Caption (from e to) a cada transicao,
// o que tornava a coisa lenta eu salvei os index dos Caption (to e from).
// Se chegar no destino antes, ou se chegar em fIxTo e o
// CaptionTo nao estiver mais lá, faz nova procura. Isto
// pq novos itens podem estar sendo enfiados durante o flaps de um texto
// p/ outro. (embora isso seja pouco frequente)..
// O algoritmo para as transicoes funciona assim:
// 1) Quando ocorre uma alteracao do Caption (SetCaption):
//    - Cria FlapEntry p/ o novo caption (i.e. o BMP), caso ainda nao exista.
//    - Seta fCaption com o Value
//    - Seta fIxFrom - Index do BMP atual
//    - Seta fIxTo   - Index do proximo BMP na transicao
// 2) A cada tick do clock:
//    - Se flappando, faz uma transicao de estado (1 a 4)
//    - Se estado=4, prepara para a proxima transicao
//    Invalida o BMP e o controle. A renderizacao do fControlBMP é feita dentro do Paint (só se necessario)

// Historico:
//  Om: abr11: Evitei renderizacao durante carregamento das props do controle  


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Debug,
  extctrls;

var
  numFlapEntries:integer=0;
  totBMPs:integer=0;
  CountFlapping:integer=0;
  //vars de controle global dos flap labels
  bBuildingSlideShow:boolean=FALSE;      //se true, nao anda conforme o timer, e sim de acordo com SlideshowTick
  bStopFlappingIfFallingBehind:boolean=FALSE;
  
  bGradientBackground:boolean=true;  // nov07: Om: Apple style  bg nos flap labels

  bRenderizacaoCompleta:boolean=FALSE;   // controla se a cada estado da transicao o BMP é todo renderizado...
  // caso contrário, vai renderizando por cima do que já havia de correto, mantendo o que nao mudou e otimizando a renderizacao

  GlobalFlapEntryTag:integer=0;          //Local para salvar o Tag do FlapLabel sendo renderizado.
  // /vars..
  GlobalSubtextFrame:integer;            //usado para sincronizar os flaps dos subtexts

type
  TFlapLabel = class;

  TFlapGetBMPEvent=Procedure(Sender:TObject; var aBMP:TBitmap) of object;

  //Bitmap associado a um determinado texto do flap-flap (ex: 'SÃO PAULO' ou 'TAM')
  TEntryType=(etText,etBitmap);

  TFlapEntry=class
  private
    fParentLabel:TFlapLabel;  //parent desse entry. Usado para determinar as dimesoes
    fText: String;
    fBitmap: TBitmap;
    fBMPsz:integer;    //debug var
    fExternalBMP:boolean;
    fOnGetBMP: TFlapGetBMPEvent;
    fEntryType: TEntryType;

    procedure SetBitmap(const Value: TBitmap);
    procedure SetText(const Value: String);
    function  GetBitmap: TBitmap;
  public
    fLinhaCentral:boolean;
    Constructor Create(aParentLabel:TFlapLabel);
    Destructor  Destroy; override;
    Procedure   Render;
    Procedure   RenderTextToCanvas(aBackColor:TColor; aCanvas:TCanvas);
    Procedure   ClearBackground;

    Property    Bitmap:TBitmap            read GetBitmap  write SetBitmap;
    Property    Text:String               read fText      write SetText;
    Property    OnGetBMP:TFlapGetBMPEvent read fOnGetBMP  write fOnGetBMP;
    Property    EntryType:TEntryType      read fEntryType write fEntryType;
  end;

  TFlapBitmapList=class(TStringList) //lista de TFlapEntrys
  private
  public
    fGroupName:string;        //nome deste grupo. p.e. 'CIDADES'
    Constructor Create;
    Destructor  Destroy; override;
    Procedure   ClearBMPs;
    Procedure   AddSetEntryBMPFile(const Caption,FileName:String; aFlapLabel:TFlapLabel);
    procedure   AddSetEntryBMP(const aCaption:string; aBMP:TBitmap);
    Procedure   RebuildTextBMPs;
  end;

  //The flap-flap control
  TFlapLabel = class(TGraphicControl)
  private
    fBitmaps:TFlapBitmapList; //TFlapBitmapList (local or global)
    fCaption: String;
    fTransitionState:integer; //estado da transicao/

    fControlBitmap:TBitmap;   //BMP for double buffering
    fBackColor: TColor;
    fFont: TFont;
    fFontTop: integer;
    fGroupName: string;
    fIsFlapping: boolean;

    //fEntryFrom, fEntryTo:TFlapEntry;  //entries usandos na renderizacao do ControlBitmap
    fIxFrom,fIxTo:integer;            //controle

    fControlBMPValid:boolean;  //indicates if current fControlBitmap is valid
    fLinhaCentral: boolean;
    fSubtexts: TStringList;
    fbGoDirect: boolean;

    fSubtextTicks:integer;     //num de ticks que fica cada subtext (c/ tick = 50ms)
    fSubtextFrame:integer;     //var p/ sincronizacao dos subtexts
    fFlapIncrement:integer;    //incremento em fBitmaps.Objects[] para c/ flap (display mecanico=1)
    fUseBackColor2: boolean;   // 0 indica que nao esta usando cores alternadas
    fBackColor2: TColor;
    fReflexoNaPlaquinhaViradaPraCima: boolean;
     //ind se (no estado 3 da pintura) mostra só um rect cinza, como se fosse um reflexo
    //fRepaintRect:TRect;     //controle da parte alterada, para economizar tempo de renderizacao

    procedure SetCaption(const Value: String);
    procedure ClearBMPs;
    procedure SetBackColor(const Value: TColor);
    procedure SetFont(const Value: TFont);
    procedure SetFontTop(const Value: integer);
    procedure SetGroupName(const Value: string);
    procedure InvalidateControlBMP;
    procedure StartFlappingFrom(const aCaptionFrom: String);
    procedure SetLinhaCentral(const Value: boolean);
    procedure SetSubtexts(const Value: TStringList);
    procedure AvancaSubtextFrame;
    procedure GetFlapEntrys(var aEntryFrom, aEntryTo: TFlapEntry);
    procedure SetIxToForNextTransition;
    procedure SetBackColor2(const Value: TColor);
    procedure SetUseBackColor2(const Value: boolean);
  protected
    procedure FlapLabelTimerTick(Sender: TObject);
    procedure FallingBehind;
    procedure SubTextTick;
    procedure Loaded; override;
    procedure PaintControlBMP;
  public
    Constructor Create(aOwner:TComponent); override;
    Destructor  Destroy; override;
    Procedure   Paint;   override;
    function    Clone:TFlapLabel;
    procedure   RenderCaption;  //nov/03: obsoleto (?) renderizador antigo
    procedure   ForceRender;    //novo nov/03 força renderizacao, levando em conta cores alternadas
    Function    TemSubtextos:boolean;
    Function    GetCaptionEntry:TFlapEntry;

    Property    IsFlapping:boolean read fIsFlapping;
    Property    Bitmaps:TFlapBitmapList read fBitmaps;
    Property    bGoDirect:boolean read fbGoDirect write fbGoDirect default FALSE; //se bGoDirect, faz um flap direto pro destino (fast)
  published
    Property    Caption:String     read fCaption     write SetCaption;
    Property    Font:TFont         read fFont        write SetFont;
    Property    BackColor:TColor   read fBackColor   write SetBackColor;
    Property    FontTop:integer    read fFontTop     write SetFontTop;
    Property    GroupName:string   read fGroupName   write SetGroupName; //if '' use local BMP list. If <>'', use global BMP list
    Property    bLinhaCentral:boolean read fLinhaCentral  write SetLinhaCentral;
    Property    Subtexts:TStringList  read fSubtexts      write SetSubtexts;
    Property    SubtextTicks:integer  read fSubtextTicks  write fSubtextTicks;                //ticks entre a mostrada de cada subtexto (in ticks of 50ms)
    Property    FlapIncrement:integer read fFlapIncrement write fFlapIncrement default 1;     //quantos BMPs avança em c/ flap (no disp mecanico seria 1..)
    // suporte a linhas de cores alternadas adicionado em nov/03
    Property    ComReflexo:boolean    read fReflexoNaPlaquinhaViradaPraCima write fReflexoNaPlaquinhaViradaPraCima default FALSE;
    Property    UseBackColor2:boolean read fUseBackColor2     write SetUseBackColor2   default FALSE; //indica que é linha impar
    Property    BackColor2:TColor     read fBackColor2        write SetBackColor2;                  //pinta fundo de linhas impares de cor alternativa
  end;

Procedure LoadFlapBitmapFile(const aGroupname,aCaption,aFilename:String; aFlapLabel:TFlapLabel);

Procedure FlapLabels_ClearBMPs;
Procedure FlapLabels_ClearTextBMPs;

Procedure FlapLabels_RebuildTextBMPs;
procedure Form2BMPCapture(aForm:TForm ; aBMP:TBitmap);

//Slide show making procs
Procedure FlapLabels_SlideshowTick;
Procedure ForcaRenderizacaoDosFlaps;
Procedure EnableGlobalFlapLabelTimer(bEnabled:boolean);

procedure Register;

implementation

uses
  OmFunctionProfiler;

type
  TGlobalFlapLabelTimer=Class //timer global dos FlapLabels
  private
    fTimer:TTimer;
    fList:TList;
    fLastTickCount:dword;
    Procedure  GlobalTimeHit(Sender:TObject);
    function   GetCount:integer;
    function   GetInterval:cardinal;
    Procedure  SetInterval(value:cardinal);
    procedure  ClearEntryFromEntryTo;
    procedure  DoFlapTheLabels;
  public
    Constructor Create;
    Destructor  Destroy; Override;

    Property    Timer:TTimer read fTimer;
    Procedure   AddFlapLabel(aFlapLabel:TFlapLabel);
    Procedure   DelFlapLabel(aFlapLabel:TFlapLabel);
    Procedure   UpdateEnabled;
    Procedure   ForcaRenderizacaoDosFlaps;

    Property    Count:integer    read GetCount;
    Property    Interval:cardinal read GetInterval write SetInterval;
  end;

const
  GlobalFlapLabelTimer:TGlobalFlapLabelTimer=nil;

var
  GlobalBMPLists:TStringList;  //list of TFlapBitmapLists globais

{ fns globais }

Procedure ForcaRenderizacaoDosFlaps;
begin
  if Assigned(GlobalFlapLabelTimer) then
    GlobalFlapLabelTimer.ForcaRenderizacaoDosFlaps;
end;

procedure Register;
begin
  RegisterComponents('Omar', [TFlapLabel]);
end;

procedure Form2BMPCapture(aForm:TForm ; aBMP:TBitmap);
var aCanvas:TCanvas; pt:TPoint; S,D:TRect; w,h:integer;
begin
  aCanvas:=aForm.Canvas;
  w:=aForm.ClientWidth;
  h:=aForm.ClientHeight;
  aBMP.Width:=w;
  aBMP.Height:=h;
  pt.x:=0;
  pt.y:=0;
  aForm.ClientToScreen(pt);
  D:=Rect(0,0,w,h);
  aBMP.Canvas.CopyRect(D,aForm.Canvas,D);
end;

Procedure FlapLabels_SlideshowTick;
begin
  GlobalFlapLabelTimer.DoFlapTheLabels;
end;

Procedure InitGlobalBMPLists;
begin
  GlobalBMPLists:=TStringList.Create;  //shared BMP lists (shared by groups)
  GlobalBMPLists.Duplicates:=dupIgnore;
  GlobalBMPLists.Sorted:=TRUE;
end;

Function FindAddGlobalBMPList(const aGroupName:String):TFlapBitmapList;
var ix:integer;
begin
  if GlobalBMPLists.Find(aGroupName,ix) then
    Result:=TFlapBitmapList(GlobalBMPLists.Objects[ix])
    else begin
      Result:=TFlapBitmapList.Create;
      Result.fGroupName:=aGroupName;
      GlobalBMPLists.AddObject(aGroupName,Result);
    end;
end;

Procedure FinishGlobalBMPLists;
var i:integer;
begin
  for i:=0 to GlobalBMPLists.Count-1 do
    TFlapBitmapList(GlobalBMPLists.Objects[i]).Free;
  GlobalBMPLists.Free;
end;

Procedure LoadFlapBitmapFile(const aGroupname, aCaption, aFilename:String;aFlapLabel:TFlapLabel);
var aList:TFlapBitmapList;
begin
  aList := FindAddGlobalBMPList(aGroupname);
  aList.AddSetEntryBMPFile(aCaption,aFilename,aFlapLabel);
end;

Procedure FlapLabels_ClearBMPs;
var i:integer; aList:TFlapBitmapList;
begin
  for i:=0 to GlobalBMPLists.Count-1 do
    begin
      aList:=TFlapBitmapList(GlobalBMPLists.Objects[i]);
      aList.ClearBMPs;
    end;
  GlobalFlapLabelTimer.ClearEntryFromEntryTo; //invalida entrys apontados para o list
end;

Procedure FlapLabels_ClearTextBMPs;
var i:integer; aList:TFlapBitmapList;
begin
  for i:=0 to GlobalBMPLists.Count-1 do
    begin
      aList:=TFlapBitmapList(GlobalBMPLists.Objects[i]);
      if aList.fGroupName='CIDADES' then
        aList.ClearBMPs;
    end;
  GlobalFlapLabelTimer.ClearEntryFromEntryTo; //invalida entrys apontados para o list
end;

Procedure FlapLabels_RebuildTextBMPs;
var i:integer; aList:TFlapBitmapList;
begin
  for i:=0 to GlobalBMPLists.Count-1 do
    begin
      aList:=TFlapBitmapList(GlobalBMPLists.Objects[i]);
      aList.RebuildTextBMPs;
    end;
end;

Procedure EnableGlobalFlapLabelTimer(bEnabled:boolean);
begin
  GlobalFlapLabelTimer.fTimer.Enabled:=bEnabled;
end;

//retorna cor mais clarinha (c)copr 1988-2005 Enfoque
function CorMaisClara(aColor:TColor; k:double ):TColor; //ex: k=0.09; --> cte de clareamento 9%
var R,G,B:integer;
begin
  r :=  aColor and $0000ff;
  g := (aColor and $00ff00) shr 8;
  b := (aColor and $ff0000) shr 16;


  if (r<250) then r:=r+Trunc((255-r)*k);    //aumenta cada componente, clareando
  if (g<250) then g:=g+Trunc((255-g)*k);    //mantendo a saturação
  if (b<250) then b:=b+Trunc((255-b)*k);
  Result:=r+256*(g+256*b);
end;

function CorMaisEscura(aColor:TColor; k:double ):TColor; //ex: k=0.09; --> cte de escurecimento 9%
var R,G,B:integer;
begin
  r :=  aColor and $0000ff;
  g := (aColor and $00ff00) shr 8;
  b := (aColor and $ff0000) shr 16;

  if (r>10) then r:=r-Trunc(r*k);    //aumenta cada componente, clareando
  if (g>10) then g:=g-Trunc(g*k);    //mantendo a saturação
  if (b>10) then b:=b-Trunc(b*k);
  Result:=r+256*(g+256*b);
end;

// GradientFill()     (c)copr 1988-205 Enfoque
Procedure GradientFill(Canvas:TCanvas;Const Rect:TRect;TopColor,BottomColor:TColor;Horizontal:Boolean);
Var Size,Steps,t,y:Integer; Trgb,Drgb:Array[0..2] of Single; tmpBrush:HBRUSH; DC:HDC; k:single; C:ColorRef;
Begin
  if Horizontal then Size:=Rect.Right-Rect.Left
    else Size:=Rect.Bottom-Rect.Top;
  Steps:=Size;
  if Steps>256 then Steps:=256;
  if Steps=0 then exit;

  Trgb[0]:=GetRValue(TopColor);
  Trgb[1]:=GetGValue(TopColor);
  Trgb[2]:=GetBValue(TopColor);
  Drgb[0]:=GetRValue(BottomColor)-Trgb[0];
  Drgb[1]:=GetGValue(BottomColor)-Trgb[1];
  Drgb[2]:=GetBValue(BottomColor)-Trgb[2];
  DC:=Canvas.Handle;
  for t:=0 to Steps-1 do
  Begin
    k:=t/(Steps-1);
    C:=RGB(Round(Trgb[0]+Drgb[0]*k),Round(Trgb[1]+Drgb[1]*k),Round(Trgb[2]+Drgb[2]*k));
    tmpBrush:=SelectObject(DC,CreateSolidBrush(C));
    if Horizontal then
    begin
      y:=Rect.Right-MulDiv(t,Size,Steps);
      PatBlt(DC,y,Rect.Top+1,Rect.Right-MulDiv(t+1,Size,Steps)-y,Rect.Bottom-Rect.Top-2,PATCOPY); //jan07 - alterei pois estava pintando 1 pix a mais
    end
    else begin
      y:=Rect.Bottom-MulDiv(t,Size,Steps);
      PatBlt(DC,Rect.Left,y,Rect.Right-Rect.Left,Rect.Bottom-MulDiv(t+1,Size,Steps)-y,PATCOPY);
    end;
    DeleteObject(SelectObject(DC,tmpBrush));
  end;
end;


{ TGlobalFlapLabelTimer }
Constructor TGlobalFlapLabelTimer.Create;
begin
  inherited;
  fTimer:=TTimer.Create(nil);
  fTimer.Enabled:=FALSE;
  fTimer.Interval:=50;
  fTimer.OnTimer:=GlobalTimeHit;
  fList:=TList.Create;
  fLastTickCount:=GetTickCount;
end;

Destructor  TGlobalFlapLabelTimer.Destroy;
begin
  fTimer.Free;
  fList.Free;
  inherited;
end;

Procedure   TGlobalFlapLabelTimer.AddFlapLabel(aFlapLabel:TFlapLabel);
begin
  fList.Add(aFlapLabel);
end;

Procedure TGlobalFlapLabelTimer.ForcaRenderizacaoDosFlaps;
var i:integer; aFlapLabel:TFlapLabel;
begin
  for i:=0 to fList.Count-1 do
    begin
      aFlapLabel:=TFlapLabel(fList.Items[i]);
      aFlapLabel.RenderCaption;
    end;
end;

Procedure   TGlobalFlapLabelTimer.ClearEntryFromEntryTo;
var i:integer; aFlapLabel:TFlapLabel;
begin
  for i:=0 to fList.Count-1 do
    begin
      aFlapLabel:=TFlapLabel(fList.Items[i]);
      //aFlapLabel.fEntryFrom:=nil;
      //aFlapLabel.fEntryTo:=nil;
      aFlapLabel.fIxFrom:=-1; //NF (New flap strategy...)
      aFlapLabel.fIxTo:=-1;
    end;
end;

Procedure   TGlobalFlapLabelTimer.DelFlapLabel(aFlapLabel:TFlapLabel);
begin
  fList.Remove(aFlapLabel);
end;

//esse é o handler do ticker global
Procedure   TGlobalFlapLabelTimer.DoFlapTheLabels;
var i:integer; aFlapLabel:TFlapLabel; bFallingBehind:boolean; ElapsedTime,T:dword;
begin
  T:=GetTickCount;
  ElapsedTime:=T-fLastTickCount;
  //MostraIntVar(1,ElapsedTime);
  if bBuildingSlideShow then bFallingBehind:=FALSE
    else bFallingBehind:=(ElapsedTime)>(4*Interval); //falling bad behind timer Interval, cut the flapping shit..
  fLastTickCount:=T;
  CountFlapping:=0;
  inc(GlobalSubtextFrame);
  for i:=0 to fList.Count-1 do
    begin
      aFlapLabel:=TFlapLabel(fList.Items[i]);
      if aFlapLabel.IsFlapping then
        begin
          inc(CountFlapping);
          if bFallingBehind and bStopFlappingIfFallingBehind then aFlapLabel.FallingBehind
            else aFlapLabel.FlapLabelTimerTick(Self);
        end
        else aFlapLabel.SubTextTick;  //ve se tem subtext pra rodar
      aFlapLabel.AvancaSubtextFrame;
    end;
end;

Procedure   TGlobalFlapLabelTimer.GlobalTimeHit(Sender:TObject);
begin
  if not bBuildingSlideShow then DoFlapTheLabels;
end;

function   TGlobalFlapLabelTimer.GetCount:integer;
begin Result:=fList.Count; end;

procedure TGlobalFlapLabelTimer.UpdateEnabled;
var i:integer; bEnabled:boolean;
begin
  bEnabled:=FALSE;
  for i:=0 to fList.Count-1 do if TFlapLabel(fList.Items[i]).IsFlapping then
    begin
      bEnabled:=TRUE;
      break;
    end;
  fTimer.Enabled:=bEnabled;
end;

function TGlobalFlapLabelTimer.GetInterval: cardinal;
begin
  Result:=fTimer.Interval;
end;

procedure TGlobalFlapLabelTimer.SetInterval(value: cardinal);
begin
  if (value<>fTimer.Interval) then
    begin
      fTimer.Interval:=value;
      fTimer.Enabled:=(value<>0);
    end;
end;

{ TFlapEntry }

const NumFlapEntrys:integer=0; //teste

constructor TFlapEntry.Create(aParentLabel: TFlapLabel);
begin
  inherited Create;
  fEntryType:=etText;  //default=tipo texto
  fParentLabel:=aParentLabel;
  fText:='';
  fBitmap:= TBitmap.Create;
  //TODO: acertar pixel format ?
  fBMPsz:=0;
  inc(numFlapEntries);
  fLinhaCentral:=TRUE;
  fExternalBMP:=FALSE;
  fOnGetBMP:=nil;
  inc(NumFlapEntrys); //teste
end;

destructor TFlapEntry.Destroy;
begin
  dec(numFlapEntries);
  dec(totBMPs,fBMPsz);
  fBitmap.Free;
  inherited;
end;

procedure TFlapEntry.ClearBackground;
var W,H,aTop:integer;
begin
  if Assigned(fParentLabel) then
    begin
      fBitmap.Canvas.Brush.Color:=fParentLabel.BackColor;
      fBitmap.Canvas.Pen.Color:=fParentLabel.BackColor;
    end;
  fBitmap.Canvas.Rectangle(0,0,fBitmap.Width,fBitmap.Height);
end;

procedure TFlapEntry.Render;
var W,H,aTop:integer; aBackColor,aSaveColor:TColor; aRect:TRect;
begin
  W:=0; H:=0; aTop:=0;
  aBackColor:=clBlack;
  if Assigned(fParentLabel) then
    begin
      aBackColor:=fParentLabel.BackColor;
      fBitmap.Canvas.Brush.Color:=aBackColor;
      fBitmap.Canvas.Pen.Color  :=aBackColor;
      W:= fParentLabel.Width;
      H:= fParentLabel.Height;
      aTop:=fParentLabel.fFontTop;
      fBitmap.Canvas.Font.Assign(fParentLabel.Font);
    end;
  fBitmap.Width  :=W;
  fBitmap.Height :=H;

  fBMPsz         :=W*H*3;
  inc(totBMPs,fBMPsz);
  //fBitmap.Canvas.Rectangle(0,0,fBitmap.Width,fBitmap.Height);
  if bGradientBackground then
    begin
      GradientFill(fBitmap.Canvas,
        Rect(0,0,W,H-1),
        {TopColor=}    aBackColor,
        {BottomColor=} CorMaisClara(aBackColor,{k=}0.09 ),
        {Horizontal=}  false );
    end
    else fBitmap.Canvas.Rectangle(0,0,W+1,H-1);
  fBitmap.Canvas.Brush.Style:=bsClear;

  //fev08: teste: passeia desenhar a letra duas vezes
  aSaveColor:=fBitmap.Canvas.Font.Color;
  fBitmap.Canvas.Font.Color:=CorMaisEscura(fBitmap.Canvas.Font.Color, {k=}0.09 );
  fBitmap.Canvas.TextOut(2,aTop,fText); //escreve caption
  //Teste. Meia letra de outra cor....
  fBitmap.Canvas.Font.Color:=aSaveColor; //restaura cor original
  aRect:=Rect( 0, aTop, W, aTop+fBitmap.Canvas.TextHeight('M') div 2 ); //só metade
  fBitmap.Canvas.TextRect(aRect,2,aTop,fText);

  fBitmap.Canvas.Brush.Style:=bsSolid;
  H:=H div 2;
  if fLinhaCentral then
    begin
      fBitmap.Canvas.MoveTo(0,H);   //desenha linha central
      fBitmap.Canvas.LineTo(W,H);
    end;
end;

procedure TFlapEntry.RenderTextToCanvas(aBackColor: TColor; aCanvas: TCanvas);
var W,H,aTop:integer; aSaveColor:TColor; aRect:TRect;
begin
  if (fEntryType=etText) then
    begin
      W:=0; H:=0; aTop:=0;
      if Assigned(fParentLabel) then
        begin
          aCanvas.Brush.Color:=aBackColor;
          aCanvas.Pen.Color:=aBackColor;
          aCanvas.Pen.Style:=psSolid;
          W:=fParentLabel.Width;
          H:=fParentLabel.Height;
          aTop:=fParentLabel.fFontTop;
          aCanvas.Font.Assign(fParentLabel.Font);
        end;

      if bGradientBackground then
        begin
          GradientFill(aCanvas,
            Rect(0,0,W,H),
            {TopColor=}    aBackColor,
            {BottomColor=} CorMaisClara(aBackColor, {k=}0.09),
            {Horizontal=} false );
        end
        else aCanvas.Rectangle(0,0,W+1,H+1);

      aCanvas.Brush.Style:=bsClear;
      //fev08: teste: passeia desenhar a letra duas vezes
      aSaveColor:=aCanvas.Font.Color;
      aCanvas.Font.Color:=CorMaisEscura(aCanvas.Font.Color, {k=}0.09);
      aCanvas.TextOut(2,aTop,fText);
      //Teste. Meia letra de outra cor....
      aCanvas.Font.Color:=aSaveColor; //restaura cor orig
      aRect:=Rect( 0, aTop, W, aTop+aCanvas.TextHeight('M') div 2 );
      aCanvas.TextRect(aRect,2,aTop,fText);

      aCanvas.Brush.Style:=bsSolid; //retorna

      H:=H div 2;
      if fLinhaCentral then
        begin
          aCanvas.MoveTo(0,H);   //desenha linha central
          aCanvas.LineTo(W,H);
        end;
    end;
end;

procedure TFlapEntry.SetBitmap(const Value: TBitmap);
begin
  fBitmap.Assign(Value);
  fExternalBMP:=TRUE;
end;

procedure TFlapEntry.SetText(const Value: String);
begin
  if (fText<>Value) or fBitmap.Empty then
    begin
      fText := Value;
      if not fExternalBMP then
        Render; //Renderiza bmp padrão se nao for BMP externo
    end;
end;

function TFlapEntry.GetBitmap: TBitmap;
begin
  if Assigned(fOnGetBMP) then fOnGetBMP(Self,fBitmap);
  Result:=fBitmap;
end;

{ TFlapBitmapList }

constructor TFlapBitmapList.Create; //Lista de FlapEntrys (pode ser local ou global, dependendo do GroupName )
begin
  inherited;
  Duplicates:=dupIgnore;
  Sorted:=TRUE;
  fGroupName:=''; //=GroupName
end;

destructor TFlapBitmapList.Destroy;
begin
  ClearBMPs;
  inherited;
end;

procedure TFlapBitmapList.ClearBMPs;
var i:integer;
begin
  for i:=0 to Count-1 do
    TFlapEntry(Objects[i]).Free;
  Clear;
end;

procedure TFlapBitmapList.AddSetEntryBMP(const aCaption:string; aBMP:TBitmap);
var aEntry:TFlapEntry; ix:integer;
begin
  if Find(aCaption,ix) then
    aEntry:=TFlapEntry(Objects[ix])
    else begin
      aEntry:=TFlapEntry.Create(nil);
      aEntry.Text:=aCaption;
      AddObject(aCaption,aEntry);
    end;
  aEntry.Bitmap:=aBMP;
end;

procedure TFlapBitmapList.AddSetEntryBMPFile(const Caption, FileName: String; aFlapLabel:TFlapLabel);
var aBMP:TBitmap; aEntry:TFlapEntry; ix:integer;
begin
  if Find(Caption,ix) then
    aEntry:=TFlapEntry(Objects[ix])
    else begin
      aEntry:=TFlapEntry.Create(aFlapLabel); //cria usando flapLabel passado como parent. Isso cria bmp padrão certo
      aEntry.Text:=Caption;        //isso cria bmp default
      aEntry.EntryType:=etBitmap;  //tipo bmp
      AddObject(Caption,aEntry);
    end;
  aBMP:=TBitmap.Create;
  try
    try
      aBMP.LoadFromFile(FileName);
      if (aBMP.Width>0) then          //teste
        aEntry.Bitmap:=aBMP;          //aqui só copia se LoadFromFile tiver sucesso
    except
      // MostraBmpVar(1,aEntry.Bitmap.Handle);  
      MessageBeep(0); //bipa, mas nao pára.
    end;
  finally
    aBMP.Free;
  end;
end;

procedure TFlapBitmapList.RebuildTextBMPs; //reconstroi os entrys da lista (p.e. após mudança do Fonte)
var i:integer; aEntry:TFlapEntry;
begin
  for i:=0 to Count-1 do
    begin
      aEntry:=TFlapEntry(Objects[i]);
      if not aEntry.fExternalBMP then  //nao limpa os BMPs cutomizados pelo usr
        begin
          aEntry.ClearBackground;
          aEntry.Render;
        end;
    end;
end;

{ TFlapLabel }

constructor TFlapLabel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  ControlStyle := ControlStyle +[csOpaque];
  Width := 30;
  Height := 30;

  fCaption:=' ';
  fBitmaps:=TFlapBitmapList.Create; //começa usando lista local de BMPs (associada a fGroupName='')
  fGroupName:='';                   //=none=usa lista local

  fTransitionState:=0;

  fFont:=TFont.Create;
  fFont.Name:='Arial';
  fFont.Color:=clWhite;
  fFont.Size:=20;

  fFontTop:=-3;

  fBackColor:=clBlack;
  fReflexoNaPlaquinhaViradaPraCima:=FALSE;  
  fUseBackColor2:=FALSE;              // default (FALSE) = usa fBackColor pra tudo
  fBackColor2:=clBlack;

  fControlBitmap:=TBitmap.Create;

  fIsFlapping:=FALSE;  //if fIsFlapping, label receives global timer ticks (and thus flaps)
  //fEntryFrom:=nil;
  //fEntryTo:=nil;
  fIxFrom:=-1; //NF
  fIxTo:=-1;
  
  fControlBMPValid:=FALSE;
  fLinhaCentral:=TRUE;
  fbGoDirect:=FALSE;

  fSubtexts:=TStringList.Create;
  fSubtextTicks:=0;
  fSubtextFrame:=0;
  fFlapIncrement:=1;

  if not Assigned(GlobalFlapLabelTimer) then GlobalFlapLabelTimer:=TGlobalFlapLabelTimer.Create;
  GlobalFlapLabelTimer.AddFlapLabel(Self); //adiciona ao timer global
end;

destructor TFlapLabel.Destroy;
begin
  GlobalFlapLabelTimer.DelFlapLabel(Self);
  if (GlobalFlapLabelTimer.Count=0) then
    begin
      GlobalFlapLabelTimer.Free;
      GlobalFlapLabelTimer:=nil;
    end;
  if (fGroupName='') then //desaloca lista, se local
    begin
      ClearBMPs;
      fBitmaps.Free;
    end;
  fControlBitmap.Free;
  fFont.Free;
  fSubtexts.Free;
  inherited;
end;

procedure TFlapLabel.ClearBMPs;
var i:integer;
begin
  //if (fGroupName='') then
  for i:=0 to fBitmaps.Count-1 do
    TFlapEntry(fBitmaps.Objects[i]).Free;
  fBitmaps.Clear;
end;

//força a renderizacao do caption atual
procedure TFlapLabel.RenderCaption;
var ix:integer; aEntry:TFlapEntry;
begin
  if not Visible then exit; //teste
  if fUseBackColor2 then ForceRender  //gambiarra p/ renderizar com BackColor2 (cores alternadas)
    else begin
      if fBitmaps.Find(fCaption,ix) then //já tem o esse ?
        begin
          aEntry:=TFlapEntry(fBitmaps.Objects[ix]);
        end
        else begin  //nao tem, cria novo BMP para este Caption
          aEntry:=TFlapEntry.Create(Self);
          aEntry.fLinhaCentral:=fLinhaCentral;
          aEntry.Text:=fCaption;     //this builds the BMP
          fBitmaps.AddObject(fCaption,aEntry);
        end;
      //fRepaintRect:=Rect(0,0,Width,Height);
      fControlBitmap.Height:=Height;
      fControlBitmap.Width:=Width;
      GlobalFlapEntryTag:=Tag;
      fControlBitmap.Canvas.Draw(0,0,aEntry.Bitmap); //poe o novo no fundo todo
      fControlBMPValid:=TRUE; //valida o BMP produzido
      fIxTo:=-1;              //pára flappagem, just in case
      Invalidate;             //redesenha a coisa
    end;
end;

procedure TFlapLabel.ForceRender;
var R,RT:TRect; H2,H4,iFrom,iTo:integer; aEntryFrom,aEntryTo:TFlapEntry; aCanvas:TCanvas;
begin
  if (csLoading	 in ComponentState) then exit;     // abr11: do not render while loading...

  GetFlapEntrys(aEntryFrom,aEntryTo); //according do fIxFrom and fIxTo
  aCanvas:=fControlBitmap.Canvas;

  H2:=Height div 2; //valores usados com frequencia...
  H4:=Height div 4;

  //Nota: 18/4/02- Os CopyRect comentados abaixo foram removidos para otimizar.
  //Como ficou, somente as partes modificadas do BMP de um estado par outro sao renderizadas

  if Assigned(aEntryTo) and (aEntryTo.EntryType=etText) then //== 100% novo
     begin
       if fUseBackColor2 then
         aEntryTo.RenderTextToCanvas({aBackColor=} fBackColor2, aCanvas) //render bmp with alternate color
         else aEntryTo.RenderTextToCanvas({aBackColor=} fBackColor, aCanvas);
     end;
end;

procedure TFlapLabel.SetCaption(const Value: String);
var ix,ixa:integer; aEntry:TFlapEntry; aCaptionFrom:String;
begin
  if (fCaption<>value) then
    begin
      aCaptionFrom:=fCaption; //salva caption anterior, para iniciar as transicoes
      fCaption := Value;      //set target caption
      //
      if (not (csReading in ComponentState))  then
        begin
          if not fBitmaps.Find(fCaption,ix) then //já tem o esse ?
            begin     //nao tem, cria novo BMP para este Caption
              aEntry:=TFlapEntry.Create(Self);
              aEntry.fLinhaCentral:=fLinhaCentral;
              aEntry.Text:=fCaption;                   //this builds the BMP
              ix:=fBitmaps.AddObject(fCaption,aEntry);
            end;
          //ix aponta o target da flappagem
          if fbGoDirect then //..começa a flapar um antes do target atual (Isso faz um flap rápido)
            begin
              ixa:=ix-1;
              if ixa<0 then ixa:=fBitmaps.Count-1;  //ix tem o novo caption, pega o anterior  ..
              aCaptionFrom:=fBitmaps.Strings[ixa];  //.. ao novo em ixa. Deste modo o flap label dá so um flap
            end;
          StartFlappingFrom(aCaptionFrom);          //inicia a transicoes no caption anterior para chegar ao atual..
          GlobalFlapLabelTimer.Timer.Enabled:=TRUE; //starta timer global, just in case
        end;
    end;
end;

procedure TFlapLabel.InvalidateControlBMP;
begin
  fControlBMPValid:=FALSE;
end;

// Aqui tem duas situacoes:
// 1> fIxTo=-1 --> Nao esta flappando (está parado).
//    Retorna aEntryTo apontado para fCaption e fTransitionState=4
// 2> fIxTo>=0 --> Retorna aEntryFrom e aEntryTo, as requested
procedure TFlapLabel.GetFlapEntrys(var aEntryFrom,aEntryTo:TFlapEntry);
var C,ix:integer;
begin
  GlobalFlapEntryTag:=Tag;
  C:=fBitmaps.Count;
  if (fIxFrom>=0) and (fIxFrom<C) then aEntryFrom:=TFlapEntry(fBitmaps.Objects[fIxFrom])
    else aEntryFrom:=nil;
  if (fIxTo>=0) and (fIxTo<C) then
    aEntryTo:=TFlapEntry(fBitmaps.Objects[fIxTo]) //se fIxTo valido, retorna
    else begin    //se fIxTo=-1, nao está flappando. Está parado em fCaption --> retorna o entry de fCaption
      if fBitmaps.Find(fCaption,ix) then //mas tem que existir previamente, né ?
        begin
          aEntryTo:=TFlapEntry(fBitmaps.Objects[ix]);
          fTransitionState:=4; //sinaliza que transicoes paradas..
        end
        else aEntryTo:=nil;    //estranho... Isso nao deveria acontecer..
    end;
end;

// na verdade, só pinta o retangulo de uma cor....
procedure PintaReflexo(aRect:TRect; aCanvas:TCanvas; aColor:TColor);
begin
  aCanvas.Brush.Color:=aColor;
  aCanvas.Pen.Style:=psClear;
  aCanvas.Rectangle(aRect);
end;

procedure TFlapLabel.PaintControlBMP;
var R,RT:TRect; H2,H4,iFrom,iTo:integer; aEntryFrom,aEntryTo:TFlapEntry; aCanvas:TCanvas;

  Procedure DesenhaMoldura(aH:integer); // no range de alturas (H2..aH) - H2 é o centro
  begin
    with aCanvas do
    begin
      Pen.Color:=clGray;
      MoveTo(0,H2); LineTo(0,aH); LineTo(Width-1,aH); LineTo(Width-1,H2);
    end;
  end;

begin {PaintControlBMP}
  GetFlapEntrys(aEntryFrom,aEntryTo); //according do fIxFrom and fIxTo
  fControlBitmap.Width:=Width;        //set correct BMP size
  fControlBitmap.Height:=Height;
  aCanvas:=fControlBitmap.Canvas;

  H2:=Height div 2; //valores usados com frequencia... altura/2
  H4:=Height div 4; // e altura/4

  //Nota: 18/4/02- Os CopyRect comentados abaixo foram removidos para otimizar.
  //Como ficou, somente as partes modificadas do BMP de um estado par outro sao renderizadas

  case fTransitionState of
    0: begin
         DesenhaMoldura(0);    //estado 0 - Só desenha a moldura na metade de cima (do anterior)
         //fRepaintRect:=Rect(0,0,Width,Height);
       end;
    1: if Assigned(aEntryFrom) and Assigned(aEntryTo) then //== 1/4 do novo no topo
       begin
         R:=Rect(0,0,Width,H4);                          //poe no 1/4 do novo no topo
         //fRepaintRect:=Rect(0,0,Width,H2);
         aCanvas.CopyRect(R,aEntryTo.Bitmap.Canvas,R);   //na metade de baixo
         if bRenderizacaoCompleta then
           begin
             R:=Rect(0,0,Width,H2);                            //poe a metade de cima do velho..
             RT:=Rect(0,H4,Width,H2);                          //no 1/4 acima da metade
             aCanvas.CopyRect(RT,aEntryFrom.Bitmap.Canvas,R);
             R:=Rect(0,H2,Width,Height);                       //poe a metade de baixo do velho..
             aCanvas.CopyRect(R,aEntryFrom.Bitmap.Canvas,R);   //na metade de baixo
           end;
         DesenhaMoldura(H4);
       end;
    2: if Assigned(aEntryFrom) and Assigned(aEntryTo) then //== novo e velho 1/2 a 1/2
       begin
         R:=Rect(0,H4,Width,H2);                           //na metade de cima poe o novo
         aCanvas.CopyRect(R,aEntryTo.Bitmap.Canvas,R);
         //fRepaintRect:=Rect(0,H4,Width,H2);
         if bRenderizacaoCompleta then
           begin
             R:=Rect(0,H2,Width,Height);                   //na metade de baixo poe o velho
             aCanvas.CopyRect(R,aEntryFrom.Bitmap.Canvas,R);
           end;
         DesenhaMoldura(H2);
       end;
    3: if Assigned(aEntryFrom) and Assigned(aEntryTo) then //== 1/4 do velho em baixo
       begin
         if bRenderizacaoCompleta then
           begin
             R:=Rect(0,0,Width,H2);                    //poe a metade de cima novo..
             aCanvas.CopyRect(R,aEntryTo.Bitmap.Canvas,R);
             R:=Rect(0,3*H4,Width,Height);                    //poe a 1/4 de baixo do velho..
             aCanvas.CopyRect(R,aEntryFrom.Bitmap.Canvas,R);  //no 1/4 de baixo
           end;
         RT:=Rect(0,H2,Width,3*H4);         //no 1/4 abaixo da metade
         if fReflexoNaPlaquinhaViradaPraCima then
           PintaReflexo(RT,aCanvas,clGray) //isso simula um reflexo no flap virado pra cima
           else begin
             R:=Rect(0,H2,Width,Height);        //poe a metade de baixo do novo..
             aCanvas.CopyRect(RT,aEntryTo.Bitmap.Canvas,R);
           end;
         //fRepaintRect:=RT;
         DesenhaMoldura(3*H4);
       end;
     4: if Assigned(aEntryTo) then //== 100% novo ( o bmp anterior desaparece)
       begin
         //TODO
         if bRenderizacaoCompleta or (fIxTo=-1) then
           begin
             fControlBitmap.Canvas.Draw(0,0,aEntryTo.Bitmap); //== 100% novo
             if fUseBackColor2 then with fControlBitmap.Canvas do
               aEntryTo.RenderTextToCanvas({aBackColor=} fBackColor2, fControlBitmap.Canvas); //render bmp with alternate color
           end
           else begin
             R:=Rect(0,H2,Width,Height);
             aCanvas.CopyRect(R,aEntryTo.Bitmap.Canvas,R);
           end;
         //fRepaintRect:=Rect(0,H2,Width,Height);
       end;
  else
    if Assigned(aEntryTo) then
      fControlBitmap.Canvas.Draw(0,0,aEntryTo.Bitmap); //== 100% novo
    //fRepaintRect:=Rect(0,0,Width,Height);
  end;
  fControlBMPValid:=TRUE; //valida o BMP produzido
end;

// Sets fEntryFrom and fEntryTo (to the next) and starts the transitions
// Chamado só por SetCaption, pois o Find() pode ser custoso..
procedure TFlapLabel.StartFlappingFrom(const aCaptionFrom:String);
begin
  if (fBitmaps.Count=0) then exit; //No BMPs to draw??
  if not fBitmaps.Find(aCaptionFrom,fIxFrom) then fIxFrom:=-1; //isso nunca deveria acontecer...
  //calcula o fIxTo (index do BMP final da proxima transicao)
  if (fIxFrom>=0) then SetIxToForNextTransition;
end;

// Searches for the next BMP and sets fIxTo. Makes sure that we are not skipping
// the fCaption while jumping fFlapIncrements
procedure TFlapLabel.SetIxToForNextTransition;
var C,iFrom,iTo,iFinal,j:integer;
begin
  C:=fBitmaps.Count;
  iTo:=fIxFrom;
  if (fFlapIncrement>1) then //avanca iTo verificando se nao está passando por cima do Caption final
    begin
      j:=0;
      repeat
        inc(j);
        inc(iTo);
        if (iTo>=C) then iTo:=0;                        //rodou o final da lista, começa do começo
        if (fCaption=fBitmaps.Strings[iTo]) then break; //chegou no destino, fica nesse
      until j>=fFlapIncrement;
    end
    else begin
      inc(iTo);                             //inicia transicao até o proximo BMP da lista
      if (iTo>=fBitmaps.Count) then iTo:=0; //rodou
    end;
  fIxTo:=iTo;
  fTransitionState:=0;  //prepara para nova transicao
  fIsFlapping:=TRUE;
end;

procedure TFlapLabel.AvancaSubtextFrame;
var aFrame:integer; C:integer;
begin
  if (fSubtextTicks=0) then exit;
  C:=fSubtexts.Count;
  if (C=0) then exit;
  fSubtextFrame:=GlobalSubtextFrame mod (fSubtextTicks*C);   //isso sincroniza os flaps de labels com o mesmo fSubtextTicks
  //era inc(fSubtextFrame);                  //num de ticks que fica cada subtext
  aFrame:=fSubtextFrame div fSubtextTicks;   //ve qual o subtext sendo mostrado
  if (aFrame>=fSubtexts.Count) then
    fSubtextFrame:=0; //rodou todos os subtexts, começa novamente
end;

procedure TFlapLabel.SubTextTick;
var aFrame:integer;
begin
  if (fSubtextTicks=0) or (fSubtexts.Count=0) then exit;
  aFrame:=fSubtextFrame div fSubtextTicks;   //ve qual o subtext sendo mostrado
  if (aFrame<fSubtexts.Count) then
    begin
      fbGoDirect:=TRUE;                   //se flapando subtextos, vai sempre direto para ser mais rapido
      Caption:=fSubtexts.Strings[aFrame]; //inicia transicao para o proximo subtext
    end;
end;

//Tick do timer global, chamado pela colecao de TFlapLabels a c/ 50 ms
procedure TFlapLabel.FlapLabelTimerTick(Sender:TObject);
var aEntryTo:TFlapEntry;
begin
  if fIxTo<0 then exit; //se fIxTo=-1, nao está flappando.
  //era: if not Assigned(fEntryTo) then exit;  //se nao tem fEntryTo, nao está flappando.
  //aqui tem que procurar o entry em cada tick, pois outro TFlapLabel pode ter alterado a lista :-(
  if (fIxTo<fBitmaps.Count) then aEntryTo:=TFlapEntry(fBitmaps.Objects[fIxTo]) else
    aEntryTo:=nil;

  if (fTransitionState=4) then  //terminou a transicao para EntryTo. Prepara proxima transicao...
     begin
       if Assigned(aEntryTo) and (aEntryTo.Text=fCaption) then  //chegou no fCaption solicitado ?
         begin
           fIsFlapping:=FALSE;                     //Sim. Pára as transicoes (fTransitionState fica no 4)
           //fRepaintRect:=Rect(0,0,Width,Height); //garante repaint completo
           fIxTo:=-1;                              //isso para a flapagem
         end
         else begin               //prepara proxima transicao
           fIxFrom:=fIxTo;        //
           SetIxToForNextTransition;
           fTransitionState:=-1;  //state = -1 ... so it starts from state 0 on the next transition ...
         end;
     end;
  if fIsFlapping then inc(fTransitionState);  //still flapping. goto next state.
  InvalidateControlBMP;                       //make sure we redraw the ControlBMP on the next Paint
  Invalidate;                                 //and make sure we do a Paint if visible
end;

//If very busy flapping, go directly to the target caption
procedure TFlapLabel.FallingBehind;
var ix:integer;
begin
  if fBitmaps.Find(fCaption,ix) then
    begin
      fIxTo:=ix;
      fTransitionState:=4;   //isso mostra o fEntryTo
      fIsFlapping:=FALSE;    //Pára as transicoes
      InvalidateControlBMP;  //make sure we redraw the ControlBMP on the next Paint
      Invalidate;            //and make sure we do a Paint if visible
    end;
end;

procedure TFlapLabel.Paint;
begin
  inherited;
  if not fControlBMPValid then PaintControlBMP;
  //Canvas.CopyRect(fRepaintRect,fControlBitmap.Canvas,fRepaintRect);
  Canvas.Draw(0,0,fControlBitmap);
end;

procedure TFlapLabel.SetBackColor(const Value: TColor);
begin
  if fBackColor<>Value then
    begin
      fBackColor := Value;
    end;
end;

procedure TFlapLabel.SetFont(const Value: TFont);
begin
  fFont.Assign(Value);
end;

procedure TFlapLabel.SetFontTop(const Value: integer);
begin
  if fFontTop<>Value then
    begin
      fFontTop := Value;
    end;
end;

function TFlapLabel.Clone: TFlapLabel;
begin
    //Profiler_Profile( 0);
  Result:=TFlapLabel.Create(Owner);
    //Profiler_Profile( 1);
  Result.Top        := Top;
    //Profiler_Profile( 2);
  Result.Left       := Left;
    //Profiler_Profile( 3);
  Result.Width      := Width;
    //Profiler_Profile( 4);
  Result.Height     := Height;
    //Profiler_Profile( 5);
  Result.Parent     := Parent;  //isso passou para cá para melhorar o desempenho. Ficou muito mais lento no D6...
    //Profiler_Profile(6);
  Result.Font.Assign(Font);
    //Profiler_Profile( 7);
  Result.BackColor  := BackColor;

    //Profiler_Profile( 8);
  Result.FontTop    := FontTop;
    //Profiler_Profile( 9);
  Result.GroupName  := GroupName;
    //Profiler_Profile(10);
  Result.bLinhaCentral := bLinhaCentral;
    //Profiler_Profile(11);
  Result.SubtextTicks:= SubtextTicks;
    //Profiler_Profile(12);
  Result.FlapIncrement:=FlapIncrement;
    //Profiler_Profile(13);
  Result.Caption:=Caption;
    //Profiler_Profile(14);
  Result.RenderCaption;
    //Profiler_Profile(15);
end;

procedure TFlapLabel.SetGroupName(const Value: string);
begin
  if (fGroupName<>Value) then
    begin
      if (fGroupName='') then fBitmaps.Free;  //estava usando lista local, desaloca-lha
      fGroupName := Value;
      if (fGroupName='') then fBitmaps:=TFlapBitmapList.Create
        else fBitmaps:=FindAddGlobalBMPList(fGroupName);
    end;
end;

procedure TFlapLabel.SetLinhaCentral(const Value: boolean);
var i:integer; aEntry:TFlapEntry;
begin
  if fLinhaCentral<>Value then
    begin
      fLinhaCentral := Value;
      for i:=0 to fBitmaps.Count-1 do
        begin
          aEntry:=TFlapEntry(fBitmaps.Objects[i]);
          aEntry.fLinhaCentral:=fLinhaCentral ;
        end;
    end;
end;

procedure TFlapLabel.SetSubtexts(const Value: TStringList);
var OldText:String;
begin
  OldText:=fSubtexts.Text;
  if Assigned(Value) then
    begin
      if (OldText<>Value.Text) then
        begin
          if (fSubtextTicks>0) then
            fSubtextFrame:=GlobalSubtextFrame mod fSubtextTicks //isso sincroniza os flaps de labels com o mesmo fSubtextTicks
            else fSubtextFrame:=0;
          fSubtexts.Assign(Value);
        end;
    end
    else fSubtexts.Clear;
end;

function TFlapLabel.TemSubtextos: boolean;
begin
  Result:=(fSubtexts.Count>0);
end;

procedure TFlapLabel.Loaded;
begin
  inherited;
  RenderCaption;
  // isso nao é feito em SetCaption para esperar a eventual
  // setagem de uma lista de BMPs global em SetGroupName()
end;

function TFlapLabel.GetCaptionEntry:TFlapEntry;
var ix:integer;
begin
  if fBitmaps.Find(fCaption,ix) then //já tem o esse ?
    Result:=TFlapEntry(fBitmaps.Objects[ix])
    else Result:=nil;
end;

procedure TFlapLabel.SetBackColor2(const Value: TColor);
begin
  fBackColor2 := Value;
end;

procedure TFlapLabel.SetUseBackColor2(const Value: boolean);
begin
  if fUseBackColor2<>Value then
    begin
      fUseBackColor2:=Value;
      ForceRender;
    end;
end;

initialization //--------------------------------
  InitGlobalBMPLists;

finalization
  FinishGlobalBMPLists;
end.


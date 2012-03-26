Unit Debug; {Mostra variaveis}
//(c)copr 19 e batatinha Omar Reis
{$H-}
interface

uses WinProcs,WinTypes,SysUtils;

var
  PosDbg: Integer;

Procedure MostraIntVar(y,i:integer);
Procedure MostraWordVar(y:integer;i:word);
Procedure MostraLongIntVar(y:integer;L:LongInt);
Procedure MostraRealVar(y:integer;r:Real);
Procedure MostraPCharVar(y:integer;S:PChar);
Procedure MostraBMPVar(y:integer;ahBMP:hBitmap);
Procedure MostraStrVar(y:integer;var S:String);


implementation

{--------------------------------------------------------}

Procedure MostraIntVar(y,i:integer);
var DC:hDC; S:Array[0..20] of char;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  Str(i:8,S);
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S,StrLen(S));
  DeleteDC(DC);
end;

Procedure MostraWordVar(y:Integer;i:word);
var DC:hDC; S:Array[0..20] of char;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  Str(i:8,S);
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S,StrLen(S));
  DeleteDC(DC);
end;

Procedure MostraLongIntVar(y:integer;L:LongInt);
var DC:hDC; S:Array[0..20] of char;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  Str(L,S); StrCat(S,'  ');
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S,StrLen(S));
  DeleteDC(DC);
end;

Procedure MostraRealVar(y:integer;r:real);
var DC:hDC; S:Array[0..20] of char;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  Str(r:10:8,S);
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S,StrLen(S));
  DeleteDC(DC);
end;

Procedure MostraPCharVar(y:integer;S:PChar);
var DC:hDC; S1:Array[0..500] of char;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  StrCopy(S1,'>');
  StrCat(S1,S);
  StrCat(S1,'<  ');
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S1,StrLen(S1));
  DeleteDC(DC);
end;

Procedure MostraBMPVar(y:integer;ahBMP:hBitmap);
var DC,MemDC:HDC; OldBitmap:hBitmap; bm:TBitmap; xb,yb,w,h:integer;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  MemDC := CreateCompatibleDC(DC);
  OldBitmap:=SelectObject(MemDC,ahBMP);
  GetObject(ahBMP,SizeOf(bm),@bm);
  W:=bm.bmWidth; H:= bm.bmHeight;
  xb:=100; yb:=y*15;
  BitBlt(DC,xb,yb,w,h,MemDC,0,0,srcCopy);
  SelectObject(MemDC,OldBitmap);
  DeleteDC(MemDC);
  DeleteDC(DC);
end;

Procedure MostraStrVar(y:integer;var S:String);
var DC:hDC; S1:Array[0..255] of char; i:integer; C:Char; 
    St1:String;
begin
  DC:=CreateDC('Display',Nil,Nil,Nil);
  St1:='';
  for i:=1 to Length(S) do
    begin
      C:=S[i];
      if (C<#$20) or (C>'z') then
        begin
          St1:=St1+'.';
        end
        else St1:=St1+C;
    end;
  St1:=St1+'<';
  StrPCopy(S1,St1);
  SelectObject(DC,GetStockObject(SYSTEM_FIXED_FONT));
  TextOut(DC,10,15*y,S1,StrLen(S1));
  DeleteDC(DC);
end;

type
  HexArray = array [0..3] of byte;

procedure WordHexToPChar(W: Word; P: PChar);
var
  Digito : HexArray;

  procedure DecToHex(D: Word; var H: HexArray);
  var
    I, Q: Word;
  begin
    Q := D;
    for I := 0 to 3 do
    begin
      H[I] := Q mod 16;
      Q := Q div 16;
    end;
  end;  {DexToHex}

  procedure HexToPChar(H: HexArray; S: PChar);
  var
    I: Byte;
    D: array [0..1] of Char;
  begin
    StrCopy(S, '$');
    for I := 3 downto 0 do
      case H[I] of
      0..9:
      begin
        Str(H[I], D);
        StrCat(S, D);
      end;
      10:
        StrCat(S, 'A');
      11:
        StrCat(S, 'B');
      12:
        StrCat(S, 'C');
      13:
        StrCat(S, 'D');
      14:
        StrCat(S, 'E');
      15:
        StrCat(S, 'F');
      end; {case}
  end; {HexToPChar}

begin {WordHexToPChar}
  DecToHex(W, Digito);
  HexToPChar(Digito, P);
end;  {WordHexToPChar}

begin
  PosDbg := 0;
end.
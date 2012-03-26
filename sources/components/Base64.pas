Unit Base64; {Encode <base64> http://ds.internic.net/rfc/rfc1521.txt}
{Codificacao para Basic Authentication http}
{*Str codificado por base64 contem apenas 'A'..'Z','a'..'z','0'..'9','/','+'}

interface
uses
  SysUtils;

Function Base64Encode(const S:String):String;
Function Base64Decode(const S:String):String;
function HttpBasicAuthStr(const aUserPW:string):String; //aUserPW tipo 'omar:xpto'. ret tipo 'Authorization: Basic GFC1123TR21yyty=='

implementation {-------------------------------------------------}

const sAuthBasic='Authorization: Basic ';

function HttpBasicAuthStr(const aUserPW:string):String; //tipo Authorization: Basic GFC1123TR21yyty==
begin
  Result:=sAuthBasic+Base64Encode(aUserPW);
end;

Function Base64Byte(C:Char):Byte;
begin
  C:=Char(Ord(C) and $7f);
  case C of
    'A'..'Z': Result:=Ord(C)-Ord('A');
    'a'..'z': Result:=Ord(C)-Ord('a')+26;
    '0'..'9': Result:=Ord(C)-Ord('0')+52;
    '+': Result:=62;
    '/': Result:=63;
  else
    Result:=Ord('?');
  end;
end;

Function Base64Char(B:Byte):Char;
begin
  B:=B and 63;
  case B of
    0..25:  Result:=Char(B+Ord('A'));
    26..51: Result:=Char(B+Ord('a')-26);
    52..61: Result:=Char(B+Ord('0')-52);
    62: Result:='+';
    63: Result:='/';
  else
    Result:='?'; {??}
  end;
end;

Function Base64Encode(const S:String):String;
var i,j:integer; c:Char; l:longInt; st:String[4]; b,b1,b2:byte;
    enc:String;
begin
  i:=Length(S);
  enc:='';
  j:=1;
  while (i>0) do
    begin
      if (i>=3) then
        begin
          l:=(LongInt(Ord(S[j+0])) shl 16) or
             (LongInt(Ord(S[j+1])) shl 8 ) or
              LongInt(Ord(S[j+2]));
          B:=(l shr 18) and $ff;
          enc:=enc+Base64Char(B);
          B:=(l shr 12) and $ff;
          enc:=enc+Base64Char(B);
          B:=(l shr  6) and $ff;
          enc:=enc+Base64Char(B);
          B:=L;
          enc:=enc+Base64Char(B);
        end
        else begin
          l:=LongInt(Ord(S[j+0])) shl 16;
          if i=2 then l:=l or LongInt(Ord(S[j+1])) shl 8;
          B:=(l shr 18) and $FF;
          enc:=enc+Base64Char(B);
          B:=(l shr 12) and $FF;
          enc:=enc+Base64Char(B);
          if i=1 then enc:=enc+'='
            else begin
              B:=(l shr 6) and $FF;
              enc:=enc+Base64Char(B);
            end;
          enc:=enc+'=';
        end;
      dec(i,3);
      inc(j,3);
    end;
  Result:=enc;
end;

Function Base64Decode(const S:String):String;
var i,j:integer; deco:String; a,b,c,d,l:LongInt; n:integer;
begin
  i:=Length(S);
  deco:='';
  j:=1;
  while (i>0) do
    begin
      a:=Base64Byte(S[j]);
      b:=Base64Byte(S[j+1]);
      c:=Base64Byte(S[j+2]);
      d:=Base64Byte(S[j+3]);
      {if ((a & 0x80) || (b & 0x80) || (c & 0x80) || (d & 0x80))
	return(-1);}
      l:=(a shl 18) or (b shl 12) or (c shl 6) or d;
      deco:=deco+Char((l shr 16) and  $ff);
      if S[j+2]<>'=' then deco:=deco+Char((l shr 8)  and  $ff);
      if S[j+3]<>'=' then deco:=deco+Char(l and  $ff);
      inc(j,4);
      dec(i,4);
    end;
  Result:=deco;
end;

end.

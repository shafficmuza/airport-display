unit strtoken; // TStringTokenizer //
///// (c)99-08 Omar Reis ///////////////////////////////////
// Historico:                                             //
//   Om: out08:                                           //
//   Om: abr09: token kinds                               //
//   Om: nov10: tipo especifico de exception              //
////////////////////////////////////////////////////////////
// Usage:                                                 //
//   st:=TStringTokenizer.Create(nil,S,';');              //
//   aInt:=st.AsInteger[0];                               //
//   aStr:=st.Items[1];                                   //
////////////////////////////////////////////////////////////

interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;


const
  CR=#13; LF=#10; TAB=#9;

type
  ETokenizerConvertException = class(Exception); //nov10:
  ETokenizerIndexException   = class(Exception); //nov10:

  TstrTokenKind=(tkNone, tkInteger, tkFloat, tkDatetime, tkString);
  TStringTokenizer = class(TObject)
  private
    fStr:String;         {String a ser parseado}
    fDelim:String;       {delimitadores}
    fTokens:TStringList; {tokens extraidos}
    fCount:integer;
    function  GetItem(i:integer):String;
    function  GetAsInteger(i:integer):integer;
    function  GetAsFloat(i:integer):Double;
    function  GetAsDate(i:integer):TDateTime;
    function  GetAsDateTime(i:integer):TDateTime;
    Procedure SetStr(const Value:String);
    Procedure SetDelim(const Value:String);
    procedure ParseString;
    function  GetKind(i: integer): TstrTokenKind;
  protected
  public
    fIgnoreDecimalSeparator:boolean; // (default=false) ignora se decimal com , ou .
    Constructor Create(AOwner:TComponent;str,delim:String);
    Destructor  Destroy; override;
    Procedure   PurgaTokensNulos;

    Property Tokens:TStringList read fTokens;
    Property Items[i:integer]:String read GetItem;
    Property Kind[i:integer]:TstrTokenKind read GetKind;
    Property AsInteger[i:integer]:integer read GetAsInteger;
    Property AsFloat[i:integer]:Double    read GetAsFloat;
    Property AsDate[i:integer]:TDateTime  read GetAsDate;
    Property AsDateTime[i:integer]:TDateTime  read GetAsDateTime;
  published
    property Count:integer read fCount write fCount;
    Property Str:String read fStr write SetStr;
    Property Delim:String read fDelim write SetDelim;  // pode conter multiplos
  end;

(* procedure Register; *)

implementation {-----------------------------------------}

Constructor TStringTokenizer.Create(AOwner:TComponent; str,delim:String);
begin
  inherited Create;
  fStr:=str;
  fDelim:=delim;
  fCount:=0;
  fTokens    := TStringList.Create;
  fIgnoreDecimalSeparator:=false; //default = nao ignora
  ParseString;
end;

Destructor  TStringTokenizer.Destroy;
begin
  fTokens.Free;
  inherited Destroy;
end;

function  TStringTokenizer.GetItem(i:integer):String;
begin
  if (i<0) or (i>=fCount) then
    Raise ETokenizerIndexException.Create('Invalid index');
  Result:=fTokens.Strings[i];
end;

function TStringTokenizer.GetKind(i:integer):TstrTokenKind;
var S:String; r:double; n:integer; d:TDatetime;
begin
  Result:=tkNone;
  if (i>=0) and (i<fCount) then
    begin
      S:=Items[i];
      if (S<>'') then
        begin
          //tenta conversao na ordem das possibilidades
          try
            n:=StrToInt(S);
            Result:=tkInteger;
            exit;
          except
          end;
          try
            r:=StrToFloat(S);
            Result:=tkFloat;
            exit;
          except
          end;
          try
            d:=StrToDatetime(S);
            Result:=tkDatetime;
            exit;
          except
          end;
          Result:=tkString;   //se não é nada, é string
        end;
    end;
end;

procedure TStringTokenizer.ParseString;
var c:Char; aToken:String; L,i:integer;

   function CIsDelim:boolean;
   var i:integer;
   begin
     Result:=FALSE;
     for i:=1 to Length(fDelim) do if C=fDelim[i] then
       begin Result:=TRUE; exit; end;
   end;

begin
  L:=Length(fStr);
  fCount:=0;
  fTokens.clear;
  aToken:='';
  for i:=1 to L do
    begin
      C:=fStr[i];
      if CIsDelim then {is separador}
        begin
          fTokens.Add(aToken);
          aToken:='';
        end
        else aToken:=aToken+C; {Add char to Token}
    end;
  fTokens.Add(aToken); {add last Token}
  fCount:=fTokens.Count;
end;

Procedure TStringTokenizer.SetDelim(const Value:String);
begin
  fDelim:=Value;
  ParseString;
end;

Procedure TStringTokenizer.SetStr(const Value:String);
begin
  fStr:=Value;
  ParseString;
end;

function  TStringTokenizer.GetAsFloat(i:integer):Double;
var aItem:String; OutroDecSeparator:Char;
begin
  aItem:=Trim(Items[i]);
  try
    if fIgnoreDecimalSeparator then
      begin
        if DecimalSeparator='.' then OutroDecSeparator:=',' else OutroDecSeparator:='.';
        if (Pos(OutroDecSeparator,aItem)>0) then
          aItem:=StringReplace(aItem,OutroDecSeparator,DecimalSeparator,[rfReplaceAll]);
      end;
    Result:=StrToFloat(aItem);
  except
    Raise ETokenizerConvertException.Create('Invalid number format: '+aItem);
  end;
end;

function  TStringTokenizer.GetAsDate(i:integer):TDateTime;
var aItem:String;
begin
  aItem:=Trim(Items[i]);
  try
    Result:=StrToDate(aItem);
  except
    Raise ETokenizerConvertException.Create('Invalid date format: '+aItem);
  end;
end;

function  TStringTokenizer.GetAsDateTime(i:integer):TDateTime;
var aItem:String;
begin
  aItem:=Trim(Items[i]);
  try
    Result:=StrToDateTime(aItem);
  except
    Raise ETokenizerConvertException.Create('Invalid date/time format: '+aItem);
  end;
end;

function  TStringTokenizer.GetAsInteger(i:integer):integer;
var aItem:String;
begin
  aItem:=Trim(Items[i]);
  try
    Result:=StrToInt(aItem);
  except
    Raise ETokenizerConvertException.Create('Invalid integer value:'+aItem);
  end;
end;

Procedure TStringTokenizer.PurgaTokensNulos;
var i:integer;
begin
  for i:=fTokens.Count-1 downto 0 do
    if (Trim(fTokens.Strings[i])='') then fTokens.Delete(i);
  fCount:=fTokens.Count;
end;

{---------------------------------------------------------------------}

(* procedure Register;
begin
  RegisterComponents('Samples', [TStringTokenizer]);
end; *)

end.

unit httpmult; {Parser de http multipart contents - RFC 1867 (acho!?)}
//Esse é o formato usado pelos browsers nos uploads
//O content-type, que vem no header http é do tipo:
//content-type: multipart/form-data; boundary=---------------------------20731188169255

//exemplo de multipart entity body:
//-----------------------------20731188169255
//Content-Disposition: form-data; name="name"
//
//omar
//-----------------------------20731188169255
//Content-Disposition: form-data; name="email"
//
//omar@tecepe.com.br
//-----------------------------20731188169255
//Content-Disposition: form-data; name="upl-file"; filename="D:\Admim\xx.txt"
//Content-Type: text/plain
//
//c:\sx\ag_l734.jpg     <--conteudo do arquivo uploaded
//c:\sx\ag_l814.jpg
//c:\sx\ce_l857.jpg
//c:\sx\ce_l957.jpg
//c:\sx\four.jpg
//
//-----------------------------20731188169255
//Content-Disposition: form-data; name="desc"
//
//descricao
//-----------------------------20731188169255--

interface
uses
  Classes,
  SysUtils;

Type
  THttpPart=class(TObject)
  private
    fContentDisposition:String;
    fName:String;
    fContentType:String;
    fContent:String;
    Procedure SetAsString(const value:String);
    function  GetContentSize:integer;
  public
    Constructor Create;
    Destructor  Destroy; override;
    Property ContentDisposition:String read fContentDisposition write fContentDisposition;
    Property Name:String         read fName         write fName;
    Property ContentType:String  read fContentType  write fContentType;
    Property Content:String      read fContent      write fContent;
    Property AsString:String     write SetAsString;
    Property ContentSize:integer read GetContentSize;
  end;

// multipart/form-data; boundary=---------------------------7ce25884e0
  TMultipartHttpContent=class(TObject)
  private
    fEntityBody:PChar;
    fEntityBodySz:integer;
    fParts:TStringList;
    fBoundary:String;
    Procedure ClearParts;
  public
    Constructor Create;
    Destructor  Destroy; override;
    Procedure   ParseEntityBody;
    {...}
    Property  Parts:TStringList read fParts;
    Property  EntityBody:PChar     read fEntityBody   write fEntityBody;
    Property  EntityBodySz:integer read fEntityBodySz write fEntityBodySz;
    Property  Boundary:String      read fBoundary     write fBoundary;
  end;

implementation

uses
  StrToken; {TStringTokenizer}

{-------------------  THttpPart. }
Constructor THttpPart.Create;
begin
  inherited;
  fContentDisposition:='';
  fName:='';
  fContentType:='';
  fContent:='';
end;

Destructor  THttpPart.Destroy;
begin
  inherited;
end;

function  THttpPart.GetContentSize:integer;
begin
  Result:=Length(fContent);
end;

Procedure THttpPart.SetAsString(const value:String);
var L,p,j,lc:integer; Linha:ShortString; C:Char; nlinha:integer; pc:PChar;
const
  cContDisp='content-disposition:';
  cName='name=';
  cContType='content-type:';

  Procedure ParseContentDisposition; //Content-Disposition: form-data; name="upl-file"; filename="D:\Admim\sex1.txt"
  var st:TStringTokenizer; aLinha:String; x:integer;
  begin
    st:=TStringTokenizer.Create(nil,Linha,';');
    if st.Count>0 then
      begin
        aLinha:=st.Items[0];
        lc:=Length(cContDisp);
        j:=Pos(cContDisp,Lowercase(aLinha));
        if j>0 then fContentDisposition:=Trim(Copy(aLinha,j+lc,Length(aLinha)));
      end;
    if st.Count>1 then
      begin
        aLinha:=st.Items[1];
        lc:=Length(cName);
        j:=Pos(cName,Lowercase(aLinha));
        if j>0 then
          begin
            aLinha:=Trim(Copy(aLinha,j+lc,Length(aLinha)));
            fName:='';
            for x:=1 to Length(aLinha) do if aLinha[x]<>'"' then fName:=fName+aLinha[x]; //tira as '"'
          end;
      end;
    st.Free;
  end;

  Procedure ParseContentType;  //Content-Type: text/plain
  begin
    lc:=Length(cContType);
    j:=Pos(cContType,Lowercase(Linha));
    if j>0 then fContentType:=Trim(Copy(Linha,j+lc,Length(Linha)-j));
  end;

begin {SetAsString}
  if (Value='') then exit;
  L:=Length(value);
  p:=1;
  Linha:='';
  nlinha:=1;
  while p<=L do
    begin
      C:=value[p];
      case C of
        #13:;
        #10:
          begin
            if Linha<>'' then
              begin
                if nlinha=1 then ParseContentDisposition
                  else ParseContentType;
                inc(nlinha);
                Linha:='';
              end
              else begin //o resto é content
                pc:=@value[p+1];
                SetString(fContent,pc,L-p);
                exit;
              end;
          end;
      else
        Linha:=Linha+C;
      end;
      inc(p);
    end;
end;

{---------------- TMultipartHttpContent. }
Constructor TMultipartHttpContent.Create;
begin
  inherited;
  fEntityBody:=nil;
  fEntityBodySz:=0;
  fParts:=TStringList.Create;
  fBoundary:='';
end;

Destructor  TMultipartHttpContent.Destroy;
begin
  ClearParts;
  inherited;
end;

Procedure TMultipartHttpContent.ClearParts;
var i:integer;
begin
  for i:=0 to fParts.Count-1 do THttpPart(fParts.Objects[i]).Free;
  fParts.Clear;
end;

Procedure TMultipartHttpContent.ParseEntityBody;
var pp,p,pin,lb,L:integer; Estado:integer; {0=Proc Boundary, 1=lendo header, 2=content}
    Ci:Char; sEntityBody:String; pc:PChar; sPart:String; aPart:THttpPart;
begin
  if (not Assigned(fEntityBody)) or (fEntityBodySz=0) or (fBoundary='') then exit;
  ClearParts;
  lb:=Length(fBoundary);
  pin:=0; {inicio da parte atual}
  Ci:=fBoundary[1];
  p:=0;   {ptr pro entitybody}
  while (p<fEntityBodySz) do
    begin
      if (fEntityBody[p]=Ci) then //match do primeiro caracter
        begin
          pp:=2; //compara do [2] pra frente
          while (pp<=lb) and (p+pp-1<fEntityBodySz) do
            begin
              if fEntityBody[p+pp-1]<>fBoundary[pp] then
                break;
              inc(pp);
            end;
          if pp>=lb then {boundary found, salva}
            begin
              inc(p,pp); {avança p}
              pc:=@fEntityBody[pin+2]; {o 2 pula o CRLF no fim do boundary anterior}
              L:=p-pin-lb-7;           {tira 2 CRLFs e 1 '--' (na verdade, funcionou com este 7! :-)}
              if (L>0) then
                begin
                  SetString(sPart,pc,L);
                  aPart:=THttpPart.Create;
                  aPart.AsString:=sPart; {isto parseia a parte}
                  fParts.AddObject(aPart.Name,aPart);
                end;
              pin:=p+1; {salva inicio do proximo trecho}
            end;
        end; {if (fEntityBody[p]=Ci)..}
      inc(p);
    end;
end;

end.

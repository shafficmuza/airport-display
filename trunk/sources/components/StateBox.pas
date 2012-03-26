unit StateBox; { Saves Form and Components state to a Ini file   }
{©Copr 97 Omar Reis <omar@tecepe.com.br> updates: 14/11/97 v 1.0 }
// salva a "principal" propriedade dos componentes mais comuns
// usados em forms. Ex: TEdit.Text, TCheckBox.Checked etc
//instruções de uso:
//  - Inserir os nomes dos comps salvos em TStateBox.CompList
//  - No FormCreate, chamar StateBox1.ReadStateFromIni
//  - No FormDestroy chamar StateBox1.WriteStateToIni
// Historico:
//  - set07 - incluí vars encriptadas. Incluir '*' no final do nome do componente para encriptar

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,ExtCtrls,Spin,IniFiles;

type
  TStateBox = class(TComponent)
  private
    fCompList:TStringList;
    fIniFileName:String;
    fSaveFormPosition:boolean;
    fUsaDiretorioDoWindows: boolean;
    Procedure SetCompList(Value:TStringList);
    procedure WriteStateToCustomIniFile(aIF: TCustomIniFile);
  protected
  public
    Constructor Create(aOwner:TComponent); override;
    Destructor Destroy; override;
    Procedure  ReadStateFromIni;
    Procedure  WriteStateToIni;
    Procedure  Loaded; override;
    function   GetInifileText:String;
    procedure  UpdateTextFromControls(var S: String);
    procedure  UpdateControlsFromText(const S: String);
  published
    Property CompList:TStringList read fCompList write SetCompList;
    Property IniFileName:String read fIniFileName write fIniFileName;
    Property SaveFormPosition:Boolean read fSaveFormPosition write fSaveFormPosition;
    Property UsaDiretorioDoWindows:boolean read fUsaDiretorioDoWindows write fUsaDiretorioDoWindows default TRUE;
  end;

procedure Register;

implementation

uses
  Base64; //base64 encode/decode, denotado por '*'

const
  sState='State';

Constructor TStateBox.Create(aOwner:TComponent);
begin
  inherited Create(aOwner);
  fCompList:=TStringList.Create;
  fIniFileName:='[ExeName.ini]'; {Default .ini name same as Exename}
  fSaveFormPosition:=FALSE;
  fUsaDiretorioDoWindows:=TRUE;
end;

Destructor TStateBox.Destroy;
begin
  fCompList.Free;
  inherited Destroy;
end;

Procedure TStateBox.SetCompList(Value:TStringList);
begin
  fCompList.Assign(Value);
end;

Procedure TStateBox.Loaded;
var p:integer; aPath:string;
begin
  inherited Loaded;
  if (not (csDesigning in ComponentState)) then
    begin
      if ((fIniFileName='') or (fIniFileName[1]='[')) then // fIniFileName vazio ou '[exename.ini]' - Aponta para ini deste aplicativo
        begin
          if fUsaDiretorioDoWindows then fIniFileName:=ExtractFileName(Application.ExeName)  //no \winnt\ - deixa só o nome do arquivo
            else fIniFileName:=Application.ExeName;                                          //no dir do aplic. Usa path completo
          p:=Pos('.',fIniFileName);                                                          //troca extensao .exe por .ini
          if (p>0) then fIniFileName:=Copy(fIniFileName,1,p-1)+'.ini'
            else fIniFileName:='noname.ini'; {??}
        end
        else begin  //outros nomes de ini
          if not fUsaDiretorioDoWindows then //completa path se for no dir de trabalho
            begin
              p:=Pos('\',fIniFileName);  //ve se especificou path absoluto
              if (p=0) then              //nop. localiza ini no dir de trabalho
                begin
                  aPath:=ExtractFilePath(Application.ExeName);
                  fIniFileName:=aPath+fIniFileName;
                end;
            end;
        end;
    end;
end;

Procedure TStateBox.UpdateControlsFromText(const S:String);
var SL:TStringList; aValue,aCompName:String; i,j,c:integer; aControl:TComponent;
begin
  SL:=TStringList.Create;
  try
    SL.Text:=S;
    for i:=0 to fCompList.Count-1 do
      begin
        aCompName:=fCompList.Strings[i];
        aValue:=SL.Values[aCompName];
        aControl:=Owner.FindComponent(aCompName);
        if Assigned(aControl) then
          begin
            if aControl is TEdit              then TEdit(aControl).Text:=aValue
            else if aControl is TCheckBox     then try TCheckBox(aControl).Checked:=Boolean(StrToInt(aValue)); except end
            else if aControl is TRadioGroup   then try TRadioGroup(aControl).ItemIndex:=StrToInt(aValue);      except end
            else if aControl is TSpinEdit     then try TSpinEdit(aControl).Value:=StrToInt(aValue);            except end
            else if aControl is TMemo then
              begin
                Raise Exception.Create('nao implementado');
                //TODO
              end;
          end;
      end;
  finally
    SL.Free;
  end;
end;

Procedure TStateBox.UpdateTextFromControls(var S:String);
var SL:TStringList; aValue,aCompName:String; i,j,c:integer; aControl:TComponent; temControle:boolean;
begin
  temControle:=false;
  SL:=TStringList.Create;
  try
    SL.Text:=S;
    for i:=0 to fCompList.Count-1 do
      begin
        aCompName:=fCompList.Strings[i];
        aControl:=Owner.FindComponent(aCompName);
        aValue:='';
        if Assigned(aControl) then
          begin
            temControle:=FALSE;
            if      aControl is TEdit       then begin aValue:=TEdit(aControl).Text;                        temControle:=TRUE; end
            else if aControl is TCheckBox   then begin aValue:=IntToStr(ord(TCheckBox(aControl).Checked));  temControle:=TRUE; end
            else if aControl is TRadioGroup then begin aValue:=IntToStr(TRadioGroup(aControl).ItemIndex);   temControle:=TRUE; end
            else if aControl is TSpinEdit   then begin aValue:=IntToStr(TSpinEdit(aControl).Value);         temControle:=TRUE; end
            else if aControl is TMemo       then
              begin
                Raise Exception.Create('nao implementado');
                //TODO
              end;
          end;
        if temControle then SL.Values[aCompName]:=aValue;
      end;
    S:=SL.Text;
  finally
    SL.Free;
  end;
end;

Procedure TStateBox.ReadStateFromIni;
var aCompName:String; i,j,c,p:integer; aControl:TComponent; aIF:TIniFile; S,FormName:String; bEncriptada:boolean;
begin
  aIF:=TIniFile.Create(fIniFileName);
  if Assigned(Owner) and (Owner is TForm) then FormName:=TForm(Owner).Name else FormName:='';
  FormName:=FormName+'_'+sState;
  for i:=0 to fCompList.Count-1 do
    begin
      aCompName:=fCompList.Strings[i];

      p:=Pos('*',aCompName);   //  se nome contem '*' (ex: 'edPassword*') então conteudo é encriptado
      bEncriptada:=(p>0);

      if bEncriptada then // tira * para obter nome do comp
        begin
          Delete(aCompName,p,1);
          aCompName:=Trim(aCompName);
        end;

      aControl:=Owner.FindComponent(aCompName);
      if Assigned(aControl) then
        begin
          if aControl is TEdit then
            begin
              S:=TEdit(aControl).Text;
              S:=aIF.ReadString(FormName,aCompName,S);
              if bEncriptada then S:=Base64Decode(S);
              TEdit(aControl).Text:=S;
            end
          else if aControl is TCheckBox then
            begin
              //não encripta checkbox for now..
              TCheckBox(aControl).Checked:=aIF.ReadBool(FormName,aCompName,TCheckBox(aControl).Checked);
            end
          else if aControl is TRadioGroup then
             TRadioGroup(aControl).ItemIndex:=aIF.ReadInteger(FormName,aCompName,TRadioGroup(aControl).ItemIndex)
          else if aControl is TSpinEdit then
             TSpinEdit(aControl).Value:=aIF.ReadInteger(FormName,aCompName,TSpinEdit(aControl).Value)
          else if aControl is TMemo then
            begin
              //não encripta memos for now..
              c:=aIF.ReadInteger(FormName,aCompName+'Count',0);
              if c>0 then
                begin
                  TMemo(aControl).Clear;
                  for j:=0 to c-1 do
                    TMemo(aControl).Lines.Add(aIF.ReadString(FormName,aCompName+IntToStr(j),''));
                end;
            end;
        end;
    end;
  if fSaveFormPosition and Assigned(Owner) and (Owner is TForm) then
    begin
      TForm(Owner).Width:=aIF.ReadInteger(FormName,'Width',TForm(Owner).Width);
      TForm(Owner).Height:=aIF.ReadInteger(FormName,'Height',TForm(Owner).Height);
      TForm(Owner).Top:=aIF.ReadInteger(FormName,'Top',TForm(Owner).Top);
      TForm(Owner).Left:=aIF.ReadInteger(FormName,'Left',TForm(Owner).Left);
    end;
  aIF.Free;
end;

Procedure TStateBox.WriteStateToCustomIniFile(aIF:TCustomIniFile);
var aCompName:String; i,j,c,p:integer; aControl:TComponent; FormName,S:String; bEncriptada:boolean;
begin
  if Assigned(Owner) and (Owner is TForm) then FormName:=TForm(Owner).Name else FormName:='';
  FormName:=FormName+'_'+sState; {ex: Form1_State}
  for i:=0 to fCompList.Count-1 do
    begin
      aCompName:=fCompList.Strings[i];

      p:=Pos('*',aCompName);   //  se nome contem '*' (ex: 'edPassword*') então conteudo é encriptado
      bEncriptada:=(p>0);

      if bEncriptada then // tira * para obter nome do comp
        begin
          Delete(aCompName,p,1);
          aCompName:=Trim(aCompName);
        end;

      aControl:=Owner.FindComponent(aCompName);
      if Assigned(aControl) then
        begin
          //save the "main" property of each control type
          if aControl is TEdit then
            begin
              S:=TEdit(aControl).Text;
              if bEncriptada then S:=Base64Encode(S); //encripta só os edits ( os passwords stupid! )
              aIF.WriteString(FormName,aCompName,S);
            end
          else if aControl is TCheckBox then   aIF.WriteBool(FormName,aCompName,TCheckBox(aControl).Checked)
          else if aControl is TRadioGroup then aIF.WriteInteger(FormName,aCompName,TRadioGroup(aControl).ItemIndex)
          else if aControl is TSpinEdit then   aIF.WriteInteger(FormName,aCompName,TSpinEdit(aControl).Value)
          else if aControl is tMemo then
            begin
              c:=TMemo(aControl).Lines.Count;
              aIF.WriteInteger(FormName,aCompName+'Count',c);
              for j:=0 to c-1 do
                aIF.WriteString(FormName,aCompName+IntToStr(j),TMemo(aControl).Lines.Strings[j]);
            end;
        end;
    end;
  //save form position
  if fSaveFormPosition and Assigned(Owner) and (Owner is TForm) then
    begin
      aIF.WriteInteger(FormName,'Width', TForm(Owner).Width);
      aIF.WriteInteger(FormName,'Height',TForm(Owner).Height);
      aIF.WriteInteger(FormName,'Top',   TForm(Owner).Top);
      aIF.WriteInteger(FormName,'Left',  TForm(Owner).Left);
    end;
end;

Procedure TStateBox.WriteStateToIni;
var aIF:TIniFile;
begin
  aIF:=TIniFile.Create(fIniFileName);
  WriteStateToCustomIniFile(aIF);
  aIF.Free;
end;

function  TStateBox.GetInifileText:String;
var aIF:TMemIniFile; SL:TStringList;
begin
  aIF:=TMemIniFile.Create('');
  WriteStateToCustomIniFile(aIF);
  SL:=TStringList.Create;
  aIF.GetStrings(SL);
  Result:=SL.Text;
  SL.Free;
  aIF.Free;
end;

procedure Register;
begin
  RegisterComponents('Omar', [TStateBox]);
end;

end.

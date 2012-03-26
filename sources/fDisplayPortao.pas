unit fDisplayPortao; // AirportDisplay - (c)copr. 02-12 Omar Reis
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/
//  display de portão de embarque do AD

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus,
  OmFlapLabel,
  uInformacaoDeVoo, {TInformacaoDeVoo}
  AnimGlob;

type
  TFormDisplayPortao = class(TForm)
    FlapAirline: TFlapLabel;
    FlapFlight1: TFlapLabel;
    FlapFlight2: TFlapLabel;
    FlapFlight3: TFlapLabel;
    FlapFlight4: TFlapLabel;
    FlapCidadeTo: TFlapLabel;
    LHVoo: TLabel;
    Label1: TLabel;
    Menu: TPopupMenu;
    Configuracao1: TMenuItem;
    N1: TMenuItem;
    Sobre1: TMenuItem;
    Termina1: TMenuItem;
    Label2: TLabel;
    Label3: TLabel;
    Led1: TGTAnimated;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    FlapEscala: TFlapLabel;
    FlapHoraHH: TFlapLabel;
    FlapHoraH: TFlapLabel;
    FlapHoraMM: TFlapLabel;
    FlapHoraM: TFlapLabel;
    Lab2: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Configuracao1Click(Sender: TObject);
    procedure Sobre1Click(Sender: TObject);
    procedure Termina1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
  public
    procedure SetInfoVoo(N: integer; aVoo: TInformacaoDeVoo);
  end;

var
  FormDisplayPortao: TFormDisplayPortao;

implementation

uses
  fADSplash,
  fDownloadInformacaoDeVoo;   {FormAirportDisplayControl}

{$R *.dfm}

Procedure LoadAirlineLogos_GR(aFlapLabel:TFlapLabel);
var i:integer; aAirline:String;
begin
  try
    for i:=0 to Airlines.Count-1 do
      begin
        aAirline:=Airlines.Strings[i];
        LoadFlapBitmapFile('AIRLINE_GR',aAirline,aAirline+'_GR.BMP', aFlapLabel); //carrega bmp da cia na lista global do  flapflap
      end;
  except
    MessageDlg('Erro no carregamento de '+aAirline+'.bmp', mtInformation,[mbOk], 0);
  end;
end;

{ TFormDisplayPortao }

procedure TFormDisplayPortao.FormCreate(Sender: TObject);
begin
  Left:=0;
  Top:=0;
  LoadAirlineLogos_GR(FlapAirline);
  ClientWidth:=800;
  ClientHeight:=600;
end;

procedure TFormDisplayPortao.SetInfoVoo(N: integer; aVoo: TInformacaoDeVoo);
var aCidade,aFlight:String; p:integer; aVooParc:TInformacaoDeVoo;
begin
  //este form mostra apenas um voo: o primeiro.
  //os outros devem ser excluidos pelo filtro
  if N<>0 then exit;
  if Assigned(aVoo) then
    begin
      aCidade:=CodLocal2Local(aVoo.Destino,aVoo);

      FlapCidadeTo.Caption:=aCidade;

      aCidade:=aVoo.Escala1;    //escala 1...
      aCidade:=CodLocal2Local(aCidade,aVoo);
      FlapEscala.Subtexts.Clear;
      if (aCidade<>'') then
        begin
          FlapEscala.Subtexts.Add(aCidade);
          aCidade:=aVoo.Escala2;     //escala 2....
          aCidade:=CodLocal2Local(aCidade,aVoo);
          if aCidade<>'' then
            begin
              FlapEscala.Subtexts.Add(aCidade);
              aCidade:=aVoo.Escala3;  //escala 3
              aCidade:=CodLocal2Local(aCidade,aVoo);
              if aCidade<>'' then
                begin
                  FlapEscala.Subtexts.Add(aCidade);
                  aCidade:=aVoo.Escala4;
                  aCidade:=CodLocal2Local(aCidade,aVoo);
                  if aCidade<>'' then FlapEscala.Subtexts.Add(aCidade);
                end;
              FlapEscala.Subtexts.Add(' '); //se tem duas ou mais escalas, insere um campo vazio no final
            end;
        end
        else begin //sem escalas..
          FlapEscala.Caption:='';
          FlapEscala.Subtexts.Clear;
        end;

      FlapAirline.Visible:=TRUE;     //mostra bmp da cia

      //FlapAirline.Caption:=aVoo.AirLine; //isso poe bmp da companhia

      FlapAirline.Subtexts.Clear;    //teste teste
      aVooParc:=aVoo.GetVooParceria;
      if Assigned(aVooParc) then     //tem voo em parceria, usa o bmp dos dois alternando
        begin
          FlapAirline.Caption:='';        //ativa os subtexts
          FlapAirline.Subtexts.Add(aVoo.AirLine);
          FlapAirline.Subtexts.Add(aVooParc.AirLine);
        end
        else begin
          FlapAirline.Caption:=aVoo.AirLine;
        end;

      if aVoo.Destacado then Led1.Play:=TRUE
          else begin Led1.Play:=FALSE; Led1.Frame:=0; end;

      aFlight:=aVoo.Voo;
      while Length(aFlight)<4 do aFlight:=' '+aFlight; //minimo de 4 digitos
      if aFlight[1]='0' then delete (aFlight,1,1);     //tira o zero a esquerda
      p:=Length(aFlight);
      if (p>4) then aFlight:=Copy(aFlight,p-4+1,4); //pega só os ultimos 4 digitos
      // ( ignora o 5 digito, que passou a ser usado por Congonhas em jul/04 mas ñ tem que aparecer )

      FlapFlight1.Caption:=aFlight[1];   FlapFlight2.Caption:=aFlight[2];
      FlapFlight3.Caption:=aFlight[3];   FlapFlight4.Caption:=aFlight[4];
    end
    else begin
      FlapCidadeTo.Caption:=' ';
      FlapFlight1.Caption:=' ';
      FlapFlight2.Caption:=' ';
      FlapFlight3.Caption:=' ';
      FlapFlight4.Caption:=' ';
      FlapAirline.Caption:=' ';
      FlapAirline.Visible:=FALSE;     //some bmp da cia
      FlapEscala.Subtexts.Clear;
      FlapEscala.Caption:='';
      Led1.Play:=FALSE;               //pára piscação de leds, se não tem voo
      Led1.Frame:=0;
    end;
end;

procedure TFormDisplayPortao.Configuracao1Click(Sender: TObject);
begin
  FormAirportDisplayControl.Show;
end;

procedure TFormDisplayPortao.Sobre1Click(Sender: TObject);
begin
  FormAirportDisplaySplash := TFormAirportDisplaySplash.Create(nil);
  FormAirportDisplaySplash.ShowModal;
  FormAirportDisplaySplash.Free;
  FormAirportDisplaySplash:=nil;
end;

procedure TFormDisplayPortao.Termina1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFormDisplayPortao.Timer1Timer(Sender: TObject);
var sHora:String;
begin
  if Visible then //so renderiza relogio se janela visivel
    begin
      sHora:=FormatDateTime('hh:nn',time); //tipo '09:15'
      FlapHoraHH.Caption:=sHora[1]; FlapHoraH.Caption:=sHora[2];
      FlapHoraMM.Caption:=sHora[4]; FlapHoraM.Caption:=sHora[5];
    end;
end;

end.

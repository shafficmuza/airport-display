unit fADScreenSaver; // AirportDisplay - (c)copr. 02-12 Omar Reis   //
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TFormADScreenSaver = class(TForm)
    LAirportDisplay: TLabel;
    TimerScreenSaver: TTimer;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimerScreenSaverTimer(Sender: TObject);
  private
  public
    Procedure Desmagnetiza(Segundos:integer);
  end;

var
  FormADScreenSaver: TFormADScreenSaver;

implementation

{$R *.DFM}

procedure TFormADScreenSaver.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Close;
end;

procedure TFormADScreenSaver.TimerScreenSaverTimer(Sender: TObject);
begin
  //Move label, para nao ficar gastando o monitor no mesmo local
  //O default do label é Top=240 e Left=200
  if Visible then
    begin
      LAirportDisplay.Left:=200-50+Random(100);
      LAirportDisplay.Top:=240-50+Random(100);
    end;
end;

//Isso apaga o display de plasma por alguns segundos, para desmagnetizar a coisa
procedure TFormADScreenSaver.Desmagnetiza(Segundos: integer);
var D:TDateTime;
begin
  LAirportDisplay.Visible:=FALSE;
  D:=Now+Segundos/24/3600;
  Visible:=TRUE;
  while Now<D do Application.ProcessMessages; //espera em loop
  Visible:=FALSE;
  LAirportDisplay.Visible:=TRUE;
end;

end.

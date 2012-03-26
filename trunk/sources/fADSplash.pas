unit fADSplash;     // AirportDisplay - (c)copr. 02-12 Omar Reis   
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/


{..$DEFINE AirportMediaCenter}

interface
uses Forms, Classes, Controls, StdCtrls, ExtCtrls, Graphics;

Type
  TFormAirportDisplaySplash = class(TForm)
    Panel1: TPanel;
    TimerClose: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormDeactivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerCloseTimer(Sender: TObject);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
  end;

var FormAirportDisplaySplash: TFormAirportDisplaySplash;

implementation
{$R *.DFM}

procedure TFormAirportDisplaySplash.FormDeactivate(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

procedure TFormAirportDisplaySplash.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TFormAirportDisplaySplash.TimerCloseTimer(Sender: TObject);
begin
  Close;
end;

procedure TFormAirportDisplaySplash.Panel1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Close; //click to close
end;

initialization  {show splash during initialization}
  {$IFNDEF AirportMediaCenter}
  Screen.Cursor := crHourGlass;
  FormAirportDisplaySplash := TFormAirportDisplaySplash.Create(nil);
  FormAirportDisplaySplash.Tag:=1; //??
  FormAirportDisplaySplash.TimerClose.Enabled:=TRUE; //isso fecha depois de 5 segs
  FormAirportDisplaySplash.Show;
  FormAirportDisplaySplash.Update;
  {$ENDIF AirportMediaCenter}
end.

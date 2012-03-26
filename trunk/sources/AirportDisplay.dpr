program AirportDisplay; // AirportDisplay - (c)copr. 02-12 Omar Reis
// Airport display is released by Omar Reis <omar@tecepe.com.br>
// under Mozilla Public License.  see http://www.mozilla.org/MPL/


uses
  Forms,
  fADSplash,
  fAirportDisplay in 'fAirportDisplay.pas' {FormAirportDisplay},
  fDownloadInformacaoDeVoo in 'fDownloadInformacaoDeVoo.pas' {FormDownloadInfoVoo},
  fADScreenSaver in 'fADScreenSaver.pas' {FormADScreenSaver},
  fDisplayPortao in 'fDisplayPortao.pas' {FormDisplayPortao};

//define em fADSplash.pas, var bEhAirportDisplay em fDownloadInformacaoDeVoo.pas,

{$R *.RES}

var bFastLoop:boolean=FALSE;

begin
  Application.Initialize;
  Application.ShowMainForm:=FALSE;     //só mostra o display realmente ativo (ad or gate)
  //AD mainform
  Application.CreateForm(TFormAirportDisplay, FormAirportDisplay);  //  <----------------- main form (carregada primeiro)
  Application.CreateForm(TFormAirportDisplayControl, FormAirportDisplayControl);             //  <----esse cara controla os displays
  Application.CreateForm(TFormADScreenSaver,         FormADScreenSaver);                     //  protetor de tela
  Application.CreateForm(TFormDisplayPortao,         FormDisplayPortao);                     //  display de portão
  // o display 3D só cria se for usar mesmo, pois ele tem inicialização lenta.....
  FormAirportDisplayControl.MostraFormDeDisplay;                   //mostra o form de display selecionado na config
  if bFastLoop then FormAirportDisplay.FasterMessageLoop
    else Application.Run;
end.


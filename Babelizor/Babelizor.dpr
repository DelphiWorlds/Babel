program Babelizor;

{$R 'Data.res' 'Data.rc'}

uses
  Vcl.Forms,
  BZ.View.Main in 'Views\BZ.View.Main.pas' {MainView},
  BZ.View.AddLanguage in 'Views\BZ.View.AddLanguage.pas' {AddLanguageView},
  BZ.View.AddTexts in 'Views\BZ.View.AddTexts.pas' {AddTextsView};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainView, MainView);
  Application.Run;
end.

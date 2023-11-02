program BasicDemo;

{$R 'Data.res' 'Data.rc'}

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  BasicDemo.Babel in 'BasicDemo.Babel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    FirstButton: TButton;
    SecondButton: TButton;
    SelectFileLabel: TLabel;
    SelectFileButton: TButton;
    JSONOpenDialog: TOpenDialog;
    procedure SelectFileButtonClick(Sender: TObject);
    procedure FirstButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  BasicDemo.Babel;

resourcestring
  sYouClickedButton = 'You clicked the button named: %s';

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited;
  // Next line is useful for testing translations. Comment the line so that the machine configured language is used
  Babel.FakeCode := 'de';
  // Translate translatable properties in the form itself, where there are values for the target language in the resource
  Babel.Translate(Self);
end;

procedure TForm1.FirstButtonClick(Sender: TObject);
begin
  // Dynamically translate the text where there are values for the target language in the resource
  ShowMessage(Format(Babel.Tx(sYouClickedButton), [TComponent(Sender).Name]));
end;

procedure TForm1.SelectFileButtonClick(Sender: TObject);
begin
  JSONOpenDialog.Execute;
end;

end.

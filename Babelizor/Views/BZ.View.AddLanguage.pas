unit BZ.View.AddLanguage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Babel.Types;

type
  TAddLanguageView = class(TForm)
    CommandButtonsPanel: TPanel;
    CancelButton: TButton;
    OKButton: TButton;
    CodesComboBox: TComboBox;
    procedure OKButtonClick(Sender: TObject);
  private
    FCodes: TBabelLanguageCodes;
    FSelectedCode: TBabelLanguageCodeItem;
  protected
    procedure DoShow; override;
  public
    property Codes: TBabelLanguageCodes read FCodes;
    property SelectedCode: TBabelLanguageCodeItem read FSelectedCode;
  end;

var
  AddLanguageView: TAddLanguageView;

implementation

{$R *.dfm}

uses
  Babel.Locale;

{ TAddLanguageView }

procedure TAddLanguageView.DoShow;
var
  I: Integer;
begin
  inherited;
  CodesComboBox.Items.Clear;
  for I := 0 to FCodes.Count - 1 do
    CodesComboBox.Items.Add(FCodes.Items[I].DisplayValue);
  CodesComboBox.ItemIndex := FCodes.IndexOf(TLocale.GetInfo.LanguageCode);
  if CodesComboBox.ItemIndex = -1 then
    CodesComboBox.ItemIndex := 0;
  CodesComboBox.SelectAll;
  CodesComboBox.SetFocus;
end;

procedure TAddLanguageView.OKButtonClick(Sender: TObject);
begin
  FSelectedCode := FCodes.Items[CodesComboBox.ItemIndex];
  FCodes.Remove(FSelectedCode.Code);
end;

end.

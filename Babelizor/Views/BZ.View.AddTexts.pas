unit BZ.View.AddTexts;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.CheckLst;

type
  TAddTextsView = class(TForm)
    CommandButtonsPanel: TPanel;
    CancelButton: TButton;
    OKButton: TButton;
    TextsCheckListBox: TCheckListBox;
    ToggleButton: TButton;
    procedure ToggleButtonClick(Sender: TObject);
    procedure TextsCheckListBoxClickCheck(Sender: TObject);
  private
    function GetSelectedTexts: TArray<string>;
  protected
    procedure DoShow; override;
  public
    property SelectedTexts: TArray<string> read GetSelectedTexts;
  end;

var
  AddTextsView: TAddTextsView;

implementation

{$R *.dfm}

uses
  DW.Vcl.ListBoxHelper;

{ TAddTextsView }

procedure TAddTextsView.DoShow;
begin
  inherited;
  TextsCheckListBox.CheckAll(TCheckBoxState.cbChecked);
end;

function TAddTextsView.GetSelectedTexts: TArray<string>;
var
  I: Integer;
begin
  for I := 0 to TextsCheckListBox.Items.Count - 1 do
  begin
    if TextsCheckListBox.Checked[I] then
      Result := Result + [TextsCheckListBox.Items[I]];
  end;
end;

procedure TAddTextsView.TextsCheckListBoxClickCheck(Sender: TObject);
begin
  OKButton.Enabled := TextsCheckListBox.CheckedCount > 0;
end;

procedure TAddTextsView.ToggleButtonClick(Sender: TObject);
begin
  TextsCheckListBox.ToggleChecked;
  OKButton.Enabled := TextsCheckListBox.CheckedCount > 0;
end;

end.

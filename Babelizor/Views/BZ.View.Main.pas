unit BZ.View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.ImageList,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ToolWin, Vcl.ImgList,
  DelphiAST.Classes,
  Babel.Types,
  BZ.View.AddLanguage;

type
  TStringGrid = class(Vcl.Grids.TStringGrid)
  public
    procedure EnsureColCount(const AColCount, AWidth: Integer);
  end;

  TGoogleTranslateRequest = class;

  TGoogleTranslateResponseProc = reference to procedure(const ARequest: TGoogleTranslateRequest);

  TGoogleTranslateRequest = class(TObject)
  private
    procedure InternalTranslate(const AResponseProc: TGoogleTranslateResponseProc);
  public
    Col: Integer;
    DefaultCode: string;
    Row: Integer;
    TranslateCode: string;
    TranslateText: string;
    Translation: string;
    Text: string;
    procedure Translate(const AResponseProc: TGoogleTranslateResponseProc);
  end;

  TMainView = class(TForm)
    MainMenu: TMainMenu;
    FileMenuItem: TMenuItem;
    FileNewMenuItem: TMenuItem;
    S1: TMenuItem;
    MainMenuActionList: TActionList;
    FileNewAction: TAction;
    FileExitMenuItem: TMenuItem;
    FileExitAction: TAction;
    FileOpenAction: TAction;
    FileOpenMenuItem: TMenuItem;
    TextsActionList: TActionList;
    TextAddAction: TAction;
    OpenDialog: TFileOpenDialog;
    TextsPanel: TPanel;
    TextsGrid: TStringGrid;
    LanguageDeleteAction: TAction;
    CodesComboBox: TComboBox;
    TextsToolBar: TToolBar;
    AddTextToolButton: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    LanguageAddToolButton: TToolButton;
    LanguageDeleteToolButton: TToolButton;
    TextDeleteAction: TAction;
    LanguageAddAction: TAction;
    TextDeleteToolButton: TToolButton;
    TextsImageList: TImageList;
    TextsPopupMenu: TPopupMenu;
    SaveDialog: TFileSaveDialog;
    FileSaveAction: TAction;
    FileSaveMenuItem: TMenuItem;
    N1: TMenuItem;
    ToolButton1: TToolButton;
    TranslateToolButton: TToolButton;
    TranslateAction: TAction;
    ImportTextsAction: TAction;
    ImportComponentsToolButton: TToolButton;
    ComponentsOpenDialog: TFileOpenDialog;
    UseDefaultValueMenuItem: TMenuItem;
    UseDefaultValueAction: TAction;
    procedure FileNewActionExecute(Sender: TObject);
    procedure LanguageDeleteActionExecute(Sender: TObject);
    procedure LanguageAddActionExecute(Sender: TObject);
    procedure TextAddActionExecute(Sender: TObject);
    procedure TextDeleteActionExecute(Sender: TObject);
    procedure TextsActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure CodesComboBoxChange(Sender: TObject);
    procedure FileSaveActionExecute(Sender: TObject);
    procedure FileExitActionExecute(Sender: TObject);
    procedure FileOpenActionExecute(Sender: TObject);
    procedure TranslateActionExecute(Sender: TObject);
    procedure ImportTextsActionExecute(Sender: TObject);
  private
    FAddLanguageView: TAddLanguageView;
    FBabel: TBabel;
    FBase: TBabel;
    FBaseCodes: TBabelLanguageCodes;
    FCodes: TBabelLanguageCodes;
    FTexts: TArray<string>;
    procedure AddTexts(const ATexts: TArray<string>);
    procedure GetComponentTexts(const AFileName: string; var ATexts: TArray<string>);
    function GetDefaultTexts: TArray<string>;
    function GetNodeValue(const ANode: TSyntaxNode): string;
    procedure GetResourcestringTexts(const AFileName: string; var ATexts: TArray<string>);
    procedure GetSectionResourcestringTexts(const ASectionNode: TSyntaxNode; var ATexts: TArray<string>);
    procedure LoadComboBox;
    procedure NewBabel;
    procedure RefocusGrid(const ACol, ARow: Integer);
    procedure ResetGrid;
    procedure SelectRowWithDefault(const AValue: string);
    procedure SortGrid;
    procedure UpdateCell(const ACol, ARow: Integer; const AText, ATranslation: string);
    procedure UpdateTranslatedCell(const ARequest: TGoogleTranslateRequest);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainView: TMainView;

implementation

{$R *.dfm}

uses
  System.Net.HTTPClient, System.JSON, System.IOUtils, System.StrUtils, System.Character, System.Generics.Defaults, System.Generics.Collections,
  DelphiAST, DelphiAST.Consts,
  DW.OSDevice, DW.Types.Helpers, DW.Vcl.DialogService, DW.Classes.Helpers, DW.IOUtils.Helpers,
  Babel.Persistence,
  BZ.View.AddTexts;

const
  cGoogleTranslateURLTemplate = 'https://translation.googleapis.com/language/translate/v2?key=%s';
  cGoogleTranslateAPIKey = 'AIzaSyA3K6KKMG74dkqPdvn5TCtWZzebJgdW_n8'; // AIzaSyDiPVYE-gzEJEfB0ldrZXOEPM0n7e80r0g

type
  TBabelAST = class(TPasSyntaxTreeBuilder)
  private
    function RunNoMessages(const ASource: TStream): TSyntaxNode;
  public
    class function RunSource(const AFileName: string): TSyntaxNode;
  end;

function StartsWithTranslatableProp(const AValue: string): Boolean;
var
  LPropName: string;
begin
  Result := False;
  for LPropName in cTranslatablePropNames do
  begin
    if AValue.StartsWith(LPropName + ' =') then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function GridRectCell(const ACol, ARow: Integer): TGridRect;
begin
  Result.Left := ACol;
  Result.Right := ACol;
  Result.Top := ARow;
  Result.Bottom := ARow;
end;

function GetLanguageCode(const ASource: string): string;
var
  LParts: TArray<string>;
begin
  LParts := ASource.Split(['(', ')'], 3);
  if LParts.Count > 1 then
    Result := LParts[1];
end;

{ TBabelAST }

function TBabelAST.RunNoMessages(const ASource: TStream): TSyntaxNode;
begin
  Result := TSyntaxNode.Create(ntUnit);
  FStack.Clear;
  FStack.Push(Result);
  try
    inherited Run('', ASource);
  finally
    FStack.Pop;
  end;
end;

class function TBabelAST.RunSource(const AFileName: string): TSyntaxNode;
var
  LBuilder: TBabelAST;
  LStream: TMemoryStream;
begin
  Result := nil;
  if TFile.Exists(AFileName) then
  begin
    LStream := TMemoryStream.Create;
    try
      LStream.LoadFromFile(AFileName);
      LStream.Position := 0;
      LBuilder := TBabelAST.Create;
      try
        Result := LBuilder.RunNoMessages(LStream);
      finally
        LBuilder.Free;
      end;
    finally
      LStream.Free;
    end;
  end;
end;

{ TGoogleTranslateRequest }

procedure TGoogleTranslateRequest.InternalTranslate(const AResponseProc: TGoogleTranslateResponseProc);
var
  LHTTP: THTTPClient;
  LHTTPResponse: IHTTPResponse;
  LJSON: TJSONObject;
  LValue: TJSONValue;
  LTranslations: TJSONArray;
  LRequest, LResponse, LTranslation: string;
  LStream: TStringStream;
begin
  LResponse := '';
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('q', TranslateText);
    LJSON.AddPair('source', DefaultCode);
    LJSON.AddPair('target', TranslateCode);
    LJSON.AddPair('format', 'text');
    LRequest := LJSON.ToJSON;
  finally
    LJSON.Free;
  end;
  LStream := TStringStream.Create(LRequest);
  try
    LHTTP := THTTPClient.Create;
    try
      LHTTPResponse := LHTTP.Post(Format(cGoogleTranslateURLTemplate, [cGoogleTranslateAPIKey]), LStream);
      if LHTTPResponse.StatusCode = 200 then
        LResponse := LHTTPResponse.ContentAsString;
    finally
      LHTTP.Free;
    end;
  finally
    LStream.Free;
  end;
  if not LResponse.IsEmpty then
  begin
    LJSON := TJSONObject.ParseJSONValue(LResponse) as TJSONObject;
    if LJSON <> nil then
    try
      if LJSON.TryGetValue('data', LValue) and LValue.TryGetValue('translations', LValue) and (LValue is TJSONArray) then
      begin
        LTranslations := TJSONArray(LValue);
        if (LTranslations.Count > 0) and LTranslations.Items[0].TryGetValue('translatedText', LValue) then
        begin
          Translation := LValue.Value;
          TDo.Sync(procedure begin AResponseProc(Self); end);
        end;
      end;
    finally
      LJSON.Free;
    end;
  end;
end;

procedure TGoogleTranslateRequest.Translate(const AResponseProc: TGoogleTranslateResponseProc);
begin
  TDo.Run(procedure begin InternalTranslate(AResponseProc); end);
end;

{ TStringGrid }

procedure TStringGrid.EnsureColCount(const AColCount, AWidth: Integer);
var
  LColCount, I: Integer;
begin
  if ColCount < AColCount then
  begin
    LColCount := ColCount;
    ColCount := AColCount;
    for I := LColCount to AColCount - 1 do
      ColWidths[I] := AWidth;
  end;
end;

{ TMainView }

constructor TMainView.Create(AOwner: TComponent);
begin
  inherited;
  FAddLanguageView := TAddLanguageView.Create(Self);
  FBaseCodes.LoadFromResource;
  FCodes := FBaseCodes;
  LoadComboBox;
  NewBabel;
  FBase.LoadFromFile(TPathHelper.GetAppDocumentsFile('lang.json'));
end;

procedure TMainView.LoadComboBox;
var
  I: Integer;
begin
  CodesComboBox.Items.Clear;
  for I := 0 to FCodes.Count - 1 do
    CodesComboBox.Items.Add(FCodes.Items[I].DisplayValue);
  CodesComboBox.ItemIndex := FCodes.IndexOf(TOSDevice.GetCurrentLocaleInfo.LanguageCode);
end;

procedure TMainView.CodesComboBoxChange(Sender: TObject);
begin
//  // If there's a column with the selected language, swap it with default
//  FBabel.Code := TBabelLanguageCodes.Current.Codes[CodesComboBox.ItemIndex].Code;
//  UpdateCodes;
end;

procedure TMainView.NewBabel;
begin
  FBabel.Code := FCodes.Items[CodesComboBox.ItemIndex].Code;
  ResetGrid;
  FAddLanguageView.Codes.CopyFrom(FCodes);
  FAddLanguageView.Codes.Remove(FBabel.Code);
end;

procedure TMainView.RefocusGrid(const ACol, ARow: Integer);
begin
  TextsGrid.Row := ARow;
  TextsGrid.Col := ACol;
  TextsGrid.Selection := GridRectCell(TextsGrid.Col, TextsGrid.Row);
  TextsGrid.SetFocus;
end;

procedure TMainView.ResetGrid;
begin
  TextsGrid.RowCount := 2; // Fixed row?
  TextsGrid.ColCount := 1;
  TextsGrid.ColWidths[0] := 150;
  TextsGrid.Cells[0, 0] := 'Default';
end;

procedure TMainView.TextAddActionExecute(Sender: TObject);
begin
  TextsGrid.RowCount := TextsGrid.RowCount + 1;
  RefocusGrid(0, TextsGrid.RowCount - 1);
end;

procedure TMainView.TextDeleteActionExecute(Sender: TObject);
var
  LSelectedRow: Integer;
begin
  if TDialog.Confirm('Delete the selected row?', True) then
  begin
    LSelectedRow := TextsGrid.Row;
    TextsGrid.DeleteRow(TextsGrid.Row);
    RefocusGrid(1, LSelectedRow - 1);
  end;
end;

procedure TMainView.TextsActionListUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  TextDeleteAction.Enabled := TextsGrid.Row > 1;
  LanguageDeleteAction.Enabled := TextsGrid.Col > 0;
  TranslateAction.Enabled := TextsGrid.Row > 0;
end;

procedure TMainView.TranslateActionExecute(Sender: TObject);
var
  I : Integer;
  LRequest: TGoogleTranslateRequest;
  LCode, LText, LTranslateText, LTranslation: string;
begin
  LText := TextsGrid.Cells[0, TextsGrid.Row];
  if (TextsGrid.Col = 0) and (TextsGrid.InplaceEditor <> nil) and not TextsGrid.InplaceEditor.SelText.IsEmpty then
    LText := TextsGrid.InplaceEditor.SelText;
  // i.e. LText is the part that is being replaced, LTranslateText is the same text with stupid chars removed
  LTranslateText := LText.Replace('&', '', [rfReplaceAll]);
  for I := 1 to TextsGrid.ColCount - 1 do
  begin
    LCode := GetLanguageCode(TextsGrid.Cells[I, 0]);
    if TextsGrid.Cells[I, TextsGrid.Row].IsEmpty then
    begin
      LTranslation := FBase.Translate(LTranslateText, LCode, True);
      if LTranslation.IsEmpty then
      begin
        LRequest := TGoogleTranslateRequest.Create;
        LRequest.Text := LText;
        LRequest.TranslateText := LTranslateText;
        LRequest.DefaultCode := FBabel.Code;
        LRequest.TranslateCode := LCode;
        LRequest.Row := TextsGrid.Row;
        LRequest.Col := I;
        LRequest.Translate(UpdateTranslatedCell);
      end
      else
        UpdateCell(I, TextsGrid.Row, LText, LTranslation);
    end;
  end;
end;

procedure TMainView.UpdateTranslatedCell(const ARequest: TGoogleTranslateRequest);
begin
  UpdateCell(ARequest.Col, ARequest.Row, ARequest.Text, ARequest.Translation);
  ARequest.Free;
end;

procedure TMainView.UpdateCell(const ACol, ARow: Integer; const AText, ATranslation: string);
var
  LWholeText, LReplacement: string;
begin
  LWholeText := TextsGrid.Cells[0, ARow];
  LReplacement := ATranslation;
  // If just one word, make sure the capitalization applies
  if (Length(AText.Split([' '])) = 1) and AText.Chars[0].IsUpper then
    LReplacement := LReplacement.Chars[0].ToUpper + LReplacement.Substring(1);
  // Part is being replaced
  if LWholeText <> AText then
    LReplacement := LWholeText.Replace(AText, LReplacement);
  TextsGrid.Cells[ACol, ARow] := LReplacement;
end;

procedure TMainView.LanguageAddActionExecute(Sender: TObject);
begin
  if FAddLanguageView.ShowModal = mrOK then
  begin
    FBabel.Languages := FBabel.Languages + [FAddLanguageView.SelectedCode.Code];
    TextsGrid.ColCount := TextsGrid.ColCount + 1;
    TextsGrid.ColWidths[TextsGrid.ColCount - 1] := 150;
    TextsGrid.Cells[TextsGrid.ColCount - 1, 0] := FAddLanguageView.SelectedCode.DisplayValue;
    RefocusGrid(TextsGrid.ColCount - 1, 1);
  end;
end;

procedure TMainView.LanguageDeleteActionExecute(Sender: TObject);
var
  LSelectedCol: Integer;
begin
  if TDialog.Confirm('Delete the selected language?', True) then
  begin
    LSelectedCol := TextsGrid.Col;
    TextsGrid.DeleteColumn(TextsGrid.Col);
    RefocusGrid(LSelectedCol - 1, 1);
  end;
end;

procedure TMainView.FileExitActionExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainView.FileNewActionExecute(Sender: TObject);
begin
  //!!!! Check if current one is modified
  NewBabel;
end;

procedure TMainView.FileOpenActionExecute(Sender: TObject);
var
  I, J, LIndex: Integer;
  LText: TBabelTextItem;
  LItem: TBabelLanguageCodeItem;
begin
  //!!!! Check if current one is modified
  if OpenDialog.Execute then
  begin
    FAddLanguageView.Codes.CopyFrom(FCodes);
    FBabel.LoadFromFile(OpenDialog.FileName);
    FAddLanguageView.Codes.Remove(FBabel.Code);
    FAddLanguageView.Codes.Remove(FBabel.Languages);
    CodesComboBox.ItemIndex := FCodes.IndexOf(FBabel.Code);
    ResetGrid;
    TextsGrid.EnsureColCount(FBabel.Languages.Count + 1, 150);
    for I := 0 to FBabel.Languages.Count - 1 do
    begin
      LIndex := FBaseCodes.IndexOf(FBabel.Languages[I]);
      LItem := FBaseCodes.Items[LIndex];
      // TextsGrid.Cells[I + 1, 0] := LCodes.Items[LCodes.IndexOf(FBabel.Languages[I])].DisplayValue;
      TextsGrid.Cells[I + 1, 0] := LItem.DisplayValue;
    end;
    for I := 0 to FBabel.Texts.Count - 1 do
    begin
      LText := FBabel.Texts.Items[I];
      TextsGrid.RowCount := I + 2;
      TextsGrid.Cells[0, I + 1] := LText.Default;
      for J := 0 to LText.Lookups.Count - 1 do
        TextsGrid.Cells[J + 1, I + 1] := LText.Lookups.Items[J].Value;
    end;
  end;
end;

procedure TMainView.FileSaveActionExecute(Sender: TObject);
var
  I, J: Integer;
  LText: TBabelTextItem;
begin
  if SaveDialog.Execute then
  begin
    FBabel.Texts.Clear;
    for I := 1 to TextsGrid.RowCount - 1 do
    begin
      LText.Default := TextsGrid.Cells[0, I];
      LText.Lookups.Clear;
      for J := 1 to TextsGrid.ColCount - 1 do
        LText.Lookups.Add(GetLanguageCode(TextsGrid.Cells[J, 0]), TextsGrid.Cells[J, I]);
      FBabel.Texts.Add(LText);
    end;
    FBabel.SaveToFile(SaveDialog.FileName);
  end;
end;

procedure TMainView.GetComponentTexts(const AFileName: string; var ATexts: TArray<string>);
var
  LReader: TStreamReader;
  LLine: string;
  LParts: TArray<string>;
begin
  LReader := TStreamReader.Create(AFileName);
  try
    while not LReader.EndOfStream do
    begin
      LLine := LReader.ReadLine.Trim;
      if StartsWithTranslatableProp(LLine) and LLine.EndsWith('''') then
      begin
        LLine := LLine.Substring(LLine.IndexOf('''') + 1);
        LLine := TBabel.GetText(LLine.Substring(0, LLine.Length - 1).Trim);
        if not LLine.IsEmpty and (FTexts.IndexOf(LLine) = -1) then
          ATexts.Add(LLine, False);
      end;
    end;
  finally
    LReader.Free;
  end;
end;

function TMainView.GetNodeValue(const ANode: TSyntaxNode): string;
var
  I, J: Integer;
  LValueNode: TSyntaxNode;
begin
  Result := '';
  for I := 0 to High(ANode.ChildNodes) do
  begin
    if ANode.ChildNodes[I].Typ = TSyntaxNodeType.ntValue then
    begin
      LValueNode := ANode.ChildNodes[I];
      for J := 0 to High(LValueNode.ChildNodes) do
      begin
        if LValueNode.ChildNodes[J] is TValuedSyntaxNode then
        begin
          Result := TValuedSyntaxNode(LValueNode.ChildNodes[J]).Value;
          Break;
        end;
      end;
      Break;
    end;
  end;
end;

procedure TMainView.GetResourcestringTexts(const AFileName: string; var ATexts: TArray<string>);
var
  LNode, LSectionNode: TSyntaxNode;
begin
  LNode := TBabelAST.RunSource(AFileName);
  try
    LSectionNode := LNode.FindNode(TSyntaxNodeType.ntInterface);
    if LSectionNode <> nil then
      GetSectionResourcestringTexts(LSectionNode, ATexts);
    LSectionNode := LNode.FindNode(TSyntaxNodeType.ntImplementation);
    if LSectionNode <> nil then
      GetSectionResourcestringTexts(LSectionNode, ATexts);
  finally
    LNode.Free;
  end;
end;

procedure TMainView.GetSectionResourcestringTexts(const ASectionNode: TSyntaxNode; var ATexts: TArray<string>);
var
  LChildNode, LConstantNode: TSyntaxNode;
  I, J: Integer;
  LValue: string;
begin
  for I := 0 to High(ASectionNode.ChildNodes) do
  begin
    LChildNode := ASectionNode.ChildNodes[I];
    if LChildNode.Typ = TSyntaxNodeType.ntConstants then
    begin
      for J := 0 to High(LChildNode.ChildNodes) do
      begin
        LConstantNode := LChildNode.ChildNodes[J];
        if LConstantNode.Typ = TSyntaxNodeType.ntResourceString then
        begin
          LValue := GetNodeValue(LConstantNode);
          if FTexts.IndexOf(LValue) = -1 then
            ATexts.Add(GetNodeValue(LConstantNode), False);
        end;
      end;
    end;
  end;
end;

function TMainView.GetDefaultTexts: TArray<string>;
var
  I: Integer;
begin
  for I := 1 to TextsGrid.RowCount - 1 do
  begin
    if not TextsGrid.Cells[0, I].IsEmpty then
      Result := Result + [TextsGrid.Cells[0, I]];
  end;
end;

procedure TMainView.ImportTextsActionExecute(Sender: TObject);
var
  LFileName, LExt: string;
  LTexts: TArray<string>;
  LView: TAddTextsView;
begin
  if ComponentsOpenDialog.Execute then
  begin
    FTexts := GetDefaultTexts;
    for LFileName in TDirectory.GetFiles(ComponentsOpenDialog.FileName, '*.*', TSearchOption.soAllDirectories) do
    begin
      LExt := TPath.GetExtension(LFileName).ToLower;
      if LExt.Equals('.fmx') or LExt.Equals('.dfm') and TFile.Exists(TPath.ChangeExtension(LFileName, '.pas')) then
        GetComponentTexts(LFileName, LTexts);
      if LExt.Equals('.pas') then
        GetResourcestringTexts(LFileName, LTexts);
    end;
    if LTexts.Count > 0 then
    begin
      LTexts.Sort;
      LView := TAddTextsView.Create(nil);
      try
        LTexts.AssignToStrings(LView.TextsCheckListBox.Items);
        if LView.ShowModal = mrOK then
          AddTexts(LView.SelectedTexts);
      finally
        LView.Free;
      end;
    end;
  end;
end;

procedure TMainView.SelectRowWithDefault(const AValue: string);
var
  I: Integer;
begin
  for I := 1 to TextsGrid.RowCount - 1 do
  begin
    if TextsGrid.Cells[0, I] = AValue then
    begin
      TextsGrid.Row := I;
      Break;
    end;
  end;
end;

procedure TMainView.AddTexts(const ATexts: TArray<string>);
var
  I, LFirstRow: Integer;
  LDefault: string;
begin
  if (TextsGrid.RowCount = 2) and (TextsGrid.Cells[0, 1] = '') then
    TextsGrid.RowCount := 1;
  LFirstRow := TextsGrid.RowCount;
  TextsGrid.RowCount := TextsGrid.RowCount + ATexts.Count;
  LDefault := TextsGrid.Cells[0, TextsGrid.Row];
  TextsGrid.BeginUpdate;
  try
    for I := 0 to ATexts.Count - 1 do
      TextsGrid.Cells[0, LFirstRow + I] := ATexts[I];
  finally
    TextsGrid.EndUpdate;
  end;
  SortGrid;
  SelectRowWithDefault(LDefault);
  RefocusGrid(0, TextsGrid.Row);
end;

procedure TMainView.SortGrid;
type
  TValues = TArray<string>;
var
  I, J: Integer;
  LGridValues: TArray<TValues>;
  LComparer: IComparer<TValues>;
begin
  SetLength(LGridValues, TextsGrid.RowCount - 1); // not sorting row 0
  for I := 1 to TextsGrid.RowCount - 1 do
    LGridValues[I - 1] := TextsGrid.Rows[I].ToStringArray;
  LComparer := TDelegatedComparer<TValues>.Create(
    function(const Left, Right: TValues): Integer
    begin
      Result := CompareStr(Left[0], Right[0]);
    end
  );
  TArray.Sort<TValues>(LGridValues, LComparer);
  TextsGrid.BeginUpdate;
  try
    for I := 1 to TextsGrid.RowCount - 1 do
    begin
      for J := 0 to High(LGridValues[I - 1]) do
        TextsGrid.Cells[J, I] := LGridValues[I - 1][J];
    end;
  finally
    TextsGrid.EndUpdate;
  end;
end;


end.

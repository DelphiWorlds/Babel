unit BZ.Options;

interface

uses
  System.JSON;

type
  TBabelizorOptions = record
  private
    procedure ReadJSON(const AValue: TJSONValue);
  public
    TranslateAPIKey: string;
    procedure Load;
  end;

var
  Options: TBabelizorOptions;

implementation

uses
  System.IOUtils, System.SysUtils,
  DW.IOUtils.Helpers;

{ TBabelizorOptions }

procedure TBabelizorOptions.Load;
var
  LFileName: string;
  LJSON: TJSONValue;
begin
  LFileName := TPathHelper.GetAppDocumentsFile('options.json');
  if TFile.Exists(LFileName) then
  begin
    LJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(LFileName));
    if LJSON <> nil then
    try
      ReadJSON(LJSON);
    finally
      LJSON.Free;
    end;
  end;
end;

procedure TBabelizorOptions.ReadJSON(const AValue: TJSONValue);
begin
  AValue.TryGetValue('TranslateAPIKey', TranslateAPIKey);
end;

initialization
  Options.Load;

end.

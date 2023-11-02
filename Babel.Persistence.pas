unit Babel.Persistence;

{*******************************************************}
{                                                       }
{                      Babel                            }
{                                                       }
{          Cross-Platform Translation Library           }
{                 from Delphi Worlds                    }
{                                                       }
{  Copyright 2020-2023 Dave Nottage under MIT license   }
{  which is located in the root folder of this library  }
{                                                       }
{*******************************************************}

interface

uses
  System.JSON,
  Babel.Types;

type
  TBabelLanguageCodeItemHelper = record helper for TBabelLanguageCodeItem
    procedure FromJSONValue(const AValue: TJSONValue);
    function ToJSONValue: TJSONValue;
  end;

  TBabelLanguageCodesHelper = record helper for TBabelLanguageCodes
  public
    procedure FromJSON(const AJSON: string);
    procedure FromJSONValue(const AValue: TJSONValue);
    procedure LoadFromFile(const AFileName: string);
    procedure LoadFromResource(const AResourceName: string = '');
    procedure ReadItems(const AValues: TJSONArray);
    procedure SaveToFile(const AFileName: string);
    function ToJSON: string;
    function WriteItems: TJSONArray;
  end;

  TBabelLookupItemHelper = record helper for TBabelLookupItem
    procedure FromJSONValue(const AValue: TJSONValue);
    function ToJSONValue: TJSONValue;
  end;

  TBabelLookupsHelper = record helper for TBabelLookups
    procedure ReadItems(const AValues: TJSONArray);
    function WriteItems: TJSONArray;
  end;

  TBabelTextItemHelper = record helper for TBabelTextItem
    procedure FromJSONValue(const AValue: TJSONValue);
    function ToJSONValue: TJSONValue;
  end;

  TBabelTextsHelper = record helper for TBabelTexts
    procedure ReadItems(const AValues: TJSONArray);
    function WriteItems: TJSONArray;
  end;

  TBabelHelper = record helper for TBabel
  public
    procedure FromJSON(const AJSON: string);
    procedure FromJSONValue(const AValue: TJSONValue);
    function LoadFromFile(const AFileName: string): TBabel;
    procedure LoadFromResource(const AResourceName: string = '');
    procedure ReadLanguages(const AValues: TJSONArray);
    procedure Save;
    procedure SaveToFile(const AFileName: string);
    function ToJSON: string;
    function WriteLanguages: TJSONArray;
  end;

implementation

uses
  System.Classes, System.Types, System.SysUtils, System.IOUtils, System.Generics.Collections;

type
  TJSONValueHelper = class helper for TJSONValue
    function GetJSONArray(out AJSONArray: TJSONArray; const ALength: Integer = 0): Boolean;
  end;

{ TJSONValueHelper }

function TJSONValueHelper.GetJSONArray(out AJSONArray: TJSONArray; const ALength: Integer): Boolean;
begin
  Result := False;
  if (Self is TJSONArray) and ((ALength = 0) or (TJSONArray(Self).Count >= ALength)) then
  begin
    AJSONArray := TJSONArray(Self);
    Result := True;
  end;
end;

{ TBabelLanguageCodeItemHelper }

procedure TBabelLanguageCodeItemHelper.FromJSONValue(const AValue: TJSONValue);
var
  LArray: TJSONArray;
begin
  if AValue.GetJSONArray(LArray, 3) then
  begin
    Code := LArray.Items[0].Value;
    Name := LArray.Items[1].Value;
    NativeName := LArray.Items[2].Value;
  end;
end;

function TBabelLanguageCodeItemHelper.ToJSONValue: TJSONValue;
var
  LArray: TJSONArray;
begin
  LArray := TJSONArray.Create;
  LArray.Add(Code);
  LArray.Add(Name);
  LArray.Add(NativeName);
  Result := LArray;
end;

{ TBabelLanguageCodesHelper }

procedure TBabelLanguageCodesHelper.ReadItems(const AValues: TJSONArray);
var
  LValue: TJSONValue;
  LItem: TBabelLanguageCodeItem;
begin
  for LValue in AValues do
  begin
    LItem := Default(TBabelLanguageCodeItem);
    LItem.FromJSONValue(LValue);
    Items := Items + [LItem];
  end;
end;

procedure TBabelLanguageCodesHelper.FromJSON(const AJSON: string);
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := TJSONObject.ParseJSONValue(AJSON);
  if LJSONValue <> nil then
  try
    FromJSONValue(LJSONValue);
  finally
    LJSONValue.Free;
  end;
end;

procedure TBabelLanguageCodesHelper.FromJSONValue(const AValue: TJSONValue);
var
  LValues: TJSONArray;
begin
  if AValue.TryGetValue('codes', LValues) then
    ReadItems(LValues);
end;

procedure TBabelLanguageCodesHelper.LoadFromFile(const AFileName: string);
begin
  FromJSON(TFile.ReadAllText(AFileName));
end;

procedure TBabelLanguageCodesHelper.LoadFromResource(const AResourceName: string = '');
var
  LResourceStream: TStream;
  LStringStream: TStringStream;
  LResourceName: string;
begin
  if AResourceName.IsEmpty then
    LResourceName := 'language_codes';
  if FindResource(HInstance, PChar(LResourceName), RT_RCDATA) > 0 then
  begin
    LResourceStream := TResourceStream.Create(HInstance, LResourceName, RT_RCDATA);
    try
      LStringStream := TStringStream.Create;
      LStringStream.CopyFrom(LResourceStream, LResourceStream.Size);
      FromJSON(LStringStream.DataString);
    finally
      LResourceStream.Free;
    end;
  end;
end;

procedure TBabelLanguageCodesHelper.SaveToFile(const AFileName: string);
begin
  TFile.WriteAllText(AFileName, ToJSON);
end;

function TBabelLanguageCodesHelper.ToJSON: string;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    LJSONObject.AddPair('Items', WriteItems);
    Result := LJSONObject.ToJSON;
  finally
    LJSONObject.Free;
  end;
end;

function TBabelLanguageCodesHelper.WriteItems: TJSONArray;
var
  LItem: TBabelLanguageCodeItem;
begin
  Result := TJSONArray.Create;
  for LItem in Items do
    Result.AddElement(LItem.ToJSONValue);
end;

{ TBabelLookupItemHelper }

procedure TBabelLookupItemHelper.FromJSONValue(const AValue: TJSONValue);
var
  LArray: TJSONArray;
begin
  if AValue.GetJSONArray(LArray, 2) then
  begin
    Code := LArray.Items[0].Value;
    Value := LArray.Items[1].Value;
  end;
end;

function TBabelLookupItemHelper.ToJSONValue: TJSONValue;
var
  LArray: TJSONArray;
begin
  LArray := TJSONArray.Create;
  LArray.Add(Code);
  LArray.Add(Value);
  Result := LArray;
end;

{ TBabelLookupsHelper }

procedure TBabelLookupsHelper.ReadItems(const AValues: TJSONArray);
var
  LValue: TJSONValue;
  LItem: TBabelLookupItem;
begin
  for LValue in AValues do
  begin
    LItem := Default(TBabelLookupItem);
    LItem.FromJSONValue(LValue);
    Items := Items + [LItem];
  end;
end;

function TBabelLookupsHelper.WriteItems: TJSONArray;
var
  LItem: TBabelLookupItem;
begin
  Result := TJSONArray.Create;
  for LItem in Items do
    Result.AddElement(LItem.ToJSONValue);
end;

{ TBabelTextItemHelper }

procedure TBabelTextItemHelper.FromJSONValue(const AValue: TJSONValue);
var
  LArray: TJSONArray;
begin
  if AValue.GetJSONArray(LArray, 2) and (LArray.Items[1] is TJSONArray) then
  begin
    Default := LArray.Items[0].Value;
    Lookups.ReadItems(TJSONArray(LArray.Items[1]));
  end;
end;

function TBabelTextItemHelper.ToJSONValue: TJSONValue;
var
  LArray: TJSONArray;
begin
  LArray := TJSONArray.Create;
  LArray.Add(Default);
  LArray.Add(Lookups.WriteItems);
  Result := LArray;
end;

{ TBabelTextsHelper }

procedure TBabelTextsHelper.ReadItems(const AValues: TJSONArray);
var
  LItem: TBabelTextItem;
  LValue: TJSONValue;
begin
  for LValue in AValues do
  begin
    LItem := Default(TBabelTextItem);
    LItem.FromJSONValue(LValue);
    Items := Items + [LItem];
  end;
end;

function TBabelTextsHelper.WriteItems: TJSONArray;
var
  LItem: TBabelTextItem;
begin
  Result := TJSONArray.Create;
  for LItem in Items do
    Result.AddElement(LItem.ToJSONValue);
end;

{ TBabelHelper }

procedure TBabelHelper.FromJSON(const AJSON: string);
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := TJSONObject.ParseJSONValue(AJSON);
  if LJSONValue <> nil then
  try
    FromJSONValue(LJSONValue);
  finally
    LJSONValue.Free;
  end;
end;

procedure TBabelHelper.FromJSONValue(const AValue: TJSONValue);
var
  LValues: TJSONArray;
begin
  AValue.TryGetValue<string>('code', Code);
  if AValue.TryGetValue('languages', LValues) then
    ReadLanguages(LValues);
  if AValue.TryGetValue('texts', LValues) then
    Texts.ReadItems(LValues);
end;

function TBabelHelper.LoadFromFile(const AFileName: string): TBabel;
begin
  if TFile.Exists(AFileName) then
  begin
    FileName := AFileName;
    FromJSON(TFile.ReadAllText(FileName));
  end;
end;

procedure TBabelHelper.LoadFromResource(const AResourceName: string = '');
var
  LResourceStream: TStream;
  LStringStream: TStringStream;
  LResourceName: string;
begin
  if AResourceName.IsEmpty then
    LResourceName := 'babel';
  if FindResource(HInstance, PChar(LResourceName), RT_RCDATA) > 0 then
  begin
    LResourceStream := TResourceStream.Create(HInstance, LResourceName, RT_RCDATA);
    try
      LStringStream := TStringStream.Create;
      LStringStream.CopyFrom(LResourceStream, LResourceStream.Size);
      FromJSON(LStringStream.DataString);
    finally
      LResourceStream.Free;
    end;
  end;
end;

procedure TBabelHelper.ReadLanguages(const AValues: TJSONArray);
var
  LValue: TJSONValue;
begin
  for LValue in AValues do
    Languages := Languages + [LValue.Value];
end;

procedure TBabelHelper.Save;
begin
  if not FileName.IsEmpty then
    SaveToFile(FileName);
end;

procedure TBabelHelper.SaveToFile(const AFileName: string);
begin
  TFile.WriteAllText(AFileName, ToJSON);
end;

function TBabelHelper.WriteLanguages: TJSONArray;
var
  LLanguage: string;
begin
  Result := TJSONArray.Create;
  for LLanguage in Languages do
    Result.Add(LLanguage);
end;

function TBabelHelper.ToJSON: string;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    LJSONObject.AddPair('code', Code);
    LJSONObject.AddPair('languages', WriteLanguages);
    LJSONObject.AddPair('texts', Texts.WriteItems);
    Result := LJSONObject.ToJSON;
  finally
    LJSONObject.Free;
  end;
end;

end.

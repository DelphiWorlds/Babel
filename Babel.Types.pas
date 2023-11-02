unit Babel.Types;

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
  System.Classes, System.Generics.Defaults;

const
  cTranslatablePropNames: array[0..4] of string = (
    'Caption', 'Text', 'Hint', 'Title', 'Filter'
  );

type
  TBabelLanguageCodeItem = record
    Code: string;
    Name: string;
    NativeName: string;
    function DisplayValue: string;
  end;

  TBabelLanguageCodeItems = TArray<TBabelLanguageCodeItem>;

  TBabelLanguageCodes = record
  public
    Items: TBabelLanguageCodeItems;
    procedure Add(const ACode, AName, ANativeName: string);
    procedure CopyFrom(const ACodes: TBabelLanguageCodes);
    function Count: Integer;
    procedure Remove(const ACode: string); overload;
    procedure Remove(const ACodes: TArray<string>); overload;
    function IndexOf(const ACode: string): Integer;
  end;

  TBabelLookupItem = record
    Code: string;
    Value: string;
  end;

  TBabelLookupItems = TArray<TBabelLookupItem>;

  TBabelLookups = record
  public
    Items: TBabelLookupItems;
    procedure Add(const ACode, AValue: string);
    procedure Clear;
    function Count: Integer;
    function Lookup(const ACode: string): string;
  end;

  TBabelComponentProperty = record
    Name: string;
    Values: TBabelLookups;
  end;

  TBabelComponentProperties = TArray<TBabelComponentProperty>;

  TBabelTextItem = record
    Default: string;
    Lookups: TBabelLookups;
  end;

  TBabelTextItems = TArray<TBabelTextItem>;

  TBabelTexts = record
  private
    class var FComparer: IComparer<TBabelTextItem>;
  public
    Items: TBabelTextItems;
    procedure Add(const AItem: TBabelTextItem);
    procedure Clear;
    function Count: Integer;
    procedure Sort;
    function Translate(const ADefault: string; const ACode: string; const ADefaultBlank: Boolean): string;
  end;

  TBabelLanguages = TArray<string>;

  TBabel = record
  private
    function InternalTranslate(const ADefault: string; const ACode: string; const ADefaultBlank: Boolean): string;
    procedure TranslateComponent(const AComponent: TComponent; const ACode: string);
  public
    /// <summary>
    ///   Obtains the "translatable" part of the text
    /// </summary>
    /// <remarks>
    ///   Omits ending ellipsis (e.g. ... or ..) and colon
    /// </remarks>
    class function GetText(const AValue: string): string; static;
    /// <summary>
    ///   Indicates whether the text has two or more consecutive letters
    /// </summary>
    class function HasLetters(const AValue: string): Boolean; static;
  public
    Code: string;
    FakeCode: string;
    FileName: string;
    Languages: TBabelLanguages;
    Texts: TBabelTexts;
    function Tx(const ADefault: string; const ACode: string = ''): string;
    function Translate(const ADefault: string; const ACode: string = ''; const ADefaultBlank: Boolean = False): string; overload;
    procedure Translate(const AComponent: TComponent; const ACode: string = ''); overload;
  end;

implementation

uses
  System.SysUtils, System.TypInfo, System.StrUtils, System.Character, System.Generics.Collections,
  Babel.Locale;

type
  TBabelTextItemComparerByDefault = class(TInterfacedObject, IComparer<TBabelTextItem>)
  protected
    { IComparer<TBabelTextItem> }
    function Compare(const Left, Right: TBabelTextItem): Integer;
  end;

function IsStringProp(const AInstance: TObject; const APropName: string): Boolean;
begin
  Result := PropType(AInstance, APropName) in [TTypeKind.tkString, TTypeKind.tkLString, TTypeKind.tkWString];
end;

function CanTranslateProperty(const APropInfo: TPropInfo): Boolean;
var
  LName: string;
  LKind: TTypeKind;
begin
  LName := string(APropInfo.Name);
  LKind := APropInfo.PropType^.Kind;
  Result := MatchText(LName, cTranslatablePropNames) and
    (LKind in [TTypeKind.tkString, TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString]);
end;

{ TBabelTextItemComparerByDefault }

function TBabelTextItemComparerByDefault.Compare(const Left, Right: TBabelTextItem): Integer;
begin
  Result := string.CompareText(Left.Default, Right.Default);
end;

{ TBabelLanguageCodeItem }

function TBabelLanguageCodeItem.DisplayValue: string;
begin
  Result := Format('%s (%s)', [Name, Code]);
end;

{ TBabelLanguageCodes }

procedure TBabelLanguageCodes.Add(const ACode, AName, ANativeName: string);
var
  LCode: TBabelLanguageCodeItem;
begin
  LCode.Code := ACode;
  LCode.Name := AName;
  LCode.NativeName := ANativeName;
  Items := Items + [LCode];
end;

procedure TBabelLanguageCodes.CopyFrom(const ACodes: TBabelLanguageCodes);
begin
  Items := Copy(ACodes.Items);
end;

function TBabelLanguageCodes.Count: Integer;
begin
  Result := Length(Items);
end;

procedure TBabelLanguageCodes.Remove(const ACode: string);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(ACode);
  if LIndex > -1 then
    Delete(Items, LIndex, 1);
end;

procedure TBabelLanguageCodes.Remove(const ACodes: TArray<string>);
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
  begin
    if IndexStr(Items[I].Code, ACodes) > -1 then
      Delete(Items, I, 1);
  end;
end;

function TBabelLanguageCodes.IndexOf(const ACode: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Code.Equals(ACode) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

{ TBabelLookups }

procedure TBabelLookups.Add(const ACode, AValue: string);
var
  LValue: TBabelLookupItem;
begin
  LValue.Code := ACode;
  LValue.Value := AValue;
  Items := Items + [LValue];
end;

procedure TBabelLookups.Clear;
begin
  SetLength(Items, 0);
end;

function TBabelLookups.Count: Integer;
begin
  Result := Length(Items);
end;

function TBabelLookups.Lookup(const ACode: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    if Items[I].Code.Equals(ACode) then
    begin
      Result := Items[I].Value;
      Break;
    end;
  end;
end;

{ TBabelTexts }

procedure TBabelTexts.Add(const AItem: TBabelTextItem);
begin
  Items := Items + [AItem];
end;

procedure TBabelTexts.Clear;
begin
  SetLength(Items, 0);
end;

function TBabelTexts.Count: Integer;
begin
  Result := Length(Items);
end;

procedure TBabelTexts.Sort;
begin
  if FComparer = nil then
    FComparer := TBabelTextItemComparerByDefault.Create;
  TArray.Sort<TBabelTextItem>(Items, FComparer);
end;

function TBabelTexts.Translate(const ADefault: string; const ACode: string; const ADefaultBlank: Boolean): string;
var
  I: Integer;
   LDefault, LCode, LTranslation: string;
begin
  if ADefaultBlank then
    Result := ''
  else
    Result := ADefault;
  if ACode.IsEmpty then
    LCode := TLocale.GetInfo.LanguageCode
  else
    LCode := ACode;
  LDefault := TBabel.GetText(ADefault.Trim);
  for I := 0 to Count - 1 do
  begin
    if SameText(Items[I].Default, LDefault) then
    begin
      LTranslation := Items[I].Lookups.Lookup(LCode);
      if not LTranslation.IsEmpty then
      begin
        if LDefault.Chars[0].IsLower then
          LTranslation := LTranslation.Chars[0].ToLower + LTranslation.Substring(1)
        else if LDefault.Chars[0].IsUpper then
          LTranslation := LTranslation.Chars[0].ToUpper + LTranslation.Substring(1);
        Result := ADefault.Replace(LDefault, LTranslation);
        Break;
      end;
    end;
  end;
end;

{ TBabel }

class function TBabel.GetText(const AValue: string): string;
begin
  Result := AValue;
  if Result.EndsWith('...') then
    Result := Result.Substring(0, Result.Length - 3)
  else if Result.EndsWith('..') then
    Result := Result.Substring(0, Result.Length - 2);
  Result := Result.TrimRight([':', ' ']);
  if MatchText(Result, ['-']) or not HasLetters(Result) then
    Result := '';
end;

class function TBabel.HasLetters(const AValue: string): Boolean;
var
  LChar: Char;
  LCount: Integer;
begin
  LCount := 0;
  for LChar in AValue do
  begin
    if LChar.IsLetter then
      Inc(LCount)
    else
      LCount := 0;
    if LCount > 1 then
      Break;
  end;
  Result := LCount > 1;
end;

function TBabel.InternalTranslate(const ADefault: string; const ACode: string; const ADefaultBlank: Boolean): string;
begin
  if FakeCode.IsEmpty then
    Result := Texts.Translate(ADefault, ACode, ADefaultBlank)
  else
    Result := Texts.Translate(ADefault, FakeCode, ADefaultBlank);
end;

procedure TBabel.TranslateComponent(const AComponent: TComponent; const ACode: string);
var
  I, LCount: Integer;
  LPropList: PPropList;
  LPropInfo: TPropInfo;
  LValue: string;
begin
  LCount := GetPropList(AComponent, LPropList);
  if LCount > 0 then
  try
    for I := 0 to LCount - 1 do
    begin
      LPropInfo := LPropList^[I]^;
      if CanTranslateProperty(LPropInfo) then
      begin
        LValue := InternalTranslate(GetStrProp(AComponent, string(LPropInfo.Name)), ACode, False);
        if LValue <> '' then
          SetStrProp(AComponent, string(LPropInfo.Name), LValue);
      end;
    end;
  finally
    FreeMem(LPropList);
  end;
end;

procedure TBabel.Translate(const AComponent: TComponent; const ACode: string = '');
var
  I: Integer;
begin
  TranslateComponent(AComponent, ACode);
  for I := 0 to AComponent.ComponentCount - 1 do
    TranslateComponent(AComponent.Components[I], ACode);
end;

function TBabel.Tx(const ADefault, ACode: string): string;
begin
  Result := InternalTranslate(ADefault, ACode, False);
end;

function TBabel.Translate(const ADefault: string; const ACode: string = ''; const ADefaultBlank: Boolean = False): string;
begin
  Result := InternalTranslate(ADefault, ACode, ADefaultBlank);
end;

end.

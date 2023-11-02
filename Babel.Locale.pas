unit Babel.Locale;

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

type
  TLocaleInfo = record
    LanguageCode: string;
  end;

  TLocale = record
    class function GetInfo: TLocaleInfo; static;
  end;

implementation

uses
  System.SysUtils,
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows;
  {$ENDIF}
  {$IF Defined(ANDROID)}
  Androidapi.JNI.JavaTypes, Androidapi.Helpers;
  {$ENDIF}
  {$IF Defined(MACOS)}
  Macapi.Helpers,
  {$ENDIF}
  {$IF Defined(IOS)}
  iOSapi.Foundation;
  {$ENDIF}
  {$IF Defined(OSX)}
  Macapi.Foundation;
  {$ENDIF}

{ TLocale }

{$IF Defined(MSWINDOWS)}
class function TLocale.GetInfo: TLocaleInfo;
var
  LBuffer: array[0..255] of Char;
  LLength: Integer;
begin
  LLength := GetLocaleInfo(GetUserDefaultLCID, LOCALE_SISO639LANGNAME, LBuffer, Length(LBuffer));
  if LLength > 0 then
  begin
    SetString(Result.LanguageCode, LBuffer, LLength - 1);
    Result.LanguageCode := Result.LanguageCode.Substring(0, 2);
  end
  else
    Result.LanguageCode := 'en';
end;
{$ENDIF}

{$IF Defined(ANDROID)}
class function TLocale.GetInfo: TLocaleInfo;
var
  LLocale: JLocale;
begin
  LLocale := TJLocale.JavaClass.getDefault;
  Result.LanguageCode := JStringToString(LLocale.getISO3Language);
  if Length(Result.LanguageCode) > 2 then
    Delete(Result.LanguageCode, 3, MaxInt);
end;
{$ENDIF}

{$IF Defined(MACOS)}
class function TLocale.GetInfo: TLocaleInfo;
var
  LLocale: NSLocale;
begin
  LLocale := TNSLocale.Wrap(TNSLocale.OCClass.currentLocale);
  Result.LanguageCode := NSStrToStr(LLocale.languageCode);
end;
{$ENDIF}

end.

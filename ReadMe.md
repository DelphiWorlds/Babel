# Babel

A lightweight, cross-platform library which helps translate text into the target languages.

Babel is used for translations in the [Codex](https://github.com/DelphiWorlds/Codex) add-in for Delphi, and for [Mosco](https://github.com/DelphiWorlds/Mosco).

## Features

* Lightweight - Babel is just 3 units: `Babel.Types`, `Babel.Persistence` and `Babel.Locale`
* Compact definition files

## How To Use Babel

### Create definition files

Use Babelizor to scan your project files for `.pas` and `.dfm` and/or `.fmx` files to create a definition file, and add supported languages. Babel will scan for Caption, Text, Hint and Title properties in form definition files and for `resourcestring` values in `.pas` files.
If you have an account for the Google Translate API, use the instant translation tool to create translations for your text. 

If using instant translastion, Babelizor expects a file called `options.json` in a folder called `Babelizor` under `Public Documents` with content like this:

```json
  {
    "TranslateAPIKey" : "AIzaSyAzXXXXXXXXXX7u7pcQ"
  }
```

where you would replace `AIzaSyAzXXXXXXXXXX7u7pcQ` with your API key.

This is a brief tutorial on how to [create a project, enable the API and get a key](https://www.youtube.com/watch?v=1wcE-DfqNtU&t=37s).

### Using the definition file in your app

Either deploy the definiton file with your app and use the `LoadFromFile` method, or include your definition file as a resource, and use `LoadFromResource`.
To translate the text in forms and datamodules, use the `Translate` method when the form or datamodule is created. 
To translate other text values that are in the definition file, use the `Tx` method.

## Demos

### Basic Demo

Demonstrates translation through the use of a resource file (babel.json) created with Babelizor.

## Version History

v1.0.0 (Nov 2nd, 2023)

* Initial release

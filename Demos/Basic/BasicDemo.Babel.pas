unit BasicDemo.Babel;

interface

uses
  Babel.Types;

var
  Babel: TBabel;

implementation

uses
  Babel.Persistence;

initialization
  // Loads the translations from the resource (default resource name is: babel)
  // The resource is linked into the application via the Data.rc resource command file in the root of the project
  Babel.LoadFromResource;

end.

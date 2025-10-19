unit uDBConfigReader;

interface

uses
  System.SysUtils, System.IniFiles, Vcl.Dialogs;

type
  TDBConfig = record
    Server: string;
    Port: string;
    User: string;
    Password: string;
    DatabaseName: string;
  end;

  TDBConfigReader = class
  private
    class function RequireValue(const Ini: TIniFile; const Section, Key: string): string;
  public
    class function LoadConfig: TDBConfig;
  end;

implementation

{ TDBConfigReader }

class function TDBConfigReader.RequireValue(const Ini: TIniFile; const Section, Key: string): string;
begin
  Result := Trim(Ini.ReadString(Section, Key, ''));

  if Result = '' then
  begin
    ShowMessage(Format('O campo "%s" não foi encontrado na seção [%s] do arquivo dbconfig.ini.', [Key, Section]));
    raise Exception.CreateFmt('Configuração ausente: [%s] %s', [Section, Key]);
  end;
end;

class function TDBConfigReader.LoadConfig: TDBConfig;
var
  Ini: TIniFile;
  PathExe, PathDev, ChosenPath: string;
begin
  // Caminho normal (produção)
  PathExe := ExtractFilePath(ParamStr(0)) + 'dbconfig.ini';

  // Caminho alternativo (desenvolvimento)
  PathDev := ExtractFilePath(ParamStr(0)) + '..\..\dbconfig.ini';
  PathDev := ExpandFileName(PathDev);

  if FileExists(PathExe) then
    ChosenPath := PathExe
  else if FileExists(PathDev) then
    ChosenPath := PathDev
  else
    raise Exception.Create(
      'Arquivo de configuração "dbconfig.ini" não encontrado.' + sLineBreak +
      'Procurei em:' + sLineBreak +
      PathExe + sLineBreak +
      PathDev
    );

  Ini := TIniFile.Create(ChosenPath);
  try
    Result.Server      := RequireValue(Ini, 'Database', 'Server');
    Result.Port        := RequireValue(Ini, 'Database', 'Port');
    Result.User        := RequireValue(Ini, 'Database', 'User');
    Result.Password    := RequireValue(Ini, 'Database', 'Password');
    Result.DatabaseName:= RequireValue(Ini, 'Database', 'DatabaseName');
  finally
    Ini.Free;
  end;
end;

end.


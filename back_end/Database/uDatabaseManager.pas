unit uDatabaseManager;

interface

uses
  System.SysUtils, Vcl.Dialogs, System.Classes,
  uDBConfigReader,
  Horse,
  FireDAC.Comp.Client;

type
  TDatabaseManager = class
  private
    class function NewFDConnection(const ADatabase: string): TFDConnection; static;
    class function DatabaseExists(const ADatabase: string): Boolean; static;
    class procedure CreateDatabase(const ADatabase: string); static;
    class procedure CreateProdutosTableIfNotExists; static;
    class procedure StartORM; static;
    class procedure CreateAuditTriggers; static;
  public
    class procedure EnsureDatabaseAndTables; static;
    class procedure ConfigureConnection(Req: THorseRequest; Res: THorseResponse;
      Next: TProc); static;
  end;

implementation

uses
  FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI,
  MVCFramework.ActiveRecord,
  MVCFramework.SQLGenerators.PostgreSQL,
  MVCFramework.Commons,
  uProdutoModel;

{ TDatabaseManager }

class function TDatabaseManager.NewFDConnection(const ADatabase: string): TFDConnection;
var
  Config: TDBConfig;
begin
  Config := TDBConfigReader.LoadConfig;

  Result := TFDConnection.Create(nil);
  Result.DriverName := 'PG';
  Result.LoginPrompt := False;
  Result.Params.Values['Server'] := Config.Server;
  Result.Params.Values['Port'] := Config.Port;
  Result.Params.Values['User_Name'] := Config.User;
  Result.Params.Values['Password'] := Config.Password;
  Result.Params.Values['Database'] := ADatabase;
end;

class function TDatabaseManager.DatabaseExists(const ADatabase: string): Boolean;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Result := False;
  Conn := NewFDConnection('postgres');
  try
    Conn.Connected := True;
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text := 'SELECT 1 FROM pg_database WHERE datname = :n';
      Qry.ParamByName('n').AsString := ADatabase;
      Qry.Open;
      Result := not Qry.IsEmpty;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TDatabaseManager.CreateDatabase(const ADatabase: string);
var
  Conn: TFDConnection;
begin
  Conn := NewFDConnection('postgres');
  try
    Conn.Connected := True;
    Conn.ExecSQL('CREATE DATABASE ' + ADatabase);
  finally
    Conn.Free;
  end;
end;

class procedure TDatabaseManager.CreateProdutosTableIfNotExists;
var
  Conn: TFDConnection;
begin
  Conn := NewFDConnection(TDBConfigReader.LoadConfig.DatabaseName);
  try
    Conn.Connected := True;
    Conn.ExecSQL(
      'CREATE TABLE IF NOT EXISTS produtos (' +
      '  id              SERIAL PRIMARY KEY, ' +
      '  codigo          VARCHAR(50)  NOT NULL UNIQUE, ' +
      '  nome            VARCHAR(100) NOT NULL, ' +
      '  descricao       TEXT, ' +
      '  categoria       VARCHAR(50), ' +
      '  unidade_medida  VARCHAR(10) DEFAULT ''UN'', ' +
      '  preco           NUMERIC(10,2) NOT NULL CHECK (preco >= 0), ' +
      '  estoque         INTEGER       NOT NULL DEFAULT 0 CHECK (estoque >= 0), ' +
      '  ativo           BOOLEAN       NOT NULL DEFAULT TRUE, ' +
      '  criado_em       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP, ' +
      '  atualizado_em   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ' +
      ')'
    );
    Conn.ExecSQL('CREATE INDEX IF NOT EXISTS idx_produtos_nome ON produtos (nome)');
    Conn.ExecSQL('CREATE INDEX IF NOT EXISTS idx_produtos_categoria ON produtos (categoria)');
  finally
    Conn.Free;
  end;
end;

class procedure TDatabaseManager.CreateAuditTriggers;
var
  Conn: TFDConnection;
begin
  Conn := NewFDConnection(TDBConfigReader.LoadConfig.DatabaseName);
  try
    Conn.Connected := True;
    Conn.ExecSQL(
      'CREATE OR REPLACE FUNCTION set_updated_at() ' +
      'RETURNS TRIGGER AS $$ ' +
      'BEGIN NEW.atualizado_em = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;');

    Conn.ExecSQL(
      'DO $$ BEGIN ' +
      'IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = ''trg_set_updated_at'') THEN ' +
      '  CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON produtos ' +
      '  FOR EACH ROW EXECUTE FUNCTION set_updated_at(); ' +
      'END IF; END $$;');

    Conn.ExecSQL(
      'CREATE OR REPLACE FUNCTION set_created_at() ' +
      'RETURNS TRIGGER AS $$ ' +
      'BEGIN IF TG_OP = ''INSERT'' THEN NEW.criado_em = NOW(); END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;');

    Conn.ExecSQL(
      'DO $$ BEGIN ' +
      'IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = ''trg_set_created_at'') THEN ' +
      '  CREATE TRIGGER trg_set_created_at BEFORE INSERT ON produtos ' +
      '  FOR EACH ROW EXECUTE FUNCTION set_created_at(); ' +
      'END IF; END $$;');
  finally
    Conn.Free;
  end;
end;

class procedure TDatabaseManager.EnsureDatabaseAndTables;
var
  DbName: string;
begin
  DbName := TDBConfigReader.LoadConfig.DatabaseName;

  if not DatabaseExists(DbName) then
    CreateDatabase(DbName);

  CreateProdutosTableIfNotExists;
  CreateAuditTriggers;

  StartORM;
end;

class procedure TDatabaseManager.StartORM;
var
  Conn: TFDConnection;
begin
  WriteLn('Iniciando configuração do ORM...');
  Conn := NewFDConnection(TDBConfigReader.LoadConfig.DatabaseName);

  try
    WriteLn('Conectando ao banco...');
    Conn.Connected := True;
    WriteLn('Conectado com sucesso!');

    WriteLn('Registrando conexão no ActiveRecord...');
    ActiveRecordConnectionsRegistry.AddConnection('main_connection', Conn, True);
    ActiveRecordConnectionsRegistry.SetCurrent('main_connection');

    WriteLn('Configuração do ORM concluída!');

  except
    on E: Exception do
    begin
      WriteLn('Erro: ' + E.Message);
      Conn.Free;
      raise;
    end;
  end;
end;

class procedure TDatabaseManager.ConfigureConnection(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Conn: TFDConnection;
begin
  Conn := NewFDConnection(TDBConfigReader.LoadConfig.DatabaseName);

  try
    Conn.LoginPrompt := False;
    Conn.Connected := True;

    ActiveRecordConnectionsRegistry.AddConnection('request_connection', Conn, True);
    ActiveRecordConnectionsRegistry.SetCurrent('request_connection');

    try
      Next();
    finally
      ActiveRecordConnectionsRegistry.RemoveConnection('request_connection', False);
    end;

  except
    Conn.Free;
    raise;
  end;
end;
end.


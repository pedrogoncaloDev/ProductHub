program API;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.CORS,
  Horse.Jhonson,
  uProductsRoutes in 'uProductsRoutes.pas',
  uProdutoRepository in 'Repositories\uProdutoRepository.pas',
  uProdutoModel in 'Models\uProdutoModel.pas',
  uDatabaseManager in 'Database\uDatabaseManager.pas',
  uDBConfigReader in 'Database\uDBConfigReader.pas';

begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;

  try
    Writeln('Iniciando servidor Horse...');

    TDatabaseManager.EnsureDatabaseAndTables;

    // Middleware JSON
    THorse.Use(Jhonson());
    THorse.Use(TDatabaseManager.ConfigureConnection);

    HorseCORS
      .AllowedOrigin('*')
      .AllowedMethods('GET,POST,PUT,DELETE,OPTIONS');

    // Registra as rotas dos produtos
    RegisterProductsRoutes;

    // Define a porta e inicia o servidor
    THorse.Listen(9000,
      procedure
      begin
        Writeln('Servidor rodando em: http://localhost:9000');
        Writeln('Pressione ENTER para encerrar.');
      end
    );

    Readln;
    THorse.StopListen;
  except
    on E: Exception do
    begin
      Writeln('Erro ao iniciar o servidor: ' + E.Message);
      Readln;
    end;
  end;
end.


unit uProductsRoutes;

interface

procedure RegisterProductsRoutes;

implementation

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  Horse, Horse.Jhonson,
  uProdutoModel,
  uProdutoRepository;

{ ==============================================================
  Helper functions
  ============================================================== }

function ProductToJSON(const Product: TProduto): TJSONObject;
begin
  Result := TJSONObject.Create
    .AddPair('id', TJSONNumber.Create(Product.Id))
    .AddPair('codigo', Product.Codigo)
    .AddPair('nome', Product.Nome)
    .AddPair('descricao', TJSONString.Create(Product.Descricao))
    .AddPair('categoria', TJSONString.Create(Product.Categoria))
    .AddPair('unidade_medida', TJSONString.Create(Product.UnidadeMedida))
    .AddPair('preco', TJSONNumber.Create(Double(Product.Preco)))
    .AddPair('estoque', TJSONNumber.Create(Product.Estoque))
    .AddPair('ativo', TJSONBool.Create(Product.Ativo))
    .AddPair('criado_em', TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', Product.CriadoEm)))
    .AddPair('atualizado_em', TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', Product.AtualizadoEm)));
end;

procedure ApplyJSONToProduct(const JsonObject: TJSONObject; const Product: TProduto; const IsUpdate: Boolean);

  function GetStringValue(const FieldName, DefaultValue: string): string;
  var JsonValue: TJSONValue;
  begin
    JsonValue := JsonObject.GetValue(FieldName);
    if JsonValue is TJSONString then
      Result := TJSONString(JsonValue).Value
    else if Assigned(JsonValue) then
      Result := JsonValue.Value
    else
      Result := DefaultValue;
  end;

  function GetIntegerValue(const FieldName: string; const DefaultValue: Integer): Integer;
  var JsonValue: TJSONValue; ParsedNumber: Double;
  begin
    JsonValue := JsonObject.GetValue(FieldName);
    if (JsonValue is TJSONNumber) and TryStrToFloat(JsonValue.Value.Replace(',', '.'), ParsedNumber, TFormatSettings.Invariant) then
      Result := Trunc(ParsedNumber)
    else if Assigned(JsonValue) then
      Result := StrToIntDef(JsonValue.Value, DefaultValue)
    else
      Result := DefaultValue;
  end;

  function GetCurrencyValue(const FieldName: string; const DefaultValue: Currency): Currency;
  var JsonValue: TJSONValue; ParsedValue: Double;
  begin
    JsonValue := JsonObject.GetValue(FieldName);
    if Assigned(JsonValue) and TryStrToFloat(JsonValue.Value.Replace(',', '.'), ParsedValue, TFormatSettings.Invariant) then
      Result := ParsedValue
    else
      Result := DefaultValue;
  end;

  function GetBooleanValue(const FieldName: string; const DefaultValue: Boolean): Boolean;
  var JsonValue: TJSONValue;
  begin
    JsonValue := JsonObject.GetValue(FieldName);
    if JsonValue is TJSONTrue then Exit(True);
    if JsonValue is TJSONFalse then Exit(False);
    if Assigned(JsonValue) then
      Result := SameText(JsonValue.Value, 'true')
    else
      Result := DefaultValue;
  end;

begin
  if (not IsUpdate) or Assigned(JsonObject.GetValue('codigo'))       then Product.Codigo        := GetStringValue('codigo', '');
  if (not IsUpdate) or Assigned(JsonObject.GetValue('nome'))         then Product.Nome          := GetStringValue('nome', '');
  if Assigned(JsonObject.GetValue('descricao'))                      then Product.Descricao     := GetStringValue('descricao', '');
  if Assigned(JsonObject.GetValue('categoria'))                      then Product.Categoria     := GetStringValue('categoria', '');
  if Assigned(JsonObject.GetValue('unidade_medida'))                 then Product.UnidadeMedida := GetStringValue('unidade_medida', 'UN');
  if Assigned(JsonObject.GetValue('preco'))                          then Product.Preco         := GetCurrencyValue('preco', 0);
  if Assigned(JsonObject.GetValue('estoque'))                        then Product.Estoque       := GetIntegerValue('estoque', 0);
  if Assigned(JsonObject.GetValue('ativo'))                          then Product.Ativo         := GetBooleanValue('ativo', True);
end;

{ ==============================================================
  Routes registration
  ============================================================== }

procedure RegisterProductsRoutes;
begin
  THorse.Use(Jhonson);

  THorse.Get('/products',
    procedure(Request: THorseRequest; Response: THorseResponse; Next: TProc)
    var
      ProductList: TObjectList<TProduto>;
      JsonArray: TJSONArray;
      Product: TProduto;
    begin
      ProductList := TProdutoRepository.GetAll;
      try
        JsonArray := TJSONArray.Create;
        try
          for Product in ProductList do
            JsonArray.AddElement(ProductToJSON(Product));

          Response.Status(200)
                  .ContentType('application/json')
                  .Send<TJSONArray>(JsonArray);
        except
          JsonArray.Free;
          raise;
        end;
      finally
        ProductList.Free;
      end;
    end);

  THorse.Get('/products/:id',
    procedure(Request: THorseRequest; Response: THorseResponse; Next: TProc)
    var
      ProductId: Integer;
      Product: TProduto;
    begin
      ProductId := StrToIntDef(Request.Params['id'], 0);
      if ProductId <= 0 then
      begin
        Response.Status(400).Send('ID do produto inválido.');
        Exit;
      end;

      Product := TProdutoRepository.GetById(ProductId);
      if Product = nil then
      begin
        Response.Status(404).Send('Produto não encontrado.');
        Exit;
      end;

      Response.Status(200)
              .ContentType('application/json')
              .Send<TJSONObject>(ProductToJSON(Product));
    end);

  THorse.Post('/products',
    procedure(Request: THorseRequest; Response: THorseResponse; Next: TProc)
    var
      JsonBody: TJSONObject;
      Product: TProduto;
    begin
      JsonBody := Request.Body<TJSONObject>;
      if JsonBody = nil then
      begin
        Response.Status(400).Send('JSON inválido.');
        Exit;
      end;

      if (JsonBody.GetValue('codigo') = nil) or (JsonBody.GetValue('nome') = nil) then
      begin
        Response.Status(400).Send('Os campos "codigo" e "nome" são obrigatórios.');
        Exit;
      end;

      Product := TProduto.Create;
      try
        Product.Ativo := True;
        Product.UnidadeMedida := 'UN';
        Product.CriadoEm := Now;
        Product.AtualizadoEm := Now;

        ApplyJSONToProduct(JsonBody, Product, False);
        TProdutoRepository.Add(Product);

        Response.AddHeader('Location', '/products/' + Product.Id.ToString);
        Response.Status(201)
                .ContentType('application/json')
                .Send<TJSONObject>(ProductToJSON(Product));
      except
        Product.Free;
        raise;
      end;
    end);

  THorse.Put('/products/:id',
    procedure(Request: THorseRequest; Response: THorseResponse; Next: TProc)
    var
      ProductId: Integer;
      JsonBody: TJSONObject;
      Product: TProduto;
    begin
      ProductId := StrToIntDef(Request.Params['id'], 0);
      if ProductId <= 0 then
      begin
        Response.Status(400).Send('ID do produto inválido.');
        Exit;
      end;

      Product := TProdutoRepository.GetById(ProductId);
      if Product = nil then
      begin
        Response.Status(404).Send('Produto não encontrado.');
        Exit;
      end;

      JsonBody := Request.Body<TJSONObject>;
      if JsonBody = nil then
      begin
        Response.Status(400).Send('JSON inválido.');
        Exit;
      end;

      ApplyJSONToProduct(JsonBody, Product, True);
      Product.AtualizadoEm := Now;
      TProdutoRepository.Update(Product);

      Response.Status(200)
              .ContentType('application/json')
              .Send<TJSONObject>(ProductToJSON(Product));
    end);

  THorse.Delete('/products/:id',
    procedure(Request: THorseRequest; Response: THorseResponse; Next: TProc)
    var
      ProductId: Integer;
      Product: TProduto;
    begin
      ProductId := StrToIntDef(Request.Params['id'], 0);
      if ProductId <= 0 then
      begin
        Response.Status(400).Send('ID do produto inválido.');
        Exit;
      end;

      Product := TProdutoRepository.GetById(ProductId);
      if Product = nil then
      begin
        Response.Status(404).Send('Produto não encontrado.');
        Exit;
      end;

      TProdutoRepository.Delete(Product.Id);
      Response.Status(204).Send('');
    end);
end;

end.


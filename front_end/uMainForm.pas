unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Vcl.StdCtrls,
  Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Vcl.Grids, System.Net.HttpClient, System.Net.URLClient, System.Net.HttpClientComponent,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList;

type
  TMainForm = class(TForm)
    PanelButtons: TPanel;
    FlowPanelButtons: TFlowPanel;
    BtnRefreshProducts: TButton;
    BtnCreateProduct: TButton;
    BtnEditProduct: TButton;
    BtnDeleteProduct: TButton;
    PanelGrid: TPanel;
    DBGridProducts: TDBGrid;
    BevelSeparator: TBevel;
    DataSourceProducts: TDataSource;
    MemTableProducts: TFDMemTable;
    HttpClient: TNetHTTPClient;
    ImageList: TImageList;

    procedure FormCreate(Sender: TObject);
    procedure BtnRefreshProductsClick(Sender: TObject);
    procedure BtnCreateProductClick(Sender: TObject);
    procedure BtnEditProductClick(Sender: TObject);
    procedure BtnDeleteProductClick(Sender: TObject);

  private
    const API_BASE_URL = 'http://localhost:9000/';
    procedure CreateMemStructure;
    procedure LoadProductsFromAPI;
    function GetSelectedProductId: Integer;
    function HasValidSelection: Boolean;
    procedure DeleteProductById(const ProductId: Integer);
    function TryStringToDateTime(const DateTimeStr: string;
      out DateTime: TDateTime): Boolean;
  end;

var
  FrmMain: TMainForm;

implementation

uses
  uProductForm;

{$R *.dfm}

{ ====== Initialization ====== }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  CreateMemStructure;
  LoadProductsFromAPI;
end;

{ ====== CRUD Buttons ====== }

procedure TMainForm.BtnRefreshProductsClick(Sender: TObject);
begin
  LoadProductsFromAPI;
end;

procedure TMainForm.BtnCreateProductClick(Sender: TObject);
var
  Form: TFrmProductForm;
  Response: IHTTPResponse;
  ProductJSON: TJSONObject;
begin
  Form := TFrmProductForm.Create(Self);
  try
    if Form.ShowModal = mrOk then
    begin
      ProductJSON := Form.GetFormDataAsJSON;
      try
        Response := HttpClient.Post(API_BASE_URL + '/products',
          TStringStream.Create(ProductJSON.ToJSON, TEncoding.UTF8),
          nil,
          [TNameValuePair.Create('Content-Type', 'application/json')]);

        if Response.StatusCode in [200, 201] then
        begin
          LoadProductsFromAPI;
        end
        else
          ShowMessage('Erro ao cadastrar produto: ' + Response.StatusText);
      finally
        ProductJSON.Free;
      end;
    end;
  finally
    Form.Free;
  end;
end;

procedure TMainForm.BtnEditProductClick(Sender: TObject);
var
  ProductId: Integer;
  Form: TFrmProductForm;
  Response: IHTTPResponse;
  ProductJSON: TJSONObject;
begin
  if not HasValidSelection then Exit;
  ProductId := GetSelectedProductId;

  // GET do produto existente
  Response := HttpClient.Get(API_BASE_URL + '/products/' + ProductId.ToString);
  if Response.StatusCode <> 200 then
  begin
    ShowMessage('Erro ao carregar produto: ' + Response.StatusText);
    Exit;
  end;

  ProductJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
  if not Assigned(ProductJSON) then
  begin
    ShowMessage('Erro ao processar dados do produto.');
    Exit;
  end;

  Form := TFrmProductForm.Create(Self);
  try
    Form.LoadFromJSON(ProductJSON);

    if Form.ShowModal = mrOk then
    begin
      Response := HttpClient.Put(
        Format('%s/%d', [API_BASE_URL + '/products', ProductId]),
        TStringStream.Create(Form.GetFormDataAsJSON.ToJSON, TEncoding.UTF8),
        nil,
        [TNameValuePair.Create('Content-Type', 'application/json')]
      );

      if Response.StatusCode in [200, 201] then
        LoadProductsFromAPI
      else
        ShowMessage('Erro ao atualizar produto: ' + Response.StatusText);
    end;
  finally
    ProductJSON.Free;
    Form.Free;
  end;
end;

procedure TMainForm.BtnDeleteProductClick(Sender: TObject);
var
  ProductId: Integer;
begin
  if not HasValidSelection then Exit;
  ProductId := GetSelectedProductId;

  if MessageDlg(Format('Deseja realmente excluir o produto com ID %d?', [ProductId]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    DeleteProductById(ProductId);
    LoadProductsFromAPI;
  except
    on E: Exception do
      ShowMessage('Erro ao excluir produto: ' + E.Message);
  end;
end;

{ ====== API Communication ====== }

procedure TMainForm.LoadProductsFromAPI;
var
  Response: IHTTPResponse;
  JsonArray: TJSONArray;
  JsonItem: TJSONObject;
  i: Integer;
  CriadoEmStr, AtualizadoEmStr: string;
  CriadoEm, AtualizadoEm: TDateTime;
begin
  try
    Response := HttpClient.Get(API_BASE_URL + 'products');
    if Response.StatusCode <> 200 then
      raise Exception.CreateFmt('Erro ao carregar produtos: %d %s',
        [Response.StatusCode, Response.StatusText]);

    JsonArray := TJSONObject.ParseJSONValue(Response.ContentAsString()) as TJSONArray;
    if not Assigned(JsonArray) then
      raise Exception.Create('JSON inválido recebido da API.');

    MemTableProducts.DisableControls;
    try
      MemTableProducts.EmptyDataSet;

      for i := 0 to JsonArray.Count - 1 do
      begin
        JsonItem := JsonArray.Items[i] as TJSONObject;

        CriadoEmStr := JsonItem.GetValue<string>('criado_em');
        AtualizadoEmStr := JsonItem.GetValue<string>('atualizado_em');

        if not TryStringToDateTime(CriadoEmStr, CriadoEm) then
          CriadoEm := 0;

        if not TryStringToDateTime(AtualizadoEmStr, AtualizadoEm) then
          AtualizadoEm := 0;

        MemTableProducts.Append;
        MemTableProducts.FieldByName('id').AsInteger := JsonItem.GetValue<Integer>('id');
        MemTableProducts.FieldByName('codigo').AsString := JsonItem.GetValue<string>('codigo');
        MemTableProducts.FieldByName('nome').AsString := JsonItem.GetValue<string>('nome');
        MemTableProducts.FieldByName('descricao').AsString := JsonItem.GetValue<string>('descricao');
        MemTableProducts.FieldByName('categoria').AsString := JsonItem.GetValue<string>('categoria');
        MemTableProducts.FieldByName('unidade_medida').AsString := JsonItem.GetValue<string>('unidade_medida');
        MemTableProducts.FieldByName('preco').AsCurrency := JsonItem.GetValue<Double>('preco');
        MemTableProducts.FieldByName('estoque').AsInteger := JsonItem.GetValue<Integer>('estoque');
        MemTableProducts.FieldByName('ativo').AsBoolean := JsonItem.GetValue<Boolean>('ativo');
        MemTableProducts.FieldByName('criado_em').AsDateTime := CriadoEm;
        MemTableProducts.FieldByName('atualizado_em').AsDateTime := AtualizadoEm;
        MemTableProducts.Post;
      end;
    finally
      MemTableProducts.EnableControls;
    end;
  except
    on E: Exception do
      ShowMessage('Falha ao carregar os produtos: ' + E.Message);
  end;
end;

procedure TMainForm.DeleteProductById(const ProductId: Integer);
var
  Response: IHTTPResponse;
  Url: string;
begin
  Url := Format('%s/%d', [API_BASE_URL + 'products', ProductId]);
  Response := HttpClient.Delete(Url);

  if not (Response.StatusCode in [200, 204]) then
    raise Exception.CreateFmt('Falha ao excluir produto (status %d): %s',
      [Response.StatusCode, Response.ContentAsString]);
end;

{ ====== Helper Functions ====== }

function TMainForm.HasValidSelection: Boolean;
begin
  Result := Assigned(DataSourceProducts.DataSet)
            and not DataSourceProducts.DataSet.IsEmpty;

  if not Result then
    ShowMessage('Selecione um produto primeiro.');
end;

function TMainForm.GetSelectedProductId: Integer;
begin
  Result := 0;
  if Assigned(DataSourceProducts.DataSet) and
     DataSourceProducts.DataSet.Active then
    Result := DataSourceProducts.DataSet.FieldByName('id').AsInteger;
end;

{ ====== Grid and Memory Table ====== }

procedure TMainForm.CreateMemStructure;
var
  Column: TColumn;
begin
  MemTableProducts.Close;
  MemTableProducts.FieldDefs.Clear;

  MemTableProducts.FieldDefs.Add('id', ftInteger);
  MemTableProducts.FieldDefs.Add('codigo', ftString, 50);
  MemTableProducts.FieldDefs.Add('nome', ftString, 100);
  MemTableProducts.FieldDefs.Add('descricao', ftString, 255);
  MemTableProducts.FieldDefs.Add('categoria', ftString, 50);
  MemTableProducts.FieldDefs.Add('unidade_medida', ftString, 10);
  MemTableProducts.FieldDefs.Add('preco', ftCurrency);
  MemTableProducts.FieldDefs.Add('estoque', ftInteger);
  MemTableProducts.FieldDefs.Add('ativo', ftBoolean);
  MemTableProducts.FieldDefs.Add('criado_em', ftDateTime);
  MemTableProducts.FieldDefs.Add('atualizado_em', ftDateTime);
  MemTableProducts.CreateDataSet;

  DataSourceProducts.DataSet := MemTableProducts;
  DBGridProducts.DataSource := DataSourceProducts;

  DBGridProducts.ReadOnly := True;
  DBGridProducts.TitleFont.Style := [fsBold];
  DBGridProducts.Options := [
    dgTitles, dgIndicator, dgColLines, dgRowLines, dgRowSelect,
    dgAlwaysShowSelection, dgColumnResize, dgTabs, dgConfirmDelete
  ];

  DBGridProducts.Columns.Clear;

  Column := DBGridProducts.Columns.Add; Column.FieldName := 'id'; Column.Title.Caption := 'ID'; Column.Width := 40;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'codigo'; Column.Title.Caption := 'Código'; Column.Width := 80;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'nome'; Column.Title.Caption := 'Nome'; Column.Width := 150;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'descricao'; Column.Title.Caption := 'Descrição'; Column.Width := 200;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'categoria'; Column.Title.Caption := 'Categoria'; Column.Width := 120;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'unidade_medida'; Column.Title.Caption := 'Un.'; Column.Width := 60;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'preco'; Column.Title.Caption := 'Preço'; Column.Width := 100;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'estoque'; Column.Title.Caption := 'Estoque'; Column.Width := 70;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'ativo'; Column.Title.Caption := 'Ativo'; Column.Width := 60;
  TBooleanField(MemTableProducts.FieldByName('ativo')).DisplayValues := 'Sim;Não';
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'criado_em'; Column.Title.Caption := 'Criado em'; Column.Width := 130;
  Column := DBGridProducts.Columns.Add; Column.FieldName := 'atualizado_em'; Column.Title.Caption := 'Atualizado em'; Column.Width := 130;
end;

function TMainForm.TryStringToDateTime(const DateTimeStr: string; out DateTime: TDateTime): Boolean;
var
  FormatSettings: TFormatSettings;
begin
  Result := False;
  if DateTimeStr = '' then Exit;

  FormatSettings := TFormatSettings.Create;
  FormatSettings.DateSeparator := '-';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FormatSettings.LongTimeFormat := 'hh:nn:ss.zzz';

  try
    DateTime := StrToDateTime(DateTimeStr, FormatSettings);
    Result := True;
  except
    try
      DateTime := StrToDateTime(Copy(DateTimeStr, 1, 19), FormatSettings);
      Result := True;
    except
      Result := False;
    end;
  end;
end;

end.


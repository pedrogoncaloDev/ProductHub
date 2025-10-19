unit uProductForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Samples.Spin, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent;

type
  TFrmProductForm = class(TForm)
    pnlBottom: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    lblCode: TLabel;
    edtCode: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblDescription: TLabel;
    memDescription: TMemo;
    lblCategory: TLabel;
    edtCategory: TEdit;
    lblUnit: TLabel;
    cbUnit: TComboBox;
    lblPrice: TLabel;
    edtPrice: TEdit;
    lblStock: TLabel;
    spnStock: TSpinEdit;
    chkActive: TCheckBox;

    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    function TryParseCurrency(const TextValue: string; out Value: Currency): Boolean;
  public
    class function Execute(AOwner: TComponent; out ProductJSON: TJSONObject): Boolean;
    function GetFormDataAsJSON: TJSONObject;
    procedure LoadFromJSON(const AJSON: TJSONObject);
  end;

var
  ProductForm: TFrmProductForm;

implementation

{$R *.dfm}

{ ================================================================== }
{ ===============   FORM INITIALIZATION   =========================== }
{ ================================================================== }

procedure TFrmProductForm.FormCreate(Sender: TObject);
begin
  Caption := 'Cadastro de Produto';
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  ClientWidth := 640;
  ClientHeight := 520;

  cbUnit.Items.SetText(PChar('UN'#13'PC'#13'KG'#13'CX'#13'MT'));
  cbUnit.ItemIndex := 0;
  chkActive.Checked := True;

  spnStock.MinValue := 0;
  spnStock.MaxValue := High(Integer);
  spnStock.Value := 0;
end;

procedure TFrmProductForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmProductForm.btnSaveClick(Sender: TObject);
begin
  // Validação simples antes de fechar o modal
  if Trim(edtCode.Text) = '' then
  begin
    MessageDlg('Informe o código do produto.', mtWarning, [mbOK], 0);
    edtCode.SetFocus;
    Exit;
  end;

  if Trim(edtName.Text) = '' then
  begin
    MessageDlg('Informe o nome do produto.', mtWarning, [mbOK], 0);
    edtName.SetFocus;
    Exit;
  end;

  ModalResult := mrOk; // fecha o modal com sucesso
end;

{ ================================================================== }
{ ===============   UTILITÁRIOS DE FORMATAÇÃO   ==================== }
{ ================================================================== }

function TFrmProductForm.TryParseCurrency(const TextValue: string; out Value: Currency): Boolean;
var
  Format: TFormatSettings;
  Clean: string;
begin
  Format := TFormatSettings.Invariant;
  Clean := StringReplace(TextValue.Trim, ',', '.', [rfReplaceAll]);
  Result := TryStrToCurr(Clean, Value, Format);
end;

{ ================================================================== }
{ ===============   OBTÉM DADOS EM FORMATO JSON   ================== }
{ ================================================================== }

function TFrmProductForm.GetFormDataAsJSON: TJSONObject;
var
  PriceValue: Currency;
begin
  Result := TJSONObject.Create;

  Result.AddPair('codigo', Trim(edtCode.Text));
  Result.AddPair('nome', Trim(edtName.Text));
  Result.AddPair('descricao', Trim(memDescription.Lines.Text));
  Result.AddPair('categoria', Trim(edtCategory.Text));
  Result.AddPair('unidade_medida', cbUnit.Text);

  if TryParseCurrency(edtPrice.Text, PriceValue) then
    Result.AddPair('preco', TJSONNumber.Create(PriceValue))
  else
    Result.AddPair('preco', TJSONNumber.Create(0));

  Result.AddPair('estoque', TJSONNumber.Create(spnStock.Value));
  Result.AddPair('ativo', TJSONBool.Create(chkActive.Checked));
end;

procedure TFrmProductForm.LoadFromJSON(const AJSON: TJSONObject);
var
  JValue: TJSONValue;
  TempStr: string;
begin
  if not Assigned(AJSON) then Exit;

  // Código
  JValue := AJSON.GetValue('codigo');
  if Assigned(JValue) then
    edtCode.Text := JValue.ToString.Replace('"','')
  else
    edtCode.Text := '';

  // Nome
  JValue := AJSON.GetValue('nome');
  if Assigned(JValue) then
    edtName.Text := JValue.ToString.Replace('"','')
  else
    edtName.Text := '';

  // Descrição
  JValue := AJSON.GetValue('descricao');
  if Assigned(JValue) then
    memDescription.Text := JValue.ToString.Replace('"','')
  else
    memDescription.Text := '';

  // Categoria
  JValue := AJSON.GetValue('categoria');
  if Assigned(JValue) then
    edtCategory.Text := JValue.ToString.Replace('"','')
  else
    edtCategory.Text := '';

  // Unidade
  JValue := AJSON.GetValue('unidade_medida');
  if Assigned(JValue) then
    cbUnit.Text := JValue.ToString.Replace('"','')
  else
    cbUnit.Text := '';

  // Preço
  JValue := AJSON.GetValue('preco');
  if Assigned(JValue) then
    edtPrice.Text := JValue.ToString.Replace('"','')
  else
    edtPrice.Text := '0';

  // Estoque
  JValue := AJSON.GetValue('estoque');
  if Assigned(JValue) then
    TempStr := JValue.ToString.Replace('"','')
  else
    TempStr := '0';
  spnStock.Value := StrToIntDef(TempStr, 0);

  // Ativo
  JValue := AJSON.GetValue('ativo');
  if Assigned(JValue) then
    TempStr := JValue.ToString.Replace('"','')
  else
    TempStr := 'true';
  chkActive.Checked := TempStr = 'true';
end;

{ ================================================================== }
{ ===============   MÉTODO EXECUTE (CHAMADA MODAL)   =============== }
{ ================================================================== }

class function TFrmProductForm.Execute(AOwner: TComponent; out ProductJSON: TJSONObject): Boolean;
var
  Form: TFrmProductForm;
begin
  ProductJSON := nil;
  Form := TFrmProductForm.Create(AOwner);
  try
    Result := Form.ShowModal = mrOk;
    if Result then
      ProductJSON := Form.GetFormDataAsJSON;
  finally
    Form.Free;
  end;
end;

end.


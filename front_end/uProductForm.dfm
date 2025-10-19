object FrmProductForm: TFrmProductForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Produto'
  ClientHeight = 520
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblCode: TLabel
    Left = 16
    Top = 16
    Width = 39
    Height = 15
    Caption = 'C'#243'digo'
  end
  object lblName: TLabel
    Left = 208
    Top = 16
    Width = 33
    Height = 15
    Caption = 'Nome'
  end
  object lblDescription: TLabel
    Left = 16
    Top = 72
    Width = 51
    Height = 15
    Caption = 'Descri'#231#227'o'
  end
  object lblCategory: TLabel
    Left = 16
    Top = 216
    Width = 51
    Height = 15
    Caption = 'Categoria'
  end
  object lblUnit: TLabel
    Left = 272
    Top = 216
    Width = 44
    Height = 15
    Caption = 'Unidade'
  end
  object lblPrice: TLabel
    Left = 368
    Top = 216
    Width = 30
    Height = 15
    Caption = 'Pre'#231'o'
  end
  object lblStock: TLabel
    Left = 504
    Top = 216
    Width = 42
    Height = 15
    Caption = 'Estoque'
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 464
    Width = 640
    Height = 56
    Align = alBottom
    TabOrder = 8
    object btnSave: TButton
      Left = 440
      Top = 12
      Width = 90
      Height = 32
      Caption = 'Salvar'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 536
      Top = 12
      Width = 90
      Height = 32
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object edtCode: TEdit
    Left = 16
    Top = 32
    Width = 180
    Height = 23
    TabOrder = 0
  end
  object edtName: TEdit
    Left = 208
    Top = 32
    Width = 416
    Height = 23
    TabOrder = 1
  end
  object memDescription: TMemo
    Left = 16
    Top = 88
    Width = 608
    Height = 120
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object edtCategory: TEdit
    Left = 16
    Top = 232
    Width = 240
    Height = 23
    TabOrder = 3
  end
  object cbUnit: TComboBox
    Left = 272
    Top = 232
    Width = 80
    Height = 23
    TabOrder = 4
  end
  object edtPrice: TEdit
    Left = 368
    Top = 232
    Width = 120
    Height = 23
    TabOrder = 5
  end
  object spnStock: TSpinEdit
    Left = 504
    Top = 232
    Width = 120
    Height = 24
    MaxValue = 2147483647
    MinValue = 0
    TabOrder = 6
    Value = 0
  end
  object chkActive: TCheckBox
    Left = 16
    Top = 272
    Width = 97
    Height = 17
    Caption = 'Ativo'
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
end

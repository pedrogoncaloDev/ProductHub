program front_end;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uProductForm in 'uProductForm.pas' {FrmProductForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, FrmMain);
  Application.CreateForm(TFrmProductForm, ProductForm);
  Application.Run;
end.


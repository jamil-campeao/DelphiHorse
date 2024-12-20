program ServidorHorse;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.Usuario in 'Controller\Controllers.Usuario.pas',
  DataModuleGlobal in 'DataModule\DataModuleGlobal.pas' {DMGlobal: TDataModule},
  uMD5 in 'Units\uMD5.pas',
  Controllers.Auth in 'Controller\Controllers.Auth.pas',
  Controllers.Notificacao in 'Controller\Controllers.Notificacao.pas',
  Controllers.Cliente in 'Controller\Controllers.Cliente.pas',
  Controllers.Produto in 'Controller\Controllers.Produto.pas',
  Controllers.Pedido in 'Controller\Controllers.Pedido.pas',
  Controllers.CondPagto in 'Controller\Controllers.CondPagto.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.

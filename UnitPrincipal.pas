unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TFrmPrincipal = class(TForm)
    Label1: TLabel;
    memo: TMemo;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.fmx}

uses Horse, Horse.Jhonson, Horse.CORS, Controllers.Usuario,
Controllers.Notificacao, Controllers.Cliente, Controllers.Produto,
Horse.OctetStream, Horse.Upload, Controllers.Pedido, Controllers.CondPagto;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  THorse.Use(Jhonson());
  THorse.Use(CORS);
  THorse.Use(OctetStream);
  THorse.Use(Upload);

  //Rotas
  Controllers.Usuario.RegistrarRotas;
  Controllers.Notificacao.RegistrarRotas;
  Controllers.Cliente.RegistrarRotas;
  Controllers.Produto.RegistrarRotas;
  Controllers.Pedido.RegistrarRotas;
  Controllers.CondPagto.RegistrarRotas;

  THorse.Listen(9000);
  memo.Lines.Add('Servidor Executando na porta: ' + THorse.Port.ToString);

end;

end.

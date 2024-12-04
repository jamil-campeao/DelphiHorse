unit Controllers.Pedido;

interface

uses Horse, System.SysUtils, DataModuleGlobal, System.JSON,
Controllers.Auth, Horse.JWT, System.Classes;

procedure RegistrarRotas;
procedure ListarPedidos(Req: THorseRequest; Res: THorseResponse);
procedure InserirEditarPedido(Req: THorseRequest; Res: THorseResponse);

implementation

procedure RegistrarRotas;
begin
  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Get('/pedidos/sincronizacao', ListarPedidos);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Post('/pedidos/sincronizacao', InserirEditarPedido);
end;


procedure ListarPedidos(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vDtUltSincronizacao: String;
  vPagina, vCodUsuario : Integer;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vCodUsuario := GetUsuarioRequest(Req);

      try
        vDtUltSincronizacao := Req.Query['dt_ult_sincronizacao'];
      except
        vDtUltSincronizacao := '';
      end;

      try
        vPagina := Req.Query['pagina'].ToInteger;
      except
        vPagina := 1;
      end;

      Res.Send<TJsonArray>(DmGlobal.ListarPedidos(vDtUltSincronizacao, vCodUsuario, vPagina)).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure InserirEditarPedido(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
  vItens : TJsonArray;
begin
  try
    try
      DmGlobal    := TDMGlobal.Create(Nil);
      vCodUsuario := GetUsuarioRequest(Req);
      vBody       := Req.Body<TJSONObject>;
      vItens      := vBody.GetValue<TJsonArray>('itens');

      vJsonRet := DmGlobal.InserirEditarPedido(vCodUsuario,
                                                vbody.GetValue<integer>('cod_pedido_local',0),
                                                vbody.GetValue<integer>('cod_cliente',0),
                                                vbody.GetValue<string>('tipo_pedido',''),
                                                vbody.GetValue<string>('data_pedido',''),
                                                vbody.GetValue<string>('contato',''),
                                                vbody.GetValue<string>('obs',''),
                                                vbody.GetValue<double>('valor_total',0),
                                                vbody.GetValue<integer>('cod_cond_pgto',0),
                                                vbody.GetValue<string>('prazo_entrega',''),
                                                vbody.GetValue<string>('data_entrega',''),
                                                vbody.GetValue<integer>('cod_pedido_oficial',0),
                                                vbody.GetValue<string>('dt_ult_sincronizacao',''),
                                                vItens
                                                );

      vJsonRet.AddPair('cod_pedido_local', TJSONNumber.Create(vBody.GetValue<integer>('cod_pedido_local',0)));

      {"cod_pedido_local": 250, "cod_pedido_oficial": 4500}
      Res.Send<TJsonObject>(vJSonRet).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.

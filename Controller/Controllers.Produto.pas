unit Controllers.Produto;

interface

uses Horse, Horse.Jhonson, Horse.CORS, System.SysUtils, DataModuleGlobal,
System.JSON, Controllers.Auth, Horse.JWT, Horse.Upload, System.Classes,
FMX.Graphics;

procedure RegistrarRotas;
procedure ListarProdutos(Req: THorseRequest; Res: THorseResponse);
procedure InserirEditarProduto(Req: THorseRequest; Res: THorseResponse);
procedure ListarFoto(Req: THorseRequest; Res: THorseResponse);
procedure EditarFoto(Req: THorseRequest; Res: THorseResponse);

implementation

procedure RegistrarRotas;
begin
  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Get('/produtos/sincronizacao', ListarProdutos);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Post('/produtos/sincronizacao', InserirEditarProduto);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Get('/produtos/foto/:cod_produto', ListarFoto);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Put('/produtos/foto/:cod_produto', EditarFoto);
end;


procedure ListarProdutos(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vDtUltSincronizacao: String;
  vPagina : Integer;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

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

      Res.Send<TJsonArray>(DmGlobal.ListarProdutos(vDtUltSincronizacao, vPagina)).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure InserirEditarProduto(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal    := TDMGlobal.Create(Nil);
      vCodUsuario := GetUsuarioRequest(Req);
      vBody       := Req.Body<TJSONObject>;

      vJsonRet := DmGlobal.InserirEditarProduto(vCodUsuario,
                                                vbody.GetValue<integer>('cod_produto_local',0),
                                                vbody.GetValue<string>('descricao',''),
                                                vbody.GetValue<double>('valor',0),
                                                vbody.GetValue<double>('qtd_estoque',0),
                                                vbody.GetValue<integer>('cod_produto_oficial',0),
                                                vbody.GetValue<string>('dt_ult_sincronizacao','')
                                                );

      vJsonRet.AddPair('cod_produto_local', TJSONNumber.Create(vBody.GetValue<integer>('cod_produto_local',0)));

      {"cod_produto_local": 250, "cod_produto_oficial": 4500}
      Res.Send<TJsonObject>(vJSonRet).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ListarFoto(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vDtUltSincronizacao: String;
  vCodProduto : Integer;
  vFoto : TStream;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      try
        vCodProduto := Req.Params.Items['cod_produto'].ToInteger;
      except
        vCodProduto := 0;
      end;

      Res.Send<TStream>(DmGlobal.ListarFoto(vCodProduto)).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarFoto(Req: THorseRequest; Res: THorseResponse);
var
  vUploadConfig : TUploadConfig;
  vCodProduto   : Integer;
  vFoto         : TBitmap;
  DMGlobal      : TDMGlobal;
begin
  try
    vCodProduto := Req.Params.Items['cod_produto'].ToInteger;
  except
    vCodProduto := 0;
  end;

  vUploadConfig               := TUploadConfig.Create(ExtractFilePath(ParamStr(0)) + 'Fotos');
  vUploadConfig.ForceDir      := True;
  vUploadConfig.OverrideFiles := True;

  vUploadConfig.UploadFileCallBack :=
  procedure(Sender: TObject; AFile: TUploadFileInfo)
  begin
    try
      DmGlobal := TDMGlobal.Create(nil);
      vFoto    := TBitmap.CreateFromFile(AFile.fullpath);

      DmGlobal.EditarFoto(vCodProduto, vFoto);

      FreeAndNil(vFoto);
    finally
      FreeAndNil(DmGlobal);

    end;

  end;

  Res.Send<TUploadConfig>(vUploadConfig);
end;

end.

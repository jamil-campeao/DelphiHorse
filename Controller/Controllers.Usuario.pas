unit Controllers.Usuario;

interface

uses Horse, Horse.Jhonson, Horse.CORS, System.SysUtils, DataModuleGlobal,
System.JSON, Controllers.Auth, Horse.JWT;

procedure RegistrarRotas;
procedure InserirUsuario(Req: THorseRequest; Res: THorseResponse);
procedure Login(Req: THorseRequest; Res: THorseResponse);
procedure Push(Req: THorseRequest; Res: THorseResponse);
procedure EditarUsuario(Req: THorseRequest; Res: THorseResponse);
procedure EditarSenha(Req: THorseRequest; Res: THorseResponse);
procedure ObterDataServidor(Req: THorseRequest; Res: THorseResponse);
procedure ExcluirUsuario(Req: THorseRequest; Res: THorseResponse);

implementation

procedure RegistrarRotas;
begin
  THorse.Post('/usuarios', InserirUsuario);
  THorse.Post('/usuarios/login', Login);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Post('/usuarios/push', Push);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Put('/usuarios', EditarUsuario);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Put('/usuarios/senha', EditarSenha);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Get('/usuarios/horario', ObterDataServidor);

  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Delete('/usuarios/:cod_usuario', ExcluirUsuario);
end;

procedure InserirUsuario(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vTeste : String;
  vTeste2: String;
  vTeste3 : String;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vBody   := Req.Body<TJSONObject>;
      vTeste  := vBody.GetValue<string>('nome','');
      vTeste2 := vBody.GetValue<string>('email','');
      vTeste3 := vBody.GetValue<string>('senha','');

      vJsonRet := DMGlobal.InserirUsuario(vTeste, vTeste2, vTeste3);

      vJsonRet.AddPair('nome', vTeste);
      vJsonRet.AddPair('email', vTeste2);
//      vJsonRet.AddPair('senha', vTeste3);

      vCodUsuario := vJsonRet.GetValue<Integer>('cod_usuario',0);


      //Gero o token contendo o cod_usuario
      vJsonRet.AddPair('token', CriarToken(vCodUsuario));


      Res.Send<TJsonObject>(vJSonRet).Status(201);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure Login(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vTeste : String;
  vTeste2: String;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vBody   := Req.Body<TJSONObject>;
      vTeste  := vBody.GetValue<string>('email','');
      vTeste2 := vBody.GetValue<string>('senha','');

      vJsonRet := DMGlobal.Login(vTeste, vTeste2);

      if vJsonRet.Size = 0 then
        Res.Send('{"erro": "Email ou senha inv�lida"}').Status(401)
      else
      begin
        vCodUsuario := vJsonRet.GetValue<Integer>('cod_usuario',0);
        //Gero o token contendo o cod_usuario
        vJsonRet.AddPair('token', CriarToken(vCodUsuario));

        Res.Send<TJsonObject>(vJSonRet).Status(200);
      end;

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarUsuario(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vNome, vEmail: String;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vCodUsuario := GetUsuarioRequest(Req);
      vBody   := Req.Body<TJSONObject>;
      vNome  := vBody.GetValue<string>('nome','');
      vEmail  := vBody.GetValue<string>('email','');

      vJsonRet := DMGlobal.EditarUsuario(vCodUsuario, vNome, vEmail);

      Res.Send<TJsonObject>(vJSonRet).Status(200);
    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure Push(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vTokenPush: String;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vCodUsuario := GetUsuarioRequest(Req);
      vBody   := Req.Body<TJSONObject>;
      vTokenPush  := vBody.GetValue<string>('token_push','');

      vJsonRet := DMGlobal.Push(vCodUsuario, vTokenPush);

      Res.Send<TJsonObject>(vJSonRet).Status(200);
    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarSenha(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vSenha: String;
  vCodUsuario: Integer;
  vBody, vJsonRet : TJsonObject;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      vCodUsuario := GetUsuarioRequest(Req);
      vBody   := Req.Body<TJSONObject>;
      vSenha  := vBody.GetValue<string>('senha','');

      vJsonRet := DMGlobal.EditarSenha(vCodUsuario, vSenha);

      Res.Send<TJsonObject>(vJSonRet).Status(200);
    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ObterDataServidor(Req: THorseRequest; Res: THorseResponse);
begin
  Res.Send(FormatDateTime('yyyy-mm-dd hh:nn:ss', now)).Status(200);
end;

procedure ExcluirUsuario(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
  vCodUsuario: Integer;
  vJsonRet : TJsonObject;
  vCodUsuarioParam : Integer;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);
      vCodUsuario := GetUsuarioRequest(Req);

      try
        vCodUsuarioParam := Req.Params.Items['cod_usuario'].ToInteger
      except
        vCodUsuarioParam := 0;
      end;

      if vCodUsuario <> vCodUsuarioParam then
        raise Exception.Create('Opera��o n�o permitida');

      vJsonRet := DMGlobal.ExcluirUsuario(vCodUsuario);

      Res.Send<TJsonObject>(vJSonRet).Status(200);
    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;


end.

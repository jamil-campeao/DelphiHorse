unit Controllers.CondPagto;

interface

uses Horse, System.SysUtils, DataModuleGlobal, System.JSON,
Controllers.Auth, Horse.JWT, System.Classes;

procedure RegistrarRotas;
procedure ListarCondPagto(Req: THorseRequest; Res: THorseResponse);

implementation

procedure RegistrarRotas;
begin
  THorse.AddCallback(HorseJWT(Controllers.Auth.cSECRET, THorseJWTConfig.New.SessionClass(TMyClaims)))
  .Get('/cond-pagto', ListarCondPagto);
end;

procedure ListarCondPagto(Req: THorseRequest; Res: THorseResponse);
var
  DmGlobal: TDMGlobal;
begin
  try
    try
      DmGlobal := TDMGlobal.Create(Nil);

      Res.Send<TJsonArray>(DmGlobal.ListarCondPagto).Status(200);

    except on e: Exception do
      Res.Send(e.Message).Status(500);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;


end.

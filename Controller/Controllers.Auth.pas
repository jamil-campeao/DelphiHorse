unit Controllers.Auth;

interface

uses
  Horse, Horse.JWT, JOSE.Core.JWT, Jose.Types.JSON, Jose.Core.Builder,
  System.JSON, System.SysUtils;

const
  cSECRET = 'PASS@123';

type
  TMyClaims = class(TJWTClaims)
    private
    function GetCodUsuario: Integer;
    procedure SetCodUsuario(const Value: Integer);
    public
      property COD_USUARIO: Integer read GetCodUsuario write SetCodUsuario;

  end;

  function CriarToken(cod_usuario: Integer): String;
  function GetUsuarioRequest(Req: THorseRequest): Integer;

implementation

function CriarToken(cod_usuario: Integer): String;
var
  vJWT: TJWT;
  vClaims: TMyClaims;
begin
  try
    vJWT := TJWT.Create;
    vClaims := TMyClaims(vJWT.Claims);

    try
      vClaims.COD_USUARIO := cod_usuario;

      Result := TJOSE.SHA256CompactToken(cSECRET, vJWT);

    except
      Result := '';

    end;
  finally
    FreeAndNil(vJWT);

  end;

end;

function GetUsuarioRequest(Req: THorseRequest): Integer;
var
  vClaims: TMyClaims;
begin
  vClaims := Req.Session<TMyClaims>;
  Result := vClaims.COD_USUARIO;

end;

function TMyClaims.GetCodUsuario: Integer;
begin
  Result := FJSON.GetValue<Integer>('id', 0);
end;

procedure TMyClaims.SetCodUsuario(const Value: Integer);
begin
  TJSONUtils.SetJSONValueFrom<Integer>('id',Value,FJSON);

end;

end.

unit DataModuleGlobal;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.FMXUI.Wait, FireDAC.Phys.IBBase, Data.DB,
  FireDAC.Comp.Client, System.IniFiles, FireDac.DApt, System.JSON, DataSet.Serialize, DataSet.Serialize.Config,
  uMD5, FMX.Graphics;

type
  TDMGlobal = class(TDataModule)
    conn: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
    procedure connBeforeConnect(Sender: TObject);
  private
    procedure CarregarConfigDB(Connection: TFDConnection);
    procedure fValidaEmailUsuario(email: string; var vSQLQuery: TFDQuery; vEditando: Boolean; codigo_usuario: Integer = 0);
    function fListarItensPedido(pCodPedido: Integer; vSQLQuery: TFDQuery): TJsonArray;
    { Private declarations}
  public
    { Public declarations }
    function Login(email, senha: String): TJSONObject;
    function InserirUsuario(nome, email, senha: String): TJSONObject;
    function Push(cod_usuario: Integer; token_push: String): TJSONObject;
    function EditarUsuario(cod_usuario: Integer; nome,
      email: String): TJSONObject;
    function EditarSenha(cod_usuario: Integer; senha: String): TJSONObject;
    function ListarNotificacoes(cod_usuario: Integer): TJSONArray;
    function ListarClientes(dt_ult_sincronizacao: String; pagina: Integer) : TJSONArray;
    function InserirEditarCliente(cod_usuario, cod_cliente_local: Integer;
cnpj_cpf, nome, fone, email, endereco, numero, complemento, bairro, cidade, uf, cep: String;
latitude, longitude, limite_disponivel: Double;
cod_cliente_oficial: Integer;
dt_ult_sincronizacao: String): TJSONObject;
    function ListarProdutos(dt_ult_sincronizacao: String;
      pagina: Integer): TJSONArray;
    function InserirEditarProduto(cod_usuario, cod_produto_local: Integer;descricao: String;
valor, qtd_estoque: Double; cod_produto_oficial: Integer; dt_ult_sincronizacao: String): TJSONObject;
    function ListarFoto(cod_produto: Integer): TMemoryStream;
    procedure EditarFoto(cod_produto: Integer; foto: TBitMap);
    function ListarPedidos(dt_ult_sincronizacao: String; cod_usuario, pagina: Integer) : TJSONArray;
    function InserirEditarPedido(cod_usuario, cod_pedido_local, cod_cliente: Integer;
tipo_pedido, data_pedido, contato, obs: String;
valor_total: Double; cod_cond_pgto: Integer;
prazo_entrega, data_entrega: String;
cod_pedido_oficial: Integer; dt_ult_sincronizacao: String;
itens: TJSonArray): TJSONObject;
function ListarCondPagto: TJSONArray;
function ExcluirUsuario(cod_usuario: Integer): TJSONObject;
  end;

var
  DMGlobal: TDMGlobal;

Const
  cQTD_REG_PAGINA_CLIENTE = 5;
  cQTD_REG_PAGINA_PRODUTO = 5;
  cQTD_REG_PAGINA_PEDIDO  = 5;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDmGlobal.CarregarConfigDB(Connection: TFDConnection);
var
    ini : TIniFile;
    arq: string;
begin
    try
        // Caminho do INI...
        arq := ExtractFilePath(ParamStr(0)) + 'config.ini';

        // Validar arquivo INI...
        if NOT FileExists(arq) then
            raise Exception.Create('Arquivo INI n�o encontrado: ' + arq);

        // Instanciar arquivo INI...
        ini := TIniFile.Create(arq);
        Connection.DriverName := ini.ReadString('Banco de Dados', 'DriverID', '');

        // Buscar dados do arquivo fisico...
        with Connection.Params do
        begin
            Clear;
            Add('DriverID=' + ini.ReadString('Banco de Dados', 'DriverID', ''));
            Add('Database=' + ini.ReadString('Banco de Dados', 'Database', ''));
            Add('User_Name=' + ini.ReadString('Banco de Dados', 'User_name', ''));
            Add('Password=' + ini.ReadString('Banco de Dados', 'Password', ''));

            if ini.ReadString('Banco de Dados', 'Port', '') <> '' then
                Add('Port=' + ini.ReadString('Banco de Dados', 'Port', ''));

            if ini.ReadString('Banco de Dados', 'Server', '') <> '' then
                Add('Server=' + ini.ReadString('Banco de Dados', 'Server', ''));

            if ini.ReadString('Banco de Dados', 'Protocol', '') <> '' then
                Add('Protocol=' + ini.ReadString('Banco de Dados', 'Protocol', ''));

            if ini.ReadString('Banco de Dados', 'VendorLib', '') <> '' then
                FDPhysFBDriverLink1.VendorLib := ini.ReadString('Banco de Dados', 'VendorLib', '');
        end;

    finally
        if Assigned(ini) then
            ini.DisposeOf;
    end;
end;

procedure TDMGlobal.connBeforeConnect(Sender: TObject);
begin
  CarregarConfigDB(Conn);
end;

procedure TDMGlobal.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
  TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';
  Conn.Connected := True;
end;

function TDMGlobal.Login(email, senha: String) : TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  if (email.IsEmpty) or (senha.IsEmpty) then
    raise Exception.Create('Informe o e-mail e a senha');

  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT COD_USUARIO, NOME, EMAIL  '+
                          ' FROM TAB_USUARIO                 '+
                          ' WHERE EMAIL = :EMAIL             '+
                          ' AND SENHA   = :SENHA             ';

    vSQLQuery.ParamByName('EMAIL').AsString := email;
    vSQLQuery.ParamByName('SENHA').AsString := SaltPassword(senha);


    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);

  end;

end;

function TDMGlobal.InserirUsuario(nome,email, senha: String) : TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  if (nome.IsEmpty) or (email.IsEmpty) or (senha.IsEmpty) then
    raise Exception.Create('Informe o nome, e-mail e a senha');

  if senha.Length < 5 then
    raise Exception.Create('A senha deve conter pelo menos 5 caracteres');

  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    fValidaEmailUsuario(email, vSQLQuery, False);

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' INSERT INTO                                   '+
                          ' TAB_USUARIO(NOME, EMAIL, SENHA, IND_EXCLUIDO) '+
                          ' VALUES(:NOME, :EMAIL, :SENHA, :IND_EXCLUIDO)  '+
                          ' RETURNING COD_USUARIO                         ';

    vSQLQuery.ParamByName('NOME').AsString         := nome;
    vSQLQuery.ParamByName('EMAIL').AsString        := email;
    vSQLQuery.ParamByName('SENHA').AsString        := SaltPassword(senha);
    vSQLQuery.ParamByName('IND_EXCLUIDO').AsString := 'N';


    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.Push(cod_usuario: Integer; token_push: String) : TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  if token_push.IsEmpty then
    raise Exception.Create('Informe o token_push do usu�rio');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' UPDATE TAB_USUARIO               '+
                          ' SET TOKEN_PUSH = :TOKEN_PUSH     '+
                          ' WHERE COD_USUARIO = :COD_USUARIO '+
                          ' RETURNING COD_USUARIO            ';

    vSQLQuery.ParamByName('TOKEN_PUSH').AsString  := token_push;
    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;
end;

function TDMGlobal.EditarUsuario(cod_usuario: Integer; nome, email: String) : TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  if (nome.IsEmpty) or (email.IsEmpty) then
    raise Exception.Create('Informe o nome e o e-mail do usu�rio');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    fValidaEmailUsuario(email, vSQLQuery, True, cod_usuario);

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' UPDATE TAB_USUARIO               '+
                          ' SET NOME = :NOME, EMAIL = :EMAIL '+
                          ' WHERE COD_USUARIO = :COD_USUARIO '+
                          ' RETURNING COD_USUARIO            ';

    vSQLQuery.ParamByName('NOME').AsString  := nome;
    vSQLQuery.ParamByName('EMAIL').AsString := email;
    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.EditarSenha(cod_usuario: Integer; senha: String) : TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  if senha.IsEmpty then
    raise Exception.Create('Informe a nova senha do usu�rio');

  if senha.Length < 5 then
    raise Exception.Create('A senha deve conter pelo menos 5 caracteres');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' UPDATE TAB_USUARIO               '+
                          ' SET SENHA = :SENHA               '+
                          ' WHERE COD_USUARIO = :COD_USUARIO '+
                          ' RETURNING COD_USUARIO            ';

    vSQLQuery.ParamByName('SENHA').AsString := SaltPassword(senha);
    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;

end;

procedure TDMGlobal.fValidaEmailUsuario(email: string; var vSQLQuery: TFDQuery; vEditando: Boolean; codigo_usuario: Integer = 0);
begin
  //Valida��o do e-mail
  vSQLQuery.Active := False;
  vSQLQuery.SQL.Clear;
  vSQLQuery.SQL.Text := ' SELECT COD_USUARIO  ' +
                        ' FROM TAB_USUARIO    ' +
                        ' WHERE EMAIL =:EMAIL ';
  if vEditando then
  begin
    vSQLQuery.SQL.Add(' AND COD_USUARIO <> :COD_USUARIO');
    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := codigo_usuario;
  end;

  vSQLQuery.ParamByName('EMAIL').AsString := email;

  vSQLQuery.Active := True;
  if vSQLQuery.RecordCount > 0 then
    raise Exception.Create('Esse e-mail j� esta em uso por outra conta de usu�rio');
end;

function TDMGlobal.ListarNotificacoes(cod_usuario: Integer) : TJSONArray;
var
  vSQLQuery  : TFDQuery;
begin
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT                         '+
                          ' COD_NOTIFICACAO,               '+
                          ' DATA_NOTIFICACAO,              '+
                          ' TITULO,                        '+
                          ' TEXTO                          '+
                          ' FROM TAB_NOTIFICACAO           '+
                          ' WHERE IND_LIDO = ''N''         '+
                          ' AND COD_USUARIO = :COD_USUARIO ';

    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONArray;

    //Marca as mensagens como lidas...

    vSQLQuery.Active := True;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' UPDATE TAB_NOTIFICACAO          '+
                           ' SET IND_LIDO = ''S''           '+
                           ' WHERE IND_LIDO  = ''N''        '+
                           ' AND COD_USUARIO = :COD_USUARIO ';

    vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;

    vSQLQuery.ExecSQL;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.ListarClientes(dt_ult_sincronizacao: String; pagina: Integer) : TJSONArray;
var
  vSQLQuery  : TFDQuery;
begin
  if dt_ult_sincronizacao = '' then
    raise Exception.Create('Par�metro dt_ult_sincronizacao n�o informado');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT FIRST :FIRST SKIP :SKIP *             '+
                          ' FROM TAB_CLIENTE                             '+
                          ' WHERE DATA_ULT_ALTERACAO > :DATAULTALTERACAO '+
                          ' ORDER BY 1                                   ';

    vSQLQuery.ParamByName('DATAULTALTERACAO').AsString := dt_ult_sincronizacao;
    vSQLQuery.ParamByName('FIRST').AsInteger := cQTD_REG_PAGINA_CLIENTE;
    vSQLQuery.ParamByName('SKIP').AsInteger := (pagina * cQTD_REG_PAGINA_CLIENTE) - cQTD_REG_PAGINA_CLIENTE;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONArray;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.InserirEditarCliente(cod_usuario, cod_cliente_local: Integer;
cnpj_cpf, nome, fone, email, endereco, numero, complemento, bairro, cidade, uf, cep: String;
latitude, longitude, limite_disponivel: Double;
cod_cliente_oficial: Integer;
dt_ult_sincronizacao: String): TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;

    if cod_cliente_oficial = 0 then
    begin
      vSQLQuery.SQL.Text := ' INSERT INTO TAB_CLIENTE                             '+
                            ' (COD_USUARIO, CNPJ_CPF, NOME, FONE, EMAIL,          '+
                            ' ENDERECO, NUMERO, COMPLEMENTO, BAIRRO, CIDADE,      '+
                            ' UF, CEP, LATITUDE, LONGITUDE,                       '+
                            ' LIMITE_DISPONIVEL, DATA_ULT_ALTERACAO)              '+
                            ' VALUES                                              '+
                            ' (:COD_USUARIO, :CNPJ_CPF, :NOME, :FONE, :EMAIL,     '+
                            ' :ENDERECO, :NUMERO, :COMPLEMENTO, :BAIRRO, :CIDADE, '+
                            ' :UF, :CEP, :LATITUDE, :LONGITUDE,                   '+
                            ' :LIMITE_DISPONIVEL, :DATAULTALTERACAO)              '+
                            ' RETURNING COD_CLIENTE                               ';

      vSQLQuery.ParamByName('COD_USUARIO').AsInteger           := cod_usuario;
    end
    else
    begin
      vSQLQuery.SQL.Text := ' UPDATE TAB_CLIENTE                                      '+
                            ' SET CNPJ_CPF = :CNPJ_CPF, NOME = :NOME, FONE = :FONE,   '+
                            ' EMAIL = :EMAIL, ENDERECO = :ENDERECO, NUMERO = :NUMERO, '+
                            ' COMPLEMENTO = :COMPLEMENTO, BAIRRO = :BAIRRO,           '+
                            ' CIDADE = :CIDADE, UF = :UF, CEP = :CEP,                 '+
                            ' LATITUDE = :LATITUDE, LONGITUDE = :LONGITUDE,           '+
                            ' LIMITE_DISPONIVEL = :LIMITE_DISPONIVEL,                 '+
                            ' DATA_ULT_ALTERACAO = :DATAULTALTERACAO                  '+
                            ' WHERE COD_CLIENTE = :COD_CLIENTE                        '+
                            ' RETURNING COD_CLIENTE                                   ';

      vSQLQuery.ParamByName('COD_CLIENTE').AsInteger         := cod_cliente_oficial;
    end;

    vSQLQuery.ParamByName('CNPJ_CPF').AsString               := cnpj_cpf;
    vSQLQuery.ParamByName('NOME').AsString                   := nome;
    vSQLQuery.ParamByName('FONE').AsString                   := fone;
    vSQLQuery.ParamByName('EMAIL').AsString                  := email;
    vSQLQuery.ParamByName('ENDERECO').AsString               := endereco;
    vSQLQuery.ParamByName('NUMERO').AsString                 := numero;
    vSQLQuery.ParamByName('COMPLEMENTO').AsString            := complemento;
    vSQLQuery.ParamByName('BAIRRO').AsString                 := bairro;
    vSQLQuery.ParamByName('CIDADE').AsString                 := cidade;
    vSQLQuery.ParamByName('UF').AsString                     := uf;
    vSQLQuery.ParamByName('CEP').AsString                    := cep;
    vSQLQuery.ParamByName('LATITUDE').AsFloat                := latitude;
    vSQLQuery.ParamByName('LONGITUDE').AsFloat               := longitude;
    vSQLQuery.ParamByName('LIMITE_DISPONIVEL').AsFloat       := limite_disponivel;
    vSQLQuery.ParamByName('DATAULTALTERACAO').Value          := dt_ult_sincronizacao;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;
end;

function TDMGlobal.ListarProdutos(dt_ult_sincronizacao: String; pagina: Integer) : TJSONArray;
var
  vSQLQuery  : TFDQuery;
begin
  if dt_ult_sincronizacao = '' then
    raise Exception.Create('Par�metro dt_ult_sincronizacao n�o informado');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT FIRST :FIRST SKIP :SKIP                '+
                          ' COD_PRODUTO, DESCRICAO, VALOR, QTD_ESTOQUE,   '+
                          ' COD_USUARIO, DATA_ULT_ALTERACAO               '+
                          ' FROM TAB_PRODUTO                              '+
                          ' WHERE DATA_ULT_ALTERACAO > :DATAULTALTERACAO  '+
                          ' ORDER BY 1                                    ';

    vSQLQuery.ParamByName('DATAULTALTERACAO').AsString := dt_ult_sincronizacao;
    vSQLQuery.ParamByName('FIRST').AsInteger := cQTD_REG_PAGINA_PRODUTO;
    vSQLQuery.ParamByName('SKIP').AsInteger := (pagina * cQTD_REG_PAGINA_PRODUTO) - cQTD_REG_PAGINA_CLIENTE;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONArray;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.InserirEditarProduto(cod_usuario, cod_produto_local: Integer;descricao: String;
valor, qtd_estoque: Double; cod_produto_oficial: Integer; dt_ult_sincronizacao: String): TJSONObject;
var
  vSQLQuery : TFDQuery;
begin
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;

    if cod_produto_oficial = 0 then
    begin
      vSQLQuery.SQL.Text := ' INSERT INTO TAB_PRODUTO                                             '+
                            ' (DESCRICAO, VALOR, QTD_ESTOQUE, COD_USUARIO, DATA_ULT_ALTERACAO)    '+
                            ' VALUES                                                              '+
                            ' (:DESCRICAO, :VALOR, :QTD_ESTOQUE, :COD_USUARIO, :DATAULTALTERACAO) '+
                            ' RETURNING COD_PRODUTO                                               ';

      vSQLQuery.ParamByName('COD_USUARIO').AsInteger  := cod_usuario;
    end
    else
    begin
      vSQLQuery.SQL.Text := ' UPDATE TAB_PRODUTO                                                 '+
                            ' SET DESCRICAO = :DESCRICAO, VALOR = :VALOR,                        '+
                            ' QTD_ESTOQUE = :QTD_ESTOQUE, DATA_ULT_ALTERACAO = :DATAULTALTERACAO '+
                            ' WHERE COD_PRODUTO = :COD_PRODUTO                                   '+
                            ' RETURNING COD_PRODUTO                                              ';

      vSQLQuery.ParamByName('COD_PRODUTO').AsInteger := cod_produto_oficial;
    end;

    vSQLQuery.ParamByName('DESCRICAO').AsString      := descricao;
    vSQLQuery.ParamByName('VALOR').AsFloat           := valor;
    vSQLQuery.ParamByName('QTD_ESTOQUE').AsFloat     := qtd_estoque;
    vSQLQuery.ParamByName('DATAULTALTERACAO').Value  := dt_ult_sincronizacao;

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONObject;
  finally
    FreeAndNil(vSQLQuery);
  end;
end;

function TDMGlobal.ListarFoto(cod_produto: Integer): TMemoryStream;
var
  vSQLQuery  : TFDQuery;
  vLStream : TStream;
begin
  if cod_produto <= 0 then
    raise Exception.Create('Par�metro dt_ult_sincronizacao n�o informado');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT FOTO                      '+
                          ' FROM TAB_PRODUTO                 '+
                          ' WHERE COD_PRODUTO = :COD_PRODUTO ';

    vSQLQuery.ParamByName('COD_PRODUTO').AsInteger := cod_produto;

    vSQLQuery.Active := True;

    if vSQLQuery.FieldByName('FOTO').AsString = '' then
      raise Exception.Create('O produto n�o possui foto cadastrada!');

    vLStream := vSQLQuery.CreateBlobStream(vSQLQuery.FieldByName('FOTO'), TBlobStreamMode.bmRead);

    Result := TMemoryStream.Create;
    Result.LoadFromStream(vLStream);

  finally
    FreeAndNil(vSQLQuery);
    FreeAndNil(vLStream);
  end;

end;

procedure TDMGlobal.EditarFoto(cod_produto: Integer; foto: TBitMap);
var
  vSQLQuery  : TFDQuery;
  vLStream : TStream;
begin
  if cod_produto <= 0 then
    raise Exception.Create('Par�metro dt_ult_sincronizacao n�o informado');
  if foto = nil then
    raise Exception.Create('Par�metro foto n�o informado');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' UPDATE TAB_PRODUTO               '+
                          ' SET FOTO = :FOTO                 '+
                          ' WHERE COD_PRODUTO = :COD_PRODUTO ';

    vSQLQuery.ParamByName('FOTO').Assign(foto);
    vSQLQuery.ParamByName('COD_PRODUTO').AsInteger := cod_produto;

    vSQLQuery.ExecSQL;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.ListarPedidos(dt_ult_sincronizacao: String; cod_usuario, pagina: Integer) : TJSONArray;
var
  vSQLQuery  : TFDQuery;
  vPedidos   : TJsonArray;
  i          : Integer;
begin
  if dt_ult_sincronizacao = '' then
    raise Exception.Create('Par�metro dt_ult_sincronizacao n�o informado');
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT FIRST :FIRST SKIP :SKIP *               '+
                          ' FROM TAB_PEDIDO                                '+
                          ' WHERE DATA_ULT_ALTERACAO > :DATA_ULT_ALTERACAO '+
                          ' AND COD_USUARIO = :COD_USUARIO                 '+
                          ' ORDER BY 1                                     ';

    vSQLQuery.ParamByName('DATA_ULT_ALTERACAO').AsString := dt_ult_sincronizacao;
    vSQLQuery.ParamByName('FIRST').AsInteger             := cQTD_REG_PAGINA_PEDIDO;
    vSQLQuery.ParamByName('SKIP').AsInteger              := (pagina * cQTD_REG_PAGINA_PEDIDO) - cQTD_REG_PAGINA_PEDIDO;
    vSQLQuery.ParamByName('COD_USUARIO').AsInteger       := cod_usuario;


    vSQLQuery.Active := True;

    vPedidos := vSQLQuery.ToJSONArray;

    for I := 0 to vPedidos.Size - 1 do
        (vPedidos[i] as TJSONObject).AddPair('itens', fListarItensPedido(vPedidos[i].GetValue<integer>('cod_pedido', 0), vSQLQuery));

    Result := vPedidos;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.fListarItensPedido(pCodPedido: Integer; vSQLQuery: TFDQuery): TJsonArray;
begin
  vSQLQuery.Active := False;
  vSQLQuery.SQL.Clear;
  vSQLQuery.SQL.Text := ' SELECT                          ' +
                        ' COD_ITEM,                       ' +
                        ' COD_PRODUTO,                    ' +
                        ' QTD,                            ' +
                        ' VALOR_UNITARIO,                 ' +
                        ' VALOR_TOTAL                     ' +
                        ' FROM TAB_PEDIDO_ITEM            ' +
                        ' WHERE COD_PEDIDO = :COD_PEDIDO  ' +
                        ' ORDER BY 1                      ';

  vSQLQuery.ParamByName('COD_PEDIDO').AsInteger := pCodPedido;
  vSQLQuery.Active := True;

  Result := vSQLQuery.ToJSONArray;

end;

function TDMGlobal.InserirEditarPedido(cod_usuario, cod_pedido_local, cod_cliente: Integer;
tipo_pedido, data_pedido, contato, obs: String;
valor_total: Double; cod_cond_pgto: Integer;
prazo_entrega, data_entrega: String;
cod_pedido_oficial: Integer; dt_ult_sincronizacao: String;
itens: TJSonArray): TJSONObject;
var
  vSQLQueryCabecalho : TFDQuery;
  vSQLQueryDetalhe   : TFDQuery;
  i                  : Integer;
begin
  try
    try
      Conn.StartTransaction;

      vSQLQueryCabecalho := TFDQuery.Create(nil);
      vSQLQueryDetalhe   := TFDQuery.Create(nil);

      vSQLQueryCabecalho.Connection := Conn;
      vSQLQueryDetalhe.Connection   := Conn;

      vSQLQueryCabecalho.Active := False;
      vSQLQueryCabecalho.SQL.Clear;

      if cod_pedido_oficial = 0 then
      begin
        vSQLQueryCabecalho.SQL.Text :=  ' INSERT INTO TAB_PEDIDO                                             '+
                                        ' (COD_CLIENTE, COD_USUARIO, TIPO_PEDIDO, DATA_PEDIDO, CONTATO,      '+
                                        ' OBS, VALOR_TOTAL, COD_COND_PAGTO, PRAZO_ENTREGA, DATA_ENTREGA,     '+
                                        ' COD_PEDIDO_LOCAL, DATA_ULT_ALTERACAO)                              '+
                                        ' VALUES                                                             '+
                                        ' (:COD_CLIENTE, :COD_USUARIO, :TIPO_PEDIDO, :DATA_PEDIDO, :CONTATO, '+
                                        ' :OBS, :VALOR_TOTAL, :COD_COND_PAGTO, :PRAZO_ENTREGA, :DATA_ENTREGA,'+
                                        ' :COD_PEDIDO_LOCAL, :DATA_ULT_ALTERACAO)                            '+
                                        ' RETURNING COD_PEDIDO                                               ';

        vSQLQueryCabecalho.ParamByName('COD_PEDIDO_LOCAL').AsInteger  := cod_pedido_local;
      end
      else
      begin
        vSQLQueryCabecalho.SQL.Text :=  ' UPDATE TAB_PEDIDO                                                 '+
                                        ' SET COD_CLIENTE = :COD_CLIENTE, COD_USUARIO = :COD_USUARIO,       '+
                                        ' TIPO_PEDIDO = :TIPO_PEDIDO, DATA_PEDIDO = :DATA_PEDIDO,           '+
                                        ' CONTATO = :CONTATO, OBS = :OBS, VALOR_TOTAL = :VALOR_TOTAL,       '+
                                        ' COD_COND_PAGTO = :COD_COND_PAGTO, PRAZO_ENTREGA = :PRAZO_ENTREGA, '+
                                        ' DATA_ENTREGA = :DATA_ENTREGA,                                     '+
                                        ' DATA_ULT_ALTERACAO = :DATA_ULT_ALTERACAO                          '+
                                        ' WHERE COD_PEDIDO = :COD_PEDIDO                                    '+
                                        ' RETURNING COD_PEDIDO                                              ';

        vSQLQueryCabecalho.ParamByName('COD_PEDIDO').AsInteger := cod_pedido_oficial;
      end;

      vSQLQueryCabecalho.ParamByName('COD_USUARIO').AsInteger       := cod_usuario;
      vSQLQueryCabecalho.ParamByName('COD_CLIENTE').AsInteger       := cod_cliente;
      vSQLQueryCabecalho.ParamByName('TIPO_PEDIDO').AsString        := tipo_pedido;
      vSQLQueryCabecalho.ParamByName('DATA_PEDIDO').AsString        := data_pedido;
      vSQLQueryCabecalho.ParamByName('CONTATO').AsString            := contato;
      vSQLQueryCabecalho.ParamByName('OBS').AsString                := obs;
      vSQLQueryCabecalho.ParamByName('VALOR_TOTAL').AsFloat         := valor_total;
      vSQLQueryCabecalho.ParamByName('COD_COND_PAGTO').AsInteger    := cod_cond_pgto;
      vSQLQueryCabecalho.ParamByName('DATA_ENTREGA').AsString       := data_entrega;
      vSQLQueryCabecalho.ParamByName('DATA_ULT_ALTERACAO').AsString := dt_ult_sincronizacao;

      if data_entrega <> '' then
        vSQLQueryCabecalho.ParamByName('PRAZO_ENTREGA').AsString      := prazo_entrega
      else
      begin
        vSQLQueryCabecalho.ParamByName('PRAZO_ENTREGA').DataType := ftString;
        vSQLQueryCabecalho.ParamByName('PRAZO_ENTREGA').Clear;
      end;

      vSQLQueryCabecalho.Active := True;

      cod_pedido_oficial := vSQLQueryCabecalho.FieldByName('COD_PEDIDO').AsInteger;
      Result := vSQLQueryCabecalho.ToJSONObject;


      //itens do pedido
      vSQLQueryDetalhe.Active := False;
      vSQLQueryDetalhe.SQL.Clear;

      vSQLQueryDetalhe.SQL.Text :=    ' DELETE FROM TAB_PEDIDO_ITEM    '+
                                      ' WHERE COD_PEDIDO = :COD_PEDIDO ';

      vSQLQueryDetalhe.ParamByName('COD_PEDIDO').AsInteger := vSQLQueryCabecalho.FieldByName('COD_PEDIDO').AsInteger;
      vSQLQueryDetalhe.ExecSQL;

      for I := 0 to itens.Size - 1 do
      begin
        vSQLQueryDetalhe.Active := False;
        vSQLQueryDetalhe.SQL.Clear;

        vSQLQueryDetalhe.SQL.Text :=    ' INSERT INTO TAB_PEDIDO_ITEM       '+
                                        ' (COD_PEDIDO, COD_PRODUTO, QTD,    '+
                                        ' VALOR_UNITARIO, VALOR_TOTAL)      '+
                                        ' VALUES                            '+
                                        ' (:COD_PEDIDO, :COD_PRODUTO, :QTD, '+
                                        ' :VALOR_UNITARIO, :VALOR_TOTAL)    ';

        vSQLQueryDetalhe.ParamByName('COD_PEDIDO').AsInteger   := cod_pedido_oficial;
        vSQLQueryDetalhe.ParamByName('COD_PRODUTO').AsInteger  := itens[i].GetValue<integer>('cod_produto',0);
        vSQLQueryDetalhe.ParamByName('QTD').AsFloat            := itens[i].GetValue<double>('qtd',0);
        vSQLQueryDetalhe.ParamByName('VALOR_UNITARIO').AsFloat := itens[i].GetValue<double>('valor_unitario',0);
        vSQLQueryDetalhe.ParamByName('VALOR_TOTAL').AsFloat    := itens[i].GetValue<double>('valor_total',0);

        vSQLQueryDetalhe.ExecSQL;
      end;

      Conn.Commit;

    except on e:Exception do
      begin
        Conn.Rollback;
        raise Exception.Create('Erro ao inserir ou atualizar pedido: ' + e.Message);
      end;
    end;
  finally
    FreeAndNil(vSQLQueryCabecalho);
  end;
end;

function TDMGlobal.ListarCondPagto: TJSONArray;
var
  vSQLQuery  : TFDQuery;
begin
  try
    vSQLQuery := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    vSQLQuery.Active := False;
    vSQLQuery.SQL.Clear;
    vSQLQuery.SQL.Text := ' SELECT               '+
                          ' COD_COND_PAGTO,      '+
                          ' COND_PAGTO           '+
                          ' FROM TAB_COND_PAGTO  '+
                          ' ORDER BY 1           ';

    vSQLQuery.Active := True;

    Result := vSQLQuery.ToJSONArray;

  finally
    FreeAndNil(vSQLQuery);
  end;

end;

function TDMGlobal.ExcluirUsuario(cod_usuario: Integer): TJSONObject;
var
  vSQLQuery  : TFDQuery;
begin
  try
    vSQLQuery            := TFDQuery.Create(nil);
    vsQLQuery.Connection := Conn;

    try
      Conn.StartTransaction;
      vSQLQuery.Active := False;
      vSQLQuery.SQL.Clear;
      vSQLQuery.SQL.Text := ' UPDATE TAB_USUARIO                        '+
                            ' SET NOME = :NOME, EMAIL = :EMAIL,         '+
                            ' SENHA = :SENHA, TOKEN_PUSH = :TOKEN_PUSH, '+
                            ' IND_EXCLUIDO = :IND_EXCLUIDO              '+
                            ' WHERE IND_EXCLUIDO = ''N''                '+
                            ' AND COD_USUARIO = :COD_USUARIO            '+
                            ' RETURNING COD_USUARIO                     ';

      vSQLQuery.ParamByName('NOME').AsString         := 'Usu�rio Exclu�do';
      vSQLQuery.ParamByName('EMAIL').AsString        := 'Usu�rio Exclu�do';
      vSQLQuery.ParamByName('SENHA').AsString        := 'Usu�rio Exclu�do';
      vSQLQuery.ParamByName('TOKEN_PUSH').AsString   := 'Usu�rio Exclu�do';
      vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;
      vSQLQuery.ParamByName('IND_EXCLUIDO').AsString := 'S';


      vSQLQuery.Active := True;

      Result := vSQLQuery.ToJSONObject;


      vSQLQuery.Active := False;
      vSQLQuery.SQL.Clear;
      vSQLQuery.SQL.Text := ' DELETE FROM TAB_NOTIFICACAO               '+
                            ' WHERE COD_USUARIO = :COD_USUARIO          ';

      vSQLQuery.ParamByName('COD_USUARIO').AsInteger := cod_usuario;


      vSQLQuery.ExecSQL;


      Conn.Commit;

    except on e:Exception do
      begin
        Conn.Rollback;
        raise Exception.Create('Erro ao deletar dados do usu�rio: ' + e.Message);
      end;

    end;
  finally
    FreeAndNil(vSQLQuery);
  end;

end;





end.

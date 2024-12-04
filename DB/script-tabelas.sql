CREATE TABLE TAB_USUARIO (
    COD_USUARIO INT NOT NULL PRIMARY KEY,
    NOME        VARCHAR(100),
    EMAIL       VARCHAR(100),
    SENHA       VARCHAR(50),
    TOKEN_PUSH  VARCHAR(200),
    PLATAFORMA  VARCHAR(50),
	IND_EXCLUIDO 	   CHAR(1)
);

 
create generator gen_usuario_id;

CREATE TRIGGER TR_USUARIO FOR TAB_USUARIO
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_USUARIO =gen_id(gen_usuario_id, 1);
END;


/******************************************************/


CREATE TABLE TAB_CLIENTE( 
    COD_CLIENTE  INT NOT NULL PRIMARY KEY,
    COD_USUARIO  INT,
    CNPJ_CPF     VARCHAR(20),
    NOME         VARCHAR(100),
    FONE         VARCHAR(20),
    EMAIL        VARCHAR(100),
    ENDERECO     VARCHAR(500),
    NUMERO       VARCHAR(50),
    COMPLEMENTO  VARCHAR(50),
    BAIRRO       VARCHAR(50),
    CIDADE       VARCHAR(50),
    UF           VARCHAR(2),
    CEP          VARCHAR(10),
    LATITUDE     DECIMAL(12,6),
    LONGITUDE    DECIMAL(12,6),
    LIMITE_DISPONIVEL DECIMAL(12,2),
    DATA_ULT_ALTERACAO TIMESTAMP
);

ALTER TABLE TAB_CLIENTE
ADD FOREIGN KEY (COD_USUARIO)
REFERENCES TAB_USUARIO(COD_USUARIO);

create generator gen_cliente_id;

CREATE TRIGGER TR_CLIENTE FOR TAB_CLIENTE
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_CLIENTE =gen_id(gen_cliente_id, 1);
END;


/******************************************************/


CREATE TABLE TAB_NOTIFICACAO(    
    COD_NOTIFICACAO INT NOT NULL PRIMARY KEY,
    COD_USUARIO INT,
    DATA_NOTIFICACAO TIMESTAMP,
    TITULO        VARCHAR(100),
    TEXTO        VARCHAR(500),    
    IND_LIDO    CHAR(1)
);

ALTER TABLE TAB_NOTIFICACAO
ADD FOREIGN KEY (COD_USUARIO)
REFERENCES TAB_USUARIO(COD_USUARIO);


create generator gen_notificacao_id;

CREATE TRIGGER TR_NOTIFICACAO FOR TAB_NOTIFICACAO
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_NOTIFICACAO =gen_id(gen_notificacao_id, 1);
END;



/******************************************************/


CREATE TABLE TAB_PRODUTO(
    COD_PRODUTO    INT NOT NULL PRIMARY KEY,
    DESCRICAO    VARCHAR(200),
    VALOR        DECIMAL(12,2),
    FOTO        BLOB,
    QTD_ESTOQUE DECIMAL(12,2),
    COD_USUARIO INT,
    DATA_ULT_ALTERACAO TIMESTAMP
);

ALTER TABLE TAB_PRODUTO
ADD FOREIGN KEY (COD_USUARIO)
REFERENCES TAB_USUARIO(COD_USUARIO);

create generator gen_produto_id;

CREATE TRIGGER TR_PRODUTO FOR TAB_PRODUTO
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_PRODUTO =gen_id(gen_produto_id, 1);
END;


/******************************************************/



CREATE TABLE TAB_COND_PAGTO(
    COD_COND_PAGTO     INT NOT NULL PRIMARY KEY,
    COND_PAGTO         VARCHAR(100),
    DATA_ULT_ALTERACAO TIMESTAMP,
	IND_EXCLUIDO 	   CHAR(1)
);

create generator gen_cond_pagto_id;

CREATE TRIGGER TR_COND_PAGTO FOR TAB_COND_PAGTO
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_COND_PAGTO =gen_id(gen_cond_pagto_id, 1);
END;


/******************************************************/


CREATE TABLE TAB_PEDIDO(
    COD_PEDIDO    INT NOT NULL PRIMARY KEY,
    COD_CLIENTE    INT,
    COD_USUARIO    INT,
    TIPO_PEDIDO    CHAR(1),
    DATA_PEDIDO    TIMESTAMP,
    CONTATO        VARCHAR(100),    
    OBS            VARCHAR(500),
    VALOR_TOTAL     DECIMAL(12,2),
    COD_COND_PAGTO   INT,
    PRAZO_ENTREGA   VARCHAR(50),
    DATA_ENTREGA    TIMESTAMP,
    COD_PEDIDO_LOCAL INT,
    DATA_ULT_ALTERACAO TIMESTAMP
);

ALTER TABLE TAB_PEDIDO
ADD FOREIGN KEY (COD_USUARIO)
REFERENCES TAB_USUARIO(COD_USUARIO);

ALTER TABLE TAB_PEDIDO
ADD FOREIGN KEY (COD_CLIENTE)
REFERENCES TAB_CLIENTE(COD_CLIENTE);

ALTER TABLE TAB_PEDIDO
ADD FOREIGN KEY (COD_COND_PAGTO)
REFERENCES TAB_COND_PAGTO(COD_COND_PAGTO);

create generator gen_pedido_id;

CREATE TRIGGER TR_PEDIDO FOR TAB_PEDIDO
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_PEDIDO =gen_id(gen_pedido_id, 1);
END;



/******************************************************/


CREATE TABLE TAB_PEDIDO_ITEM(
    COD_ITEM        INT NOT NULL PRIMARY KEY,
    COD_PEDIDO      INT NOT NULL,
    COD_PRODUTO     INT,
    QTD             INT,
    VALOR_UNITARIO  DECIMAL(12,2),
    VALOR_TOTAL     DECIMAL(12,2)
);

ALTER TABLE TAB_PEDIDO_ITEM
ADD FOREIGN KEY (COD_PEDIDO)
REFERENCES TAB_PEDIDO(COD_PEDIDO);

ALTER TABLE TAB_PEDIDO_ITEM
ADD FOREIGN KEY (COD_PRODUTO)
REFERENCES TAB_PRODUTO(COD_PRODUTO);


create generator gen_pedido_item_id;

CREATE TRIGGER TR_PEDIDO_ITEM FOR TAB_PEDIDO_ITEM
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    new.COD_ITEM =gen_id(gen_pedido_item_id, 1);
END













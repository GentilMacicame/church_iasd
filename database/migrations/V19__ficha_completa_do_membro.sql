-- =====================================================================
-- V19 · Ficha completa do membro (F-SEC-01) e baptismo ligado à igreja e ao pastor (F-SEC-03)
--
--   membro    dados pessoais (naturalidade, nacionalidade, identificação, profissão, escolaridade),
--             filiação (nome do pai e da mãe) e morada detalhada (província, cidade/distrito, bairro,
--             quarteirão, n.º da casa). O campo morada continua: ponto de referência / outras indicações.
--   baptismo  igreja onde foi baptizado e pastor oficiante, ligados ao sistema quando existem
--             (os campos de texto local e oficiante continuam para igrejas e pastores de fora).
--
-- Todos opcionais: os registos existentes não mudam. Os contactos (telefone, e-mail, WhatsApp) estão na
-- tabela secretaria.contacto (um membro pode ter vários). As permissões não mudam: quem lê ou altera o
-- membro (RLS por igreja) lê ou altera estes campos; a vista vw_membro_basico continua sem eles.
--
-- Gerado com database/gerador (defs.py, sql/V1__base.sql).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TYPE nucleo.tipo_identificacao_t    AS ENUM ('BI', 'PASSAPORTE', 'DIRE', 'CEDULA', 'CARTA_CONDUCAO', 'OUTRO');
CREATE TYPE nucleo.escolaridade_t          AS ENUM ('NENHUMA', 'PRIMARIO', 'SECUNDARIO', 'TECNICO_PROFISSIONAL', 'SUPERIOR');

-- ---------------------------------------------------------------- membro
ALTER TABLE secretaria.membro
    ADD COLUMN mem_naturalidade VARCHAR(150),
    ADD COLUMN mem_nacionalidade VARCHAR(60),
    ADD COLUMN mem_tipo_identificacao tipo_identificacao_t,
    ADD COLUMN mem_numero_identificacao VARCHAR(30),
    ADD COLUMN mem_profissao VARCHAR(100),
    ADD COLUMN mem_escolaridade escolaridade_t,
    ADD COLUMN mem_nome_pai VARCHAR(150),
    ADD COLUMN mem_nome_mae VARCHAR(150),
    ADD COLUMN mem_provincia VARCHAR(60),
    ADD COLUMN mem_cidade_distrito VARCHAR(100),
    ADD COLUMN mem_bairro VARCHAR(100),
    ADD COLUMN mem_quarteirao VARCHAR(20),
    ADD COLUMN mem_numero_casa VARCHAR(20);
COMMENT ON COLUMN secretaria.membro.mem_naturalidade IS 'Onde nasceu (cidade/distrito, país)';
COMMENT ON COLUMN secretaria.membro.mem_numero_identificacao IS 'Número do BI, passaporte, DIRE ou cédula';
COMMENT ON COLUMN secretaria.membro.mem_cidade_distrito IS 'Cidade ou distrito';
COMMENT ON COLUMN secretaria.membro.mem_numero_casa IS 'Número da casa ou do talhão';

-- ---------------------------------------------------------------- baptismo
ALTER TABLE secretaria.baptismo
    ADD COLUMN bap_local_igr_id INT,
    ADD COLUMN bap_oficiante_usu_id INT,
    ADD CONSTRAINT fk_bap_local_igr_id FOREIGN KEY (bap_local_igr_id) REFERENCES organizacao.igreja(igr_id),
    ADD CONSTRAINT fk_bap_oficiante_usu_id FOREIGN KEY (bap_oficiante_usu_id) REFERENCES nucleo.usuario(usu_id);
COMMENT ON COLUMN secretaria.baptismo.bap_local_igr_id IS 'Igreja onde foi baptizado, se estiver no sistema (senão: local)';
COMMENT ON COLUMN secretaria.baptismo.bap_oficiante_usu_id IS 'Pastor que baptizou, se tiver conta no sistema (senão: oficiante)';
CREATE INDEX idx_bap_local_igr_id ON secretaria.baptismo (bap_local_igr_id);
CREATE INDEX idx_bap_oficiante_usu_id ON secretaria.baptismo (bap_oficiante_usu_id);

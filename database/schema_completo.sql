-- =====================================================================
-- Sistema de Gestão da Igreja Adventista · esquema completo (script único)
-- GERADO por scripts/gerar-schema-completo.sh a partir de database/migrations
-- (V1__base.sql … V56__despesas_pelo_conselho_e_fundo_de_maneio.sql). NÃO EDITAR À MÃO.
-- PostgreSQL 16+, como administrador; depois: scripts/criar-papel-api.sh
-- =====================================================================

-- >>>>> V1__base.sql
-- =====================================================================
-- V1 · Módulos (schemas), tipos e funções genéricas
--
-- Módulos
--   nucleo           acesso, utilizadores, auditoria, funções comuns
--   organizacao      Associação/Missão, distritos, igrejas e grupos, departamentos, cargos
--   secretaria       membros, reuniões e votos, livro de membros, transferências, disciplina, eleições
--   actividades      actividades, material, escalas
--   escola_sabatina  trimestres, classes, relatórios, chamada, pontuação
--   tesouraria       contas, fundos, movimentos, despesas, recibos, remessas, orçamento, saldos
--   pagamentos       M-Pesa e bancos
--   comunicacao      fila de SMS, WhatsApp e e-mail
--
-- Convenções
--   * Colunas com o prefixo de 3 letras da tabela (membro -> mem_). PK: <pfx>_id.
--   * FK: <pfx>_<papel>_<pfx_destino>_id (ex.: ect_professor_mem_id).
--   * Todas as tabelas: <pfx>_estado, _criado_em, _criado_por, _modificado_em,
--     _modificado_por, _end_date. Nada se apaga.
--   * A API identifica o utilizador em cada transacção SQL:
--       SELECT set_config('app.usuario_id', '<usu_id>', true);
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS nucleo;
CREATE SCHEMA IF NOT EXISTS organizacao;
CREATE SCHEMA IF NOT EXISTS secretaria;
CREATE SCHEMA IF NOT EXISTS actividades;
CREATE SCHEMA IF NOT EXISTS escola_sabatina;
CREATE SCHEMA IF NOT EXISTS tesouraria;
CREATE SCHEMA IF NOT EXISTS pagamentos;
CREATE SCHEMA IF NOT EXISTS comunicacao;

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- tipos (no núcleo)
CREATE TYPE nucleo.estado_registo_t        AS ENUM ('ACTIVO', 'INACTIVO');
CREATE TYPE nucleo.sexo_t                  AS ENUM ('M', 'F');
CREATE TYPE nucleo.estado_civil_t          AS ENUM ('SOLTEIRO', 'CASADO', 'DIVORCIADO', 'VIUVO', 'UNIAO_FACTO');
CREATE TYPE nucleo.estado_validacao_t      AS ENUM ('PENDENTE', 'APROVADO', 'REJEITADO');
CREATE TYPE nucleo.tipo_entidade_t         AS ENUM ('CONFERENCIA_GERAL', 'DIVISAO', 'UNIAO', 'ASSOCIACAO', 'MISSAO', 'CAMPO');
CREATE TYPE nucleo.tipo_igreja_t           AS ENUM ('IGREJA_ORGANIZADA', 'GRUPO_ORGANIZADO', 'GRUPO', 'FILIAL');
CREATE TYPE nucleo.estado_membro_t         AS ENUM ('INTERESSADO', 'ACTIVO', 'TRANSFERIDO', 'FALECIDO', 'REMOVIDO', 'DESAPARECIDO');
CREATE TYPE nucleo.tipo_movimento_t        AS ENUM ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA',
                                                    'TRANSFERENCIA_SAIDA', 'FALECIMENTO', 'REMOCAO_DISCIPLINA',
                                                    'REMOCAO_PEDIDO', 'DESAPARECIDO');
CREATE TYPE nucleo.tipo_reuniao_t          AS ENUM ('JUNTA_DIRECTIVA', 'REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA',
                                                    'COMISSAO_NOMEACOES', 'CONSELHO_ES');
CREATE TYPE nucleo.estado_reuniao_t        AS ENUM ('CONVOCADA', 'REALIZADA', 'ACTA_APROVADA', 'CANCELADA');
CREATE TYPE nucleo.tipo_voto_t             AS ENUM ('ADMISSAO', 'TRANSFERENCIA', 'REMOCAO', 'DISCIPLINA', 'ELEICAO',
                                                    'FINANCEIRO', 'OUTRO');
CREATE TYPE nucleo.resultado_voto_t        AS ENUM ('APROVADO', 'REJEITADO', 'ADIADO');
CREATE TYPE nucleo.tipo_contacto_t         AS ENUM ('TELEFONE', 'EMAIL', 'WHATSAPP', 'OUTRO');
CREATE TYPE nucleo.tipo_consentimento_t    AS ENUM ('DADOS_PESSOAIS', 'FOTOGRAFIAS', 'CONTACTO_SMS', 'CONTACTO_WHATSAPP', 'CONTACTO_EMAIL');
CREATE TYPE nucleo.estado_transferencia_t  AS ENUM ('PEDIDA', 'CARTA_EMITIDA', 'CONCLUIDA', 'RECUSADA', 'EXPIRADA');
CREATE TYPE nucleo.estado_actividade_t     AS ENUM ('PLANEADA', 'EM_CURSO', 'CONCLUIDA', 'CANCELADA');
CREATE TYPE nucleo.funcao_escala_t         AS ENUM ('PREGADOR', 'ANCIAO_DO_DIA', 'DIACONO', 'DIACONISA', 'RECEPCAO', 'MUSICA',
                                                    'SONOPLASTIA', 'PROFESSOR_ES', 'DIRECTOR_ES', 'LIMPEZA', 'OUTRA');
CREATE TYPE nucleo.estado_escala_t         AS ENUM ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA', 'CUMPRIDA', 'FALTOU');
CREATE TYPE nucleo.es_divisao_t            AS ENUM ('ROL_DO_BERCO', 'JARDIM_DE_INFANCIA', 'PRIMARIOS', 'JUVENIS',
                                                    'ADOLESCENTES', 'JOVENS', 'ADULTOS');
CREATE TYPE nucleo.estado_relatorio_t      AS ENUM ('ABERTO', 'FECHADO');
CREATE TYPE nucleo.tipo_conta_t            AS ENUM ('MPESA', 'EMOLA', 'BANCO', 'CAIXA');
CREATE TYPE nucleo.tipo_transacao_t        AS ENUM ('ENTRADA', 'SAIDA', 'TRANSFERENCIA');
CREATE TYPE nucleo.metodo_pagamento_t      AS ENUM ('MPESA', 'EMOLA', 'BANCO', 'NUMERARIO');
CREATE TYPE nucleo.estado_transacao_t      AS ENUM ('PENDENTE', 'CONFIRMADA', 'FALHADA', 'ANULADA');
CREATE TYPE nucleo.tipo_fundo_t            AS ENUM ('DIZIMO', 'OFERTA_MISSIONARIA', 'ES_MISSOES', 'ES_13_SABADO', 'ES_DESPESAS',
                                                    'OFERTA_COMBINADA', 'OFERTA_ESPECIAL', 'ORCAMENTO_LOCAL', 'PROJECTO');
CREATE TYPE nucleo.tipo_categoria_t        AS ENUM ('RECEITA', 'DESPESA');
CREATE TYPE nucleo.estado_despesa_t        AS ENUM ('SUBMETIDA', 'APROVADA', 'REJEITADA', 'PAGA', 'CANCELADA');
CREATE TYPE nucleo.estado_contagem_t       AS ENUM ('ABERTA', 'CONFERIDA', 'DEPOSITADA');
CREATE TYPE nucleo.estado_remessa_t        AS ENUM ('PREPARADA', 'ENVIADA', 'CONFIRMADA');
CREATE TYPE nucleo.estado_orcamento_t      AS ENUM ('RASCUNHO', 'APROVADO', 'ENCERRADO');
CREATE TYPE nucleo.tipo_documento_t        AS ENUM ('FACTURA', 'RECIBO', 'COMPROVATIVO', 'EXTRACTO', 'OUTRO');
CREATE TYPE nucleo.canal_notificacao_t     AS ENUM ('SMS', 'WHATSAPP', 'EMAIL');
CREATE TYPE nucleo.estado_notificacao_t    AS ENUM ('PENDENTE', 'ENVIADA', 'FALHADA', 'CANCELADA');

-- ---------------------------------------------------------------- funções comuns
CREATE FUNCTION nucleo.fn_usuario_sessao() RETURNS INT AS $$
    SELECT NULLIF(current_setting('app.usuario_id', true), '')::INT;
$$ LANGUAGE sql STABLE PARALLEL SAFE;

-- Preenche criado_em/por e modificado_em/por; protege a criação e registos terminados.
-- Argumentos: prefixo, nome da tabela para as permissões ('' = tabela do sistema), coluna de igreja ('' se não tiver).
CREATE FUNCTION nucleo.fn_campos_padrao() RETURNS trigger AS $$
DECLARE
    p     TEXT  := TG_ARGV[0];
    v_usr INT   := nucleo.fn_usuario_sessao();
    o     JSONB;
    n     JSONB := to_jsonb(NEW);
    j     JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        j := jsonb_build_object(p || '_criado_em', now(), p || '_modificado_em', now());
        IF v_usr IS NOT NULL THEN
            j := j || jsonb_build_object(p || '_criado_por', v_usr, p || '_modificado_por', v_usr);
        ELSE
            j := j || jsonb_build_object(p || '_modificado_por', n -> (p || '_criado_por'));
        END IF;
        IF n ->> (p || '_end_date') IS NOT NULL THEN
            RAISE EXCEPTION 'Não se cria um registo já terminado em %', TG_TABLE_NAME;
        END IF;
    ELSE
        o := to_jsonb(OLD);
        IF o ->> (p || '_end_date') IS NOT NULL AND n ->> (p || '_end_date') IS NOT NULL THEN
            RAISE EXCEPTION 'O registo % de % está terminado (end_date) e não pode ser alterado; para o reactivar limpe %_end_date',
                o ->> (p || '_id'), TG_TABLE_NAME, p;
        END IF;
        -- terminar (preencher end_date) ou reactivar exige a permissão "terminar" da tabela
        IF TG_ARGV[1] <> '' AND (o ->> (p || '_end_date')) IS DISTINCT FROM (n ->> (p || '_end_date')) THEN
            PERFORM nucleo.fn_exigir(TG_ARGV[1] || '.terminar',
                    CASE WHEN TG_ARGV[2] <> '' THEN (n ->> TG_ARGV[2])::INT END);
        END IF;
        j := jsonb_build_object(p || '_criado_em',  o -> (p || '_criado_em'),
                                p || '_criado_por', o -> (p || '_criado_por'),
                                p || '_modificado_em', now());
        IF v_usr IS NOT NULL THEN
            j := j || jsonb_build_object(p || '_modificado_por', v_usr);
        END IF;
    END IF;
    NEW := jsonb_populate_record(NEW, j);
    RETURN NEW;
END $$ LANGUAGE plpgsql;

-- Nada se apaga
CREATE FUNCTION nucleo.fn_proibir_delete() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Não se apagam registos de %.%: preencha %_end_date para terminar o registo',
        TG_TABLE_SCHEMA, TG_TABLE_NAME, COALESCE(TG_ARGV[0], '<prefixo>');
END $$ LANGUAGE plpgsql;

-- Auditoria das alterações: guarda só os campos que mudaram (antes e depois)
CREATE FUNCTION nucleo.fn_log_auditoria() RETURNS trigger AS $$
DECLARE
    p      TEXT  := TG_ARGV[0];
    n      JSONB := to_jsonb(NEW);
    o      JSONB;
    antes  JSONB := NULL;
    depois JSONB := n;
    accao  TEXT  := TG_OP;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        o := to_jsonb(OLD);
        SELECT jsonb_object_agg(k, o -> k), jsonb_object_agg(k, n -> k)
          INTO antes, depois
          FROM jsonb_object_keys(n) k
         WHERE (o -> k) IS DISTINCT FROM (n -> k)
           AND k NOT IN (p || '_modificado_em', p || '_modificado_por');
        IF depois IS NULL THEN
            RETURN NULL;                              -- nada mudou de facto
        END IF;
        IF o ->> (p || '_end_date') IS NULL AND n ->> (p || '_end_date') IS NOT NULL THEN
            accao := 'TERMINO';
        END IF;
    END IF;
    INSERT INTO nucleo.log_auditoria (lau_usu_id, lau_tabela, lau_registo_id, lau_accao, lau_dados_antes, lau_dados_depois)
    VALUES (nucleo.fn_usuario_sessao(), TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            (n ->> (p || '_id'))::BIGINT, accao, antes, depois);
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION nucleo.fn_log_imutavel() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'O log de auditoria não pode ser alterado';
END $$ LANGUAGE plpgsql;

-- Partições mensais do log de auditoria: cria as que faltam até N meses à frente.
-- Chamar uma vez por mês (tarefa agendada da API ou pg_cron).
CREATE FUNCTION nucleo.fn_criar_particoes_log(p_meses_a_frente INT DEFAULT 3) RETURNS INT AS $$
DECLARE
    m   DATE := date_trunc('month', now() - INTERVAL '1 month')::date;
    fim DATE := date_trunc('month', now() + make_interval(months => p_meses_a_frente))::date;
    nome TEXT;
    n   INT := 0;
BEGIN
    WHILE m <= fim LOOP
        nome := 'log_auditoria_' || to_char(m, 'YYYY_MM');
        IF to_regclass('nucleo.' || nome) IS NULL THEN
            EXECUTE format('CREATE TABLE nucleo.%I PARTITION OF nucleo.log_auditoria FOR VALUES FROM (%L) TO (%L)',
                           nome, m, (m + INTERVAL '1 month')::date);
            n := n + 1;
        END IF;
        m := (m + INTERVAL '1 month')::date;
    END LOOP;
    RETURN n;
END $$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------- permissões
-- Tudo é calculado a partir do utilizador da sessão (app.usuario_id).
-- Fontes de permissão:
--   1. usuario_igreja   perfil numa igreja
--   2. usuario_entidade perfil numa Associação/Missão (vale para as igrejas dela e das entidades abaixo)
--   3. pastor distrital perfil PASTOR em todas as igrejas do seu distrito
--   4. super_admin      tudo

CREATE FUNCTION nucleo.fn_e_super_admin() RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM nucleo.usuario WHERE usu_id = nucleo.fn_usuario_sessao()
                   AND usu_super_admin AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL);
END $$;

CREATE FUNCTION nucleo.fn_membro_sessao() RETURNS INT
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN (SELECT usu_mem_id FROM nucleo.usuario WHERE usu_id = nucleo.fn_usuario_sessao()
            AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL);
END $$;

CREATE FUNCTION nucleo.fn_familia_sessao() RETURNS INT
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN (SELECT m.mem_fam_id FROM secretaria.membro m WHERE m.mem_id = nucleo.fn_membro_sessao());
END $$;

-- Igrejas onde o utilizador da sessão tem uma permissão.
-- Nas políticas é chamada como (SELECT ...): calcula-se uma vez por consulta, não por linha.
CREATE FUNCTION nucleo.fn_igrejas_com_permissao(p_codigo TEXT) RETURNS INT[]
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN RETURN ARRAY[]::INT[]; END IF;
    IF nucleo.fn_e_super_admin() THEN
        RETURN ARRAY(SELECT igr_id FROM organizacao.igreja WHERE igr_end_date IS NULL);
    END IF;
    RETURN ARRAY(
        WITH perm AS (
            SELECT pp.ppe_per_id AS per_id
            FROM nucleo.permissao pm
            JOIN nucleo.perfil_permissao pp ON pp.ppe_prm_id = pm.prm_id AND pp.ppe_end_date IS NULL
            WHERE pm.prm_codigo = p_codigo AND pm.prm_end_date IS NULL
        )
        SELECT u.uig_igr_id
          FROM nucleo.usuario_igreja u JOIN perm ON perm.per_id = u.uig_per_id
         WHERE u.uig_usu_id = v_usr AND u.uig_estado = 'ACTIVO' AND u.uig_end_date IS NULL
        UNION
        SELECT i.igr_id
          FROM organizacao.distrito d
          JOIN organizacao.igreja i ON i.igr_dst_id = d.dst_id AND i.igr_end_date IS NULL
         WHERE d.dst_pastor_usu_id = v_usr AND d.dst_end_date IS NULL
           AND EXISTS (SELECT 1 FROM nucleo.perfil pf JOIN perm ON perm.per_id = pf.per_id WHERE pf.per_nome = 'PASTOR')
        UNION
        SELECT i.igr_id
          FROM nucleo.fn_entidades_com_permissao(p_codigo) e
          JOIN organizacao.igreja i ON i.igr_ent_id = e AND i.igr_end_date IS NULL);
END $$;

-- Entidades (e todas as que estão abaixo) onde o utilizador tem a permissão por usuario_entidade
CREATE FUNCTION nucleo.fn_entidades_com_permissao(p_codigo TEXT) RETURNS SETOF INT
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE base AS (
        SELECT ue.uen_ent_id AS ent_id
        FROM nucleo.usuario_entidade ue
        JOIN nucleo.perfil_permissao pp ON pp.ppe_per_id = ue.uen_per_id AND pp.ppe_end_date IS NULL
        JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id AND pm.prm_codigo = p_codigo AND pm.prm_end_date IS NULL
        WHERE ue.uen_usu_id = nucleo.fn_usuario_sessao() AND ue.uen_estado = 'ACTIVO' AND ue.uen_end_date IS NULL
    ), arvore AS (
        SELECT b.ent_id FROM base b
        UNION
        SELECT e.ent_id FROM organizacao.entidade e JOIN arvore a ON e.ent_pai_ent_id = a.ent_id
        WHERE e.ent_end_date IS NULL
    )
    SELECT a.ent_id FROM arvore a;
END $$;

-- Permissão sem igreja concreta (tabelas comuns): basta tê-la em algum sítio
CREATE FUNCTION nucleo.fn_tem_permissao_global(p_codigo TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN nucleo.fn_e_super_admin()
        OR cardinality(nucleo.fn_igrejas_com_permissao(p_codigo)) > 0
        OR EXISTS (SELECT 1 FROM nucleo.fn_entidades_com_permissao(p_codigo));
END $$;

CREATE FUNCTION nucleo.fn_tem_permissao(p_codigo TEXT, p_igr INT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    IF p_igr IS NULL THEN RETURN nucleo.fn_tem_permissao_global(p_codigo); END IF;
    RETURN nucleo.fn_e_super_admin() OR p_igr = ANY (nucleo.fn_igrejas_com_permissao(p_codigo));
END $$;

-- Interrompe a operação se o utilizador não tiver a permissão.
-- Sem utilizador na sessão só passa quem administra a base de dados (instalação, manutenção).
CREATE FUNCTION nucleo.fn_exigir(p_codigo TEXT, p_igr INT DEFAULT NULL) RETURNS VOID
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE v_desc TEXT;
BEGIN
    IF nucleo.fn_usuario_sessao() IS NULL THEN
        IF (SELECT rolsuper FROM pg_roles WHERE rolname = session_user) THEN RETURN; END IF;
        RAISE EXCEPTION 'Sem utilizador identificado na sessão (app.usuario_id)';
    END IF;
    IF NOT nucleo.fn_tem_permissao(p_codigo, p_igr) THEN
        SELECT prm_descricao INTO v_desc FROM nucleo.permissao WHERE prm_codigo = p_codigo;
        RAISE EXCEPTION 'Sem permissão: % (%)%', COALESCE(v_desc, p_codigo), p_codigo,
            CASE WHEN p_igr IS NOT NULL THEN ' na igreja ' || p_igr ELSE '' END
            USING ERRCODE = 'insufficient_privilege';
    END IF;
END $$;

-- >>>>> V2__nucleo.sql
-- =====================================================================
-- V2 · Módulo nucleo: Núcleo: acesso e auditoria
-- Utilizadores, perfis, permissões e o histórico de todas as alterações.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Perfis de acesso (Admin, Secretário, Tesoureiro, ...)
CREATE TABLE nucleo.perfil (
    per_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    per_nome VARCHAR(50) NOT NULL,
    per_descricao VARCHAR(255),
    per_ambito VARCHAR(10) NOT NULL DEFAULT 'IGREJA',
    per_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    per_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    per_criado_por INT,
    per_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    per_modificado_por INT,
    per_end_date TIMESTAMPTZ,
    CONSTRAINT chk_per_ambito CHECK (per_ambito IN ('IGREJA', 'ENTIDADE')),
    CONSTRAINT chk_per_end_date CHECK (per_end_date IS NULL OR per_end_date >= per_criado_em)
);
COMMENT ON TABLE nucleo.perfil IS 'Perfis de acesso (Admin, Secretário, Tesoureiro, ...)';
COMMENT ON COLUMN nucleo.perfil.per_ambito IS 'IGREJA ou ENTIDADE (Associação/Missão)';
CREATE UNIQUE INDEX uq_per_nome ON nucleo.perfil (per_nome) WHERE per_end_date IS NULL;

-- Permissões elementares (ex.: transacao.aprovar)
CREATE TABLE nucleo.permissao (
    prm_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    prm_codigo VARCHAR(80) NOT NULL,
    prm_descricao VARCHAR(255),
    prm_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    prm_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    prm_criado_por INT,
    prm_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    prm_modificado_por INT,
    prm_end_date TIMESTAMPTZ,
    CONSTRAINT chk_prm_end_date CHECK (prm_end_date IS NULL OR prm_end_date >= prm_criado_em)
);
COMMENT ON TABLE nucleo.permissao IS 'Permissões elementares (ex.: transacao.aprovar)';
CREATE UNIQUE INDEX uq_prm_codigo ON nucleo.permissao (prm_codigo) WHERE prm_end_date IS NULL;

-- Que permissões cada perfil tem
CREATE TABLE nucleo.perfil_permissao (
    ppe_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ppe_per_id INT NOT NULL,
    ppe_prm_id INT NOT NULL,
    ppe_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ppe_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppe_criado_por INT,
    ppe_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppe_modificado_por INT,
    ppe_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ppe_per_id FOREIGN KEY (ppe_per_id) REFERENCES nucleo.perfil(per_id),
    CONSTRAINT fk_ppe_prm_id FOREIGN KEY (ppe_prm_id) REFERENCES nucleo.permissao(prm_id),
    CONSTRAINT chk_ppe_end_date CHECK (ppe_end_date IS NULL OR ppe_end_date >= ppe_criado_em)
);
COMMENT ON TABLE nucleo.perfil_permissao IS 'Que permissões cada perfil tem';
CREATE UNIQUE INDEX uq_ppe_per_id_prm_id ON nucleo.perfil_permissao (ppe_per_id, ppe_prm_id) WHERE ppe_end_date IS NULL;
CREATE INDEX idx_ppe_prm_id ON nucleo.perfil_permissao (ppe_prm_id);

-- Contas de acesso ao sistema
CREATE TABLE nucleo.usuario (
    usu_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    usu_mem_id INT,
    usu_nome VARCHAR(150),
    usu_email VARCHAR(150),
    usu_telefone VARCHAR(20),
    usu_senha_hash VARCHAR(255) NOT NULL,
    usu_super_admin BOOLEAN NOT NULL DEFAULT FALSE,
    usu_ultimo_login TIMESTAMPTZ,
    usu_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    usu_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    usu_criado_por INT,
    usu_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    usu_modificado_por INT,
    usu_end_date TIMESTAMPTZ,
    CONSTRAINT chk_usu_contacto CHECK (usu_email IS NOT NULL OR usu_telefone IS NOT NULL),
    CONSTRAINT chk_usu_end_date CHECK (usu_end_date IS NULL OR usu_end_date >= usu_criado_em)
);
COMMENT ON TABLE nucleo.usuario IS 'Contas de acesso ao sistema';
COMMENT ON COLUMN nucleo.usuario.usu_senha_hash IS 'bcrypt/argon2, nunca texto';
COMMENT ON COLUMN nucleo.usuario.usu_super_admin IS 'Vê todas as igrejas';
CREATE UNIQUE INDEX uq_usu_mem_id ON nucleo.usuario (usu_mem_id) WHERE usu_end_date IS NULL;
CREATE UNIQUE INDEX uq_usu_email ON nucleo.usuario (usu_email) WHERE usu_end_date IS NULL;
CREATE UNIQUE INDEX uq_usu_telefone ON nucleo.usuario (usu_telefone) WHERE usu_end_date IS NULL;

-- Perfil de cada utilizador em cada igreja (base da segurança por igreja)
CREATE TABLE nucleo.usuario_igreja (
    uig_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    uig_usu_id INT NOT NULL,
    uig_igr_id INT NOT NULL,
    uig_per_id INT NOT NULL,
    uig_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    uig_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    uig_criado_por INT,
    uig_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    uig_modificado_por INT,
    uig_end_date TIMESTAMPTZ,
    CONSTRAINT fk_uig_usu_id FOREIGN KEY (uig_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT fk_uig_per_id FOREIGN KEY (uig_per_id) REFERENCES nucleo.perfil(per_id),
    CONSTRAINT chk_uig_end_date CHECK (uig_end_date IS NULL OR uig_end_date >= uig_criado_em)
);
COMMENT ON TABLE nucleo.usuario_igreja IS 'Perfil de cada utilizador em cada igreja (base da segurança por igreja)';
CREATE UNIQUE INDEX uq_uig_usu_id_igr_id_per_id ON nucleo.usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) WHERE uig_end_date IS NULL;
CREATE INDEX idx_uig_igr_id ON nucleo.usuario_igreja (uig_igr_id);
CREATE INDEX idx_uig_per_id ON nucleo.usuario_igreja (uig_per_id);
CREATE INDEX idx_uig_sessao ON nucleo.usuario_igreja (uig_usu_id) INCLUDE (uig_igr_id) WHERE uig_end_date IS NULL;

-- Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)
CREATE TABLE nucleo.usuario_entidade (
    uen_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    uen_usu_id INT NOT NULL,
    uen_ent_id INT NOT NULL,
    uen_per_id INT NOT NULL,
    uen_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    uen_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    uen_criado_por INT,
    uen_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    uen_modificado_por INT,
    uen_end_date TIMESTAMPTZ,
    CONSTRAINT fk_uen_usu_id FOREIGN KEY (uen_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT fk_uen_per_id FOREIGN KEY (uen_per_id) REFERENCES nucleo.perfil(per_id),
    CONSTRAINT chk_uen_end_date CHECK (uen_end_date IS NULL OR uen_end_date >= uen_criado_em)
);
COMMENT ON TABLE nucleo.usuario_entidade IS 'Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)';
CREATE UNIQUE INDEX uq_uen_usu_id_ent_id_per_id ON nucleo.usuario_entidade (uen_usu_id, uen_ent_id, uen_per_id) WHERE uen_end_date IS NULL;
CREATE INDEX idx_uen_ent_id ON nucleo.usuario_entidade (uen_ent_id);
CREATE INDEX idx_uen_per_id ON nucleo.usuario_entidade (uen_per_id);

-- Histórico de alterações (só os campos que mudaram); particionado por mês
CREATE TABLE nucleo.log_auditoria (
    lau_id BIGSERIAL,
    lau_usu_id INT,
    lau_tabela VARCHAR(80) NOT NULL,
    lau_registo_id BIGINT NOT NULL,
    lau_accao VARCHAR(10) NOT NULL,
    lau_dados_antes JSONB,
    lau_dados_depois JSONB,
    lau_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    lau_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    lau_criado_por INT,
    lau_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    lau_modificado_por INT,
    lau_end_date TIMESTAMPTZ,
    PRIMARY KEY (lau_id, lau_criado_em),
    CONSTRAINT fk_lau_usu_id FOREIGN KEY (lau_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_lau_accao CHECK (lau_accao IN ('INSERT', 'UPDATE', 'TERMINO')),
    CONSTRAINT chk_lau_end_date CHECK (lau_end_date IS NULL OR lau_end_date >= lau_criado_em)
) PARTITION BY RANGE (lau_criado_em);
COMMENT ON TABLE nucleo.log_auditoria IS 'Histórico de alterações (só os campos que mudaram); particionado por mês';
CREATE INDEX idx_lau_usu_id ON nucleo.log_auditoria (lau_usu_id);
CREATE INDEX idx_lau_registo ON nucleo.log_auditoria (lau_tabela, lau_registo_id);
CREATE INDEX idx_lau_data ON nucleo.log_auditoria USING BRIN (lau_criado_em);
CREATE TABLE nucleo.log_auditoria_default PARTITION OF nucleo.log_auditoria DEFAULT;
SELECT nucleo.fn_criar_particoes_log(12);

-- Regras de acesso ---------------------------------------------------------

-- Utilizadores: ninguém se torna super_admin sozinho; só se gere quem está em igrejas que se administram
CREATE FUNCTION nucleo.fn_usu_proteger() RETURNS trigger AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');      -- só passa na instalação/manutenção
        RETURN NEW;
    END IF;
    IF NEW.usu_super_admin AND (TG_OP = 'INSERT' OR NOT OLD.usu_super_admin) AND NOT nucleo.fn_e_super_admin() THEN
        RAISE EXCEPTION 'Só um super-administrador pode criar outro';
    END IF;
    IF TG_OP = 'INSERT' THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');
        RETURN NEW;
    END IF;
    IF OLD.usu_id = v_usr THEN
        -- a própria pessoa muda nome, contactos e senha, mas não o estado nem a ligação ao membro
        IF (NEW.usu_estado, NEW.usu_mem_id, NEW.usu_super_admin) IS DISTINCT FROM (OLD.usu_estado, OLD.usu_mem_id, OLD.usu_super_admin)
           AND NOT nucleo.fn_e_super_admin() THEN
            RAISE EXCEPTION 'Não pode alterar o seu próprio estado, membro ou nível de acesso';
        END IF;
        RETURN NEW;
    END IF;
    PERFORM nucleo.fn_exigir('nucleo.usuario.alterar');
    IF NOT nucleo.fn_e_super_admin() THEN
        IF OLD.usu_super_admin THEN
            RAISE EXCEPTION 'Só um super-administrador altera outro super-administrador';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_igreja u
                   WHERE u.uig_usu_id = OLD.usu_id AND u.uig_end_date IS NULL
                     AND NOT nucleo.fn_tem_permissao('nucleo.usuario.alterar', u.uig_igr_id)) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis em igrejas que não administra';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_entidade e
                   WHERE e.uen_usu_id = OLD.usu_id AND e.uen_end_date IS NULL
                     AND e.uen_ent_id NOT IN (SELECT nucleo.fn_entidades_com_permissao('nucleo.usuario.alterar'))) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis numa Associação/Missão que não administra';
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usu_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_usu_proteger();

-- Atribuir perfis numa igreja: não a si próprio e só perfis cujas permissões já tem nessa igreja
CREATE FUNCTION nucleo.fn_uig_proteger() RETURNS trigger AS $$
DECLARE v_falta TEXT;
BEGIN
    IF (SELECT per_ambito FROM nucleo.perfil WHERE per_id = NEW.uig_per_id) <> 'IGREJA' THEN
        RAISE EXCEPTION 'Este perfil é de Associação/Missão: atribua-o em nucleo.usuario_entidade';
    END IF;
    IF nucleo.fn_usuario_sessao() IS NULL OR nucleo.fn_e_super_admin() THEN RETURN NEW; END IF;
    IF NEW.uig_usu_id = nucleo.fn_usuario_sessao() THEN
        RAISE EXCEPTION 'Ninguém altera os seus próprios perfis';
    END IF;
    SELECT string_agg(pm.prm_codigo, ', ') INTO v_falta
    FROM nucleo.perfil_permissao pp JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id
    WHERE pp.ppe_per_id = NEW.uig_per_id AND pp.ppe_end_date IS NULL
      AND NOT nucleo.fn_tem_permissao(pm.prm_codigo, NEW.uig_igr_id);
    IF v_falta IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode dar um perfil com permissões que não tem nesta igreja: %', left(v_falta, 300)
            USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_uig_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario_igreja
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_uig_proteger();

CREATE FUNCTION nucleo.fn_uen_proteger() RETURNS trigger AS $$
DECLARE v_falta TEXT;
BEGIN
    IF (SELECT per_ambito FROM nucleo.perfil WHERE per_id = NEW.uen_per_id) <> 'ENTIDADE' THEN
        RAISE EXCEPTION 'Este perfil é de igreja: atribua-o em nucleo.usuario_igreja';
    END IF;
    IF nucleo.fn_usuario_sessao() IS NULL OR nucleo.fn_e_super_admin() THEN RETURN NEW; END IF;
    IF NEW.uen_usu_id = nucleo.fn_usuario_sessao() THEN
        RAISE EXCEPTION 'Ninguém altera os seus próprios perfis';
    END IF;
    SELECT string_agg(pm.prm_codigo, ', ') INTO v_falta
    FROM nucleo.perfil_permissao pp JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id
    WHERE pp.ppe_per_id = NEW.uen_per_id AND pp.ppe_end_date IS NULL
      AND NEW.uen_ent_id NOT IN (SELECT nucleo.fn_entidades_com_permissao(pm.prm_codigo));
    IF v_falta IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode dar um perfil com permissões que não tem nesta Associação/Missão: %', left(v_falta, 300)
            USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_uen_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario_entidade
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_uen_proteger();

-- Login: a API obtém o hash da senha por esta função (a coluna da senha não é legível directamente)
CREATE FUNCTION nucleo.fn_credenciais(p_login TEXT)
RETURNS TABLE (usu_id INT, senha_hash VARCHAR, estado nucleo.estado_registo_t)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT u.usu_id, u.usu_senha_hash, u.usu_estado
    FROM nucleo.usuario u
    WHERE (u.usu_email = p_login OR u.usu_telefone = p_login) AND u.usu_end_date IS NULL;
$$;

-- O que o utilizador da sessão pode fazer (para a API mostrar ou esconder menus e botões)
CREATE FUNCTION nucleo.fn_minhas_permissoes()
RETURNS TABLE (codigo VARCHAR, igr_id INT)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT pm.prm_codigo, i
    FROM nucleo.permissao pm, unnest(nucleo.fn_igrejas_com_permissao(pm.prm_codigo)) i
    WHERE pm.prm_end_date IS NULL;
$$;


-- >>>>> V3__organizacao.sql
-- =====================================================================
-- V3 · Módulo organizacao: Organização
-- Estrutura da denominação (Associação/Missão, distritos, igrejas e grupos), departamentos e cargos.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão
CREATE TABLE organizacao.entidade (
    ent_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ent_pai_ent_id INT,
    ent_tipo tipo_entidade_t NOT NULL,
    ent_nome VARCHAR(150) NOT NULL,
    ent_sigla VARCHAR(20),
    ent_data_criacao DATE,
    ent_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ent_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ent_criado_por INT,
    ent_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ent_modificado_por INT,
    ent_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ent_pai_ent_id FOREIGN KEY (ent_pai_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT chk_ent_end_date CHECK (ent_end_date IS NULL OR ent_end_date >= ent_criado_em)
);
COMMENT ON TABLE organizacao.entidade IS 'Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão';
CREATE INDEX idx_ent_pai_ent_id ON organizacao.entidade (ent_pai_ent_id);

-- chaves estrangeiras que esperavam por organizacao.entidade
ALTER TABLE nucleo.usuario_entidade ADD CONSTRAINT fk_uen_ent_id FOREIGN KEY (uen_ent_id) REFERENCES organizacao.entidade(ent_id);

-- Distritos pastorais de uma Associação/Missão
CREATE TABLE organizacao.distrito (
    dst_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    dst_ent_id INT NOT NULL,
    dst_nome VARCHAR(100) NOT NULL,
    dst_pastor_usu_id INT,
    dst_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    dst_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dst_criado_por INT,
    dst_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dst_modificado_por INT,
    dst_end_date TIMESTAMPTZ,
    CONSTRAINT fk_dst_ent_id FOREIGN KEY (dst_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT fk_dst_pastor_usu_id FOREIGN KEY (dst_pastor_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_dst_end_date CHECK (dst_end_date IS NULL OR dst_end_date >= dst_criado_em)
);
COMMENT ON TABLE organizacao.distrito IS 'Distritos pastorais de uma Associação/Missão';
COMMENT ON COLUMN organizacao.distrito.dst_pastor_usu_id IS 'Pastor distrital';
CREATE UNIQUE INDEX uq_dst_ent_id_nome ON organizacao.distrito (dst_ent_id, dst_nome) WHERE dst_end_date IS NULL;
CREATE INDEX idx_dst_pastor_usu_id ON organizacao.distrito (dst_pastor_usu_id);

-- Igrejas organizadas, grupos organizados e grupos/filiais
CREATE TABLE organizacao.igreja (
    igr_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    igr_ent_id INT NOT NULL,
    igr_dst_id INT,
    igr_tipo tipo_igreja_t NOT NULL DEFAULT 'IGREJA_ORGANIZADA',
    igr_mae_igr_id INT,
    igr_nome VARCHAR(150) NOT NULL,
    igr_codigo_acms VARCHAR(30),
    igr_data_organizacao DATE,
    igr_endereco VARCHAR(255),
    igr_latitude DECIMAL(9,6),
    igr_longitude DECIMAL(9,6),
    igr_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    igr_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    igr_criado_por INT,
    igr_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    igr_modificado_por INT,
    igr_end_date TIMESTAMPTZ,
    CONSTRAINT fk_igr_ent_id FOREIGN KEY (igr_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT fk_igr_dst_id FOREIGN KEY (igr_dst_id) REFERENCES organizacao.distrito(dst_id),
    CONSTRAINT fk_igr_mae_igr_id FOREIGN KEY (igr_mae_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_igr_mae CHECK (igr_tipo = 'IGREJA_ORGANIZADA' OR igr_mae_igr_id IS NOT NULL OR igr_tipo = 'GRUPO_ORGANIZADO'),
    CONSTRAINT chk_igr_end_date CHECK (igr_end_date IS NULL OR igr_end_date >= igr_criado_em)
);
COMMENT ON TABLE organizacao.igreja IS 'Igrejas organizadas, grupos organizados e grupos/filiais';
COMMENT ON COLUMN organizacao.igreja.igr_ent_id IS 'Associação/Missão a que pertence';
COMMENT ON COLUMN organizacao.igreja.igr_mae_igr_id IS 'Igreja-mãe de um grupo ou filial';
COMMENT ON COLUMN organizacao.igreja.igr_codigo_acms IS 'Código no sistema da Associação (ACMS/eAdventist)';
CREATE UNIQUE INDEX uq_igr_codigo_acms ON organizacao.igreja (igr_codigo_acms) WHERE igr_end_date IS NULL;
CREATE INDEX idx_igr_ent_id ON organizacao.igreja (igr_ent_id);
CREATE INDEX idx_igr_dst_id ON organizacao.igreja (igr_dst_id);
CREATE INDEX idx_igr_mae_igr_id ON organizacao.igreja (igr_mae_igr_id);

-- chaves estrangeiras que esperavam por organizacao.igreja
ALTER TABLE nucleo.usuario_igreja ADD CONSTRAINT fk_uig_igr_id FOREIGN KEY (uig_igr_id) REFERENCES organizacao.igreja(igr_id);

-- Departamentos e ministérios (Manual da Igreja)
CREATE TABLE organizacao.departamento (
    dep_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    dep_nome VARCHAR(100) NOT NULL,
    dep_descricao VARCHAR(255),
    dep_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    dep_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dep_criado_por INT,
    dep_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dep_modificado_por INT,
    dep_end_date TIMESTAMPTZ,
    CONSTRAINT chk_dep_end_date CHECK (dep_end_date IS NULL OR dep_end_date >= dep_criado_em)
);
COMMENT ON TABLE organizacao.departamento IS 'Departamentos e ministérios (Manual da Igreja)';
CREATE UNIQUE INDEX uq_dep_nome ON organizacao.departamento (dep_nome) WHERE dep_end_date IS NULL;

-- Departamento a funcionar numa igreja
CREATE TABLE organizacao.igreja_departamento (
    ide_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ide_igr_id INT NOT NULL,
    ide_dep_id INT NOT NULL,
    ide_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ide_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ide_criado_por INT,
    ide_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ide_modificado_por INT,
    ide_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ide_igr_id FOREIGN KEY (ide_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_ide_dep_id FOREIGN KEY (ide_dep_id) REFERENCES organizacao.departamento(dep_id),
    CONSTRAINT chk_ide_end_date CHECK (ide_end_date IS NULL OR ide_end_date >= ide_criado_em)
);
COMMENT ON TABLE organizacao.igreja_departamento IS 'Departamento a funcionar numa igreja';
CREATE UNIQUE INDEX uq_ide_igr_id_dep_id ON organizacao.igreja_departamento (ide_igr_id, ide_dep_id) WHERE ide_end_date IS NULL;
CREATE INDEX idx_ide_dep_id ON organizacao.igreja_departamento (ide_dep_id);

-- Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)
CREATE TABLE organizacao.cargo (
    car_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    car_dep_id INT,
    car_nome VARCHAR(100) NOT NULL,
    car_mandato_anos SMALLINT NOT NULL DEFAULT 1,
    car_exige_membro BOOLEAN NOT NULL DEFAULT TRUE,
    car_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    car_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    car_criado_por INT,
    car_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    car_modificado_por INT,
    car_end_date TIMESTAMPTZ,
    CONSTRAINT fk_car_dep_id FOREIGN KEY (car_dep_id) REFERENCES organizacao.departamento(dep_id),
    CONSTRAINT chk_car_mandato CHECK (car_mandato_anos IN (1, 2)),
    CONSTRAINT chk_car_end_date CHECK (car_end_date IS NULL OR car_end_date >= car_criado_em)
);
COMMENT ON TABLE organizacao.cargo IS 'Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)';
COMMENT ON COLUMN organizacao.cargo.car_dep_id IS 'NULL = cargo geral da igreja';
COMMENT ON COLUMN organizacao.cargo.car_mandato_anos IS 'Duração habitual do mandato';
COMMENT ON COLUMN organizacao.cargo.car_exige_membro IS 'Só membros em situação regular';
CREATE UNIQUE INDEX uq_car_nome ON organizacao.cargo (car_nome) WHERE car_end_date IS NULL;
CREATE INDEX idx_car_dep_id ON organizacao.cargo (car_dep_id);

-- >>>>> V4__secretaria.sql
-- =====================================================================
-- V4 · Módulo secretaria: Secretaria
-- Membros, famílias, reuniões e votos, movimentos do livro de membros, transferências, disciplina e eleições.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Agregados familiares
CREATE TABLE secretaria.familia (
    fam_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    fam_igr_id INT NOT NULL,
    fam_nome VARCHAR(150) NOT NULL,
    fam_morada VARCHAR(255),
    fam_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    fam_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fam_criado_por INT,
    fam_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fam_modificado_por INT,
    fam_end_date TIMESTAMPTZ,
    CONSTRAINT fk_fam_igr_id FOREIGN KEY (fam_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_fam_end_date CHECK (fam_end_date IS NULL OR fam_end_date >= fam_criado_em)
);
COMMENT ON TABLE secretaria.familia IS 'Agregados familiares';
CREATE INDEX idx_fam_igr_id ON secretaria.familia (fam_igr_id);

-- Membros, interessados e visitantes regulares (estado muda só por movimento)
CREATE TABLE secretaria.membro (
    mem_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mem_igr_id INT NOT NULL,
    mem_fam_id INT,
    mem_nome VARCHAR(100) NOT NULL,
    mem_apelido VARCHAR(100) NOT NULL,
    mem_data_nascimento DATE,
    mem_sexo sexo_t,
    mem_estado_civil estado_civil_t,
    mem_morada VARCHAR(255),
    mem_data_entrada DATE,
    mem_modo_entrada tipo_movimento_t,
    mem_encarregado_mem_id INT,
    mem_validacao estado_validacao_t NOT NULL DEFAULT 'PENDENTE',
    mem_validado_por_usu_id INT,
    mem_data_validacao TIMESTAMPTZ,
    mem_estado estado_membro_t NOT NULL DEFAULT 'INTERESSADO',
    mem_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mem_criado_por INT,
    mem_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mem_modificado_por INT,
    mem_end_date TIMESTAMPTZ,
    CONSTRAINT fk_mem_igr_id FOREIGN KEY (mem_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_mem_fam_id FOREIGN KEY (mem_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT fk_mem_encarregado_mem_id FOREIGN KEY (mem_encarregado_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_mem_validado_por_usu_id FOREIGN KEY (mem_validado_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_mem_encarregado CHECK (mem_encarregado_mem_id IS NULL OR mem_encarregado_mem_id <> mem_id),
    CONSTRAINT chk_mem_end_date CHECK (mem_end_date IS NULL OR mem_end_date >= mem_criado_em)
);
COMMENT ON TABLE secretaria.membro IS 'Membros, interessados e visitantes regulares (estado muda só por movimento)';
COMMENT ON COLUMN secretaria.membro.mem_data_entrada IS 'Data do voto de admissão nesta igreja';
COMMENT ON COLUMN secretaria.membro.mem_encarregado_mem_id IS 'Encarregado de educação (menores)';
CREATE INDEX idx_mem_igr_id ON secretaria.membro (mem_igr_id);
CREATE INDEX idx_mem_fam_id ON secretaria.membro (mem_fam_id);
CREATE INDEX idx_mem_encarregado_mem_id ON secretaria.membro (mem_encarregado_mem_id);
CREATE INDEX idx_mem_validado_por_usu_id ON secretaria.membro (mem_validado_por_usu_id);
CREATE INDEX idx_mem_igr_estado ON secretaria.membro (mem_igr_id, mem_estado) WHERE mem_end_date IS NULL;
CREATE INDEX idx_mem_nome ON secretaria.membro (lower(mem_apelido), lower(mem_nome));

-- chaves estrangeiras que esperavam por secretaria.membro
ALTER TABLE nucleo.usuario ADD CONSTRAINT fk_usu_mem_id FOREIGN KEY (usu_mem_id) REFERENCES secretaria.membro(mem_id);

-- Telefones, e-mails e WhatsApp de membros ou igrejas
CREATE TABLE secretaria.contacto (
    cto_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cto_mem_id INT,
    cto_igr_id INT,
    cto_tipo tipo_contacto_t NOT NULL,
    cto_valor VARCHAR(150) NOT NULL,
    cto_principal BOOLEAN NOT NULL DEFAULT FALSE,
    cto_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cto_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cto_criado_por INT,
    cto_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cto_modificado_por INT,
    cto_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cto_mem_id FOREIGN KEY (cto_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_cto_igr_id FOREIGN KEY (cto_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_cto_dono CHECK ((cto_mem_id IS NOT NULL) <> (cto_igr_id IS NOT NULL)),
    CONSTRAINT chk_cto_end_date CHECK (cto_end_date IS NULL OR cto_end_date >= cto_criado_em)
);
COMMENT ON TABLE secretaria.contacto IS 'Telefones, e-mails e WhatsApp de membros ou igrejas';
CREATE INDEX idx_cto_mem_id ON secretaria.contacto (cto_mem_id);
CREATE INDEX idx_cto_igr_id ON secretaria.contacto (cto_igr_id);

-- Consentimentos para tratamento de dados (menores: dado pelo encarregado)
CREATE TABLE secretaria.consentimento (
    cns_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cns_mem_id INT NOT NULL,
    cns_tipo tipo_consentimento_t NOT NULL,
    cns_concedido BOOLEAN NOT NULL,
    cns_data DATE NOT NULL DEFAULT CURRENT_DATE,
    cns_concedido_por_mem_id INT,
    cns_observacoes VARCHAR(255),
    cns_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cns_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cns_criado_por INT,
    cns_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cns_modificado_por INT,
    cns_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cns_mem_id FOREIGN KEY (cns_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_cns_concedido_por_mem_id FOREIGN KEY (cns_concedido_por_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_cns_end_date CHECK (cns_end_date IS NULL OR cns_end_date >= cns_criado_em)
);
COMMENT ON TABLE secretaria.consentimento IS 'Consentimentos para tratamento de dados (menores: dado pelo encarregado)';
CREATE INDEX idx_cns_mem_id ON secretaria.consentimento (cns_mem_id);
CREATE INDEX idx_cns_concedido_por_mem_id ON secretaria.consentimento (cns_concedido_por_mem_id);

-- Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES
CREATE TABLE secretaria.reuniao (
    reu_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    reu_igr_id INT NOT NULL,
    reu_tipo tipo_reuniao_t NOT NULL,
    reu_data TIMESTAMPTZ NOT NULL,
    reu_local VARCHAR(150),
    reu_presidida_por_mem_id INT,
    reu_secretario_mem_id INT,
    reu_quorum_presentes SMALLINT,
    reu_acta_url VARCHAR(500),
    reu_estado estado_reuniao_t NOT NULL DEFAULT 'CONVOCADA',
    reu_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    reu_criado_por INT,
    reu_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    reu_modificado_por INT,
    reu_end_date TIMESTAMPTZ,
    CONSTRAINT fk_reu_igr_id FOREIGN KEY (reu_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_reu_presidida_por_mem_id FOREIGN KEY (reu_presidida_por_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_reu_secretario_mem_id FOREIGN KEY (reu_secretario_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_reu_end_date CHECK (reu_end_date IS NULL OR reu_end_date >= reu_criado_em)
);
COMMENT ON TABLE secretaria.reuniao IS 'Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES';
CREATE INDEX idx_reu_igr_id ON secretaria.reuniao (reu_igr_id);
CREATE INDEX idx_reu_presidida_por_mem_id ON secretaria.reuniao (reu_presidida_por_mem_id);
CREATE INDEX idx_reu_secretario_mem_id ON secretaria.reuniao (reu_secretario_mem_id);

-- Votos registados em acta (admissões, transferências, remoções, eleições, finanças)
CREATE TABLE secretaria.voto (
    vot_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    vot_reu_id INT NOT NULL,
    vot_numero VARCHAR(20) NOT NULL,
    vot_tipo tipo_voto_t NOT NULL,
    vot_assunto VARCHAR(255) NOT NULL,
    vot_texto TEXT,
    vot_leitura SMALLINT NOT NULL DEFAULT 1,
    vot_a_favor SMALLINT,
    vot_contra SMALLINT,
    vot_abstencoes SMALLINT,
    vot_estado resultado_voto_t NOT NULL DEFAULT 'APROVADO',
    vot_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    vot_criado_por INT,
    vot_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    vot_modificado_por INT,
    vot_end_date TIMESTAMPTZ,
    CONSTRAINT fk_vot_reu_id FOREIGN KEY (vot_reu_id) REFERENCES secretaria.reuniao(reu_id),
    CONSTRAINT chk_vot_leitura CHECK (vot_leitura IN (1, 2)),
    CONSTRAINT chk_vot_end_date CHECK (vot_end_date IS NULL OR vot_end_date >= vot_criado_em)
);
COMMENT ON TABLE secretaria.voto IS 'Votos registados em acta (admissões, transferências, remoções, eleições, finanças)';
COMMENT ON COLUMN secretaria.voto.vot_numero IS 'Número do voto na acta, ex.: 2026-015';
COMMENT ON COLUMN secretaria.voto.vot_leitura IS '1 = primeira leitura, 2 = votação na semana seguinte';
CREATE UNIQUE INDEX uq_vot_reu_id_numero ON secretaria.voto (vot_reu_id, vot_numero) WHERE vot_end_date IS NULL;

-- Livro de membros: cada entrada e saída, com o voto que a autoriza
CREATE TABLE secretaria.movimento_membro (
    mmb_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mmb_mem_id INT NOT NULL,
    mmb_igr_id INT NOT NULL,
    mmb_tipo tipo_movimento_t NOT NULL,
    mmb_data DATE NOT NULL,
    mmb_vot_id INT,
    mmb_tme_id INT,
    mmb_observacoes VARCHAR(255),
    mmb_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    mmb_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mmb_criado_por INT,
    mmb_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mmb_modificado_por INT,
    mmb_end_date TIMESTAMPTZ,
    CONSTRAINT fk_mmb_mem_id FOREIGN KEY (mmb_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_mmb_igr_id FOREIGN KEY (mmb_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_mmb_vot_id FOREIGN KEY (mmb_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_mmb_voto CHECK (mmb_tipo = 'FALECIMENTO' OR mmb_vot_id IS NOT NULL OR mmb_tme_id IS NOT NULL),
    CONSTRAINT chk_mmb_end_date CHECK (mmb_end_date IS NULL OR mmb_end_date >= mmb_criado_em)
);
COMMENT ON TABLE secretaria.movimento_membro IS 'Livro de membros: cada entrada e saída, com o voto que a autoriza';
COMMENT ON COLUMN secretaria.movimento_membro.mmb_vot_id IS 'Obrigatório excepto falecimento';
CREATE INDEX idx_mmb_mem_id ON secretaria.movimento_membro (mmb_mem_id);
CREATE INDEX idx_mmb_igr_id ON secretaria.movimento_membro (mmb_igr_id);
CREATE INDEX idx_mmb_vot_id ON secretaria.movimento_membro (mmb_vot_id);
CREATE INDEX idx_mmb_tme_id ON secretaria.movimento_membro (mmb_tme_id);
CREATE INDEX idx_mmb_igr_data ON secretaria.movimento_membro (mmb_igr_id, mmb_data);

-- Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)
CREATE TABLE secretaria.transferencia_membro (
    tme_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tme_mem_id INT NOT NULL,
    tme_origem_igr_id INT NOT NULL,
    tme_destino_igr_id INT,
    tme_destino_externo VARCHAR(150),
    tme_data_pedido DATE NOT NULL DEFAULT CURRENT_DATE,
    tme_origem_vot_id INT,
    tme_carta_emitida_em DATE,
    tme_destino_vot_id INT,
    tme_aceite_em DATE,
    tme_observacoes VARCHAR(255),
    tme_estado estado_transferencia_t NOT NULL DEFAULT 'PEDIDA',
    tme_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tme_criado_por INT,
    tme_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tme_modificado_por INT,
    tme_end_date TIMESTAMPTZ,
    CONSTRAINT fk_tme_mem_id FOREIGN KEY (tme_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_tme_origem_igr_id FOREIGN KEY (tme_origem_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_tme_destino_igr_id FOREIGN KEY (tme_destino_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_tme_origem_vot_id FOREIGN KEY (tme_origem_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT fk_tme_destino_vot_id FOREIGN KEY (tme_destino_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_tme_destino CHECK (tme_destino_igr_id IS NOT NULL OR tme_destino_externo IS NOT NULL),
    CONSTRAINT chk_tme_diferente CHECK (tme_destino_igr_id IS NULL OR tme_destino_igr_id <> tme_origem_igr_id),
    CONSTRAINT chk_tme_carta CHECK (tme_estado IN ('PEDIDA', 'RECUSADA') OR (tme_origem_vot_id IS NOT NULL AND tme_carta_emitida_em IS NOT NULL)),
    CONSTRAINT chk_tme_validade CHECK (tme_aceite_em IS NULL OR tme_aceite_em <= tme_carta_emitida_em + INTERVAL '6 months'),
    CONSTRAINT chk_tme_conclusao CHECK (tme_estado <> 'CONCLUIDA' OR (tme_aceite_em IS NOT NULL AND (tme_destino_igr_id IS NULL OR tme_destino_vot_id IS NOT NULL))),
    CONSTRAINT chk_tme_end_date CHECK (tme_end_date IS NULL OR tme_end_date >= tme_criado_em)
);
COMMENT ON TABLE secretaria.transferencia_membro IS 'Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)';
COMMENT ON COLUMN secretaria.transferencia_membro.tme_destino_externo IS 'Igreja fora do sistema';
COMMENT ON COLUMN secretaria.transferencia_membro.tme_origem_vot_id IS 'Voto da igreja de origem que concede a carta';
COMMENT ON COLUMN secretaria.transferencia_membro.tme_destino_vot_id IS 'Voto da igreja de destino que aceita o membro';
CREATE INDEX idx_tme_mem_id ON secretaria.transferencia_membro (tme_mem_id);
CREATE INDEX idx_tme_origem_igr_id ON secretaria.transferencia_membro (tme_origem_igr_id);
CREATE INDEX idx_tme_destino_igr_id ON secretaria.transferencia_membro (tme_destino_igr_id);
CREATE INDEX idx_tme_origem_vot_id ON secretaria.transferencia_membro (tme_origem_vot_id);
CREATE INDEX idx_tme_destino_vot_id ON secretaria.transferencia_membro (tme_destino_vot_id);

-- chaves estrangeiras que esperavam por secretaria.transferencia_membro
ALTER TABLE secretaria.movimento_membro ADD CONSTRAINT fk_mmb_tme_id FOREIGN KEY (mmb_tme_id) REFERENCES secretaria.transferencia_membro(tme_id);

-- Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura
CREATE TABLE secretaria.disciplina (
    dsc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    dsc_mem_id INT NOT NULL,
    dsc_vot_id INT NOT NULL,
    dsc_data_inicio DATE NOT NULL,
    dsc_data_fim DATE NOT NULL,
    dsc_encarregado_notificado BOOLEAN NOT NULL DEFAULT FALSE,
    dsc_motivo TEXT,
    dsc_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    dsc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dsc_criado_por INT,
    dsc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dsc_modificado_por INT,
    dsc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_dsc_mem_id FOREIGN KEY (dsc_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_dsc_vot_id FOREIGN KEY (dsc_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_dsc_duracao CHECK (dsc_data_fim > dsc_data_inicio AND dsc_data_fim <= dsc_data_inicio + INTERVAL '12 months'),
    CONSTRAINT chk_dsc_end_date CHECK (dsc_end_date IS NULL OR dsc_end_date >= dsc_criado_em)
);
COMMENT ON TABLE secretaria.disciplina IS 'Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura';
COMMENT ON COLUMN secretaria.disciplina.dsc_encarregado_notificado IS 'Obrigatório para menores';
COMMENT ON COLUMN secretaria.disciplina.dsc_motivo IS 'Dado sensível: só secretário, pastor e anciãos';
CREATE INDEX idx_dsc_mem_id ON secretaria.disciplina (dsc_mem_id);
CREATE INDEX idx_dsc_vot_id ON secretaria.disciplina (dsc_vot_id);

-- Eleições e mandatos: quem ocupou que cargo e quando
CREATE TABLE secretaria.oficial (
    ofi_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ofi_mem_id INT NOT NULL,
    ofi_car_id INT NOT NULL,
    ofi_igr_id INT NOT NULL,
    ofi_vot_id INT,
    ofi_data_inicio DATE NOT NULL,
    ofi_data_fim DATE,
    ofi_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ofi_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ofi_criado_por INT,
    ofi_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ofi_modificado_por INT,
    ofi_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ofi_mem_id FOREIGN KEY (ofi_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_ofi_car_id FOREIGN KEY (ofi_car_id) REFERENCES organizacao.cargo(car_id),
    CONSTRAINT fk_ofi_igr_id FOREIGN KEY (ofi_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_ofi_vot_id FOREIGN KEY (ofi_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_ofi_datas CHECK (ofi_data_fim IS NULL OR ofi_data_fim >= ofi_data_inicio),
    CONSTRAINT chk_ofi_end_date CHECK (ofi_end_date IS NULL OR ofi_end_date >= ofi_criado_em)
);
COMMENT ON TABLE secretaria.oficial IS 'Eleições e mandatos: quem ocupou que cargo e quando';
COMMENT ON COLUMN secretaria.oficial.ofi_vot_id IS 'Voto da igreja que aprovou o relatório da comissão de nomeações';
CREATE INDEX idx_ofi_mem_id ON secretaria.oficial (ofi_mem_id);
CREATE INDEX idx_ofi_car_id ON secretaria.oficial (ofi_car_id);
CREATE INDEX idx_ofi_igr_id ON secretaria.oficial (ofi_igr_id);
CREATE INDEX idx_ofi_vot_id ON secretaria.oficial (ofi_vot_id);

-- Baptismos e rebaptismos
CREATE TABLE secretaria.baptismo (
    bap_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    bap_mem_id INT NOT NULL,
    bap_data DATE NOT NULL,
    bap_local VARCHAR(150),
    bap_oficiante VARCHAR(150),
    bap_rebaptismo BOOLEAN NOT NULL DEFAULT FALSE,
    bap_ect_id INT,
    bap_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    bap_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    bap_criado_por INT,
    bap_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    bap_modificado_por INT,
    bap_end_date TIMESTAMPTZ,
    CONSTRAINT fk_bap_mem_id FOREIGN KEY (bap_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_bap_end_date CHECK (bap_end_date IS NULL OR bap_end_date >= bap_criado_em)
);
COMMENT ON TABLE secretaria.baptismo IS 'Baptismos e rebaptismos';
COMMENT ON COLUMN secretaria.baptismo.bap_oficiante IS 'Pastor ordenado que baptizou';
COMMENT ON COLUMN secretaria.baptismo.bap_ect_id IS 'Classe da ES que preparou o candidato';
CREATE INDEX idx_bap_mem_id ON secretaria.baptismo (bap_mem_id);
CREATE INDEX idx_bap_ect_id ON secretaria.baptismo (bap_ect_id);
CREATE UNIQUE INDEX uq_bap_mem ON secretaria.baptismo (bap_mem_id) WHERE NOT bap_rebaptismo AND bap_end_date IS NULL;

-- Regras da secretaria (Manual da Igreja) -------------------------------

-- Verifica um voto: aprovado, da igreja certa e num tipo de reunião permitido
CREATE FUNCTION secretaria.fn_voto_valido(p_vot BIGINT, p_igr INT, p_tipos nucleo.tipo_reuniao_t[],
                                          p_exige_segunda_leitura BOOLEAN DEFAULT FALSE) RETURNS TEXT AS $$
DECLARE r RECORD;
BEGIN
    SELECT v.vot_estado, v.vot_leitura, u.reu_igr_id, u.reu_tipo INTO r
    FROM secretaria.voto v JOIN secretaria.reuniao u ON u.reu_id = v.vot_reu_id
    WHERE v.vot_id = p_vot AND v.vot_end_date IS NULL;
    IF NOT FOUND THEN RETURN 'o voto não existe'; END IF;
    IF r.vot_estado <> 'APROVADO' THEN RETURN 'o voto não foi aprovado'; END IF;
    IF r.reu_igr_id <> p_igr THEN RETURN 'o voto é de outra igreja'; END IF;
    IF NOT (r.reu_tipo = ANY (p_tipos)) THEN
        RETURN format('o voto foi tomado em %s; este acto exige %s', r.reu_tipo, array_to_string(p_tipos, ' ou '));
    END IF;
    IF p_exige_segunda_leitura AND r.vot_leitura <> 2 THEN
        RETURN 'é preciso a votação na segunda leitura (primeira leitura numa semana, voto na seguinte)';
    END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION secretaria.fn_em_censura(p_mem INT, p_data DATE) RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT 1 FROM secretaria.disciplina
                   WHERE dsc_mem_id = p_mem AND dsc_end_date IS NULL
                     AND p_data >= dsc_data_inicio AND p_data < dsc_data_fim);
$$ LANGUAGE sql STABLE;

-- O estado e a igreja do membro só mudam através do livro de membros;
-- aprovar o registo de um membro exige a permissão "validar"
CREATE FUNCTION secretaria.fn_mem_proteger() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.mem_estado, NEW.mem_igr_id) IS DISTINCT FROM (OLD.mem_estado, OLD.mem_igr_id)
       AND current_setting('app.via_movimento', true) IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'O estado e a igreja do membro só mudam com um movimento no livro de membros (secretaria.movimento_membro)';
    END IF;
    IF (TG_OP = 'INSERT' AND NEW.mem_validacao <> 'PENDENTE')
       OR (TG_OP = 'UPDATE' AND NEW.mem_validacao IS DISTINCT FROM OLD.mem_validacao) THEN
        PERFORM nucleo.fn_exigir('secretaria.membro.validar', NEW.mem_igr_id);
        NEW.mem_validado_por_usu_id := COALESCE(nucleo.fn_usuario_sessao(), NEW.mem_validado_por_usu_id);
        NEW.mem_data_validacao := now();
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mem_10_proteger
    BEFORE INSERT OR UPDATE ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_proteger();

-- Movimento no livro de membros: valida o voto e aplica-o ao membro
CREATE FUNCTION secretaria.fn_mmb_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    reg  nucleo.tipo_reuniao_t[] := ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[];
BEGIN
    IF NEW.mmb_tme_id IS NOT NULL OR NEW.mmb_tipo = 'FALECIMENTO' THEN
        RETURN NEW;                                       -- transferências validam-se na carta
    END IF;
    erro := secretaria.fn_voto_valido(NEW.mmb_vot_id, NEW.mmb_igr_id,
        CASE NEW.mmb_tipo
            WHEN 'REMOCAO_PEDIDO'     THEN ARRAY['JUNTA_DIRECTIVA', 'REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            WHEN 'REMOCAO_DISCIPLINA' THEN ARRAY['ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            WHEN 'DESAPARECIDO'       THEN ARRAY['ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            ELSE reg END);
    IF erro IS NOT NULL THEN
        RAISE EXCEPTION 'Movimento % do membro %: %', NEW.mmb_tipo, NEW.mmb_mem_id, erro;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mmb_10_validar
    BEFORE INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_validar();

-- Corre com privilégios do sistema: quem pode registar o movimento pode aplicá-lo ao membro
CREATE FUNCTION secretaria.fn_mmb_aplicar() RETURNS trigger AS $$
BEGIN
    PERFORM set_config('app.via_movimento', 'on', true);
    IF NEW.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA') THEN
        UPDATE secretaria.membro
           SET mem_estado = 'ACTIVO', mem_igr_id = NEW.mmb_igr_id,
               mem_data_entrada = NEW.mmb_data, mem_modo_entrada = NEW.mmb_tipo
         WHERE mem_id = NEW.mmb_mem_id;
    ELSIF NEW.mmb_tipo = 'TRANSFERENCIA_SAIDA' THEN
        UPDATE secretaria.membro SET mem_estado = 'TRANSFERIDO', mem_fam_id = NULL WHERE mem_id = NEW.mmb_mem_id;
    ELSE
        UPDATE secretaria.membro
           SET mem_estado = CASE NEW.mmb_tipo WHEN 'FALECIMENTO'  THEN 'FALECIDO'
                                              WHEN 'DESAPARECIDO' THEN 'DESAPARECIDO'
                                              ELSE 'REMOVIDO' END::nucleo.estado_membro_t
         WHERE mem_id = NEW.mmb_mem_id;
        -- quem deixa de ser membro deixa os cargos
        UPDATE secretaria.oficial SET ofi_data_fim = NEW.mmb_data
         WHERE ofi_mem_id = NEW.mmb_mem_id AND ofi_data_fim IS NULL AND ofi_end_date IS NULL;
    END IF;
    PERFORM set_config('app.via_movimento', 'off', true);
    RETURN NULL;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_mmb_20_aplicar
    AFTER INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_aplicar();

CREATE FUNCTION secretaria.fn_mmb_imutavel() RETURNS trigger AS $$
BEGIN
    IF (NEW.mmb_mem_id, NEW.mmb_igr_id, NEW.mmb_tipo, NEW.mmb_data, NEW.mmb_vot_id)
       IS DISTINCT FROM (OLD.mmb_mem_id, OLD.mmb_igr_id, OLD.mmb_tipo, OLD.mmb_data, OLD.mmb_vot_id) THEN
        RAISE EXCEPTION 'Um movimento do livro de membros não se altera; registe um novo movimento';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mmb_10_imutavel
    BEFORE UPDATE ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_imutavel();

-- Carta de transferência
CREATE FUNCTION secretaria.fn_tme_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    reg  nucleo.tipo_reuniao_t[] := ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[];
    v_estado nucleo.estado_membro_t;
BEGIN
    IF NEW.tme_estado = 'CARTA_EMITIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CARTA_EMITIDA') THEN
        PERFORM nucleo.fn_exigir('secretaria.transferencia_membro.emitir_carta', NEW.tme_origem_igr_id);
        SELECT mem_estado INTO v_estado FROM secretaria.membro WHERE mem_id = NEW.tme_mem_id;
        IF v_estado <> 'ACTIVO' THEN
            RAISE EXCEPTION 'Só se emite carta a um membro activo (estado actual: %)', v_estado;
        END IF;
        IF secretaria.fn_em_censura(NEW.tme_mem_id, NEW.tme_carta_emitida_em) THEN
            RAISE EXCEPTION 'Um membro sob censura não pode receber carta de transferência';
        END IF;
        erro := secretaria.fn_voto_valido(NEW.tme_origem_vot_id, NEW.tme_origem_igr_id, reg, TRUE);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Carta de transferência: %', erro; END IF;
    END IF;
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA') THEN
        PERFORM nucleo.fn_exigir('secretaria.transferencia_membro.aceitar', COALESCE(NEW.tme_destino_igr_id, NEW.tme_origem_igr_id));
    END IF;
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA')
       AND NEW.tme_destino_igr_id IS NOT NULL THEN
        erro := secretaria.fn_voto_valido(NEW.tme_destino_vot_id, NEW.tme_destino_igr_id, reg, TRUE);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Aceitação da transferência: %', erro; END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tme_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.transferencia_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_tme_validar();

-- Ao concluir: saída na origem e entrada no destino (as duas igrejas ficam com o registo).
-- SECURITY DEFINER porque mexe nas duas igrejas, que um utilizador normalmente não vê ao mesmo tempo.
CREATE FUNCTION secretaria.fn_tme_concluir() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA') THEN
        INSERT INTO secretaria.movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_tme_id)
        VALUES (NEW.tme_mem_id, NEW.tme_origem_igr_id, 'TRANSFERENCIA_SAIDA', NEW.tme_aceite_em, NEW.tme_id);
        IF NEW.tme_destino_igr_id IS NOT NULL THEN
            INSERT INTO secretaria.movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id, mmb_tme_id)
            VALUES (NEW.tme_mem_id, NEW.tme_destino_igr_id, 'TRANSFERENCIA_ENTRADA', NEW.tme_aceite_em,
                    NEW.tme_destino_vot_id, NEW.tme_id);
        END IF;
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_tme_20_concluir
    AFTER INSERT OR UPDATE ON secretaria.transferencia_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_tme_concluir();

-- Censura: voto da igreja, encarregado avisado se for menor, e o membro deixa os cargos
CREATE FUNCTION secretaria.fn_dsc_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    v_nasc DATE; v_igr INT;
BEGIN
    SELECT mem_data_nascimento, mem_igr_id INTO v_nasc, v_igr FROM secretaria.membro WHERE mem_id = NEW.dsc_mem_id;
    erro := secretaria.fn_voto_valido(NEW.dsc_vot_id, v_igr,
            ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]);
    IF erro IS NOT NULL THEN RAISE EXCEPTION 'Censura: %', erro; END IF;
    IF v_nasc > NEW.dsc_data_inicio - INTERVAL '18 years' AND NOT NEW.dsc_encarregado_notificado THEN
        RAISE EXCEPTION 'O membro é menor: os pais ou encarregado têm de ser avisados';
    END IF;
    IF TG_OP = 'INSERT' THEN
        UPDATE secretaria.oficial SET ofi_data_fim = NEW.dsc_data_inicio
         WHERE ofi_mem_id = NEW.dsc_mem_id AND ofi_data_fim IS NULL AND ofi_end_date IS NULL;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dsc_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.disciplina
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_dsc_validar();

-- Eleição: membro activo da igreja, sem censura, voto de eleição aprovado
CREATE FUNCTION secretaria.fn_ofi_validar() RETURNS trigger AS $$
DECLARE
    v_exige BOOLEAN; m RECORD; erro TEXT;
BEGIN
    IF NEW.ofi_data_fim IS NOT NULL AND TG_OP = 'UPDATE' AND OLD.ofi_data_fim IS NULL THEN
        RETURN NEW;                                       -- fim de mandato: sempre permitido
    END IF;
    SELECT car_exige_membro INTO v_exige FROM organizacao.cargo WHERE car_id = NEW.ofi_car_id;
    SELECT mem_estado, mem_igr_id INTO m FROM secretaria.membro WHERE mem_id = NEW.ofi_mem_id;
    IF v_exige AND (m.mem_estado <> 'ACTIVO' OR m.mem_igr_id <> NEW.ofi_igr_id) THEN
        RAISE EXCEPTION 'Este cargo exige um membro activo desta igreja';
    END IF;
    IF secretaria.fn_em_censura(NEW.ofi_mem_id, NEW.ofi_data_inicio) THEN
        RAISE EXCEPTION 'Um membro sob censura não pode ocupar cargos';
    END IF;
    IF NEW.ofi_vot_id IS NOT NULL THEN
        erro := secretaria.fn_voto_valido(NEW.ofi_vot_id, NEW.ofi_igr_id,
                ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Eleição: %', erro; END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ofi_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.oficial
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_ofi_validar();


-- >>>>> V5__actividades.sql
-- =====================================================================
-- V5 · Módulo actividades: Actividades e escalas
-- Programas dos departamentos, material necessário e escalas de serviço.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Actividades e eventos dos departamentos
CREATE TABLE actividades.actividade (
    act_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    act_ide_id INT NOT NULL,
    act_responsavel_mem_id INT,
    act_nome VARCHAR(150) NOT NULL,
    act_descricao TEXT,
    act_local VARCHAR(255),
    act_data_inicio TIMESTAMPTZ NOT NULL,
    act_data_fim TIMESTAMPTZ,
    act_data_hora_lembrete TIMESTAMPTZ,
    act_valor_previsto DECIMAL(12,2) NOT NULL DEFAULT 0,
    act_estado estado_actividade_t NOT NULL DEFAULT 'PLANEADA',
    act_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    act_criado_por INT,
    act_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    act_modificado_por INT,
    act_end_date TIMESTAMPTZ,
    CONSTRAINT fk_act_ide_id FOREIGN KEY (act_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_act_responsavel_mem_id FOREIGN KEY (act_responsavel_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_act_datas CHECK (act_data_fim IS NULL OR act_data_fim >= act_data_inicio),
    CONSTRAINT chk_act_end_date CHECK (act_end_date IS NULL OR act_end_date >= act_criado_em)
);
COMMENT ON TABLE actividades.actividade IS 'Actividades e eventos dos departamentos';
CREATE INDEX idx_act_ide_id ON actividades.actividade (act_ide_id);
CREATE INDEX idx_act_responsavel_mem_id ON actividades.actividade (act_responsavel_mem_id);

-- Material necessário para uma actividade
CREATE TABLE actividades.material (
    mat_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mat_act_id INT NOT NULL,
    mat_descricao VARCHAR(255) NOT NULL,
    mat_quantidade DECIMAL(10,2) NOT NULL DEFAULT 1,
    mat_preco_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    mat_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    mat_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mat_criado_por INT,
    mat_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mat_modificado_por INT,
    mat_end_date TIMESTAMPTZ,
    CONSTRAINT fk_mat_act_id FOREIGN KEY (mat_act_id) REFERENCES actividades.actividade(act_id),
    CONSTRAINT chk_mat_end_date CHECK (mat_end_date IS NULL OR mat_end_date >= mat_criado_em)
);
COMMENT ON TABLE actividades.material IS 'Material necessário para uma actividade';
CREATE INDEX idx_mat_act_id ON actividades.material (mat_act_id);

-- Escalas de serviço (pregador, diáconos, recepção, ...)
CREATE TABLE actividades.escala (
    esc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    esc_igr_id INT NOT NULL,
    esc_data DATE NOT NULL,
    esc_funcao funcao_escala_t NOT NULL,
    esc_mem_id INT NOT NULL,
    esc_act_id INT,
    esc_substituto_mem_id INT,
    esc_observacoes VARCHAR(255),
    esc_estado estado_escala_t NOT NULL DEFAULT 'PREVISTA',
    esc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    esc_criado_por INT,
    esc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    esc_modificado_por INT,
    esc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_esc_igr_id FOREIGN KEY (esc_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_esc_mem_id FOREIGN KEY (esc_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_esc_act_id FOREIGN KEY (esc_act_id) REFERENCES actividades.actividade(act_id),
    CONSTRAINT fk_esc_substituto_mem_id FOREIGN KEY (esc_substituto_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_esc_end_date CHECK (esc_end_date IS NULL OR esc_end_date >= esc_criado_em)
);
COMMENT ON TABLE actividades.escala IS 'Escalas de serviço (pregador, diáconos, recepção, ...)';
CREATE UNIQUE INDEX uq_esc_igr_id_data_funcao_mem_id ON actividades.escala (esc_igr_id, esc_data, esc_funcao, esc_mem_id) WHERE esc_end_date IS NULL;
CREATE INDEX idx_esc_mem_id ON actividades.escala (esc_mem_id);
CREATE INDEX idx_esc_act_id ON actividades.escala (esc_act_id);
CREATE INDEX idx_esc_substituto_mem_id ON actividades.escala (esc_substituto_mem_id);

-- >>>>> V6__escola_sabatina.sql
-- =====================================================================
-- V6 · Módulo escola_sabatina: Escola Sabatina
-- Trimestres, sábados, classes (unidades de acção) por divisão, relatórios, chamada, visitantes e pontuação.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Trimestres da lição
CREATE TABLE escola_sabatina.trimestre (
    etr_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    etr_ano SMALLINT NOT NULL,
    etr_numero SMALLINT NOT NULL,
    etr_tema_licao VARCHAR(200),
    etr_data_inicio DATE NOT NULL,
    etr_data_fim DATE NOT NULL,
    etr_num_sabados SMALLINT NOT NULL,
    etr_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    etr_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    etr_criado_por INT,
    etr_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    etr_modificado_por INT,
    etr_end_date TIMESTAMPTZ,
    CONSTRAINT chk_etr_numero CHECK (etr_numero BETWEEN 1 AND 4),
    CONSTRAINT chk_etr_sabados CHECK (etr_num_sabados IN (13, 14)),
    CONSTRAINT chk_etr_datas CHECK (etr_data_fim > etr_data_inicio),
    CONSTRAINT chk_etr_end_date CHECK (etr_end_date IS NULL OR etr_end_date >= etr_criado_em)
);
COMMENT ON TABLE escola_sabatina.trimestre IS 'Trimestres da lição';
CREATE UNIQUE INDEX uq_etr_ano_numero ON escola_sabatina.trimestre (etr_ano, etr_numero) WHERE etr_end_date IS NULL;

-- Sábados de cada trimestre
CREATE TABLE escola_sabatina.sabado (
    esa_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    esa_etr_id INT NOT NULL,
    esa_numero SMALLINT NOT NULL,
    esa_data DATE NOT NULL,
    esa_decimo_terceiro BOOLEAN NOT NULL DEFAULT FALSE,
    esa_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    esa_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    esa_criado_por INT,
    esa_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    esa_modificado_por INT,
    esa_end_date TIMESTAMPTZ,
    CONSTRAINT fk_esa_etr_id FOREIGN KEY (esa_etr_id) REFERENCES escola_sabatina.trimestre(etr_id),
    CONSTRAINT chk_esa_numero CHECK (esa_numero BETWEEN 1 AND 14),
    CONSTRAINT chk_esa_sabado CHECK (EXTRACT(ISODOW FROM esa_data) = 6),
    CONSTRAINT chk_esa_end_date CHECK (esa_end_date IS NULL OR esa_end_date >= esa_criado_em)
);
COMMENT ON TABLE escola_sabatina.sabado IS 'Sábados de cada trimestre';
CREATE UNIQUE INDEX uq_esa_etr_id_numero ON escola_sabatina.sabado (esa_etr_id, esa_numero) WHERE esa_end_date IS NULL;
CREATE UNIQUE INDEX uq_esa_data ON escola_sabatina.sabado (esa_data) WHERE esa_end_date IS NULL;
CREATE UNIQUE INDEX uq_esa_13 ON escola_sabatina.sabado (esa_etr_id) WHERE esa_decimo_terceiro AND esa_end_date IS NULL;

-- Classes / unidades de acção, por divisão da Escola Sabatina
CREATE TABLE escola_sabatina.classe (
    ecl_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ecl_igr_id INT NOT NULL,
    ecl_nome VARCHAR(100) NOT NULL,
    ecl_divisao es_divisao_t NOT NULL DEFAULT 'ADULTOS',
    ecl_local_reuniao VARCHAR(150),
    ecl_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ecl_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ecl_criado_por INT,
    ecl_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ecl_modificado_por INT,
    ecl_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ecl_igr_id FOREIGN KEY (ecl_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_ecl_end_date CHECK (ecl_end_date IS NULL OR ecl_end_date >= ecl_criado_em)
);
COMMENT ON TABLE escola_sabatina.classe IS 'Classes / unidades de acção, por divisão da Escola Sabatina';
CREATE UNIQUE INDEX uq_ecl_igr_id_nome ON escola_sabatina.classe (ecl_igr_id, ecl_nome) WHERE ecl_end_date IS NULL;

-- Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)
CREATE TABLE escola_sabatina.classe_trimestre (
    ect_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ect_ecl_id INT NOT NULL,
    ect_etr_id INT NOT NULL,
    ect_igr_id INT NOT NULL,
    ect_professor_mem_id INT,
    ect_auxiliar_mem_id INT,
    ect_secretario_mem_id INT,
    ect_alvo_membros SMALLINT NOT NULL DEFAULT 0,
    ect_alvo_estudo_diario DECIMAL(5,4) NOT NULL DEFAULT 1,
    ect_alvo_filiais SMALLINT NOT NULL DEFAULT 0,
    ect_alvo_oferta_sabado DECIMAL(12,2) NOT NULL DEFAULT 0,
    ect_alvo_baptismos SMALLINT NOT NULL DEFAULT 0,
    ect_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ect_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ect_criado_por INT,
    ect_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ect_modificado_por INT,
    ect_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ect_ecl_id FOREIGN KEY (ect_ecl_id) REFERENCES escola_sabatina.classe(ecl_id),
    CONSTRAINT fk_ect_etr_id FOREIGN KEY (ect_etr_id) REFERENCES escola_sabatina.trimestre(etr_id),
    CONSTRAINT fk_ect_igr_id FOREIGN KEY (ect_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_ect_professor_mem_id FOREIGN KEY (ect_professor_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_ect_auxiliar_mem_id FOREIGN KEY (ect_auxiliar_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_ect_secretario_mem_id FOREIGN KEY (ect_secretario_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_ect_alvos CHECK (ect_alvo_membros >= 0 AND ect_alvo_estudo_diario BETWEEN 0 AND 1 AND ect_alvo_oferta_sabado >= 0),
    CONSTRAINT chk_ect_end_date CHECK (ect_end_date IS NULL OR ect_end_date >= ect_criado_em)
);
COMMENT ON TABLE escola_sabatina.classe_trimestre IS 'Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)';
COMMENT ON COLUMN escola_sabatina.classe_trimestre.ect_igr_id IS 'Copiado da classe (segurança e desempenho)';
COMMENT ON COLUMN escola_sabatina.classe_trimestre.ect_alvo_oferta_sabado IS 'Alvo da oferta missionária por sábado';
CREATE UNIQUE INDEX uq_ect_ecl_id_etr_id ON escola_sabatina.classe_trimestre (ect_ecl_id, ect_etr_id) WHERE ect_end_date IS NULL;
CREATE INDEX idx_ect_etr_id ON escola_sabatina.classe_trimestre (ect_etr_id);
CREATE INDEX idx_ect_igr_id ON escola_sabatina.classe_trimestre (ect_igr_id);
CREATE INDEX idx_ect_professor_mem_id ON escola_sabatina.classe_trimestre (ect_professor_mem_id);
CREATE INDEX idx_ect_auxiliar_mem_id ON escola_sabatina.classe_trimestre (ect_auxiliar_mem_id);
CREATE INDEX idx_ect_secretario_mem_id ON escola_sabatina.classe_trimestre (ect_secretario_mem_id);
CREATE INDEX idx_ect_igr_etr ON escola_sabatina.classe_trimestre (ect_igr_id, ect_etr_id) WHERE ect_end_date IS NULL;

-- chaves estrangeiras que esperavam por escola_sabatina.classe_trimestre
ALTER TABLE secretaria.baptismo ADD CONSTRAINT fk_bap_ect_id FOREIGN KEY (bap_ect_id) REFERENCES escola_sabatina.classe_trimestre(ect_id);

-- Inscrição nas classes (histórico); membros e não membros
CREATE TABLE escola_sabatina.matricula (
    ema_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ema_ecl_id INT NOT NULL,
    ema_mem_id INT NOT NULL,
    ema_data_entrada DATE NOT NULL DEFAULT CURRENT_DATE,
    ema_data_saida DATE,
    ema_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ema_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ema_criado_por INT,
    ema_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ema_modificado_por INT,
    ema_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ema_ecl_id FOREIGN KEY (ema_ecl_id) REFERENCES escola_sabatina.classe(ecl_id),
    CONSTRAINT fk_ema_mem_id FOREIGN KEY (ema_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_ema_datas CHECK (ema_data_saida IS NULL OR ema_data_saida >= ema_data_entrada),
    CONSTRAINT chk_ema_end_date CHECK (ema_end_date IS NULL OR ema_end_date >= ema_criado_em)
);
COMMENT ON TABLE escola_sabatina.matricula IS 'Inscrição nas classes (histórico); membros e não membros';
CREATE INDEX idx_ema_ecl_id ON escola_sabatina.matricula (ema_ecl_id);
CREATE INDEX idx_ema_mem_id ON escola_sabatina.matricula (ema_mem_id);
CREATE UNIQUE INDEX uq_ema_activa ON escola_sabatina.matricula (ema_mem_id) WHERE ema_data_saida IS NULL AND ema_end_date IS NULL;

-- Relatório de cada classe em cada sábado (linha da folha "Grupo N")
CREATE TABLE escola_sabatina.relatorio_sabado (
    ers_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ers_ect_id INT NOT NULL,
    ers_esa_id INT NOT NULL,
    ers_igr_id INT NOT NULL,
    ers_membros_matriculados SMALLINT NOT NULL,
    ers_membros_presentes SMALLINT NOT NULL,
    ers_estudo_diario SMALLINT NOT NULL DEFAULT 0,
    ers_visitantes SMALLINT NOT NULL DEFAULT 0,
    ers_filiais SMALLINT NOT NULL DEFAULT 0,
    ers_oferta DECIMAL(12,2) NOT NULL DEFAULT 0,
    ers_oferta_13_sabado DECIMAL(12,2) NOT NULL DEFAULT 0,
    ers_oferta_despesas DECIMAL(12,2) NOT NULL DEFAULT 0,
    ers_tra_id BIGINT,
    ers_observacoes VARCHAR(500),
    ers_estado estado_relatorio_t NOT NULL DEFAULT 'ABERTO',
    ers_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ers_criado_por INT,
    ers_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ers_modificado_por INT,
    ers_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ers_ect_id FOREIGN KEY (ers_ect_id) REFERENCES escola_sabatina.classe_trimestre(ect_id),
    CONSTRAINT fk_ers_esa_id FOREIGN KEY (ers_esa_id) REFERENCES escola_sabatina.sabado(esa_id),
    CONSTRAINT fk_ers_igr_id FOREIGN KEY (ers_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_ers_numeros CHECK (ers_membros_presentes BETWEEN 0 AND ers_membros_matriculados AND ers_estudo_diario BETWEEN 0 AND ers_membros_presentes AND ers_visitantes >= 0 AND ers_filiais >= 0),
    CONSTRAINT chk_ers_ofertas CHECK (ers_oferta >= 0 AND ers_oferta_13_sabado >= 0 AND ers_oferta_despesas >= 0),
    CONSTRAINT chk_ers_end_date CHECK (ers_end_date IS NULL OR ers_end_date >= ers_criado_em)
);
COMMENT ON TABLE escola_sabatina.relatorio_sabado IS 'Relatório de cada classe em cada sábado (linha da folha "Grupo N")';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_igr_id IS 'Copiado da classe (segurança e desempenho)';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_membros_matriculados IS 'M.M. (se vier vazio, é calculado pelas matrículas)';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_membros_presentes IS 'M.P. (recalculado quando há chamada nominal)';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_estudo_diario IS 'E.D.';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_oferta IS 'Oferta missionária (vai toda para as missões)';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_oferta_despesas IS 'Oferta para despesas da ES local (sempre separada da missionária)';
COMMENT ON COLUMN escola_sabatina.relatorio_sabado.ers_tra_id IS 'Lançamento das ofertas na tesouraria';
CREATE UNIQUE INDEX uq_ers_ect_id_esa_id ON escola_sabatina.relatorio_sabado (ers_ect_id, ers_esa_id) WHERE ers_end_date IS NULL;
CREATE INDEX idx_ers_esa_id ON escola_sabatina.relatorio_sabado (ers_esa_id);
CREATE INDEX idx_ers_igr_id ON escola_sabatina.relatorio_sabado (ers_igr_id);
CREATE INDEX idx_ers_tra_id ON escola_sabatina.relatorio_sabado (ers_tra_id);

-- Chamada nominal (opcional); actualiza M.P. e E.D. do relatório
CREATE TABLE escola_sabatina.presenca (
    epr_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    epr_ers_id INT NOT NULL,
    epr_mem_id INT NOT NULL,
    epr_igr_id INT NOT NULL,
    epr_presente BOOLEAN NOT NULL,
    epr_estudou_licao BOOLEAN NOT NULL DEFAULT FALSE,
    epr_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    epr_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epr_criado_por INT,
    epr_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epr_modificado_por INT,
    epr_end_date TIMESTAMPTZ,
    CONSTRAINT fk_epr_ers_id FOREIGN KEY (epr_ers_id) REFERENCES escola_sabatina.relatorio_sabado(ers_id),
    CONSTRAINT fk_epr_mem_id FOREIGN KEY (epr_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_epr_igr_id FOREIGN KEY (epr_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_epr_estudo CHECK (epr_presente OR NOT epr_estudou_licao),
    CONSTRAINT chk_epr_end_date CHECK (epr_end_date IS NULL OR epr_end_date >= epr_criado_em)
);
COMMENT ON TABLE escola_sabatina.presenca IS 'Chamada nominal (opcional); actualiza M.P. e E.D. do relatório';
COMMENT ON COLUMN escola_sabatina.presenca.epr_igr_id IS 'Copiado do relatório (segurança e desempenho)';
CREATE UNIQUE INDEX uq_epr_ers_id_mem_id ON escola_sabatina.presenca (epr_ers_id, epr_mem_id) WHERE epr_end_date IS NULL;
CREATE INDEX idx_epr_mem_id ON escola_sabatina.presenca (epr_mem_id);
CREATE INDEX idx_epr_igr_id ON escola_sabatina.presenca (epr_igr_id);
CREATE INDEX idx_epr_mem ON escola_sabatina.presenca (epr_mem_id) WHERE epr_presente;

-- Visitantes com contacto para seguimento
CREATE TABLE escola_sabatina.visitante (
    evi_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    evi_ers_id INT NOT NULL,
    evi_nome VARCHAR(150) NOT NULL,
    evi_telefone VARCHAR(20),
    evi_convidado_por_mem_id INT,
    evi_tornou_se_mem_id INT,
    evi_anonimizado_em TIMESTAMPTZ,
    evi_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    evi_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    evi_criado_por INT,
    evi_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    evi_modificado_por INT,
    evi_end_date TIMESTAMPTZ,
    CONSTRAINT fk_evi_ers_id FOREIGN KEY (evi_ers_id) REFERENCES escola_sabatina.relatorio_sabado(ers_id),
    CONSTRAINT fk_evi_convidado_por_mem_id FOREIGN KEY (evi_convidado_por_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_evi_tornou_se_mem_id FOREIGN KEY (evi_tornou_se_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_evi_end_date CHECK (evi_end_date IS NULL OR evi_end_date >= evi_criado_em)
);
COMMENT ON TABLE escola_sabatina.visitante IS 'Visitantes com contacto para seguimento';
COMMENT ON COLUMN escola_sabatina.visitante.evi_anonimizado_em IS 'Dados apagados por fim do prazo de retenção';
CREATE INDEX idx_evi_ers_id ON escola_sabatina.visitante (evi_ers_id);
CREATE INDEX idx_evi_convidado_por_mem_id ON escola_sabatina.visitante (evi_convidado_por_mem_id);
CREATE INDEX idx_evi_tornou_se_mem_id ON escola_sabatina.visitante (evi_tornou_se_mem_id);

-- Pesos da pontuação (sem trimestre = pesos por defeito)
CREATE TABLE escola_sabatina.pontuacao_config (
    epc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    epc_etr_id INT,
    epc_peso_presenca DECIMAL(4,3) NOT NULL DEFAULT 0.30,
    epc_peso_estudo DECIMAL(4,3) NOT NULL DEFAULT 0.30,
    epc_peso_ofertas DECIMAL(4,3) NOT NULL DEFAULT 0.25,
    epc_peso_visitantes DECIMAL(4,3) NOT NULL DEFAULT 0.15,
    epc_limite_ofertas DECIMAL(4,2) NOT NULL DEFAULT 1.20,
    epc_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    epc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epc_criado_por INT,
    epc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epc_modificado_por INT,
    epc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_epc_etr_id FOREIGN KEY (epc_etr_id) REFERENCES escola_sabatina.trimestre(etr_id),
    CONSTRAINT chk_epc_soma CHECK (epc_peso_presenca + epc_peso_estudo + epc_peso_ofertas + epc_peso_visitantes = 1),
    CONSTRAINT chk_epc_limite CHECK (epc_limite_ofertas >= 1),
    CONSTRAINT chk_epc_end_date CHECK (epc_end_date IS NULL OR epc_end_date >= epc_criado_em)
);
COMMENT ON TABLE escola_sabatina.pontuacao_config IS 'Pesos da pontuação (sem trimestre = pesos por defeito)';
CREATE INDEX idx_epc_etr_id ON escola_sabatina.pontuacao_config (epc_etr_id);
CREATE UNIQUE INDEX uq_epc_trimestre ON escola_sabatina.pontuacao_config (epc_etr_id) WHERE epc_etr_id IS NOT NULL AND epc_end_date IS NULL;
CREATE UNIQUE INDEX uq_epc_defeito ON escola_sabatina.pontuacao_config ((TRUE)) WHERE epc_etr_id IS NULL AND epc_end_date IS NULL;

-- Regras da Escola Sabatina ---------------------------------------------

-- Copia a igreja da classe (usada pela segurança e pelos índices)
CREATE FUNCTION escola_sabatina.fn_ect_igreja() RETURNS trigger AS $$
BEGIN
    SELECT ecl_igr_id INTO NEW.ect_igr_id FROM escola_sabatina.classe WHERE ecl_id = NEW.ect_ecl_id;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ect_05_igreja
    BEFORE INSERT OR UPDATE OF ect_ecl_id ON escola_sabatina.classe_trimestre
    FOR EACH ROW EXECUTE FUNCTION escola_sabatina.fn_ect_igreja();

-- Relatório do sábado:
--  * o sábado tem de ser do trimestre da classe
--  * M.M. vazio -> calculado pelas matrículas activas nessa data
--  * só fecha com as ofertas lançadas e confirmadas na tesouraria, cada uma no seu fundo
--    (missões, 13º sábado e despesas sempre separadas, como pede o Manual da Igreja)
--  * relatório fechado não muda de números
CREATE FUNCTION escola_sabatina.fn_ers_validar() RETURNS trigger AS $$
DECLARE
    v_data DATE;
    v_ecl  INT;
    v_tra  RECORD;
    f      RECORD;
BEGIN
    SELECT s.esa_data, ct.ect_ecl_id, ct.ect_igr_id INTO v_data, v_ecl, NEW.ers_igr_id
    FROM escola_sabatina.classe_trimestre ct
    JOIN escola_sabatina.sabado s ON s.esa_etr_id = ct.ect_etr_id
    WHERE ct.ect_id = NEW.ers_ect_id AND s.esa_id = NEW.ers_esa_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O sábado % não pertence ao trimestre desta classe', NEW.ers_esa_id;
    END IF;

    IF NEW.ers_membros_matriculados IS NULL THEN
        SELECT count(*) INTO NEW.ers_membros_matriculados
        FROM escola_sabatina.matricula
        WHERE ema_ecl_id = v_ecl AND ema_end_date IS NULL
          AND ema_data_entrada <= v_data AND (ema_data_saida IS NULL OR ema_data_saida > v_data);
    END IF;

    IF NEW.ers_estado = 'FECHADO' AND (TG_OP = 'INSERT' OR OLD.ers_estado <> 'FECHADO') THEN
        PERFORM nucleo.fn_exigir('escola_sabatina.relatorio_sabado.fechar', NEW.ers_igr_id);
    ELSIF TG_OP = 'UPDATE' AND OLD.ers_estado = 'FECHADO' AND NEW.ers_estado <> 'FECHADO' THEN
        PERFORM nucleo.fn_exigir('escola_sabatina.relatorio_sabado.reabrir', NEW.ers_igr_id);
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.ers_estado = 'FECHADO' AND NEW.ers_estado = 'FECHADO'
       AND (OLD.ers_membros_matriculados, OLD.ers_membros_presentes, OLD.ers_estudo_diario, OLD.ers_visitantes,
            OLD.ers_filiais, OLD.ers_oferta, OLD.ers_oferta_13_sabado, OLD.ers_oferta_despesas, OLD.ers_tra_id)
           IS DISTINCT FROM
           (NEW.ers_membros_matriculados, NEW.ers_membros_presentes, NEW.ers_estudo_diario, NEW.ers_visitantes,
            NEW.ers_filiais, NEW.ers_oferta, NEW.ers_oferta_13_sabado, NEW.ers_oferta_despesas, NEW.ers_tra_id) THEN
        RAISE EXCEPTION 'O relatório % está fechado; reabra-o (estado ABERTO) para corrigir', OLD.ers_id;
    END IF;

    IF NEW.ers_estado = 'FECHADO' AND NEW.ers_oferta + NEW.ers_oferta_13_sabado + NEW.ers_oferta_despesas > 0 THEN
        SELECT tra_estado INTO v_tra FROM tesouraria.transacao WHERE tra_id = NEW.ers_tra_id;
        IF NOT FOUND OR v_tra.tra_estado <> 'CONFIRMADA' THEN
            RAISE EXCEPTION 'O relatório só fecha depois de as ofertas estarem lançadas e confirmadas na tesouraria';
        END IF;
        SELECT COALESCE(SUM(l.tli_valor) FILTER (WHERE fu.fun_tipo = 'ES_MISSOES'), 0)   AS missoes,
               COALESCE(SUM(l.tli_valor) FILTER (WHERE fu.fun_tipo = 'ES_13_SABADO'), 0) AS treze,
               COALESCE(SUM(l.tli_valor) FILTER (WHERE fu.fun_tipo = 'ES_DESPESAS'), 0)  AS despesas
          INTO f
          FROM tesouraria.transacao_linha l JOIN tesouraria.fundo fu ON fu.fun_id = l.tli_fun_id
         WHERE l.tli_tra_id = NEW.ers_tra_id AND l.tli_end_date IS NULL;
        IF (f.missoes, f.treze, f.despesas) IS DISTINCT FROM (NEW.ers_oferta, NEW.ers_oferta_13_sabado, NEW.ers_oferta_despesas) THEN
            RAISE EXCEPTION 'Ofertas do relatório (missões %, 13º %, despesas %) diferentes do lançado na tesouraria (missões %, 13º %, despesas %)',
                NEW.ers_oferta, NEW.ers_oferta_13_sabado, NEW.ers_oferta_despesas, f.missoes, f.treze, f.despesas;
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ers_10_validar
    BEFORE INSERT OR UPDATE ON escola_sabatina.relatorio_sabado
    FOR EACH ROW EXECUTE FUNCTION escola_sabatina.fn_ers_validar();

-- Chamada nominal: copia a igreja e recalcula M.P. e E.D. do relatório
CREATE FUNCTION escola_sabatina.fn_epr_igreja() RETURNS trigger AS $$
BEGIN
    SELECT ers_igr_id INTO NEW.epr_igr_id FROM escola_sabatina.relatorio_sabado WHERE ers_id = NEW.epr_ers_id;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_epr_05_igreja
    BEFORE INSERT OR UPDATE OF epr_ers_id ON escola_sabatina.presenca
    FOR EACH ROW EXECUTE FUNCTION escola_sabatina.fn_epr_igreja();

-- Uma vez por comando (não por linha): uma chamada de 40 pessoas actualiza o relatório uma só vez
CREATE FUNCTION escola_sabatina.fn_epr_sincronizar_lote() RETURNS trigger AS $$
BEGIN
    UPDATE escola_sabatina.relatorio_sabado r
       SET ers_membros_presentes = c.presentes,
           ers_estudo_diario     = c.estudaram
      FROM (SELECT p.epr_ers_id,
                   count(*) FILTER (WHERE p.epr_presente)      AS presentes,
                   count(*) FILTER (WHERE p.epr_estudou_licao) AS estudaram
              FROM escola_sabatina.presenca p
             WHERE p.epr_end_date IS NULL
               AND p.epr_ers_id IN (SELECT DISTINCT epr_ers_id FROM novas)
             GROUP BY p.epr_ers_id) c
     WHERE r.ers_id = c.epr_ers_id;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_epr_20_sincronizar_ins
    AFTER INSERT ON escola_sabatina.presenca
    REFERENCING NEW TABLE AS novas
    FOR EACH STATEMENT EXECUTE FUNCTION escola_sabatina.fn_epr_sincronizar_lote();

CREATE TRIGGER trg_epr_20_sincronizar_upd
    AFTER UPDATE ON escola_sabatina.presenca
    REFERENCING NEW TABLE AS novas
    FOR EACH STATEMENT EXECUTE FUNCTION escola_sabatina.fn_epr_sincronizar_lote();


-- >>>>> V7__tesouraria.sql
-- =====================================================================
-- V7 · Módulo tesouraria: Tesouraria
-- Contas, fundos (da Associação e locais), movimentos divididos por fundo, despesas, contagens, recibos, remessas, orçamento, fecho mensal e saldos pré-calculados.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Contas onde o dinheiro está (M-Pesa, banco, caixa)
CREATE TABLE tesouraria.conta_financeira (
    cfi_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cfi_igr_id INT NOT NULL,
    cfi_tipo tipo_conta_t NOT NULL,
    cfi_nome VARCHAR(100) NOT NULL,
    cfi_numero VARCHAR(50),
    cfi_titular VARCHAR(150),
    cfi_banco VARCHAR(100),
    cfi_moeda CHAR(3) NOT NULL DEFAULT 'MZN',
    cfi_saldo_inicial DECIMAL(14,2) NOT NULL DEFAULT 0,
    cfi_data_saldo_inicial DATE NOT NULL,
    cfi_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cfi_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cfi_criado_por INT,
    cfi_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cfi_modificado_por INT,
    cfi_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cfi_igr_id FOREIGN KEY (cfi_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_cfi_end_date CHECK (cfi_end_date IS NULL OR cfi_end_date >= cfi_criado_em)
);
COMMENT ON TABLE tesouraria.conta_financeira IS 'Contas onde o dinheiro está (M-Pesa, banco, caixa)';
COMMENT ON COLUMN tesouraria.conta_financeira.cfi_data_saldo_inicial IS 'Movimentos anteriores a esta data não entram no saldo';
CREATE UNIQUE INDEX uq_cfi_igr_id_nome ON tesouraria.conta_financeira (cfi_igr_id, cfi_nome) WHERE cfi_end_date IS NULL;

-- Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais
CREATE TABLE tesouraria.fundo (
    fun_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    fun_igr_id INT,
    fun_codigo VARCHAR(20) NOT NULL,
    fun_nome VARCHAR(100) NOT NULL,
    fun_tipo tipo_fundo_t NOT NULL,
    fun_restrito BOOLEAN NOT NULL DEFAULT FALSE,
    fun_percentagem_remessa DECIMAL(5,2) NOT NULL DEFAULT 0,
    fun_destino_ent_id INT,
    fun_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    fun_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fun_criado_por INT,
    fun_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fun_modificado_por INT,
    fun_end_date TIMESTAMPTZ,
    CONSTRAINT fk_fun_igr_id FOREIGN KEY (fun_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_fun_destino_ent_id FOREIGN KEY (fun_destino_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT chk_fun_remessa CHECK (fun_percentagem_remessa BETWEEN 0 AND 100 AND (fun_percentagem_remessa = 0 OR fun_destino_ent_id IS NOT NULL)),
    CONSTRAINT chk_fun_associacao CHECK (fun_tipo NOT IN ('DIZIMO', 'ES_MISSOES', 'ES_13_SABADO', 'OFERTA_MISSIONARIA') OR fun_percentagem_remessa = 100),
    CONSTRAINT chk_fun_local CHECK (fun_tipo NOT IN ('ES_DESPESAS', 'ORCAMENTO_LOCAL') OR fun_percentagem_remessa = 0),
    CONSTRAINT chk_fun_end_date CHECK (fun_end_date IS NULL OR fun_end_date >= fun_criado_em)
);
COMMENT ON TABLE tesouraria.fundo IS 'Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais';
COMMENT ON COLUMN tesouraria.fundo.fun_igr_id IS 'NULL = fundo geral';
COMMENT ON COLUMN tesouraria.fundo.fun_restrito IS 'Fundo local que só pode ser gasto no seu fim';
COMMENT ON COLUMN tesouraria.fundo.fun_percentagem_remessa IS '100 = fundo da Associação, a igreja não o pode usar';
CREATE UNIQUE INDEX uq_fun_codigo ON tesouraria.fundo (fun_codigo) WHERE fun_end_date IS NULL;
CREATE INDEX idx_fun_igr_id ON tesouraria.fundo (fun_igr_id);
CREATE INDEX idx_fun_destino_ent_id ON tesouraria.fundo (fun_destino_ent_id);

-- Calendário de ofertas especiais definido pela Divisão/União/Associação
CREATE TABLE tesouraria.calendario_oferta (
    cof_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cof_ent_id INT NOT NULL,
    cof_data DATE NOT NULL,
    cof_fun_id INT NOT NULL,
    cof_descricao VARCHAR(150) NOT NULL,
    cof_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cof_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cof_criado_por INT,
    cof_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cof_modificado_por INT,
    cof_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cof_ent_id FOREIGN KEY (cof_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT fk_cof_fun_id FOREIGN KEY (cof_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT chk_cof_end_date CHECK (cof_end_date IS NULL OR cof_end_date >= cof_criado_em)
);
COMMENT ON TABLE tesouraria.calendario_oferta IS 'Calendário de ofertas especiais definido pela Divisão/União/Associação';
CREATE UNIQUE INDEX uq_cof_ent_id_data_fun_id ON tesouraria.calendario_oferta (cof_ent_id, cof_data, cof_fun_id) WHERE cof_end_date IS NULL;
CREATE INDEX idx_cof_fun_id ON tesouraria.calendario_oferta (cof_fun_id);

-- Plano de contas: categorias de receita e despesa
CREATE TABLE tesouraria.categoria (
    cat_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cat_pai_cat_id INT,
    cat_codigo VARCHAR(20) NOT NULL,
    cat_nome VARCHAR(100) NOT NULL,
    cat_tipo tipo_categoria_t NOT NULL,
    cat_e_remessa BOOLEAN NOT NULL DEFAULT FALSE,
    cat_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cat_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cat_criado_por INT,
    cat_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cat_modificado_por INT,
    cat_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cat_pai_cat_id FOREIGN KEY (cat_pai_cat_id) REFERENCES tesouraria.categoria(cat_id),
    CONSTRAINT chk_cat_end_date CHECK (cat_end_date IS NULL OR cat_end_date >= cat_criado_em)
);
COMMENT ON TABLE tesouraria.categoria IS 'Plano de contas: categorias de receita e despesa';
COMMENT ON COLUMN tesouraria.categoria.cat_e_remessa IS 'Categoria usada para enviar fundos à Associação';
CREATE UNIQUE INDEX uq_cat_codigo ON tesouraria.categoria (cat_codigo) WHERE cat_end_date IS NULL;
CREATE INDEX idx_cat_pai_cat_id ON tesouraria.categoria (cat_pai_cat_id);

-- Alvos de arrecadação por fundo
CREATE TABLE tesouraria.alvo (
    alv_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    alv_igr_id INT NOT NULL,
    alv_fun_id INT NOT NULL,
    alv_descricao VARCHAR(255),
    alv_valor_alvo DECIMAL(14,2) NOT NULL,
    alv_data_inicio DATE NOT NULL,
    alv_data_fim DATE NOT NULL,
    alv_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    alv_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    alv_criado_por INT,
    alv_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    alv_modificado_por INT,
    alv_end_date TIMESTAMPTZ,
    CONSTRAINT fk_alv_igr_id FOREIGN KEY (alv_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_alv_fun_id FOREIGN KEY (alv_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT chk_alv CHECK (alv_valor_alvo > 0 AND alv_data_fim >= alv_data_inicio),
    CONSTRAINT chk_alv_end_date CHECK (alv_end_date IS NULL OR alv_end_date >= alv_criado_em)
);
COMMENT ON TABLE tesouraria.alvo IS 'Alvos de arrecadação por fundo';
CREATE INDEX idx_alv_igr_id ON tesouraria.alvo (alv_igr_id);
CREATE INDEX idx_alv_fun_id ON tesouraria.alvo (alv_fun_id);

-- Orçamento anual da igreja local (aprovado pela igreja)
CREATE TABLE tesouraria.orcamento (
    orc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    orc_igr_id INT NOT NULL,
    orc_ide_id INT,
    orc_ano SMALLINT NOT NULL,
    orc_vot_id INT,
    orc_observacoes VARCHAR(500),
    orc_estado estado_orcamento_t NOT NULL DEFAULT 'RASCUNHO',
    orc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    orc_criado_por INT,
    orc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    orc_modificado_por INT,
    orc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_orc_igr_id FOREIGN KEY (orc_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_orc_ide_id FOREIGN KEY (orc_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_orc_vot_id FOREIGN KEY (orc_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_orc_aprovado CHECK (orc_estado = 'RASCUNHO' OR orc_vot_id IS NOT NULL),
    CONSTRAINT chk_orc_end_date CHECK (orc_end_date IS NULL OR orc_end_date >= orc_criado_em)
);
COMMENT ON TABLE tesouraria.orcamento IS 'Orçamento anual da igreja local (aprovado pela igreja)';
COMMENT ON COLUMN tesouraria.orcamento.orc_vot_id IS 'Voto da igreja que aprovou o orçamento';
CREATE INDEX idx_orc_igr_id ON tesouraria.orcamento (orc_igr_id);
CREATE INDEX idx_orc_ide_id ON tesouraria.orcamento (orc_ide_id);
CREATE INDEX idx_orc_vot_id ON tesouraria.orcamento (orc_vot_id);
CREATE UNIQUE INDEX uq_orc ON tesouraria.orcamento (orc_igr_id, COALESCE(orc_ide_id, 0), orc_ano) WHERE orc_end_date IS NULL;

-- Valor previsto por categoria
CREATE TABLE tesouraria.orcamento_linha (
    orl_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    orl_orc_id INT NOT NULL,
    orl_cat_id INT NOT NULL,
    orl_valor_previsto DECIMAL(14,2) NOT NULL,
    orl_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    orl_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    orl_criado_por INT,
    orl_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    orl_modificado_por INT,
    orl_end_date TIMESTAMPTZ,
    CONSTRAINT fk_orl_orc_id FOREIGN KEY (orl_orc_id) REFERENCES tesouraria.orcamento(orc_id),
    CONSTRAINT fk_orl_cat_id FOREIGN KEY (orl_cat_id) REFERENCES tesouraria.categoria(cat_id),
    CONSTRAINT chk_orl_valor CHECK (orl_valor_previsto >= 0),
    CONSTRAINT chk_orl_end_date CHECK (orl_end_date IS NULL OR orl_end_date >= orl_criado_em)
);
COMMENT ON TABLE tesouraria.orcamento_linha IS 'Valor previsto por categoria';
CREATE UNIQUE INDEX uq_orl_orc_id_cat_id ON tesouraria.orcamento_linha (orl_orc_id, orl_cat_id) WHERE orl_end_date IS NULL;
CREATE INDEX idx_orl_cat_id ON tesouraria.orcamento_linha (orl_cat_id);

-- Requisições de despesa (quem pede não aprova)
CREATE TABLE tesouraria.despesa (
    des_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    des_igr_id INT NOT NULL,
    des_ide_id INT,
    des_act_id INT,
    des_cat_id INT NOT NULL,
    des_fun_id INT NOT NULL,
    des_descricao VARCHAR(255) NOT NULL,
    des_fornecedor VARCHAR(150),
    des_valor_solicitado DECIMAL(14,2) NOT NULL,
    des_valor_aprovado DECIMAL(14,2),
    des_solicitado_por_usu_id INT NOT NULL,
    des_aprovado_por_usu_id INT,
    des_vot_id INT,
    des_aprovado_em TIMESTAMPTZ,
    des_motivo_rejeicao VARCHAR(255),
    des_estado estado_despesa_t NOT NULL DEFAULT 'SUBMETIDA',
    des_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    des_criado_por INT,
    des_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    des_modificado_por INT,
    des_end_date TIMESTAMPTZ,
    CONSTRAINT fk_des_igr_id FOREIGN KEY (des_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_des_ide_id FOREIGN KEY (des_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_des_act_id FOREIGN KEY (des_act_id) REFERENCES actividades.actividade(act_id),
    CONSTRAINT fk_des_cat_id FOREIGN KEY (des_cat_id) REFERENCES tesouraria.categoria(cat_id),
    CONSTRAINT fk_des_fun_id FOREIGN KEY (des_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT fk_des_solicitado_por_usu_id FOREIGN KEY (des_solicitado_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT fk_des_aprovado_por_usu_id FOREIGN KEY (des_aprovado_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT fk_des_vot_id FOREIGN KEY (des_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_des_valores CHECK (des_valor_solicitado > 0 AND (des_valor_aprovado IS NULL OR des_valor_aprovado > 0)),
    CONSTRAINT chk_des_quem_pede_nao_aprova CHECK (des_aprovado_por_usu_id IS NULL OR des_aprovado_por_usu_id <> des_solicitado_por_usu_id),
    CONSTRAINT chk_des_aprovacao CHECK (des_estado NOT IN ('APROVADA', 'PAGA') OR (des_aprovado_por_usu_id IS NOT NULL AND des_valor_aprovado IS NOT NULL)),
    CONSTRAINT chk_des_rejeicao CHECK (des_estado <> 'REJEITADA' OR des_motivo_rejeicao IS NOT NULL),
    CONSTRAINT chk_des_end_date CHECK (des_end_date IS NULL OR des_end_date >= des_criado_em)
);
COMMENT ON TABLE tesouraria.despesa IS 'Requisições de despesa (quem pede não aprova)';
COMMENT ON COLUMN tesouraria.despesa.des_vot_id IS 'Voto da junta, quando o valor o exige';
CREATE INDEX idx_des_igr_id ON tesouraria.despesa (des_igr_id);
CREATE INDEX idx_des_ide_id ON tesouraria.despesa (des_ide_id);
CREATE INDEX idx_des_act_id ON tesouraria.despesa (des_act_id);
CREATE INDEX idx_des_cat_id ON tesouraria.despesa (des_cat_id);
CREATE INDEX idx_des_fun_id ON tesouraria.despesa (des_fun_id);
CREATE INDEX idx_des_solicitado_por_usu_id ON tesouraria.despesa (des_solicitado_por_usu_id);
CREATE INDEX idx_des_aprovado_por_usu_id ON tesouraria.despesa (des_aprovado_por_usu_id);
CREATE INDEX idx_des_vot_id ON tesouraria.despesa (des_vot_id);

-- Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)
CREATE TABLE tesouraria.contagem_numerario (
    cnu_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cnu_igr_id INT NOT NULL,
    cnu_cfi_id INT NOT NULL,
    cnu_data DATE NOT NULL,
    cnu_ocasiao VARCHAR(100) NOT NULL DEFAULT 'Culto de sábado',
    cnu_contador1_mem_id INT NOT NULL,
    cnu_contador2_mem_id INT NOT NULL,
    cnu_total_contado DECIMAL(14,2) NOT NULL,
    cnu_conferido_por_usu_id INT,
    cnu_estado estado_contagem_t NOT NULL DEFAULT 'ABERTA',
    cnu_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cnu_criado_por INT,
    cnu_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cnu_modificado_por INT,
    cnu_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cnu_igr_id FOREIGN KEY (cnu_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_cnu_cfi_id FOREIGN KEY (cnu_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT fk_cnu_contador1_mem_id FOREIGN KEY (cnu_contador1_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_cnu_contador2_mem_id FOREIGN KEY (cnu_contador2_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_cnu_conferido_por_usu_id FOREIGN KEY (cnu_conferido_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_cnu_contadores_diferentes CHECK (cnu_contador1_mem_id <> cnu_contador2_mem_id),
    CONSTRAINT chk_cnu_total CHECK (cnu_total_contado >= 0),
    CONSTRAINT chk_cnu_end_date CHECK (cnu_end_date IS NULL OR cnu_end_date >= cnu_criado_em)
);
COMMENT ON TABLE tesouraria.contagem_numerario IS 'Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)';
CREATE INDEX idx_cnu_igr_id ON tesouraria.contagem_numerario (cnu_igr_id);
CREATE INDEX idx_cnu_cfi_id ON tesouraria.contagem_numerario (cnu_cfi_id);
CREATE INDEX idx_cnu_contador1_mem_id ON tesouraria.contagem_numerario (cnu_contador1_mem_id);
CREATE INDEX idx_cnu_contador2_mem_id ON tesouraria.contagem_numerario (cnu_contador2_mem_id);
CREATE INDEX idx_cnu_conferido_por_usu_id ON tesouraria.contagem_numerario (cnu_conferido_por_usu_id);

-- Movimentos: entradas, saídas e transferências (cabeçalho)
CREATE TABLE tesouraria.transacao (
    tra_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tra_igr_id INT NOT NULL,
    tra_tipo tipo_transacao_t NOT NULL,
    tra_metodo metodo_pagamento_t NOT NULL,
    tra_valor_total DECIMAL(14,2) NOT NULL,
    tra_cfi_id INT NOT NULL,
    tra_destino_cfi_id INT,
    tra_mem_id INT,
    tra_fam_id INT,
    tra_anonimo BOOLEAN NOT NULL DEFAULT FALSE,
    tra_cnu_id INT,
    tra_des_id INT,
    tra_estorno_tra_id BIGINT,
    tra_beneficiario VARCHAR(150),
    tra_descricao VARCHAR(255),
    tra_referencia VARCHAR(100),
    tra_data_hora TIMESTAMPTZ NOT NULL DEFAULT now(),
    tra_aprovado_por_usu_id INT,
    tra_estado estado_transacao_t NOT NULL DEFAULT 'PENDENTE',
    tra_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tra_criado_por INT,
    tra_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tra_modificado_por INT,
    tra_end_date TIMESTAMPTZ,
    CONSTRAINT fk_tra_igr_id FOREIGN KEY (tra_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_tra_cfi_id FOREIGN KEY (tra_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT fk_tra_destino_cfi_id FOREIGN KEY (tra_destino_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT fk_tra_mem_id FOREIGN KEY (tra_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_tra_fam_id FOREIGN KEY (tra_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT fk_tra_cnu_id FOREIGN KEY (tra_cnu_id) REFERENCES tesouraria.contagem_numerario(cnu_id),
    CONSTRAINT fk_tra_des_id FOREIGN KEY (tra_des_id) REFERENCES tesouraria.despesa(des_id),
    CONSTRAINT fk_tra_estorno_tra_id FOREIGN KEY (tra_estorno_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT fk_tra_aprovado_por_usu_id FOREIGN KEY (tra_aprovado_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_tra_valor CHECK (tra_valor_total > 0),
    CONSTRAINT chk_tra_anonimo CHECK (NOT (tra_anonimo AND (tra_mem_id IS NOT NULL OR tra_fam_id IS NOT NULL))),
    CONSTRAINT chk_tra_transferencia CHECK ((tra_tipo = 'TRANSFERENCIA') = (tra_destino_cfi_id IS NOT NULL) AND (tra_destino_cfi_id IS NULL OR tra_destino_cfi_id <> tra_cfi_id)),
    CONSTRAINT chk_tra_quem_regista_nao_aprova CHECK (tra_aprovado_por_usu_id IS NULL OR tra_criado_por IS NULL OR tra_aprovado_por_usu_id <> tra_criado_por),
    CONSTRAINT chk_tra_despesa CHECK (tra_des_id IS NULL OR tra_tipo = 'SAIDA'),
    CONSTRAINT chk_tra_contagem CHECK (tra_cnu_id IS NULL OR (tra_tipo = 'ENTRADA' AND tra_metodo = 'NUMERARIO')),
    CONSTRAINT chk_tra_end_date CHECK (tra_end_date IS NULL OR tra_end_date >= tra_criado_em)
);
COMMENT ON TABLE tesouraria.transacao IS 'Movimentos: entradas, saídas e transferências (cabeçalho)';
COMMENT ON COLUMN tesouraria.transacao.tra_igr_id IS 'Preenchido automaticamente a partir da conta';
COMMENT ON COLUMN tesouraria.transacao.tra_destino_cfi_id IS 'Só transferências';
COMMENT ON COLUMN tesouraria.transacao.tra_mem_id IS 'Quem entregou';
COMMENT ON COLUMN tesouraria.transacao.tra_fam_id IS 'Entrega em nome da família';
CREATE INDEX idx_tra_igr_id ON tesouraria.transacao (tra_igr_id);
CREATE INDEX idx_tra_cfi_id ON tesouraria.transacao (tra_cfi_id);
CREATE INDEX idx_tra_destino_cfi_id ON tesouraria.transacao (tra_destino_cfi_id);
CREATE INDEX idx_tra_mem_id ON tesouraria.transacao (tra_mem_id);
CREATE INDEX idx_tra_fam_id ON tesouraria.transacao (tra_fam_id);
CREATE INDEX idx_tra_cnu_id ON tesouraria.transacao (tra_cnu_id);
CREATE INDEX idx_tra_des_id ON tesouraria.transacao (tra_des_id);
CREATE INDEX idx_tra_estorno_tra_id ON tesouraria.transacao (tra_estorno_tra_id);
CREATE INDEX idx_tra_aprovado_por_usu_id ON tesouraria.transacao (tra_aprovado_por_usu_id);
CREATE INDEX idx_tra_igr_data ON tesouraria.transacao (tra_igr_id, tra_data_hora DESC);
CREATE INDEX idx_tra_pendentes ON tesouraria.transacao (tra_igr_id) WHERE tra_estado = 'PENDENTE' AND tra_end_date IS NULL;

-- chaves estrangeiras que esperavam por tesouraria.transacao
ALTER TABLE escola_sabatina.relatorio_sabado ADD CONSTRAINT fk_ers_tra_id FOREIGN KEY (ers_tra_id) REFERENCES tesouraria.transacao(tra_id);

-- Divisão do valor por fundo e categoria (soma = valor_total)
CREATE TABLE tesouraria.transacao_linha (
    tli_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tli_tra_id BIGINT NOT NULL,
    tli_igr_id INT NOT NULL,
    tli_fun_id INT NOT NULL,
    tli_cat_id INT NOT NULL,
    tli_ide_id INT,
    tli_act_id INT,
    tli_valor DECIMAL(14,2) NOT NULL,
    tli_descricao VARCHAR(255),
    tli_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    tli_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tli_criado_por INT,
    tli_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tli_modificado_por INT,
    tli_end_date TIMESTAMPTZ,
    CONSTRAINT fk_tli_tra_id FOREIGN KEY (tli_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT fk_tli_igr_id FOREIGN KEY (tli_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_tli_fun_id FOREIGN KEY (tli_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT fk_tli_cat_id FOREIGN KEY (tli_cat_id) REFERENCES tesouraria.categoria(cat_id),
    CONSTRAINT fk_tli_ide_id FOREIGN KEY (tli_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_tli_act_id FOREIGN KEY (tli_act_id) REFERENCES actividades.actividade(act_id),
    CONSTRAINT chk_tli_valor CHECK (tli_valor > 0),
    CONSTRAINT chk_tli_end_date CHECK (tli_end_date IS NULL OR tli_end_date >= tli_criado_em)
);
COMMENT ON TABLE tesouraria.transacao_linha IS 'Divisão do valor por fundo e categoria (soma = valor_total)';
COMMENT ON COLUMN tesouraria.transacao_linha.tli_igr_id IS 'Copiado da transacção (segurança e desempenho)';
CREATE INDEX idx_tli_tra_id ON tesouraria.transacao_linha (tli_tra_id);
CREATE INDEX idx_tli_igr_id ON tesouraria.transacao_linha (tli_igr_id);
CREATE INDEX idx_tli_fun_id ON tesouraria.transacao_linha (tli_fun_id);
CREATE INDEX idx_tli_cat_id ON tesouraria.transacao_linha (tli_cat_id);
CREATE INDEX idx_tli_ide_id ON tesouraria.transacao_linha (tli_ide_id);
CREATE INDEX idx_tli_act_id ON tesouraria.transacao_linha (tli_act_id);
CREATE INDEX idx_tli_igr_fun ON tesouraria.transacao_linha (tli_igr_id, tli_fun_id);

-- Saldo pré-calculado por conta e dia (mantido por triggers; não editar)
CREATE TABLE tesouraria.saldo_diario_conta (
    sdc_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    sdc_cfi_id INT NOT NULL,
    sdc_igr_id INT NOT NULL,
    sdc_data DATE NOT NULL,
    sdc_entradas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdc_saidas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdc_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    sdc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sdc_criado_por INT,
    sdc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sdc_modificado_por INT,
    sdc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_sdc_cfi_id FOREIGN KEY (sdc_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT fk_sdc_igr_id FOREIGN KEY (sdc_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_sdc_end_date CHECK (sdc_end_date IS NULL OR sdc_end_date >= sdc_criado_em)
);
COMMENT ON TABLE tesouraria.saldo_diario_conta IS 'Saldo pré-calculado por conta e dia (mantido por triggers; não editar)';
CREATE UNIQUE INDEX uq_sdc_cfi_id_data ON tesouraria.saldo_diario_conta (sdc_cfi_id, sdc_data) WHERE sdc_end_date IS NULL;
CREATE INDEX idx_sdc_igr_id ON tesouraria.saldo_diario_conta (sdc_igr_id);

-- Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar)
CREATE TABLE tesouraria.saldo_diario_fundo (
    sdf_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    sdf_igr_id INT NOT NULL,
    sdf_fun_id INT NOT NULL,
    sdf_moeda CHAR(3) NOT NULL,
    sdf_data DATE NOT NULL,
    sdf_entradas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdf_saidas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdf_estornos_entradas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdf_estornos_saidas DECIMAL(16,2) NOT NULL DEFAULT 0,
    sdf_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    sdf_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sdf_criado_por INT,
    sdf_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sdf_modificado_por INT,
    sdf_end_date TIMESTAMPTZ,
    CONSTRAINT fk_sdf_igr_id FOREIGN KEY (sdf_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_sdf_fun_id FOREIGN KEY (sdf_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT chk_sdf_end_date CHECK (sdf_end_date IS NULL OR sdf_end_date >= sdf_criado_em)
);
COMMENT ON TABLE tesouraria.saldo_diario_fundo IS 'Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar)';
COMMENT ON COLUMN tesouraria.saldo_diario_fundo.sdf_entradas IS 'Entradas que não são estornos';
COMMENT ON COLUMN tesouraria.saldo_diario_fundo.sdf_saidas IS 'Saídas que não são estornos';
COMMENT ON COLUMN tesouraria.saldo_diario_fundo.sdf_estornos_entradas IS 'Saídas que estornam entradas';
COMMENT ON COLUMN tesouraria.saldo_diario_fundo.sdf_estornos_saidas IS 'Entradas que estornam saídas';
CREATE UNIQUE INDEX uq_sdf_igr_id_fun_id_moeda_data ON tesouraria.saldo_diario_fundo (sdf_igr_id, sdf_fun_id, sdf_moeda, sdf_data) WHERE sdf_end_date IS NULL;
CREATE INDEX idx_sdf_fun_id ON tesouraria.saldo_diario_fundo (sdf_fun_id);

-- Recibos numerados por igreja e ano
CREATE TABLE tesouraria.recibo (
    rec_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rec_tra_id BIGINT NOT NULL,
    rec_igr_id INT NOT NULL,
    rec_ano SMALLINT NOT NULL,
    rec_numero INT NOT NULL,
    rec_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rec_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rec_criado_por INT,
    rec_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rec_modificado_por INT,
    rec_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rec_tra_id FOREIGN KEY (rec_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT fk_rec_igr_id FOREIGN KEY (rec_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_rec_end_date CHECK (rec_end_date IS NULL OR rec_end_date >= rec_criado_em)
);
COMMENT ON TABLE tesouraria.recibo IS 'Recibos numerados por igreja e ano';
CREATE UNIQUE INDEX uq_rec_tra_id ON tesouraria.recibo (rec_tra_id) WHERE rec_end_date IS NULL;
CREATE UNIQUE INDEX uq_rec_igr_id_ano_numero ON tesouraria.recibo (rec_igr_id, rec_ano, rec_numero) WHERE rec_end_date IS NULL;

-- Comprovativos (facturas, talões, prints M-Pesa)
CREATE TABLE tesouraria.documento (
    doc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    doc_tra_id BIGINT,
    doc_des_id INT,
    doc_tipo tipo_documento_t NOT NULL,
    doc_nome_ficheiro VARCHAR(255) NOT NULL,
    doc_url VARCHAR(500) NOT NULL,
    doc_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    doc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    doc_criado_por INT,
    doc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    doc_modificado_por INT,
    doc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_doc_tra_id FOREIGN KEY (doc_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT fk_doc_des_id FOREIGN KEY (doc_des_id) REFERENCES tesouraria.despesa(des_id),
    CONSTRAINT chk_doc_dono CHECK (doc_tra_id IS NOT NULL OR doc_des_id IS NOT NULL),
    CONSTRAINT chk_doc_end_date CHECK (doc_end_date IS NULL OR doc_end_date >= doc_criado_em)
);
COMMENT ON TABLE tesouraria.documento IS 'Comprovativos (facturas, talões, prints M-Pesa)';
CREATE INDEX idx_doc_tra_id ON tesouraria.documento (doc_tra_id);
CREATE INDEX idx_doc_des_id ON tesouraria.documento (doc_des_id);

-- Remessas mensais à Associação/Missão
CREATE TABLE tesouraria.remessa (
    rem_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rem_igr_id INT NOT NULL,
    rem_ent_id INT NOT NULL,
    rem_ano SMALLINT NOT NULL,
    rem_mes SMALLINT NOT NULL,
    rem_tra_id BIGINT,
    rem_enviada_em DATE,
    rem_estado estado_remessa_t NOT NULL DEFAULT 'PREPARADA',
    rem_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rem_criado_por INT,
    rem_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rem_modificado_por INT,
    rem_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rem_igr_id FOREIGN KEY (rem_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_rem_ent_id FOREIGN KEY (rem_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT fk_rem_tra_id FOREIGN KEY (rem_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT chk_rem_mes CHECK (rem_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_rem_end_date CHECK (rem_end_date IS NULL OR rem_end_date >= rem_criado_em)
);
COMMENT ON TABLE tesouraria.remessa IS 'Remessas mensais à Associação/Missão';
CREATE UNIQUE INDEX uq_rem_igr_id_ent_id_ano_mes ON tesouraria.remessa (rem_igr_id, rem_ent_id, rem_ano, rem_mes) WHERE rem_end_date IS NULL;
CREATE INDEX idx_rem_ent_id ON tesouraria.remessa (rem_ent_id);
CREATE INDEX idx_rem_tra_id ON tesouraria.remessa (rem_tra_id);

-- Valor remetido por fundo
CREATE TABLE tesouraria.remessa_linha (
    rml_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rml_rem_id INT NOT NULL,
    rml_fun_id INT NOT NULL,
    rml_valor DECIMAL(14,2) NOT NULL,
    rml_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rml_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rml_criado_por INT,
    rml_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rml_modificado_por INT,
    rml_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rml_rem_id FOREIGN KEY (rml_rem_id) REFERENCES tesouraria.remessa(rem_id),
    CONSTRAINT fk_rml_fun_id FOREIGN KEY (rml_fun_id) REFERENCES tesouraria.fundo(fun_id),
    CONSTRAINT chk_rml_valor CHECK (rml_valor >= 0),
    CONSTRAINT chk_rml_end_date CHECK (rml_end_date IS NULL OR rml_end_date >= rml_criado_em)
);
COMMENT ON TABLE tesouraria.remessa_linha IS 'Valor remetido por fundo';
CREATE UNIQUE INDEX uq_rml_rem_id_fun_id ON tesouraria.remessa_linha (rml_rem_id, rml_fun_id) WHERE rml_end_date IS NULL;
CREATE INDEX idx_rml_fun_id ON tesouraria.remessa_linha (rml_fun_id);

-- Meses fechados: movimentos bloqueados (reabrir = preencher end_date)
CREATE TABLE tesouraria.fecho_periodo (
    fpe_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    fpe_igr_id INT NOT NULL,
    fpe_ano SMALLINT NOT NULL,
    fpe_mes SMALLINT NOT NULL,
    fpe_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    fpe_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fpe_criado_por INT,
    fpe_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fpe_modificado_por INT,
    fpe_end_date TIMESTAMPTZ,
    CONSTRAINT fk_fpe_igr_id FOREIGN KEY (fpe_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_fpe_mes CHECK (fpe_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_fpe_end_date CHECK (fpe_end_date IS NULL OR fpe_end_date >= fpe_criado_em)
);
COMMENT ON TABLE tesouraria.fecho_periodo IS 'Meses fechados: movimentos bloqueados (reabrir = preencher end_date)';
CREATE UNIQUE INDEX uq_fpe_igr_id_ano_mes ON tesouraria.fecho_periodo (fpe_igr_id, fpe_ano, fpe_mes) WHERE fpe_end_date IS NULL;

-- Linhas do extracto bancário/M-Pesa para reconciliação
CREATE TABLE tesouraria.extrato_linha (
    ext_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ext_cfi_id INT NOT NULL,
    ext_data DATE NOT NULL,
    ext_descricao VARCHAR(255),
    ext_referencia VARCHAR(100),
    ext_valor DECIMAL(14,2) NOT NULL,
    ext_tra_id BIGINT,
    ext_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ext_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ext_criado_por INT,
    ext_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ext_modificado_por INT,
    ext_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ext_cfi_id FOREIGN KEY (ext_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT fk_ext_tra_id FOREIGN KEY (ext_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT chk_ext_end_date CHECK (ext_end_date IS NULL OR ext_end_date >= ext_criado_em)
);
COMMENT ON TABLE tesouraria.extrato_linha IS 'Linhas do extracto bancário/M-Pesa para reconciliação';
CREATE UNIQUE INDEX uq_ext_cfi_id_data_referencia_valor ON tesouraria.extrato_linha (ext_cfi_id, ext_data, ext_referencia, ext_valor) WHERE ext_end_date IS NULL;
CREATE INDEX idx_ext_tra_id ON tesouraria.extrato_linha (ext_tra_id);

-- Regras da tesouraria ---------------------------------------------------

CREATE FUNCTION tesouraria.fn_periodo_fechado(p_igr INT, p_data TIMESTAMPTZ) RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM tesouraria.fecho_periodo
        WHERE fpe_igr_id = p_igr AND fpe_end_date IS NULL
          AND fpe_ano = EXTRACT(YEAR  FROM p_data AT TIME ZONE 'Africa/Maputo')
          AND fpe_mes = EXTRACT(MONTH FROM p_data AT TIME ZONE 'Africa/Maputo'));
$$ LANGUAGE sql STABLE;

-- Cabeçalho da transacção
CREATE FUNCTION tesouraria.fn_tra_validar() RETURNS trigger AS $$
DECLARE
    c_orig  tesouraria.conta_financeira%ROWTYPE;
    c_dest  tesouraria.conta_financeira%ROWTYPE;
    v_orig  tesouraria.transacao%ROWTYPE;
    v_des   tesouraria.despesa%ROWTYPE;
BEGIN
    SELECT * INTO c_orig FROM tesouraria.conta_financeira WHERE cfi_id = NEW.tra_cfi_id;
    NEW.tra_igr_id := c_orig.cfi_igr_id;

    IF NEW.tra_destino_cfi_id IS NOT NULL THEN
        SELECT * INTO c_dest FROM tesouraria.conta_financeira WHERE cfi_id = NEW.tra_destino_cfi_id;
        IF c_dest.cfi_moeda <> c_orig.cfi_moeda THEN
            RAISE EXCEPTION 'Transferência entre contas de moedas diferentes (% -> %)', c_orig.cfi_moeda, c_dest.cfi_moeda;
        END IF;
        IF c_dest.cfi_igr_id <> c_orig.cfi_igr_id THEN
            RAISE EXCEPTION 'Transferências só entre contas da mesma igreja';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND tesouraria.fn_periodo_fechado(OLD.tra_igr_id, OLD.tra_data_hora) THEN
        RAISE EXCEPTION 'O mês da transacção % já foi fechado', OLD.tra_id;
    END IF;
    IF tesouraria.fn_periodo_fechado(NEW.tra_igr_id, NEW.tra_data_hora) THEN
        RAISE EXCEPTION 'Não é possível registar movimentos num mês já fechado';
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.tra_estado = 'CONFIRMADA' AND
       (NEW.tra_estado, NEW.tra_tipo, NEW.tra_metodo, NEW.tra_valor_total, NEW.tra_cfi_id, NEW.tra_destino_cfi_id,
        NEW.tra_mem_id, NEW.tra_fam_id, NEW.tra_data_hora, NEW.tra_end_date)
       IS DISTINCT FROM
       (OLD.tra_estado, OLD.tra_tipo, OLD.tra_metodo, OLD.tra_valor_total, OLD.tra_cfi_id, OLD.tra_destino_cfi_id,
        OLD.tra_mem_id, OLD.tra_fam_id, OLD.tra_data_hora, OLD.tra_end_date) THEN
        RAISE EXCEPTION 'A transacção % está confirmada; para corrigir registe um estorno', OLD.tra_id;
    END IF;

    -- aprovar uma saída: só em nome próprio e com a permissão "aprovar"
    IF NEW.tra_aprovado_por_usu_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.tra_aprovado_por_usu_id IS DISTINCT FROM OLD.tra_aprovado_por_usu_id) THEN
        IF nucleo.fn_usuario_sessao() IS NOT NULL AND NEW.tra_aprovado_por_usu_id <> nucleo.fn_usuario_sessao() THEN
            RAISE EXCEPTION 'Só se aprova em nome próprio';
        END IF;
        PERFORM nucleo.fn_exigir('tesouraria.transacao.aprovar', NEW.tra_igr_id);
    END IF;

    IF NEW.tra_estorno_tra_id IS NOT NULL AND TG_OP = 'INSERT' THEN
        SELECT * INTO v_orig FROM tesouraria.transacao WHERE tra_id = NEW.tra_estorno_tra_id;
        IF v_orig.tra_estado <> 'CONFIRMADA'
           OR NOT ((v_orig.tra_tipo = 'ENTRADA' AND NEW.tra_tipo = 'SAIDA') OR (v_orig.tra_tipo = 'SAIDA' AND NEW.tra_tipo = 'ENTRADA'))
           OR NEW.tra_valor_total > v_orig.tra_valor_total THEN
            RAISE EXCEPTION 'Estorno inválido: tem de ser do tipo contrário a uma transacção confirmada e não pode exceder o valor original';
        END IF;
    END IF;

    IF NEW.tra_des_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.tra_des_id IS DISTINCT FROM NEW.tra_des_id OR OLD.tra_estado <> NEW.tra_estado) THEN
        SELECT * INTO v_des FROM tesouraria.despesa WHERE des_id = NEW.tra_des_id;
        IF v_des.des_estado NOT IN ('APROVADA', 'PAGA') THEN
            RAISE EXCEPTION 'A despesa % ainda não foi aprovada', NEW.tra_des_id;
        END IF;
        IF NEW.tra_valor_total > v_des.des_valor_aprovado THEN
            RAISE EXCEPTION 'Pagamento (% MT) acima do valor aprovado (% MT)', NEW.tra_valor_total, v_des.des_valor_aprovado;
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tra_10_validar
    BEFORE INSERT OR UPDATE ON tesouraria.transacao
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_validar();

-- Linha: copia a igreja; período fechado; transacção confirmada;
-- fundos da Associação (dízimo, missões, 13º sábado) não se gastam na igreja: só saem como remessa ou estorno
CREATE FUNCTION tesouraria.fn_tli_validar() RETURNS trigger AS $$
DECLARE
    r tesouraria.transacao%ROWTYPE;
    v_pct NUMERIC; v_fundo TEXT; v_remessa BOOLEAN;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = NEW.tli_tra_id;
    NEW.tli_igr_id := r.tra_igr_id;
    IF tesouraria.fn_periodo_fechado(r.tra_igr_id, r.tra_data_hora) THEN
        RAISE EXCEPTION 'O mês da transacção % já foi fechado', r.tra_id;
    END IF;
    IF TG_OP = 'UPDATE' AND r.tra_estado = 'CONFIRMADA' THEN
        RAISE EXCEPTION 'As linhas da transacção % confirmada não podem ser alteradas; registe um estorno', r.tra_id;
    END IF;
    IF r.tra_tipo = 'TRANSFERENCIA' THEN
        RAISE EXCEPTION 'Uma transferência entre contas não tem linhas de fundo';
    END IF;
    IF r.tra_tipo = 'SAIDA' AND r.tra_estorno_tra_id IS NULL THEN
        SELECT fun_percentagem_remessa, fun_nome INTO v_pct, v_fundo FROM tesouraria.fundo WHERE fun_id = NEW.tli_fun_id;
        SELECT cat_e_remessa INTO v_remessa FROM tesouraria.categoria WHERE cat_id = NEW.tli_cat_id;
        IF v_pct = 100 AND NOT v_remessa THEN
            RAISE EXCEPTION 'O fundo "%" pertence à Associação: só pode sair como remessa (categoria de remessa) ou estorno', v_fundo;
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tli_10_validar
    BEFORE INSERT OR UPDATE ON tesouraria.transacao_linha
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tli_validar();

-- Soma das linhas = total (verificado no COMMIT)
CREATE FUNCTION tesouraria.fn_tra_soma_linhas() RETURNS trigger AS $$
DECLARE
    v_id   BIGINT;
    r      tesouraria.transacao%ROWTYPE;
    v_soma NUMERIC;
BEGIN
    IF TG_TABLE_NAME = 'transacao' THEN v_id := NEW.tra_id; ELSE v_id := NEW.tli_tra_id; END IF;
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = v_id;
    IF NOT FOUND OR r.tra_tipo = 'TRANSFERENCIA' OR r.tra_end_date IS NOT NULL THEN
        RETURN NULL;
    END IF;
    SELECT COALESCE(sum(tli_valor), 0) INTO v_soma
    FROM tesouraria.transacao_linha WHERE tli_tra_id = v_id AND tli_end_date IS NULL;
    IF v_soma <> r.tra_valor_total THEN
        RAISE EXCEPTION 'Transacção %: a soma das linhas (%) é diferente do total (%)', v_id, v_soma, r.tra_valor_total;
    END IF;
    -- uma saída confirmada precisa de aprovação: despesa aprovada, aprovação de outra pessoa,
    -- ou ser só remessa à Associação (obrigação mensal)
    IF r.tra_tipo = 'SAIDA' AND r.tra_estado = 'CONFIRMADA' AND r.tra_des_id IS NULL AND r.tra_aprovado_por_usu_id IS NULL
       AND EXISTS (SELECT 1 FROM tesouraria.transacao_linha l JOIN tesouraria.categoria c ON c.cat_id = l.tli_cat_id
                   WHERE l.tli_tra_id = v_id AND l.tli_end_date IS NULL AND NOT c.cat_e_remessa) THEN
        RAISE EXCEPTION 'A saída % precisa de aprovação (despesa aprovada ou tesouraria.fn_aprovar_saida) antes de ser confirmada', v_id;
    END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_tra_90_soma
    AFTER INSERT OR UPDATE ON tesouraria.transacao
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_soma_linhas();

CREATE CONSTRAINT TRIGGER trg_tli_90_soma
    AFTER INSERT OR UPDATE ON tesouraria.transacao_linha
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_soma_linhas();

-- ---------------------------------------------------------------- saldos pré-calculados
-- Uma transacção confirmada nunca muda nem é terminada, por isso os saldos só somam.
-- Os saldos só são escritos por estas funções (SECURITY DEFINER); os utilizadores apenas os lêem.
CREATE FUNCTION tesouraria.fn_saldo_fundo_somar(t tesouraria.transacao, p_fun INT, p_valor NUMERIC) RETURNS VOID
SECURITY DEFINER AS $$
DECLARE
    v_data  DATE := (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::date;
    v_moeda CHAR(3);
    e NUMERIC := 0; s NUMERIC := 0; ee NUMERIC := 0; es NUMERIC := 0;
BEGIN
    SELECT cfi_moeda INTO v_moeda FROM tesouraria.conta_financeira WHERE cfi_id = t.tra_cfi_id;
    IF t.tra_tipo = 'ENTRADA' THEN
        IF t.tra_estorno_tra_id IS NULL THEN e := p_valor; ELSE es := p_valor; END IF;
    ELSE
        IF t.tra_estorno_tra_id IS NULL THEN s := p_valor; ELSE ee := p_valor; END IF;
    END IF;
    INSERT INTO tesouraria.saldo_diario_fundo AS x
           (sdf_igr_id, sdf_fun_id, sdf_moeda, sdf_data, sdf_entradas, sdf_saidas, sdf_estornos_entradas, sdf_estornos_saidas)
    VALUES (t.tra_igr_id, p_fun, v_moeda, v_data, e, s, ee, es)
    ON CONFLICT (sdf_igr_id, sdf_fun_id, sdf_moeda, sdf_data) WHERE sdf_end_date IS NULL
    DO UPDATE SET sdf_entradas          = x.sdf_entradas          + EXCLUDED.sdf_entradas,
                  sdf_saidas            = x.sdf_saidas            + EXCLUDED.sdf_saidas,
                  sdf_estornos_entradas = x.sdf_estornos_entradas + EXCLUDED.sdf_estornos_entradas,
                  sdf_estornos_saidas   = x.sdf_estornos_saidas   + EXCLUDED.sdf_estornos_saidas;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION tesouraria.fn_saldo_conta_somar(p_cfi INT, p_igr INT, p_data DATE, p_ent NUMERIC, p_sai NUMERIC) RETURNS VOID AS $$
    INSERT INTO tesouraria.saldo_diario_conta AS x (sdc_cfi_id, sdc_igr_id, sdc_data, sdc_entradas, sdc_saidas)
    VALUES (p_cfi, p_igr, p_data, p_ent, p_sai)
    ON CONFLICT (sdc_cfi_id, sdc_data) WHERE sdc_end_date IS NULL
    DO UPDATE SET sdc_entradas = x.sdc_entradas + EXCLUDED.sdc_entradas,
                  sdc_saidas   = x.sdc_saidas   + EXCLUDED.sdc_saidas;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE FUNCTION tesouraria.fn_tra_saldos() RETURNS trigger AS $$
DECLARE
    v_data DATE := (NEW.tra_data_hora AT TIME ZONE 'Africa/Maputo')::date;
    l RECORD;
BEGIN
    IF NEW.tra_estado <> 'CONFIRMADA' OR (TG_OP = 'UPDATE' AND OLD.tra_estado = 'CONFIRMADA') THEN
        RETURN NULL;
    END IF;
    IF NEW.tra_tipo = 'ENTRADA' THEN
        PERFORM tesouraria.fn_saldo_conta_somar(NEW.tra_cfi_id, NEW.tra_igr_id, v_data, NEW.tra_valor_total, 0);
    ELSE
        PERFORM tesouraria.fn_saldo_conta_somar(NEW.tra_cfi_id, NEW.tra_igr_id, v_data, 0, NEW.tra_valor_total);
        IF NEW.tra_tipo = 'TRANSFERENCIA' THEN
            PERFORM tesouraria.fn_saldo_conta_somar(NEW.tra_destino_cfi_id, NEW.tra_igr_id, v_data, NEW.tra_valor_total, 0);
        END IF;
    END IF;
    -- linhas que já existiam antes da confirmação
    FOR l IN SELECT tli_fun_id, tli_valor FROM tesouraria.transacao_linha
             WHERE tli_tra_id = NEW.tra_id AND tli_end_date IS NULL LOOP
        PERFORM tesouraria.fn_saldo_fundo_somar(NEW, l.tli_fun_id, l.tli_valor);
    END LOOP;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tra_30_saldos
    AFTER INSERT OR UPDATE OF tra_estado ON tesouraria.transacao
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_saldos();

CREATE FUNCTION tesouraria.fn_tli_saldos() RETURNS trigger AS $$
DECLARE r tesouraria.transacao;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = NEW.tli_tra_id;
    IF r.tra_estado = 'CONFIRMADA' THEN
        PERFORM tesouraria.fn_saldo_fundo_somar(r, NEW.tli_fun_id, NEW.tli_valor);
    END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tli_30_saldos
    AFTER INSERT ON tesouraria.transacao_linha
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tli_saldos();

-- Recalcula os saldos a partir dos movimentos (para auditoria ou depois de uma importação)
CREATE FUNCTION tesouraria.fn_recalcular_saldos(p_igr INT) RETURNS VOID AS $$
BEGIN
    PERFORM nucleo.fn_exigir('tesouraria.fecho_periodo.criar', p_igr);
    UPDATE tesouraria.saldo_diario_conta SET sdc_end_date = now() WHERE sdc_igr_id = p_igr AND sdc_end_date IS NULL;
    UPDATE tesouraria.saldo_diario_fundo SET sdf_end_date = now() WHERE sdf_igr_id = p_igr AND sdf_end_date IS NULL;
    INSERT INTO tesouraria.saldo_diario_conta (sdc_cfi_id, sdc_igr_id, sdc_data, sdc_entradas, sdc_saidas)
    SELECT cfi, p_igr, d, SUM(e), SUM(s) FROM (
        SELECT tra_cfi_id cfi, (tra_data_hora AT TIME ZONE 'Africa/Maputo')::date d,
               CASE WHEN tra_tipo = 'ENTRADA' THEN tra_valor_total ELSE 0 END e,
               CASE WHEN tra_tipo <> 'ENTRADA' THEN tra_valor_total ELSE 0 END s
        FROM tesouraria.transacao WHERE tra_igr_id = p_igr AND tra_estado = 'CONFIRMADA' AND tra_end_date IS NULL
        UNION ALL
        SELECT tra_destino_cfi_id, (tra_data_hora AT TIME ZONE 'Africa/Maputo')::date, tra_valor_total, 0
        FROM tesouraria.transacao WHERE tra_igr_id = p_igr AND tra_tipo = 'TRANSFERENCIA'
          AND tra_estado = 'CONFIRMADA' AND tra_end_date IS NULL) x
    GROUP BY cfi, d;
    INSERT INTO tesouraria.saldo_diario_fundo (sdf_igr_id, sdf_fun_id, sdf_moeda, sdf_data, sdf_entradas, sdf_saidas,
                                               sdf_estornos_entradas, sdf_estornos_saidas)
    SELECT p_igr, l.tli_fun_id, c.cfi_moeda, (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::date,
           COALESCE(SUM(l.tli_valor) FILTER (WHERE t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL), 0),
           COALESCE(SUM(l.tli_valor) FILTER (WHERE t.tra_tipo = 'SAIDA'   AND t.tra_estorno_tra_id IS NULL), 0),
           COALESCE(SUM(l.tli_valor) FILTER (WHERE t.tra_tipo = 'SAIDA'   AND t.tra_estorno_tra_id IS NOT NULL), 0),
           COALESCE(SUM(l.tli_valor) FILTER (WHERE t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NOT NULL), 0)
    FROM tesouraria.transacao_linha l
    JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id
    WHERE t.tra_igr_id = p_igr AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL AND l.tli_end_date IS NULL
    GROUP BY 1, 2, 3, 4;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

-- Despesa paga quando o pagamento é confirmado
CREATE FUNCTION tesouraria.fn_tra_despesa_paga() RETURNS trigger AS $$
BEGIN
    IF NEW.tra_des_id IS NOT NULL AND NEW.tra_estado = 'CONFIRMADA' THEN
        UPDATE tesouraria.despesa SET des_estado = 'PAGA'
         WHERE des_id = NEW.tra_des_id AND des_estado = 'APROVADA';
    END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tra_20_despesa_paga
    AFTER INSERT OR UPDATE OF tra_estado ON tesouraria.transacao
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_despesa_paga();

-- Próximo número de recibo (na mesma transacção SQL que insere o recibo)
CREATE FUNCTION tesouraria.fn_proximo_recibo(p_igr INT, p_ano INT) RETURNS INT AS $$
    SELECT COALESCE(max(rec_numero), 0) + 1 FROM tesouraria.recibo WHERE rec_igr_id = p_igr AND rec_ano = p_ano;
$$ LANGUAGE sql;

-- Fundos-padrão de uma Associação/Missão. A parte da oferta combinada que vai para a
-- Associação depende do plano de ofertas da sua União/Divisão: indique-a em p_pct_oferta_combinada.
CREATE FUNCTION tesouraria.fn_criar_fundos_padrao(p_ent INT, p_pct_oferta_combinada NUMERIC, p_sufixo TEXT DEFAULT '')
RETURNS VOID AS $$
    INSERT INTO tesouraria.fundo (fun_codigo, fun_nome, fun_tipo, fun_percentagem_remessa, fun_destino_ent_id) VALUES
      ('DIZ'   || p_sufixo, 'Dízimo',                                 'DIZIMO',             100, p_ent),
      ('ESM'   || p_sufixo, 'Escola Sabatina: ofertas missionárias',  'ES_MISSOES',         100, p_ent),
      ('ES13'  || p_sufixo, 'Escola Sabatina: 13º sábado',            'ES_13_SABADO',       100, p_ent),
      ('ESD'   || p_sufixo, 'Escola Sabatina: despesas locais',       'ES_DESPESAS',          0, NULL),
      ('OMIS'  || p_sufixo, 'Ofertas missionárias',                   'OFERTA_MISSIONARIA', 100, p_ent),
      ('OCOMB' || p_sufixo, 'Oferta combinada / plano de ofertas',    'OFERTA_COMBINADA',
               p_pct_oferta_combinada, CASE WHEN p_pct_oferta_combinada > 0 THEN p_ent END),
      ('OLOC'  || p_sufixo, 'Orçamento da igreja local',              'ORCAMENTO_LOCAL',      0, NULL);
$$ LANGUAGE sql;

-- ---------------------------------------------------------------- aprovações
-- Despesas, orçamentos e remessas: a mudança de estado exige a permissão própria
CREATE FUNCTION tesouraria.fn_des_aprovacao() RETURNS trigger AS $$
BEGIN
    IF NEW.des_estado IN ('APROVADA', 'REJEITADA') AND (TG_OP = 'INSERT' OR OLD.des_estado IS DISTINCT FROM NEW.des_estado) THEN
        PERFORM nucleo.fn_exigir('tesouraria.despesa.aprovar', NEW.des_igr_id);
        NEW.des_aprovado_por_usu_id := COALESCE(nucleo.fn_usuario_sessao(), NEW.des_aprovado_por_usu_id);
        NEW.des_aprovado_em := now();
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_des_10_aprovacao
    BEFORE INSERT OR UPDATE ON tesouraria.despesa
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_des_aprovacao();

CREATE FUNCTION tesouraria.fn_orc_aprovacao() RETURNS trigger AS $$
BEGIN
    IF NEW.orc_estado = 'APROVADO' AND (TG_OP = 'INSERT' OR OLD.orc_estado IS DISTINCT FROM NEW.orc_estado) THEN
        PERFORM nucleo.fn_exigir('tesouraria.orcamento.aprovar', NEW.orc_igr_id);
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orc_10_aprovacao
    BEFORE INSERT OR UPDATE ON tesouraria.orcamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_orc_aprovacao();

CREATE FUNCTION tesouraria.fn_rem_confirmacao() RETURNS trigger AS $$
BEGIN
    IF NEW.rem_estado = 'CONFIRMADA' AND (TG_OP = 'INSERT' OR OLD.rem_estado IS DISTINCT FROM NEW.rem_estado) THEN
        PERFORM nucleo.fn_exigir('tesouraria.remessa.confirmar', NEW.rem_igr_id);
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rem_10_confirmacao
    BEFORE INSERT OR UPDATE ON tesouraria.remessa
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_rem_confirmacao();

-- Funções de aprovação para a API: verificam a permissão de quem aprova e
-- registam-no, sem que essa pessoa precise de poder editar o resto do registo.
CREATE FUNCTION tesouraria.fn_aprovar_saida(p_tra BIGINT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE r tesouraria.transacao%ROWTYPE;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = p_tra AND tra_end_date IS NULL;
    IF NOT FOUND OR r.tra_tipo <> 'SAIDA' OR r.tra_estado <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Só se aprova uma saída pendente';
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.transacao.aprovar', r.tra_igr_id);
    UPDATE tesouraria.transacao SET tra_aprovado_por_usu_id = nucleo.fn_usuario_sessao() WHERE tra_id = p_tra;
END $$;

CREATE FUNCTION tesouraria.fn_decidir_despesa(p_des INT, p_aprovar BOOLEAN, p_valor NUMERIC DEFAULT NULL,
                                              p_motivo TEXT DEFAULT NULL) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE d tesouraria.despesa%ROWTYPE;
BEGIN
    SELECT * INTO d FROM tesouraria.despesa WHERE des_id = p_des AND des_end_date IS NULL;
    IF NOT FOUND OR d.des_estado <> 'SUBMETIDA' THEN RAISE EXCEPTION 'Só se decide uma despesa submetida'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.despesa.aprovar', d.des_igr_id);
    UPDATE tesouraria.despesa
       SET des_estado = CASE WHEN p_aprovar THEN 'APROVADA' ELSE 'REJEITADA' END::nucleo.estado_despesa_t,
           des_valor_aprovado = CASE WHEN p_aprovar THEN COALESCE(p_valor, d.des_valor_solicitado) END,
           des_motivo_rejeicao = CASE WHEN NOT p_aprovar THEN p_motivo END
     WHERE des_id = p_des;
END $$;

CREATE FUNCTION tesouraria.fn_aprovar_orcamento(p_orc INT, p_vot INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE o tesouraria.orcamento%ROWTYPE;
BEGIN
    SELECT * INTO o FROM tesouraria.orcamento WHERE orc_id = p_orc AND orc_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Orçamento inexistente'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.orcamento.aprovar', o.orc_igr_id);
    UPDATE tesouraria.orcamento SET orc_estado = 'APROVADO', orc_vot_id = p_vot WHERE orc_id = p_orc;
END $$;

CREATE FUNCTION tesouraria.fn_confirmar_remessa(p_rem INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE r tesouraria.remessa%ROWTYPE;
BEGIN
    SELECT * INTO r FROM tesouraria.remessa WHERE rem_id = p_rem AND rem_end_date IS NULL;
    IF NOT FOUND OR r.rem_estado <> 'ENVIADA' THEN RAISE EXCEPTION 'Só se confirma uma remessa enviada'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.remessa.confirmar', r.rem_igr_id);
    UPDATE tesouraria.remessa SET rem_estado = 'CONFIRMADA' WHERE rem_id = p_rem;
END $$;


-- >>>>> V8__pagamentos.sql
-- =====================================================================
-- V8 · Módulo pagamentos: Pagamentos electrónicos
-- Integração com M-Pesa e bancos.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Pedido e resposta da API M-Pesa
CREATE TABLE pagamentos.pagamento_mpesa (
    pmp_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pmp_tra_id BIGINT NOT NULL,
    pmp_direccao VARCHAR(3) NOT NULL DEFAULT 'C2B',
    pmp_msisdn VARCHAR(15) NOT NULL,
    pmp_valor DECIMAL(14,2) NOT NULL,
    pmp_taxa DECIMAL(12,2) NOT NULL DEFAULT 0,
    pmp_transaction_reference VARCHAR(50) NOT NULL,
    pmp_third_party_reference VARCHAR(50) NOT NULL,
    pmp_service_provider_code VARCHAR(20) NOT NULL,
    pmp_response_code VARCHAR(20),
    pmp_response_desc VARCHAR(255),
    pmp_mpesa_transaction_id VARCHAR(50),
    pmp_conversation_id VARCHAR(100),
    pmp_pedido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pmp_respondido_em TIMESTAMPTZ,
    pmp_ultima_consulta_em TIMESTAMPTZ,
    pmp_tentativas_consulta SMALLINT NOT NULL DEFAULT 0,
    pmp_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pmp_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pmp_criado_por INT,
    pmp_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pmp_modificado_por INT,
    pmp_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pmp_tra_id FOREIGN KEY (pmp_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT chk_pmp_direccao CHECK (pmp_direccao IN ('C2B', 'B2C')),
    CONSTRAINT chk_pmp_end_date CHECK (pmp_end_date IS NULL OR pmp_end_date >= pmp_criado_em)
);
COMMENT ON TABLE pagamentos.pagamento_mpesa IS 'Pedido e resposta da API M-Pesa';
CREATE UNIQUE INDEX uq_pmp_tra_id ON pagamentos.pagamento_mpesa (pmp_tra_id) WHERE pmp_end_date IS NULL;
CREATE UNIQUE INDEX uq_pmp_third_party_reference ON pagamentos.pagamento_mpesa (pmp_third_party_reference) WHERE pmp_end_date IS NULL;
CREATE UNIQUE INDEX uq_pmp_mpesa_transaction_id ON pagamentos.pagamento_mpesa (pmp_mpesa_transaction_id) WHERE pmp_end_date IS NULL;
CREATE INDEX idx_pmp_pendentes ON pagamentos.pagamento_mpesa (pmp_pedido_em) WHERE pmp_respondido_em IS NULL AND pmp_end_date IS NULL;

-- Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)
CREATE TABLE pagamentos.mpesa_callback_log (
    mcl_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mcl_pmp_id BIGINT,
    mcl_tipo VARCHAR(30) NOT NULL,
    mcl_chave_idempotencia VARCHAR(100) NOT NULL,
    mcl_payload JSONB NOT NULL,
    mcl_processado BOOLEAN NOT NULL DEFAULT FALSE,
    mcl_erro VARCHAR(500),
    mcl_recebido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mcl_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    mcl_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mcl_criado_por INT,
    mcl_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mcl_modificado_por INT,
    mcl_end_date TIMESTAMPTZ,
    CONSTRAINT fk_mcl_pmp_id FOREIGN KEY (mcl_pmp_id) REFERENCES pagamentos.pagamento_mpesa(pmp_id),
    CONSTRAINT chk_mcl_end_date CHECK (mcl_end_date IS NULL OR mcl_end_date >= mcl_criado_em)
);
COMMENT ON TABLE pagamentos.mpesa_callback_log IS 'Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)';
CREATE UNIQUE INDEX uq_mcl_chave_idempotencia ON pagamentos.mpesa_callback_log (mcl_chave_idempotencia) WHERE mcl_end_date IS NULL;
CREATE INDEX idx_mcl_pmp_id ON pagamentos.mpesa_callback_log (mcl_pmp_id);
CREATE INDEX idx_mcl_por_processar ON pagamentos.mpesa_callback_log (mcl_recebido_em) WHERE NOT mcl_processado;

-- Detalhe de pagamentos por banco
CREATE TABLE pagamentos.pagamento_bancario (
    pba_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pba_tra_id BIGINT NOT NULL,
    pba_banco VARCHAR(100),
    pba_nib VARCHAR(25) NOT NULL,
    pba_titular VARCHAR(150) NOT NULL,
    pba_referencia_bancaria VARCHAR(100),
    pba_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pba_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pba_criado_por INT,
    pba_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pba_modificado_por INT,
    pba_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pba_tra_id FOREIGN KEY (pba_tra_id) REFERENCES tesouraria.transacao(tra_id),
    CONSTRAINT chk_pba_end_date CHECK (pba_end_date IS NULL OR pba_end_date >= pba_criado_em)
);
COMMENT ON TABLE pagamentos.pagamento_bancario IS 'Detalhe de pagamentos por banco';
CREATE UNIQUE INDEX uq_pba_tra_id ON pagamentos.pagamento_bancario (pba_tra_id) WHERE pba_end_date IS NULL;

-- Regras de pagamentos ----------------------------------------------------

-- O valor do pedido M-Pesa tem de ser igual ao da transacção
CREATE FUNCTION pagamentos.fn_pmp_validar() RETURNS trigger AS $$
DECLARE v_total NUMERIC;
BEGIN
    SELECT tra_valor_total INTO v_total FROM tesouraria.transacao WHERE tra_id = NEW.pmp_tra_id;
    IF v_total IS DISTINCT FROM NEW.pmp_valor THEN
        RAISE EXCEPTION 'Valor M-Pesa (%) diferente do valor da transacção (%)', NEW.pmp_valor, v_total;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pmp_10_validar
    BEFORE INSERT OR UPDATE ON pagamentos.pagamento_mpesa
    FOR EACH ROW EXECUTE FUNCTION pagamentos.fn_pmp_validar();


-- >>>>> V9__comunicacao.sql
-- =====================================================================
-- V9 · Módulo comunicacao: Comunicação
-- Fila de SMS, WhatsApp e e-mail.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;


-- Fila de SMS, WhatsApp e e-mail a enviar
CREATE TABLE comunicacao.notificacao (
    ntf_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ntf_igr_id INT NOT NULL,
    ntf_mem_id INT,
    ntf_canal canal_notificacao_t NOT NULL,
    ntf_destino VARCHAR(150) NOT NULL,
    ntf_assunto VARCHAR(150),
    ntf_mensagem TEXT NOT NULL,
    ntf_agendada_para TIMESTAMPTZ NOT NULL DEFAULT now(),
    ntf_enviada_em TIMESTAMPTZ,
    ntf_tentativas SMALLINT NOT NULL DEFAULT 0,
    ntf_erro VARCHAR(500),
    ntf_origem_tabela VARCHAR(80),
    ntf_origem_id BIGINT,
    ntf_estado estado_notificacao_t NOT NULL DEFAULT 'PENDENTE',
    ntf_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ntf_criado_por INT,
    ntf_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ntf_modificado_por INT,
    ntf_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ntf_igr_id FOREIGN KEY (ntf_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_ntf_mem_id FOREIGN KEY (ntf_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_ntf_end_date CHECK (ntf_end_date IS NULL OR ntf_end_date >= ntf_criado_em)
);
COMMENT ON TABLE comunicacao.notificacao IS 'Fila de SMS, WhatsApp e e-mail a enviar';
CREATE INDEX idx_ntf_igr_id ON comunicacao.notificacao (ntf_igr_id);
CREATE INDEX idx_ntf_mem_id ON comunicacao.notificacao (ntf_mem_id);
CREATE INDEX idx_ntf_fila ON comunicacao.notificacao (ntf_agendada_para) WHERE ntf_estado = 'PENDENTE' AND ntf_end_date IS NULL;

-- Regras de comunicação ---------------------------------------------------

-- Ao emitir um recibo, envia-o ao membro pelo contacto principal (se tiver consentimento)
CREATE FUNCTION comunicacao.fn_rec_notificar() RETURNS trigger AS $$
DECLARE
    v_mem   INT;
    v_valor NUMERIC;
    c       secretaria.contacto%ROWTYPE;
    v_canal nucleo.canal_notificacao_t;
BEGIN
    SELECT tra_mem_id, tra_valor_total INTO v_mem, v_valor FROM tesouraria.transacao WHERE tra_id = NEW.rec_tra_id;
    IF v_mem IS NULL THEN RETURN NULL; END IF;

    SELECT * INTO c FROM secretaria.contacto
    WHERE cto_mem_id = v_mem AND cto_end_date IS NULL AND cto_estado = 'ACTIVO'
      AND cto_tipo IN ('WHATSAPP', 'TELEFONE', 'EMAIL')
    ORDER BY cto_principal DESC, cto_id LIMIT 1;
    IF NOT FOUND THEN RETURN NULL; END IF;

    v_canal := CASE c.cto_tipo WHEN 'WHATSAPP' THEN 'WHATSAPP' WHEN 'EMAIL' THEN 'EMAIL' ELSE 'SMS' END;
    IF NOT EXISTS (SELECT 1 FROM secretaria.consentimento
                   WHERE cns_mem_id = v_mem AND cns_end_date IS NULL AND cns_concedido
                     AND cns_tipo = ('CONTACTO_' || v_canal)::nucleo.tipo_consentimento_t) THEN
        RETURN NULL;
    END IF;

    INSERT INTO comunicacao.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                         ntf_origem_tabela, ntf_origem_id)
    VALUES (NEW.rec_igr_id, v_mem, v_canal, c.cto_valor, 'Recibo ' || NEW.rec_numero || '/' || NEW.rec_ano,
            'Recebemos a sua contribuição de ' || to_char(v_valor, 'FM999G999G990D00') || ' MT. Recibo n.º '
            || NEW.rec_numero || '/' || NEW.rec_ano || '. Deus o abençoe.',
            'tesouraria.recibo', NEW.rec_id);
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rec_10_notificar
    AFTER INSERT ON tesouraria.recibo
    FOR EACH ROW EXECUTE FUNCTION comunicacao.fn_rec_notificar();


-- >>>>> V10__comportamento_comum.sql
-- =====================================================================
-- V10 · Comportamento comum a todas as tabelas
--   criado/modificado automáticos; DELETE e TRUNCATE proibidos
--   auditoria: cada alteração e término guarda só os campos que mudaram. As inserções não
--   se duplicam no log: a própria linha guarda quem a criou e quando, e nunca é apagada.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

CREATE TRIGGER trg_per_00_padrao BEFORE INSERT OR UPDATE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('per', 'nucleo.perfil', '');
CREATE TRIGGER trg_per_00_sem_delete BEFORE DELETE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('per');
CREATE TRIGGER trg_per_00_sem_truncate BEFORE TRUNCATE ON nucleo.perfil FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('per');
CREATE TRIGGER trg_per_99_log AFTER UPDATE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('per');
ALTER TABLE nucleo.perfil ADD CONSTRAINT fk_per_criado_por FOREIGN KEY (per_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.perfil ADD CONSTRAINT fk_per_modificado_por FOREIGN KEY (per_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_prm_00_padrao BEFORE INSERT OR UPDATE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('prm', 'nucleo.permissao', '');
CREATE TRIGGER trg_prm_00_sem_delete BEFORE DELETE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('prm');
CREATE TRIGGER trg_prm_00_sem_truncate BEFORE TRUNCATE ON nucleo.permissao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('prm');
CREATE TRIGGER trg_prm_99_log AFTER UPDATE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('prm');
ALTER TABLE nucleo.permissao ADD CONSTRAINT fk_prm_criado_por FOREIGN KEY (prm_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.permissao ADD CONSTRAINT fk_prm_modificado_por FOREIGN KEY (prm_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ppe_00_padrao BEFORE INSERT OR UPDATE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ppe', 'nucleo.perfil_permissao', '');
CREATE TRIGGER trg_ppe_00_sem_delete BEFORE DELETE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ppe');
CREATE TRIGGER trg_ppe_00_sem_truncate BEFORE TRUNCATE ON nucleo.perfil_permissao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ppe');
CREATE TRIGGER trg_ppe_99_log AFTER UPDATE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ppe');
ALTER TABLE nucleo.perfil_permissao ADD CONSTRAINT fk_ppe_criado_por FOREIGN KEY (ppe_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.perfil_permissao ADD CONSTRAINT fk_ppe_modificado_por FOREIGN KEY (ppe_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_usu_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('usu', 'nucleo.usuario', '');
CREATE TRIGGER trg_usu_00_sem_delete BEFORE DELETE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('usu');
CREATE TRIGGER trg_usu_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('usu');
CREATE TRIGGER trg_usu_99_log AFTER UPDATE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('usu');
ALTER TABLE nucleo.usuario ADD CONSTRAINT fk_usu_criado_por FOREIGN KEY (usu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario ADD CONSTRAINT fk_usu_modificado_por FOREIGN KEY (usu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_uig_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('uig', 'nucleo.usuario_igreja', 'uig_igr_id');
CREATE TRIGGER trg_uig_00_sem_delete BEFORE DELETE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('uig');
CREATE TRIGGER trg_uig_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario_igreja FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('uig');
CREATE TRIGGER trg_uig_99_log AFTER UPDATE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('uig');
ALTER TABLE nucleo.usuario_igreja ADD CONSTRAINT fk_uig_criado_por FOREIGN KEY (uig_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario_igreja ADD CONSTRAINT fk_uig_modificado_por FOREIGN KEY (uig_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_uen_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('uen', 'nucleo.usuario_entidade', '');
CREATE TRIGGER trg_uen_00_sem_delete BEFORE DELETE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('uen');
CREATE TRIGGER trg_uen_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario_entidade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('uen');
CREATE TRIGGER trg_uen_99_log AFTER UPDATE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('uen');
ALTER TABLE nucleo.usuario_entidade ADD CONSTRAINT fk_uen_criado_por FOREIGN KEY (uen_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario_entidade ADD CONSTRAINT fk_uen_modificado_por FOREIGN KEY (uen_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_lau_00_padrao BEFORE INSERT OR UPDATE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('lau', '', '');
CREATE TRIGGER trg_lau_00_sem_delete BEFORE DELETE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('lau');
CREATE TRIGGER trg_lau_00_sem_truncate BEFORE TRUNCATE ON nucleo.log_auditoria FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('lau');
CREATE TRIGGER trg_lau_00_imutavel BEFORE UPDATE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_imutavel();
ALTER TABLE nucleo.log_auditoria ADD CONSTRAINT fk_lau_criado_por FOREIGN KEY (lau_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.log_auditoria ADD CONSTRAINT fk_lau_modificado_por FOREIGN KEY (lau_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ent_00_padrao BEFORE INSERT OR UPDATE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ent', 'organizacao.entidade', '');
CREATE TRIGGER trg_ent_00_sem_delete BEFORE DELETE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ent');
CREATE TRIGGER trg_ent_00_sem_truncate BEFORE TRUNCATE ON organizacao.entidade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ent');
CREATE TRIGGER trg_ent_99_log AFTER UPDATE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ent');
ALTER TABLE organizacao.entidade ADD CONSTRAINT fk_ent_criado_por FOREIGN KEY (ent_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.entidade ADD CONSTRAINT fk_ent_modificado_por FOREIGN KEY (ent_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dst_00_padrao BEFORE INSERT OR UPDATE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dst', 'organizacao.distrito', '');
CREATE TRIGGER trg_dst_00_sem_delete BEFORE DELETE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dst');
CREATE TRIGGER trg_dst_00_sem_truncate BEFORE TRUNCATE ON organizacao.distrito FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dst');
CREATE TRIGGER trg_dst_99_log AFTER UPDATE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dst');
ALTER TABLE organizacao.distrito ADD CONSTRAINT fk_dst_criado_por FOREIGN KEY (dst_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.distrito ADD CONSTRAINT fk_dst_modificado_por FOREIGN KEY (dst_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_igr_00_padrao BEFORE INSERT OR UPDATE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('igr', 'organizacao.igreja', 'igr_id');
CREATE TRIGGER trg_igr_00_sem_delete BEFORE DELETE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('igr');
CREATE TRIGGER trg_igr_00_sem_truncate BEFORE TRUNCATE ON organizacao.igreja FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('igr');
CREATE TRIGGER trg_igr_99_log AFTER UPDATE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('igr');
ALTER TABLE organizacao.igreja ADD CONSTRAINT fk_igr_criado_por FOREIGN KEY (igr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.igreja ADD CONSTRAINT fk_igr_modificado_por FOREIGN KEY (igr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dep_00_padrao BEFORE INSERT OR UPDATE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dep', 'organizacao.departamento', '');
CREATE TRIGGER trg_dep_00_sem_delete BEFORE DELETE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dep');
CREATE TRIGGER trg_dep_00_sem_truncate BEFORE TRUNCATE ON organizacao.departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dep');
CREATE TRIGGER trg_dep_99_log AFTER UPDATE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dep');
ALTER TABLE organizacao.departamento ADD CONSTRAINT fk_dep_criado_por FOREIGN KEY (dep_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.departamento ADD CONSTRAINT fk_dep_modificado_por FOREIGN KEY (dep_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ide_00_padrao BEFORE INSERT OR UPDATE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ide', 'organizacao.igreja_departamento', 'ide_igr_id');
CREATE TRIGGER trg_ide_00_sem_delete BEFORE DELETE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ide');
CREATE TRIGGER trg_ide_00_sem_truncate BEFORE TRUNCATE ON organizacao.igreja_departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ide');
CREATE TRIGGER trg_ide_99_log AFTER UPDATE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ide');
ALTER TABLE organizacao.igreja_departamento ADD CONSTRAINT fk_ide_criado_por FOREIGN KEY (ide_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.igreja_departamento ADD CONSTRAINT fk_ide_modificado_por FOREIGN KEY (ide_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_car_00_padrao BEFORE INSERT OR UPDATE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('car', 'organizacao.cargo', '');
CREATE TRIGGER trg_car_00_sem_delete BEFORE DELETE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('car');
CREATE TRIGGER trg_car_00_sem_truncate BEFORE TRUNCATE ON organizacao.cargo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('car');
CREATE TRIGGER trg_car_99_log AFTER UPDATE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('car');
ALTER TABLE organizacao.cargo ADD CONSTRAINT fk_car_criado_por FOREIGN KEY (car_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.cargo ADD CONSTRAINT fk_car_modificado_por FOREIGN KEY (car_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fam_00_padrao BEFORE INSERT OR UPDATE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fam', 'secretaria.familia', 'fam_igr_id');
CREATE TRIGGER trg_fam_00_sem_delete BEFORE DELETE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fam');
CREATE TRIGGER trg_fam_00_sem_truncate BEFORE TRUNCATE ON secretaria.familia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fam');
CREATE TRIGGER trg_fam_99_log AFTER UPDATE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fam');
ALTER TABLE secretaria.familia ADD CONSTRAINT fk_fam_criado_por FOREIGN KEY (fam_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.familia ADD CONSTRAINT fk_fam_modificado_por FOREIGN KEY (fam_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mem_00_padrao BEFORE INSERT OR UPDATE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mem', 'secretaria.membro', 'mem_igr_id');
CREATE TRIGGER trg_mem_00_sem_delete BEFORE DELETE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mem');
CREATE TRIGGER trg_mem_00_sem_truncate BEFORE TRUNCATE ON secretaria.membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mem');
CREATE TRIGGER trg_mem_99_log AFTER UPDATE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mem');
ALTER TABLE secretaria.membro ADD CONSTRAINT fk_mem_criado_por FOREIGN KEY (mem_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.membro ADD CONSTRAINT fk_mem_modificado_por FOREIGN KEY (mem_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cto_00_padrao BEFORE INSERT OR UPDATE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cto', 'secretaria.contacto', '');
CREATE TRIGGER trg_cto_00_sem_delete BEFORE DELETE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cto');
CREATE TRIGGER trg_cto_00_sem_truncate BEFORE TRUNCATE ON secretaria.contacto FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cto');
CREATE TRIGGER trg_cto_99_log AFTER UPDATE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cto');
ALTER TABLE secretaria.contacto ADD CONSTRAINT fk_cto_criado_por FOREIGN KEY (cto_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.contacto ADD CONSTRAINT fk_cto_modificado_por FOREIGN KEY (cto_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cns_00_padrao BEFORE INSERT OR UPDATE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cns', 'secretaria.consentimento', '');
CREATE TRIGGER trg_cns_00_sem_delete BEFORE DELETE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cns');
CREATE TRIGGER trg_cns_00_sem_truncate BEFORE TRUNCATE ON secretaria.consentimento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cns');
CREATE TRIGGER trg_cns_99_log AFTER UPDATE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cns');
ALTER TABLE secretaria.consentimento ADD CONSTRAINT fk_cns_criado_por FOREIGN KEY (cns_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.consentimento ADD CONSTRAINT fk_cns_modificado_por FOREIGN KEY (cns_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_reu_00_padrao BEFORE INSERT OR UPDATE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('reu', 'secretaria.reuniao', 'reu_igr_id');
CREATE TRIGGER trg_reu_00_sem_delete BEFORE DELETE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('reu');
CREATE TRIGGER trg_reu_00_sem_truncate BEFORE TRUNCATE ON secretaria.reuniao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('reu');
CREATE TRIGGER trg_reu_99_log AFTER UPDATE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('reu');
ALTER TABLE secretaria.reuniao ADD CONSTRAINT fk_reu_criado_por FOREIGN KEY (reu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.reuniao ADD CONSTRAINT fk_reu_modificado_por FOREIGN KEY (reu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_vot_00_padrao BEFORE INSERT OR UPDATE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('vot', 'secretaria.voto', '');
CREATE TRIGGER trg_vot_00_sem_delete BEFORE DELETE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('vot');
CREATE TRIGGER trg_vot_00_sem_truncate BEFORE TRUNCATE ON secretaria.voto FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('vot');
CREATE TRIGGER trg_vot_99_log AFTER UPDATE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('vot');
ALTER TABLE secretaria.voto ADD CONSTRAINT fk_vot_criado_por FOREIGN KEY (vot_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.voto ADD CONSTRAINT fk_vot_modificado_por FOREIGN KEY (vot_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mmb_00_padrao BEFORE INSERT OR UPDATE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mmb', 'secretaria.movimento_membro', 'mmb_igr_id');
CREATE TRIGGER trg_mmb_00_sem_delete BEFORE DELETE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mmb');
CREATE TRIGGER trg_mmb_00_sem_truncate BEFORE TRUNCATE ON secretaria.movimento_membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mmb');
CREATE TRIGGER trg_mmb_99_log AFTER UPDATE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mmb');
ALTER TABLE secretaria.movimento_membro ADD CONSTRAINT fk_mmb_criado_por FOREIGN KEY (mmb_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.movimento_membro ADD CONSTRAINT fk_mmb_modificado_por FOREIGN KEY (mmb_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tme_00_padrao BEFORE INSERT OR UPDATE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tme', 'secretaria.transferencia_membro', '');
CREATE TRIGGER trg_tme_00_sem_delete BEFORE DELETE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tme');
CREATE TRIGGER trg_tme_00_sem_truncate BEFORE TRUNCATE ON secretaria.transferencia_membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tme');
CREATE TRIGGER trg_tme_99_log AFTER UPDATE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tme');
ALTER TABLE secretaria.transferencia_membro ADD CONSTRAINT fk_tme_criado_por FOREIGN KEY (tme_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.transferencia_membro ADD CONSTRAINT fk_tme_modificado_por FOREIGN KEY (tme_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dsc_00_padrao BEFORE INSERT OR UPDATE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dsc', 'secretaria.disciplina', '');
CREATE TRIGGER trg_dsc_00_sem_delete BEFORE DELETE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dsc');
CREATE TRIGGER trg_dsc_00_sem_truncate BEFORE TRUNCATE ON secretaria.disciplina FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dsc');
CREATE TRIGGER trg_dsc_99_log AFTER UPDATE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dsc');
ALTER TABLE secretaria.disciplina ADD CONSTRAINT fk_dsc_criado_por FOREIGN KEY (dsc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.disciplina ADD CONSTRAINT fk_dsc_modificado_por FOREIGN KEY (dsc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ofi_00_padrao BEFORE INSERT OR UPDATE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ofi', 'secretaria.oficial', 'ofi_igr_id');
CREATE TRIGGER trg_ofi_00_sem_delete BEFORE DELETE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ofi');
CREATE TRIGGER trg_ofi_00_sem_truncate BEFORE TRUNCATE ON secretaria.oficial FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ofi');
CREATE TRIGGER trg_ofi_99_log AFTER UPDATE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ofi');
ALTER TABLE secretaria.oficial ADD CONSTRAINT fk_ofi_criado_por FOREIGN KEY (ofi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.oficial ADD CONSTRAINT fk_ofi_modificado_por FOREIGN KEY (ofi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_bap_00_padrao BEFORE INSERT OR UPDATE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('bap', 'secretaria.baptismo', '');
CREATE TRIGGER trg_bap_00_sem_delete BEFORE DELETE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('bap');
CREATE TRIGGER trg_bap_00_sem_truncate BEFORE TRUNCATE ON secretaria.baptismo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('bap');
CREATE TRIGGER trg_bap_99_log AFTER UPDATE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('bap');
ALTER TABLE secretaria.baptismo ADD CONSTRAINT fk_bap_criado_por FOREIGN KEY (bap_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.baptismo ADD CONSTRAINT fk_bap_modificado_por FOREIGN KEY (bap_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_act_00_padrao BEFORE INSERT OR UPDATE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('act', 'actividades.actividade', '');
CREATE TRIGGER trg_act_00_sem_delete BEFORE DELETE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('act');
CREATE TRIGGER trg_act_00_sem_truncate BEFORE TRUNCATE ON actividades.actividade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('act');
CREATE TRIGGER trg_act_99_log AFTER UPDATE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('act');
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_criado_por FOREIGN KEY (act_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_modificado_por FOREIGN KEY (act_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mat_00_padrao BEFORE INSERT OR UPDATE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mat', 'actividades.material', '');
CREATE TRIGGER trg_mat_00_sem_delete BEFORE DELETE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mat');
CREATE TRIGGER trg_mat_00_sem_truncate BEFORE TRUNCATE ON actividades.material FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mat');
CREATE TRIGGER trg_mat_99_log AFTER UPDATE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mat');
ALTER TABLE actividades.material ADD CONSTRAINT fk_mat_criado_por FOREIGN KEY (mat_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.material ADD CONSTRAINT fk_mat_modificado_por FOREIGN KEY (mat_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_esc_00_padrao BEFORE INSERT OR UPDATE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('esc', 'actividades.escala', 'esc_igr_id');
CREATE TRIGGER trg_esc_00_sem_delete BEFORE DELETE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('esc');
CREATE TRIGGER trg_esc_00_sem_truncate BEFORE TRUNCATE ON actividades.escala FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('esc');
CREATE TRIGGER trg_esc_99_log AFTER UPDATE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('esc');
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_criado_por FOREIGN KEY (esc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_modificado_por FOREIGN KEY (esc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_etr_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('etr', 'escola_sabatina.trimestre', '');
CREATE TRIGGER trg_etr_00_sem_delete BEFORE DELETE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('etr');
CREATE TRIGGER trg_etr_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.trimestre FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('etr');
CREATE TRIGGER trg_etr_99_log AFTER UPDATE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('etr');
ALTER TABLE escola_sabatina.trimestre ADD CONSTRAINT fk_etr_criado_por FOREIGN KEY (etr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.trimestre ADD CONSTRAINT fk_etr_modificado_por FOREIGN KEY (etr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_esa_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('esa', 'escola_sabatina.sabado', '');
CREATE TRIGGER trg_esa_00_sem_delete BEFORE DELETE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('esa');
CREATE TRIGGER trg_esa_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.sabado FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('esa');
CREATE TRIGGER trg_esa_99_log AFTER UPDATE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('esa');
ALTER TABLE escola_sabatina.sabado ADD CONSTRAINT fk_esa_criado_por FOREIGN KEY (esa_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.sabado ADD CONSTRAINT fk_esa_modificado_por FOREIGN KEY (esa_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ecl_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ecl', 'escola_sabatina.classe', 'ecl_igr_id');
CREATE TRIGGER trg_ecl_00_sem_delete BEFORE DELETE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ecl');
CREATE TRIGGER trg_ecl_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.classe FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ecl');
CREATE TRIGGER trg_ecl_99_log AFTER UPDATE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ecl');
ALTER TABLE escola_sabatina.classe ADD CONSTRAINT fk_ecl_criado_por FOREIGN KEY (ecl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.classe ADD CONSTRAINT fk_ecl_modificado_por FOREIGN KEY (ecl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ect_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ect', 'escola_sabatina.classe_trimestre', 'ect_igr_id');
CREATE TRIGGER trg_ect_00_sem_delete BEFORE DELETE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ect');
CREATE TRIGGER trg_ect_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.classe_trimestre FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ect');
CREATE TRIGGER trg_ect_99_log AFTER UPDATE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ect');
ALTER TABLE escola_sabatina.classe_trimestre ADD CONSTRAINT fk_ect_criado_por FOREIGN KEY (ect_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.classe_trimestre ADD CONSTRAINT fk_ect_modificado_por FOREIGN KEY (ect_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ema_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ema', 'escola_sabatina.matricula', '');
CREATE TRIGGER trg_ema_00_sem_delete BEFORE DELETE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ema');
CREATE TRIGGER trg_ema_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.matricula FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ema');
CREATE TRIGGER trg_ema_99_log AFTER UPDATE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ema');
ALTER TABLE escola_sabatina.matricula ADD CONSTRAINT fk_ema_criado_por FOREIGN KEY (ema_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.matricula ADD CONSTRAINT fk_ema_modificado_por FOREIGN KEY (ema_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ers_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ers', 'escola_sabatina.relatorio_sabado', 'ers_igr_id');
CREATE TRIGGER trg_ers_00_sem_delete BEFORE DELETE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ers');
CREATE TRIGGER trg_ers_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.relatorio_sabado FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ers');
CREATE TRIGGER trg_ers_99_log AFTER UPDATE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ers');
ALTER TABLE escola_sabatina.relatorio_sabado ADD CONSTRAINT fk_ers_criado_por FOREIGN KEY (ers_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.relatorio_sabado ADD CONSTRAINT fk_ers_modificado_por FOREIGN KEY (ers_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_epr_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('epr', 'escola_sabatina.presenca', 'epr_igr_id');
CREATE TRIGGER trg_epr_00_sem_delete BEFORE DELETE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('epr');
CREATE TRIGGER trg_epr_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.presenca FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('epr');
CREATE TRIGGER trg_epr_99_log AFTER UPDATE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('epr');
ALTER TABLE escola_sabatina.presenca ADD CONSTRAINT fk_epr_criado_por FOREIGN KEY (epr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.presenca ADD CONSTRAINT fk_epr_modificado_por FOREIGN KEY (epr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_evi_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('evi', 'escola_sabatina.visitante', '');
CREATE TRIGGER trg_evi_00_sem_delete BEFORE DELETE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('evi');
CREATE TRIGGER trg_evi_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.visitante FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('evi');
CREATE TRIGGER trg_evi_99_log AFTER UPDATE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('evi');
ALTER TABLE escola_sabatina.visitante ADD CONSTRAINT fk_evi_criado_por FOREIGN KEY (evi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.visitante ADD CONSTRAINT fk_evi_modificado_por FOREIGN KEY (evi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_epc_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('epc', 'escola_sabatina.pontuacao_config', '');
CREATE TRIGGER trg_epc_00_sem_delete BEFORE DELETE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('epc');
CREATE TRIGGER trg_epc_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.pontuacao_config FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('epc');
CREATE TRIGGER trg_epc_99_log AFTER UPDATE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('epc');
ALTER TABLE escola_sabatina.pontuacao_config ADD CONSTRAINT fk_epc_criado_por FOREIGN KEY (epc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.pontuacao_config ADD CONSTRAINT fk_epc_modificado_por FOREIGN KEY (epc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cfi_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cfi', 'tesouraria.conta_financeira', 'cfi_igr_id');
CREATE TRIGGER trg_cfi_00_sem_delete BEFORE DELETE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cfi');
CREATE TRIGGER trg_cfi_00_sem_truncate BEFORE TRUNCATE ON tesouraria.conta_financeira FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cfi');
CREATE TRIGGER trg_cfi_99_log AFTER UPDATE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cfi');
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT fk_cfi_criado_por FOREIGN KEY (cfi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT fk_cfi_modificado_por FOREIGN KEY (cfi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fun_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fun', 'tesouraria.fundo', '');
CREATE TRIGGER trg_fun_00_sem_delete BEFORE DELETE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fun');
CREATE TRIGGER trg_fun_00_sem_truncate BEFORE TRUNCATE ON tesouraria.fundo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fun');
CREATE TRIGGER trg_fun_99_log AFTER UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fun');
ALTER TABLE tesouraria.fundo ADD CONSTRAINT fk_fun_criado_por FOREIGN KEY (fun_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.fundo ADD CONSTRAINT fk_fun_modificado_por FOREIGN KEY (fun_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cof_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cof', 'tesouraria.calendario_oferta', '');
CREATE TRIGGER trg_cof_00_sem_delete BEFORE DELETE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cof');
CREATE TRIGGER trg_cof_00_sem_truncate BEFORE TRUNCATE ON tesouraria.calendario_oferta FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cof');
CREATE TRIGGER trg_cof_99_log AFTER UPDATE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cof');
ALTER TABLE tesouraria.calendario_oferta ADD CONSTRAINT fk_cof_criado_por FOREIGN KEY (cof_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.calendario_oferta ADD CONSTRAINT fk_cof_modificado_por FOREIGN KEY (cof_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cat_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cat', 'tesouraria.categoria', '');
CREATE TRIGGER trg_cat_00_sem_delete BEFORE DELETE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cat');
CREATE TRIGGER trg_cat_00_sem_truncate BEFORE TRUNCATE ON tesouraria.categoria FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cat');
CREATE TRIGGER trg_cat_99_log AFTER UPDATE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cat');
ALTER TABLE tesouraria.categoria ADD CONSTRAINT fk_cat_criado_por FOREIGN KEY (cat_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.categoria ADD CONSTRAINT fk_cat_modificado_por FOREIGN KEY (cat_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_alv_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('alv', 'tesouraria.alvo', 'alv_igr_id');
CREATE TRIGGER trg_alv_00_sem_delete BEFORE DELETE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('alv');
CREATE TRIGGER trg_alv_00_sem_truncate BEFORE TRUNCATE ON tesouraria.alvo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('alv');
CREATE TRIGGER trg_alv_99_log AFTER UPDATE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('alv');
ALTER TABLE tesouraria.alvo ADD CONSTRAINT fk_alv_criado_por FOREIGN KEY (alv_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.alvo ADD CONSTRAINT fk_alv_modificado_por FOREIGN KEY (alv_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_orc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('orc', 'tesouraria.orcamento', 'orc_igr_id');
CREATE TRIGGER trg_orc_00_sem_delete BEFORE DELETE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('orc');
CREATE TRIGGER trg_orc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.orcamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('orc');
CREATE TRIGGER trg_orc_99_log AFTER UPDATE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('orc');
ALTER TABLE tesouraria.orcamento ADD CONSTRAINT fk_orc_criado_por FOREIGN KEY (orc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.orcamento ADD CONSTRAINT fk_orc_modificado_por FOREIGN KEY (orc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_orl_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('orl', 'tesouraria.orcamento_linha', '');
CREATE TRIGGER trg_orl_00_sem_delete BEFORE DELETE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('orl');
CREATE TRIGGER trg_orl_00_sem_truncate BEFORE TRUNCATE ON tesouraria.orcamento_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('orl');
CREATE TRIGGER trg_orl_99_log AFTER UPDATE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('orl');
ALTER TABLE tesouraria.orcamento_linha ADD CONSTRAINT fk_orl_criado_por FOREIGN KEY (orl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.orcamento_linha ADD CONSTRAINT fk_orl_modificado_por FOREIGN KEY (orl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_des_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('des', 'tesouraria.despesa', 'des_igr_id');
CREATE TRIGGER trg_des_00_sem_delete BEFORE DELETE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('des');
CREATE TRIGGER trg_des_00_sem_truncate BEFORE TRUNCATE ON tesouraria.despesa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('des');
CREATE TRIGGER trg_des_99_log AFTER UPDATE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('des');
ALTER TABLE tesouraria.despesa ADD CONSTRAINT fk_des_criado_por FOREIGN KEY (des_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.despesa ADD CONSTRAINT fk_des_modificado_por FOREIGN KEY (des_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cnu_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cnu', 'tesouraria.contagem_numerario', 'cnu_igr_id');
CREATE TRIGGER trg_cnu_00_sem_delete BEFORE DELETE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cnu');
CREATE TRIGGER trg_cnu_00_sem_truncate BEFORE TRUNCATE ON tesouraria.contagem_numerario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cnu');
CREATE TRIGGER trg_cnu_99_log AFTER UPDATE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cnu');
ALTER TABLE tesouraria.contagem_numerario ADD CONSTRAINT fk_cnu_criado_por FOREIGN KEY (cnu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.contagem_numerario ADD CONSTRAINT fk_cnu_modificado_por FOREIGN KEY (cnu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tra_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tra', 'tesouraria.transacao', 'tra_igr_id');
CREATE TRIGGER trg_tra_00_sem_delete BEFORE DELETE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tra');
CREATE TRIGGER trg_tra_00_sem_truncate BEFORE TRUNCATE ON tesouraria.transacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tra');
CREATE TRIGGER trg_tra_99_log AFTER UPDATE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tra');
ALTER TABLE tesouraria.transacao ADD CONSTRAINT fk_tra_criado_por FOREIGN KEY (tra_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.transacao ADD CONSTRAINT fk_tra_modificado_por FOREIGN KEY (tra_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tli_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tli', 'tesouraria.transacao_linha', 'tli_igr_id');
CREATE TRIGGER trg_tli_00_sem_delete BEFORE DELETE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tli');
CREATE TRIGGER trg_tli_00_sem_truncate BEFORE TRUNCATE ON tesouraria.transacao_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tli');
CREATE TRIGGER trg_tli_99_log AFTER UPDATE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tli');
ALTER TABLE tesouraria.transacao_linha ADD CONSTRAINT fk_tli_criado_por FOREIGN KEY (tli_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.transacao_linha ADD CONSTRAINT fk_tli_modificado_por FOREIGN KEY (tli_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_sdc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.saldo_diario_conta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('sdc', '', 'sdc_igr_id');
CREATE TRIGGER trg_sdc_00_sem_delete BEFORE DELETE ON tesouraria.saldo_diario_conta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('sdc');
CREATE TRIGGER trg_sdc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.saldo_diario_conta FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('sdc');
ALTER TABLE tesouraria.saldo_diario_conta ADD CONSTRAINT fk_sdc_criado_por FOREIGN KEY (sdc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.saldo_diario_conta ADD CONSTRAINT fk_sdc_modificado_por FOREIGN KEY (sdc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_sdf_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.saldo_diario_fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('sdf', '', 'sdf_igr_id');
CREATE TRIGGER trg_sdf_00_sem_delete BEFORE DELETE ON tesouraria.saldo_diario_fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('sdf');
CREATE TRIGGER trg_sdf_00_sem_truncate BEFORE TRUNCATE ON tesouraria.saldo_diario_fundo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('sdf');
ALTER TABLE tesouraria.saldo_diario_fundo ADD CONSTRAINT fk_sdf_criado_por FOREIGN KEY (sdf_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.saldo_diario_fundo ADD CONSTRAINT fk_sdf_modificado_por FOREIGN KEY (sdf_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rec_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rec', 'tesouraria.recibo', 'rec_igr_id');
CREATE TRIGGER trg_rec_00_sem_delete BEFORE DELETE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rec');
CREATE TRIGGER trg_rec_00_sem_truncate BEFORE TRUNCATE ON tesouraria.recibo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rec');
CREATE TRIGGER trg_rec_99_log AFTER UPDATE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rec');
ALTER TABLE tesouraria.recibo ADD CONSTRAINT fk_rec_criado_por FOREIGN KEY (rec_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.recibo ADD CONSTRAINT fk_rec_modificado_por FOREIGN KEY (rec_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_doc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('doc', 'tesouraria.documento', '');
CREATE TRIGGER trg_doc_00_sem_delete BEFORE DELETE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('doc');
CREATE TRIGGER trg_doc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.documento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('doc');
CREATE TRIGGER trg_doc_99_log AFTER UPDATE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('doc');
ALTER TABLE tesouraria.documento ADD CONSTRAINT fk_doc_criado_por FOREIGN KEY (doc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.documento ADD CONSTRAINT fk_doc_modificado_por FOREIGN KEY (doc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rem_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rem', 'tesouraria.remessa', 'rem_igr_id');
CREATE TRIGGER trg_rem_00_sem_delete BEFORE DELETE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rem');
CREATE TRIGGER trg_rem_00_sem_truncate BEFORE TRUNCATE ON tesouraria.remessa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rem');
CREATE TRIGGER trg_rem_99_log AFTER UPDATE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rem');
ALTER TABLE tesouraria.remessa ADD CONSTRAINT fk_rem_criado_por FOREIGN KEY (rem_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.remessa ADD CONSTRAINT fk_rem_modificado_por FOREIGN KEY (rem_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rml_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rml', 'tesouraria.remessa_linha', '');
CREATE TRIGGER trg_rml_00_sem_delete BEFORE DELETE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rml');
CREATE TRIGGER trg_rml_00_sem_truncate BEFORE TRUNCATE ON tesouraria.remessa_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rml');
CREATE TRIGGER trg_rml_99_log AFTER UPDATE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rml');
ALTER TABLE tesouraria.remessa_linha ADD CONSTRAINT fk_rml_criado_por FOREIGN KEY (rml_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.remessa_linha ADD CONSTRAINT fk_rml_modificado_por FOREIGN KEY (rml_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fpe_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fpe', 'tesouraria.fecho_periodo', 'fpe_igr_id');
CREATE TRIGGER trg_fpe_00_sem_delete BEFORE DELETE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fpe');
CREATE TRIGGER trg_fpe_00_sem_truncate BEFORE TRUNCATE ON tesouraria.fecho_periodo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fpe');
CREATE TRIGGER trg_fpe_99_log AFTER UPDATE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fpe');
ALTER TABLE tesouraria.fecho_periodo ADD CONSTRAINT fk_fpe_criado_por FOREIGN KEY (fpe_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.fecho_periodo ADD CONSTRAINT fk_fpe_modificado_por FOREIGN KEY (fpe_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ext_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ext', 'tesouraria.extrato_linha', '');
CREATE TRIGGER trg_ext_00_sem_delete BEFORE DELETE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ext');
CREATE TRIGGER trg_ext_00_sem_truncate BEFORE TRUNCATE ON tesouraria.extrato_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ext');
CREATE TRIGGER trg_ext_99_log AFTER UPDATE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ext');
ALTER TABLE tesouraria.extrato_linha ADD CONSTRAINT fk_ext_criado_por FOREIGN KEY (ext_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.extrato_linha ADD CONSTRAINT fk_ext_modificado_por FOREIGN KEY (ext_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_pmp_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pmp', 'pagamentos.pagamento_mpesa', '');
CREATE TRIGGER trg_pmp_00_sem_delete BEFORE DELETE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pmp');
CREATE TRIGGER trg_pmp_00_sem_truncate BEFORE TRUNCATE ON pagamentos.pagamento_mpesa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pmp');
CREATE TRIGGER trg_pmp_99_log AFTER UPDATE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pmp');
ALTER TABLE pagamentos.pagamento_mpesa ADD CONSTRAINT fk_pmp_criado_por FOREIGN KEY (pmp_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.pagamento_mpesa ADD CONSTRAINT fk_pmp_modificado_por FOREIGN KEY (pmp_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mcl_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mcl', 'pagamentos.mpesa_callback_log', '');
CREATE TRIGGER trg_mcl_00_sem_delete BEFORE DELETE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mcl');
CREATE TRIGGER trg_mcl_00_sem_truncate BEFORE TRUNCATE ON pagamentos.mpesa_callback_log FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mcl');
CREATE TRIGGER trg_mcl_99_log AFTER UPDATE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mcl');
ALTER TABLE pagamentos.mpesa_callback_log ADD CONSTRAINT fk_mcl_criado_por FOREIGN KEY (mcl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.mpesa_callback_log ADD CONSTRAINT fk_mcl_modificado_por FOREIGN KEY (mcl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_pba_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pba', 'pagamentos.pagamento_bancario', '');
CREATE TRIGGER trg_pba_00_sem_delete BEFORE DELETE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pba');
CREATE TRIGGER trg_pba_00_sem_truncate BEFORE TRUNCATE ON pagamentos.pagamento_bancario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pba');
CREATE TRIGGER trg_pba_99_log AFTER UPDATE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pba');
ALTER TABLE pagamentos.pagamento_bancario ADD CONSTRAINT fk_pba_criado_por FOREIGN KEY (pba_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.pagamento_bancario ADD CONSTRAINT fk_pba_modificado_por FOREIGN KEY (pba_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ntf_00_padrao BEFORE INSERT OR UPDATE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ntf', 'comunicacao.notificacao', 'ntf_igr_id');
CREATE TRIGGER trg_ntf_00_sem_delete BEFORE DELETE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ntf');
CREATE TRIGGER trg_ntf_00_sem_truncate BEFORE TRUNCATE ON comunicacao.notificacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ntf');
CREATE TRIGGER trg_ntf_99_log AFTER UPDATE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ntf');
ALTER TABLE comunicacao.notificacao ADD CONSTRAINT fk_ntf_criado_por FOREIGN KEY (ntf_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE comunicacao.notificacao ADD CONSTRAINT fk_ntf_modificado_por FOREIGN KEY (ntf_modificado_por) REFERENCES nucleo.usuario(usu_id);

-- Todas as funções do sistema resolvem nomes sempre da mesma forma, seja quem for que as chama
DO $$
DECLARE f RECORD;
BEGIN
    FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'pagamentos', 'comunicacao') LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public', f.sig);
    END LOOP;
    -- As funções de trigger validam com os privilégios do sistema (vêem todos os dados de que
    -- precisam para decidir); quem pode fazer o quê decide-se sempre pelo utilizador da sessão
    -- (políticas RLS da operação original e nucleo.fn_exigir).
    FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'pagamentos', 'comunicacao')
               AND p.prorettype = 'trigger'::regtype LOOP
        EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER', f.sig);
    END LOOP;
END $$;

-- >>>>> V11__permissoes_e_seguranca.sql
-- =====================================================================
-- V11 · Permissões e segurança por igreja (Row Level Security)
--
--   Cada tabela tem 4 permissões: <schema>.<tabela>.ler / criar / alterar / terminar.
--   Ler, criar e alterar são verificadas pelo PostgreSQL linha a linha, na igreja do registo.
--   Terminar (end_date) e as acções de negócio (aprovar, emitir carta, fechar relatório, ...)
--   são verificadas pelos triggers. Ninguém tem DELETE.
--   A API liga-se com um utilizador membro de app_igreja e, em cada transacção SQL:
--     SELECT set_config('app.usuario_id', '<usu_id>', true);
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_igreja') THEN CREATE ROLE app_igreja NOLOGIN; END IF; END $$;
GRANT USAGE ON SCHEMA nucleo TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA nucleo TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA nucleo TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nucleo TO app_igreja;
GRANT USAGE ON SCHEMA organizacao TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA organizacao TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA organizacao TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA organizacao TO app_igreja;
GRANT USAGE ON SCHEMA secretaria TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA secretaria TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA secretaria TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA secretaria TO app_igreja;
GRANT USAGE ON SCHEMA actividades TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA actividades TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA actividades TO app_igreja;
GRANT USAGE ON SCHEMA escola_sabatina TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA escola_sabatina TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA escola_sabatina TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA escola_sabatina TO app_igreja;
GRANT USAGE ON SCHEMA tesouraria TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA tesouraria TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tesouraria TO app_igreja;
GRANT USAGE ON SCHEMA pagamentos TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA pagamentos TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pagamentos TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pagamentos TO app_igreja;
GRANT USAGE ON SCHEMA comunicacao TO app_igreja;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA comunicacao TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA comunicacao TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA comunicacao TO app_igreja;
-- Tabelas escritas só pelo sistema
REVOKE INSERT, UPDATE ON tesouraria.saldo_diario_conta FROM app_igreja;
REVOKE INSERT, UPDATE ON tesouraria.saldo_diario_fundo FROM app_igreja;
REVOKE INSERT, UPDATE ON nucleo.log_auditoria FROM app_igreja;
ALTER FUNCTION nucleo.fn_log_auditoria() SECURITY DEFINER;
-- A senha nunca é legível pela API (o login usa nucleo.fn_credenciais)
REVOKE SELECT ON nucleo.usuario FROM app_igreja;
GRANT SELECT (usu_id, usu_mem_id, usu_nome, usu_email, usu_telefone, usu_super_admin, usu_ultimo_login, usu_estado, usu_criado_em, usu_criado_por, usu_modificado_em, usu_modificado_por, usu_end_date) ON nucleo.usuario TO app_igreja;

ALTER TABLE nucleo.perfil ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_per_ler ON nucleo.perfil FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_per_criar ON nucleo.perfil FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil.criar')));
CREATE POLICY pol_per_alterar ON nucleo.perfil FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil.alterar')));
ALTER TABLE nucleo.permissao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_prm_ler ON nucleo.permissao FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_prm_criar ON nucleo.permissao FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.permissao.criar')));
CREATE POLICY pol_prm_alterar ON nucleo.permissao FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.permissao.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.permissao.alterar')));
ALTER TABLE nucleo.perfil_permissao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ppe_ler ON nucleo.perfil_permissao FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_ppe_criar ON nucleo.perfil_permissao FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil_permissao.criar')));
CREATE POLICY pol_ppe_alterar ON nucleo.perfil_permissao FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil_permissao.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.perfil_permissao.alterar')));
ALTER TABLE nucleo.usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_usu_ler ON nucleo.usuario FOR SELECT USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario.ler')));
CREATE POLICY pol_usu_criar ON nucleo.usuario FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario.criar')));
CREATE POLICY pol_usu_alterar ON nucleo.usuario FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario.alterar')));
CREATE POLICY pol_usu_proprio ON nucleo.usuario FOR SELECT USING (usu_id = (SELECT nucleo.fn_usuario_sessao()));
CREATE POLICY pol_usu_proprio_alterar ON nucleo.usuario FOR UPDATE USING (usu_id = nucleo.fn_usuario_sessao()) WITH CHECK (usu_id = nucleo.fn_usuario_sessao());
ALTER TABLE nucleo.usuario_igreja ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_uig_ler ON nucleo.usuario_igreja FOR SELECT USING (uig_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('nucleo.usuario_igreja.ler'))::INT[]));
CREATE POLICY pol_uig_criar ON nucleo.usuario_igreja FOR INSERT WITH CHECK (uig_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('nucleo.usuario_igreja.criar'))::INT[]));
CREATE POLICY pol_uig_alterar ON nucleo.usuario_igreja FOR UPDATE USING (uig_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('nucleo.usuario_igreja.alterar'))::INT[])) WITH CHECK (uig_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('nucleo.usuario_igreja.alterar'))::INT[]));
ALTER TABLE nucleo.usuario_entidade ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_uen_ler ON nucleo.usuario_entidade FOR SELECT USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario_entidade.ler')));
CREATE POLICY pol_uen_criar ON nucleo.usuario_entidade FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario_entidade.criar')));
CREATE POLICY pol_uen_alterar ON nucleo.usuario_entidade FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario_entidade.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('nucleo.usuario_entidade.alterar')));
ALTER TABLE nucleo.log_auditoria ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_lau_ler ON nucleo.log_auditoria FOR SELECT USING ((SELECT nucleo.fn_tem_permissao_global('nucleo.log_auditoria.ler')));
ALTER TABLE organizacao.entidade ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ent_ler ON organizacao.entidade FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_ent_criar ON organizacao.entidade FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.entidade.criar')));
CREATE POLICY pol_ent_alterar ON organizacao.entidade FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('organizacao.entidade.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.entidade.alterar')));
ALTER TABLE organizacao.distrito ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dst_ler ON organizacao.distrito FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_dst_criar ON organizacao.distrito FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.distrito.criar')));
CREATE POLICY pol_dst_alterar ON organizacao.distrito FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('organizacao.distrito.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.distrito.alterar')));
ALTER TABLE organizacao.igreja ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_igr_ler ON organizacao.igreja FOR SELECT USING (igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja.ler'))::INT[]));
CREATE POLICY pol_igr_criar ON organizacao.igreja FOR INSERT WITH CHECK (igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja.criar'))::INT[]));
CREATE POLICY pol_igr_alterar ON organizacao.igreja FOR UPDATE USING (igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja.alterar'))::INT[])) WITH CHECK (igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja.alterar'))::INT[]));
ALTER TABLE organizacao.departamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dep_ler ON organizacao.departamento FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_dep_criar ON organizacao.departamento FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.departamento.criar')));
CREATE POLICY pol_dep_alterar ON organizacao.departamento FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('organizacao.departamento.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.departamento.alterar')));
ALTER TABLE organizacao.igreja_departamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ide_ler ON organizacao.igreja_departamento FOR SELECT USING (ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja_departamento.ler'))::INT[]));
CREATE POLICY pol_ide_criar ON organizacao.igreja_departamento FOR INSERT WITH CHECK (ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja_departamento.criar'))::INT[]));
CREATE POLICY pol_ide_alterar ON organizacao.igreja_departamento FOR UPDATE USING (ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja_departamento.alterar'))::INT[])) WITH CHECK (ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('organizacao.igreja_departamento.alterar'))::INT[]));
ALTER TABLE organizacao.cargo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_car_ler ON organizacao.cargo FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_car_criar ON organizacao.cargo FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.cargo.criar')));
CREATE POLICY pol_car_alterar ON organizacao.cargo FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('organizacao.cargo.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('organizacao.cargo.alterar')));
ALTER TABLE secretaria.familia ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_fam_ler ON secretaria.familia FOR SELECT USING (fam_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.familia.ler'))::INT[]));
CREATE POLICY pol_fam_criar ON secretaria.familia FOR INSERT WITH CHECK (fam_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.familia.criar'))::INT[]));
CREATE POLICY pol_fam_alterar ON secretaria.familia FOR UPDATE USING (fam_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.familia.alterar'))::INT[])) WITH CHECK (fam_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.familia.alterar'))::INT[]));
ALTER TABLE secretaria.membro ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_mem_ler ON secretaria.membro FOR SELECT USING (mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'))::INT[]));
CREATE POLICY pol_mem_criar ON secretaria.membro FOR INSERT WITH CHECK (mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.criar'))::INT[]));
CREATE POLICY pol_mem_alterar ON secretaria.membro FOR UPDATE USING (mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.alterar'))::INT[])) WITH CHECK (mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.alterar'))::INT[]));
CREATE POLICY pol_mem_proprio ON secretaria.membro FOR SELECT USING (mem_id = (SELECT nucleo.fn_membro_sessao()));
ALTER TABLE secretaria.contacto ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cto_ler ON secretaria.contacto FOR SELECT USING (cto_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.ler'))::INT[])) OR EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = cto_mem_id AND m.mem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.ler'))::INT[]))));
CREATE POLICY pol_cto_criar ON secretaria.contacto FOR INSERT WITH CHECK (cto_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.criar'))::INT[])) OR EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = cto_mem_id AND m.mem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.criar'))::INT[]))));
CREATE POLICY pol_cto_alterar ON secretaria.contacto FOR UPDATE USING (cto_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.alterar'))::INT[])) OR EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = cto_mem_id AND m.mem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.alterar'))::INT[])))) WITH CHECK (cto_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.alterar'))::INT[])) OR EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = cto_mem_id AND m.mem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.contacto.alterar'))::INT[]))));
CREATE POLICY pol_cto_proprio ON secretaria.contacto FOR SELECT USING (cto_mem_id = (SELECT nucleo.fn_membro_sessao()));
ALTER TABLE secretaria.consentimento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cns_ler ON secretaria.consentimento FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = cns_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.consentimento.ler'))::INT[])));
CREATE POLICY pol_cns_criar ON secretaria.consentimento FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = cns_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.consentimento.criar'))::INT[])));
CREATE POLICY pol_cns_alterar ON secretaria.consentimento FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = cns_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.consentimento.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = cns_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.consentimento.alterar'))::INT[])));
CREATE POLICY pol_cns_proprio ON secretaria.consentimento FOR SELECT USING (cns_mem_id = (SELECT nucleo.fn_membro_sessao()));
ALTER TABLE secretaria.reuniao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_reu_ler ON secretaria.reuniao FOR SELECT USING (reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao.ler'))::INT[]));
CREATE POLICY pol_reu_criar ON secretaria.reuniao FOR INSERT WITH CHECK (reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao.criar'))::INT[]));
CREATE POLICY pol_reu_alterar ON secretaria.reuniao FOR UPDATE USING (reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao.alterar'))::INT[])) WITH CHECK (reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao.alterar'))::INT[]));
ALTER TABLE secretaria.voto ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_vot_ler ON secretaria.voto FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = vot_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto.ler'))::INT[])));
CREATE POLICY pol_vot_criar ON secretaria.voto FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = vot_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto.criar'))::INT[])));
CREATE POLICY pol_vot_alterar ON secretaria.voto FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = vot_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = vot_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto.alterar'))::INT[])));
ALTER TABLE secretaria.movimento_membro ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_mmb_ler ON secretaria.movimento_membro FOR SELECT USING (mmb_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.ler'))::INT[]));
CREATE POLICY pol_mmb_criar ON secretaria.movimento_membro FOR INSERT WITH CHECK (mmb_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.criar'))::INT[]));
CREATE POLICY pol_mmb_alterar ON secretaria.movimento_membro FOR UPDATE USING (mmb_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.alterar'))::INT[])) WITH CHECK (mmb_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.alterar'))::INT[]));
ALTER TABLE secretaria.transferencia_membro ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_tme_ler ON secretaria.transferencia_membro FOR SELECT USING (tme_origem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[])) OR tme_destino_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[])));
CREATE POLICY pol_tme_criar ON secretaria.transferencia_membro FOR INSERT WITH CHECK (tme_origem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.criar'))::INT[])) OR tme_destino_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.criar'))::INT[])));
CREATE POLICY pol_tme_alterar ON secretaria.transferencia_membro FOR UPDATE USING (tme_origem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.alterar'))::INT[])) OR tme_destino_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.alterar'))::INT[]))) WITH CHECK (tme_origem_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.alterar'))::INT[])) OR tme_destino_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.alterar'))::INT[])));
ALTER TABLE secretaria.disciplina ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dsc_ler ON secretaria.disciplina FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = dsc_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.disciplina.ler'))::INT[])));
CREATE POLICY pol_dsc_criar ON secretaria.disciplina FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = dsc_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.disciplina.criar'))::INT[])));
CREATE POLICY pol_dsc_alterar ON secretaria.disciplina FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = dsc_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.disciplina.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = dsc_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.disciplina.alterar'))::INT[])));
ALTER TABLE secretaria.oficial ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ofi_ler ON secretaria.oficial FOR SELECT USING (ofi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.oficial.ler'))::INT[]));
CREATE POLICY pol_ofi_criar ON secretaria.oficial FOR INSERT WITH CHECK (ofi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.oficial.criar'))::INT[]));
CREATE POLICY pol_ofi_alterar ON secretaria.oficial FOR UPDATE USING (ofi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.oficial.alterar'))::INT[])) WITH CHECK (ofi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.oficial.alterar'))::INT[]));
ALTER TABLE secretaria.baptismo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_bap_ler ON secretaria.baptismo FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = bap_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.baptismo.ler'))::INT[])));
CREATE POLICY pol_bap_criar ON secretaria.baptismo FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = bap_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.baptismo.criar'))::INT[])));
CREATE POLICY pol_bap_alterar ON secretaria.baptismo FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = bap_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.baptismo.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.membro x WHERE x.mem_id = bap_mem_id AND x.mem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.baptismo.alterar'))::INT[])));
ALTER TABLE actividades.actividade ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_act_ler ON actividades.actividade FOR SELECT USING (EXISTS (SELECT 1 FROM organizacao.igreja_departamento x WHERE x.ide_id = act_ide_id AND x.ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.ler'))::INT[])));
CREATE POLICY pol_act_criar ON actividades.actividade FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM organizacao.igreja_departamento x WHERE x.ide_id = act_ide_id AND x.ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.criar'))::INT[])));
CREATE POLICY pol_act_alterar ON actividades.actividade FOR UPDATE USING (EXISTS (SELECT 1 FROM organizacao.igreja_departamento x WHERE x.ide_id = act_ide_id AND x.ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM organizacao.igreja_departamento x WHERE x.ide_id = act_ide_id AND x.ide_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[])));
ALTER TABLE actividades.material ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_mat_ler ON actividades.material FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.ler'))::INT[]))));
CREATE POLICY pol_mat_criar ON actividades.material FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.criar'))::INT[]))));
CREATE POLICY pol_mat_alterar ON actividades.material FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[])))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[]))));
ALTER TABLE actividades.escala ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_esc_ler ON actividades.escala FOR SELECT USING (esc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala.ler'))::INT[]));
CREATE POLICY pol_esc_criar ON actividades.escala FOR INSERT WITH CHECK (esc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala.criar'))::INT[]));
CREATE POLICY pol_esc_alterar ON actividades.escala FOR UPDATE USING (esc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala.alterar'))::INT[])) WITH CHECK (esc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala.alterar'))::INT[]));
CREATE POLICY pol_esc_proprio ON actividades.escala FOR SELECT USING ((SELECT nucleo.fn_membro_sessao()) IN (esc_mem_id, esc_substituto_mem_id));
ALTER TABLE escola_sabatina.trimestre ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_etr_ler ON escola_sabatina.trimestre FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_etr_criar ON escola_sabatina.trimestre FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.trimestre.criar')));
CREATE POLICY pol_etr_alterar ON escola_sabatina.trimestre FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.trimestre.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.trimestre.alterar')));
ALTER TABLE escola_sabatina.sabado ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_esa_ler ON escola_sabatina.sabado FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_esa_criar ON escola_sabatina.sabado FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.sabado.criar')));
CREATE POLICY pol_esa_alterar ON escola_sabatina.sabado FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.sabado.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.sabado.alterar')));
ALTER TABLE escola_sabatina.classe ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ecl_ler ON escola_sabatina.classe FOR SELECT USING (ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe.ler'))::INT[]));
CREATE POLICY pol_ecl_criar ON escola_sabatina.classe FOR INSERT WITH CHECK (ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe.criar'))::INT[]));
CREATE POLICY pol_ecl_alterar ON escola_sabatina.classe FOR UPDATE USING (ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe.alterar'))::INT[])) WITH CHECK (ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe.alterar'))::INT[]));
ALTER TABLE escola_sabatina.classe_trimestre ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ect_ler ON escola_sabatina.classe_trimestre FOR SELECT USING (ect_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe_trimestre.ler'))::INT[]));
CREATE POLICY pol_ect_criar ON escola_sabatina.classe_trimestre FOR INSERT WITH CHECK (ect_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe_trimestre.criar'))::INT[]));
CREATE POLICY pol_ect_alterar ON escola_sabatina.classe_trimestre FOR UPDATE USING (ect_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe_trimestre.alterar'))::INT[])) WITH CHECK (ect_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.classe_trimestre.alterar'))::INT[]));
ALTER TABLE escola_sabatina.matricula ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ema_ler ON escola_sabatina.matricula FOR SELECT USING (EXISTS (SELECT 1 FROM escola_sabatina.classe x WHERE x.ecl_id = ema_ecl_id AND x.ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.matricula.ler'))::INT[])));
CREATE POLICY pol_ema_criar ON escola_sabatina.matricula FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM escola_sabatina.classe x WHERE x.ecl_id = ema_ecl_id AND x.ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.matricula.criar'))::INT[])));
CREATE POLICY pol_ema_alterar ON escola_sabatina.matricula FOR UPDATE USING (EXISTS (SELECT 1 FROM escola_sabatina.classe x WHERE x.ecl_id = ema_ecl_id AND x.ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.matricula.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM escola_sabatina.classe x WHERE x.ecl_id = ema_ecl_id AND x.ecl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.matricula.alterar'))::INT[])));
CREATE POLICY pol_ema_proprio ON escola_sabatina.matricula FOR SELECT USING (ema_mem_id = (SELECT nucleo.fn_membro_sessao()));
ALTER TABLE escola_sabatina.relatorio_sabado ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ers_ler ON escola_sabatina.relatorio_sabado FOR SELECT USING (ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.relatorio_sabado.ler'))::INT[]));
CREATE POLICY pol_ers_criar ON escola_sabatina.relatorio_sabado FOR INSERT WITH CHECK (ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.relatorio_sabado.criar'))::INT[]));
CREATE POLICY pol_ers_alterar ON escola_sabatina.relatorio_sabado FOR UPDATE USING (ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.relatorio_sabado.alterar'))::INT[])) WITH CHECK (ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.relatorio_sabado.alterar'))::INT[]));
ALTER TABLE escola_sabatina.presenca ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_epr_ler ON escola_sabatina.presenca FOR SELECT USING (epr_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.presenca.ler'))::INT[]));
CREATE POLICY pol_epr_criar ON escola_sabatina.presenca FOR INSERT WITH CHECK (epr_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.presenca.criar'))::INT[]));
CREATE POLICY pol_epr_alterar ON escola_sabatina.presenca FOR UPDATE USING (epr_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.presenca.alterar'))::INT[])) WITH CHECK (epr_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.presenca.alterar'))::INT[]));
CREATE POLICY pol_epr_proprio ON escola_sabatina.presenca FOR SELECT USING (epr_mem_id = (SELECT nucleo.fn_membro_sessao()));
ALTER TABLE escola_sabatina.visitante ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_evi_ler ON escola_sabatina.visitante FOR SELECT USING (EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado x WHERE x.ers_id = evi_ers_id AND x.ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.visitante.ler'))::INT[])));
CREATE POLICY pol_evi_criar ON escola_sabatina.visitante FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado x WHERE x.ers_id = evi_ers_id AND x.ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.visitante.criar'))::INT[])));
CREATE POLICY pol_evi_alterar ON escola_sabatina.visitante FOR UPDATE USING (EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado x WHERE x.ers_id = evi_ers_id AND x.ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.visitante.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado x WHERE x.ers_id = evi_ers_id AND x.ers_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.visitante.alterar'))::INT[])));
ALTER TABLE escola_sabatina.pontuacao_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_epc_ler ON escola_sabatina.pontuacao_config FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_epc_criar ON escola_sabatina.pontuacao_config FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.pontuacao_config.criar')));
CREATE POLICY pol_epc_alterar ON escola_sabatina.pontuacao_config FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.pontuacao_config.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('escola_sabatina.pontuacao_config.alterar')));
ALTER TABLE tesouraria.conta_financeira ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cfi_ler ON tesouraria.conta_financeira FOR SELECT USING (cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.conta_financeira.ler'))::INT[]));
CREATE POLICY pol_cfi_criar ON tesouraria.conta_financeira FOR INSERT WITH CHECK (cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.conta_financeira.criar'))::INT[]));
CREATE POLICY pol_cfi_alterar ON tesouraria.conta_financeira FOR UPDATE USING (cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.conta_financeira.alterar'))::INT[])) WITH CHECK (cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.conta_financeira.alterar'))::INT[]));
ALTER TABLE tesouraria.fundo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_fun_ler ON tesouraria.fundo FOR SELECT USING (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.ler'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('tesouraria.fundo.ler'))));
CREATE POLICY pol_fun_criar ON tesouraria.fundo FOR INSERT WITH CHECK (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.criar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('tesouraria.fundo.criar'))));
CREATE POLICY pol_fun_alterar ON tesouraria.fundo FOR UPDATE USING (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.alterar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('tesouraria.fundo.alterar')))) WITH CHECK (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.alterar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('tesouraria.fundo.alterar'))));
CREATE POLICY pol_fun_proprio ON tesouraria.fundo FOR SELECT USING (TRUE);
ALTER TABLE tesouraria.calendario_oferta ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cof_ler ON tesouraria.calendario_oferta FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_cof_criar ON tesouraria.calendario_oferta FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('tesouraria.calendario_oferta.criar')));
CREATE POLICY pol_cof_alterar ON tesouraria.calendario_oferta FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('tesouraria.calendario_oferta.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('tesouraria.calendario_oferta.alterar')));
ALTER TABLE tesouraria.categoria ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cat_ler ON tesouraria.categoria FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_cat_criar ON tesouraria.categoria FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('tesouraria.categoria.criar')));
CREATE POLICY pol_cat_alterar ON tesouraria.categoria FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('tesouraria.categoria.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('tesouraria.categoria.alterar')));
ALTER TABLE tesouraria.alvo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_alv_ler ON tesouraria.alvo FOR SELECT USING (alv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.alvo.ler'))::INT[]));
CREATE POLICY pol_alv_criar ON tesouraria.alvo FOR INSERT WITH CHECK (alv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.alvo.criar'))::INT[]));
CREATE POLICY pol_alv_alterar ON tesouraria.alvo FOR UPDATE USING (alv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.alvo.alterar'))::INT[])) WITH CHECK (alv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.alvo.alterar'))::INT[]));
ALTER TABLE tesouraria.orcamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_orc_ler ON tesouraria.orcamento FOR SELECT USING (orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.ler'))::INT[]));
CREATE POLICY pol_orc_criar ON tesouraria.orcamento FOR INSERT WITH CHECK (orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.criar'))::INT[]));
CREATE POLICY pol_orc_alterar ON tesouraria.orcamento FOR UPDATE USING (orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.alterar'))::INT[])) WITH CHECK (orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.alterar'))::INT[]));
ALTER TABLE tesouraria.orcamento_linha ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_orl_ler ON tesouraria.orcamento_linha FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.orcamento x WHERE x.orc_id = orl_orc_id AND x.orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento_linha.ler'))::INT[])));
CREATE POLICY pol_orl_criar ON tesouraria.orcamento_linha FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.orcamento x WHERE x.orc_id = orl_orc_id AND x.orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento_linha.criar'))::INT[])));
CREATE POLICY pol_orl_alterar ON tesouraria.orcamento_linha FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.orcamento x WHERE x.orc_id = orl_orc_id AND x.orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento_linha.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.orcamento x WHERE x.orc_id = orl_orc_id AND x.orc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento_linha.alterar'))::INT[])));
ALTER TABLE tesouraria.despesa ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_des_ler ON tesouraria.despesa FOR SELECT USING (des_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.ler'))::INT[]));
CREATE POLICY pol_des_criar ON tesouraria.despesa FOR INSERT WITH CHECK (des_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.criar'))::INT[]));
CREATE POLICY pol_des_alterar ON tesouraria.despesa FOR UPDATE USING (des_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.alterar'))::INT[])) WITH CHECK (des_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.alterar'))::INT[]));
ALTER TABLE tesouraria.contagem_numerario ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cnu_ler ON tesouraria.contagem_numerario FOR SELECT USING (cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.ler'))::INT[]));
CREATE POLICY pol_cnu_criar ON tesouraria.contagem_numerario FOR INSERT WITH CHECK (cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.criar'))::INT[]));
CREATE POLICY pol_cnu_alterar ON tesouraria.contagem_numerario FOR UPDATE USING (cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.alterar'))::INT[])) WITH CHECK (cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.alterar'))::INT[]));
ALTER TABLE tesouraria.transacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_tra_ler ON tesouraria.transacao FOR SELECT USING (tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler'))::INT[]));
CREATE POLICY pol_tra_criar ON tesouraria.transacao FOR INSERT WITH CHECK (tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.criar'))::INT[]));
CREATE POLICY pol_tra_alterar ON tesouraria.transacao FOR UPDATE USING (tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.alterar'))::INT[])) WITH CHECK (tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.alterar'))::INT[]));
CREATE POLICY pol_tra_proprio ON tesouraria.transacao FOR SELECT USING (tra_mem_id = (SELECT nucleo.fn_membro_sessao()) OR tra_fam_id = (SELECT nucleo.fn_familia_sessao()));
ALTER TABLE tesouraria.transacao_linha ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_tli_ler ON tesouraria.transacao_linha FOR SELECT USING (tli_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao_linha.ler'))::INT[]));
CREATE POLICY pol_tli_criar ON tesouraria.transacao_linha FOR INSERT WITH CHECK (tli_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao_linha.criar'))::INT[]));
CREATE POLICY pol_tli_alterar ON tesouraria.transacao_linha FOR UPDATE USING (tli_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao_linha.alterar'))::INT[])) WITH CHECK (tli_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao_linha.alterar'))::INT[]));
CREATE POLICY pol_tli_proprio ON tesouraria.transacao_linha FOR SELECT USING (tli_tra_id IN (SELECT x.tra_id FROM tesouraria.transacao x WHERE x.tra_mem_id = (SELECT nucleo.fn_membro_sessao()) OR x.tra_fam_id = (SELECT nucleo.fn_familia_sessao())));
ALTER TABLE tesouraria.saldo_diario_conta ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_sdc_ler ON tesouraria.saldo_diario_conta FOR SELECT USING (sdc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.saldo_diario_conta.ler'))::INT[]));
ALTER TABLE tesouraria.saldo_diario_fundo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_sdf_ler ON tesouraria.saldo_diario_fundo FOR SELECT USING (sdf_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.saldo_diario_fundo.ler'))::INT[]));
ALTER TABLE tesouraria.recibo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rec_ler ON tesouraria.recibo FOR SELECT USING (rec_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.recibo.ler'))::INT[]));
CREATE POLICY pol_rec_criar ON tesouraria.recibo FOR INSERT WITH CHECK (rec_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.recibo.criar'))::INT[]));
CREATE POLICY pol_rec_alterar ON tesouraria.recibo FOR UPDATE USING (rec_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.recibo.alterar'))::INT[])) WITH CHECK (rec_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.recibo.alterar'))::INT[]));
CREATE POLICY pol_rec_proprio ON tesouraria.recibo FOR SELECT USING (rec_tra_id IN (SELECT x.tra_id FROM tesouraria.transacao x WHERE x.tra_mem_id = (SELECT nucleo.fn_membro_sessao()) OR x.tra_fam_id = (SELECT nucleo.fn_familia_sessao())));
ALTER TABLE tesouraria.documento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_doc_ler ON tesouraria.documento FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = doc_tra_id AND x.tra_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.ler'))::INT[]))) OR EXISTS (SELECT 1 FROM tesouraria.despesa x WHERE x.des_id = doc_des_id AND x.des_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.ler'))::INT[]))));
CREATE POLICY pol_doc_criar ON tesouraria.documento FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = doc_tra_id AND x.tra_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.criar'))::INT[]))) OR EXISTS (SELECT 1 FROM tesouraria.despesa x WHERE x.des_id = doc_des_id AND x.des_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.criar'))::INT[]))));
CREATE POLICY pol_doc_alterar ON tesouraria.documento FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = doc_tra_id AND x.tra_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.alterar'))::INT[]))) OR EXISTS (SELECT 1 FROM tesouraria.despesa x WHERE x.des_id = doc_des_id AND x.des_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.alterar'))::INT[])))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = doc_tra_id AND x.tra_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.alterar'))::INT[]))) OR EXISTS (SELECT 1 FROM tesouraria.despesa x WHERE x.des_id = doc_des_id AND x.des_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.documento.alterar'))::INT[]))));
ALTER TABLE tesouraria.remessa ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rem_ler ON tesouraria.remessa FOR SELECT USING (rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa.ler'))::INT[]));
CREATE POLICY pol_rem_criar ON tesouraria.remessa FOR INSERT WITH CHECK (rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa.criar'))::INT[]));
CREATE POLICY pol_rem_alterar ON tesouraria.remessa FOR UPDATE USING (rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa.alterar'))::INT[])) WITH CHECK (rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa.alterar'))::INT[]));
ALTER TABLE tesouraria.remessa_linha ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rml_ler ON tesouraria.remessa_linha FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.remessa x WHERE x.rem_id = rml_rem_id AND x.rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa_linha.ler'))::INT[])));
CREATE POLICY pol_rml_criar ON tesouraria.remessa_linha FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.remessa x WHERE x.rem_id = rml_rem_id AND x.rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa_linha.criar'))::INT[])));
CREATE POLICY pol_rml_alterar ON tesouraria.remessa_linha FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.remessa x WHERE x.rem_id = rml_rem_id AND x.rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa_linha.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.remessa x WHERE x.rem_id = rml_rem_id AND x.rem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.remessa_linha.alterar'))::INT[])));
ALTER TABLE tesouraria.fecho_periodo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_fpe_ler ON tesouraria.fecho_periodo FOR SELECT USING (fpe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fecho_periodo.ler'))::INT[]));
CREATE POLICY pol_fpe_criar ON tesouraria.fecho_periodo FOR INSERT WITH CHECK (fpe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fecho_periodo.criar'))::INT[]));
CREATE POLICY pol_fpe_alterar ON tesouraria.fecho_periodo FOR UPDATE USING (fpe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fecho_periodo.alterar'))::INT[])) WITH CHECK (fpe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fecho_periodo.alterar'))::INT[]));
ALTER TABLE tesouraria.extrato_linha ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ext_ler ON tesouraria.extrato_linha FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.conta_financeira x WHERE x.cfi_id = ext_cfi_id AND x.cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.extrato_linha.ler'))::INT[])));
CREATE POLICY pol_ext_criar ON tesouraria.extrato_linha FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.conta_financeira x WHERE x.cfi_id = ext_cfi_id AND x.cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.extrato_linha.criar'))::INT[])));
CREATE POLICY pol_ext_alterar ON tesouraria.extrato_linha FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.conta_financeira x WHERE x.cfi_id = ext_cfi_id AND x.cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.extrato_linha.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.conta_financeira x WHERE x.cfi_id = ext_cfi_id AND x.cfi_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.extrato_linha.alterar'))::INT[])));
ALTER TABLE pagamentos.pagamento_mpesa ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pmp_ler ON pagamentos.pagamento_mpesa FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pmp_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_mpesa.ler'))::INT[])));
CREATE POLICY pol_pmp_criar ON pagamentos.pagamento_mpesa FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pmp_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_mpesa.criar'))::INT[])));
CREATE POLICY pol_pmp_alterar ON pagamentos.pagamento_mpesa FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pmp_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_mpesa.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pmp_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_mpesa.alterar'))::INT[])));
ALTER TABLE pagamentos.mpesa_callback_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_mcl_ler ON pagamentos.mpesa_callback_log FOR SELECT USING ((SELECT nucleo.fn_tem_permissao_global('pagamentos.mpesa_callback_log.ler')));
CREATE POLICY pol_mcl_criar ON pagamentos.mpesa_callback_log FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('pagamentos.mpesa_callback_log.criar')));
CREATE POLICY pol_mcl_alterar ON pagamentos.mpesa_callback_log FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_global('pagamentos.mpesa_callback_log.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_global('pagamentos.mpesa_callback_log.alterar')));
ALTER TABLE pagamentos.pagamento_bancario ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pba_ler ON pagamentos.pagamento_bancario FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pba_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_bancario.ler'))::INT[])));
CREATE POLICY pol_pba_criar ON pagamentos.pagamento_bancario FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pba_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_bancario.criar'))::INT[])));
CREATE POLICY pol_pba_alterar ON pagamentos.pagamento_bancario FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pba_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_bancario.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = pba_tra_id AND x.tra_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('pagamentos.pagamento_bancario.alterar'))::INT[])));
ALTER TABLE comunicacao.notificacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ntf_ler ON comunicacao.notificacao FOR SELECT USING (ntf_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('comunicacao.notificacao.ler'))::INT[]));
CREATE POLICY pol_ntf_criar ON comunicacao.notificacao FOR INSERT WITH CHECK (ntf_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('comunicacao.notificacao.criar'))::INT[]));
CREATE POLICY pol_ntf_alterar ON comunicacao.notificacao FOR UPDATE USING (ntf_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('comunicacao.notificacao.alterar'))::INT[])) WITH CHECK (ntf_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('comunicacao.notificacao.alterar'))::INT[]));
-- Tabelas comuns (lidas por qualquer utilizador autenticado): escola_sabatina.pontuacao_config, escola_sabatina.sabado, escola_sabatina.trimestre, nucleo.perfil, nucleo.perfil_permissao, nucleo.permissao, organizacao.cargo, organizacao.departamento, organizacao.distrito, organizacao.entidade, tesouraria.calendario_oferta, tesouraria.categoria

-- >>>>> V12__vistas.sql
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- =====================================================================
-- Vistas por módulo (security_invoker: respeitam a segurança por igreja)
-- Registos com end_date não entram nas contas.
-- =====================================================================

-- ================================================================ secretaria
CREATE VIEW secretaria.vw_familia_resumo WITH (security_invoker = true) AS
SELECT f.fam_id, f.fam_igr_id, f.fam_nome,
       COUNT(m.mem_id)                                         AS membros_activos,
       COUNT(m.mem_id) FILTER (WHERE m.mem_modo_entrada IN ('BAPTISMO', 'REBAPTISMO')
                               OR EXISTS (SELECT 1 FROM secretaria.baptismo b
                                          WHERE b.bap_mem_id = m.mem_id AND b.bap_end_date IS NULL)) AS baptizados
FROM secretaria.familia f
LEFT JOIN secretaria.membro m ON m.mem_fam_id = f.fam_id AND m.mem_end_date IS NULL AND m.mem_estado = 'ACTIVO'
WHERE f.fam_end_date IS NULL
GROUP BY f.fam_id, f.fam_igr_id, f.fam_nome;

CREATE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado
FROM secretaria.membro WHERE mem_end_date IS NULL;

-- Relatório mensal do secretário à Associação/Missão: entradas e saídas do livro de membros
CREATE VIEW secretaria.vw_relatorio_mensal_membros WITH (security_invoker = true) AS
SELECT m.mmb_igr_id AS igr_id,
       EXTRACT(YEAR FROM m.mmb_data)::INT  AS ano,
       EXTRACT(MONTH FROM m.mmb_data)::INT AS mes,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'BAPTISMO')              AS baptismos,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'REBAPTISMO')            AS rebaptismos,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'PROFISSAO_FE')          AS profissoes_de_fe,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transferencias_entrada,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transferencias_saida,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'FALECIMENTO')           AS falecimentos,
       COUNT(*) FILTER (WHERE m.mmb_tipo IN ('REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO')) AS remocoes,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'DESAPARECIDO')          AS desaparecidos,
       COUNT(*) FILTER (WHERE m.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA'))
     - COUNT(*) FILTER (WHERE m.mmb_tipo NOT IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA')) AS variacao
FROM secretaria.movimento_membro m
WHERE m.mmb_end_date IS NULL
GROUP BY 1, 2, 3;

-- Cartas emitidas ainda por concluir (válidas 6 meses)
CREATE VIEW secretaria.vw_cartas_pendentes WITH (security_invoker = true) AS
SELECT t.tme_id, t.tme_origem_igr_id, t.tme_destino_igr_id, t.tme_destino_externo,
       m.mem_nome || ' ' || m.mem_apelido AS membro, t.tme_carta_emitida_em,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date AS valida_ate,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date < CURRENT_DATE AS expirada
FROM secretaria.transferencia_membro t
JOIN secretaria.membro m ON m.mem_id = t.tme_mem_id
WHERE t.tme_end_date IS NULL AND t.tme_estado = 'CARTA_EMITIDA';

CREATE VIEW secretaria.vw_censuras_activas WITH (security_invoker = true) AS
SELECT d.dsc_id, m.mem_igr_id, d.dsc_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       d.dsc_data_inicio, d.dsc_data_fim
FROM secretaria.disciplina d
JOIN secretaria.membro m ON m.mem_id = d.dsc_mem_id
WHERE d.dsc_end_date IS NULL AND CURRENT_DATE >= d.dsc_data_inicio AND CURRENT_DATE < d.dsc_data_fim;

-- Mandatos que terminam nos próximos 60 dias (para a comissão de nomeações)
CREATE VIEW secretaria.vw_mandatos_a_terminar WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, c.car_nome AS cargo, m.mem_nome || ' ' || m.mem_apelido AS membro,
       o.ofi_data_inicio, (o.ofi_data_inicio + make_interval(years => c.car_mandato_anos))::date AS fim_previsto
FROM secretaria.oficial o
JOIN organizacao.cargo c ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m ON m.mem_id = o.ofi_mem_id
WHERE o.ofi_end_date IS NULL AND o.ofi_data_fim IS NULL
  AND o.ofi_data_inicio + make_interval(years => c.car_mandato_anos) < CURRENT_DATE + 60;

CREATE VIEW secretaria.vw_menores_pendentes WITH (security_invoker = true) AS
SELECT m.mem_id, m.mem_igr_id, m.mem_nome, m.mem_apelido, m.mem_data_nascimento,
       (m.mem_encarregado_mem_id IS NULL) AS falta_encarregado,
       NOT EXISTS (SELECT 1 FROM secretaria.consentimento c
                   WHERE c.cns_mem_id = m.mem_id AND c.cns_end_date IS NULL
                     AND c.cns_tipo = 'DADOS_PESSOAIS' AND c.cns_concedido
                     AND c.cns_concedido_por_mem_id IS NOT NULL) AS falta_consentimento
FROM secretaria.membro m
WHERE m.mem_end_date IS NULL
  AND m.mem_data_nascimento > CURRENT_DATE - INTERVAL '18 years'
  AND (m.mem_encarregado_mem_id IS NULL
       OR NOT EXISTS (SELECT 1 FROM secretaria.consentimento c
                      WHERE c.cns_mem_id = m.mem_id AND c.cns_end_date IS NULL
                        AND c.cns_tipo = 'DADOS_PESSOAIS' AND c.cns_concedido
                        AND c.cns_concedido_por_mem_id IS NOT NULL));

-- ================================================================ actividades
CREATE VIEW actividades.vw_escala_proximas WITH (security_invoker = true) AS
SELECT e.esc_id, e.esc_igr_id, e.esc_data, e.esc_funcao,
       m.mem_nome || ' ' || m.mem_apelido AS membro, e.esc_estado
FROM actividades.escala e
JOIN secretaria.membro m ON m.mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
WHERE e.esc_end_date IS NULL AND e.esc_data BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
  AND e.esc_estado IN ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA');

-- ================================================================ escola_sabatina
CREATE VIEW escola_sabatina.vw_resumo_classe WITH (security_invoker = true) AS
SELECT ct.ect_id, ct.ect_etr_id, ct.ect_igr_id, c.ecl_nome AS classe, c.ecl_divisao AS divisao,
       (ct.ect_estado = 'ACTIVO')                                  AS activa,
       TRIM(CONCAT(p.mem_nome, ' ', p.mem_apelido))                AS professor,
       COUNT(r.ers_id)                                             AS sabados_registados,
       ROUND(AVG(r.ers_membros_matriculados), 2)                   AS media_matriculados,
       ROUND(AVG(r.ers_membros_presentes), 2)                      AS media_presentes,
       SUM(r.ers_membros_presentes)::NUMERIC / NULLIF(SUM(r.ers_membros_matriculados), 0) AS pct_presenca,
       SUM(r.ers_estudo_diario)::NUMERIC     / NULLIF(SUM(r.ers_membros_presentes), 0)    AS pct_estudo_diario,
       COALESCE(SUM(r.ers_visitantes), 0)                          AS visitantes,
       ROUND(AVG(r.ers_filiais), 2)                                AS media_filiais,
       COALESCE(SUM(r.ers_oferta), 0)                              AS ofertas,
       ct.ect_alvo_oferta_sabado * COUNT(r.ers_id)                 AS alvo_ofertas,
       COALESCE(SUM(r.ers_oferta), 0) / NULLIF(ct.ect_alvo_oferta_sabado * COUNT(r.ers_id), 0) AS pct_alvo_ofertas,
       COALESCE(SUM(r.ers_oferta_13_sabado), 0)                    AS oferta_13_sabado,
       COALESCE(SUM(r.ers_oferta_despesas), 0)                     AS oferta_despesas,
       (SELECT COUNT(*) FROM secretaria.baptismo b WHERE b.bap_ect_id = ct.ect_id AND b.bap_end_date IS NULL) AS baptismos,
       ct.ect_alvo_baptismos                                       AS alvo_baptismos,
       ct.ect_alvo_membros                                         AS alvo_membros
FROM escola_sabatina.classe_trimestre ct
JOIN escola_sabatina.classe c                ON c.ecl_id = ct.ect_ecl_id
LEFT JOIN secretaria.membro p                ON p.mem_id = ct.ect_professor_mem_id
LEFT JOIN escola_sabatina.relatorio_sabado r ON r.ers_ect_id = ct.ect_id AND r.ers_end_date IS NULL
WHERE ct.ect_end_date IS NULL AND c.ecl_end_date IS NULL
GROUP BY ct.ect_id, ct.ect_etr_id, ct.ect_igr_id, c.ecl_nome, c.ecl_divisao, ct.ect_estado, p.mem_nome, p.mem_apelido,
         ct.ect_alvo_oferta_sabado, ct.ect_alvo_baptismos, ct.ect_alvo_membros;

CREATE VIEW escola_sabatina.vw_classificacao WITH (security_invoker = true) AS
WITH pesos AS (
    SELECT t.etr_id,
           COALESCE(ct.epc_peso_presenca,   cd.epc_peso_presenca,   0.30) AS wp,
           COALESCE(ct.epc_peso_estudo,     cd.epc_peso_estudo,     0.30) AS we,
           COALESCE(ct.epc_peso_ofertas,    cd.epc_peso_ofertas,    0.25) AS wo,
           COALESCE(ct.epc_peso_visitantes, cd.epc_peso_visitantes, 0.15) AS wv,
           COALESCE(ct.epc_limite_ofertas,  cd.epc_limite_ofertas,  1.20) AS lim
    FROM escola_sabatina.trimestre t
    LEFT JOIN escola_sabatina.pontuacao_config ct ON ct.epc_etr_id = t.etr_id AND ct.epc_end_date IS NULL
    LEFT JOIN escola_sabatina.pontuacao_config cd ON cd.epc_etr_id IS NULL    AND cd.epc_end_date IS NULL
),
base AS (
    SELECT r.*, MAX(r.visitantes) OVER (PARTITION BY r.ect_etr_id, r.ect_igr_id) AS max_visitantes
    FROM escola_sabatina.vw_resumo_classe r
    WHERE r.activa AND r.sabados_registados > 0
),
pont AS (
    SELECT b.*,
           ROUND(100 * (
               p.wp * LEAST(COALESCE(b.pct_presenca, 0), 1)
             + p.we * LEAST(COALESCE(b.pct_estudo_diario, 0), 1)
             + p.wo * LEAST(COALESCE(b.pct_alvo_ofertas, 0), p.lim) / p.lim
             + p.wv * COALESCE(b.visitantes::NUMERIC / NULLIF(b.max_visitantes, 0), 0)), 1) AS pontuacao
    FROM base b JOIN pesos p ON p.etr_id = b.ect_etr_id
)
SELECT ect_id, ect_etr_id, ect_igr_id, classe, divisao, professor, pontuacao,
       RANK() OVER w                                               AS lugar,
       ROUND(pct_presenca      - AVG(pct_presenca)      OVER g, 4) AS dif_presenca_media,
       ROUND(pct_estudo_diario - AVG(pct_estudo_diario) OVER g, 4) AS dif_estudo_media,
       ROUND(ofertas - AVG(ofertas) OVER g, 2)                     AS dif_ofertas_media,
       MAX(pontuacao) OVER g - pontuacao                           AS pontos_atras_do_1o,
       CASE WHEN pontuacao >= AVG(pontuacao) OVER g THEN 'Acima da média' ELSE 'Abaixo da média' END AS situacao
FROM pont
WINDOW w AS (PARTITION BY ect_etr_id, ect_igr_id ORDER BY pontuacao DESC),
       g AS (PARTITION BY ect_etr_id, ect_igr_id);

-- Relatório trimestral (painel) por igreja
CREATE VIEW escola_sabatina.vw_painel WITH (security_invoker = true) AS
SELECT t.etr_id, t.etr_ano AS ano, t.etr_numero AS trimestre, r.ect_igr_id AS igr_id,
       COUNT(*)                            AS classes_activas,
       ROUND(SUM(r.media_matriculados), 1) AS membros,
       ROUND(AVG(r.pct_presenca), 4)       AS presenca_media,
       ROUND(AVG(r.pct_estudo_diario), 4)  AS estudo_diario_medio,
       SUM(r.ofertas)                      AS ofertas_missionarias,
       SUM(r.oferta_13_sabado)             AS oferta_13_sabado,
       SUM(r.oferta_despesas)              AS oferta_despesas,
       SUM(r.visitantes)                   AS visitantes,
       SUM(r.baptismos)                    AS baptismos,
       SUM(r.alvo_baptismos)               AS alvo_baptismos
FROM escola_sabatina.vw_resumo_classe r
JOIN escola_sabatina.trimestre t ON t.etr_id = r.ect_etr_id
WHERE r.activa AND r.sabados_registados > 0
GROUP BY t.etr_id, t.etr_ano, t.etr_numero, r.ect_igr_id;

-- Relatório trimestral consolidado por Associação/Missão e por divisão da ES
CREATE VIEW escola_sabatina.vw_relatorio_associacao WITH (security_invoker = true) AS
SELECT i.igr_ent_id AS ent_id, r.ect_etr_id AS etr_id, r.divisao,
       COUNT(DISTINCT r.ect_igr_id)        AS igrejas,
       COUNT(*)                            AS classes,
       ROUND(SUM(r.media_matriculados), 1) AS matriculados,
       ROUND(SUM(r.media_presentes), 1)    AS presentes,
       SUM(r.ofertas)                      AS ofertas_missionarias,
       SUM(r.oferta_13_sabado)             AS oferta_13_sabado,
       SUM(r.baptismos)                    AS baptismos
FROM escola_sabatina.vw_resumo_classe r
JOIN organizacao.igreja i ON i.igr_id = r.ect_igr_id
WHERE r.activa
GROUP BY 1, 2, 3;

CREATE VIEW escola_sabatina.vw_evolucao_sabado WITH (security_invoker = true) AS
SELECT ct.ect_etr_id, ct.ect_igr_id, s.esa_numero AS sabado, s.esa_data AS data, c.ecl_nome AS classe,
       r.ers_membros_presentes::NUMERIC / NULLIF(r.ers_membros_matriculados, 0) AS pct_presenca,
       r.ers_estudo_diario::NUMERIC / NULLIF(r.ers_membros_presentes, 0)        AS pct_estudo_diario,
       r.ers_oferta                                                              AS oferta,
       r.ers_oferta / NULLIF(ct.ect_alvo_oferta_sabado, 0)                       AS pct_alvo_oferta
FROM escola_sabatina.relatorio_sabado r
JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = r.ers_ect_id
JOIN escola_sabatina.classe c            ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s            ON s.esa_id = r.ers_esa_id
WHERE r.ers_end_date IS NULL AND ct.ect_estado = 'ACTIVO';

CREATE VIEW escola_sabatina.vw_relatorios_em_falta WITH (security_invoker = true) AS
SELECT ct.ect_igr_id, c.ecl_nome AS classe, s.esa_numero AS sabado, s.esa_data AS data,
       ct.ect_secretario_mem_id, ct.ect_professor_mem_id
FROM escola_sabatina.classe_trimestre ct
JOIN escola_sabatina.classe c ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s ON s.esa_etr_id = ct.ect_etr_id AND s.esa_end_date IS NULL
WHERE ct.ect_end_date IS NULL AND ct.ect_estado = 'ACTIVO' AND s.esa_data < CURRENT_DATE
  AND NOT EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado r
                  WHERE r.ers_ect_id = ct.ect_id AND r.ers_esa_id = s.esa_id AND r.ers_end_date IS NULL);

CREATE VIEW escola_sabatina.vw_conferencia_ofertas WITH (security_invoker = true) AS
SELECT r.ers_id, r.ers_igr_id, c.ecl_nome AS classe, s.esa_data AS data,
       r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas AS oferta_relatorio,
       t.tra_valor_total AS lancado_tesouraria, t.tra_estado AS estado_lancamento,
       CASE WHEN r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas = 0 THEN 'Sem oferta'
            WHEN t.tra_id IS NULL THEN 'Por lançar'
            WHEN t.tra_estado <> 'CONFIRMADA' THEN 'Lançamento por confirmar'
            WHEN t.tra_valor_total <> r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas THEN 'Valores diferentes'
            ELSE 'Conferido' END AS situacao
FROM escola_sabatina.relatorio_sabado r
JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = r.ers_ect_id
JOIN escola_sabatina.classe c            ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s            ON s.esa_id = r.ers_esa_id
LEFT JOIN tesouraria.transacao t         ON t.tra_id = r.ers_tra_id
WHERE r.ers_end_date IS NULL;

CREATE VIEW escola_sabatina.vw_visitantes_a_anonimizar WITH (security_invoker = true) AS
SELECT v.evi_id, r.ers_igr_id, v.evi_nome, s.esa_data AS data_visita
FROM escola_sabatina.visitante v
JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = v.evi_ers_id
JOIN escola_sabatina.sabado s           ON s.esa_id = r.ers_esa_id
WHERE v.evi_end_date IS NULL AND v.evi_anonimizado_em IS NULL AND v.evi_tornou_se_mem_id IS NULL
  AND s.esa_data < CURRENT_DATE - INTERVAL '12 months';

-- ================================================================ tesouraria
-- Saldos a partir das tabelas pré-calculadas (rápido mesmo com milhões de movimentos)
CREATE VIEW tesouraria.vw_saldo_conta WITH (security_invoker = true) AS
SELECT c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda,
       c.cfi_saldo_inicial + COALESCE(SUM(s.sdc_entradas - s.sdc_saidas), 0) AS saldo
FROM tesouraria.conta_financeira c
LEFT JOIN tesouraria.saldo_diario_conta s
       ON s.sdc_cfi_id = c.cfi_id AND s.sdc_end_date IS NULL AND s.sdc_data >= c.cfi_data_saldo_inicial
WHERE c.cfi_end_date IS NULL
GROUP BY c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda, c.cfi_saldo_inicial;

CREATE VIEW tesouraria.vw_saldo_fundo WITH (security_invoker = true) AS
SELECT s.sdf_igr_id AS igr_id, s.sdf_moeda AS moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito,
       SUM(s.sdf_entradas + s.sdf_estornos_saidas)                                         AS entradas,
       SUM(s.sdf_saidas + s.sdf_estornos_entradas)                                         AS saidas,
       SUM(s.sdf_entradas + s.sdf_estornos_saidas - s.sdf_saidas - s.sdf_estornos_entradas) AS saldo,
       (f.fun_restrito AND SUM(s.sdf_entradas + s.sdf_estornos_saidas - s.sdf_saidas - s.sdf_estornos_entradas) < 0) AS alerta_restrito
FROM tesouraria.saldo_diario_fundo s
JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
WHERE s.sdf_end_date IS NULL
GROUP BY s.sdf_igr_id, s.sdf_moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito;

-- Quanto se deve à Associação/Missão por mês e fundo (estornos de entradas descontam)
CREATE VIEW tesouraria.vw_remessa_devida WITH (security_invoker = true) AS
WITH recebido AS (
    SELECT s.sdf_igr_id AS igr_id, f.fun_id, f.fun_destino_ent_id AS ent_id,
           EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
           SUM(s.sdf_entradas - s.sdf_estornos_entradas) AS recebido,
           ROUND(SUM(s.sdf_entradas - s.sdf_estornos_entradas) * f.fun_percentagem_remessa / 100, 2) AS devido
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL AND f.fun_percentagem_remessa > 0
    GROUP BY 1, 2, 3, 4, 5, f.fun_percentagem_remessa
),
remetido AS (
    SELECT r.rem_igr_id AS igr_id, r.rem_ent_id AS ent_id, r.rem_ano AS ano, r.rem_mes AS mes,
           rl.rml_fun_id AS fun_id, SUM(rl.rml_valor) AS remetido
    FROM tesouraria.remessa r
    JOIN tesouraria.remessa_linha rl ON rl.rml_rem_id = r.rem_id AND rl.rml_end_date IS NULL
    WHERE r.rem_end_date IS NULL AND r.rem_estado IN ('ENVIADA', 'CONFIRMADA')
    GROUP BY 1, 2, 3, 4, 5
)
SELECT rc.*, COALESCE(rm.remetido, 0) AS remetido, rc.devido - COALESCE(rm.remetido, 0) AS em_falta
FROM recebido rc
LEFT JOIN remetido rm USING (igr_id, ent_id, ano, mes, fun_id);

CREATE VIEW tesouraria.vw_execucao_orcamento WITH (security_invoker = true) AS
SELECT o.orc_id, o.orc_igr_id, o.orc_ano, d.dep_nome AS departamento,
       c.cat_codigo, c.cat_nome AS categoria, c.cat_tipo,
       ol.orl_valor_previsto                         AS previsto,
       COALESCE(rl.valor, 0)                         AS realizado,
       ol.orl_valor_previsto - COALESCE(rl.valor, 0) AS diferenca,
       ROUND(COALESCE(rl.valor, 0) / NULLIF(ol.orl_valor_previsto, 0) * 100, 1) AS pct_execucao
FROM tesouraria.orcamento o
JOIN tesouraria.orcamento_linha ol ON ol.orl_orc_id = o.orc_id AND ol.orl_end_date IS NULL
JOIN tesouraria.categoria c        ON c.cat_id = ol.orl_cat_id
LEFT JOIN organizacao.igreja_departamento ide ON ide.ide_id = o.orc_ide_id
LEFT JOIN organizacao.departamento d          ON d.dep_id = ide.ide_dep_id
LEFT JOIN LATERAL (
    SELECT SUM(l.tli_valor) AS valor
    FROM tesouraria.transacao_linha l
    JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
    WHERE l.tli_end_date IS NULL AND l.tli_igr_id = o.orc_igr_id AND l.tli_cat_id = ol.orl_cat_id
      AND (o.orc_ide_id IS NULL OR l.tli_ide_id = o.orc_ide_id)
      AND t.tra_data_hora >= make_date(o.orc_ano, 1, 1) AND t.tra_data_hora < make_date(o.orc_ano + 1, 1, 1)
) rl ON TRUE
WHERE o.orc_end_date IS NULL;

CREATE VIEW tesouraria.vw_contagem_conferencia WITH (security_invoker = true) AS
SELECT c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado,
       COALESCE(SUM(t.tra_valor_total), 0)                       AS total_lancado,
       c.cnu_total_contado - COALESCE(SUM(t.tra_valor_total), 0) AS diferenca,
       c.cnu_estado
FROM tesouraria.contagem_numerario c
LEFT JOIN tesouraria.transacao t ON t.tra_cnu_id = c.cnu_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
WHERE c.cnu_end_date IS NULL
GROUP BY c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado, c.cnu_estado;

CREATE VIEW tesouraria.vw_despesas_por_pagar WITH (security_invoker = true) AS
SELECT d.des_id, d.des_igr_id, d.des_descricao, d.des_valor_aprovado, d.des_aprovado_em,
       CURRENT_DATE - d.des_aprovado_em::date AS dias_desde_aprovacao
FROM tesouraria.despesa d
WHERE d.des_end_date IS NULL AND d.des_estado = 'APROVADA';

CREATE VIEW tesouraria.vw_contribuicoes_membro WITH (security_invoker = true) AS
SELECT t.tra_igr_id, t.tra_mem_id, t.tra_fam_id, t.tra_id, t.tra_data_hora, t.tra_metodo,
       f.fun_nome AS fundo,
       CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END AS valor,
       (t.tra_estorno_tra_id IS NOT NULL) AS estorno, r.rec_ano, r.rec_numero
FROM tesouraria.transacao t
JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
JOIN tesouraria.fundo f           ON f.fun_id = l.tli_fun_id
LEFT JOIN tesouraria.recibo r     ON r.rec_tra_id = t.tra_id AND r.rec_end_date IS NULL
WHERE (t.tra_tipo = 'ENTRADA' OR t.tra_estorno_tra_id IS NOT NULL)
  AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
  AND (t.tra_mem_id IS NOT NULL OR t.tra_fam_id IS NOT NULL);

CREATE VIEW tesouraria.vw_extracto_anual WITH (security_invoker = true) AS
SELECT tra_igr_id, tra_mem_id, tra_fam_id,
       EXTRACT(YEAR FROM tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
       fundo, COUNT(DISTINCT tra_id) FILTER (WHERE NOT estorno) AS entregas, SUM(valor) AS total
FROM tesouraria.vw_contribuicoes_membro
GROUP BY 1, 2, 3, 4, 5;

CREATE VIEW tesouraria.vw_progresso_alvo WITH (security_invoker = true) AS
SELECT a.alv_id, a.alv_igr_id, f.fun_nome AS fundo, a.alv_valor_alvo,
       COALESCE(SUM(s.sdf_entradas - s.sdf_estornos_entradas), 0) AS arrecadado,
       ROUND(COALESCE(SUM(s.sdf_entradas - s.sdf_estornos_entradas), 0) / a.alv_valor_alvo * 100, 1) AS percentagem
FROM tesouraria.alvo a
JOIN tesouraria.fundo f ON f.fun_id = a.alv_fun_id
LEFT JOIN tesouraria.saldo_diario_fundo s
       ON s.sdf_fun_id = a.alv_fun_id AND s.sdf_igr_id = a.alv_igr_id AND s.sdf_end_date IS NULL
      AND s.sdf_data BETWEEN a.alv_data_inicio AND a.alv_data_fim
WHERE a.alv_end_date IS NULL
GROUP BY a.alv_id, a.alv_igr_id, f.fun_nome, a.alv_valor_alvo;

CREATE VIEW tesouraria.vw_extrato_por_reconciliar WITH (security_invoker = true) AS
SELECT e.*, c.cfi_nome AS conta
FROM tesouraria.extrato_linha e
JOIN tesouraria.conta_financeira c ON c.cfi_id = e.ext_cfi_id
WHERE e.ext_end_date IS NULL AND e.ext_tra_id IS NULL;

-- ================================================================ pagamentos e comunicação
CREATE VIEW pagamentos.vw_mpesa_pendentes WITH (security_invoker = true) AS
SELECT p.pmp_id, p.pmp_tra_id, p.pmp_third_party_reference, p.pmp_pedido_em,
       p.pmp_tentativas_consulta, p.pmp_ultima_consulta_em
FROM pagamentos.pagamento_mpesa p
JOIN tesouraria.transacao t ON t.tra_id = p.pmp_tra_id
WHERE p.pmp_end_date IS NULL AND p.pmp_respondido_em IS NULL AND t.tra_estado = 'PENDENTE'
  AND p.pmp_pedido_em < now() - INTERVAL '5 minutes';

CREATE VIEW comunicacao.vw_notificacoes_a_enviar WITH (security_invoker = true) AS
SELECT * FROM comunicacao.notificacao
WHERE ntf_end_date IS NULL AND ntf_estado = 'PENDENTE' AND ntf_agendada_para <= now()
ORDER BY ntf_agendada_para;

GRANT SELECT ON ALL TABLES IN SCHEMA nucleo TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA organizacao TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA secretaria TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA actividades TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA escola_sabatina TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA tesouraria TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA pagamentos TO app_igreja;
GRANT SELECT ON ALL TABLES IN SCHEMA comunicacao TO app_igreja;
-- a senha continua ilegível
REVOKE SELECT ON nucleo.usuario FROM app_igreja;
GRANT SELECT (usu_id, usu_mem_id, usu_nome, usu_email, usu_telefone, usu_super_admin, usu_ultimo_login, usu_estado, usu_criado_em, usu_criado_por, usu_modificado_em, usu_modificado_por, usu_end_date) ON nucleo.usuario TO app_igreja;

-- >>>>> V13__dados_referencia.sql
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- =====================================================================
-- Dados de referência
-- =====================================================================
-- Perfis e permissões: gerados no fim deste ficheiro a partir de defs.py

-- Departamentos e ministérios da igreja local (Manual da Igreja)
INSERT INTO organizacao.departamento (dep_nome) VALUES
  ('Escola Sabatina e Ministério Pessoal'), ('Ministério Jovem'), ('Desbravadores'), ('Aventureiros'),
  ('Ministério da Mulher'), ('Ministério da Criança'), ('Ministério da Família'), ('Ministério de Saúde'),
  ('Mordomia Cristã'), ('Comunicação'), ('Educação'), ('Liberdade Religiosa'), ('Publicações'),
  ('Música'), ('Diaconato'), ('ADRA / Acção Solidária'), ('Ministério dos Homens'), ('Ministério das Possibilidades');

INSERT INTO organizacao.cargo (car_nome, car_mandato_anos) VALUES
  ('Ancião', 1), ('Diácono', 1), ('Diaconisa', 1), ('Secretário(a) da igreja', 1), ('Tesoureiro(a)', 1),
  ('Tesoureiro(a) adjunto(a)', 1), ('Secretário(a) da junta', 1);
INSERT INTO organizacao.cargo (car_nome, car_mandato_anos, car_dep_id)
SELECT x.nome, 1, d.dep_id FROM (VALUES
  ('Director(a) da Escola Sabatina', 'Escola Sabatina e Ministério Pessoal'),
  ('Secretário(a) da Escola Sabatina', 'Escola Sabatina e Ministério Pessoal'),
  ('Director(a) do Ministério Pessoal', 'Escola Sabatina e Ministério Pessoal'),
  ('Director(a) de Jovens', 'Ministério Jovem'),
  ('Director(a) de Desbravadores', 'Desbravadores'),
  ('Director(a) de Aventureiros', 'Aventureiros'),
  ('Director(a) do Ministério da Mulher', 'Ministério da Mulher'),
  ('Director(a) do Ministério da Criança', 'Ministério da Criança'),
  ('Director(a) de Mordomia', 'Mordomia Cristã'),
  ('Director(a) de Comunicação', 'Comunicação'),
  ('Director(a) de Música', 'Música')) x(nome, dep)
JOIN organizacao.departamento d ON d.dep_nome = x.dep;

INSERT INTO escola_sabatina.pontuacao_config (epc_etr_id) VALUES (NULL);

INSERT INTO tesouraria.categoria (cat_codigo, cat_nome, cat_tipo, cat_e_remessa) VALUES
  ('R1', 'Dízimos',                         'RECEITA', FALSE),
  ('R2', 'Ofertas',                         'RECEITA', FALSE),
  ('R3', 'Ofertas da Escola Sabatina',      'RECEITA', FALSE),
  ('R4', 'Doações para projectos',          'RECEITA', FALSE),
  ('R9', 'Outras receitas',                 'RECEITA', FALSE),
  ('D1', 'Remessas à Associação/Missão',    'DESPESA', TRUE),
  ('D2', 'Água, luz e comunicações',        'DESPESA', FALSE),
  ('D3', 'Manutenção e obras',              'DESPESA', FALSE),
  ('D4', 'Actividades de departamentos',    'DESPESA', FALSE),
  ('D5', 'Assistência social',              'DESPESA', FALSE),
  ('D6', 'Material e literatura',           'DESPESA', FALSE),
  ('D7', 'Taxas bancárias e M-Pesa',        'DESPESA', FALSE),
  ('D8', 'Despesas da Escola Sabatina',     'DESPESA', FALSE),
  ('D9', 'Outras despesas',                 'DESPESA', FALSE);

-- ---------------------------------------------------------------- permissões (geradas)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('nucleo.perfil.criar', 'Criar: Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.perfil.alterar', 'Alterar: Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.perfil.terminar', 'Terminar (end_date): Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.permissao.criar', 'Criar: Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.permissao.alterar', 'Alterar: Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.permissao.terminar', 'Terminar (end_date): Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.perfil_permissao.criar', 'Criar: Que permissões cada perfil tem'),
  ('nucleo.perfil_permissao.alterar', 'Alterar: Que permissões cada perfil tem'),
  ('nucleo.perfil_permissao.terminar', 'Terminar (end_date): Que permissões cada perfil tem'),
  ('nucleo.usuario.ler', 'Ler: Contas de acesso ao sistema'),
  ('nucleo.usuario.criar', 'Criar: Contas de acesso ao sistema'),
  ('nucleo.usuario.alterar', 'Alterar: Contas de acesso ao sistema'),
  ('nucleo.usuario.terminar', 'Terminar (end_date): Contas de acesso ao sistema'),
  ('nucleo.usuario_igreja.ler', 'Ler: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.criar', 'Criar: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.alterar', 'Alterar: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.terminar', 'Terminar (end_date): Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_entidade.ler', 'Ler: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.criar', 'Criar: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.alterar', 'Alterar: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.terminar', 'Terminar (end_date): Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.log_auditoria.ler', 'Ler: Histórico de alterações (só os campos que mudaram); particionado por mês'),
  ('organizacao.entidade.criar', 'Criar: Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.entidade.alterar', 'Alterar: Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.entidade.terminar', 'Terminar (end_date): Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.distrito.criar', 'Criar: Distritos pastorais de uma Associação/Missão'),
  ('organizacao.distrito.alterar', 'Alterar: Distritos pastorais de uma Associação/Missão'),
  ('organizacao.distrito.terminar', 'Terminar (end_date): Distritos pastorais de uma Associação/Missão'),
  ('organizacao.igreja.ler', 'Ler: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.criar', 'Criar: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.alterar', 'Alterar: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.terminar', 'Terminar (end_date): Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.departamento.criar', 'Criar: Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.departamento.alterar', 'Alterar: Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.departamento.terminar', 'Terminar (end_date): Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.igreja_departamento.ler', 'Ler: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.criar', 'Criar: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.alterar', 'Alterar: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.terminar', 'Terminar (end_date): Departamento a funcionar numa igreja'),
  ('organizacao.cargo.criar', 'Criar: Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('organizacao.cargo.alterar', 'Alterar: Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('organizacao.cargo.terminar', 'Terminar (end_date): Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('secretaria.familia.ler', 'Ler: Agregados familiares'),
  ('secretaria.familia.criar', 'Criar: Agregados familiares'),
  ('secretaria.familia.alterar', 'Alterar: Agregados familiares'),
  ('secretaria.familia.terminar', 'Terminar (end_date): Agregados familiares'),
  ('secretaria.membro.ler', 'Ler: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.criar', 'Criar: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.alterar', 'Alterar: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.terminar', 'Terminar (end_date): Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.contacto.ler', 'Ler: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.criar', 'Criar: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.alterar', 'Alterar: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.terminar', 'Terminar (end_date): Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.consentimento.ler', 'Ler: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.criar', 'Criar: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.alterar', 'Alterar: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.terminar', 'Terminar (end_date): Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.reuniao.ler', 'Ler: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.criar', 'Criar: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.alterar', 'Alterar: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.terminar', 'Terminar (end_date): Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.voto.ler', 'Ler: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.criar', 'Criar: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.alterar', 'Alterar: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.terminar', 'Terminar (end_date): Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.movimento_membro.ler', 'Ler: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.criar', 'Criar: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.alterar', 'Alterar: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.terminar', 'Terminar (end_date): Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.transferencia_membro.ler', 'Ler: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.criar', 'Criar: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.alterar', 'Alterar: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.terminar', 'Terminar (end_date): Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.disciplina.ler', 'Ler: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.criar', 'Criar: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.alterar', 'Alterar: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.terminar', 'Terminar (end_date): Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.oficial.ler', 'Ler: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.criar', 'Criar: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.alterar', 'Alterar: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.terminar', 'Terminar (end_date): Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.baptismo.ler', 'Ler: Baptismos e rebaptismos'),
  ('secretaria.baptismo.criar', 'Criar: Baptismos e rebaptismos'),
  ('secretaria.baptismo.alterar', 'Alterar: Baptismos e rebaptismos'),
  ('secretaria.baptismo.terminar', 'Terminar (end_date): Baptismos e rebaptismos'),
  ('actividades.actividade.ler', 'Ler: Actividades e eventos dos departamentos'),
  ('actividades.actividade.criar', 'Criar: Actividades e eventos dos departamentos'),
  ('actividades.actividade.alterar', 'Alterar: Actividades e eventos dos departamentos'),
  ('actividades.actividade.terminar', 'Terminar (end_date): Actividades e eventos dos departamentos'),
  ('actividades.material.ler', 'Ler: Material necessário para uma actividade'),
  ('actividades.material.criar', 'Criar: Material necessário para uma actividade'),
  ('actividades.material.alterar', 'Alterar: Material necessário para uma actividade'),
  ('actividades.material.terminar', 'Terminar (end_date): Material necessário para uma actividade'),
  ('actividades.escala.ler', 'Ler: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.criar', 'Criar: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.alterar', 'Alterar: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.terminar', 'Terminar (end_date): Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('escola_sabatina.trimestre.criar', 'Criar: Trimestres da lição'),
  ('escola_sabatina.trimestre.alterar', 'Alterar: Trimestres da lição'),
  ('escola_sabatina.trimestre.terminar', 'Terminar (end_date): Trimestres da lição'),
  ('escola_sabatina.sabado.criar', 'Criar: Sábados de cada trimestre'),
  ('escola_sabatina.sabado.alterar', 'Alterar: Sábados de cada trimestre'),
  ('escola_sabatina.sabado.terminar', 'Terminar (end_date): Sábados de cada trimestre'),
  ('escola_sabatina.classe.ler', 'Ler: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.criar', 'Criar: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.alterar', 'Alterar: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.terminar', 'Terminar (end_date): Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe_trimestre.ler', 'Ler: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.criar', 'Criar: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.alterar', 'Alterar: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.terminar', 'Terminar (end_date): Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.matricula.ler', 'Ler: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.criar', 'Criar: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.alterar', 'Alterar: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.terminar', 'Terminar (end_date): Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.relatorio_sabado.ler', 'Ler: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.criar', 'Criar: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.alterar', 'Alterar: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.terminar', 'Terminar (end_date): Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.presenca.ler', 'Ler: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.criar', 'Criar: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.alterar', 'Alterar: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.terminar', 'Terminar (end_date): Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.visitante.ler', 'Ler: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.criar', 'Criar: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.alterar', 'Alterar: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.terminar', 'Terminar (end_date): Visitantes com contacto para seguimento'),
  ('escola_sabatina.pontuacao_config.criar', 'Criar: Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('escola_sabatina.pontuacao_config.alterar', 'Alterar: Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('escola_sabatina.pontuacao_config.terminar', 'Terminar (end_date): Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('tesouraria.conta_financeira.ler', 'Ler: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.criar', 'Criar: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.alterar', 'Alterar: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.terminar', 'Terminar (end_date): Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.fundo.ler', 'Ler: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.criar', 'Criar: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.alterar', 'Alterar: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.terminar', 'Terminar (end_date): Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.calendario_oferta.criar', 'Criar: Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.calendario_oferta.alterar', 'Alterar: Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.calendario_oferta.terminar', 'Terminar (end_date): Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.categoria.criar', 'Criar: Plano de contas: categorias de receita e despesa'),
  ('tesouraria.categoria.alterar', 'Alterar: Plano de contas: categorias de receita e despesa'),
  ('tesouraria.categoria.terminar', 'Terminar (end_date): Plano de contas: categorias de receita e despesa'),
  ('tesouraria.alvo.ler', 'Ler: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.criar', 'Criar: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.alterar', 'Alterar: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.terminar', 'Terminar (end_date): Alvos de arrecadação por fundo'),
  ('tesouraria.orcamento.ler', 'Ler: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.criar', 'Criar: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.alterar', 'Alterar: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.terminar', 'Terminar (end_date): Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento_linha.ler', 'Ler: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.criar', 'Criar: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.alterar', 'Alterar: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.terminar', 'Terminar (end_date): Valor previsto por categoria'),
  ('tesouraria.despesa.ler', 'Ler: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.criar', 'Criar: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.alterar', 'Alterar: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.terminar', 'Terminar (end_date): Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.contagem_numerario.ler', 'Ler: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.criar', 'Criar: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.alterar', 'Alterar: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.terminar', 'Terminar (end_date): Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.transacao.ler', 'Ler: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.criar', 'Criar: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.alterar', 'Alterar: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.terminar', 'Terminar (end_date): Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao_linha.ler', 'Ler: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.criar', 'Criar: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.alterar', 'Alterar: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.terminar', 'Terminar (end_date): Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.saldo_diario_conta.ler', 'Ler: Saldo pré-calculado por conta e dia (mantido por triggers; não editar)'),
  ('tesouraria.saldo_diario_fundo.ler', 'Ler: Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar)'),
  ('tesouraria.recibo.ler', 'Ler: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.criar', 'Criar: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.alterar', 'Alterar: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.terminar', 'Terminar (end_date): Recibos numerados por igreja e ano'),
  ('tesouraria.documento.ler', 'Ler: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.criar', 'Criar: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.alterar', 'Alterar: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.terminar', 'Terminar (end_date): Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.remessa.ler', 'Ler: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.criar', 'Criar: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.alterar', 'Alterar: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.terminar', 'Terminar (end_date): Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa_linha.ler', 'Ler: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.criar', 'Criar: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.alterar', 'Alterar: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.terminar', 'Terminar (end_date): Valor remetido por fundo'),
  ('tesouraria.fecho_periodo.ler', 'Ler: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.criar', 'Criar: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.alterar', 'Alterar: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.terminar', 'Terminar (end_date): Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.extrato_linha.ler', 'Ler: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.criar', 'Criar: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.alterar', 'Alterar: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.terminar', 'Terminar (end_date): Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('pagamentos.pagamento_mpesa.ler', 'Ler: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.criar', 'Criar: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.alterar', 'Alterar: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.terminar', 'Terminar (end_date): Pedido e resposta da API M-Pesa'),
  ('pagamentos.mpesa_callback_log.ler', 'Ler: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.criar', 'Criar: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.alterar', 'Alterar: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.terminar', 'Terminar (end_date): Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.pagamento_bancario.ler', 'Ler: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.criar', 'Criar: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.alterar', 'Alterar: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.terminar', 'Terminar (end_date): Detalhe de pagamentos por banco'),
  ('comunicacao.notificacao.ler', 'Ler: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.criar', 'Criar: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.alterar', 'Alterar: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.terminar', 'Terminar (end_date): Fila de SMS, WhatsApp e e-mail a enviar'),
  ('secretaria.membro.validar', 'Aprovar o registo de um membro'),
  ('secretaria.transferencia_membro.emitir_carta', 'Emitir a carta de transferência (igreja de origem)'),
  ('secretaria.transferencia_membro.aceitar', 'Concluir a transferência (igreja de destino)'),
  ('tesouraria.transacao.aprovar', 'Aprovar uma saída de dinheiro'),
  ('tesouraria.despesa.aprovar', 'Aprovar ou rejeitar requisições de despesa'),
  ('tesouraria.orcamento.aprovar', 'Marcar o orçamento como aprovado'),
  ('tesouraria.remessa.confirmar', 'Confirmar a recepção de uma remessa (Associação)'),
  ('escola_sabatina.relatorio_sabado.fechar', 'Fechar o relatório do sábado'),
  ('escola_sabatina.relatorio_sabado.reabrir', 'Reabrir um relatório fechado');

-- ---------------------------------------------------------------- perfis (gerados)
INSERT INTO nucleo.perfil (per_nome, per_ambito, per_descricao) VALUES
  ('ADMIN', 'IGREJA', 'Administrador do sistema na igreja (não vê a disciplina)'),
  ('PASTOR', 'IGREJA', 'Pastor: lê tudo da igreja, gere a secretaria e a disciplina, aprova despesas'),
  ('ANCIAO', 'IGREJA', 'Ancião: aprova saídas e despesas, fecha e reabre meses, reuniões e votos'),
  ('SECRETARIO', 'IGREJA', 'Secretário(a) da igreja: livro de membros, reuniões, votos, transferências, disciplina'),
  ('TESOUREIRO', 'IGREJA', 'Tesoureiro(a): movimentos, recibos, contagens, despesas, remessas (não aprova o que regista)'),
  ('DIRECTOR_ES', 'IGREJA', 'Director(a) da Escola Sabatina: classes, alvos, relatórios'),
  ('SECRETARIO_ES', 'IGREJA', 'Secretário(a) da Escola Sabatina: relatórios do sábado e chamada'),
  ('DIRECTOR_DEPARTAMENTO', 'IGREJA', 'Director(a) de departamento: actividades, material, escalas, pedir despesas'),
  ('MEMBRO', 'IGREJA', 'Membro: vê os seus dados, contribuições e escalas (garantido sem perfil)'),
  ('ADMIN_ASSOCIACAO', 'ENTIDADE', 'Administração da Associação/Missão: igrejas, distritos, tabelas comuns, utilizadores'),
  ('TESOUREIRO_ASSOCIACAO', 'ENTIDADE', 'Tesoureiro(a) da Associação/Missão: lê as tesourarias e confirma remessas'),
  ('SECRETARIO_ASSOCIACAO', 'ENTIDADE', 'Secretário(a) da Associação/Missão: lê os livros de membros e as estatísticas'),
  ('INTEGRACAO', 'ENTIDADE', 'Conta de serviço da API (callbacks M-Pesa, envio de notificações)');

-- ADMIN: 183 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'comunicacao.notificacao.alterar', 'comunicacao.notificacao.criar', 'comunicacao.notificacao.ler', 'comunicacao.notificacao.terminar', 'escola_sabatina.classe.alterar', 'escola_sabatina.classe.criar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe.terminar', 'escola_sabatina.classe_trimestre.alterar', 'escola_sabatina.classe_trimestre.criar', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.classe_trimestre.terminar', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.relatorio_sabado.terminar', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'nucleo.usuario.alterar', 'nucleo.usuario.criar', 'nucleo.usuario.ler', 'nucleo.usuario.terminar', 'nucleo.usuario_igreja.alterar', 'nucleo.usuario_igreja.criar', 'nucleo.usuario_igreja.ler', 'nucleo.usuario_igreja.terminar', 'organizacao.igreja.alterar', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.alterar', 'organizacao.igreja_departamento.criar', 'organizacao.igreja_departamento.ler', 'organizacao.igreja_departamento.terminar', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.mpesa_callback_log.terminar', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_bancario.terminar', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'pagamentos.pagamento_mpesa.terminar', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.alterar', 'tesouraria.alvo.criar', 'tesouraria.alvo.ler', 'tesouraria.alvo.terminar', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.alterar', 'tesouraria.conta_financeira.criar', 'tesouraria.conta_financeira.ler', 'tesouraria.conta_financeira.terminar', 'tesouraria.contagem_numerario.alterar', 'tesouraria.contagem_numerario.criar', 'tesouraria.contagem_numerario.ler', 'tesouraria.contagem_numerario.terminar', 'tesouraria.despesa.alterar', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.despesa.terminar', 'tesouraria.documento.alterar', 'tesouraria.documento.criar', 'tesouraria.documento.ler', 'tesouraria.documento.terminar', 'tesouraria.extrato_linha.alterar', 'tesouraria.extrato_linha.criar', 'tesouraria.extrato_linha.ler', 'tesouraria.extrato_linha.terminar', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fecho_periodo.terminar', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.criar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento.terminar', 'tesouraria.orcamento_linha.alterar', 'tesouraria.orcamento_linha.criar', 'tesouraria.orcamento_linha.ler', 'tesouraria.orcamento_linha.terminar', 'tesouraria.recibo.alterar', 'tesouraria.recibo.criar', 'tesouraria.recibo.ler', 'tesouraria.recibo.terminar', 'tesouraria.remessa.alterar', 'tesouraria.remessa.criar', 'tesouraria.remessa.ler', 'tesouraria.remessa.terminar', 'tesouraria.remessa_linha.alterar', 'tesouraria.remessa_linha.criar', 'tesouraria.remessa_linha.ler', 'tesouraria.remessa_linha.terminar', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.criar', 'tesouraria.transacao.ler', 'tesouraria.transacao.terminar', 'tesouraria.transacao_linha.alterar', 'tesouraria.transacao_linha.criar', 'tesouraria.transacao_linha.ler', 'tesouraria.transacao_linha.terminar');

-- PASTOR: 94 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'PASTOR'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'comunicacao.notificacao.ler', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'nucleo.usuario.ler', 'nucleo.usuario_entidade.ler', 'nucleo.usuario_igreja.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.disciplina.alterar', 'secretaria.disciplina.criar', 'secretaria.disciplina.ler', 'secretaria.disciplina.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.membro.validar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.aceitar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.emitir_carta', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.aprovar', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.ler', 'tesouraria.orcamento.aprovar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.aprovar', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- ANCIAO: 63 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ANCIAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'nucleo.usuario_igreja.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.disciplina.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.ler', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.alterar', 'tesouraria.despesa.aprovar', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fecho_periodo.terminar', 'tesouraria.fundo.ler', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.aprovar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.aprovar', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- SECRETARIO: 59 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.disciplina.alterar', 'secretaria.disciplina.criar', 'secretaria.disciplina.ler', 'secretaria.disciplina.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.membro.validar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.aceitar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.emitir_carta', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar');

-- TESOUREIRO: 92 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'TESOUREIRO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.ler', 'comunicacao.notificacao.alterar', 'comunicacao.notificacao.criar', 'comunicacao.notificacao.ler', 'comunicacao.notificacao.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.relatorio_sabado.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.mpesa_callback_log.terminar', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_bancario.terminar', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'pagamentos.pagamento_mpesa.terminar', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'tesouraria.alvo.alterar', 'tesouraria.alvo.criar', 'tesouraria.alvo.ler', 'tesouraria.alvo.terminar', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.alterar', 'tesouraria.conta_financeira.criar', 'tesouraria.conta_financeira.ler', 'tesouraria.conta_financeira.terminar', 'tesouraria.contagem_numerario.alterar', 'tesouraria.contagem_numerario.criar', 'tesouraria.contagem_numerario.ler', 'tesouraria.contagem_numerario.terminar', 'tesouraria.despesa.alterar', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.despesa.terminar', 'tesouraria.documento.alterar', 'tesouraria.documento.criar', 'tesouraria.documento.ler', 'tesouraria.documento.terminar', 'tesouraria.extrato_linha.alterar', 'tesouraria.extrato_linha.criar', 'tesouraria.extrato_linha.ler', 'tesouraria.extrato_linha.terminar', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.criar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento.terminar', 'tesouraria.orcamento_linha.alterar', 'tesouraria.orcamento_linha.criar', 'tesouraria.orcamento_linha.ler', 'tesouraria.orcamento_linha.terminar', 'tesouraria.recibo.alterar', 'tesouraria.recibo.criar', 'tesouraria.recibo.ler', 'tesouraria.recibo.terminar', 'tesouraria.remessa.alterar', 'tesouraria.remessa.criar', 'tesouraria.remessa.ler', 'tesouraria.remessa.terminar', 'tesouraria.remessa_linha.alterar', 'tesouraria.remessa_linha.criar', 'tesouraria.remessa_linha.ler', 'tesouraria.remessa_linha.terminar', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.criar', 'tesouraria.transacao.ler', 'tesouraria.transacao.terminar', 'tesouraria.transacao_linha.alterar', 'tesouraria.transacao_linha.criar', 'tesouraria.transacao_linha.ler', 'tesouraria.transacao_linha.terminar');

-- DIRECTOR_ES: 42 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_ES'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'escola_sabatina.classe.alterar', 'escola_sabatina.classe.criar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe.terminar', 'escola_sabatina.classe_trimestre.alterar', 'escola_sabatina.classe_trimestre.criar', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.classe_trimestre.terminar', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.fechar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.relatorio_sabado.reabrir', 'escola_sabatina.relatorio_sabado.terminar', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'organizacao.igreja.ler', 'secretaria.baptismo.ler', 'secretaria.membro.ler');

-- SECRETARIO_ES: 20 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO_ES'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.fechar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'organizacao.igreja.ler', 'secretaria.membro.ler');

-- DIRECTOR_DEPARTAMENTO: 16 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_DEPARTAMENTO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.membro.ler', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.documento.criar', 'tesouraria.documento.ler');

-- ADMIN_ASSOCIACAO: 91 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.ler', 'actividades.escala.ler', 'actividades.material.ler', 'comunicacao.notificacao.ler', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.ler', 'nucleo.log_auditoria.ler', 'nucleo.usuario.alterar', 'nucleo.usuario.criar', 'nucleo.usuario.ler', 'nucleo.usuario.terminar', 'nucleo.usuario_entidade.alterar', 'nucleo.usuario_entidade.criar', 'nucleo.usuario_entidade.ler', 'nucleo.usuario_entidade.terminar', 'nucleo.usuario_igreja.alterar', 'nucleo.usuario_igreja.criar', 'nucleo.usuario_igreja.ler', 'nucleo.usuario_igreja.terminar', 'organizacao.cargo.alterar', 'organizacao.cargo.criar', 'organizacao.cargo.terminar', 'organizacao.departamento.alterar', 'organizacao.departamento.criar', 'organizacao.departamento.terminar', 'organizacao.distrito.alterar', 'organizacao.distrito.criar', 'organizacao.distrito.terminar', 'organizacao.entidade.alterar', 'organizacao.entidade.criar', 'organizacao.entidade.terminar', 'organizacao.igreja.alterar', 'organizacao.igreja.criar', 'organizacao.igreja.ler', 'organizacao.igreja.terminar', 'organizacao.igreja_departamento.alterar', 'organizacao.igreja_departamento.criar', 'organizacao.igreja_departamento.ler', 'organizacao.igreja_departamento.terminar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.ler', 'secretaria.transferencia_membro.ler', 'secretaria.voto.ler', 'tesouraria.alvo.ler', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- TESOUREIRO_ASSOCIACAO: 24 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'TESOUREIRO_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.ler', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.alterar', 'tesouraria.remessa.confirmar', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- SECRETARIO_ASSOCIACAO: 18 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.ler', 'secretaria.transferencia_membro.ler', 'secretaria.voto.ler');

-- INTEGRACAO: 13 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'INTEGRACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('comunicacao.notificacao.alterar', 'comunicacao.notificacao.ler', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.ler');

-- >>>>> V14__sessoes_e_api.sql
-- =====================================================================
-- V14 · Apoio à API: sessões de login, recuperação de senha, bloqueio de login,
--       pedidos repetidos (Idempotency-Key) e ligação das ofertas da ES à tesouraria
--
-- As quatro tabelas são do sistema: a API não as lê nem escreve directamente,
-- só através das funções abaixo (SECURITY DEFINER). Seguem as convenções do esquema
-- (prefixo, campos-padrão, nada se apaga).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- tabelas
CREATE TABLE nucleo.sessao (
    ses_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ses_usu_id        INT NOT NULL REFERENCES nucleo.usuario(usu_id),
    ses_refresh_hash  VARCHAR(128) NOT NULL,
    ses_familia       UUID NOT NULL,
    ses_expira_em     TIMESTAMPTZ NOT NULL,
    ses_usado_em      TIMESTAMPTZ,
    ses_ip            INET,
    ses_navegador     VARCHAR(255),
    ses_estado        nucleo.estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ses_criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    ses_criado_por    INT,
    ses_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ses_modificado_por INT,
    ses_end_date      TIMESTAMPTZ,
    CONSTRAINT chk_ses_end_date CHECK (ses_end_date IS NULL OR ses_end_date >= ses_criado_em)
);
COMMENT ON TABLE nucleo.sessao IS 'Sessões de login (token de renovação guardado só como hash; renovar troca-o por outro)';
CREATE INDEX idx_ses_refresh ON nucleo.sessao (ses_refresh_hash);
CREATE INDEX idx_ses_usu_activas ON nucleo.sessao (ses_usu_id) WHERE ses_end_date IS NULL;

CREATE TABLE nucleo.recuperacao_senha (
    rsn_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rsn_usu_id        INT NOT NULL REFERENCES nucleo.usuario(usu_id),
    rsn_codigo_hash   VARCHAR(128) NOT NULL,
    rsn_expira_em     TIMESTAMPTZ NOT NULL,
    rsn_tentativas    SMALLINT NOT NULL DEFAULT 0,
    rsn_usado_em      TIMESTAMPTZ,
    rsn_estado        nucleo.estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rsn_criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    rsn_criado_por    INT,
    rsn_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rsn_modificado_por INT,
    rsn_end_date      TIMESTAMPTZ,
    CONSTRAINT chk_rsn_end_date CHECK (rsn_end_date IS NULL OR rsn_end_date >= rsn_criado_em)
);
COMMENT ON TABLE nucleo.recuperacao_senha IS 'Códigos de recuperação de senha (6 dígitos, 15 minutos, 5 tentativas; guardados como hash)';
CREATE INDEX idx_rsn_usu ON nucleo.recuperacao_senha (rsn_usu_id) WHERE rsn_end_date IS NULL;

CREATE TABLE nucleo.bloqueio_login (
    blq_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    blq_login         VARCHAR(150) NOT NULL,
    blq_falhas        SMALLINT NOT NULL DEFAULT 0,
    blq_bloqueado_ate TIMESTAMPTZ,
    blq_estado        nucleo.estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    blq_criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    blq_criado_por    INT,
    blq_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    blq_modificado_por INT,
    blq_end_date      TIMESTAMPTZ,
    CONSTRAINT chk_blq_end_date CHECK (blq_end_date IS NULL OR blq_end_date >= blq_criado_em)
);
COMMENT ON TABLE nucleo.bloqueio_login IS 'Falhas de login seguidas por login (10 falhas = 15 minutos bloqueado)';
CREATE UNIQUE INDEX uq_blq_login ON nucleo.bloqueio_login (lower(blq_login)) WHERE blq_end_date IS NULL;

CREATE TABLE nucleo.pedido_idempotente (
    pid_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pid_chave         UUID NOT NULL,
    pid_usu_id        INT NOT NULL REFERENCES nucleo.usuario(usu_id),
    pid_metodo        VARCHAR(10) NOT NULL,
    pid_caminho       VARCHAR(255) NOT NULL,
    pid_estado_http   SMALLINT NOT NULL,
    pid_resposta      JSONB,
    pid_expira_em     TIMESTAMPTZ NOT NULL,
    pid_estado        nucleo.estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pid_criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    pid_criado_por    INT,
    pid_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pid_modificado_por INT,
    pid_end_date      TIMESTAMPTZ,
    CONSTRAINT chk_pid_end_date CHECK (pid_end_date IS NULL OR pid_end_date >= pid_criado_em)
);
COMMENT ON TABLE nucleo.pedido_idempotente IS 'Respostas guardadas 24 horas por Idempotency-Key, para pedidos repetidos não criarem nada de novo';
CREATE UNIQUE INDEX uq_pid_chave ON nucleo.pedido_idempotente (pid_usu_id, pid_chave) WHERE pid_end_date IS NULL;
CREATE INDEX idx_pid_expira ON nucleo.pedido_idempotente (pid_expira_em) WHERE pid_end_date IS NULL;

-- comportamento comum (tabelas do sistema: sem permissão "terminar" e sem log, como os saldos)
DO $$
DECLARE t RECORD;
BEGIN
    FOR t IN SELECT * FROM (VALUES ('sessao','ses'), ('recuperacao_senha','rsn'), ('bloqueio_login','blq'), ('pedido_idempotente','pid')) x(tab, p) LOOP
        EXECUTE format('CREATE TRIGGER trg_%s_00_padrao BEFORE INSERT OR UPDATE ON nucleo.%I FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao(%L, %L, %L)', t.p, t.tab, t.p, '', '');
        EXECUTE format('CREATE TRIGGER trg_%s_00_sem_delete BEFORE DELETE ON nucleo.%I FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete(%L)', t.p, t.tab, t.p);
        EXECUTE format('CREATE TRIGGER trg_%s_00_sem_truncate BEFORE TRUNCATE ON nucleo.%I FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete(%L)', t.p, t.tab, t.p);
        EXECUTE format('ALTER TABLE nucleo.%I ADD CONSTRAINT fk_%s_criado_por FOREIGN KEY (%s_criado_por) REFERENCES nucleo.usuario(usu_id)', t.tab, t.p, t.p);
        EXECUTE format('ALTER TABLE nucleo.%I ADD CONSTRAINT fk_%s_modificado_por FOREIGN KEY (%s_modificado_por) REFERENCES nucleo.usuario(usu_id)', t.tab, t.p, t.p);
        EXECUTE format('ALTER TABLE nucleo.%I ENABLE ROW LEVEL SECURITY', t.tab);   -- sem políticas: ninguém lê directamente
        EXECUTE format('REVOKE ALL ON nucleo.%I FROM app_igreja', t.tab);
    END LOOP;
END $$;

-- ---------------------------------------------------------------- login e sessões
-- Bloqueio: devolve até quando o login está bloqueado (NULL = pode tentar)
CREATE FUNCTION nucleo.fn_login_bloqueado_ate(p_login TEXT) RETURNS TIMESTAMPTZ
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT blq_bloqueado_ate FROM nucleo.bloqueio_login
    WHERE lower(blq_login) = lower(p_login) AND blq_end_date IS NULL AND blq_bloqueado_ate > now();
$$;

-- Uma falha: ao fim de 10 seguidas, bloqueia 15 minutos e recomeça a contagem
CREATE FUNCTION nucleo.fn_login_falhou(p_login TEXT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO nucleo.bloqueio_login AS b (blq_login, blq_falhas) VALUES (lower(p_login), 1)
    ON CONFLICT (lower(blq_login)) WHERE blq_end_date IS NULL
    DO UPDATE SET blq_falhas = b.blq_falhas + 1;
    UPDATE nucleo.bloqueio_login SET blq_bloqueado_ate = now() + INTERVAL '15 minutes', blq_falhas = 0
     WHERE lower(blq_login) = lower(p_login) AND blq_end_date IS NULL AND blq_falhas >= 10;
END $$;

-- Login certo: abre a sessão (a API já comparou a senha com o hash de fn_credenciais)
CREATE FUNCTION nucleo.fn_abrir_sessao(p_usu INT, p_refresh_hash TEXT, p_ip INET DEFAULT NULL,
                                       p_navegador TEXT DEFAULT NULL) RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_login TEXT; v_ses BIGINT;
BEGIN
    SELECT COALESCE(usu_email, usu_telefone) INTO v_login FROM nucleo.usuario
     WHERE usu_id = p_usu AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Utilizador inactivo ou inexistente'; END IF;
    PERFORM set_config('app.usuario_id', p_usu::TEXT, true);   -- a partir daqui, a sessão é desta pessoa
    UPDATE nucleo.bloqueio_login SET blq_falhas = 0, blq_bloqueado_ate = NULL
     WHERE blq_end_date IS NULL AND lower(blq_login) IN (SELECT lower(x) FROM nucleo.usuario u,
           unnest(ARRAY[u.usu_email, u.usu_telefone]) x WHERE u.usu_id = p_usu AND x IS NOT NULL);
    UPDATE nucleo.usuario SET usu_ultimo_login = now() WHERE usu_id = p_usu;
    INSERT INTO nucleo.sessao (ses_usu_id, ses_refresh_hash, ses_familia, ses_expira_em, ses_ip, ses_navegador)
    VALUES (p_usu, p_refresh_hash, gen_random_uuid(), now() + INTERVAL '30 days', p_ip, left(p_navegador, 255))
    RETURNING ses_id INTO v_ses;
    RETURN v_ses;
END $$;

-- Renovação: troca o token. Um token já trocado que volte a aparecer termina todas as sessões da pessoa.
-- Devolve sempre uma linha; resultado = OK | INVALIDA | EXPIRADA | REUTILIZADA
CREATE FUNCTION nucleo.fn_renovar_sessao(p_refresh_hash TEXT, p_novo_refresh_hash TEXT, p_ip INET DEFAULT NULL,
                                         p_navegador TEXT DEFAULT NULL)
RETURNS TABLE (resultado TEXT, utilizador INT, sessao_id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE s nucleo.sessao%ROWTYPE; v_novo BIGINT;
BEGIN
    SELECT * INTO s FROM nucleo.sessao WHERE ses_refresh_hash = p_refresh_hash ORDER BY nucleo.sessao.ses_id DESC LIMIT 1;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'INVALIDA'::TEXT, NULL::INT, NULL::BIGINT; RETURN;
    END IF;
    PERFORM set_config('app.usuario_id', s.ses_usu_id::TEXT, true);
    IF s.ses_usado_em IS NOT NULL THEN
        UPDATE nucleo.sessao SET ses_end_date = now()
         WHERE ses_usu_id = s.ses_usu_id AND ses_end_date IS NULL;
        RETURN QUERY SELECT 'REUTILIZADA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    IF s.ses_end_date IS NOT NULL OR s.ses_expira_em < now() THEN
        RETURN QUERY SELECT 'EXPIRADA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM nucleo.usuario WHERE nucleo.usuario.usu_id = s.ses_usu_id
                   AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL) THEN
        UPDATE nucleo.sessao SET ses_end_date = now() WHERE nucleo.sessao.ses_id = s.ses_id;
        RETURN QUERY SELECT 'INVALIDA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    UPDATE nucleo.sessao SET ses_usado_em = now(), ses_end_date = now() WHERE nucleo.sessao.ses_id = s.ses_id;
    INSERT INTO nucleo.sessao (ses_usu_id, ses_refresh_hash, ses_familia, ses_expira_em, ses_ip, ses_navegador)
    VALUES (s.ses_usu_id, p_novo_refresh_hash, s.ses_familia, now() + INTERVAL '30 days', p_ip, left(p_navegador, 255))
    RETURNING nucleo.sessao.ses_id INTO v_novo;
    RETURN QUERY SELECT 'OK'::TEXT, s.ses_usu_id, v_novo;
END $$;

CREATE FUNCTION nucleo.fn_terminar_sessao(p_refresh_hash TEXT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE nucleo.sessao SET ses_end_date = now()
     WHERE ses_refresh_hash = p_refresh_hash AND ses_end_date IS NULL;
END $$;

-- ---------------------------------------------------------------- recuperação de senha
-- A API gera o código de 6 dígitos, guarda aqui o hash e envia o código por SMS/WhatsApp.
-- Devolve o utilizador e o telefone (vazio se o login não existir: a API responde igual nos dois casos).
CREATE FUNCTION nucleo.fn_pedir_recuperacao(p_login TEXT, p_codigo_hash TEXT)
RETURNS TABLE (utilizador INT, telefone VARCHAR)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE u nucleo.usuario%ROWTYPE;
BEGIN
    SELECT * INTO u FROM nucleo.usuario
     WHERE (lower(usu_email) = lower(p_login) OR usu_telefone = p_login)
       AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL;
    IF NOT FOUND THEN RETURN; END IF;
    PERFORM set_config('app.usuario_id', u.usu_id::TEXT, true);
    UPDATE nucleo.recuperacao_senha SET rsn_end_date = now() WHERE rsn_usu_id = u.usu_id AND rsn_end_date IS NULL;
    INSERT INTO nucleo.recuperacao_senha (rsn_usu_id, rsn_codigo_hash, rsn_expira_em)
    VALUES (u.usu_id, p_codigo_hash, now() + INTERVAL '15 minutes');
    RETURN QUERY SELECT u.usu_id, u.usu_telefone;
END $$;

-- Resultado = OK | CODIGO_ERRADO | EXPIRADO (expirado, já usado ou 5 tentativas). Com OK, todas as sessões terminam.
CREATE FUNCTION nucleo.fn_redefinir_senha(p_login TEXT, p_codigo_hash TEXT, p_nova_senha_hash TEXT) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE u INT; r nucleo.recuperacao_senha%ROWTYPE;
BEGIN
    SELECT usu_id INTO u FROM nucleo.usuario
     WHERE (lower(usu_email) = lower(p_login) OR usu_telefone = p_login) AND usu_end_date IS NULL;
    IF u IS NULL THEN RETURN 'EXPIRADO'; END IF;
    PERFORM set_config('app.usuario_id', u::TEXT, true);
    SELECT * INTO r FROM nucleo.recuperacao_senha WHERE rsn_usu_id = u AND rsn_end_date IS NULL ORDER BY rsn_id DESC LIMIT 1;
    IF NOT FOUND OR r.rsn_expira_em < now() OR r.rsn_tentativas >= 5 THEN RETURN 'EXPIRADO'; END IF;
    IF r.rsn_codigo_hash <> p_codigo_hash THEN
        UPDATE nucleo.recuperacao_senha SET rsn_tentativas = rsn_tentativas + 1 WHERE rsn_id = r.rsn_id;
        RETURN 'CODIGO_ERRADO';
    END IF;
    UPDATE nucleo.recuperacao_senha SET rsn_usado_em = now(), rsn_end_date = now() WHERE rsn_id = r.rsn_id;
    UPDATE nucleo.usuario SET usu_senha_hash = p_nova_senha_hash WHERE usu_id = u;
    UPDATE nucleo.sessao SET ses_end_date = now() WHERE ses_usu_id = u AND ses_end_date IS NULL;
    RETURN 'OK';
END $$;

-- ---------------------------------------------------------------- pedidos repetidos
CREATE FUNCTION nucleo.fn_idempotencia_obter(p_chave UUID)
RETURNS TABLE (metodo VARCHAR, caminho VARCHAR, estado_http SMALLINT, resposta JSONB)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT pid_metodo, pid_caminho, pid_estado_http, pid_resposta FROM nucleo.pedido_idempotente
    WHERE pid_usu_id = nucleo.fn_usuario_sessao() AND pid_chave = p_chave
      AND pid_end_date IS NULL AND pid_expira_em > now();
$$;

-- Chamar na mesma transacção SQL do trabalho, antes do COMMIT: ou fica tudo, ou nada
CREATE FUNCTION nucleo.fn_idempotencia_guardar(p_chave UUID, p_metodo TEXT, p_caminho TEXT, p_estado_http INT,
                                               p_resposta JSONB) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF nucleo.fn_usuario_sessao() IS NULL THEN RAISE EXCEPTION 'Sem utilizador identificado na sessão (app.usuario_id)'; END IF;
    INSERT INTO nucleo.pedido_idempotente (pid_chave, pid_usu_id, pid_metodo, pid_caminho, pid_estado_http, pid_resposta, pid_expira_em)
    VALUES (p_chave, nucleo.fn_usuario_sessao(), p_metodo, p_caminho, p_estado_http, p_resposta, now() + INTERVAL '24 hours');
END $$;

-- Tarefa diária: termina as chaves com mais de 24 horas
CREATE FUNCTION nucleo.fn_idempotencia_limpar() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE n INT;
BEGIN
    UPDATE nucleo.pedido_idempotente SET pid_end_date = now() WHERE pid_end_date IS NULL AND pid_expira_em <= now();
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;

-- ---------------------------------------------------------------- ofertas da Escola Sabatina
-- O tesoureiro liga a entrada que lançou ao relatório da classe (sem precisar de poder editar o relatório)
CREATE FUNCTION escola_sabatina.fn_ligar_ofertas(p_ers INT, p_tra BIGINT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE r escola_sabatina.relatorio_sabado%ROWTYPE; t tesouraria.transacao%ROWTYPE;
BEGIN
    SELECT * INTO r FROM escola_sabatina.relatorio_sabado WHERE ers_id = p_ers AND ers_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Relatório inexistente'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.transacao.criar', r.ers_igr_id);
    SELECT * INTO t FROM tesouraria.transacao WHERE tra_id = p_tra AND tra_end_date IS NULL;
    IF NOT FOUND OR t.tra_igr_id <> r.ers_igr_id OR t.tra_tipo <> 'ENTRADA' THEN
        RAISE EXCEPTION 'A transacção tem de ser uma entrada da mesma igreja do relatório';
    END IF;
    IF r.ers_estado = 'FECHADO' THEN RAISE EXCEPTION 'O relatório já está fechado'; END IF;
    UPDATE escola_sabatina.relatorio_sabado SET ers_tra_id = p_tra WHERE ers_id = p_ers;
END $$;

-- todas as funções novas resolvem nomes sempre da mesma forma
DO $$
DECLARE f RECORD;
BEGIN
    FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'escola_sabatina')
               AND p.proname IN ('fn_login_bloqueado_ate', 'fn_login_falhou', 'fn_abrir_sessao', 'fn_renovar_sessao',
                                 'fn_terminar_sessao', 'fn_pedir_recuperacao', 'fn_redefinir_senha',
                                 'fn_idempotencia_obter', 'fn_idempotencia_guardar', 'fn_idempotencia_limpar',
                                 'fn_ligar_ofertas') LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public', f.sig);
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO app_igreja', f.sig);
    END LOOP;
END $$;

-- >>>>> V15__perfis_proprios_e_manutencao.sql
-- =====================================================================
-- V15 · Perfis próprios e tarefas de manutenção
--
--   1. Cada utilizador vê os seus próprios perfis (GET /v1/eu): até aqui só quem tinha
--      nucleo.usuario_igreja.ler os via; um tesoureiro não sabia que perfis tinha.
--   2. Partições mensais do log de auditoria: só o dono das tabelas cria partições. A função
--      passa a correr com os privilégios do sistema para a tarefa agendada da API a poder chamar.
--   3. Retenção dos visitantes da Escola Sabatina: 12 meses depois da visita, quem não se tornou
--      membro fica sem nome nem telefone (escola_sabatina.vw_visitantes_a_anonimizar).
--      O log de auditoria desta alteração não guarda os valores antigos (senão o nome continuaria lá).
--      Limitação: alterações anteriores do visitante que já estejam no log mantêm-se (o log é imutável).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- 1. perfis próprios
CREATE POLICY pol_uig_proprio ON nucleo.usuario_igreja FOR SELECT
    USING (uig_usu_id = (SELECT nucleo.fn_usuario_sessao()));

CREATE POLICY pol_uen_proprio ON nucleo.usuario_entidade FOR SELECT
    USING (uen_usu_id = (SELECT nucleo.fn_usuario_sessao()));

-- ---------------------------------------------------------------- 2. partições do log
ALTER FUNCTION nucleo.fn_criar_particoes_log(INT) SECURITY DEFINER;

-- ---------------------------------------------------------------- 3. retenção dos visitantes
-- Igual à função de V1, com uma única diferença: durante uma anonimização não guarda os valores antigos.
CREATE OR REPLACE FUNCTION nucleo.fn_log_auditoria() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE
    p      TEXT  := TG_ARGV[0];
    n      JSONB := to_jsonb(NEW);
    o      JSONB;
    antes  JSONB := NULL;
    depois JSONB := n;
    accao  TEXT  := TG_OP;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        o := to_jsonb(OLD);
        SELECT jsonb_object_agg(k, o -> k), jsonb_object_agg(k, n -> k)
          INTO antes, depois
          FROM jsonb_object_keys(n) k
         WHERE (o -> k) IS DISTINCT FROM (n -> k)
           AND k NOT IN (p || '_modificado_em', p || '_modificado_por');
        IF depois IS NULL THEN
            RETURN NULL;                              -- nada mudou de facto
        END IF;
        IF o ->> (p || '_end_date') IS NULL AND n ->> (p || '_end_date') IS NOT NULL THEN
            accao := 'TERMINO';
        END IF;
        IF current_setting('app.anonimizacao', true) = 'on' THEN
            antes := NULL;                            -- dados pessoais apagados: não ficam no histórico
        END IF;
    END IF;
    INSERT INTO nucleo.log_auditoria (lau_usu_id, lau_tabela, lau_registo_id, lau_accao, lau_dados_antes, lau_dados_depois)
    VALUES (nucleo.fn_usuario_sessao(), TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            (n ->> (p || '_id'))::BIGINT, accao, antes, depois);
    RETURN NULL;
END $$;

-- Tarefa diária (API): anonimiza os visitantes com mais de 12 meses que não se tornaram membros.
-- Devolve quantos foram anonimizados.
CREATE FUNCTION escola_sabatina.fn_anonimizar_visitantes() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE n INT;
BEGIN
    PERFORM set_config('app.anonimizacao', 'on', true);
    UPDATE escola_sabatina.visitante v
       SET evi_nome = 'Anonimizado', evi_telefone = NULL, evi_anonimizado_em = now()
      FROM escola_sabatina.relatorio_sabado r
      JOIN escola_sabatina.sabado s ON s.esa_id = r.ers_esa_id
     WHERE r.ers_id = v.evi_ers_id
       AND v.evi_end_date IS NULL AND v.evi_anonimizado_em IS NULL AND v.evi_tornou_se_mem_id IS NULL
       AND s.esa_data < CURRENT_DATE - INTERVAL '12 months';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM set_config('app.anonimizacao', 'off', true);
    RETURN n;
END $$;

ALTER FUNCTION escola_sabatina.fn_anonimizar_visitantes()
    SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;
GRANT EXECUTE ON FUNCTION escola_sabatina.fn_anonimizar_visitantes() TO app_igreja;

-- >>>>> V16__correccoes_da_auditoria.sql
-- =====================================================================
-- V16 · Correcções da auditoria técnica (docs/AUDITORIA.md)
--
--   H3  o log de auditoria deixa de guardar hashes de senhas (e limpa os que já lá estão)
--   M1  nucleo.fn_sessao_activa: a API recusa tokens de acesso de sessões terminadas ou de
--       utilizadores inactivos (logout, senha redefinida, token reutilizado)
--   M2  renovar a sessão bloqueia a linha; dois pedidos simultâneos com o mesmo token
--       (dois separadores) já não terminam todas as sessões: o segundo recebe CONCORRENTE
--   M3  login sem distinguir maiúsculas no e-mail, igual em todo o lado, com índice único
--   M7  pesquisa de membros por nome com índice trigram
--   M8  aprovações e numeração de recibos sem corridas (FOR UPDATE / bloqueio por igreja e ano)
--   L3  Idempotency-Key guarda o hash do pedido: a mesma chave com outro corpo é recusada
--   L5  limpeza diária das sessões, códigos de recuperação e bloqueios antigos
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- H3 · senhas fora do log
CREATE OR REPLACE FUNCTION nucleo.fn_log_auditoria() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE
    p      TEXT  := TG_ARGV[0];
    n      JSONB := to_jsonb(NEW);
    o      JSONB;
    antes  JSONB := NULL;
    depois JSONB := n;
    accao  TEXT  := TG_OP;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        o := to_jsonb(OLD);
        SELECT jsonb_object_agg(k, o -> k), jsonb_object_agg(k, n -> k)
          INTO antes, depois
          FROM jsonb_object_keys(n) k
         WHERE (o -> k) IS DISTINCT FROM (n -> k)
           AND k NOT IN (p || '_modificado_em', p || '_modificado_por');
        IF depois IS NULL THEN
            RETURN NULL;                              -- nada mudou de facto
        END IF;
        IF o ->> (p || '_end_date') IS NULL AND n ->> (p || '_end_date') IS NOT NULL THEN
            accao := 'TERMINO';
        END IF;
        IF current_setting('app.anonimizacao', true) = 'on' THEN
            antes := NULL;                            -- dados pessoais apagados: não ficam no histórico (V15)
        END IF;
    END IF;
    -- hashes de senhas nunca ficam no histórico: fica só a indicação de que a senha mudou
    IF depois ? (p || '_senha_hash') THEN
        depois := jsonb_set(depois, ARRAY[p || '_senha_hash'], '"(alterada)"');
    END IF;
    IF antes ? (p || '_senha_hash') THEN
        antes := antes - (p || '_senha_hash');
    END IF;
    INSERT INTO nucleo.log_auditoria (lau_usu_id, lau_tabela, lau_registo_id, lau_accao, lau_dados_antes, lau_dados_depois)
    VALUES (nucleo.fn_usuario_sessao(), TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            (n ->> (p || '_id'))::BIGINT, accao, antes, depois);
    RETURN NULL;
END $$;

-- limpar os hashes que já estão no log. O log é imutável: o trigger que o protege é desligado só aqui,
-- na tabela e em cada partição (conforme a versão do PostgreSQL, desligar na tabela-mãe pode não chegar às partições).
DO $$
DECLARE t regclass;
BEGIN
    FOR t IN SELECT 'nucleo.log_auditoria'::regclass
             UNION ALL SELECT inhrelid::regclass FROM pg_inherits WHERE inhparent = 'nucleo.log_auditoria'::regclass LOOP
        EXECUTE format('ALTER TABLE %s DISABLE TRIGGER trg_lau_00_imutavel', t);
    END LOOP;
    UPDATE nucleo.log_auditoria
       SET lau_dados_antes  = lau_dados_antes - 'usu_senha_hash',
           lau_dados_depois = CASE WHEN lau_dados_depois ? 'usu_senha_hash'
                                   THEN jsonb_set(lau_dados_depois, '{usu_senha_hash}', '"(alterada)"')
                                   ELSE lau_dados_depois END
     WHERE lau_tabela = 'nucleo.usuario'
       AND (lau_dados_antes ? 'usu_senha_hash' OR lau_dados_depois ? 'usu_senha_hash');
    FOR t IN SELECT 'nucleo.log_auditoria'::regclass
             UNION ALL SELECT inhrelid::regclass FROM pg_inherits WHERE inhparent = 'nucleo.log_auditoria'::regclass LOOP
        EXECUTE format('ALTER TABLE %s ENABLE TRIGGER trg_lau_00_imutavel', t);
    END LOOP;
END $$;

-- ---------------------------------------------------------------- M3 · login sem maiúsculas
-- Falha (de propósito) se já houver dois utilizadores activos com o mesmo e-mail em maiúsculas diferentes.
CREATE UNIQUE INDEX uq_usu_email_ci ON nucleo.usuario (lower(usu_email)) WHERE usu_end_date IS NULL;

CREATE OR REPLACE FUNCTION nucleo.fn_credenciais(p_login TEXT)
RETURNS TABLE (usu_id INT, senha_hash VARCHAR, estado nucleo.estado_registo_t)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
    SELECT u.usu_id, u.usu_senha_hash, u.usu_estado
    FROM nucleo.usuario u
    WHERE (lower(u.usu_email) = lower(p_login) OR u.usu_telefone = p_login) AND u.usu_end_date IS NULL;
$$;

-- ---------------------------------------------------------------- M1 · token de acesso só com sessão activa
-- A sessão do token (sid) pertence a uma "família" (renovações sucessivas). O token vale enquanto a família
-- tiver uma sessão activa e o utilizador estiver activo.
CREATE FUNCTION nucleo.fn_sessao_activa(p_usu INT, p_ses BIGINT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
    SELECT EXISTS (
        SELECT 1
          FROM nucleo.sessao s
          JOIN nucleo.sessao f ON f.ses_familia = s.ses_familia AND f.ses_usu_id = s.ses_usu_id
          JOIN nucleo.usuario u ON u.usu_id = s.ses_usu_id
         WHERE s.ses_id = p_ses AND s.ses_usu_id = p_usu
           AND f.ses_end_date IS NULL AND f.ses_expira_em > now()
           AND u.usu_estado = 'ACTIVO' AND u.usu_end_date IS NULL);
$$;
CREATE INDEX idx_ses_familia_activas ON nucleo.sessao (ses_familia) WHERE ses_end_date IS NULL;
GRANT EXECUTE ON FUNCTION nucleo.fn_sessao_activa(INT, BIGINT) TO app_igreja;

-- ---------------------------------------------------------------- M2 · renovação sem corrida
-- Igual à V14, com FOR UPDATE e o resultado CONCORRENTE: o token acabou de ser trocado (há menos de
-- 10 segundos) por outro pedido do mesmo navegador; não é roubo, não se terminam as sessões.
CREATE OR REPLACE FUNCTION nucleo.fn_renovar_sessao(p_refresh_hash TEXT, p_novo_refresh_hash TEXT, p_ip INET DEFAULT NULL,
                                                    p_navegador TEXT DEFAULT NULL)
RETURNS TABLE (resultado TEXT, utilizador INT, sessao_id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE s nucleo.sessao%ROWTYPE; v_novo BIGINT;
BEGIN
    SELECT * INTO s FROM nucleo.sessao WHERE ses_refresh_hash = p_refresh_hash
     ORDER BY nucleo.sessao.ses_id DESC LIMIT 1 FOR UPDATE;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'INVALIDA'::TEXT, NULL::INT, NULL::BIGINT; RETURN;
    END IF;
    PERFORM set_config('app.usuario_id', s.ses_usu_id::TEXT, true);
    IF s.ses_usado_em IS NOT NULL THEN
        IF s.ses_usado_em > now() - INTERVAL '10 seconds' THEN
            RETURN QUERY SELECT 'CONCORRENTE'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
        END IF;
        UPDATE nucleo.sessao SET ses_end_date = now()
         WHERE ses_usu_id = s.ses_usu_id AND ses_end_date IS NULL;
        RETURN QUERY SELECT 'REUTILIZADA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    IF s.ses_end_date IS NOT NULL OR s.ses_expira_em < now() THEN
        RETURN QUERY SELECT 'EXPIRADA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM nucleo.usuario WHERE nucleo.usuario.usu_id = s.ses_usu_id
                   AND usu_estado = 'ACTIVO' AND usu_end_date IS NULL) THEN
        UPDATE nucleo.sessao SET ses_end_date = now() WHERE nucleo.sessao.ses_id = s.ses_id;
        RETURN QUERY SELECT 'INVALIDA'::TEXT, s.ses_usu_id, NULL::BIGINT; RETURN;
    END IF;
    UPDATE nucleo.sessao SET ses_usado_em = now(), ses_end_date = now() WHERE nucleo.sessao.ses_id = s.ses_id;
    INSERT INTO nucleo.sessao (ses_usu_id, ses_refresh_hash, ses_familia, ses_expira_em, ses_ip, ses_navegador)
    VALUES (s.ses_usu_id, p_novo_refresh_hash, s.ses_familia, now() + INTERVAL '30 days', p_ip, left(p_navegador, 255))
    RETURNING nucleo.sessao.ses_id INTO v_novo;
    RETURN QUERY SELECT 'OK'::TEXT, s.ses_usu_id, v_novo;
END $$;

-- ---------------------------------------------------------------- M8 · aprovações sem corridas
-- Iguais à V7, com a linha bloqueada (FOR UPDATE): um segundo pedido simultâneo espera e depois
-- vê o estado já mudado.
CREATE OR REPLACE FUNCTION tesouraria.fn_aprovar_saida(p_tra BIGINT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE r tesouraria.transacao%ROWTYPE;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = p_tra AND tra_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR r.tra_tipo <> 'SAIDA' OR r.tra_estado <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Só se aprova uma saída pendente';
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.transacao.aprovar', r.tra_igr_id);
    UPDATE tesouraria.transacao SET tra_aprovado_por_usu_id = nucleo.fn_usuario_sessao() WHERE tra_id = p_tra;
END $$;

CREATE OR REPLACE FUNCTION tesouraria.fn_decidir_despesa(p_des INT, p_aprovar BOOLEAN, p_valor NUMERIC DEFAULT NULL,
                                                         p_motivo TEXT DEFAULT NULL) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE d tesouraria.despesa%ROWTYPE;
BEGIN
    SELECT * INTO d FROM tesouraria.despesa WHERE des_id = p_des AND des_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR d.des_estado <> 'SUBMETIDA' THEN RAISE EXCEPTION 'Só se decide uma despesa submetida'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.despesa.aprovar', d.des_igr_id);
    UPDATE tesouraria.despesa
       SET des_estado = CASE WHEN p_aprovar THEN 'APROVADA' ELSE 'REJEITADA' END::nucleo.estado_despesa_t,
           des_valor_aprovado = CASE WHEN p_aprovar THEN COALESCE(p_valor, d.des_valor_solicitado) END,
           des_motivo_rejeicao = CASE WHEN NOT p_aprovar THEN p_motivo END
     WHERE des_id = p_des;
END $$;

CREATE OR REPLACE FUNCTION tesouraria.fn_aprovar_orcamento(p_orc INT, p_vot INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE o tesouraria.orcamento%ROWTYPE;
BEGIN
    SELECT * INTO o FROM tesouraria.orcamento WHERE orc_id = p_orc AND orc_end_date IS NULL FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Orçamento inexistente'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.orcamento.aprovar', o.orc_igr_id);
    UPDATE tesouraria.orcamento SET orc_estado = 'APROVADO', orc_vot_id = p_vot WHERE orc_id = p_orc;
END $$;

CREATE OR REPLACE FUNCTION tesouraria.fn_confirmar_remessa(p_rem INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE r tesouraria.remessa%ROWTYPE;
BEGIN
    SELECT * INTO r FROM tesouraria.remessa WHERE rem_id = p_rem AND rem_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR r.rem_estado <> 'ENVIADA' THEN RAISE EXCEPTION 'Só se confirma uma remessa enviada'; END IF;
    PERFORM nucleo.fn_exigir('tesouraria.remessa.confirmar', r.rem_igr_id);
    UPDATE tesouraria.remessa SET rem_estado = 'CONFIRMADA' WHERE rem_id = p_rem;
END $$;

-- Número do recibo: dois recibos da mesma igreja e ano ao mesmo tempo esperam um pelo outro
-- (bloqueio até ao fim da transacção) em vez de um falhar com número repetido.
CREATE OR REPLACE FUNCTION tesouraria.fn_proximo_recibo(p_igr INT, p_ano INT) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(p_igr, p_ano);
    RETURN (SELECT COALESCE(max(rec_numero), 0) + 1 FROM tesouraria.recibo WHERE rec_igr_id = p_igr AND rec_ano = p_ano);
END $$;

-- ---------------------------------------------------------------- M7 · pesquisa de membros por nome
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_mem_nome_trgm ON secretaria.membro USING gin ((mem_nome || ' ' || mem_apelido) gin_trgm_ops)
    WHERE mem_end_date IS NULL;

-- ---------------------------------------------------------------- L3 · Idempotency-Key com o hash do pedido
ALTER TABLE nucleo.pedido_idempotente ADD COLUMN pid_pedido_hash VARCHAR(64);
COMMENT ON COLUMN nucleo.pedido_idempotente.pid_pedido_hash IS 'SHA-256 do corpo do pedido: a mesma chave com outro corpo é recusada';

DROP FUNCTION nucleo.fn_idempotencia_obter(UUID);
CREATE FUNCTION nucleo.fn_idempotencia_obter(p_chave UUID)
RETURNS TABLE (metodo VARCHAR, caminho VARCHAR, estado_http SMALLINT, resposta JSONB, pedido_hash VARCHAR)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
    SELECT pid_metodo, pid_caminho, pid_estado_http, pid_resposta, pid_pedido_hash FROM nucleo.pedido_idempotente
    WHERE pid_usu_id = nucleo.fn_usuario_sessao() AND pid_chave = p_chave
      AND pid_end_date IS NULL AND pid_expira_em > now();
$$;

DROP FUNCTION nucleo.fn_idempotencia_guardar(UUID, TEXT, TEXT, INT, JSONB);
CREATE FUNCTION nucleo.fn_idempotencia_guardar(p_chave UUID, p_metodo TEXT, p_caminho TEXT, p_estado_http INT,
                                               p_resposta JSONB, p_pedido_hash TEXT DEFAULT NULL) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
BEGIN
    IF nucleo.fn_usuario_sessao() IS NULL THEN RAISE EXCEPTION 'Sem utilizador identificado na sessão (app.usuario_id)'; END IF;
    INSERT INTO nucleo.pedido_idempotente (pid_chave, pid_usu_id, pid_metodo, pid_caminho, pid_estado_http, pid_resposta,
                                           pid_pedido_hash, pid_expira_em)
    VALUES (p_chave, nucleo.fn_usuario_sessao(), p_metodo, p_caminho, p_estado_http, p_resposta, p_pedido_hash,
            now() + INTERVAL '24 hours');
END $$;
GRANT EXECUTE ON FUNCTION nucleo.fn_idempotencia_obter(UUID) TO app_igreja;
GRANT EXECUTE ON FUNCTION nucleo.fn_idempotencia_guardar(UUID, TEXT, TEXT, INT, JSONB, TEXT) TO app_igreja;

-- ---------------------------------------------------------------- L5 · limpeza diária
-- Termina (não apaga) sessões expiradas, códigos de recuperação expirados e contadores de falhas de login
-- parados há mais de um dia. Devolve quantos registos terminou.
CREATE FUNCTION nucleo.fn_limpar_sessoes() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public
AS $$
DECLARE n INT; total INT := 0;
BEGIN
    UPDATE nucleo.sessao SET ses_end_date = now() WHERE ses_end_date IS NULL AND ses_expira_em <= now();
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    UPDATE nucleo.recuperacao_senha SET rsn_end_date = now() WHERE rsn_end_date IS NULL AND rsn_expira_em <= now();
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    UPDATE nucleo.bloqueio_login SET blq_end_date = now()
     WHERE blq_end_date IS NULL AND blq_modificado_em < now() - INTERVAL '1 day'
       AND (blq_bloqueado_ate IS NULL OR blq_bloqueado_ate < now());
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    RETURN total;
END $$;
GRANT EXECUTE ON FUNCTION nucleo.fn_limpar_sessoes() TO app_igreja;

-- ---------------------------------------------------------------- conferência das ofertas da ES
-- Encontrado ao correr os testes de integração: a vista lia a transacção com as permissões de quem consulta;
-- o Director da ES (sem tesouraria.transacao.ler) via "Por lançar" em ofertas já lançadas e confirmadas.
-- Um relatório FECHADO está sempre conferido (escola_sabatina.fn_ers_validar só o deixa fechar com as ofertas
-- confirmadas e iguais às da tesouraria); um lançamento que o utilizador não vê é indicado como tal.
CREATE OR REPLACE VIEW escola_sabatina.vw_conferencia_ofertas WITH (security_invoker = true) AS
SELECT r.ers_id, r.ers_igr_id, c.ecl_nome AS classe, s.esa_data AS data,
       r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas AS oferta_relatorio,
       t.tra_valor_total AS lancado_tesouraria, t.tra_estado AS estado_lancamento,
       CASE WHEN r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas = 0 THEN 'Sem oferta'
            WHEN r.ers_estado = 'FECHADO' THEN 'Conferido'
            WHEN r.ers_tra_id IS NULL THEN 'Por lançar'
            WHEN t.tra_id IS NULL THEN 'Lançado (sem acesso à tesouraria)'
            WHEN t.tra_estado <> 'CONFIRMADA' THEN 'Lançamento por confirmar'
            WHEN t.tra_valor_total <> r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas THEN 'Valores diferentes'
            ELSE 'Conferido' END AS situacao
FROM escola_sabatina.relatorio_sabado r
JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = r.ers_ect_id
JOIN escola_sabatina.classe c            ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s            ON s.esa_id = r.ers_esa_id
LEFT JOIN tesouraria.transacao t         ON t.tra_id = r.ers_tra_id
WHERE r.ers_end_date IS NULL;

-- >>>>> V17__escalas_e_lembretes.sql
-- =====================================================================
-- V17 · Escalas da igreja (planos, dias, funções da escala de pregação) e lembretes por SMS
--
--   actividades.escala_plano   a escala de um período (ex.: escala de pregação do IV trimestre), assinada
--                              pelo ancião e pelo secretário; só a publicada é vista pelos membros
--   actividades.escala_dia     cada culto: grupo coral, departamento ou evento especial (13.º sábado, simpósio)
--   actividades.escala         (já existia) quem faz o quê; passa a poder pertencer a um dia do plano
--   funções novas              TRADUTOR e os três acompanhantes do pregador
--   lembretes                  actividades.fn_lembretes_escala: SMS à quarta e à sexta para o sábado (18:00)
--   envio da fila              comunicacao.fn_notificacoes_reservar / fn_notificacao_resultado (tarefa da API)
--
-- Gerado com database/gerador (defs.py, sql/actividades_regras.sql, sql/comunicacao_regras.sql,
-- sql/vistas.sql); só a parte nova, como manda o CLAUDE.md.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- funções novas da escala
-- (os valores novos não se usam nesta migração: o PostgreSQL só os aceita depois do COMMIT)
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'TRADUTOR';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ACOMPANHANTE_VISITAS';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ACOMPANHANTE_OFERTAS';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ACOMPANHANTE_BOAS_VINDAS';

-- ---------------------------------------------------------------- tabelas
-- Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada
CREATE TABLE actividades.escala_plano (
    epl_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    epl_igr_id INT NOT NULL,
    epl_titulo VARCHAR(150) NOT NULL,
    epl_data_inicio DATE NOT NULL,
    epl_data_fim DATE NOT NULL,
    epl_etr_id INT,
    epl_local_emissao VARCHAR(100),
    epl_data_emissao DATE,
    epl_anciao_mem_id INT,
    epl_secretario_mem_id INT,
    epl_publicada BOOLEAN NOT NULL DEFAULT FALSE,
    epl_observacoes VARCHAR(500),
    epl_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    epl_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epl_criado_por INT,
    epl_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    epl_modificado_por INT,
    epl_end_date TIMESTAMPTZ,
    CONSTRAINT fk_epl_igr_id FOREIGN KEY (epl_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_epl_anciao_mem_id FOREIGN KEY (epl_anciao_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_epl_secretario_mem_id FOREIGN KEY (epl_secretario_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_epl_datas CHECK (epl_data_fim >= epl_data_inicio),
    CONSTRAINT chk_epl_end_date CHECK (epl_end_date IS NULL OR epl_end_date >= epl_criado_em)
);
COMMENT ON TABLE actividades.escala_plano IS 'Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada';
COMMENT ON COLUMN actividades.escala_plano.epl_titulo IS 'Ex.: Escala de Pregação';
COMMENT ON COLUMN actividades.escala_plano.epl_etr_id IS 'Trimestre (opcional)';
COMMENT ON COLUMN actividades.escala_plano.epl_local_emissao IS 'Ex.: Matola';
COMMENT ON COLUMN actividades.escala_plano.epl_anciao_mem_id IS 'Ancião que assina';
COMMENT ON COLUMN actividades.escala_plano.epl_secretario_mem_id IS 'Secretário que assina';
COMMENT ON COLUMN actividades.escala_plano.epl_publicada IS 'Só as escalas publicadas são vistas pelos membros e geram lembretes';
CREATE INDEX idx_epl_igr_id ON actividades.escala_plano (epl_igr_id);
CREATE INDEX idx_epl_etr_id ON actividades.escala_plano (epl_etr_id);
CREATE INDEX idx_epl_anciao_mem_id ON actividades.escala_plano (epl_anciao_mem_id);
CREATE INDEX idx_epl_secretario_mem_id ON actividades.escala_plano (epl_secretario_mem_id);
CREATE INDEX idx_epl_igr_periodo ON actividades.escala_plano (epl_igr_id, epl_data_inicio) WHERE epl_end_date IS NULL;

-- Um dia (culto) da escala: grupo coral, departamento ou evento especial
CREATE TABLE actividades.escala_dia (
    eds_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    eds_epl_id INT NOT NULL,
    eds_data DATE NOT NULL,
    eds_evento VARCHAR(200),
    eds_grupo_coral VARCHAR(100),
    eds_ide_id INT,
    eds_observacoes VARCHAR(255),
    eds_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    eds_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    eds_criado_por INT,
    eds_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    eds_modificado_por INT,
    eds_end_date TIMESTAMPTZ,
    CONSTRAINT fk_eds_epl_id FOREIGN KEY (eds_epl_id) REFERENCES actividades.escala_plano(epl_id),
    CONSTRAINT fk_eds_ide_id FOREIGN KEY (eds_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT chk_eds_end_date CHECK (eds_end_date IS NULL OR eds_end_date >= eds_criado_em)
);
COMMENT ON TABLE actividades.escala_dia IS 'Um dia (culto) da escala: grupo coral, departamento ou evento especial';
COMMENT ON COLUMN actividades.escala_dia.eds_evento IS 'Dia especial que substitui a escala (ex.: Simpósio, 13.º sábado)';
COMMENT ON COLUMN actividades.escala_dia.eds_ide_id IS 'Departamento responsável';
CREATE UNIQUE INDEX uq_eds_epl_id_data ON actividades.escala_dia (eds_epl_id, eds_data) WHERE eds_end_date IS NULL;
CREATE INDEX idx_eds_ide_id ON actividades.escala_dia (eds_ide_id);

ALTER TABLE actividades.escala ADD COLUMN esc_eds_id INT;
COMMENT ON COLUMN actividades.escala.esc_eds_id IS 'Dia da escala (plano) a que pertence; a data e a igreja vêm do dia';
CREATE INDEX idx_esc_eds_id ON actividades.escala (esc_eds_id);
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_eds_id FOREIGN KEY (esc_eds_id) REFERENCES actividades.escala_dia(eds_id);
ALTER TABLE actividades.escala_plano ADD CONSTRAINT fk_epl_etr_id FOREIGN KEY (epl_etr_id) REFERENCES escola_sabatina.trimestre(etr_id);

ALTER TABLE comunicacao.notificacao ADD COLUMN ntf_chave VARCHAR(100);
COMMENT ON COLUMN comunicacao.notificacao.ntf_chave IS 'Evita repetir a mesma notificação (ex.: escala:12:2026-11-11)';
CREATE UNIQUE INDEX uq_ntf_chave ON comunicacao.notificacao (ntf_chave) WHERE ntf_end_date IS NULL;

-- ---------------------------------------------------------------- regras
-- Regras das escalas (V17) ------------------------------------------------

-- Nome de cada função para as mensagens (compara como texto: funciona na mesma transacção que acrescenta valores ao tipo)
CREATE FUNCTION actividades.fn_funcao_escala_nome(p_funcao nucleo.funcao_escala_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_funcao::text
        WHEN 'PREGADOR' THEN 'pregador(a)'
        WHEN 'ANCIAO_DO_DIA' THEN 'ancião do dia'
        WHEN 'DIACONO' THEN 'diácono'
        WHEN 'DIACONISA' THEN 'diaconisa'
        WHEN 'RECEPCAO' THEN 'recepção'
        WHEN 'MUSICA' THEN 'música'
        WHEN 'SONOPLASTIA' THEN 'sonoplastia'
        WHEN 'PROFESSOR_ES' THEN 'professor(a) da Escola Sabatina'
        WHEN 'DIRECTOR_ES' THEN 'director(a) da Escola Sabatina'
        WHEN 'LIMPEZA' THEN 'limpeza'
        WHEN 'TRADUTOR' THEN 'tradutor(a)'
        WHEN 'ACOMPANHANTE_VISITAS' THEN 'acompanhante (visitas e 2.ª oração)'
        WHEN 'ACOMPANHANTE_OFERTAS' THEN 'acompanhante (dízimos e ofertas)'
        WHEN 'ACOMPANHANTE_BOAS_VINDAS' THEN 'acompanhante (boas-vindas e 1.ª oração)'
        ELSE 'serviço' END;
$$;

-- Escala ligada a um dia do plano: a data e a igreja vêm do dia (não se escrevem duas vezes)
CREATE FUNCTION actividades.fn_esc_dia() RETURNS trigger AS $$
BEGIN
    IF NEW.esc_eds_id IS NOT NULL THEN
        SELECT d.eds_data, p.epl_igr_id INTO NEW.esc_data, NEW.esc_igr_id
        FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
        WHERE d.eds_id = NEW.esc_eds_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_esc_05_dia
    BEFORE INSERT OR UPDATE OF esc_eds_id, esc_data, esc_igr_id ON actividades.escala
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_esc_dia();

-- Dia da escala: dentro do período do plano
CREATE FUNCTION actividades.fn_eds_validar() RETURNS trigger AS $$
DECLARE p actividades.escala_plano%ROWTYPE;
BEGIN
    SELECT * INTO p FROM actividades.escala_plano WHERE epl_id = NEW.eds_epl_id;
    IF NEW.eds_data < p.epl_data_inicio OR NEW.eds_data > p.epl_data_fim THEN
        RAISE EXCEPTION 'O dia % está fora do período da escala (% a %)', to_char(NEW.eds_data, 'DD/MM/YYYY'),
            to_char(p.epl_data_inicio, 'DD/MM/YYYY'), to_char(p.epl_data_fim, 'DD/MM/YYYY');
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_eds_10_validar
    BEFORE INSERT OR UPDATE ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_validar();

-- Mudou a data do dia: as escalas desse dia acompanham
CREATE FUNCTION actividades.fn_eds_data() RETURNS trigger AS $$
BEGIN
    UPDATE actividades.escala SET esc_data = NEW.eds_data
     WHERE esc_eds_id = NEW.eds_id AND esc_end_date IS NULL AND esc_data IS DISTINCT FROM NEW.eds_data;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_eds_20_data
    AFTER UPDATE OF eds_data ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_data();

-- Elaborar a escala: cria um dia para cada sábado (ou outro dia da semana, 1 = segunda … 7 = domingo) do período
-- que ainda não tenha dia. Corre com as permissões de quem a chama (RLS de escala_dia). Devolve quantos criou.
CREATE FUNCTION actividades.fn_gerar_dias_escala(p_epl INT, p_dia_semana INT DEFAULT 6) RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE p actividades.escala_plano%ROWTYPE; n INT;
BEGIN
    IF p_dia_semana NOT BETWEEN 1 AND 7 THEN RAISE EXCEPTION 'Dia da semana inválido: % (1 = segunda … 7 = domingo)', p_dia_semana; END IF;
    SELECT * INTO p FROM actividades.escala_plano WHERE epl_id = p_epl AND epl_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Escala inexistente'; END IF;
    INSERT INTO actividades.escala_dia (eds_epl_id, eds_data)
    SELECT p_epl, d::date FROM generate_series(p.epl_data_inicio, p.epl_data_fim, INTERVAL '1 day') d
    WHERE EXTRACT(ISODOW FROM d) = p_dia_semana
      AND NOT EXISTS (SELECT 1 FROM actividades.escala_dia x
                      WHERE x.eds_epl_id = p_epl AND x.eds_data = d::date AND x.eds_end_date IS NULL);
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;

-- Lembretes por SMS a quem está escalado: à quarta e à sexta, para o sábado seguinte, às 18:00 (hora de Maputo).
-- Só escalas publicadas (ou escalas soltas, sem plano), dias sem evento especial, quem tem telefone e deu
-- consentimento para SMS. Quem substitui recebe no lugar do escalado. Corre de hora a hora (tarefa da API):
-- a chave da notificação impede repetições; depois das 20:00 já não cria (não se mandam SMS à noite).
-- Devolve quantas mensagens pôs na fila (comunicacao.notificacao).
CREATE FUNCTION actividades.fn_lembretes_escala(p_agora TIMESTAMPTZ DEFAULT now()) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_local  TIMESTAMP := p_agora AT TIME ZONE 'Africa/Maputo';
    v_hoje   DATE := (p_agora AT TIME ZONE 'Africa/Maputo')::date;
    v_dia    INT := EXTRACT(ISODOW FROM (p_agora AT TIME ZONE 'Africa/Maputo'));
    v_sabado DATE;
    v_envio  TIMESTAMPTZ;
    n INT;
BEGIN
    IF v_dia NOT IN (3, 5) OR v_local::time >= TIME '20:00' THEN
        RETURN 0;
    END IF;
    v_sabado := v_hoje + (6 - v_dia);
    v_envio := GREATEST(p_agora, (v_hoje + TIME '18:00') AT TIME ZONE 'Africa/Maputo');
    INSERT INTO comunicacao.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                         ntf_agendada_para, ntf_origem_tabela, ntf_origem_id, ntf_chave)
    SELECT e.esc_igr_id, x.mem_id, 'SMS', x.telefone, 'Escala de ' || to_char(v_sabado, 'DD/MM'),
           left(i.igr_nome, 40) || ': lembrete - no sábado ' || to_char(v_sabado, 'DD/MM') || ' está escalado(a) como '
               || actividades.fn_funcao_escala_nome(e.esc_funcao) || '. Deus o(a) abençoe.',
           v_envio, 'actividades.escala', e.esc_id, 'escala:' || e.esc_id || ':' || v_hoje
    FROM actividades.escala e
    JOIN organizacao.igreja i ON i.igr_id = e.esc_igr_id
    LEFT JOIN actividades.escala_dia d ON d.eds_id = e.esc_eds_id
    LEFT JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
    CROSS JOIN LATERAL (
        SELECT c.cto_mem_id AS mem_id, c.cto_valor AS telefone
        FROM secretaria.contacto c
        WHERE c.cto_mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
          AND c.cto_end_date IS NULL AND c.cto_estado = 'ACTIVO' AND c.cto_tipo IN ('TELEFONE', 'WHATSAPP')
        ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) x
    WHERE e.esc_data = v_sabado AND e.esc_end_date IS NULL
      AND e.esc_estado IN ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA')
      AND (e.esc_eds_id IS NULL
           OR (p.epl_publicada AND p.epl_end_date IS NULL AND d.eds_end_date IS NULL AND d.eds_evento IS NULL))
      AND EXISTS (SELECT 1 FROM secretaria.consentimento s
                  WHERE s.cns_mem_id = x.mem_id AND s.cns_end_date IS NULL AND s.cns_concedido
                    AND s.cns_tipo = 'CONTACTO_SMS')
    ON CONFLICT (ntf_chave) WHERE ntf_end_date IS NULL DO NOTHING;
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;

-- Envio da fila (V17) ------------------------------------------------------
-- A tarefa da API (sem utilizador) reserva até p_limite SMS por enviar. A reserva conta a tentativa e adia a
-- mensagem 10 minutos: se a API parar a meio, a mensagem volta à fila em vez de se perder ou sair duas vezes.
CREATE FUNCTION comunicacao.fn_notificacoes_reservar(p_limite INT DEFAULT 50)
RETURNS TABLE (id BIGINT, destino VARCHAR, mensagem TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    UPDATE comunicacao.notificacao n
       SET ntf_tentativas = n.ntf_tentativas + 1, ntf_agendada_para = now() + INTERVAL '10 minutes'
     WHERE n.ntf_id IN (SELECT x.ntf_id FROM comunicacao.notificacao x
                        WHERE x.ntf_estado = 'PENDENTE' AND x.ntf_end_date IS NULL AND x.ntf_canal = 'SMS'
                          AND x.ntf_agendada_para <= now()
                        ORDER BY x.ntf_agendada_para LIMIT p_limite
                        FOR UPDATE SKIP LOCKED)
    RETURNING n.ntf_id, n.ntf_destino, n.ntf_mensagem;
END $$;

-- Resultado do envio: ENVIADA; ou o erro, e nova tentativa daqui a 15 minutos (à 5.ª tentativa fica FALHADA)
CREATE FUNCTION comunicacao.fn_notificacao_resultado(p_id BIGINT, p_enviada BOOLEAN, p_erro TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE comunicacao.notificacao
       SET ntf_estado = CASE WHEN p_enviada THEN 'ENVIADA' WHEN ntf_tentativas >= 5 THEN 'FALHADA' ELSE 'PENDENTE' END
                        ::nucleo.estado_notificacao_t,
           ntf_enviada_em = CASE WHEN p_enviada THEN now() END,
           ntf_erro = CASE WHEN p_enviada THEN NULL ELSE left(p_erro, 500) END,
           ntf_agendada_para = CASE WHEN p_enviada THEN ntf_agendada_para ELSE now() + INTERVAL '15 minutes' END
     WHERE ntf_id = p_id;
END $$;

-- ---------------------------------------------------------------- comportamento comum (como na V10)
CREATE TRIGGER trg_epl_00_padrao BEFORE INSERT OR UPDATE ON actividades.escala_plano FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('epl', 'actividades.escala_plano', 'epl_igr_id');
CREATE TRIGGER trg_epl_00_sem_delete BEFORE DELETE ON actividades.escala_plano FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('epl');
CREATE TRIGGER trg_epl_00_sem_truncate BEFORE TRUNCATE ON actividades.escala_plano FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('epl');
CREATE TRIGGER trg_epl_99_log AFTER UPDATE ON actividades.escala_plano FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('epl');
ALTER TABLE actividades.escala_plano ADD CONSTRAINT fk_epl_criado_por FOREIGN KEY (epl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala_plano ADD CONSTRAINT fk_epl_modificado_por FOREIGN KEY (epl_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_eds_00_padrao BEFORE INSERT OR UPDATE ON actividades.escala_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('eds', 'actividades.escala_dia', '');
CREATE TRIGGER trg_eds_00_sem_delete BEFORE DELETE ON actividades.escala_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('eds');
CREATE TRIGGER trg_eds_00_sem_truncate BEFORE TRUNCATE ON actividades.escala_dia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('eds');
CREATE TRIGGER trg_eds_99_log AFTER UPDATE ON actividades.escala_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('eds');
ALTER TABLE actividades.escala_dia ADD CONSTRAINT fk_eds_criado_por FOREIGN KEY (eds_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala_dia ADD CONSTRAINT fk_eds_modificado_por FOREIGN KEY (eds_modificado_por) REFERENCES nucleo.usuario(usu_id);

-- funções novas: o mesmo search_path de todas; as de trigger com os privilégios do sistema (como na V10)
DO $$
DECLARE f RECORD;
BEGIN
    FOR f IN SELECT p.oid::regprocedure AS sig, p.prorettype = 'trigger'::regtype AS de_trigger
             FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE (n.nspname, p.proname) IN (('actividades', 'fn_funcao_escala_nome'), ('actividades', 'fn_esc_dia'),
                                              ('actividades', 'fn_eds_validar'), ('actividades', 'fn_eds_data'),
                                              ('actividades', 'fn_gerar_dias_escala'), ('actividades', 'fn_lembretes_escala'),
                                              ('comunicacao', 'fn_notificacoes_reservar'),
                                              ('comunicacao', 'fn_notificacao_resultado')) LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public', f.sig);
        IF f.de_trigger THEN
            EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER', f.sig);
        END IF;
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO app_igreja', f.sig);
    END LOOP;
END $$;

-- ---------------------------------------------------------------- segurança (como na V11)
GRANT SELECT, INSERT, UPDATE ON actividades.escala_plano, actividades.escala_dia TO app_igreja;
GRANT USAGE, SELECT ON SEQUENCE actividades.escala_plano_epl_id_seq, actividades.escala_dia_eds_id_seq TO app_igreja;
ALTER TABLE actividades.escala_plano ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_epl_ler ON actividades.escala_plano FOR SELECT USING (epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.ler'))::INT[]));
CREATE POLICY pol_epl_criar ON actividades.escala_plano FOR INSERT WITH CHECK (epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.criar'))::INT[]));
CREATE POLICY pol_epl_alterar ON actividades.escala_plano FOR UPDATE USING (epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.alterar'))::INT[])) WITH CHECK (epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.alterar'))::INT[]));
CREATE POLICY pol_epl_proprio ON actividades.escala_plano FOR SELECT USING (epl_publicada AND epl_igr_id = (SELECT m.mem_igr_id FROM secretaria.membro m WHERE m.mem_id = (SELECT nucleo.fn_membro_sessao())));
ALTER TABLE actividades.escala_dia ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_eds_ler ON actividades.escala_dia FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.escala_plano x WHERE x.epl_id = eds_epl_id AND x.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_dia.ler'))::INT[])));
CREATE POLICY pol_eds_criar ON actividades.escala_dia FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.escala_plano x WHERE x.epl_id = eds_epl_id AND x.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_dia.criar'))::INT[])));
CREATE POLICY pol_eds_alterar ON actividades.escala_dia FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.escala_plano x WHERE x.epl_id = eds_epl_id AND x.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_dia.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.escala_plano x WHERE x.epl_id = eds_epl_id AND x.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_dia.alterar'))::INT[])));
CREATE POLICY pol_eds_proprio ON actividades.escala_dia FOR SELECT USING (eds_epl_id IN (SELECT p.epl_id FROM actividades.escala_plano p));
-- os membros vêem as escalas publicadas da sua igreja (antes só viam as linhas em que eles próprios estavam)
DROP POLICY pol_esc_proprio ON actividades.escala;
CREATE POLICY pol_esc_proprio ON actividades.escala FOR SELECT USING ((SELECT nucleo.fn_membro_sessao()) IN (esc_mem_id, esc_substituto_mem_id) OR esc_eds_id IN (SELECT d.eds_id FROM actividades.escala_dia d));

-- ---------------------------------------------------------------- vista (como na V12)
-- ================================================================ escala (V17)
-- A escala como no papel afixado na igreja: um dia por linha e uma coluna por função.
-- Vista do sistema (não security_invoker) com a regra de quem vê escrita aqui: quem tem
-- actividades.escala_plano.ler nessa igreja, ou o membro da igreja se a escala estiver publicada
-- (os nomes dos escalados fazem parte da escala publicada).
CREATE VIEW actividades.vw_escala_grelha WITH (security_barrier = true) AS
SELECT p.epl_id AS plano_id, p.epl_igr_id AS igreja_id, p.epl_titulo AS titulo, p.epl_publicada AS publicada,
       d.eds_id AS dia_id, d.eds_data AS data, d.eds_evento AS evento,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'PREGADOR') AS pregador,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'TRADUTOR') AS tradutor,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_VISITAS') AS acompanhante_visitas,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_OFERTAS') AS acompanhante_ofertas,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_BOAS_VINDAS') AS acompanhante_boas_vindas,
       string_agg(actividades.fn_funcao_escala_nome(e.esc_funcao) || ': ' || m.mem_nome || ' ' || m.mem_apelido, '; ')
           FILTER (WHERE e.esc_funcao::text NOT IN ('PREGADOR', 'TRADUTOR', 'ACOMPANHANTE_VISITAS', 'ACOMPANHANTE_OFERTAS',
                                                     'ACOMPANHANTE_BOAS_VINDAS')) AS outras_funcoes,
       d.eds_grupo_coral AS grupo_coral, dep.dep_nome AS departamento, d.eds_observacoes AS observacoes
FROM actividades.escala_dia d
JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
LEFT JOIN actividades.escala e ON e.esc_eds_id = d.eds_id AND e.esc_end_date IS NULL
LEFT JOIN secretaria.membro m ON m.mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
LEFT JOIN organizacao.igreja_departamento ide ON ide.ide_id = d.eds_ide_id
LEFT JOIN organizacao.departamento dep ON dep.dep_id = ide.ide_dep_id
WHERE d.eds_end_date IS NULL AND p.epl_end_date IS NULL
  AND (p.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.ler'))::INT[])
       OR (p.epl_publicada AND p.epl_igr_id = (SELECT m2.mem_igr_id FROM secretaria.membro m2
                                               WHERE m2.mem_id = (SELECT nucleo.fn_membro_sessao()))))
GROUP BY p.epl_id, p.epl_igr_id, p.epl_titulo, p.epl_publicada, d.eds_id, d.eds_data, d.eds_evento,
         d.eds_grupo_coral, dep.dep_nome, d.eds_observacoes;
GRANT SELECT ON actividades.vw_escala_grelha TO app_igreja;

-- ---------------------------------------------------------------- permissões e perfis (como na V13)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('actividades.escala_plano.ler', 'Ler: Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada'),
  ('actividades.escala_plano.criar', 'Criar: Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada'),
  ('actividades.escala_plano.alterar', 'Alterar: Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada'),
  ('actividades.escala_plano.terminar', 'Terminar (end_date): Escala de um período (ex.: escala de pregação do trimestre), assinada e publicada'),
  ('actividades.escala_dia.ler', 'Ler: Um dia (culto) da escala: grupo coral, departamento ou evento especial'),
  ('actividades.escala_dia.criar', 'Criar: Um dia (culto) da escala: grupo coral, departamento ou evento especial'),
  ('actividades.escala_dia.alterar', 'Alterar: Um dia (culto) da escala: grupo coral, departamento ou evento especial'),
  ('actividades.escala_dia.terminar', 'Terminar (end_date): Um dia (culto) da escala: grupo coral, departamento ou evento especial');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_dia.terminar', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler', 'actividades.escala_plano.terminar');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'PASTOR'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_dia.terminar', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler', 'actividades.escala_plano.terminar');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ANCIAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_dia.terminar', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler', 'actividades.escala_plano.terminar');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_dia.terminar', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler', 'actividades.escala_plano.terminar');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_ES'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_dia.terminar', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler', 'actividades.escala_plano.terminar');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_DEPARTAMENTO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.alterar', 'actividades.escala_dia.criar', 'actividades.escala_dia.ler', 'actividades.escala_plano.alterar', 'actividades.escala_plano.criar', 'actividades.escala_plano.ler');

INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala_dia.ler', 'actividades.escala_plano.ler');

-- >>>>> V18__juntar_schemas_e_indices.sql
-- =====================================================================
-- V18 · Menos schemas e índices para as listagens por igreja
--
-- 1. Os schemas com 1 e 3 tabelas passam para o módulo a que pertencem (ficam 6 schemas):
--      pagamentos.pagamento_mpesa, mpesa_callback_log, pagamento_bancario, vw_mpesa_pendentes → tesouraria
--      comunicacao.notificacao, vw_notificacoes_a_enviar                                     → nucleo
--    Os códigos de permissão mudam com o schema (pagamentos.pagamento_mpesa.ler → tesouraria.pagamento_mpesa.ler);
--    os perfis continuam com exactamente as mesmas permissões (são ligados pelo id, não pelo código).
--    Os registos antigos do log de auditoria guardam o nome antigo da tabela (o log não se altera).
--
-- 2. Listagens por igreja (a API pede sempre igrejaId e ordena por id, com cursor): o índice (igreja) passa
--    a (igreja, id) nas 18 tabelas que crescem com o uso. A página seguinte sai directamente do índice, em vez
--    de ler e ordenar todos os registos da igreja. Medido com a carga de database/tests/carga_*.sql.
--
-- Gerado a partir de database/gerador (defs.py, gen.py); o estado final é igual ao que o gerador produz.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- 1. mover para tesouraria e nucleo
ALTER TABLE pagamentos.pagamento_mpesa    SET SCHEMA tesouraria;
ALTER TABLE pagamentos.mpesa_callback_log SET SCHEMA tesouraria;
ALTER TABLE pagamentos.pagamento_bancario SET SCHEMA tesouraria;
ALTER VIEW  pagamentos.vw_mpesa_pendentes SET SCHEMA tesouraria;
ALTER FUNCTION pagamentos.fn_pmp_validar() SET SCHEMA tesouraria;

ALTER TABLE comunicacao.notificacao              SET SCHEMA nucleo;
ALTER VIEW  comunicacao.vw_notificacoes_a_enviar SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_rec_notificar() SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_notificacoes_reservar(INT) SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_notificacao_resultado(BIGINT, BOOLEAN, TEXT) SET SCHEMA nucleo;

-- O que guarda os nomes antigos em texto: corpo das funções, códigos de permissão nas políticas RLS e nos
-- triggers-padrão (o "terminar" exige <schema>.<tabela>.terminar), e o catálogo de permissões.
DO $$
DECLARE
    r   RECORD;
    def TEXT;
    sql TEXT;
BEGIN
    -- funções (plpgsql guarda o corpo em texto)
    FOR r IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
               AND p.prosrc ~ '\m(pagamentos|comunicacao)\.' LOOP
        def := pg_get_functiondef(r.oid);
        def := regexp_replace(def, '\mpagamentos\.', 'tesouraria.', 'g');
        def := regexp_replace(def, '\mcomunicacao\.', 'nucleo.', 'g');
        EXECUTE def;
    END LOOP;

    -- políticas RLS: os códigos de permissão são texto
    FOR r IN SELECT schemaname, tablename, policyname, qual, with_check FROM pg_policies
             WHERE coalesce(qual, '') || coalesce(with_check, '') ~ '\m(pagamentos|comunicacao)\.' LOOP
        sql := format('ALTER POLICY %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
        IF r.qual IS NOT NULL THEN
            sql := sql || ' USING (' || regexp_replace(regexp_replace(r.qual, '\mpagamentos\.', 'tesouraria.', 'g'),
                                                       '\mcomunicacao\.', 'nucleo.', 'g') || ')';
        END IF;
        IF r.with_check IS NOT NULL THEN
            sql := sql || ' WITH CHECK (' || regexp_replace(regexp_replace(r.with_check, '\mpagamentos\.', 'tesouraria.', 'g'),
                                                            '\mcomunicacao\.', 'nucleo.', 'g') || ')';
        END IF;
        EXECUTE sql;
    END LOOP;

    -- triggers-padrão com o código da tabela nos argumentos
    FOR r IN SELECT t.oid, t.tgname, t.tgrelid::regclass AS tabela FROM pg_trigger t
             WHERE NOT t.tgisinternal AND encode(t.tgargs, 'escape') ~ '(^|\\000)(pagamentos|comunicacao)\.' LOOP
        def := pg_get_triggerdef(r.oid);
        def := regexp_replace(def, '''pagamentos\.', '''tesouraria.', 'g');
        def := regexp_replace(def, '''comunicacao\.', '''nucleo.', 'g');
        EXECUTE format('DROP TRIGGER %I ON %s', r.tgname, r.tabela);
        EXECUTE def;
    END LOOP;
END $$;

UPDATE nucleo.permissao
   SET prm_codigo = regexp_replace(regexp_replace(prm_codigo, '^pagamentos\.', 'tesouraria.'), '^comunicacao\.', 'nucleo.')
 WHERE prm_codigo ~ '^(pagamentos|comunicacao)\.';

-- search_path das funções, da base e dos utilizadores da API (sem os dois schemas)
DO $$
DECLARE
    r RECORD;
    novo CONSTANT TEXT := 'nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public';
    cfg TEXT;
BEGIN
    FOR r IN SELECT p.oid::regprocedure AS sig FROM pg_proc p
             WHERE array_to_string(p.proconfig, ',') ~ 'search_path=.*\m(pagamentos|comunicacao)\M' LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = %s', r.sig, novo);
    END LOOP;
    FOR r IN SELECT s.setrole, s.setdatabase, c AS cfg FROM pg_db_role_setting s, unnest(s.setconfig) c
             WHERE c ~ '^search_path=.*\m(pagamentos|comunicacao)\M'
               AND (s.setdatabase = 0 OR s.setdatabase = (SELECT oid FROM pg_database WHERE datname = current_database())) LOOP
        cfg := regexp_replace(substr(r.cfg, length('search_path=') + 1), ',\s*(pagamentos|comunicacao)\M', '', 'g');
        IF r.setrole = 0 THEN
            EXECUTE format('ALTER DATABASE %I SET search_path = %s', current_database(), cfg);
        ELSIF r.setdatabase = 0 THEN
            EXECUTE format('ALTER ROLE %I SET search_path = %s', (SELECT rolname FROM pg_roles WHERE oid = r.setrole), cfg);
        ELSE
            EXECUTE format('ALTER ROLE %I IN DATABASE %I SET search_path = %s',
                           (SELECT rolname FROM pg_roles WHERE oid = r.setrole), current_database(), cfg);
        END IF;
    END LOOP;
END $$;

-- vazios: se ainda tiverem alguma coisa, a migração pára aqui (e nada do que está acima fica feito)
DROP SCHEMA pagamentos;
DROP SCHEMA comunicacao;

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- 2. índices (igreja, id) para as listagens
-- O índice novo começa pela igreja: serve também a chave estrangeira e as políticas RLS, por isso substitui o
-- índice simples (igreja).
CREATE INDEX idx_uig_igr_pagina ON nucleo.usuario_igreja (uig_igr_id, uig_id);
CREATE INDEX idx_fam_igr_pagina ON secretaria.familia (fam_igr_id, fam_id);
CREATE INDEX idx_mem_igr_pagina ON secretaria.membro (mem_igr_id, mem_id);
CREATE INDEX idx_reu_igr_pagina ON secretaria.reuniao (reu_igr_id, reu_id);
CREATE INDEX idx_mmb_igr_pagina ON secretaria.movimento_membro (mmb_igr_id, mmb_id);
CREATE INDEX idx_ofi_igr_pagina ON secretaria.oficial (ofi_igr_id, ofi_id);
CREATE INDEX idx_epl_igr_pagina ON actividades.escala_plano (epl_igr_id, epl_id);
CREATE INDEX idx_ect_igr_pagina ON escola_sabatina.classe_trimestre (ect_igr_id, ect_id);
CREATE INDEX idx_ers_igr_pagina ON escola_sabatina.relatorio_sabado (ers_igr_id, ers_id);
CREATE INDEX idx_epr_igr_pagina ON escola_sabatina.presenca (epr_igr_id, epr_id);
CREATE INDEX idx_alv_igr_pagina ON tesouraria.alvo (alv_igr_id, alv_id);
CREATE INDEX idx_orc_igr_pagina ON tesouraria.orcamento (orc_igr_id, orc_id);
CREATE INDEX idx_des_igr_pagina ON tesouraria.despesa (des_igr_id, des_id);
CREATE INDEX idx_cnu_igr_pagina ON tesouraria.contagem_numerario (cnu_igr_id, cnu_id);
CREATE INDEX idx_tra_igr_pagina ON tesouraria.transacao (tra_igr_id, tra_id);
CREATE INDEX idx_tli_igr_pagina ON tesouraria.transacao_linha (tli_igr_id, tli_id);
CREATE INDEX idx_sdc_igr_pagina ON tesouraria.saldo_diario_conta (sdc_igr_id, sdc_id);
CREATE INDEX idx_ntf_igr_pagina ON nucleo.notificacao (ntf_igr_id, ntf_id);

DROP INDEX nucleo.idx_uig_igr_id;
DROP INDEX secretaria.idx_fam_igr_id;
DROP INDEX secretaria.idx_mem_igr_id;
DROP INDEX secretaria.idx_reu_igr_id;
DROP INDEX secretaria.idx_mmb_igr_id;
DROP INDEX secretaria.idx_ofi_igr_id;
DROP INDEX actividades.idx_epl_igr_id;
DROP INDEX escola_sabatina.idx_ect_igr_id;
DROP INDEX escola_sabatina.idx_ers_igr_id;
DROP INDEX escola_sabatina.idx_epr_igr_id;
DROP INDEX tesouraria.idx_alv_igr_id;
DROP INDEX tesouraria.idx_orc_igr_id;
DROP INDEX tesouraria.idx_des_igr_id;
DROP INDEX tesouraria.idx_cnu_igr_id;
DROP INDEX tesouraria.idx_tra_igr_id;
DROP INDEX tesouraria.idx_tli_igr_id;
DROP INDEX tesouraria.idx_sdc_igr_id;
DROP INDEX nucleo.idx_ntf_igr_id;

-- >>>>> V19__ficha_completa_do_membro.sql
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

-- >>>>> V20__remessa_devida_com_fundo.sql
-- =====================================================================
-- V20 · Remessa devida: o fundo e a entidade com nomes que a API não confunde (F-TES-10, P-09)
--
-- Na API, o nome JSON de uma coluna é o nome sem o prefixo de 3 letras; igr_id, fun_id e ent_id davam todos
-- "id" e o relatório GET /v1/tesouraria/remessas-devidas não dizia de que fundo era cada valor. A vista
-- ganha, no fim, fundo_id, fundo_nome, fundo_codigo e entidade_id (→ fundoId, fundoNome, fundoCodigo,
-- entidadeId). As colunas antigas ficam iguais e na mesma ordem (nada do que já as usa muda).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE OR REPLACE VIEW tesouraria.vw_remessa_devida WITH (security_invoker = true) AS
WITH recebido AS (
    SELECT s.sdf_igr_id AS igr_id, f.fun_id, f.fun_destino_ent_id AS ent_id,
           EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
           SUM(s.sdf_entradas - s.sdf_estornos_entradas) AS recebido,
           ROUND(SUM(s.sdf_entradas - s.sdf_estornos_entradas) * f.fun_percentagem_remessa / 100, 2) AS devido
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL AND f.fun_percentagem_remessa > 0
    GROUP BY 1, 2, 3, 4, 5, f.fun_percentagem_remessa
),
remetido AS (
    SELECT r.rem_igr_id AS igr_id, r.rem_ent_id AS ent_id, r.rem_ano AS ano, r.rem_mes AS mes,
           rl.rml_fun_id AS fun_id, SUM(rl.rml_valor) AS remetido
    FROM tesouraria.remessa r
    JOIN tesouraria.remessa_linha rl ON rl.rml_rem_id = r.rem_id AND rl.rml_end_date IS NULL
    WHERE r.rem_end_date IS NULL AND r.rem_estado IN ('ENVIADA', 'CONFIRMADA')
    GROUP BY 1, 2, 3, 4, 5
)
SELECT rc.*, COALESCE(rm.remetido, 0) AS remetido, rc.devido - COALESCE(rm.remetido, 0) AS em_falta,
       rc.fun_id AS fundo_id, f.fun_nome AS fundo_nome, f.fun_codigo AS fundo_codigo, rc.ent_id AS entidade_id
FROM recebido rc
LEFT JOIN remetido rm USING (igr_id, ent_id, ano, mes, fun_id)
JOIN tesouraria.fundo f ON f.fun_id = rc.fun_id;

-- >>>>> V21__conta_da_missao_e_parte_da_igreja.sql
-- =====================================================================
-- V21 · Pagamentos directos na conta da Missão e a parte da igreja nas ofertas (F-TES-01, F-TES-10, P-06, P-09)
--
-- 1. Conta da Missão. Alguns membros pagam o dízimo e as ofertas directamente na conta bancária (ou M-Pesa) da
--    Associação/Missão e mandam o comprovativo à igreja. A igreja regista esses pagamentos numa conta marcada
--    com a entidade (cfi_ent_id): contam como contribuição do membro (recibo, extracto anual, relatório mensal),
--    mas o dinheiro já está na Missão, por isso contam também como já remetidos e não entram no saldo da igreja.
--    Nessa conta só há entradas (e os seus estornos), só dos fundos dessa entidade, e com a referência do
--    comprovativo.
-- 2. Parte da igreja. Nos fundos repartidos (oferta combinada: 50% Missão, 50% igreja) a igreja só gasta a sua
--    parte: uma saída que não seja remessa não pode deixar o fundo com menos do que ainda se deve à Missão.
-- 3. Vistas: remessa devida desconta o pago directamente (pago_directo); saldo por fundo é o dinheiro que está
--    nas contas da igreja, com na_associacao, por_remeter e disponivel; saldo por conta diz a entidade da conta;
--    contribuições com o mês (periodo_ano, periodo_mes), o fundo e se foi paga na conta da Missão.
--    Colunas antigas: os mesmos nomes e a mesma ordem; as novas vão no fim.
-- 4. Remessa complementar: mais do que uma remessa no mesmo mês (só uma preparada de cada vez).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- 1. conta da Missão
ALTER TABLE tesouraria.conta_financeira ADD COLUMN cfi_ent_id INT;
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT fk_cfi_ent_id FOREIGN KEY (cfi_ent_id) REFERENCES organizacao.entidade(ent_id);
COMMENT ON COLUMN tesouraria.conta_financeira.cfi_ent_id IS
    'Conta da Associação/Missão (ex.: a conta bancária da Missão): regista o que os membros pagam directamente lá. Só recebe entradas dos fundos dessa entidade; o dinheiro já não está na igreja';

CREATE FUNCTION tesouraria.fn_cfi_validar() RETURNS trigger AS $$
BEGIN
    IF NEW.cfi_ent_id IS NOT NULL THEN
        IF NEW.cfi_tipo = 'CAIXA' THEN
            RAISE EXCEPTION 'Uma conta da Missão é uma conta bancária ou de carteira móvel, não um caixa';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM tesouraria.fundo WHERE fun_destino_ent_id = NEW.cfi_ent_id AND fun_end_date IS NULL) THEN
            RAISE EXCEPTION 'A entidade % não recebe nenhum fundo: não pode ter uma conta da Missão', NEW.cfi_ent_id;
        END IF;
    END IF;
    IF TG_OP = 'UPDATE' AND NEW.cfi_ent_id IS DISTINCT FROM OLD.cfi_ent_id
       AND EXISTS (SELECT 1 FROM tesouraria.transacao WHERE tra_cfi_id = NEW.cfi_id OR tra_destino_cfi_id = NEW.cfi_id) THEN
        RAISE EXCEPTION 'A conta "%" já tem movimentos: não pode passar a ser (ou deixar de ser) uma conta da Missão', NEW.cfi_nome;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cfi_10_validar
    BEFORE INSERT OR UPDATE ON tesouraria.conta_financeira
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cfi_validar();

-- Movimentos na conta da Missão: só entradas (e estornos delas), com o comprovativo; nada se paga nem transfere
CREATE FUNCTION tesouraria.fn_tra_conta_missao() RETURNS trigger AS $$
DECLARE
    v_orig TEXT; v_dest TEXT;
BEGIN
    SELECT cfi_nome INTO v_orig FROM tesouraria.conta_financeira WHERE cfi_id = NEW.tra_cfi_id AND cfi_ent_id IS NOT NULL;
    IF NEW.tra_destino_cfi_id IS NOT NULL THEN
        SELECT cfi_nome INTO v_dest FROM tesouraria.conta_financeira WHERE cfi_id = NEW.tra_destino_cfi_id AND cfi_ent_id IS NOT NULL;
    END IF;
    IF v_dest IS NOT NULL OR (v_orig IS NOT NULL AND NEW.tra_tipo = 'TRANSFERENCIA') THEN
        RAISE EXCEPTION 'Não se transfere de nem para a conta da Missão "%": o que a igreja envia à Missão é uma remessa', COALESCE(v_dest, v_orig);
    END IF;
    IF v_orig IS NULL THEN
        RETURN NEW;
    END IF;
    IF NEW.tra_tipo = 'SAIDA' AND NEW.tra_estorno_tra_id IS NULL THEN
        RAISE EXCEPTION 'A conta "%" é da Missão: regista só o que os membros lá pagaram; a igreja não paga nada a partir dela', v_orig;
    END IF;
    IF NEW.tra_tipo = 'ENTRADA' AND NEW.tra_estorno_tra_id IS NULL AND NULLIF(btrim(NEW.tra_referencia), '') IS NULL THEN
        RAISE EXCEPTION 'Pagamento na conta da Missão: escreva a referência do comprovativo que o membro mandou';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tra_15_conta_missao
    BEFORE INSERT OR UPDATE ON tesouraria.transacao
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_conta_missao();

-- Linhas na conta da Missão: só fundos dessa entidade (dízimo, ofertas missionárias, oferta combinada, ...)
CREATE FUNCTION tesouraria.fn_tli_conta_missao() RETURNS trigger AS $$
DECLARE
    v_ent INT; v_conta TEXT;
BEGIN
    SELECT c.cfi_ent_id, c.cfi_nome INTO v_ent, v_conta
      FROM tesouraria.transacao t JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id
     WHERE t.tra_id = NEW.tli_tra_id;
    IF v_ent IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tesouraria.fundo WHERE fun_id = NEW.tli_fun_id AND fun_destino_ent_id = v_ent AND fun_percentagem_remessa > 0) THEN
        RAISE EXCEPTION 'Na conta da Missão "%" só entram fundos da Missão (dízimo, ofertas missionárias, oferta combinada, ...); "%" fica na igreja',
            v_conta, (SELECT fun_nome FROM tesouraria.fundo WHERE fun_id = NEW.tli_fun_id);
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tli_15_conta_missao
    BEFORE INSERT OR UPDATE ON tesouraria.transacao_linha
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tli_conta_missao();

-- ---------------------------------------------------------------- 3. vistas
CREATE OR REPLACE VIEW tesouraria.vw_saldo_conta WITH (security_invoker = true) AS
SELECT c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda,
       c.cfi_saldo_inicial + COALESCE(SUM(s.sdc_entradas - s.sdc_saidas), 0) AS saldo,
       c.cfi_ent_id AS entidade_id
FROM tesouraria.conta_financeira c
LEFT JOIN tesouraria.saldo_diario_conta s
       ON s.sdc_cfi_id = c.cfi_id AND s.sdc_end_date IS NULL AND s.sdc_data >= c.cfi_data_saldo_inicial
WHERE c.cfi_end_date IS NULL
GROUP BY c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda, c.cfi_saldo_inicial, c.cfi_ent_id;

-- Pago directamente na conta da Missão, por igreja, entidade, mês e fundo (estornos descontam)
CREATE VIEW tesouraria.vw_pago_na_missao WITH (security_invoker = true) AS
SELECT t.tra_igr_id AS igr_id, c.cfi_ent_id AS ent_id, c.cfi_moeda AS moeda,
       EXTRACT(YEAR  FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
       EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       l.tli_fun_id AS fun_id,
       SUM(CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END) AS pago
FROM tesouraria.conta_financeira c
JOIN tesouraria.transacao t       ON t.tra_cfi_id = c.cfi_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
WHERE c.cfi_ent_id IS NOT NULL
GROUP BY 1, 2, 3, 4, 5, 6;
COMMENT ON VIEW tesouraria.vw_pago_na_missao IS 'Contribuições pagas directamente na conta da Associação/Missão (já lá estão: contam como remetidas)';

CREATE OR REPLACE VIEW tesouraria.vw_remessa_devida WITH (security_invoker = true) AS
WITH recebido AS (
    SELECT s.sdf_igr_id AS igr_id, f.fun_id, f.fun_destino_ent_id AS ent_id,
           EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
           SUM(s.sdf_entradas - s.sdf_estornos_entradas) AS recebido,
           ROUND(SUM(s.sdf_entradas - s.sdf_estornos_entradas) * f.fun_percentagem_remessa / 100, 2) AS devido
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL AND f.fun_percentagem_remessa > 0
    GROUP BY 1, 2, 3, 4, 5, f.fun_percentagem_remessa
),
remetido AS (
    SELECT r.rem_igr_id AS igr_id, r.rem_ent_id AS ent_id, r.rem_ano AS ano, r.rem_mes AS mes,
           rl.rml_fun_id AS fun_id, SUM(rl.rml_valor) AS remetido
    FROM tesouraria.remessa r
    JOIN tesouraria.remessa_linha rl ON rl.rml_rem_id = r.rem_id AND rl.rml_end_date IS NULL
    WHERE r.rem_end_date IS NULL AND r.rem_estado IN ('ENVIADA', 'CONFIRMADA')
    GROUP BY 1, 2, 3, 4, 5
),
directo AS (
    SELECT igr_id, ent_id, ano, mes, fun_id, SUM(pago) AS pago_directo
    FROM tesouraria.vw_pago_na_missao GROUP BY 1, 2, 3, 4, 5
)
SELECT rc.*, COALESCE(rm.remetido, 0) AS remetido,
       rc.devido - COALESCE(rm.remetido, 0) - COALESCE(d.pago_directo, 0) AS em_falta,
       rc.fun_id AS fundo_id, f.fun_nome AS fundo_nome, f.fun_codigo AS fundo_codigo, rc.ent_id AS entidade_id,
       COALESCE(d.pago_directo, 0) AS pago_directo
FROM recebido rc
LEFT JOIN remetido rm USING (igr_id, ent_id, ano, mes, fun_id)
LEFT JOIN directo d   USING (igr_id, ent_id, ano, mes, fun_id)
JOIN tesouraria.fundo f ON f.fun_id = rc.fun_id;

-- saldo = o que está nas contas da igreja (o pago na Missão não conta); disponivel = o que a igreja pode gastar
CREATE OR REPLACE VIEW tesouraria.vw_saldo_fundo WITH (security_invoker = true) AS
WITH base AS (
    SELECT s.sdf_igr_id AS igr_id, s.sdf_moeda AS moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito,
           f.fun_percentagem_remessa,
           SUM(s.sdf_entradas + s.sdf_estornos_saidas) AS entradas,
           SUM(s.sdf_saidas + s.sdf_estornos_entradas) AS saidas
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL
    GROUP BY s.sdf_igr_id, s.sdf_moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito, f.fun_percentagem_remessa
),
directo AS (
    SELECT igr_id, moeda, fun_id, SUM(pago) AS pago FROM tesouraria.vw_pago_na_missao GROUP BY 1, 2, 3
),
devido AS (
    SELECT igr_id, fun_id, SUM(em_falta) AS por_remeter FROM tesouraria.vw_remessa_devida GROUP BY 1, 2
),
calc AS (
    SELECT b.*, b.entradas - b.saidas - COALESCE(d.pago, 0) AS saldo, COALESCE(d.pago, 0) AS na_associacao,
           CASE WHEN b.moeda = 'MZN' THEN COALESCE(p.por_remeter, 0) ELSE 0 END AS por_remeter
    FROM base b
    LEFT JOIN directo d ON d.igr_id = b.igr_id AND d.moeda = b.moeda AND d.fun_id = b.fun_id
    LEFT JOIN devido p  ON p.igr_id = b.igr_id AND p.fun_id = b.fun_id
)
SELECT igr_id, moeda, fun_id, fun_codigo, fun_nome, fun_tipo, fun_restrito, entradas, saidas, saldo,
       (fun_restrito AND saldo < 0) AS alerta_restrito,
       fun_id AS fundo_id, fun_percentagem_remessa AS percentagem_remessa, na_associacao, por_remeter,
       LEAST(saldo, saldo - por_remeter) AS disponivel
FROM calc;

-- Se uma conta é da Missão. SECURITY DEFINER: o membro sem perfil não lê as contas, mas vê nas suas contribuições
-- que pagou na Missão (só se revela isto, nada da conta).
CREATE FUNCTION tesouraria.fn_conta_da_missao(p_cfi INT) RETURNS BOOLEAN
SECURITY DEFINER SET search_path = tesouraria, pg_temp AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM tesouraria.conta_financeira WHERE cfi_id = p_cfi AND cfi_ent_id IS NOT NULL);
END $$ LANGUAGE plpgsql STABLE;
REVOKE ALL ON FUNCTION tesouraria.fn_conta_da_missao(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_conta_da_missao(INT) TO app_igreja;

CREATE OR REPLACE VIEW tesouraria.vw_contribuicoes_membro WITH (security_invoker = true) AS
SELECT t.tra_igr_id, t.tra_mem_id, t.tra_fam_id, t.tra_id, t.tra_data_hora, t.tra_metodo,
       f.fun_nome AS fundo,
       CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END AS valor,
       (t.tra_estorno_tra_id IS NOT NULL) AS estorno, r.rec_ano, r.rec_numero,
       EXTRACT(YEAR  FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS periodo_ano,
       EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS periodo_mes,
       l.tli_fun_id AS fundo_id, tesouraria.fn_conta_da_missao(t.tra_cfi_id) AS pago_na_missao, t.tra_referencia AS referencia
FROM tesouraria.transacao t
JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
JOIN tesouraria.fundo f           ON f.fun_id = l.tli_fun_id
LEFT JOIN tesouraria.recibo r     ON r.rec_tra_id = t.tra_id AND r.rec_end_date IS NULL
WHERE (t.tra_tipo = 'ENTRADA' OR t.tra_estorno_tra_id IS NOT NULL)
  AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
  AND (t.tra_mem_id IS NOT NULL OR t.tra_fam_id IS NOT NULL);

GRANT SELECT ON tesouraria.vw_pago_na_missao TO app_igreja;

-- ---------------------------------------------------------------- 2. parte da igreja nos fundos repartidos
-- O que a igreja pode gastar de um fundo: o saldo nas suas contas menos o que ainda deve à Missão desse fundo.
-- SECURITY DEFINER: a regra vale para todos (o tesoureiro que confirma pode não ler todos os saldos).
CREATE FUNCTION tesouraria.fn_fundo_disponivel(p_igr INT, p_fun INT) RETURNS NUMERIC
SECURITY DEFINER SET search_path = tesouraria, pg_temp AS $$
BEGIN
    RETURN (SELECT COALESCE(SUM(disponivel), 0) FROM tesouraria.vw_saldo_fundo WHERE igr_id = p_igr AND fun_id = p_fun);
END $$ LANGUAGE plpgsql STABLE;
REVOKE ALL ON FUNCTION tesouraria.fn_fundo_disponivel(INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_fundo_disponivel(INT, INT) TO app_igreja;

-- No COMMIT (com os saldos já actualizados): uma saída confirmada de um fundo repartido, que não seja remessa,
-- não pode deixar a igreja a dever à Missão mais do que tem
CREATE FUNCTION tesouraria.fn_tra_parte_da_igreja() RETURNS trigger AS $$
DECLARE l RECORD;
BEGIN
    IF NEW.tra_tipo <> 'SAIDA' OR NEW.tra_estado <> 'CONFIRMADA' OR NEW.tra_estorno_tra_id IS NOT NULL OR NEW.tra_end_date IS NOT NULL
       OR (TG_OP = 'UPDATE' AND OLD.tra_estado = 'CONFIRMADA') THEN
        RETURN NULL;
    END IF;
    FOR l IN SELECT f.fun_id, f.fun_nome, f.fun_percentagem_remessa, SUM(tl.tli_valor) AS valor
               FROM tesouraria.transacao_linha tl
               JOIN tesouraria.fundo f ON f.fun_id = tl.tli_fun_id
               JOIN tesouraria.categoria c ON c.cat_id = tl.tli_cat_id
              WHERE tl.tli_tra_id = NEW.tra_id AND tl.tli_end_date IS NULL AND NOT c.cat_e_remessa
                AND f.fun_percentagem_remessa > 0 AND f.fun_percentagem_remessa < 100
              GROUP BY f.fun_id, f.fun_nome, f.fun_percentagem_remessa LOOP
        IF tesouraria.fn_fundo_disponivel(NEW.tra_igr_id, l.fun_id) < 0 THEN
            RAISE EXCEPTION 'A parte da igreja no fundo "%" não chega para esta saída: % é da Missão e ainda não foi remetido. Disponível para a igreja: % MT',
                l.fun_nome, trim_scale(l.fun_percentagem_remessa)::TEXT || '%',
                GREATEST(tesouraria.fn_fundo_disponivel(NEW.tra_igr_id, l.fun_id) + l.valor, 0);
        END IF;
    END LOOP;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_tra_91_parte_da_igreja
    AFTER INSERT OR UPDATE ON tesouraria.transacao
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_parte_da_igreja();

-- ---------------------------------------------------------------- 4. remessa complementar
-- O que entra depois do depósito do mês (envelope atrasado, comprovativo que chega tarde) segue numa remessa
-- complementar do mesmo mês: várias remessas por mês, mas só uma preparada de cada vez (não se duplica).
DROP INDEX IF EXISTS tesouraria.uq_rem_igr_id_ent_id_ano_mes;
CREATE INDEX idx_rem_igr_periodo ON tesouraria.remessa (rem_igr_id, rem_ent_id, rem_ano, rem_mes);
CREATE UNIQUE INDEX uq_rem_preparada ON tesouraria.remessa (rem_igr_id, rem_ent_id, rem_ano, rem_mes)
    WHERE rem_end_date IS NULL AND rem_estado = 'PREPARADA';

-- >>>>> V22__conselho_e_actas.sql
-- =====================================================================
-- V22 · Conselho da igreja e actas das reuniões (F-SEC-07, F-SEC-08, P-04)
--
-- 1. Conselho: os cargos que fazem parte do conselho (car_conselho) e a duração dos mandatos de cada igreja
--    (igr_mandato_anos, 1 a 5 anos). Cada oficial ganha o fim previsto do mandato, calculado sozinho a partir
--    da data de início e da duração da igreja (pode corrigir-se). A vista vw_conselho dá o conselho com o cargo,
--    o contacto principal e o estado do mandato (ACTIVO, A_TERMINAR, TERMINADO, FUTURO).
-- 2. Reuniões: número da acta, hora e registo do encerramento.
-- 3. Presenças (reuniao_presenca): quem esteve e quem faltou, com o cargo com que participou e a justificação.
-- 4. Pontos da agenda (reuniao_ponto): assunto, detalhes, se foi discutido e votado, votos, voto formal da acta
--    ligado, deliberação e estado (PENDENTE, APROVADO, REJEITADO, ADIADO, INFORMATIVO).
-- 5. Acta aprovada fica fechada: presenças e pontos já não se alteram.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TYPE nucleo.estado_ponto_t AS ENUM ('PENDENTE', 'APROVADO', 'REJEITADO', 'ADIADO', 'INFORMATIVO');

-- ---------------------------------------------------------------- colunas novas
ALTER TABLE organizacao.cargo ADD COLUMN car_conselho BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN organizacao.cargo.car_conselho IS 'Faz parte do conselho da igreja (junta directiva)';

ALTER TABLE organizacao.igreja ADD COLUMN igr_mandato_anos SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE organizacao.igreja ADD CONSTRAINT chk_igr_mandato CHECK (igr_mandato_anos BETWEEN 1 AND 5);
COMMENT ON COLUMN organizacao.igreja.igr_mandato_anos IS 'Duração dos mandatos dos oficiais nesta igreja, em anos';

ALTER TABLE secretaria.oficial ADD COLUMN ofi_fim_previsto DATE;
ALTER TABLE secretaria.oficial ADD CONSTRAINT chk_ofi_fim_previsto CHECK (ofi_fim_previsto IS NULL OR ofi_fim_previsto >= ofi_data_inicio);
COMMENT ON COLUMN secretaria.oficial.ofi_data_fim IS 'Fim efectivo (mandato terminado antes ou depois do previsto)';
COMMENT ON COLUMN secretaria.oficial.ofi_fim_previsto IS 'Fim do mandato pela duração definida na igreja (preenchido sozinho; pode corrigir-se)';

ALTER TABLE secretaria.reuniao ADD COLUMN reu_numero VARCHAR(20);
ALTER TABLE secretaria.reuniao ADD COLUMN reu_encerrada_em TIMESTAMPTZ;
ALTER TABLE secretaria.reuniao ADD COLUMN reu_encerramento TEXT;
COMMENT ON COLUMN secretaria.reuniao.reu_numero IS 'Número da reunião/acta, ex.: 2026-03';
COMMENT ON COLUMN secretaria.reuniao.reu_encerrada_em IS 'Hora do encerramento';
COMMENT ON COLUMN secretaria.reuniao.reu_encerramento IS 'Registo do encerramento (oração final, próxima reunião, ...)';
CREATE UNIQUE INDEX uq_reu_igr_id_numero ON secretaria.reuniao (reu_igr_id, reu_numero) WHERE reu_end_date IS NULL;

-- ---------------------------------------------------------------- tabelas novas (gen.py)
CREATE TABLE secretaria.reuniao_presenca (
    rpr_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rpr_reu_id INT NOT NULL,
    rpr_mem_id INT NOT NULL,
    rpr_presente BOOLEAN NOT NULL DEFAULT TRUE,
    rpr_funcao VARCHAR(100),
    rpr_justificacao VARCHAR(255),
    rpr_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rpr_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpr_criado_por INT,
    rpr_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpr_modificado_por INT,
    rpr_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rpr_reu_id FOREIGN KEY (rpr_reu_id) REFERENCES secretaria.reuniao(reu_id),
    CONSTRAINT fk_rpr_mem_id FOREIGN KEY (rpr_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_rpr_end_date CHECK (rpr_end_date IS NULL OR rpr_end_date >= rpr_criado_em)
);
COMMENT ON TABLE secretaria.reuniao_presenca IS 'Presenças nas reuniões: quem esteve e quem faltou (com a justificação)';
COMMENT ON COLUMN secretaria.reuniao_presenca.rpr_funcao IS 'Cargo com que participou (fica no histórico)';
COMMENT ON COLUMN secretaria.reuniao_presenca.rpr_justificacao IS 'Motivo da ausência';
CREATE UNIQUE INDEX uq_rpr_reu_id_mem_id ON secretaria.reuniao_presenca (rpr_reu_id, rpr_mem_id) WHERE rpr_end_date IS NULL;
CREATE INDEX idx_rpr_mem_id ON secretaria.reuniao_presenca (rpr_mem_id);

-- Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação
CREATE TABLE secretaria.reuniao_ponto (
    rpt_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rpt_reu_id INT NOT NULL,
    rpt_ordem SMALLINT NOT NULL DEFAULT 1,
    rpt_assunto VARCHAR(255) NOT NULL,
    rpt_detalhes TEXT,
    rpt_discutido BOOLEAN NOT NULL DEFAULT FALSE,
    rpt_votado BOOLEAN NOT NULL DEFAULT FALSE,
    rpt_a_favor SMALLINT,
    rpt_contra SMALLINT,
    rpt_abstencoes SMALLINT,
    rpt_vot_id INT,
    rpt_deliberacao TEXT,
    rpt_estado estado_ponto_t NOT NULL DEFAULT 'PENDENTE',
    rpt_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpt_criado_por INT,
    rpt_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpt_modificado_por INT,
    rpt_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rpt_reu_id FOREIGN KEY (rpt_reu_id) REFERENCES secretaria.reuniao(reu_id),
    CONSTRAINT chk_rpt_votacao CHECK (rpt_votado OR (rpt_a_favor IS NULL AND rpt_contra IS NULL AND rpt_abstencoes IS NULL)),
    CONSTRAINT chk_rpt_contagens CHECK (COALESCE(rpt_a_favor, 0) >= 0 AND COALESCE(rpt_contra, 0) >= 0 AND COALESCE(rpt_abstencoes, 0) >= 0),
    CONSTRAINT chk_rpt_end_date CHECK (rpt_end_date IS NULL OR rpt_end_date >= rpt_criado_em)
);
COMMENT ON TABLE secretaria.reuniao_ponto IS 'Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação';
COMMENT ON COLUMN secretaria.reuniao_ponto.rpt_vot_id IS 'Voto formal da acta (admissões, transferências, ...) ligado a este ponto';
COMMENT ON COLUMN secretaria.reuniao_ponto.rpt_deliberacao IS 'Decisão ou deliberação tomada';
CREATE INDEX idx_rpt_reu_id ON secretaria.reuniao_ponto (rpt_reu_id);
CREATE INDEX idx_rpt_vot_id ON secretaria.reuniao_ponto (rpt_vot_id);

CREATE TRIGGER trg_rpr_00_padrao BEFORE INSERT OR UPDATE ON secretaria.reuniao_presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rpr', 'secretaria.reuniao_presenca', '');
CREATE TRIGGER trg_rpr_00_sem_delete BEFORE DELETE ON secretaria.reuniao_presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rpr');
CREATE TRIGGER trg_rpr_00_sem_truncate BEFORE TRUNCATE ON secretaria.reuniao_presenca FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rpr');
CREATE TRIGGER trg_rpr_99_log AFTER UPDATE ON secretaria.reuniao_presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rpr');
ALTER TABLE secretaria.reuniao_presenca ADD CONSTRAINT fk_rpr_criado_por FOREIGN KEY (rpr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.reuniao_presenca ADD CONSTRAINT fk_rpr_modificado_por FOREIGN KEY (rpr_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_rpt_00_padrao BEFORE INSERT OR UPDATE ON secretaria.reuniao_ponto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rpt', 'secretaria.reuniao_ponto', '');
CREATE TRIGGER trg_rpt_00_sem_delete BEFORE DELETE ON secretaria.reuniao_ponto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rpt');
CREATE TRIGGER trg_rpt_00_sem_truncate BEFORE TRUNCATE ON secretaria.reuniao_ponto FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rpt');
CREATE TRIGGER trg_rpt_99_log AFTER UPDATE ON secretaria.reuniao_ponto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rpt');
ALTER TABLE secretaria.reuniao_ponto ADD CONSTRAINT fk_rpt_criado_por FOREIGN KEY (rpt_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.reuniao_ponto ADD CONSTRAINT fk_rpt_modificado_por FOREIGN KEY (rpt_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE secretaria.reuniao_presenca ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rpr_ler ON secretaria.reuniao_presenca FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpr_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_presenca.ler'))::INT[])));
CREATE POLICY pol_rpr_criar ON secretaria.reuniao_presenca FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpr_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_presenca.criar'))::INT[])));
CREATE POLICY pol_rpr_alterar ON secretaria.reuniao_presenca FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpr_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_presenca.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpr_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_presenca.alterar'))::INT[])));
ALTER TABLE secretaria.reuniao_ponto ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rpt_ler ON secretaria.reuniao_ponto FOR SELECT USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpt_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_ponto.ler'))::INT[])));
CREATE POLICY pol_rpt_criar ON secretaria.reuniao_ponto FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpt_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_ponto.criar'))::INT[])));
CREATE POLICY pol_rpt_alterar ON secretaria.reuniao_ponto FOR UPDATE USING (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpt_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_ponto.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM secretaria.reuniao x WHERE x.reu_id = rpt_reu_id AND x.reu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.reuniao_ponto.alterar'))::INT[])));

GRANT SELECT, INSERT, UPDATE ON secretaria.reuniao_presenca, secretaria.reuniao_ponto TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA secretaria TO app_igreja;

-- ---------------------------------------------------------------- permissões e perfis
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('secretaria.reuniao_presenca.ler', 'Ler: Presenças nas reuniões: quem esteve e quem faltou (com a justificação)'),
  ('secretaria.reuniao_presenca.criar', 'Criar: Presenças nas reuniões: quem esteve e quem faltou (com a justificação)'),
  ('secretaria.reuniao_presenca.alterar', 'Alterar: Presenças nas reuniões: quem esteve e quem faltou (com a justificação)'),
  ('secretaria.reuniao_presenca.terminar', 'Terminar (end_date): Presenças nas reuniões: quem esteve e quem faltou (com a justificação)'),
  ('secretaria.reuniao_ponto.ler', 'Ler: Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação'),
  ('secretaria.reuniao_ponto.criar', 'Criar: Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação'),
  ('secretaria.reuniao_ponto.alterar', 'Alterar: Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação'),
  ('secretaria.reuniao_ponto.terminar', 'Terminar (end_date): Pontos da agenda de uma reunião: assunto, discussão, votação e deliberação');
-- tudo: ADMIN, PASTOR, ANCIAO, SECRETARIO; só ler: ADMIN_ASSOCIACAO, SECRETARIO_ASSOCIACAO (como no gen.py)
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pe.per_id, pm.prm_id FROM nucleo.perfil pe JOIN nucleo.permissao pm ON pm.prm_codigo LIKE 'secretaria.reuniao\_p%'
WHERE pe.per_nome IN ('ADMIN', 'PASTOR', 'ANCIAO', 'SECRETARIO')
   OR (pe.per_nome IN ('ADMIN_ASSOCIACAO', 'SECRETARIO_ASSOCIACAO') AND pm.prm_codigo LIKE '%.ler');

-- ---------------------------------------------------------------- regras
-- ---------------------------------------------------------------- conselho e actas (V22)
-- Fim previsto do mandato: início + duração dos mandatos da igreja (menos um dia). Recalcula-se se o início
-- mudar e o fim previsto não for corrigido à mão.
CREATE FUNCTION secretaria.fn_ofi_fim_previsto() RETURNS trigger AS $$
DECLARE v_anos SMALLINT;
BEGIN
    IF NEW.ofi_fim_previsto IS NULL
       OR (TG_OP = 'UPDATE' AND NEW.ofi_data_inicio IS DISTINCT FROM OLD.ofi_data_inicio
           AND NEW.ofi_fim_previsto IS NOT DISTINCT FROM OLD.ofi_fim_previsto) THEN
        SELECT igr_mandato_anos INTO v_anos FROM organizacao.igreja WHERE igr_id = NEW.ofi_igr_id;
        NEW.ofi_fim_previsto := (NEW.ofi_data_inicio + make_interval(years => COALESCE(v_anos, 1)) - INTERVAL '1 day')::date;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ofi_05_fim_previsto
    BEFORE INSERT OR UPDATE ON secretaria.oficial
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_ofi_fim_previsto();

-- Acta aprovada fica fechada: presenças e pontos da agenda já não se registam nem se alteram
CREATE FUNCTION secretaria.fn_reuniao_acta_aberta() RETURNS trigger AS $$
DECLARE v_estado nucleo.estado_reuniao_t;
BEGIN
    -- a mesma função serve as duas tabelas: lê o id da reunião pelo nome da coluna (rpr_ ou rpt_)
    SELECT reu_estado INTO v_estado FROM secretaria.reuniao
     WHERE reu_id = (to_jsonb(NEW) ->> (CASE TG_TABLE_NAME WHEN 'reuniao_presenca' THEN 'rpr_reu_id' ELSE 'rpt_reu_id' END))::INT;
    IF v_estado = 'ACTA_APROVADA' THEN
        RAISE EXCEPTION 'A acta desta reunião já foi aprovada: as presenças e os pontos da agenda já não se alteram';
    END IF;
    IF v_estado = 'CANCELADA' THEN
        RAISE EXCEPTION 'Esta reunião foi cancelada';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rpr_10_acta_aberta
    BEFORE INSERT OR UPDATE ON secretaria.reuniao_presenca
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_reuniao_acta_aberta();
CREATE TRIGGER trg_rpt_10_acta_aberta
    BEFORE INSERT OR UPDATE ON secretaria.reuniao_ponto
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_reuniao_acta_aberta();

-- ---------------------------------------------------------------- vistas
CREATE OR REPLACE VIEW secretaria.vw_mandatos_a_terminar WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, c.car_nome AS cargo, m.mem_nome || ' ' || m.mem_apelido AS membro,
       o.ofi_data_inicio, COALESCE(o.ofi_fim_previsto, (o.ofi_data_inicio + make_interval(years => c.car_mandato_anos))::date) AS fim_previsto
FROM secretaria.oficial o
JOIN organizacao.cargo c ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m ON m.mem_id = o.ofi_mem_id
WHERE o.ofi_end_date IS NULL AND o.ofi_data_fim IS NULL
  AND COALESCE(o.ofi_fim_previsto, (o.ofi_data_inicio + make_interval(years => c.car_mandato_anos))::date) < CURRENT_DATE + 60;

-- Conselho da igreja: os oficiais (com cargo do conselho ou não), o contacto principal e o estado do mandato
CREATE VIEW secretaria.vw_conselho WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, o.ofi_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       c.car_id AS cargo_id, c.car_nome AS cargo, c.car_conselho AS do_conselho,
       o.ofi_data_inicio, o.ofi_fim_previsto, o.ofi_data_fim,
       (SELECT ct.cto_valor FROM secretaria.contacto ct
         WHERE ct.cto_mem_id = o.ofi_mem_id AND ct.cto_end_date IS NULL
         ORDER BY ct.cto_principal DESC, (ct.cto_tipo = 'TELEFONE') DESC, ct.cto_id LIMIT 1) AS contacto,
       CASE WHEN o.ofi_data_inicio > CURRENT_DATE THEN 'FUTURO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE THEN 'TERMINADO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE + 60 THEN 'A_TERMINAR'
            ELSE 'ACTIVO' END AS estado_mandato
FROM secretaria.oficial o
JOIN organizacao.cargo c   ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m   ON m.mem_id = o.ofi_mem_id
WHERE o.ofi_end_date IS NULL;

GRANT SELECT ON secretaria.vw_conselho TO app_igreja;

-- ---------------------------------------------------------------- dados: cargos do conselho e mandatos em curso
UPDATE organizacao.cargo SET car_conselho = TRUE
 WHERE car_nome IN ('Ancião', 'Diácono', 'Diaconisa', 'Secretário(a) da igreja', 'Tesoureiro(a)', 'Secretário(a) da junta',
                    'Director(a) da Escola Sabatina', 'Director(a) do Ministério Pessoal', 'Director(a) de Jovens',
                    'Director(a) de Desbravadores', 'Director(a) de Aventureiros', 'Director(a) do Ministério da Mulher',
                    'Director(a) do Ministério da Criança', 'Director(a) de Mordomia', 'Director(a) de Comunicação');
INSERT INTO organizacao.cargo (car_nome, car_mandato_anos, car_conselho)
SELECT 'Vogal do conselho', 1, TRUE WHERE NOT EXISTS (SELECT 1 FROM organizacao.cargo WHERE car_nome = 'Vogal do conselho');
-- mandatos já registados: o fim previsto pela duração da igreja (o trigger trata dos novos)
UPDATE secretaria.oficial o SET ofi_fim_previsto = (o.ofi_data_inicio + make_interval(years => i.igr_mandato_anos) - INTERVAL '1 day')::date
  FROM organizacao.igreja i WHERE i.igr_id = o.ofi_igr_id AND o.ofi_fim_previsto IS NULL;

-- >>>>> V23__tabelas_comuns_e_ofertas_da_igreja.sql
-- =====================================================================
-- V23 · Tabelas comuns só se mudam ao nível da Associação; ofertas próprias de cada igreja
--
-- Problema (encontrado ao preparar as ofertas da igreja): as tabelas comuns a todas as igrejas (fundos gerais,
-- plano de contas, calendário de ofertas, trimestres, sábados e pesos da Escola Sabatina) aceitavam escritas de
-- quem tivesse a permissão em QUALQUER igreja (fn_tem_permissao_global). Um tesoureiro de igreja podia, por
-- exemplo, marcar uma categoria de despesa como "de remessa" ou mudar a parte da Missão na oferta combinada
-- para todas as igrejas, e terminar fundos gerais.
--
-- Agora:
--   * criar/alterar/terminar uma linha comum exige a permissão ao nível da Associação (perfil em
--     usuario_entidade, ex.: ADMIN_ASSOCIACAO) ou ser super-administrador (fn_tem_permissao_comum);
--   * cada igreja pode ter fundos seus (ofertas especiais e projectos: construção, gratidão, ...) com a
--     permissão nessa igreja; ficam 100% na igreja (chk_fun_da_igreja) e terminam-se com a permissão dessa igreja.
--   * o fundo de uma igreja só entra nos movimentos e despesas dessa igreja;
--   * despesa com a categoria "Outras despesas" diz que despesa é (des_outra_categoria);
--   * a contagem do numerário separa dízimos, ofertas, Escola Sabatina e outras ofertas, e a conferência
--     compara cada parte com o lançado.
-- A leitura não muda.
-- =====================================================================

-- V23: linhas comuns definidas pela Associação/Missão (fundos gerais, plano de contas, calendário, lição): só com a
-- permissão ao nível da Associação (perfil em usuario_entidade) ou como super-administrador. Ter a permissão numa
-- igreja não chega para mudar o que vale para todas.
CREATE FUNCTION nucleo.fn_tem_permissao_comum(p_codigo TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
    RETURN nucleo.fn_e_super_admin() OR EXISTS (SELECT 1 FROM nucleo.fn_entidades_com_permissao(p_codigo));
END $$;

-- Trigger: terminar/reactivar uma linha comum (sem igreja) exige a permissão "terminar" ao nível da Associação.
-- Argumentos: prefixo, código da tabela, coluna da igreja ('' se a tabela não tem igreja).
CREATE FUNCTION nucleo.fn_terminar_comum() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE o JSONB := to_jsonb(OLD); n JSONB := to_jsonb(NEW); p TEXT := TG_ARGV[0];
BEGIN
    IF (o ->> (p || '_end_date')) IS DISTINCT FROM (n ->> (p || '_end_date'))
       AND (TG_ARGV[2] = '' OR n ->> TG_ARGV[2] IS NULL)
       AND nucleo.fn_usuario_sessao() IS NOT NULL
       AND NOT nucleo.fn_tem_permissao_comum(TG_ARGV[1] || '.terminar') THEN
        RAISE EXCEPTION 'Sem permissão: só a Associação/Missão termina ou reactiva registos comuns a todas as igrejas (%)', TG_ARGV[1]
              USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN NEW;
END $$;


GRANT EXECUTE ON FUNCTION nucleo.fn_tem_permissao_comum(TEXT) TO app_igreja;
GRANT EXECUTE ON FUNCTION nucleo.fn_terminar_comum() TO app_igreja;

-- escrever linhas comuns: só a Associação
DROP POLICY pol_fun_criar ON tesouraria.fundo;
CREATE POLICY pol_fun_criar ON tesouraria.fundo FOR INSERT WITH CHECK (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.criar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('tesouraria.fundo.criar'))));
DROP POLICY pol_fun_alterar ON tesouraria.fundo;
CREATE POLICY pol_fun_alterar ON tesouraria.fundo FOR UPDATE USING (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.alterar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('tesouraria.fundo.alterar')))) WITH CHECK (fun_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.fundo.alterar'))::INT[])) OR (fun_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('tesouraria.fundo.alterar'))));
DROP POLICY pol_cat_criar ON tesouraria.categoria;
CREATE POLICY pol_cat_criar ON tesouraria.categoria FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.categoria.criar')));
DROP POLICY pol_cat_alterar ON tesouraria.categoria;
CREATE POLICY pol_cat_alterar ON tesouraria.categoria FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.categoria.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.categoria.alterar')));
DROP POLICY pol_cof_criar ON tesouraria.calendario_oferta;
CREATE POLICY pol_cof_criar ON tesouraria.calendario_oferta FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.calendario_oferta.criar')));
DROP POLICY pol_cof_alterar ON tesouraria.calendario_oferta;
CREATE POLICY pol_cof_alterar ON tesouraria.calendario_oferta FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.calendario_oferta.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('tesouraria.calendario_oferta.alterar')));
DROP POLICY pol_etr_criar ON escola_sabatina.trimestre;
CREATE POLICY pol_etr_criar ON escola_sabatina.trimestre FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.trimestre.criar')));
DROP POLICY pol_etr_alterar ON escola_sabatina.trimestre;
CREATE POLICY pol_etr_alterar ON escola_sabatina.trimestre FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.trimestre.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.trimestre.alterar')));
DROP POLICY pol_esa_criar ON escola_sabatina.sabado;
CREATE POLICY pol_esa_criar ON escola_sabatina.sabado FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.sabado.criar')));
DROP POLICY pol_esa_alterar ON escola_sabatina.sabado;
CREATE POLICY pol_esa_alterar ON escola_sabatina.sabado FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.sabado.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.sabado.alterar')));
DROP POLICY pol_epc_criar ON escola_sabatina.pontuacao_config;
CREATE POLICY pol_epc_criar ON escola_sabatina.pontuacao_config FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.pontuacao_config.criar')));
DROP POLICY pol_epc_alterar ON escola_sabatina.pontuacao_config;
CREATE POLICY pol_epc_alterar ON escola_sabatina.pontuacao_config FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.pontuacao_config.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('escola_sabatina.pontuacao_config.alterar')));

-- terminar/reactivar linhas comuns: só a Associação; os fundos de uma igreja, com a permissão nessa igreja
DROP TRIGGER trg_fun_00_padrao ON tesouraria.fundo;
CREATE TRIGGER trg_fun_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fun', 'tesouraria.fundo', 'fun_igr_id');
CREATE TRIGGER trg_etr_01_comum BEFORE UPDATE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('etr', 'escola_sabatina.trimestre', '');
CREATE TRIGGER trg_esa_01_comum BEFORE UPDATE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('esa', 'escola_sabatina.sabado', '');
CREATE TRIGGER trg_epc_01_comum BEFORE UPDATE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('epc', 'escola_sabatina.pontuacao_config', '');
CREATE TRIGGER trg_fun_01_comum BEFORE UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('fun', 'tesouraria.fundo', 'fun_igr_id');
CREATE TRIGGER trg_cof_01_comum BEFORE UPDATE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('cof', 'tesouraria.calendario_oferta', '');
CREATE TRIGGER trg_cat_01_comum BEFORE UPDATE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('cat', 'tesouraria.categoria', '');

-- fundos de uma igreja: ofertas especiais e projectos, sem parte para a Missão
ALTER TABLE tesouraria.fundo ADD CONSTRAINT chk_fun_da_igreja
    CHECK (fun_igr_id IS NULL OR (fun_percentagem_remessa = 0 AND fun_destino_ent_id IS NULL AND fun_tipo IN ('OFERTA_ESPECIAL', 'PROJECTO')));
COMMENT ON COLUMN tesouraria.fundo.fun_igr_id IS 'NULL = fundo geral (da Associação/Missão); preenchido = oferta ou projecto próprio desta igreja (100% da igreja)';

-- despesa com a categoria "Outras despesas": que despesa é
ALTER TABLE tesouraria.despesa ADD COLUMN des_outra_categoria VARCHAR(100);
COMMENT ON COLUMN tesouraria.despesa.des_outra_categoria IS 'Com a categoria "Outras despesas": que despesa é (V23)';

-- O fundo próprio de uma igreja (oferta ou projecto dela) só entra nos movimentos e nas despesas dessa igreja.
CREATE FUNCTION tesouraria.fn_fundo_da_igreja(p_fun INT, p_igr INT) RETURNS VOID AS $$
DECLARE v_igr INT; v_nome TEXT;
BEGIN
    SELECT fun_igr_id, fun_nome INTO v_igr, v_nome FROM tesouraria.fundo WHERE fun_id = p_fun;
    IF v_igr IS NOT NULL AND v_igr IS DISTINCT FROM p_igr THEN
        RAISE EXCEPTION 'O fundo "%" é de outra igreja', v_nome;
    END IF;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE FUNCTION tesouraria.fn_tli_fundo_da_igreja() RETURNS trigger AS $$
BEGIN
    PERFORM tesouraria.fn_fundo_da_igreja(NEW.tli_fun_id, (SELECT tra_igr_id FROM tesouraria.transacao WHERE tra_id = NEW.tli_tra_id));
    RETURN NEW;
END $$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER trg_tli_30_fundo_da_igreja BEFORE INSERT OR UPDATE OF tli_fun_id ON tesouraria.transacao_linha
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tli_fundo_da_igreja();

-- Despesa: fundo da própria igreja; com a categoria "Outras despesas" (D9) diz-se que despesa é.
CREATE FUNCTION tesouraria.fn_des_fundo_e_outra() RETURNS trigger AS $$
BEGIN
    PERFORM tesouraria.fn_fundo_da_igreja(NEW.des_fun_id, NEW.des_igr_id);
    IF (SELECT cat_codigo FROM tesouraria.categoria WHERE cat_id = NEW.des_cat_id) = 'D9'
       AND coalesce(btrim(NEW.des_outra_categoria), '') = '' THEN
        RAISE EXCEPTION 'Com a categoria "Outras despesas", escreva que despesa é';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER trg_des_30_fundo_e_outra BEFORE INSERT OR UPDATE OF des_fun_id, des_cat_id, des_outra_categoria ON tesouraria.despesa
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_des_fundo_e_outra();

-- contagem do numerário por partes: dízimos, ofertas, Escola Sabatina e outras ofertas (a soma = total contado)
ALTER TABLE tesouraria.contagem_numerario
    ADD COLUMN cnu_dizimos DECIMAL(14,2), ADD COLUMN cnu_ofertas DECIMAL(14,2),
    ADD COLUMN cnu_escola_sabatina DECIMAL(14,2), ADD COLUMN cnu_outras DECIMAL(14,2),
    ADD CONSTRAINT chk_cnu_partes CHECK ((cnu_dizimos IS NULL AND cnu_ofertas IS NULL AND cnu_escola_sabatina IS NULL AND cnu_outras IS NULL) OR
        (cnu_dizimos >= 0 AND cnu_ofertas >= 0 AND cnu_escola_sabatina >= 0 AND cnu_outras >= 0 AND
         cnu_dizimos + cnu_ofertas + cnu_escola_sabatina + cnu_outras = cnu_total_contado));
COMMENT ON COLUMN tesouraria.contagem_numerario.cnu_dizimos IS 'Parte do contado: dízimos (V23)';
COMMENT ON COLUMN tesouraria.contagem_numerario.cnu_ofertas IS 'Parte do contado: ofertas (oferta combinada, missionárias)';
COMMENT ON COLUMN tesouraria.contagem_numerario.cnu_escola_sabatina IS 'Parte do contado: ofertas da Escola Sabatina';
COMMENT ON COLUMN tesouraria.contagem_numerario.cnu_outras IS 'Parte do contado: outras ofertas (especiais, projectos da igreja)';
CREATE OR REPLACE VIEW tesouraria.vw_contagem_conferencia WITH (security_invoker = true) AS
SELECT c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado,
       COALESCE(x.total, 0)                       AS total_lancado,
       c.cnu_total_contado - COALESCE(x.total, 0) AS diferenca,
       c.cnu_estado,
       -- V23: o contado e o lançado por parte (dízimos, ofertas, Escola Sabatina, outras ofertas)
       c.cnu_dizimos, c.cnu_ofertas, c.cnu_escola_sabatina, c.cnu_outras,
       COALESCE(x.dizimos, 0)         AS dizimos_lancado,
       COALESCE(x.ofertas, 0)         AS ofertas_lancado,
       COALESCE(x.escola_sabatina, 0) AS escola_sabatina_lancado,
       COALESCE(x.outras, 0)          AS outras_lancado
FROM tesouraria.contagem_numerario c
LEFT JOIN LATERAL (
    SELECT SUM(l.tli_valor) AS total,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo = 'DIZIMO') AS dizimos,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo IN ('OFERTA_COMBINADA', 'OFERTA_MISSIONARIA')) AS ofertas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo IN ('ES_MISSOES', 'ES_13_SABADO', 'ES_DESPESAS')) AS escola_sabatina,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo NOT IN ('DIZIMO', 'OFERTA_COMBINADA', 'OFERTA_MISSIONARIA',
                                                            'ES_MISSOES', 'ES_13_SABADO', 'ES_DESPESAS')) AS outras
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id
    WHERE t.tra_cnu_id = c.cnu_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
) x ON TRUE
WHERE c.cnu_end_date IS NULL;

-- >>>>> V24__nome_dos_depositos_a_missao.sql
-- =====================================================================
-- V24 · Nome da categoria: "Depósitos à Associação/Missão" em vez de "Remessas"
--
-- Na interface, "remessa" passou a chamar-se "depósito à Missão" (é o depósito do fim do mês na conta da
-- Missão, com o talão). A categoria do plano de contas acompanha o nome; o código (D1) e a marca de remessa
-- (cat_e_remessa) não mudam, nem os nomes técnicos (tabela remessa, rotas /remessas).
-- =====================================================================
UPDATE tesouraria.categoria SET cat_nome = 'Depósitos à Associação/Missão (remessas)'
 WHERE cat_codigo = 'D1' AND cat_nome = 'Remessas à Associação/Missão';

-- >>>>> V25__registar_igrejas.sql
-- =====================================================================
-- V25 · Registar igrejas (F-ORG-01, P-13)
--
-- Problema: ninguém conseguia registar uma igreja, nem o super-administrador. A política de INSERT exigia que o
-- id da igreja nova estivesse em fn_igrejas_com_permissao(...), mas essa lista só tem as igrejas que já existem.
--
-- Agora regista uma igreja o super-administrador, ou quem tem organizacao.igreja.criar ao nível da
-- Associação/Missão a que a igreja pertence (perfil em usuario_entidade, ex.: ADMIN_ASSOCIACAO). Ter a permissão
-- numa igreja (perfil de igreja) não chega para criar outras. A leitura ganha a mesma regra (pela Associação da igreja):
-- o INSERT ... RETURNING da API lê a linha nova, que ainda não está na lista de igrejas do utilizador.
-- =====================================================================
DROP POLICY pol_igr_criar ON organizacao.igreja;
CREATE POLICY pol_igr_criar ON organizacao.igreja FOR INSERT WITH CHECK ((SELECT nucleo.fn_e_super_admin()) OR igr_ent_id IN (SELECT nucleo.fn_entidades_com_permissao('organizacao.igreja.criar')));
CREATE POLICY pol_igr_ler_associacao ON organizacao.igreja FOR SELECT USING ((SELECT nucleo.fn_e_super_admin()) OR igr_ent_id IN (SELECT nucleo.fn_entidades_com_permissao('organizacao.igreja.ler')));

-- >>>>> V26__provincias_e_distritos.sql
-- =====================================================================
-- V26 · Províncias, distritos e localidade das igrejas (F-ORG-01)
--
-- Onde fica cada igreja na divisão administrativa de Moçambique: província, distrito administrativo (na Cidade de
-- Maputo, distrito municipal) e localidade/bairro (texto). O distrito administrativo não é o distrito pastoral
-- (organizacao.distrito, da Associação/Missão), que continua igual.
-- Tabelas comuns: todos os utilizadores lêem; só a Associação/Missão (ou o super-administrador) as altera (V23).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TABLE organizacao.provincia (
    prv_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    prv_nome VARCHAR(60) NOT NULL,
    prv_codigo VARCHAR(10),
    prv_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    prv_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    prv_criado_por INT,
    prv_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    prv_modificado_por INT,
    prv_end_date TIMESTAMPTZ,
    CONSTRAINT chk_prv_end_date CHECK (prv_end_date IS NULL OR prv_end_date >= prv_criado_em)
);
COMMENT ON TABLE organizacao.provincia IS 'Províncias de Moçambique (e a Cidade de Maputo)';
COMMENT ON COLUMN organizacao.provincia.prv_codigo IS 'Sigla (ex.: MPC, GZA)';
CREATE UNIQUE INDEX uq_prv_nome ON organizacao.provincia (prv_nome) WHERE prv_end_date IS NULL;
CREATE TABLE organizacao.distrito_administrativo (
    dad_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    dad_prv_id INT NOT NULL,
    dad_nome VARCHAR(80) NOT NULL,
    dad_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    dad_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dad_criado_por INT,
    dad_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dad_modificado_por INT,
    dad_end_date TIMESTAMPTZ,
    CONSTRAINT fk_dad_prv_id FOREIGN KEY (dad_prv_id) REFERENCES organizacao.provincia(prv_id),
    CONSTRAINT chk_dad_end_date CHECK (dad_end_date IS NULL OR dad_end_date >= dad_criado_em)
);
COMMENT ON TABLE organizacao.distrito_administrativo IS 'Distritos administrativos de cada província (e distritos municipais da Cidade de Maputo)';
CREATE UNIQUE INDEX uq_dad_prv_id_nome ON organizacao.distrito_administrativo (dad_prv_id, dad_nome) WHERE dad_end_date IS NULL;

-- comportamento comum (campos-padrão, nada se apaga, auditoria, terminar só pela Associação)
CREATE TRIGGER trg_prv_00_padrao BEFORE INSERT OR UPDATE ON organizacao.provincia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('prv', 'organizacao.provincia', '');
CREATE TRIGGER trg_prv_00_sem_delete BEFORE DELETE ON organizacao.provincia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('prv');
CREATE TRIGGER trg_prv_00_sem_truncate BEFORE TRUNCATE ON organizacao.provincia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('prv');
CREATE TRIGGER trg_prv_01_comum BEFORE UPDATE ON organizacao.provincia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('prv', 'organizacao.provincia', '');
CREATE TRIGGER trg_prv_99_log AFTER UPDATE ON organizacao.provincia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('prv');
ALTER TABLE organizacao.provincia ADD CONSTRAINT fk_prv_criado_por FOREIGN KEY (prv_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.provincia ADD CONSTRAINT fk_prv_modificado_por FOREIGN KEY (prv_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_dad_00_padrao BEFORE INSERT OR UPDATE ON organizacao.distrito_administrativo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dad', 'organizacao.distrito_administrativo', '');
CREATE TRIGGER trg_dad_00_sem_delete BEFORE DELETE ON organizacao.distrito_administrativo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dad');
CREATE TRIGGER trg_dad_00_sem_truncate BEFORE TRUNCATE ON organizacao.distrito_administrativo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dad');
CREATE TRIGGER trg_dad_01_comum BEFORE UPDATE ON organizacao.distrito_administrativo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('dad', 'organizacao.distrito_administrativo', '');
CREATE TRIGGER trg_dad_99_log AFTER UPDATE ON organizacao.distrito_administrativo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dad');
ALTER TABLE organizacao.distrito_administrativo ADD CONSTRAINT fk_dad_criado_por FOREIGN KEY (dad_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.distrito_administrativo ADD CONSTRAINT fk_dad_modificado_por FOREIGN KEY (dad_modificado_por) REFERENCES nucleo.usuario(usu_id);

-- segurança
ALTER TABLE organizacao.provincia ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizacao.distrito_administrativo ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_prv_ler ON organizacao.provincia FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_prv_criar ON organizacao.provincia FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('organizacao.provincia.criar')));
CREATE POLICY pol_prv_alterar ON organizacao.provincia FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('organizacao.provincia.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('organizacao.provincia.alterar')));
CREATE POLICY pol_dad_ler ON organizacao.distrito_administrativo FOR SELECT USING (nucleo.fn_usuario_sessao() IS NOT NULL);
CREATE POLICY pol_dad_criar ON organizacao.distrito_administrativo FOR INSERT WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('organizacao.distrito_administrativo.criar')));
CREATE POLICY pol_dad_alterar ON organizacao.distrito_administrativo FOR UPDATE USING ((SELECT nucleo.fn_tem_permissao_comum('organizacao.distrito_administrativo.alterar'))) WITH CHECK ((SELECT nucleo.fn_tem_permissao_comum('organizacao.distrito_administrativo.alterar')));
GRANT SELECT, INSERT, UPDATE ON organizacao.provincia, organizacao.distrito_administrativo TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA organizacao TO app_igreja;

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('organizacao.provincia.criar', 'Criar: Províncias de Moçambique (e a Cidade de Maputo)'),
  ('organizacao.provincia.alterar', 'Alterar: Províncias de Moçambique (e a Cidade de Maputo)'),
  ('organizacao.provincia.terminar', 'Terminar (end_date): Províncias de Moçambique (e a Cidade de Maputo)'),
  ('organizacao.distrito_administrativo.criar', 'Criar: Distritos administrativos de cada província (e distritos municipais da Cidade de Maputo)'),
  ('organizacao.distrito_administrativo.alterar', 'Alterar: Distritos administrativos de cada província (e distritos municipais da Cidade de Maputo)'),
  ('organizacao.distrito_administrativo.terminar', 'Terminar (end_date): Distritos administrativos de cada província (e distritos municipais da Cidade de Maputo)');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pe.per_id, pm.prm_id FROM nucleo.perfil pe
JOIN nucleo.permissao pm ON pm.prm_codigo LIKE 'organizacao.provincia.%' OR pm.prm_codigo LIKE 'organizacao.distrito\_administrativo.%'
WHERE pe.per_nome = 'ADMIN_ASSOCIACAO';

-- a igreja: província, distrito e localidade
ALTER TABLE organizacao.igreja
  ADD COLUMN igr_prv_id INT,
  ADD COLUMN igr_dad_id INT,
  ADD COLUMN igr_localidade VARCHAR(120),
  ADD CONSTRAINT fk_igr_prv_id FOREIGN KEY (igr_prv_id) REFERENCES organizacao.provincia(prv_id),
  ADD CONSTRAINT fk_igr_dad_id FOREIGN KEY (igr_dad_id) REFERENCES organizacao.distrito_administrativo(dad_id);
COMMENT ON COLUMN organizacao.igreja.igr_prv_id IS 'Província onde fica (V26)';
COMMENT ON COLUMN organizacao.igreja.igr_dad_id IS 'Distrito administrativo onde fica (V26)';
COMMENT ON COLUMN organizacao.igreja.igr_localidade IS 'Localidade / bairro (V26)';
CREATE INDEX idx_igr_prv_id ON organizacao.igreja (igr_prv_id);
CREATE INDEX idx_igr_dad_id ON organizacao.igreja (igr_dad_id);

-- ---------------------------------------------------------------- organização: regras
-- V26: o distrito administrativo da igreja pertence à província indicada. Sem província, vem a do distrito.
CREATE FUNCTION organizacao.fn_igr_provincia_distrito() RETURNS trigger AS $$
DECLARE v_prv INT;
BEGIN
    IF NEW.igr_dad_id IS NOT NULL THEN
        SELECT dad_prv_id INTO v_prv FROM organizacao.distrito_administrativo WHERE dad_id = NEW.igr_dad_id;
        IF NEW.igr_prv_id IS NULL THEN
            NEW.igr_prv_id := v_prv;
        ELSIF NEW.igr_prv_id IS DISTINCT FROM v_prv THEN
            RAISE EXCEPTION 'O distrito escolhido não pertence a essa província';
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_igr_20_provincia_distrito BEFORE INSERT OR UPDATE OF igr_prv_id, igr_dad_id ON organizacao.igreja
    FOR EACH ROW EXECUTE FUNCTION organizacao.fn_igr_provincia_distrito();

-- dados de referência
-- Divisão administrativa de Moçambique (V26): as 11 províncias (com a Cidade de Maputo) e os seus distritos
-- (na Cidade de Maputo, os distritos municipais). Lista de referência: a Associação/Missão pode acrescentar ou
-- corrigir em Administração (permissões organizacao.provincia.* / organizacao.distrito_administrativo.*).
INSERT INTO organizacao.provincia (prv_nome, prv_codigo) VALUES
  ('Niassa', 'NSA'), ('Cabo Delgado', 'CDG'), ('Nampula', 'NPL'), ('Zambézia', 'ZBZ'), ('Tete', 'TTE'),
  ('Manica', 'MNC'), ('Sofala', 'SFL'), ('Inhambane', 'IBN'), ('Gaza', 'GZA'), ('Maputo Província', 'MPP'),
  ('Cidade de Maputo', 'MPC');

INSERT INTO organizacao.distrito_administrativo (dad_prv_id, dad_nome)
SELECT p.prv_id, d.nome
FROM (VALUES
  ('Niassa', 'Chimbunila'), ('Niassa', 'Cidade de Lichinga'), ('Niassa', 'Cuamba'), ('Niassa', 'Lago'),
  ('Niassa', 'Majune'), ('Niassa', 'Mandimba'), ('Niassa', 'Marrupa'), ('Niassa', 'Maúa'), ('Niassa', 'Mavago'),
  ('Niassa', 'Mecanhelas'), ('Niassa', 'Mecula'), ('Niassa', 'Metarica'), ('Niassa', 'Muembe'),
  ('Niassa', 'N''gauma'), ('Niassa', 'Nipepe'), ('Niassa', 'Sanga'),
  ('Cabo Delgado', 'Ancuabe'), ('Cabo Delgado', 'Balama'), ('Cabo Delgado', 'Chiúre'), ('Cabo Delgado', 'Cidade de Pemba'),
  ('Cabo Delgado', 'Ibo'), ('Cabo Delgado', 'Macomia'), ('Cabo Delgado', 'Mecúfi'), ('Cabo Delgado', 'Meluco'),
  ('Cabo Delgado', 'Metuge'), ('Cabo Delgado', 'Mocímboa da Praia'), ('Cabo Delgado', 'Montepuez'), ('Cabo Delgado', 'Mueda'),
  ('Cabo Delgado', 'Muidumbe'), ('Cabo Delgado', 'Namuno'), ('Cabo Delgado', 'Nangade'), ('Cabo Delgado', 'Palma'),
  ('Cabo Delgado', 'Quissanga'),
  ('Nampula', 'Angoche'), ('Nampula', 'Cidade de Nampula'), ('Nampula', 'Eráti'), ('Nampula', 'Ilha de Moçambique'),
  ('Nampula', 'Lalaua'), ('Nampula', 'Larde'), ('Nampula', 'Liúpo'), ('Nampula', 'Malema'), ('Nampula', 'Meconta'),
  ('Nampula', 'Mecubúri'), ('Nampula', 'Memba'), ('Nampula', 'Mogincual'), ('Nampula', 'Mogovolas'), ('Nampula', 'Moma'),
  ('Nampula', 'Monapo'), ('Nampula', 'Mossuril'), ('Nampula', 'Muecate'), ('Nampula', 'Murrupula'),
  ('Nampula', 'Nacala-a-Velha'), ('Nampula', 'Nacala Porto'), ('Nampula', 'Nacarôa'), ('Nampula', 'Rapale'), ('Nampula', 'Ribaué'),
  ('Zambézia', 'Alto Molócuè'), ('Zambézia', 'Chinde'), ('Zambézia', 'Cidade de Quelimane'), ('Zambézia', 'Derre'),
  ('Zambézia', 'Gilé'), ('Zambézia', 'Gurué'), ('Zambézia', 'Ile'), ('Zambézia', 'Inhassunge'), ('Zambézia', 'Luabo'),
  ('Zambézia', 'Lugela'), ('Zambézia', 'Maganja da Costa'), ('Zambézia', 'Milange'), ('Zambézia', 'Mocuba'),
  ('Zambézia', 'Mocubela'), ('Zambézia', 'Molumbo'), ('Zambézia', 'Mopeia'), ('Zambézia', 'Morrumbala'),
  ('Zambézia', 'Mulevala'), ('Zambézia', 'Namacurra'), ('Zambézia', 'Namarrói'), ('Zambézia', 'Nicoadala'), ('Zambézia', 'Pebane'),
  ('Tete', 'Angónia'), ('Tete', 'Cahora-Bassa'), ('Tete', 'Changara'), ('Tete', 'Chifunde'), ('Tete', 'Chiuta'),
  ('Tete', 'Cidade de Tete'), ('Tete', 'Dôa'), ('Tete', 'Macanga'), ('Tete', 'Magoé'), ('Tete', 'Marara'),
  ('Tete', 'Marávia'), ('Tete', 'Moatize'), ('Tete', 'Mutarara'), ('Tete', 'Tsangano'), ('Tete', 'Zumbo'),
  ('Manica', 'Bárue'), ('Manica', 'Cidade de Chimoio'), ('Manica', 'Gondola'), ('Manica', 'Guro'), ('Manica', 'Macate'),
  ('Manica', 'Machaze'), ('Manica', 'Macossa'), ('Manica', 'Manica'), ('Manica', 'Mossurize'), ('Manica', 'Sussundenga'),
  ('Manica', 'Tambara'), ('Manica', 'Vanduzi'),
  ('Sofala', 'Búzi'), ('Sofala', 'Caia'), ('Sofala', 'Chemba'), ('Sofala', 'Cheringoma'), ('Sofala', 'Chibabava'),
  ('Sofala', 'Cidade da Beira'), ('Sofala', 'Dondo'), ('Sofala', 'Gorongosa'), ('Sofala', 'Machanga'),
  ('Sofala', 'Maringué'), ('Sofala', 'Marromeu'), ('Sofala', 'Muanza'), ('Sofala', 'Nhamatanda'),
  ('Inhambane', 'Cidade de Inhambane'), ('Inhambane', 'Funhalouro'), ('Inhambane', 'Govuro'), ('Inhambane', 'Homoíne'),
  ('Inhambane', 'Inharrime'), ('Inhambane', 'Inhassoro'), ('Inhambane', 'Jangamo'), ('Inhambane', 'Mabote'),
  ('Inhambane', 'Massinga'), ('Inhambane', 'Maxixe'), ('Inhambane', 'Morrumbene'), ('Inhambane', 'Panda'),
  ('Inhambane', 'Vilankulo'), ('Inhambane', 'Zavala'),
  ('Gaza', 'Bilene'), ('Gaza', 'Chibuto'), ('Gaza', 'Chicualacuala'), ('Gaza', 'Chigubo'), ('Gaza', 'Chókwè'),
  ('Gaza', 'Chongoene'), ('Gaza', 'Cidade de Xai-Xai'), ('Gaza', 'Guijá'), ('Gaza', 'Limpopo'), ('Gaza', 'Mabalane'),
  ('Gaza', 'Manjacaze'), ('Gaza', 'Mapai'), ('Gaza', 'Massangena'), ('Gaza', 'Massingir'),
  ('Maputo Província', 'Boane'), ('Maputo Província', 'Cidade da Matola'), ('Maputo Província', 'Magude'),
  ('Maputo Província', 'Manhiça'), ('Maputo Província', 'Marracuene'), ('Maputo Província', 'Matutuíne'),
  ('Maputo Província', 'Moamba'), ('Maputo Província', 'Namaacha'),
  ('Cidade de Maputo', 'KaMpfumo'), ('Cidade de Maputo', 'Nlhamankulu'), ('Cidade de Maputo', 'KaMaxakeni'),
  ('Cidade de Maputo', 'KaMavota'), ('Cidade de Maputo', 'KaMubukwana'), ('Cidade de Maputo', 'KaTembe'),
  ('Cidade de Maputo', 'KaNyaka')
) AS d(provincia, nome)
JOIN organizacao.provincia p ON p.prv_nome = d.provincia;

-- >>>>> V27__directorio_de_igrejas.sql
-- =====================================================================
-- V27 · Directório de igrejas e transferências vistas pelas duas igrejas (F-SEC-06, P-02)
--
-- Para pedir uma carta de transferência, a igreja de origem escolhe a igreja de destino; mas um secretário só vê
-- (RLS) a sua igreja. O directório mostra a QUALQUER utilizador com sessão só o nome, o tipo, a Associação/Missão e
-- a localização de cada igreja activa — informação pública, sem membros, dinheiro nem outros dados da igreja.
-- A vista NÃO é security_invoker de propósito (corre com os direitos do dono, que não está sujeito à RLS) e mostra
-- apenas estas colunas.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE VIEW organizacao.vw_directorio_igrejas AS
SELECT i.igr_id, i.igr_nome AS nome, i.igr_tipo AS tipo, i.igr_ent_id, e.ent_nome AS entidade,
       p.prv_nome AS provincia, d.dad_nome AS distrito, i.igr_localidade AS localidade
FROM organizacao.igreja i
JOIN organizacao.entidade e ON e.ent_id = i.igr_ent_id
LEFT JOIN organizacao.provincia p ON p.prv_id = i.igr_prv_id
LEFT JOIN organizacao.distrito_administrativo d ON d.dad_id = i.igr_dad_id
WHERE i.igr_end_date IS NULL AND nucleo.fn_usuario_sessao() IS NOT NULL;
COMMENT ON VIEW organizacao.vw_directorio_igrejas IS 'Directório público de igrejas (nome, tipo, Associação, localização) para escolher o destino de uma transferência (V27)';
GRANT SELECT ON organizacao.vw_directorio_igrejas TO app_igreja;

-- Transferências vistas pelas duas igrejas (P-02): a igreja de destino tem de saber QUEM vai receber, mas a RLS
-- não lhe mostra o membro (ainda é da igreja de origem). Esta vista (também com os direitos do dono) mostra o nome
-- do membro e das duas igrejas, só nas transferências de uma igreja em que o utilizador pode ler transferências.
CREATE VIEW secretaria.vw_transferencias AS
SELECT t.tme_id, t.tme_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       t.tme_origem_igr_id, io.igr_nome AS origem,
       t.tme_destino_igr_id, COALESCE(id.igr_nome, t.tme_destino_externo) AS destino, t.tme_destino_externo,
       t.tme_data_pedido, t.tme_origem_vot_id, t.tme_carta_emitida_em,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date AS valida_ate,
       COALESCE((t.tme_carta_emitida_em + INTERVAL '6 months')::date < CURRENT_DATE, FALSE) AS expirada,
       t.tme_destino_vot_id, t.tme_aceite_em, t.tme_observacoes, t.tme_estado
FROM secretaria.transferencia_membro t
JOIN secretaria.membro m       ON m.mem_id = t.tme_mem_id
JOIN organizacao.igreja io     ON io.igr_id = t.tme_origem_igr_id
LEFT JOIN organizacao.igreja id ON id.igr_id = t.tme_destino_igr_id
WHERE t.tme_end_date IS NULL
  AND (t.tme_origem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[])
       OR t.tme_destino_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[]));
COMMENT ON VIEW secretaria.vw_transferencias IS 'Transferências de membros com o nome do membro e das duas igrejas, para a origem e o destino (V27)';
GRANT SELECT ON secretaria.vw_transferencias TO app_igreja;

-- >>>>> V28__meditacao_hino_e_oracoes_da_reuniao.sql
-- =====================================================================
-- V28 · Reuniões: meditação, hino e orações (F-SEC-04)
--
-- A acta regista quem fez a meditação (um membro desta igreja ou um convidado, ex.: o pastor do distrito), o hino
-- entoado e quem fez a primeira e a última oração. Colunas opcionais: as reuniões antigas ficam como estão.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE secretaria.reuniao
  ADD COLUMN reu_meditacao_mem_id INT,
  ADD COLUMN reu_meditacao_convidado VARCHAR(150),
  ADD COLUMN reu_hino VARCHAR(150),
  ADD COLUMN reu_oracao_inicial_mem_id INT,
  ADD COLUMN reu_oracao_final_mem_id INT,
  ADD CONSTRAINT fk_reu_meditacao_mem_id FOREIGN KEY (reu_meditacao_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT fk_reu_oracao_inicial_mem_id FOREIGN KEY (reu_oracao_inicial_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT fk_reu_oracao_final_mem_id FOREIGN KEY (reu_oracao_final_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT chk_reu_meditacao CHECK (NOT (reu_meditacao_mem_id IS NOT NULL AND reu_meditacao_convidado IS NOT NULL));

COMMENT ON COLUMN secretaria.reuniao.reu_meditacao_mem_id IS 'Quem fez a meditação (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_meditacao_convidado IS 'Quem fez a meditação, se não for membro desta igreja (ex.: pastor do distrito) (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_hino IS 'Hino entoado, ex.: "Hino 123 — Castelo forte" (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_oracao_inicial_mem_id IS 'Quem fez a primeira oração (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_oracao_final_mem_id IS 'Quem fez a última oração (V28)';

CREATE INDEX idx_reu_meditacao_mem_id ON secretaria.reuniao (reu_meditacao_mem_id);
CREATE INDEX idx_reu_oracao_inicial_mem_id ON secretaria.reuniao (reu_oracao_inicial_mem_id);
CREATE INDEX idx_reu_oracao_final_mem_id ON secretaria.reuniao (reu_oracao_final_mem_id);

-- >>>>> V29__mensagens_das_restricoes.sql
-- V29 · Mensagens das restrições em português
--
-- Até aqui uma recusa por CHECK ou por único chegava ao utilizador como "Valor não permitido (chk_ers_numeros)"
-- ou "Já existe um registo com estes dados". Agora cada restrição tem a frase no seu COMMENT, e a API lê-as no
-- arranque (nucleo.fn_mensagens_restricoes) para responder com ela. A base de dados continua a decidir; passa a
-- explicar também. Quem acrescentar uma restrição deve acrescentar o COMMENT.
--
-- Formato do comentário: "[campoJson] Mensagem" (o campo é opcional; com ele o erro aparece junto ao campo).
-- Os CHECK genéricos "<pfx>_end_date >= <pfx>_criado_em" têm uma frase comum na API.

-- ---------------------------------------------------------------- função lida pela API no arranque
CREATE FUNCTION nucleo.fn_mensagens_restricoes()
RETURNS TABLE (nome TEXT, mensagem TEXT)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = pg_catalog AS $$
    SELECT c.conname::text, d.description
      FROM pg_constraint c
      JOIN pg_namespace n ON n.oid = c.connamespace
      JOIN pg_description d ON d.objoid = c.oid AND d.classoid = 'pg_constraint'::regclass
     WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
    UNION
    SELECT i.relname::text, d.description
      FROM pg_index x
      JOIN pg_class i ON i.oid = x.indexrelid
      JOIN pg_namespace n ON n.oid = i.relnamespace
      JOIN pg_description d ON d.objoid = i.oid AND d.classoid = 'pg_class'::regclass
     WHERE x.indisunique
       AND n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
$$;
COMMENT ON FUNCTION nucleo.fn_mensagens_restricoes() IS
    'Frase em português de cada restrição (COMMENT ON CONSTRAINT / INDEX), lida pela API para traduzir os erros 23514 e 23505';
REVOKE ALL ON FUNCTION nucleo.fn_mensagens_restricoes() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_mensagens_restricoes() TO app_igreja;

-- ---------------------------------------------------------------- Escola Sabatina
COMMENT ON CONSTRAINT chk_ers_numeros ON escola_sabatina.relatorio_sabado IS
    'Os números do relatório não batem: os presentes não podem ser mais do que os matriculados, quem estudou a lição não pode ser mais do que os presentes, e visitantes e filiais não podem ser negativos.';
COMMENT ON CONSTRAINT chk_ers_ofertas ON escola_sabatina.relatorio_sabado IS
    'As ofertas não podem ser negativas.';
COMMENT ON CONSTRAINT chk_epr_estudo ON escola_sabatina.presenca IS
    'Só quem esteve presente pode ser marcado como tendo estudado a lição.';
COMMENT ON CONSTRAINT chk_ect_alvos ON escola_sabatina.classe_trimestre IS
    'Os alvos não podem ser negativos e o alvo de estudo diário tem de estar entre 0% e 100%.';
COMMENT ON CONSTRAINT chk_ema_datas ON escola_sabatina.matricula IS
    '[dataSaida] A data de saída da classe não pode ser anterior à data de entrada.';
COMMENT ON CONSTRAINT chk_epc_soma ON escola_sabatina.pontuacao_config IS
    'Os quatro pesos da pontuação (presença, estudo, ofertas e visitantes) têm de somar 100%.';
COMMENT ON CONSTRAINT chk_epc_limite ON escola_sabatina.pontuacao_config IS
    '[limiteOfertas] O limite das ofertas tem de ser pelo menos 100% do alvo.';
COMMENT ON CONSTRAINT chk_esa_numero ON escola_sabatina.sabado IS
    '[numero] O número do sábado tem de estar entre 1 e 14.';
COMMENT ON CONSTRAINT chk_esa_sabado ON escola_sabatina.sabado IS
    '[data] A data indicada não é um sábado.';
COMMENT ON CONSTRAINT chk_etr_datas ON escola_sabatina.trimestre IS
    '[dataFim] O fim do trimestre tem de ser depois do início.';
COMMENT ON CONSTRAINT chk_etr_numero ON escola_sabatina.trimestre IS
    '[numero] O trimestre tem de ser o 1.º, 2.º, 3.º ou 4.º.';
COMMENT ON CONSTRAINT chk_etr_sabados ON escola_sabatina.trimestre IS
    'Um trimestre tem 13 ou 14 sábados; confirme as datas de início e de fim.';

COMMENT ON INDEX escola_sabatina.uq_ecl_igr_id_nome IS '[nome] Já existe uma classe com este nome nesta igreja.';
COMMENT ON INDEX escola_sabatina.uq_ect_ecl_id_etr_id IS 'Esta classe já está configurada para este trimestre.';
COMMENT ON INDEX escola_sabatina.uq_ema_activa IS '[membroId] Este membro já está matriculado noutra classe; tire-o primeiro dessa classe.';
COMMENT ON INDEX escola_sabatina.uq_epc_defeito IS 'Já existem pesos por defeito; altere-os em vez de criar outros.';
COMMENT ON INDEX escola_sabatina.uq_epc_trimestre IS 'Este trimestre já tem pesos próprios; altere-os em vez de criar outros.';
COMMENT ON INDEX escola_sabatina.uq_epr_ers_id_mem_id IS '[membroId] Este membro já está na chamada deste relatório.';
COMMENT ON INDEX escola_sabatina.uq_ers_ect_id_esa_id IS 'Esta classe já tem relatório neste sábado.';
COMMENT ON INDEX escola_sabatina.uq_esa_13 IS 'Este trimestre já tem um 13.º sábado marcado; desmarque-o primeiro.';
COMMENT ON INDEX escola_sabatina.uq_esa_data IS '[data] Já existe um sábado com esta data.';
COMMENT ON INDEX escola_sabatina.uq_esa_etr_id_numero IS '[numero] Este trimestre já tem um sábado com este número.';
COMMENT ON INDEX escola_sabatina.uq_etr_ano_numero IS 'Este trimestre já existe para esse ano.';

-- ---------------------------------------------------------------- Tesouraria
COMMENT ON CONSTRAINT chk_alv ON tesouraria.alvo IS 'O valor do alvo tem de ser maior que zero e o fim não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_cnu_contadores_diferentes ON tesouraria.contagem_numerario IS
    '[contador2MembroId] A contagem exige dois contadores diferentes.';
COMMENT ON CONSTRAINT chk_cnu_partes ON tesouraria.contagem_numerario IS
    'As partes da contagem (dízimos, ofertas, Escola Sabatina, outras) têm de somar o total contado.';
COMMENT ON CONSTRAINT chk_cnu_total ON tesouraria.contagem_numerario IS '[totalContado] O total contado não pode ser negativo.';
COMMENT ON CONSTRAINT chk_des_aprovacao ON tesouraria.despesa IS 'Uma despesa aprovada ou paga tem de ter quem a aprovou e o valor aprovado.';
COMMENT ON CONSTRAINT chk_des_quem_pede_nao_aprova ON tesouraria.despesa IS 'Quem pede a despesa não a pode aprovar.';
COMMENT ON CONSTRAINT chk_des_rejeicao ON tesouraria.despesa IS '[motivoRejeicao] Para rejeitar a despesa, indique o motivo.';
COMMENT ON CONSTRAINT chk_des_valores ON tesouraria.despesa IS 'Os valores da despesa têm de ser maiores que zero e o aprovado não pode passar o pedido.';
COMMENT ON CONSTRAINT chk_doc_dono ON tesouraria.documento IS 'O comprovativo tem de estar ligado a um movimento ou a uma despesa.';
COMMENT ON CONSTRAINT chk_fpe_mes ON tesouraria.fecho_periodo IS '[mes] O mês tem de estar entre 1 e 12.';
COMMENT ON CONSTRAINT chk_fun_associacao ON tesouraria.fundo IS 'Dízimo, oferta missionária e ofertas da Escola Sabatina para as missões são fundos da Associação, não da igreja.';
COMMENT ON CONSTRAINT chk_fun_da_igreja ON tesouraria.fundo IS 'Um fundo próprio da igreja fica 100% na igreja: não tem parte da Missão nem destino.';
COMMENT ON CONSTRAINT chk_fun_local ON tesouraria.fundo IS 'Este tipo de fundo só pode ser da igreja.';
COMMENT ON CONSTRAINT chk_fun_remessa ON tesouraria.fundo IS '[percentagemRemessa] A parte da Missão tem de estar entre 0% e 100%.';
COMMENT ON CONSTRAINT chk_orc_aprovado ON tesouraria.orcamento IS 'Para aprovar o orçamento é preciso o voto da igreja.';
COMMENT ON CONSTRAINT chk_orl_valor ON tesouraria.orcamento_linha IS '[valorPrevisto] O valor previsto não pode ser negativo.';
COMMENT ON CONSTRAINT chk_pmp_direccao ON tesouraria.pagamento_mpesa IS 'Direcção do pagamento M-Pesa inválida.';
COMMENT ON CONSTRAINT chk_rem_mes ON tesouraria.remessa IS '[mes] O mês tem de estar entre 1 e 12.';
COMMENT ON CONSTRAINT chk_rml_valor ON tesouraria.remessa_linha IS '[valor] O valor não pode ser negativo.';
COMMENT ON CONSTRAINT chk_tli_valor ON tesouraria.transacao_linha IS '[valor] Cada linha tem de ter um valor maior que zero.';
COMMENT ON CONSTRAINT chk_tra_anonimo ON tesouraria.transacao IS 'Uma contribuição anónima não pode ter membro nem família.';
COMMENT ON CONSTRAINT chk_tra_contagem ON tesouraria.transacao IS 'Só uma entrada em numerário pode ficar ligada a uma contagem.';
COMMENT ON CONSTRAINT chk_tra_despesa ON tesouraria.transacao IS 'Só uma saída pode pagar uma despesa.';
COMMENT ON CONSTRAINT chk_tra_quem_regista_nao_aprova ON tesouraria.transacao IS 'Quem regista o movimento não o pode aprovar; tem de ser outra pessoa.';
COMMENT ON CONSTRAINT chk_tra_transferencia ON tesouraria.transacao IS 'Uma transferência precisa da conta de destino, diferente da de origem.';
COMMENT ON CONSTRAINT chk_tra_valor ON tesouraria.transacao IS '[valorTotal] O valor tem de ser maior que zero.';

COMMENT ON INDEX tesouraria.uq_cat_codigo IS '[codigo] Já existe uma categoria com este código.';
COMMENT ON INDEX tesouraria.uq_cfi_igr_id_nome IS '[nome] Já existe uma conta com este nome nesta igreja.';
COMMENT ON INDEX tesouraria.uq_fpe_igr_id_ano_mes IS 'Este mês já foi fechado.';
COMMENT ON INDEX tesouraria.uq_fun_codigo IS '[codigo] Já existe um fundo com este código.';
COMMENT ON INDEX tesouraria.uq_orc IS 'Já existe um orçamento para este ano.';
COMMENT ON INDEX tesouraria.uq_orl_orc_id_cat_id IS '[categoriaId] Esta categoria já está no orçamento.';
COMMENT ON INDEX tesouraria.uq_rec_tra_id IS 'Este movimento já tem recibo.';
COMMENT ON INDEX tesouraria.uq_rem_preparada IS 'Já existe um depósito à Missão por enviar para este mês.';
COMMENT ON INDEX tesouraria.uq_rml_rem_id_fun_id IS '[fundoId] Este fundo já está neste depósito.';
COMMENT ON INDEX tesouraria.uq_ext_cfi_id_data_referencia_valor IS 'Esta linha do extracto já foi importada.';

-- ---------------------------------------------------------------- Secretaria
COMMENT ON CONSTRAINT chk_cto_dono ON secretaria.contacto IS 'O contacto tem de ser de um membro ou da igreja (não dos dois).';
COMMENT ON CONSTRAINT chk_dsc_duracao ON secretaria.disciplina IS '[dataFim] A censura dura de 1 dia a 12 meses: o fim tem de ser depois do início e até um ano depois.';
COMMENT ON CONSTRAINT chk_mem_encarregado ON secretaria.membro IS '[encarregadoMembroId] O membro não pode ser o seu próprio encarregado de educação.';
COMMENT ON CONSTRAINT chk_mmb_voto ON secretaria.movimento_membro IS '[votoId] Este movimento no livro de membros exige o voto que o autoriza.';
COMMENT ON CONSTRAINT chk_ofi_datas ON secretaria.oficial IS '[dataFim] O fim do mandato não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_ofi_fim_previsto ON secretaria.oficial IS '[fimPrevisto] O fim previsto do mandato não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_reu_meditacao ON secretaria.reuniao IS 'A meditação é de um membro ou de um convidado, não dos dois.';
COMMENT ON CONSTRAINT chk_rpt_contagens ON secretaria.reuniao_ponto IS 'Os votos a favor, contra e abstenções não podem ser negativos.';
COMMENT ON CONSTRAINT chk_rpt_votacao ON secretaria.reuniao_ponto IS 'Só um ponto votado pode ter votos a favor, contra ou abstenções.';
COMMENT ON CONSTRAINT chk_tme_carta ON secretaria.transferencia_membro IS 'A carta de transferência tem de ter a data e o voto em que foi emitida.';
COMMENT ON CONSTRAINT chk_tme_conclusao ON secretaria.transferencia_membro IS 'A transferência só se conclui depois de aceite pela igreja de destino.';
COMMENT ON CONSTRAINT chk_tme_destino ON secretaria.transferencia_membro IS 'Indique a igreja de destino (do sistema ou de fora).';
COMMENT ON CONSTRAINT chk_tme_diferente ON secretaria.transferencia_membro IS '[destinoIgrejaId] A igreja de destino tem de ser diferente da de origem.';
COMMENT ON CONSTRAINT chk_tme_validade ON secretaria.transferencia_membro IS 'A carta de transferência só é válida 6 meses: já não pode ser aceite.';
COMMENT ON CONSTRAINT chk_vot_leitura ON secretaria.voto IS '[leitura] A leitura do voto é a 1.ª ou a 2.ª.';

COMMENT ON INDEX secretaria.uq_bap_mem IS 'Este membro já tem o baptismo registado.';
COMMENT ON INDEX secretaria.uq_reu_igr_id_numero IS '[numero] Já existe uma reunião com este número.';
COMMENT ON INDEX secretaria.uq_rpr_reu_id_mem_id IS '[membroId] Este membro já está nas presenças desta reunião.';
COMMENT ON INDEX secretaria.uq_vot_reu_id_numero IS '[numero] Já existe um voto com este número nesta reunião.';

-- ---------------------------------------------------------------- Actividades, organização e núcleo
COMMENT ON CONSTRAINT chk_act_datas ON actividades.actividade IS '[dataFim] O fim da actividade não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_epl_datas ON actividades.escala_plano IS '[dataFim] O fim da escala não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_car_mandato ON organizacao.cargo IS '[mandatoAnos] O mandato do cargo é de 1 ou 2 anos.';
COMMENT ON CONSTRAINT chk_igr_mae ON organizacao.igreja IS '[maeIgrejaId] Um grupo ou filial precisa da igreja-mãe.';
COMMENT ON CONSTRAINT chk_igr_mandato ON organizacao.igreja IS '[mandatoAnos] A duração dos mandatos tem de estar entre 1 e 5 anos.';
COMMENT ON CONSTRAINT chk_per_ambito ON nucleo.perfil IS '[ambito] O âmbito do perfil é a igreja ou a Associação.';
COMMENT ON CONSTRAINT chk_usu_contacto ON nucleo.usuario IS 'O utilizador precisa de e-mail ou telefone para entrar.';

COMMENT ON INDEX actividades.uq_eds_epl_id_data IS '[data] Esta escala já tem este dia.';
COMMENT ON INDEX actividades.uq_esc_igr_id_data_funcao_mem_id IS 'Este membro já está escalado nesta função neste dia.';
COMMENT ON INDEX organizacao.uq_car_nome IS '[nome] Já existe um cargo com este nome.';
COMMENT ON INDEX organizacao.uq_dep_nome IS '[nome] Já existe um departamento com este nome.';
COMMENT ON INDEX organizacao.uq_dst_ent_id_nome IS '[nome] Já existe um distrito com este nome nesta Associação.';
COMMENT ON INDEX organizacao.uq_ide_igr_id_dep_id IS 'Este departamento já está nesta igreja.';
COMMENT ON INDEX nucleo.uq_per_nome IS '[nome] Já existe um perfil com este nome.';
COMMENT ON INDEX nucleo.uq_usu_email IS '[email] Já existe um utilizador com este e-mail.';
COMMENT ON INDEX nucleo.uq_usu_email_ci IS '[email] Já existe um utilizador com este e-mail.';
COMMENT ON INDEX nucleo.uq_usu_telefone IS '[telefone] Já existe um utilizador com este telefone.';
COMMENT ON INDEX nucleo.uq_usu_mem_id IS '[membroId] Este membro já tem uma conta de utilizador.';
COMMENT ON INDEX nucleo.uq_uig_usu_id_igr_id_per_id IS 'O utilizador já tem este perfil nesta igreja.';
COMMENT ON INDEX nucleo.uq_uen_usu_id_ent_id_per_id IS 'O utilizador já tem este perfil nesta Associação.';

-- >>>>> V30__painel_geral_das_igrejas.sql
-- V30 · Painel geral das igrejas (direcção: Associação/Missão, pastor do distrito, super-administrador)
--
-- Uma linha por igreja com os indicadores-chave (membros, transferências, dizimistas, situação financeira) e a série
-- dos últimos 12 meses, para comparar as igrejas. As vistas correm com os direitos de quem consulta
-- (security_invoker): cada utilizador só vê as igrejas a que tem acesso. O pastor do distrito tem o perfil PASTOR
-- em todas as igrejas do seu distrito (nucleo.fn_igrejas_com_permissao), por isso vê só essas; a Associação vê as
-- suas; o super-administrador, todas. Nada se calcula na API: a base de dados decide quem vê o quê.
--
-- Os números de cada área só contam onde o utilizador as pode ler; ve_membros e ve_tesouraria dizem se pode
-- (para o ecrã mostrar "sem acesso" em vez de zero).

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- indicadores por igreja
CREATE VIEW organizacao.vw_painel_igrejas WITH (security_invoker = true) AS
WITH ref AS (
    SELECT date_trunc('year',  now() AT TIME ZONE 'Africa/Maputo')::date AS ini_ano,
           date_trunc('month', now() AT TIME ZONE 'Africa/Maputo')::date AS ini_mes
),
acesso AS (
    SELECT (SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'))   AS membros,
           (SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler')) AS tesouraria
),
membros AS (
    SELECT m.mem_igr_id AS igr_id,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO')                       AS activos,
           COUNT(*) FILTER (WHERE m.mem_estado = 'INTERESSADO')                  AS interessados,
           COUNT(*) FILTER (WHERE m.mem_estado = 'TRANSFERIDO')                  AS transferidos,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'F')  AS mulheres,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'M')  AS homens
    FROM secretaria.membro m
    WHERE m.mem_end_date IS NULL
    GROUP BY 1
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA')                    AS transf_entrada_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')                      AS transf_saida_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS outras_saidas_ano
    FROM secretaria.movimento_membro l, ref
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= ref.ini_ano
    GROUP BY 1
),
pendentes AS (
    SELECT t.tme_origem_igr_id AS igr_id, COUNT(*) AS transf_pendentes
    FROM secretaria.transferencia_membro t
    WHERE t.tme_end_date IS NULL AND t.tme_estado IN ('PEDIDA', 'CARTA_EMITIDA')
    GROUP BY 1
),
-- dinheiro da igreja: entradas e saídas confirmadas nas contas da igreja (não a conta da Missão)
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA' AND t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS entradas_mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA'   AND t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS saidas_mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas_ano,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas_ano
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, ref
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA')
      AND t.tra_data_hora >= (ref.ini_ano::timestamp AT TIME ZONE 'Africa/Maputo')
    GROUP BY 1
),
-- dizimistas: membros (e famílias) com dízimo confirmado este ano, também os pagos directamente na Missão
dizimo AS (
    SELECT t.tra_igr_id AS igr_id,
           COUNT(DISTINCT t.tra_mem_id) AS dizimistas,
           COUNT(DISTINCT t.tra_fam_id) AS familias_dizimistas,
           SUM(l.tli_valor) AS dizimos_ano,
           SUM(l.tli_valor) FILTER (WHERE t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS dizimos_mes
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo = 'DIZIMO', ref
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= (ref.ini_ano::timestamp AT TIME ZONE 'Africa/Maputo')
    GROUP BY 1
),
saldo AS (
    SELECT s.cfi_igr_id AS igr_id, SUM(s.saldo) AS saldo
    FROM tesouraria.vw_saldo_conta s
    WHERE s.entidade_id IS NULL
    GROUP BY 1
),
-- o que falta depositar na conta da Missão, dos meses já terminados
remeter AS (
    SELECT d.igr_id, SUM(GREATEST(d.em_falta, 0)) AS por_remeter
    FROM tesouraria.vw_remessa_devida d, ref
    WHERE make_date(d.ano, d.mes, 1) < ref.ini_mes
    GROUP BY 1
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_tipo AS tipo, i.igr_ent_id AS entidade_id, e.ent_nome AS entidade,
       i.igr_dst_id AS distrito_pastoral_id, d.dst_nome AS distrito_pastoral, p.prv_nome AS provincia,
       (i.igr_id = ANY (a.membros))    AS ve_membros,
       (i.igr_id = ANY (a.tesouraria)) AS ve_tesouraria,
       COALESCE(m.activos, 0)       AS membros_activos,
       COALESCE(m.interessados, 0)  AS interessados,
       COALESCE(m.mulheres, 0)      AS mulheres,
       COALESCE(m.homens, 0)        AS homens,
       COALESCE(m.transferidos, 0)  AS transferidos,
       COALESCE(l.transf_saida_ano, 0)   AS transf_saida_ano,
       COALESCE(l.transf_entrada_ano, 0) AS transf_entrada_ano,
       COALESCE(pd.transf_pendentes, 0)  AS transf_pendentes,
       COALESCE(l.admissoes_ano, 0)      AS admissoes_ano,
       COALESCE(l.outras_saidas_ano, 0)  AS outras_saidas_ano,
       COALESCE(z.dizimistas, 0)          AS dizimistas,
       COALESCE(z.familias_dizimistas, 0) AS familias_dizimistas,
       ROUND(COALESCE(z.dizimistas, 0)::NUMERIC / NULLIF(m.activos, 0), 4) AS pct_dizimistas,
       COALESCE(z.dizimos_ano, 0) AS dizimos_ano,
       COALESCE(z.dizimos_mes, 0) AS dizimos_mes,
       COALESCE(dn.entradas_mes, 0) AS entradas_mes,
       COALESCE(dn.saidas_mes, 0)   AS saidas_mes,
       COALESCE(dn.entradas_ano, 0) AS entradas_ano,
       COALESCE(dn.saidas_ano, 0)   AS saidas_ano,
       COALESCE(dn.entradas_ano, 0) - COALESCE(dn.saidas_ano, 0) AS resultado_ano,
       COALESCE(s.saldo, 0)         AS saldo,
       COALESCE(r.por_remeter, 0)   AS por_remeter
FROM organizacao.igreja i
CROSS JOIN acesso a
JOIN organizacao.entidade e          ON e.ent_id = i.igr_ent_id
LEFT JOIN organizacao.distrito d     ON d.dst_id = i.igr_dst_id
LEFT JOIN organizacao.provincia p    ON p.prv_id = i.igr_prv_id
LEFT JOIN membros m   ON m.igr_id = i.igr_id
LEFT JOIN livro l     ON l.igr_id = i.igr_id
LEFT JOIN pendentes pd ON pd.igr_id = i.igr_id
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id
LEFT JOIN dizimo z    ON z.igr_id = i.igr_id
LEFT JOIN saldo s     ON s.igr_id = i.igr_id
LEFT JOIN remeter r   ON r.igr_id = i.igr_id
WHERE i.igr_end_date IS NULL;
COMMENT ON VIEW organizacao.vw_painel_igrejas IS
    'Painel geral: por igreja visível ao utilizador, membros, transferências, dizimistas e situação financeira do ano (V30)';
GRANT SELECT ON organizacao.vw_painel_igrejas TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses por igreja (gráficos)
CREATE VIEW organizacao.vw_painel_igrejas_mensal WITH (security_invoker = true) AS
WITH meses AS (
    SELECT g::date AS ini, (g + INTERVAL '1 month')::date AS fim,
           EXTRACT(YEAR FROM g)::INT AS ano, EXTRACT(MONTH FROM g)::INT AS mes
    FROM generate_series(date_trunc('month', now() AT TIME ZONE 'Africa/Maputo') - INTERVAL '11 months',
                         date_trunc('month', now() AT TIME ZONE 'Africa/Maputo'), INTERVAL '1 month') g
),
desde AS (SELECT (MIN(ini)::timestamp AT TIME ZONE 'Africa/Maputo') AS t, MIN(ini) AS d FROM meses),
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
dizimo AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(l.tli_valor) AS dizimos, COUNT(DISTINCT t.tra_mem_id) AS dizimistas
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo = 'DIZIMO', desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id, EXTRACT(YEAR FROM l.mmb_data)::INT AS ano, EXTRACT(MONTH FROM l.mmb_data)::INT AS mes,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transf_entrada,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transf_saida
    FROM secretaria.movimento_membro l, desde
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= desde.d
    GROUP BY 1, 2, 3
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id, ms.ano, ms.mes,
       COALESCE(dn.entradas, 0) AS entradas, COALESCE(dn.saidas, 0) AS saidas,
       COALESCE(z.dizimos, 0) AS dizimos, COALESCE(z.dizimistas, 0) AS dizimistas,
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN dizimo z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;
COMMENT ON VIEW organizacao.vw_painel_igrejas_mensal IS
    'Painel geral: últimos 12 meses por igreja visível (entradas, saídas, dízimos, dizimistas, admissões, transferências) (V30)';
GRANT SELECT ON organizacao.vw_painel_igrejas_mensal TO app_igreja;

-- >>>>> V31__mandatos_conselho_e_direccao.sql
-- V31 · Mandatos, conselho e direcção
--
-- Um mandato é o período (com a duração) em que servem os oficiais eleitos; dentro dele, cada oficial pertence a um
-- órgão: CONSELHO (conselho da igreja / junta directiva) ou DIRECCAO (direcção e departamentos).
--   Mandato 2026–2027 ─┬─ Conselho da igreja: anciãos, secretário, tesoureiro, ...
--                      └─ Direcção: directores de departamento, ...
-- Regras (na base de dados):
--   * mandatos da mesma igreja não se sobrepõem; o fim é depois do início;
--   * o oficial de um mandato é da mesma igreja; o início e o fim previsto vêm do mandato (se não se indicarem);
--   * o órgão, se não se indicar, vem do cargo (cargo do conselho → CONSELHO; os outros → DIRECCAO);
--   * mudar as datas do mandato actualiza o fim previsto dos oficiais que ainda o seguem.
-- Os oficiais que já existiam ficam num mandato criado para o seu período (um por período distinto em cada igreja).

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- tabela secretaria.mandato (gerada: gen.py)
CREATE TABLE secretaria.mandato (
    mdt_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mdt_igr_id INT NOT NULL,
    mdt_nome VARCHAR(100) NOT NULL,
    mdt_data_inicio DATE NOT NULL,
    mdt_data_fim DATE NOT NULL,
    mdt_vot_id INT,
    mdt_observacoes VARCHAR(255),
    mdt_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    mdt_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mdt_criado_por INT,
    mdt_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    mdt_modificado_por INT,
    mdt_end_date TIMESTAMPTZ,
    CONSTRAINT fk_mdt_igr_id FOREIGN KEY (mdt_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_mdt_vot_id FOREIGN KEY (mdt_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT chk_mdt_datas CHECK (mdt_data_fim > mdt_data_inicio),
    CONSTRAINT chk_mdt_end_date CHECK (mdt_end_date IS NULL OR mdt_end_date >= mdt_criado_em)
);
COMMENT ON TABLE secretaria.mandato IS 'Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos (V31)';
COMMENT ON COLUMN secretaria.mandato.mdt_nome IS 'Ex.: Mandato 2026–2027';
COMMENT ON COLUMN secretaria.mandato.mdt_data_fim IS 'Último dia do mandato';
COMMENT ON COLUMN secretaria.mandato.mdt_vot_id IS 'Voto da igreja que elegeu os oficiais deste mandato';
CREATE UNIQUE INDEX uq_mdt_igr_id_nome ON secretaria.mandato (mdt_igr_id, mdt_nome) WHERE mdt_end_date IS NULL;
CREATE INDEX idx_mdt_vot_id ON secretaria.mandato (mdt_vot_id);
CREATE INDEX idx_mdt_igr_pagina ON secretaria.mandato (mdt_igr_id, mdt_id);

CREATE TRIGGER trg_mdt_00_padrao BEFORE INSERT OR UPDATE ON secretaria.mandato FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mdt', 'secretaria.mandato', 'mdt_igr_id');
CREATE TRIGGER trg_mdt_00_sem_delete BEFORE DELETE ON secretaria.mandato FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mdt');
CREATE TRIGGER trg_mdt_00_sem_truncate BEFORE TRUNCATE ON secretaria.mandato FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mdt');
CREATE TRIGGER trg_mdt_99_log AFTER UPDATE ON secretaria.mandato FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mdt');
ALTER TABLE secretaria.mandato ADD CONSTRAINT fk_mdt_criado_por FOREIGN KEY (mdt_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.mandato ADD CONSTRAINT fk_mdt_modificado_por FOREIGN KEY (mdt_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE secretaria.mandato ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_mdt_ler ON secretaria.mandato FOR SELECT USING (mdt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.mandato.ler'))::INT[]));
CREATE POLICY pol_mdt_criar ON secretaria.mandato FOR INSERT WITH CHECK (mdt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.mandato.criar'))::INT[]));
CREATE POLICY pol_mdt_alterar ON secretaria.mandato FOR UPDATE USING (mdt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.mandato.alterar'))::INT[])) WITH CHECK (mdt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.mandato.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON secretaria.mandato TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA secretaria TO app_igreja;

-- ---------------------------------------------------------------- oficial: mandato e órgão
ALTER TABLE secretaria.oficial ADD COLUMN ofi_mdt_id INT;
ALTER TABLE secretaria.oficial ADD COLUMN ofi_orgao VARCHAR(10);
ALTER TABLE secretaria.oficial ADD CONSTRAINT fk_ofi_mdt_id FOREIGN KEY (ofi_mdt_id) REFERENCES secretaria.mandato(mdt_id);
ALTER TABLE secretaria.oficial ADD CONSTRAINT chk_ofi_orgao CHECK (ofi_orgao IS NULL OR ofi_orgao IN ('CONSELHO', 'DIRECCAO'));
CREATE INDEX idx_ofi_mdt_id ON secretaria.oficial (ofi_mdt_id);
COMMENT ON COLUMN secretaria.oficial.ofi_mdt_id IS 'Mandato a que pertence (V31): dá o início e o fim previsto';
COMMENT ON COLUMN secretaria.oficial.ofi_orgao IS 'CONSELHO (conselho da igreja) ou DIRECCAO (direcção / departamentos); vazio = pelo cargo (V31)';

-- frases das restrições novas (V29: a API responde com elas)
COMMENT ON CONSTRAINT chk_mdt_datas ON secretaria.mandato IS '[dataFim] O fim do mandato tem de ser depois do início.';
COMMENT ON CONSTRAINT chk_ofi_orgao ON secretaria.oficial IS '[orgao] O órgão é o Conselho da igreja ou a Direcção.';
COMMENT ON INDEX secretaria.uq_mdt_igr_id_nome IS '[nome] Já existe um mandato com este nome nesta igreja.';

-- ---------------------------------------------------------------- permissões (os mesmos perfis que gerem os oficiais)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('secretaria.mandato.ler', 'Ler: Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos'),
  ('secretaria.mandato.criar', 'Criar: Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos'),
  ('secretaria.mandato.alterar', 'Alterar: Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos'),
  ('secretaria.mandato.terminar', 'Terminar (end_date): Mandatos da igreja: o período (com a duração) em que servem os oficiais eleitos');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'secretaria.oficial.%'
  JOIN nucleo.permissao novo   ON novo.prm_codigo = replace(antigo.prm_codigo, 'secretaria.oficial.', 'secretaria.mandato.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- oficiais que já existiam: órgão pelo cargo e um mandato por período
UPDATE secretaria.oficial o SET ofi_orgao = CASE WHEN c.car_conselho THEN 'CONSELHO' ELSE 'DIRECCAO' END
  FROM organizacao.cargo c WHERE c.car_id = o.ofi_car_id AND o.ofi_orgao IS NULL;

WITH periodos AS (
    SELECT DISTINCT o.ofi_igr_id AS igr, o.ofi_data_inicio AS ini,
           COALESCE(o.ofi_fim_previsto, o.ofi_data_fim, (o.ofi_data_inicio + INTERVAL '1 year' - INTERVAL '1 day')::date) AS fim
      FROM secretaria.oficial o
     WHERE o.ofi_end_date IS NULL AND o.ofi_mdt_id IS NULL
)
INSERT INTO secretaria.mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim)
SELECT igr,
       CASE WHEN to_char(ini, 'MM-DD') = '01-01' AND to_char(fim, 'MM-DD') = '12-31'
            THEN 'Mandato ' || to_char(ini, 'YYYY') || CASE WHEN to_char(fim, 'YYYY') <> to_char(ini, 'YYYY') THEN '–' || to_char(fim, 'YYYY') ELSE '' END
            ELSE 'Mandato de ' || to_char(ini, 'DD/MM/YYYY') || ' a ' || to_char(fim, 'DD/MM/YYYY') END,
       ini, GREATEST(fim, ini + 1)
  FROM periodos;

UPDATE secretaria.oficial o SET ofi_mdt_id = m.mdt_id
  FROM secretaria.mandato m
 WHERE o.ofi_end_date IS NULL AND o.ofi_mdt_id IS NULL AND m.mdt_igr_id = o.ofi_igr_id AND m.mdt_data_inicio = o.ofi_data_inicio
   AND m.mdt_data_fim = GREATEST(COALESCE(o.ofi_fim_previsto, o.ofi_data_fim, (o.ofi_data_inicio + INTERVAL '1 year' - INTERVAL '1 day')::date), o.ofi_data_inicio + 1);

-- ---------------------------------------------------------------- regras
-- Mandato: os da mesma igreja não se sobrepõem (só os activos)
CREATE FUNCTION secretaria.fn_mdt_validar() RETURNS trigger AS $$
DECLARE v_outro TEXT;
BEGIN
    -- datas ao contrário: fica para a CHECK chk_mdt_datas (com a sua frase)
    IF NEW.mdt_end_date IS NULL AND NEW.mdt_data_fim > NEW.mdt_data_inicio THEN
        SELECT mdt_nome INTO v_outro FROM secretaria.mandato
         WHERE mdt_igr_id = NEW.mdt_igr_id AND mdt_id <> NEW.mdt_id AND mdt_end_date IS NULL
           AND daterange(mdt_data_inicio, mdt_data_fim, '[]') && daterange(NEW.mdt_data_inicio, NEW.mdt_data_fim, '[]')
         LIMIT 1;
        IF FOUND THEN
            RAISE EXCEPTION 'O mandato coincide com o "%"; os mandatos da mesma igreja não se sobrepõem', v_outro;
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mdt_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.mandato
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mdt_validar();

-- Mudar as datas do mandato: os oficiais que seguiam o mandato acompanham-no (início e fim previsto)
CREATE FUNCTION secretaria.fn_mdt_propagar() RETURNS trigger AS $$
BEGIN
    UPDATE secretaria.oficial
       SET ofi_fim_previsto = CASE WHEN ofi_fim_previsto = OLD.mdt_data_fim THEN NEW.mdt_data_fim ELSE ofi_fim_previsto END,
           ofi_data_inicio  = CASE WHEN ofi_data_inicio = OLD.mdt_data_inicio THEN NEW.mdt_data_inicio ELSE ofi_data_inicio END
     WHERE ofi_mdt_id = NEW.mdt_id AND ofi_end_date IS NULL AND ofi_data_fim IS NULL;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mdt_20_propagar
    AFTER UPDATE OF mdt_data_inicio, mdt_data_fim ON secretaria.mandato
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mdt_propagar();

-- Oficial: o mandato é da mesma igreja e dá o início e o fim previsto; o órgão vem do cargo se não se indicar.
-- Corre antes de trg_ofi_05_fim_previsto (que só calcula pela duração da igreja quando não há fim previsto).
CREATE FUNCTION secretaria.fn_ofi_mandato() RETURNS trigger AS $$
DECLARE m RECORD;
BEGIN
    IF NEW.ofi_mdt_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.ofi_mdt_id IS DISTINCT FROM OLD.ofi_mdt_id) THEN
        SELECT mdt_igr_id, mdt_data_inicio, mdt_data_fim, mdt_end_date INTO m FROM secretaria.mandato WHERE mdt_id = NEW.ofi_mdt_id;
        IF NOT FOUND OR m.mdt_end_date IS NOT NULL THEN
            RAISE EXCEPTION 'O mandato indicado não existe ou foi terminado';
        END IF;
        IF m.mdt_igr_id <> NEW.ofi_igr_id THEN
            RAISE EXCEPTION 'O mandato é de outra igreja';
        END IF;
        NEW.ofi_data_inicio := COALESCE(NEW.ofi_data_inicio, m.mdt_data_inicio);
        IF NEW.ofi_fim_previsto IS NULL OR TG_OP = 'UPDATE' THEN
            NEW.ofi_fim_previsto := GREATEST(m.mdt_data_fim, NEW.ofi_data_inicio);
        END IF;
    END IF;
    IF NEW.ofi_orgao IS NULL THEN
        SELECT CASE WHEN car_conselho THEN 'CONSELHO' ELSE 'DIRECCAO' END INTO NEW.ofi_orgao
          FROM organizacao.cargo WHERE car_id = NEW.ofi_car_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ofi_04_mandato
    BEFORE INSERT OR UPDATE ON secretaria.oficial
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_ofi_mandato();

-- ---------------------------------------------------------------- vistas
-- Conselho e direcção: as colunas de antes e, no fim, o mandato e o órgão
CREATE OR REPLACE VIEW secretaria.vw_conselho WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, o.ofi_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       c.car_id AS cargo_id, c.car_nome AS cargo, c.car_conselho AS do_conselho,
       o.ofi_data_inicio, o.ofi_fim_previsto, o.ofi_data_fim,
       (SELECT ct.cto_valor FROM secretaria.contacto ct
         WHERE ct.cto_mem_id = o.ofi_mem_id AND ct.cto_end_date IS NULL
         ORDER BY ct.cto_principal DESC, (ct.cto_tipo = 'TELEFONE') DESC, ct.cto_id LIMIT 1) AS contacto,
       CASE WHEN o.ofi_data_inicio > CURRENT_DATE THEN 'FUTURO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE THEN 'TERMINADO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE + 60 THEN 'A_TERMINAR'
            ELSE 'ACTIVO' END AS estado_mandato,
       o.ofi_mdt_id AS mandato_id, md.mdt_nome AS mandato, COALESCE(o.ofi_orgao, CASE WHEN c.car_conselho THEN 'CONSELHO' ELSE 'DIRECCAO' END) AS orgao
FROM secretaria.oficial o
JOIN organizacao.cargo c   ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m   ON m.mem_id = o.ofi_mem_id
LEFT JOIN secretaria.mandato md ON md.mdt_id = o.ofi_mdt_id
WHERE o.ofi_end_date IS NULL;

-- >>>>> V32__codigos_fixos_e_super_admin.sql
-- =====================================================================
-- V32 · Códigos fixos em vez de nomes, e permissões do super-administrador intocáveis
--
--   1. Perfis: código fixo (per_codigo). O acesso do pastor do distrito dependia do NOME do perfil
--      (per_nome = 'PASTOR', em nucleo.fn_igrejas_com_permissao, chamada em todas as verificações de permissão):
--      mudar o nome do perfil tirava o acesso aos pastores sem qualquer erro. Agora depende do código, que não muda.
--      O nome passa a ser só o texto mostrado. Os perfis do sistema (com código) não se terminam nem mudam de âmbito.
--   2. Códigos das categorias e das permissões não se alteram depois de criados. As regras e a API identificam
--      categorias pelo código (D1 remessas, D9 outras despesas, R3 ofertas da Escola Sabatina) e as permissões pelo
--      código (secretaria.membro.ler, ...): o código é o identificador estável; o nome/descrição pode mudar.
--   3. Super-administrador: as suas permissões não se alteram pelo sistema. Ninguém (nem outro super-administrador,
--      nem o próprio) lhe retira o acesso total, o inactiva ou o termina. Só a manutenção da base (sem utilizador
--      na sessão, como dono das tabelas) o pode fazer, por exemplo quando a pessoa sai da organização.
--
-- Nota sobre os ENUM (tra_tipo = 'ENTRADA', mmb_tipo = 'BAPTISMO', ...): não são pesquisas por nome. Cada linha guarda
-- o identificador interno do valor (4 bytes) e a comparação é tão rápida como entre inteiros; não mudam aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- 1. código fixo dos perfis (gerado: gen.py)
ALTER TABLE nucleo.perfil ADD COLUMN per_codigo VARCHAR(30);
COMMENT ON COLUMN nucleo.perfil.per_codigo IS 'Código fixo dos perfis do sistema (ADMIN, PASTOR, ...): não muda, ao contrário do nome; vazio nos perfis criados pelos utilizadores (V32)';
CREATE UNIQUE INDEX uq_per_codigo ON nucleo.perfil (per_codigo) WHERE per_end_date IS NULL;
COMMENT ON INDEX nucleo.uq_per_codigo IS '[codigo] Já existe um perfil com este código.';

-- os 13 perfis do sistema: o código é o nome que tinham (carga única)
UPDATE nucleo.perfil SET per_codigo = per_nome
 WHERE per_end_date IS NULL
   AND per_nome IN ('ADMIN', 'PASTOR', 'ANCIAO', 'SECRETARIO', 'TESOUREIRO', 'DIRECTOR_ES', 'SECRETARIO_ES',
                    'DIRECTOR_DEPARTAMENTO', 'MEMBRO', 'ADMIN_ASSOCIACAO', 'TESOUREIRO_ASSOCIACAO',
                    'SECRETARIO_ASSOCIACAO', 'INTEGRACAO');

CREATE FUNCTION nucleo.fn_per_proteger() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.per_codigo IS NOT NULL AND nucleo.fn_usuario_sessao() IS NOT NULL THEN
            RAISE EXCEPTION 'O código de um perfil do sistema só é definido pelo sistema (deixe o código vazio)';
        END IF;
        RETURN NEW;
    END IF;
    IF NEW.per_codigo IS DISTINCT FROM OLD.per_codigo THEN
        RAISE EXCEPTION 'O código de um perfil não se altera';
    END IF;
    IF OLD.per_codigo IS NOT NULL AND nucleo.fn_usuario_sessao() IS NOT NULL THEN
        IF NEW.per_end_date IS NOT NULL AND OLD.per_end_date IS NULL THEN
            RAISE EXCEPTION 'Os perfis do sistema não se terminam';
        END IF;
        IF NEW.per_ambito IS DISTINCT FROM OLD.per_ambito THEN
            RAISE EXCEPTION 'O âmbito de um perfil do sistema não se altera';
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_per_10_proteger BEFORE INSERT OR UPDATE ON nucleo.perfil
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_per_proteger();

-- igual à de V1, com uma diferença: o pastor do distrito reconhece-se pelo código do perfil, não pelo nome
CREATE OR REPLACE FUNCTION nucleo.fn_igrejas_com_permissao(p_codigo TEXT) RETURNS INT[]
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN RETURN ARRAY[]::INT[]; END IF;
    IF nucleo.fn_e_super_admin() THEN
        RETURN ARRAY(SELECT igr_id FROM organizacao.igreja WHERE igr_end_date IS NULL);
    END IF;
    RETURN ARRAY(
        WITH perm AS (
            SELECT pp.ppe_per_id AS per_id
            FROM nucleo.permissao pm
            JOIN nucleo.perfil_permissao pp ON pp.ppe_prm_id = pm.prm_id AND pp.ppe_end_date IS NULL
            WHERE pm.prm_codigo = p_codigo AND pm.prm_end_date IS NULL
        )
        SELECT u.uig_igr_id
          FROM nucleo.usuario_igreja u JOIN perm ON perm.per_id = u.uig_per_id
         WHERE u.uig_usu_id = v_usr AND u.uig_estado = 'ACTIVO' AND u.uig_end_date IS NULL
        UNION
        SELECT i.igr_id
          FROM organizacao.distrito d
          JOIN organizacao.igreja i ON i.igr_dst_id = d.dst_id AND i.igr_end_date IS NULL
         WHERE d.dst_pastor_usu_id = v_usr AND d.dst_end_date IS NULL
           AND EXISTS (SELECT 1 FROM nucleo.perfil pf JOIN perm ON perm.per_id = pf.per_id
                        WHERE pf.per_codigo = 'PASTOR' AND pf.per_end_date IS NULL)
        UNION
        SELECT i.igr_id
          FROM nucleo.fn_entidades_com_permissao(p_codigo) e
          JOIN organizacao.igreja i ON i.igr_ent_id = e AND i.igr_end_date IS NULL);
END $$;

-- ---------------------------------------------------------------- 2. códigos de categorias e permissões
CREATE FUNCTION nucleo.fn_codigo_imutavel() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_coluna TEXT := TG_ARGV[0];
BEGIN
    IF (to_jsonb(NEW) ->> v_coluna) IS DISTINCT FROM (to_jsonb(OLD) ->> v_coluna) THEN
        RAISE EXCEPTION 'O código não se altera depois de criado (é o identificador usado pelas regras): termine este registo e crie outro';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_cat_10_codigo_fixo BEFORE UPDATE OF cat_codigo ON tesouraria.categoria
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_codigo_imutavel('cat_codigo');
CREATE TRIGGER trg_prm_10_codigo_fixo BEFORE UPDATE OF prm_codigo ON nucleo.permissao
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_codigo_imutavel('prm_codigo');

-- ---------------------------------------------------------------- 3. super-administrador
-- igual à de V2, com uma regra nova no início das alterações: o super-administrador fica como está
CREATE OR REPLACE FUNCTION nucleo.fn_usu_proteger() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');      -- só passa na instalação/manutenção
        RETURN NEW;
    END IF;
    IF NEW.usu_super_admin AND (TG_OP = 'INSERT' OR NOT OLD.usu_super_admin) AND NOT nucleo.fn_e_super_admin() THEN
        RAISE EXCEPTION 'Só um super-administrador pode criar outro';
    END IF;
    IF TG_OP = 'INSERT' THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');
        RETURN NEW;
    END IF;
    -- V32: as permissões do super-administrador não se alteram (nem pelo próprio, nem por outro super-administrador)
    IF OLD.usu_super_admin AND (NEW.usu_super_admin IS DISTINCT FROM OLD.usu_super_admin
                                OR NEW.usu_estado IS DISTINCT FROM OLD.usu_estado
                                OR (NEW.usu_end_date IS NOT NULL AND OLD.usu_end_date IS NULL)) THEN
        RAISE EXCEPTION 'As permissões do super-administrador não podem ser alteradas (nem o acesso total, nem o estado)'
            USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF OLD.usu_id = v_usr THEN
        -- a própria pessoa muda nome, contactos e senha, mas não o estado nem a ligação ao membro
        IF (NEW.usu_estado, NEW.usu_mem_id, NEW.usu_super_admin) IS DISTINCT FROM (OLD.usu_estado, OLD.usu_mem_id, OLD.usu_super_admin)
           AND NOT nucleo.fn_e_super_admin() THEN
            RAISE EXCEPTION 'Não pode alterar o seu próprio estado, membro ou nível de acesso';
        END IF;
        RETURN NEW;
    END IF;
    PERFORM nucleo.fn_exigir('nucleo.usuario.alterar');
    IF NOT nucleo.fn_e_super_admin() THEN
        IF OLD.usu_super_admin THEN
            RAISE EXCEPTION 'Só um super-administrador altera outro super-administrador';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_igreja u
                   WHERE u.uig_usu_id = OLD.usu_id AND u.uig_end_date IS NULL
                     AND NOT nucleo.fn_tem_permissao('nucleo.usuario.alterar', u.uig_igr_id)) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis em igrejas que não administra';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_entidade e
                   WHERE e.uen_usu_id = OLD.usu_id AND e.uen_end_date IS NULL
                     AND e.uen_ent_id NOT IN (SELECT nucleo.fn_entidades_com_permissao('nucleo.usuario.alterar'))) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis numa Associação/Missão que não administra';
        END IF;
    END IF;
    RETURN NEW;
END $$;

-- >>>>> V33__ficha_do_membro_conjuge_e_duplicados.sql
-- =====================================================================
-- V33 · Ficha completa do membro (F-SEC-01): cônjuge ligado, casamento, trabalho, endereço postal,
--       conversão, ex-membro, telefone fixo e aviso de registos parecidos (possíveis duplicados)
--
--   membro     colunas novas, todas opcionais (ex_membro tem FALSE por defeito): os registos existentes
--              não mudam. O baptismo anterior de um ex-membro é uma linha de secretaria.baptismo sem
--              rebaptismo (o baptismo actual fica como rebaptismo): não há coluna nova para ele.
--   cônjuge    mem_conjuge_mem_id liga dois registos de membros (não se cria outro registo para o cônjuge).
--              A ligação é recíproca: ao ligar A → B, B fica ligado a A (se B estiver livre); ao desligar,
--              desliga-se dos dois lados. Um membro já ligado a outro cônjuge não pode ser escolhido.
--   contacto   novo tipo TELEFONE_FIXO. TELEFONE continua a ser o telemóvel (celular), o único que recebe SMS.
--   parecidos  nucleo.fn_membros_parecidos(...): membros visíveis com o mesmo documento, ou nome parecido e a
--              mesma data de nascimento / local de nascimento. Só avisa (a API devolve a lista e o
--              utilizador confirma); não bloqueia o registo.
--   vistas     vw_membro_basico ganha estado civil, data de nascimento e cônjuge (indicadores e escolha do
--              cônjuge); vw_membros_lista é a lista para exportar (CSV/PDF).
--
-- Permissões: não mudam. Quem lê ou altera o membro (RLS por igreja) lê ou altera estes campos.
-- Gerado com database/gerador (defs.py, sql/V1__base.sql); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TYPE nucleo.tipo_contacto_t ADD VALUE IF NOT EXISTS 'TELEFONE_FIXO';

-- ---------------------------------------------------------------- membro
ALTER TABLE secretaria.membro
    ADD COLUMN mem_outro_documento VARCHAR(100),
    ADD COLUMN mem_ex_membro BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN mem_endereco_postal VARCHAR(150),
    ADD COLUMN mem_codigo_postal VARCHAR(20),
    ADD COLUMN mem_local_trabalho VARCHAR(150),
    ADD COLUMN mem_data_casamento DATE,
    ADD COLUMN mem_conjuge_mem_id INT,
    ADD COLUMN mem_nome_conjuge VARCHAR(150),
    ADD COLUMN mem_dependentes SMALLINT,
    ADD COLUMN mem_religiao_anterior VARCHAR(100),
    ADD COLUMN mem_metodo_conversao VARCHAR(100),
    ADD CONSTRAINT fk_mem_conjuge_mem_id FOREIGN KEY (mem_conjuge_mem_id) REFERENCES secretaria.membro(mem_id),
    ADD CONSTRAINT chk_mem_conjuge CHECK (mem_conjuge_mem_id IS NULL OR mem_conjuge_mem_id <> mem_id),
    ADD CONSTRAINT chk_mem_dependentes CHECK (mem_dependentes IS NULL OR mem_dependentes BETWEEN 0 AND 50),
    ADD CONSTRAINT chk_mem_casamento CHECK (mem_data_casamento IS NULL OR mem_data_nascimento IS NULL OR mem_data_casamento > mem_data_nascimento);

COMMENT ON COLUMN secretaria.membro.mem_outro_documento IS 'Outro documento além do principal (tipo e número, ex.: NUIT 400123456)';
COMMENT ON COLUMN secretaria.membro.mem_ex_membro IS 'Já foi membro da IASD (o baptismo anterior fica em baptismo, sem rebaptismo) (V33)';
COMMENT ON COLUMN secretaria.membro.mem_endereco_postal IS 'Endereço para correspondência (caixa postal, rua)';
COMMENT ON COLUMN secretaria.membro.mem_local_trabalho IS 'Onde trabalha (empresa ou instituição)';
COMMENT ON COLUMN secretaria.membro.mem_conjuge_mem_id IS 'Cônjuge que é membro (no sistema): liga os dois registos, sem criar outro (V33)';
COMMENT ON COLUMN secretaria.membro.mem_nome_conjuge IS 'Nome do cônjuge que não está no sistema';
COMMENT ON COLUMN secretaria.membro.mem_dependentes IS 'Número de dependentes a cargo';
COMMENT ON COLUMN secretaria.membro.mem_metodo_conversao IS 'Como conheceu a mensagem (estudo bíblico, evangelismo, família, rádio/TV, ...)';

COMMENT ON CONSTRAINT chk_mem_conjuge ON secretaria.membro IS '[conjugeMembroId] O membro não pode ser o seu próprio cônjuge.';
COMMENT ON CONSTRAINT chk_mem_dependentes ON secretaria.membro IS '[dependentes] O número de dependentes tem de estar entre 0 e 50.';
COMMENT ON CONSTRAINT chk_mem_casamento ON secretaria.membro IS '[dataCasamento] A data do casamento tem de ser depois da data de nascimento.';

CREATE INDEX idx_mem_conjuge_mem_id ON secretaria.membro (mem_conjuge_mem_id);
-- procura de registos parecidos: pelo documento (sem espaços nem traços) e pela data de nascimento
CREATE INDEX idx_mem_documento ON secretaria.membro (upper(regexp_replace(mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')))
    WHERE mem_numero_identificacao IS NOT NULL AND mem_end_date IS NULL;
CREATE INDEX idx_mem_nascimento ON secretaria.membro (mem_data_nascimento)
    WHERE mem_data_nascimento IS NOT NULL AND mem_end_date IS NULL;

-- ---------------------------------------------------------------- cônjuge: escolha válida e ligação recíproca
CREATE FUNCTION secretaria.fn_mem_conjuge_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_outro INT;
    v_nome  TEXT;
BEGIN
    IF NEW.mem_conjuge_mem_id IS NULL
       OR (TG_OP = 'UPDATE' AND NEW.mem_conjuge_mem_id IS NOT DISTINCT FROM OLD.mem_conjuge_mem_id) THEN
        RETURN NEW;
    END IF;
    SELECT mem_conjuge_mem_id, mem_nome || ' ' || mem_apelido INTO v_outro, v_nome
      FROM secretaria.membro WHERE mem_id = NEW.mem_conjuge_mem_id;
    IF v_outro IS NOT NULL AND v_outro <> NEW.mem_id THEN
        RAISE EXCEPTION '% já está ligado(a) a outro cônjuge. Desligue primeiro esse registo.', v_nome
            USING COLUMN = 'mem_conjuge_mem_id';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_mem_15_conjuge
    BEFORE INSERT OR UPDATE OF mem_conjuge_mem_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_conjuge_validar();

-- Liga (ou desliga) o outro lado. Corre com as permissões de quem altera: se não puder ver ou alterar o
-- registo do cônjuge (outra igreja), esse lado fica como estava.
CREATE FUNCTION secretaria.fn_mem_conjuge_reciproco() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.mem_conjuge_mem_id IS NOT NULL
       AND OLD.mem_conjuge_mem_id IS DISTINCT FROM NEW.mem_conjuge_mem_id THEN
        UPDATE secretaria.membro SET mem_conjuge_mem_id = NULL
         WHERE mem_id = OLD.mem_conjuge_mem_id AND mem_conjuge_mem_id = NEW.mem_id;
    END IF;
    IF NEW.mem_conjuge_mem_id IS NOT NULL THEN
        UPDATE secretaria.membro SET mem_conjuge_mem_id = NEW.mem_id
         WHERE mem_id = NEW.mem_conjuge_mem_id AND mem_conjuge_mem_id IS NULL;
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_mem_50_conjuge_reciproco
    AFTER INSERT OR UPDATE OF mem_conjuge_mem_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_conjuge_reciproco();

-- ---------------------------------------------------------------- registos parecidos (possíveis duplicados)
-- Pontos: mesmo documento 100; nome igual ou muito parecido 40 (parecido 20); mesma data de nascimento 30;
-- mesmo local de nascimento 10. Devolve os que somam 40 ou mais (os mais parecidos primeiro, até 10).
-- SECURITY INVOKER: cada utilizador só compara com os membros que pode ver (RLS).
CREATE FUNCTION nucleo.fn_membros_parecidos(p_nome TEXT, p_apelido TEXT, p_data_nascimento DATE DEFAULT NULL,
                                            p_naturalidade TEXT DEFAULT NULL, p_numero_identificacao TEXT DEFAULT NULL,
                                            p_excluir_mem_id INT DEFAULT NULL)
RETURNS TABLE (mem_id INT, mem_igr_id INT, nome TEXT, data_nascimento DATE, naturalidade TEXT,
               numero_identificacao TEXT, estado nucleo.estado_membro_t, pontos INT, motivos TEXT[])
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH p AS (
        SELECT lower(trim(coalesce(p_nome, '') || ' ' || coalesce(p_apelido, ''))) AS nome,
               nullif(upper(regexp_replace(coalesce(p_numero_identificacao, ''), '[^A-Za-z0-9]', '', 'g')), '') AS doc,
               nullif(lower(trim(coalesce(p_naturalidade, ''))), '') AS nat
    ), candidatos AS (
        SELECT m.*, similarity(lower(m.mem_nome || ' ' || m.mem_apelido), p.nome) AS sim,
               (p.doc IS NOT NULL AND length(p.doc) >= 5
                AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc) AS mesmo_doc,
               (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento) AS mesma_data,
               (p.nat IS NOT NULL AND lower(trim(m.mem_naturalidade)) = p.nat) AS mesmo_local
          FROM secretaria.membro m, p
         WHERE m.mem_end_date IS NULL
           AND m.mem_id IS DISTINCT FROM p_excluir_mem_id
           AND ((m.mem_nome || ' ' || m.mem_apelido) % (coalesce(p_nome, '') || ' ' || coalesce(p_apelido, ''))
                OR (p.doc IS NOT NULL AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc)
                OR (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento))
    ), pontuados AS (
        SELECT c.*,
               (CASE WHEN c.mesmo_doc THEN 100 ELSE 0 END
              + CASE WHEN c.sim >= 0.6 THEN 40 WHEN c.sim >= 0.45 THEN 20 ELSE 0 END
              + CASE WHEN c.mesma_data THEN 30 ELSE 0 END
              + CASE WHEN c.mesmo_local THEN 10 ELSE 0 END) AS pts,
               array_remove(ARRAY[
                 CASE WHEN c.mesmo_doc THEN 'Mesmo número de documento' END,
                 CASE WHEN c.sim >= 0.6 THEN 'Nome igual ou muito parecido' WHEN c.sim >= 0.45 THEN 'Nome parecido' END,
                 CASE WHEN c.mesma_data THEN 'Mesma data de nascimento' END,
                 CASE WHEN c.mesmo_local THEN 'Mesmo local de nascimento' END], NULL) AS mot
          FROM candidatos c
    )
    SELECT x.mem_id, x.mem_igr_id, (x.mem_nome || ' ' || x.mem_apelido)::TEXT, x.mem_data_nascimento,
           x.mem_naturalidade::TEXT, x.mem_numero_identificacao::TEXT, x.mem_estado, x.pts, x.mot
      FROM pontuados x
     WHERE x.pts >= 40
     ORDER BY x.pts DESC, x.mem_apelido, x.mem_nome
     LIMIT 10
$$;
COMMENT ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) IS
    'Registos de membros parecidos (possíveis duplicados) entre os que o utilizador vê: só aviso, não bloqueia (V33)';
REVOKE ALL ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) TO app_igreja;

-- ---------------------------------------------------------------- vistas
-- Colunas novas só no fim (CREATE OR REPLACE mantém as que já existem)
CREATE OR REPLACE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado,
       mem_estado_civil, mem_data_nascimento, mem_conjuge_mem_id
FROM secretaria.membro WHERE mem_end_date IS NULL;

-- Lista dos membros para exportar (CSV/PDF): os campos mais usados, o contacto principal e o baptismo
CREATE VIEW secretaria.vw_membros_lista WITH (security_invoker = true) AS
SELECT m.mem_id, m.mem_igr_id,
       m.mem_nome || ' ' || m.mem_apelido AS nome,
       m.mem_sexo AS sexo, m.mem_data_nascimento AS data_nascimento,
       date_part('year', age(m.mem_data_nascimento))::INT AS idade,
       m.mem_estado_civil AS estado_civil, m.mem_estado AS estado,
       (SELECT c.cto_valor FROM secretaria.contacto c
         WHERE c.cto_mem_id = m.mem_id AND c.cto_end_date IS NULL AND c.cto_tipo IN ('TELEFONE', 'WHATSAPP')
         ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) AS telemovel,
       (SELECT c.cto_valor FROM secretaria.contacto c
         WHERE c.cto_mem_id = m.mem_id AND c.cto_end_date IS NULL AND c.cto_tipo = 'EMAIL'
         ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) AS email,
       m.mem_bairro AS bairro, m.mem_cidade_distrito AS cidade,
       m.mem_profissao AS profissao,
       f.fam_nome AS familia,
       (SELECT min(b.bap_data) FROM secretaria.baptismo b WHERE b.bap_mem_id = m.mem_id AND b.bap_end_date IS NULL) AS data_baptismo,
       m.mem_data_entrada AS data_entrada
FROM secretaria.membro m
LEFT JOIN secretaria.familia f ON f.fam_id = m.mem_fam_id
WHERE m.mem_end_date IS NULL;
COMMENT ON VIEW secretaria.vw_membros_lista IS 'Lista dos membros para exportar (V33); RLS das tabelas por baixo';
GRANT SELECT ON secretaria.vw_membros_lista TO app_igreja;

-- >>>>> V34__actividades_responsaveis_conflitos_e_execucao.sql
-- =====================================================================
-- V34 · Actividades dos departamentos (F-ACT): objectivos, vários responsáveis, conflitos de calendário e
--       execução financeira (programa anual da igreja)
--
--   actividade               objectivos (texto). O responsável principal continua em act_responsavel_mem_id.
--   actividade_responsavel   tabela nova: outros responsáveis e a função de cada um; o membro é da mesma igreja.
--   conflitos                actividades.fn_conflitos_actividade(igreja, início, fim, excluir): as actividades da
--                            mesma igreja (não canceladas) cujo horário se sobrepõe. Só informa: a actividade pode
--                            gravar-se mesmo com conflito (quem a regista confirma).
--                            actividades.fn_datas_alternativas(...): os dias seguintes, à mesma hora, sem conflito.
--   execução                actividades.vw_actividades_execucao: previsto, material, despesas pedidas e aprovadas e
--                            o que já saiu da tesouraria (saídas confirmadas ligadas à actividade, menos estornos).
--
-- Permissões: as da tabela nova seguem os perfis que gerem o material das actividades (actividades.material.*).
-- As vistas e funções são SECURITY INVOKER: cada um só vê as actividades, despesas e movimentos que pode ler.
-- Gerado com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- actividade: objectivos
ALTER TABLE actividades.actividade ADD COLUMN act_objectivos TEXT;
COMMENT ON COLUMN actividades.actividade.act_objectivos IS 'O que a actividade pretende alcançar (V34)';
-- listagem por departamento e procura de conflitos por data
CREATE INDEX idx_act_inicio ON actividades.actividade (act_data_inicio) WHERE act_end_date IS NULL;

-- ---------------------------------------------------------------- tabela actividades.actividade_responsavel (gerada: gen.py)
CREATE TABLE actividades.actividade_responsavel (
    acr_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    acr_act_id INT NOT NULL,
    acr_mem_id INT NOT NULL,
    acr_funcao VARCHAR(100),
    acr_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    acr_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    acr_criado_por INT,
    acr_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    acr_modificado_por INT,
    acr_end_date TIMESTAMPTZ,
    CONSTRAINT fk_acr_act_id FOREIGN KEY (acr_act_id) REFERENCES actividades.actividade(act_id),
    CONSTRAINT fk_acr_mem_id FOREIGN KEY (acr_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_acr_end_date CHECK (acr_end_date IS NULL OR acr_end_date >= acr_criado_em)
);
COMMENT ON TABLE actividades.actividade_responsavel IS 'Responsáveis de uma actividade, além do principal, e a função de cada um (V34)';
COMMENT ON COLUMN actividades.actividade_responsavel.acr_funcao IS 'Ex.: coordenação, logística, programa, finanças';
CREATE UNIQUE INDEX uq_acr_act_id_mem_id ON actividades.actividade_responsavel (acr_act_id, acr_mem_id) WHERE acr_end_date IS NULL;
COMMENT ON INDEX actividades.uq_acr_act_id_mem_id IS '[membroId] Este membro já é responsável por esta actividade.';
CREATE INDEX idx_acr_mem_id ON actividades.actividade_responsavel (acr_mem_id);

CREATE TRIGGER trg_acr_00_padrao BEFORE INSERT OR UPDATE ON actividades.actividade_responsavel FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('acr', 'actividades.actividade_responsavel', '');
CREATE TRIGGER trg_acr_00_sem_delete BEFORE DELETE ON actividades.actividade_responsavel FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('acr');
CREATE TRIGGER trg_acr_00_sem_truncate BEFORE TRUNCATE ON actividades.actividade_responsavel FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('acr');
CREATE TRIGGER trg_acr_99_log AFTER UPDATE ON actividades.actividade_responsavel FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('acr');
ALTER TABLE actividades.actividade_responsavel ADD CONSTRAINT fk_acr_criado_por FOREIGN KEY (acr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.actividade_responsavel ADD CONSTRAINT fk_acr_modificado_por FOREIGN KEY (acr_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE actividades.actividade_responsavel ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_acr_ler ON actividades.actividade_responsavel FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.ler'))::INT[]))));
CREATE POLICY pol_acr_criar ON actividades.actividade_responsavel FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.criar'))::INT[]))));
CREATE POLICY pol_acr_alterar ON actividades.actividade_responsavel FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[])))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[]))));
GRANT SELECT, INSERT, UPDATE ON actividades.actividade_responsavel TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;

-- ---------------------------------------------------------------- permissões (os perfis que gerem o material)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('actividades.actividade_responsavel.ler', 'Ler: Responsáveis de uma actividade, além do principal, e a função de cada um'),
  ('actividades.actividade_responsavel.criar', 'Criar: Responsáveis de uma actividade, além do principal, e a função de cada um'),
  ('actividades.actividade_responsavel.alterar', 'Alterar: Responsáveis de uma actividade, além do principal, e a função de cada um'),
  ('actividades.actividade_responsavel.terminar', 'Terminar (end_date): Responsáveis de uma actividade, além do principal, e a função de cada um');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.material.%'
  JOIN nucleo.permissao novo   ON novo.prm_codigo = replace(antigo.prm_codigo, 'actividades.material.', 'actividades.actividade_responsavel.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- regra: o responsável é membro da igreja da actividade
CREATE FUNCTION actividades.fn_acr_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_igr_act INT;
    v_igr_mem INT;
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.acr_act_id, NEW.acr_mem_id) IS NOT DISTINCT FROM (OLD.acr_act_id, OLD.acr_mem_id) THEN
        RETURN NEW;
    END IF;
    SELECT d.ide_igr_id INTO v_igr_act FROM actividades.actividade a
      JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = NEW.acr_act_id;
    SELECT mem_igr_id INTO v_igr_mem FROM secretaria.membro WHERE mem_id = NEW.acr_mem_id;
    IF v_igr_mem IS DISTINCT FROM v_igr_act THEN
        RAISE EXCEPTION 'O responsável tem de ser membro da igreja da actividade' USING COLUMN = 'acr_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_acr_10_validar
    BEFORE INSERT OR UPDATE ON actividades.actividade_responsavel
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_acr_validar();

-- ---------------------------------------------------------------- conflitos de calendário
-- Sem hora de fim, conta-se uma actividade de 2 horas. Canceladas e terminadas não contam.
CREATE FUNCTION actividades.fn_conflitos_actividade(p_igr INT, p_inicio TIMESTAMPTZ, p_fim TIMESTAMPTZ DEFAULT NULL,
                                                   p_excluir_act_id INT DEFAULT NULL)
RETURNS TABLE (act_id INT, nome TEXT, departamento TEXT, data_inicio TIMESTAMPTZ, data_fim TIMESTAMPTZ, local TEXT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT a.act_id, a.act_nome::TEXT, dp.dep_nome::TEXT, a.act_data_inicio, a.act_data_fim, a.act_local::TEXT
      FROM actividades.actividade a
      JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
     WHERE d.ide_igr_id = p_igr
       AND a.act_end_date IS NULL AND a.act_estado <> 'CANCELADA'
       AND a.act_id IS DISTINCT FROM p_excluir_act_id
       AND a.act_data_inicio < coalesce(p_fim, p_inicio + INTERVAL '2 hours')
       AND p_inicio < coalesce(a.act_data_fim, a.act_data_inicio + INTERVAL '2 hours')
     ORDER BY a.act_data_inicio
$$;

-- Os primeiros p_n dias seguintes (até 60), à mesma hora e com a mesma duração, sem conflito
CREATE FUNCTION actividades.fn_datas_alternativas(p_igr INT, p_inicio TIMESTAMPTZ, p_fim TIMESTAMPTZ DEFAULT NULL,
                                                 p_excluir_act_id INT DEFAULT NULL, p_n INT DEFAULT 3)
RETURNS TABLE (data_inicio TIMESTAMPTZ, data_fim TIMESTAMPTZ)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT p_inicio + (k * INTERVAL '1 day'), p_fim + (k * INTERVAL '1 day')
      FROM generate_series(1, 60) k
     WHERE NOT EXISTS (SELECT 1 FROM actividades.fn_conflitos_actividade(p_igr, p_inicio + (k * INTERVAL '1 day'),
                                                                         p_fim + (k * INTERVAL '1 day'), p_excluir_act_id))
     ORDER BY k
     LIMIT p_n
$$;
REVOKE ALL ON FUNCTION actividades.fn_conflitos_actividade(INT, TIMESTAMPTZ, TIMESTAMPTZ, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION actividades.fn_datas_alternativas(INT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION actividades.fn_conflitos_actividade(INT, TIMESTAMPTZ, TIMESTAMPTZ, INT) TO app_igreja;
GRANT EXECUTE ON FUNCTION actividades.fn_datas_alternativas(INT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT) TO app_igreja;

-- ---------------------------------------------------------------- programa anual e execução financeira
CREATE VIEW actividades.vw_actividades_execucao WITH (security_invoker = true) AS
SELECT a.act_id, d.ide_igr_id AS igreja_id, a.act_ide_id AS departamento_igreja_id, dp.dep_nome AS departamento,
       a.act_nome AS nome, a.act_descricao AS descricao, a.act_objectivos AS objectivos, a.act_local AS local,
       a.act_data_inicio AS data_inicio, a.act_data_fim AS data_fim, a.act_estado AS estado,
       EXTRACT(YEAR FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT  AS ano,
       EXTRACT(MONTH FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       a.act_responsavel_mem_id AS responsavel_mem_id,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = a.act_responsavel_mem_id) AS responsavel,
       (SELECT count(*) FROM actividades.actividade_responsavel r WHERE r.acr_act_id = a.act_id AND r.acr_end_date IS NULL)::INT AS outros_responsaveis,
       a.act_valor_previsto AS valor_previsto,
       coalesce((SELECT sum(x.mat_quantidade * x.mat_preco_unitario) FROM actividades.material x
                  WHERE x.mat_act_id = a.act_id AND x.mat_end_date IS NULL), 0)::DECIMAL(14,2) AS material_previsto,
       coalesce((SELECT sum(x.des_valor_solicitado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('SUBMETIDA', 'APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_pedidas,
       coalesce((SELECT sum(x.des_valor_aprovado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_aprovadas,
       coalesce((SELECT sum(CASE WHEN t.tra_tipo = 'SAIDA' THEN l.tli_valor ELSE -l.tli_valor END)
                   FROM tesouraria.transacao_linha l JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id
                  WHERE l.tli_act_id = a.act_id AND l.tli_end_date IS NULL AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
                    AND (t.tra_tipo = 'SAIDA' OR (t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NOT NULL))), 0)::DECIMAL(14,2) AS executado
FROM actividades.actividade a
JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
WHERE a.act_end_date IS NULL;
COMMENT ON VIEW actividades.vw_actividades_execucao IS
    'Programa anual: actividades da igreja com o previsto e o executado (V34); cada um só vê o que pode ler';
GRANT SELECT ON actividades.vw_actividades_execucao TO app_igreja;

-- >>>>> V35__actividades_da_area_pastoral.sql
-- =====================================================================
-- V35 · Actividades da área pastoral (F-ACT, F-ORG): actividades do distrito pastoral nos calendários das igrejas
--
--   actividade   pertence OU a um departamento de uma igreja (act_ide_id: actividade local) OU a um distrito
--                pastoral (act_dst_id: área pastoral) — nunca aos dois nem a nenhum (chk_act_origem).
--   acesso       actividades.fn_acesso_distrito(distrito, permissão):
--                  ler     → quem tem a permissão numa igreja do distrito (aparecem no calendário de todas elas);
--                  criar, alterar, terminar → o pastor do distrito (perfil PASTOR com a permissão), quem a tem ao
--                            nível da Associação/Missão do distrito, ou o super-administrador.
--                Um director de departamento de uma igreja não cria nem altera actividades do distrito.
--   políticas    actividade, material e actividade_responsavel: a regra local de antes OU a do distrito.
--   regras       responsável de uma actividade do distrito: membro de uma igreja do distrito.
--   conflitos    as actividades do distrito contam nos conflitos de cada igreja do distrito.
--   programa     vw_actividades_execucao inclui, para cada igreja, as actividades do seu distrito, com a origem
--                (IGREJA ou AREA_PASTORAL) e o distrito (colunas novas no fim).
--
-- Gerado com database/gerador (defs.py, seguranca_gen.py: marcador {C}); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- acesso às actividades de um distrito
CREATE FUNCTION actividades.fn_acesso_distrito(p_dst INT, p_codigo TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL OR p_dst IS NULL THEN RETURN FALSE; END IF;
    IF nucleo.fn_e_super_admin() THEN RETURN TRUE; END IF;
    -- ler: as igrejas do distrito vêem as actividades da área pastoral
    IF p_codigo LIKE '%.ler' AND EXISTS (
        SELECT 1 FROM organizacao.igreja i
         WHERE i.igr_dst_id = p_dst AND i.igr_end_date IS NULL
           AND i.igr_id = ANY (nucleo.fn_igrejas_com_permissao(p_codigo))) THEN
        RETURN TRUE;
    END IF;
    -- o pastor do distrito (se o perfil PASTOR tiver a permissão)
    IF EXISTS (SELECT 1 FROM organizacao.distrito d
                WHERE d.dst_id = p_dst AND d.dst_end_date IS NULL AND d.dst_pastor_usu_id = v_usr)
       AND EXISTS (SELECT 1 FROM nucleo.perfil pf
                     JOIN nucleo.perfil_permissao pp ON pp.ppe_per_id = pf.per_id AND pp.ppe_end_date IS NULL
                     JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id AND pm.prm_end_date IS NULL
                    WHERE pf.per_codigo = 'PASTOR' AND pf.per_end_date IS NULL AND pm.prm_codigo = p_codigo) THEN
        RETURN TRUE;
    END IF;
    -- quem tem a permissão ao nível da Associação/Missão do distrito
    RETURN EXISTS (SELECT 1 FROM organizacao.distrito d
                    WHERE d.dst_id = p_dst AND d.dst_ent_id IN (SELECT nucleo.fn_entidades_com_permissao(p_codigo)));
END $$;
COMMENT ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) IS
    'V35: acesso às actividades da área pastoral (ler: igrejas do distrito; escrever: pastor do distrito, Associação, super-administrador)';
REVOKE ALL ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) TO app_igreja;

-- ---------------------------------------------------------------- actividade: local ou da área pastoral
ALTER TABLE actividades.actividade ALTER COLUMN act_ide_id DROP NOT NULL;
ALTER TABLE actividades.actividade ADD COLUMN act_dst_id INT;
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_dst_id FOREIGN KEY (act_dst_id) REFERENCES organizacao.distrito(dst_id);
ALTER TABLE actividades.actividade ADD CONSTRAINT chk_act_origem CHECK ((act_ide_id IS NULL) <> (act_dst_id IS NULL));
COMMENT ON COLUMN actividades.actividade.act_ide_id IS 'Departamento da igreja (actividade local); vazio nas da área pastoral (V35)';
COMMENT ON COLUMN actividades.actividade.act_dst_id IS 'Distrito pastoral: actividade da área pastoral, nos calendários de todas as igrejas do distrito (V35)';
COMMENT ON CONSTRAINT chk_act_origem ON actividades.actividade IS
    'A actividade é de um departamento da igreja ou da área pastoral (distrito), não das duas nem de nenhuma.';
CREATE INDEX idx_act_dst_id ON actividades.actividade (act_dst_id);

-- ---------------------------------------------------------------- políticas (geradas: gen.py)
DROP POLICY pol_act_ler ON actividades.actividade;
DROP POLICY pol_act_criar ON actividades.actividade;
DROP POLICY pol_act_alterar ON actividades.actividade;
DROP POLICY pol_mat_ler ON actividades.material;
DROP POLICY pol_mat_criar ON actividades.material;
DROP POLICY pol_mat_alterar ON actividades.material;
DROP POLICY pol_acr_ler ON actividades.actividade_responsavel;
DROP POLICY pol_acr_criar ON actividades.actividade_responsavel;
DROP POLICY pol_acr_alterar ON actividades.actividade_responsavel;
CREATE POLICY pol_act_ler ON actividades.actividade FOR SELECT USING ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.ler'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.ler')));
CREATE POLICY pol_act_criar ON actividades.actividade FOR INSERT WITH CHECK ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.criar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.criar')));
CREATE POLICY pol_act_alterar ON actividades.actividade FOR UPDATE USING ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.alterar'))) WITH CHECK ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.alterar')));
CREATE POLICY pol_mat_ler ON actividades.material FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.ler'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.ler')))));
CREATE POLICY pol_mat_criar ON actividades.material FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.criar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.criar')))));
CREATE POLICY pol_mat_alterar ON actividades.material FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.alterar'))))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.alterar')))));
CREATE POLICY pol_acr_ler ON actividades.actividade_responsavel FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.ler'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.ler')))));
CREATE POLICY pol_acr_criar ON actividades.actividade_responsavel FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.criar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.criar')))));
CREATE POLICY pol_acr_alterar ON actividades.actividade_responsavel FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.alterar'))))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.alterar')))));

-- ---------------------------------------------------------------- responsável: membro da igreja (ou do distrito)
CREATE OR REPLACE FUNCTION actividades.fn_acr_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_ide INT;
    v_dst INT;
    v_igr_mem INT;
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.acr_act_id, NEW.acr_mem_id) IS NOT DISTINCT FROM (OLD.acr_act_id, OLD.acr_mem_id) THEN
        RETURN NEW;
    END IF;
    SELECT act_ide_id, act_dst_id INTO v_ide, v_dst FROM actividades.actividade WHERE act_id = NEW.acr_act_id;
    SELECT mem_igr_id INTO v_igr_mem FROM secretaria.membro WHERE mem_id = NEW.acr_mem_id;
    IF v_dst IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM organizacao.igreja WHERE igr_id = v_igr_mem AND igr_dst_id = v_dst) THEN
            RAISE EXCEPTION 'O responsável tem de ser membro de uma igreja do distrito' USING COLUMN = 'acr_mem_id';
        END IF;
    ELSIF v_igr_mem IS DISTINCT FROM (SELECT ide_igr_id FROM organizacao.igreja_departamento WHERE ide_id = v_ide) THEN
        RAISE EXCEPTION 'O responsável tem de ser membro da igreja da actividade' USING COLUMN = 'acr_mem_id';
    END IF;
    RETURN NEW;
END $$;

-- ---------------------------------------------------------------- conflitos: também as actividades do distrito
CREATE OR REPLACE FUNCTION actividades.fn_conflitos_actividade(p_igr INT, p_inicio TIMESTAMPTZ, p_fim TIMESTAMPTZ DEFAULT NULL,
                                                              p_excluir_act_id INT DEFAULT NULL)
RETURNS TABLE (act_id INT, nome TEXT, departamento TEXT, data_inicio TIMESTAMPTZ, data_fim TIMESTAMPTZ, local TEXT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT a.act_id, a.act_nome::TEXT,
           coalesce(dp.dep_nome, 'Área pastoral (' || ds.dst_nome || ')')::TEXT,
           a.act_data_inicio, a.act_data_fim, a.act_local::TEXT
      FROM actividades.actividade a
      LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      LEFT JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
      LEFT JOIN organizacao.distrito ds ON ds.dst_id = a.act_dst_id
     WHERE (d.ide_igr_id = p_igr
            OR a.act_dst_id = (SELECT i.igr_dst_id FROM organizacao.igreja i WHERE i.igr_id = p_igr))
       AND a.act_end_date IS NULL AND a.act_estado <> 'CANCELADA'
       AND a.act_id IS DISTINCT FROM p_excluir_act_id
       AND a.act_data_inicio < coalesce(p_fim, p_inicio + INTERVAL '2 hours')
       AND p_inicio < coalesce(a.act_data_fim, a.act_data_inicio + INTERVAL '2 hours')
     ORDER BY a.act_data_inicio
$$;

-- ---------------------------------------------------------------- programa: locais e da área pastoral
-- Mesmas colunas de V34 e, no fim, a origem e o distrito. As do distrito aparecem em cada igreja do distrito.
CREATE OR REPLACE VIEW actividades.vw_actividades_execucao WITH (security_invoker = true) AS
WITH base AS (
    SELECT a.*, d.ide_igr_id AS igreja_id, dp.dep_nome AS departamento, 'IGREJA'::TEXT AS origem, NULL::INT AS distrito_id, NULL::TEXT AS distrito
      FROM actividades.actividade a
      JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
     WHERE a.act_end_date IS NULL
    UNION ALL
    SELECT a.*, i.igr_id, 'Área pastoral', 'AREA_PASTORAL', ds.dst_id, ds.dst_nome::TEXT
      FROM actividades.actividade a
      JOIN organizacao.distrito ds ON ds.dst_id = a.act_dst_id
      JOIN organizacao.igreja i ON i.igr_dst_id = ds.dst_id AND i.igr_end_date IS NULL
     WHERE a.act_end_date IS NULL
)
SELECT a.act_id, a.igreja_id, a.act_ide_id AS departamento_igreja_id, a.departamento::VARCHAR(100) AS departamento,
       a.act_nome AS nome, a.act_descricao AS descricao, a.act_objectivos AS objectivos, a.act_local AS local,
       a.act_data_inicio AS data_inicio, a.act_data_fim AS data_fim, a.act_estado AS estado,
       EXTRACT(YEAR FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT  AS ano,
       EXTRACT(MONTH FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       a.act_responsavel_mem_id AS responsavel_mem_id,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = a.act_responsavel_mem_id) AS responsavel,
       (SELECT count(*) FROM actividades.actividade_responsavel r WHERE r.acr_act_id = a.act_id AND r.acr_end_date IS NULL)::INT AS outros_responsaveis,
       a.act_valor_previsto AS valor_previsto,
       coalesce((SELECT sum(x.mat_quantidade * x.mat_preco_unitario) FROM actividades.material x
                  WHERE x.mat_act_id = a.act_id AND x.mat_end_date IS NULL), 0)::DECIMAL(14,2) AS material_previsto,
       coalesce((SELECT sum(x.des_valor_solicitado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('SUBMETIDA', 'APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_pedidas,
       coalesce((SELECT sum(x.des_valor_aprovado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_aprovadas,
       coalesce((SELECT sum(CASE WHEN t.tra_tipo = 'SAIDA' THEN l.tli_valor ELSE -l.tli_valor END)
                   FROM tesouraria.transacao_linha l JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id
                  WHERE l.tli_act_id = a.act_id AND l.tli_end_date IS NULL AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
                    AND (t.tra_tipo = 'SAIDA' OR (t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NOT NULL))), 0)::DECIMAL(14,2) AS executado,
       a.origem, a.distrito_id, a.distrito
FROM base a;

-- >>>>> V36__participacao_contribuicoes_e_metas.sql
-- =====================================================================
-- V36 · Decisões pendentes do plano: participação (membros inactivos), contribuições lançadas duas vezes
--       (membro e família), estado civil "noivo" e metas anuais com +5% (ex.: obra de reavivamento)
--
--   estado civil   novo valor NOIVO.
--   participação   secretaria.fn_participacao_membros(igreja): para cada membro, a data da última participação
--                  (presença na Escola Sabatina ou contribuição dele ou da família) e se está INACTIVO: estado
--                  ACTIVO no livro sem participação nos últimos 6 meses. O estado no livro não muda (só por voto).
--                  Só para quem lê os membros da igreja; devolve datas, nunca valores.
--   duplicados     tesouraria.fn_contribuicoes_sobrepostas(membro, família, data): dízimos do mesmo mês já lançados
--                  em nome da família do membro (ou, para uma família, em nome dos seus membros). Só avisa.
--   metas          tesouraria.fn_alvo_sugerido(igreja, fundo, ano): o alvo do ano anterior + 5% (o utilizador
--                  pode ajustar). O histórico é o próprio alvo de cada ano (e o log de auditoria).
--                  tesouraria.vw_fundo_mensal: o arrecadado por fundo, mês a mês (registo mensal e acumulado no ano).
--
-- A obra de reavivamento é um fundo próprio da igreja (Fundos e ofertas) com um alvo por ano: não há tabela nova.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TYPE nucleo.estado_civil_t ADD VALUE IF NOT EXISTS 'NOIVO';

-- ---------------------------------------------------------------- participação dos membros
CREATE FUNCTION secretaria.fn_participacao_membros(p_igr INT, p_meses INT DEFAULT 6)
RETURNS TABLE (mem_id INT, ultima_participacao DATE, inactivo BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH membros AS (
        SELECT m.mem_id, m.mem_fam_id, m.mem_estado
          FROM secretaria.membro m
         WHERE m.mem_igr_id = p_igr AND m.mem_end_date IS NULL
           AND p_igr = ANY (nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'))
    ), datas AS (
        SELECT x.mem_id, x.mem_estado,
               greatest(
                 (SELECT max(s.esa_data) FROM escola_sabatina.presenca p
                    JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = p.epr_ers_id
                    JOIN escola_sabatina.sabado s ON s.esa_id = r.ers_esa_id
                   WHERE p.epr_mem_id = x.mem_id AND p.epr_presente AND p.epr_end_date IS NULL),
                 (SELECT max((t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE) FROM tesouraria.transacao t
                   WHERE (t.tra_mem_id = x.mem_id OR (x.mem_fam_id IS NOT NULL AND t.tra_fam_id = x.mem_fam_id))
                     AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
                     AND t.tra_estado IN ('PENDENTE', 'CONFIRMADA') AND t.tra_end_date IS NULL)) AS ultima
          FROM membros x
    )
    SELECT d.mem_id, d.ultima,
           d.mem_estado = 'ACTIVO' AND (d.ultima IS NULL OR d.ultima < (current_date - make_interval(months => p_meses)))
      FROM datas d
$$;
COMMENT ON FUNCTION secretaria.fn_participacao_membros(INT, INT) IS
    'V36: membros ACTIVO sem presença na ES nem contribuição nos últimos meses = inactivos (indicador; o estado no livro não muda)';
REVOKE ALL ON FUNCTION secretaria.fn_participacao_membros(INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION secretaria.fn_participacao_membros(INT, INT) TO app_igreja;

-- ---------------------------------------------------------------- dízimo do mesmo mês em nome do membro e da família
-- SECURITY INVOKER: só encontra os movimentos que o utilizador pode ler (RLS).
CREATE FUNCTION tesouraria.fn_contribuicoes_sobrepostas(p_mem INT, p_fam INT, p_data DATE)
RETURNS TABLE (tra_id BIGINT, data_hora TIMESTAMPTZ, quem TEXT, dizimo DECIMAL(14,2), recibo TEXT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT t.tra_id, t.tra_data_hora,
           coalesce((SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = t.tra_mem_id),
                    (SELECT f.fam_nome FROM secretaria.familia f WHERE f.fam_id = t.tra_fam_id))::TEXT,
           sum(l.tli_valor)::DECIMAL(14,2),
           (SELECT r.rec_numero || '/' || r.rec_ano FROM tesouraria.recibo r WHERE r.rec_tra_id = t.tra_id AND r.rec_end_date IS NULL)
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
      JOIN tesouraria.fundo fu ON fu.fun_id = l.tli_fun_id AND fu.fun_tipo = 'DIZIMO'
     WHERE t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL AND t.tra_end_date IS NULL
       AND t.tra_estado IN ('PENDENTE', 'CONFIRMADA')
       AND date_trunc('month', t.tra_data_hora AT TIME ZONE 'Africa/Maputo') = date_trunc('month', p_data::TIMESTAMP)
       AND (
            -- a contribuir um membro: a família dele já entregou o dízimo neste mês
            (p_mem IS NOT NULL AND t.tra_fam_id = (SELECT m.mem_fam_id FROM secretaria.membro m WHERE m.mem_id = p_mem))
            -- a contribuir uma família: um dos membros dela já entregou em nome próprio
         OR (p_fam IS NOT NULL AND t.tra_mem_id IN (SELECT m.mem_id FROM secretaria.membro m
                                                     WHERE m.mem_fam_id = p_fam AND m.mem_end_date IS NULL)))
     GROUP BY t.tra_id
     ORDER BY t.tra_data_hora
$$;
COMMENT ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) IS
    'V36: dízimos do mesmo mês já lançados em nome da família do membro (ou dos membros da família): só aviso';
REVOKE ALL ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) TO app_igreja;

-- ---------------------------------------------------------------- metas anuais: +5% sobre o alvo do ano anterior
CREATE FUNCTION tesouraria.fn_alvo_sugerido(p_igr INT, p_fun INT, p_ano INT)
RETURNS DECIMAL(14,2)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT round(a.alv_valor_alvo * 1.05, 2)
      FROM tesouraria.alvo a
     WHERE a.alv_igr_id = p_igr AND a.alv_fun_id = p_fun AND a.alv_end_date IS NULL
       AND EXTRACT(YEAR FROM a.alv_data_inicio) = p_ano - 1
     ORDER BY a.alv_data_inicio DESC, a.alv_id DESC
     LIMIT 1
$$;
COMMENT ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) IS
    'V36: meta do ano = alvo do ano anterior + 5% (sugestão; o utilizador autorizado pode ajustar)';
REVOKE ALL ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) TO app_igreja;

-- arrecadado por fundo, mês a mês (sem estornos)
CREATE VIEW tesouraria.vw_fundo_mensal WITH (security_invoker = true) AS
SELECT s.sdf_igr_id AS igreja_id, s.sdf_fun_id AS fundo_id, f.fun_nome AS fundo,
       EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
       sum(s.sdf_entradas - s.sdf_estornos_entradas)::DECIMAL(14,2) AS arrecadado
  FROM tesouraria.saldo_diario_fundo s
  JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
 WHERE s.sdf_end_date IS NULL
 GROUP BY s.sdf_igr_id, s.sdf_fun_id, f.fun_nome, EXTRACT(YEAR FROM s.sdf_data), EXTRACT(MONTH FROM s.sdf_data);
COMMENT ON VIEW tesouraria.vw_fundo_mensal IS 'V36: arrecadado por fundo e mês (ex.: obra de reavivamento: registo mensal e acumulado no ano)';
GRANT SELECT ON tesouraria.vw_fundo_mensal TO app_igreja;

-- >>>>> V37__comunicados.sql
-- =====================================================================
-- V37 · Comunicados e anúncios (F-COM): de uma igreja, do distrito pastoral ou da Associação/Missão
--
--   comunicado          título, conteúdo, público (MEMBROS = todos os membros; LIDERANCA = só quem tem perfil nas
--                       igrejas), publicar em, válido até e estado (RASCUNHO, PUBLICADO, ARQUIVADO). Tem um e um só
--                       emissor: a igreja (cmc_igr_id), o distrito pastoral (cmc_dst_id) ou a Associação (cmc_ent_id).
--   comunicado_igreja   para o distrito e a Associação: um conjunto de igrejas (sem linhas = todas as do emissor).
--                       As igrejas têm de ser do distrito / da Associação que publica.
--   quem publica        nucleo.fn_comunicado_emissor: a igreja → quem tem a permissão nela; o distrito → o pastor do
--                       distrito (perfil PASTOR com a permissão); a Associação → quem a tem lá; o super-administrador.
--                       Os rascunhos só os vê quem os pode editar.
--   quem lê             nucleo.fn_comunicado_para_mim: publicado, já em vigor e ainda válido, para uma igreja em que o
--                       utilizador tem nucleo.comunicado.ler (liderança) ou, se o público for MEMBROS, a igreja do
--                       membro com sessão.
--   directório          vw_directorio_igrejas ganha o distrito pastoral (escolher as igrejas do distrito).
--
-- Permissões novas (nucleo.comunicado.*, nucleo.comunicado_igreja.*): publicam ADMIN, PASTOR, ANCIAO, SECRETARIO,
-- ADMIN_ASSOCIACAO e SECRETARIO_ASSOCIACAO; lêem TESOUREIRO, DIRECTOR_ES, SECRETARIO_ES, DIRECTOR_DEPARTAMENTO e
-- TESOUREIRO_ASSOCIACAO. Gerado com database/gerador (defs.py, seguranca_gen.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TYPE nucleo.estado_comunicado_t AS ENUM ('RASCUNHO', 'PUBLICADO', 'ARQUIVADO');

-- ---------------------------------------------------------------- tabelas (geradas: gen.py)
CREATE TABLE nucleo.comunicado (
    cmc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cmc_igr_id INT,
    cmc_dst_id INT,
    cmc_ent_id INT,
    cmc_titulo VARCHAR(200) NOT NULL,
    cmc_conteudo TEXT NOT NULL,
    cmc_publico VARCHAR(10) NOT NULL DEFAULT 'MEMBROS',
    cmc_publicar_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cmc_valido_ate TIMESTAMPTZ,
    cmc_estado estado_comunicado_t NOT NULL DEFAULT 'RASCUNHO',
    cmc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cmc_criado_por INT,
    cmc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cmc_modificado_por INT,
    cmc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cmc_igr_id FOREIGN KEY (cmc_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_cmc_dst_id FOREIGN KEY (cmc_dst_id) REFERENCES organizacao.distrito(dst_id),
    CONSTRAINT fk_cmc_ent_id FOREIGN KEY (cmc_ent_id) REFERENCES organizacao.entidade(ent_id),
    CONSTRAINT chk_cmc_emissor CHECK ((cmc_igr_id IS NOT NULL)::INT + (cmc_dst_id IS NOT NULL)::INT + (cmc_ent_id IS NOT NULL)::INT = 1),
    CONSTRAINT chk_cmc_publico CHECK (cmc_publico IN ('MEMBROS', 'LIDERANCA')),
    CONSTRAINT chk_cmc_validade CHECK (cmc_valido_ate IS NULL OR cmc_valido_ate > cmc_publicar_em),
    CONSTRAINT chk_cmc_end_date CHECK (cmc_end_date IS NULL OR cmc_end_date >= cmc_criado_em)
);
COMMENT ON TABLE nucleo.comunicado IS 'Comunicados e anúncios: de uma igreja, do distrito pastoral ou da Associação/Missão (V37)';
COMMENT ON COLUMN nucleo.comunicado.cmc_igr_id IS 'Publicado por esta igreja (para os seus membros)';
COMMENT ON COLUMN nucleo.comunicado.cmc_dst_id IS 'Publicado pelo distrito pastoral (para as igrejas do distrito)';
COMMENT ON COLUMN nucleo.comunicado.cmc_ent_id IS 'Publicado pela Associação/Missão (para as suas igrejas)';
COMMENT ON COLUMN nucleo.comunicado.cmc_publico IS 'MEMBROS (todos os membros) ou LIDERANCA (só quem tem perfil nas igrejas)';
COMMENT ON COLUMN nucleo.comunicado.cmc_publicar_em IS 'A partir de quando aparece';
COMMENT ON COLUMN nucleo.comunicado.cmc_valido_ate IS 'Deixa de aparecer depois desta data (vazio = sem fim)';
CREATE INDEX idx_cmc_igr_id ON nucleo.comunicado (cmc_igr_id);
CREATE INDEX idx_cmc_dst_id ON nucleo.comunicado (cmc_dst_id);
CREATE INDEX idx_cmc_ent_id ON nucleo.comunicado (cmc_ent_id);
CREATE INDEX idx_cmc_publicar ON nucleo.comunicado (cmc_publicar_em DESC) WHERE cmc_end_date IS NULL;

-- Igrejas a que se dirige um comunicado do distrito ou da Associação (sem linhas = todas) (V37)
CREATE TABLE nucleo.comunicado_igreja (
    cmi_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cmi_cmc_id INT NOT NULL,
    cmi_igr_id INT NOT NULL,
    cmi_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cmi_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cmi_criado_por INT,
    cmi_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cmi_modificado_por INT,
    cmi_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cmi_cmc_id FOREIGN KEY (cmi_cmc_id) REFERENCES nucleo.comunicado(cmc_id),
    CONSTRAINT fk_cmi_igr_id FOREIGN KEY (cmi_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_cmi_end_date CHECK (cmi_end_date IS NULL OR cmi_end_date >= cmi_criado_em)
);
COMMENT ON TABLE nucleo.comunicado_igreja IS 'Igrejas a que se dirige um comunicado do distrito ou da Associação (sem linhas = todas) (V37)';
CREATE UNIQUE INDEX uq_cmi_cmc_id_igr_id ON nucleo.comunicado_igreja (cmi_cmc_id, cmi_igr_id) WHERE cmi_end_date IS NULL;
CREATE INDEX idx_cmi_igr_id ON nucleo.comunicado_igreja (cmi_igr_id);

CREATE TRIGGER trg_cmc_00_padrao BEFORE INSERT OR UPDATE ON nucleo.comunicado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cmc', 'nucleo.comunicado', '');
CREATE TRIGGER trg_cmc_00_sem_delete BEFORE DELETE ON nucleo.comunicado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cmc');
CREATE TRIGGER trg_cmc_00_sem_truncate BEFORE TRUNCATE ON nucleo.comunicado FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cmc');
CREATE TRIGGER trg_cmc_99_log AFTER UPDATE ON nucleo.comunicado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cmc');
ALTER TABLE nucleo.comunicado ADD CONSTRAINT fk_cmc_criado_por FOREIGN KEY (cmc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.comunicado ADD CONSTRAINT fk_cmc_modificado_por FOREIGN KEY (cmc_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_cmi_00_padrao BEFORE INSERT OR UPDATE ON nucleo.comunicado_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cmi', 'nucleo.comunicado_igreja', '');
CREATE TRIGGER trg_cmi_00_sem_delete BEFORE DELETE ON nucleo.comunicado_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cmi');
CREATE TRIGGER trg_cmi_00_sem_truncate BEFORE TRUNCATE ON nucleo.comunicado_igreja FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cmi');
CREATE TRIGGER trg_cmi_99_log AFTER UPDATE ON nucleo.comunicado_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cmi');
ALTER TABLE nucleo.comunicado_igreja ADD CONSTRAINT fk_cmi_criado_por FOREIGN KEY (cmi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.comunicado_igreja ADD CONSTRAINT fk_cmi_modificado_por FOREIGN KEY (cmi_modificado_por) REFERENCES nucleo.usuario(usu_id);

COMMENT ON CONSTRAINT chk_cmc_emissor ON nucleo.comunicado IS 'O comunicado é publicado por uma igreja, um distrito pastoral ou uma Associação (um e só um).';
COMMENT ON CONSTRAINT chk_cmc_publico ON nucleo.comunicado IS '[publico] O público é MEMBROS (todos os membros) ou LIDERANCA.';
COMMENT ON CONSTRAINT chk_cmc_validade ON nucleo.comunicado IS '[validoAte] A validade tem de terminar depois da data de publicação.';
COMMENT ON INDEX nucleo.uq_cmi_cmc_id_igr_id IS '[igrejaId] Esta igreja já está nos destinatários.';

-- ---------------------------------------------------------------- quem publica e quem lê
CREATE FUNCTION nucleo.fn_comunicado_emissor(p_igr INT, p_dst INT, p_ent INT, p_codigo TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_usr INT := nucleo.fn_usuario_sessao();
    -- ver como emissor (incluindo rascunhos) é para quem pode editar; os outros lêem só o que foi publicado
    v_cod TEXT := CASE WHEN p_codigo LIKE '%.ler' THEN regexp_replace(p_codigo, '\.ler$', '.alterar') ELSE p_codigo END;
BEGIN
    IF v_usr IS NULL THEN RETURN FALSE; END IF;
    IF nucleo.fn_e_super_admin() THEN RETURN TRUE; END IF;
    IF p_igr IS NOT NULL THEN
        RETURN p_igr = ANY (nucleo.fn_igrejas_com_permissao(v_cod));
    END IF;
    IF p_dst IS NOT NULL THEN
        RETURN (EXISTS (SELECT 1 FROM organizacao.distrito d
                         WHERE d.dst_id = p_dst AND d.dst_end_date IS NULL AND d.dst_pastor_usu_id = v_usr)
                AND EXISTS (SELECT 1 FROM nucleo.perfil pf
                              JOIN nucleo.perfil_permissao pp ON pp.ppe_per_id = pf.per_id AND pp.ppe_end_date IS NULL
                              JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id AND pm.prm_end_date IS NULL
                             WHERE pf.per_codigo = 'PASTOR' AND pf.per_end_date IS NULL AND pm.prm_codigo = v_cod))
            OR EXISTS (SELECT 1 FROM organizacao.distrito d
                        WHERE d.dst_id = p_dst AND d.dst_ent_id IN (SELECT nucleo.fn_entidades_com_permissao(v_cod)));
    END IF;
    RETURN p_ent IN (SELECT nucleo.fn_entidades_com_permissao(v_cod));
END $$;
COMMENT ON FUNCTION nucleo.fn_comunicado_emissor(INT, INT, INT, TEXT) IS
    'V37: quem publica (e vê os rascunhos de) um comunicado da igreja, do distrito ou da Associação';

-- As igrejas a que o comunicado se dirige: as escolhidas (comunicado_igreja) ou todas as do emissor
CREATE FUNCTION nucleo.fn_comunicado_igrejas(p_cmc INT) RETURNS SETOF INT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT ci.cmi_igr_id FROM nucleo.comunicado_igreja ci WHERE ci.cmi_cmc_id = p_cmc AND ci.cmi_end_date IS NULL
    UNION
    SELECT i.igr_id
      FROM nucleo.comunicado c
      JOIN organizacao.igreja i ON i.igr_end_date IS NULL
       AND (i.igr_id = c.cmc_igr_id OR i.igr_dst_id = c.cmc_dst_id OR i.igr_ent_id = c.cmc_ent_id)
     WHERE c.cmc_id = p_cmc
       AND NOT EXISTS (SELECT 1 FROM nucleo.comunicado_igreja ci WHERE ci.cmi_cmc_id = p_cmc AND ci.cmi_end_date IS NULL)
$$;

CREATE FUNCTION nucleo.fn_comunicado_para_mim(p_cmc INT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM nucleo.comunicado c
         WHERE c.cmc_id = p_cmc AND c.cmc_end_date IS NULL AND c.cmc_estado = 'PUBLICADO'
           AND c.cmc_publicar_em <= now() AND (c.cmc_valido_ate IS NULL OR c.cmc_valido_ate >= now())
           AND EXISTS (SELECT 1 FROM nucleo.fn_comunicado_igrejas(p_cmc) g(igr_id)
                        WHERE g.igr_id = ANY (nucleo.fn_igrejas_com_permissao('nucleo.comunicado.ler'))
                           OR (c.cmc_publico = 'MEMBROS' AND g.igr_id = (SELECT m.mem_igr_id FROM secretaria.membro m
                                                                          WHERE m.mem_id = nucleo.fn_membro_sessao()))))
$$;
COMMENT ON FUNCTION nucleo.fn_comunicado_para_mim(INT) IS
    'V37: o comunicado publicado e em vigor dirige-se a uma igreja do utilizador (liderança) ou, para MEMBROS, à do membro';
REVOKE ALL ON FUNCTION nucleo.fn_comunicado_emissor(INT, INT, INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION nucleo.fn_comunicado_igrejas(INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION nucleo.fn_comunicado_para_mim(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_comunicado_emissor(INT, INT, INT, TEXT) TO app_igreja;
GRANT EXECUTE ON FUNCTION nucleo.fn_comunicado_igrejas(INT) TO app_igreja;
GRANT EXECUTE ON FUNCTION nucleo.fn_comunicado_para_mim(INT) TO app_igreja;

-- ---------------------------------------------------------------- regras: destinatários do emissor
CREATE FUNCTION nucleo.fn_cmi_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE c nucleo.comunicado%ROWTYPE;
BEGIN
    SELECT * INTO c FROM nucleo.comunicado WHERE cmc_id = NEW.cmi_cmc_id;
    IF c.cmc_igr_id IS NOT NULL THEN
        RAISE EXCEPTION 'O comunicado de uma igreja é para os membros dessa igreja: não se escolhem outras igrejas';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM organizacao.igreja i WHERE i.igr_id = NEW.cmi_igr_id
                      AND (i.igr_dst_id = c.cmc_dst_id OR i.igr_ent_id = c.cmc_ent_id)) THEN
        RAISE EXCEPTION 'Esta igreja não é % que publica o comunicado',
            CASE WHEN c.cmc_dst_id IS NOT NULL THEN 'do distrito' ELSE 'da Associação/Missão' END
            USING COLUMN = 'cmi_igr_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_cmi_10_validar BEFORE INSERT OR UPDATE OF cmi_cmc_id, cmi_igr_id ON nucleo.comunicado_igreja
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_cmi_validar();

-- ---------------------------------------------------------------- segurança (gerada: gen.py)
ALTER TABLE nucleo.comunicado ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cmc_ler ON nucleo.comunicado FOR SELECT USING (nucleo.fn_comunicado_emissor(cmc_igr_id, cmc_dst_id, cmc_ent_id, 'nucleo.comunicado.ler') OR ('nucleo.comunicado.ler' LIKE '%.ler' AND cmc_estado = 'PUBLICADO' AND nucleo.fn_comunicado_para_mim(cmc_id)));
CREATE POLICY pol_cmc_criar ON nucleo.comunicado FOR INSERT WITH CHECK (nucleo.fn_comunicado_emissor(cmc_igr_id, cmc_dst_id, cmc_ent_id, 'nucleo.comunicado.criar') OR ('nucleo.comunicado.criar' LIKE '%.ler' AND cmc_estado = 'PUBLICADO' AND nucleo.fn_comunicado_para_mim(cmc_id)));
CREATE POLICY pol_cmc_alterar ON nucleo.comunicado FOR UPDATE USING (nucleo.fn_comunicado_emissor(cmc_igr_id, cmc_dst_id, cmc_ent_id, 'nucleo.comunicado.alterar') OR ('nucleo.comunicado.alterar' LIKE '%.ler' AND cmc_estado = 'PUBLICADO' AND nucleo.fn_comunicado_para_mim(cmc_id))) WITH CHECK (nucleo.fn_comunicado_emissor(cmc_igr_id, cmc_dst_id, cmc_ent_id, 'nucleo.comunicado.alterar') OR ('nucleo.comunicado.alterar' LIKE '%.ler' AND cmc_estado = 'PUBLICADO' AND nucleo.fn_comunicado_para_mim(cmc_id)));
ALTER TABLE nucleo.comunicado_igreja ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cmi_ler ON nucleo.comunicado_igreja FOR SELECT USING (EXISTS (SELECT 1 FROM nucleo.comunicado c WHERE c.cmc_id = cmi_cmc_id AND nucleo.fn_comunicado_emissor(c.cmc_igr_id, c.cmc_dst_id, c.cmc_ent_id, 'nucleo.comunicado_igreja.ler')));
CREATE POLICY pol_cmi_criar ON nucleo.comunicado_igreja FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM nucleo.comunicado c WHERE c.cmc_id = cmi_cmc_id AND nucleo.fn_comunicado_emissor(c.cmc_igr_id, c.cmc_dst_id, c.cmc_ent_id, 'nucleo.comunicado_igreja.criar')));
CREATE POLICY pol_cmi_alterar ON nucleo.comunicado_igreja FOR UPDATE USING (EXISTS (SELECT 1 FROM nucleo.comunicado c WHERE c.cmc_id = cmi_cmc_id AND nucleo.fn_comunicado_emissor(c.cmc_igr_id, c.cmc_dst_id, c.cmc_ent_id, 'nucleo.comunicado_igreja.alterar'))) WITH CHECK (EXISTS (SELECT 1 FROM nucleo.comunicado c WHERE c.cmc_id = cmi_cmc_id AND nucleo.fn_comunicado_emissor(c.cmc_igr_id, c.cmc_dst_id, c.cmc_ent_id, 'nucleo.comunicado_igreja.alterar')));
GRANT SELECT, INSERT, UPDATE ON nucleo.comunicado, nucleo.comunicado_igreja TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA nucleo TO app_igreja;

-- ---------------------------------------------------------------- permissões
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('nucleo.comunicado.ler', 'Ler: Comunicados e anúncios'),
  ('nucleo.comunicado.criar', 'Criar: Comunicados e anúncios'),
  ('nucleo.comunicado.alterar', 'Alterar: Comunicados e anúncios'),
  ('nucleo.comunicado.terminar', 'Terminar (end_date): Comunicados e anúncios'),
  ('nucleo.comunicado_igreja.ler', 'Ler: Igrejas destinatárias de um comunicado'),
  ('nucleo.comunicado_igreja.criar', 'Criar: Igrejas destinatárias de um comunicado'),
  ('nucleo.comunicado_igreja.alterar', 'Alterar: Igrejas destinatárias de um comunicado'),
  ('nucleo.comunicado_igreja.terminar', 'Terminar (end_date): Igrejas destinatárias de um comunicado');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pf.per_id, pm.prm_id
  FROM nucleo.perfil pf, nucleo.permissao pm
 WHERE pm.prm_codigo LIKE 'nucleo.comunicado%'
   AND ((pf.per_codigo IN ('ADMIN', 'PASTOR', 'ANCIAO', 'SECRETARIO', 'ADMIN_ASSOCIACAO', 'SECRETARIO_ASSOCIACAO'))
        OR (pf.per_codigo IN ('TESOUREIRO', 'DIRECTOR_ES', 'SECRETARIO_ES', 'DIRECTOR_DEPARTAMENTO', 'TESOUREIRO_ASSOCIACAO')
            AND pm.prm_codigo LIKE '%.ler'));

-- ---------------------------------------------------------------- directório: o distrito pastoral de cada igreja (no fim)
CREATE OR REPLACE VIEW organizacao.vw_directorio_igrejas AS
SELECT i.igr_id, i.igr_nome AS nome, i.igr_tipo AS tipo, i.igr_ent_id, e.ent_nome AS entidade,
       p.prv_nome AS provincia, d.dad_nome AS distrito, i.igr_localidade AS localidade,
       i.igr_dst_id
FROM organizacao.igreja i
JOIN organizacao.entidade e ON e.ent_id = i.igr_ent_id
LEFT JOIN organizacao.provincia p ON p.prv_id = i.igr_prv_id
LEFT JOIN organizacao.distrito_administrativo d ON d.dad_id = i.igr_dad_id
WHERE i.igr_end_date IS NULL AND nucleo.fn_usuario_sessao() IS NOT NULL;

-- >>>>> V38__painel_por_periodo.sql
-- =====================================================================
-- V38 · Dashboard geral por período (F-ORG, P-13): membros activos e inactivos, dízimos, ofertas, obra de
--       reavivamento, fidelidade contributiva e movimento de membros, igreja a igreja
--
--   fundo        novo tipo REAVIVAMENTO: fundo próprio da igreja (100% da igreja) para a obra de reavivamento, com
--                alvo anual (V36: +5%). Assim soma-se e compara-se entre igrejas.
--   período      organizacao.fn_painel_periodo(início, fim): uma linha por igreja visível (RLS), no período escolhido:
--                  membros        estado ACTIVO no livro;
--                  inactivos      membros sem presença na ES nem contribuição há 6 meses (V36); activos = o resto;
--                  dízimos        entradas confirmadas no fundo DIZIMO (também as pagas directamente na Missão);
--                  ofertas        as outras entradas confirmadas, menos o reavivamento (sem estornos);
--                  reavivamento   entradas no fundo REAVIVAMENTO;
--                  contribuintes  membros ACTIVO que contribuíram (eles ou a família) no período: fidelidade =
--                                 contribuintes / membros;
--                  entradas e perdas de membros no livro (baptismo, profissão de fé, transferência; transferência,
--                  falecimento, remoção, desaparecido).
--                SECURITY INVOKER: cada número só conta o que o utilizador pode ler (ve_membros, ve_tesouraria dizem
--                se pode, para o ecrã mostrar "sem acesso" em vez de zero).
--   mensal       vw_painel_igrejas_mensal ganha as ofertas e o reavivamento (colunas no fim).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- O valor novo não se usa nesta transacção (só como texto): o db-migrar aplica cada migração numa transacção.
ALTER TYPE nucleo.tipo_fundo_t ADD VALUE IF NOT EXISTS 'REAVIVAMENTO';

ALTER TABLE tesouraria.fundo DROP CONSTRAINT chk_fun_da_igreja;
ALTER TABLE tesouraria.fundo ADD CONSTRAINT chk_fun_da_igreja
    CHECK (fun_igr_id IS NULL OR (fun_percentagem_remessa = 0 AND fun_destino_ent_id IS NULL
                                  AND fun_tipo::TEXT IN ('OFERTA_ESPECIAL', 'PROJECTO', 'REAVIVAMENTO')));
COMMENT ON CONSTRAINT chk_fun_da_igreja ON tesouraria.fundo IS
    '[tipo] Um fundo próprio da igreja é uma oferta especial, um projecto ou a obra de reavivamento, e fica todo na igreja.';

-- ---------------------------------------------------------------- painel por período
CREATE FUNCTION organizacao.fn_painel_periodo(p_inicio DATE, p_fim DATE)
RETURNS TABLE (igr_id INT, nome TEXT, entidade_id INT, entidade TEXT, distrito_pastoral_id INT, distrito_pastoral TEXT,
               ve_membros BOOLEAN, ve_tesouraria BOOLEAN,
               membros INT, activos INT, inactivos INT, interessados INT,
               dizimos DECIMAL(14,2), ofertas DECIMAL(14,2), reavivamento DECIMAL(14,2), contribuintes INT,
               entradas_membros INT, perdas_membros INT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH per AS (
        SELECT (p_inicio::timestamp AT TIME ZONE 'Africa/Maputo') AS de,
               ((p_fim + 1)::timestamp AT TIME ZONE 'Africa/Maputo') AS ate
    ),
    acesso AS (
        SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.ler')   AS membros,
               nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler') AS tesouraria
    ),
    mem AS (
        SELECT m.mem_igr_id AS igr_id,
               count(*) FILTER (WHERE m.mem_estado = 'ACTIVO')      AS membros,
               count(*) FILTER (WHERE m.mem_estado = 'INTERESSADO') AS interessados
          FROM secretaria.membro m WHERE m.mem_end_date IS NULL GROUP BY 1
    ),
    linhas AS (
        SELECT t.tra_igr_id AS igr_id, t.tra_mem_id, t.tra_fam_id, f.fun_tipo::TEXT AS tipo, l.tli_valor AS valor
          FROM tesouraria.transacao t
          JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
          JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id, per
         WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
           AND t.tra_data_hora >= per.de AND t.tra_data_hora < per.ate
    ),
    din AS (
        SELECT igr_id,
               sum(valor) FILTER (WHERE tipo = 'DIZIMO') AS dizimos,
               sum(valor) FILTER (WHERE tipo NOT IN ('DIZIMO', 'REAVIVAMENTO')) AS ofertas,
               sum(valor) FILTER (WHERE tipo = 'REAVIVAMENTO') AS reavivamento
          FROM linhas GROUP BY 1
    ),
    contrib AS (
        SELECT m.mem_igr_id AS igr_id, count(DISTINCT m.mem_id) AS contribuintes
          FROM secretaria.membro m
         WHERE m.mem_end_date IS NULL AND m.mem_estado = 'ACTIVO'
           AND EXISTS (SELECT 1 FROM linhas x WHERE x.tra_mem_id = m.mem_id OR (m.mem_fam_id IS NOT NULL AND x.tra_fam_id = m.mem_fam_id))
         GROUP BY 1
    ),
    livro AS (
        SELECT l.mmb_igr_id AS igr_id,
               count(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA')) AS entradas,
               count(*) FILTER (WHERE l.mmb_tipo IN ('TRANSFERENCIA_SAIDA', 'FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS perdas
          FROM secretaria.movimento_membro l
         WHERE l.mmb_end_date IS NULL AND l.mmb_data BETWEEN p_inicio AND p_fim
         GROUP BY 1
    )
    SELECT i.igr_id, i.igr_nome::TEXT, i.igr_ent_id, e.ent_nome::TEXT, i.igr_dst_id, d.dst_nome::TEXT,
           i.igr_id = ANY (a.membros), i.igr_id = ANY (a.tesouraria),
           coalesce(m.membros, 0)::INT,
           (coalesce(m.membros, 0) - coalesce(ina.n, 0))::INT,
           coalesce(ina.n, 0)::INT,
           coalesce(m.interessados, 0)::INT,
           coalesce(dn.dizimos, 0)::DECIMAL(14,2), coalesce(dn.ofertas, 0)::DECIMAL(14,2), coalesce(dn.reavivamento, 0)::DECIMAL(14,2),
           coalesce(c.contribuintes, 0)::INT,
           coalesce(lv.entradas, 0)::INT, coalesce(lv.perdas, 0)::INT
      FROM organizacao.igreja i
      CROSS JOIN acesso a
      JOIN organizacao.entidade e ON e.ent_id = i.igr_ent_id
      LEFT JOIN organizacao.distrito d ON d.dst_id = i.igr_dst_id
      LEFT JOIN mem m ON m.igr_id = i.igr_id
      LEFT JOIN din dn ON dn.igr_id = i.igr_id
      LEFT JOIN contrib c ON c.igr_id = i.igr_id
      LEFT JOIN livro lv ON lv.igr_id = i.igr_id
      LEFT JOIN LATERAL (SELECT count(*) AS n FROM secretaria.fn_participacao_membros(i.igr_id) p WHERE p.inactivo) ina ON i.igr_id = ANY (a.membros)
     WHERE i.igr_end_date IS NULL
     ORDER BY i.igr_nome
$$;
COMMENT ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) IS
    'V38: dashboard por igreja visível no período (membros, activos, inactivos, dízimos, ofertas, reavivamento, contribuintes, entradas e perdas)';
REVOKE ALL ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses: também ofertas e reavivamento
CREATE OR REPLACE VIEW organizacao.vw_painel_igrejas_mensal WITH (security_invoker = true) AS
WITH meses AS (
    SELECT g::date AS ini, (g + INTERVAL '1 month')::date AS fim,
           EXTRACT(YEAR FROM g)::INT AS ano, EXTRACT(MONTH FROM g)::INT AS mes
    FROM generate_series(date_trunc('month', now() AT TIME ZONE 'Africa/Maputo') - INTERVAL '11 months',
                         date_trunc('month', now() AT TIME ZONE 'Africa/Maputo'), INTERVAL '1 month') g
),
desde AS (SELECT (MIN(ini)::timestamp AT TIME ZONE 'Africa/Maputo') AS t, MIN(ini) AS d FROM meses),
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
fundos AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimos,
           COUNT(DISTINCT t.tra_mem_id) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimistas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT NOT IN ('DIZIMO', 'REAVIVAMENTO')) AS ofertas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'REAVIVAMENTO') AS reavivamento
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id, EXTRACT(YEAR FROM l.mmb_data)::INT AS ano, EXTRACT(MONTH FROM l.mmb_data)::INT AS mes,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transf_entrada,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transf_saida
    FROM secretaria.movimento_membro l, desde
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= desde.d
    GROUP BY 1, 2, 3
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id, ms.ano, ms.mes,
       COALESCE(dn.entradas, 0) AS entradas, COALESCE(dn.saidas, 0) AS saidas,
       COALESCE(z.dizimos, 0) AS dizimos, COALESCE(z.dizimistas, 0) AS dizimistas,
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida,
       COALESCE(z.ofertas, 0) AS ofertas, COALESCE(z.reavivamento, 0) AS reavivamento
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN fundos z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;

-- >>>>> V39__santa_ceia.sql
-- =====================================================================
-- V39 · Santa Ceia (F-ACT): agendamento e participantes
--
--   santa_ceia   igreja, data, hora, local, responsável (quem oficia), observações; depois de realizada, os
--                participantes: homens, mulheres e visitantes. Estado AGENDADA, REALIZADA ou CANCELADA.
--   regras       uma Santa Ceia por igreja e dia; números não negativos e obrigatórios quando REALIZADA;
--                não se marca como realizada uma data futura; o responsável é membro da igreja.
--   histórico    actividades.vw_santa_ceia: cada celebração com o total de participantes (para o Início, o painel
--                e a comparação entre igrejas).
--
-- Permissões novas (actividades.santa_ceia.*): gerem ADMIN, PASTOR, ANCIAO e SECRETARIO; lêem DIRECTOR_DEPARTAMENTO e
-- ADMIN_ASSOCIACAO. Gerado com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TYPE nucleo.estado_santa_ceia_t AS ENUM ('AGENDADA', 'REALIZADA', 'CANCELADA');

-- ---------------------------------------------------------------- tabela (gerada: gen.py)
CREATE TABLE actividades.santa_ceia (
    stc_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    stc_igr_id INT NOT NULL,
    stc_data DATE NOT NULL,
    stc_hora VARCHAR(5),
    stc_local VARCHAR(150),
    stc_responsavel_mem_id INT,
    stc_observacoes VARCHAR(500),
    stc_homens SMALLINT,
    stc_mulheres SMALLINT,
    stc_visitantes SMALLINT,
    stc_estado estado_santa_ceia_t NOT NULL DEFAULT 'AGENDADA',
    stc_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    stc_criado_por INT,
    stc_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    stc_modificado_por INT,
    stc_end_date TIMESTAMPTZ,
    CONSTRAINT fk_stc_igr_id FOREIGN KEY (stc_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_stc_responsavel_mem_id FOREIGN KEY (stc_responsavel_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_stc_numeros CHECK (coalesce(stc_homens, 0) >= 0 AND coalesce(stc_mulheres, 0) >= 0 AND coalesce(stc_visitantes, 0) >= 0),
    CONSTRAINT chk_stc_hora CHECK (stc_hora IS NULL OR stc_hora ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
    CONSTRAINT chk_stc_realizada CHECK (stc_estado <> 'REALIZADA' OR (stc_homens IS NOT NULL AND stc_mulheres IS NOT NULL AND stc_visitantes IS NOT NULL)),
    CONSTRAINT chk_stc_end_date CHECK (stc_end_date IS NULL OR stc_end_date >= stc_criado_em)
);
COMMENT ON TABLE actividades.santa_ceia IS 'Santa Ceia: agendamento (data, hora, local, responsável) e participantes depois de realizada (V39)';
COMMENT ON COLUMN actividades.santa_ceia.stc_hora IS 'Hora (hh:mm)';
COMMENT ON COLUMN actividades.santa_ceia.stc_responsavel_mem_id IS 'Quem oficia (pastor ou ancião)';
COMMENT ON COLUMN actividades.santa_ceia.stc_homens IS 'Participantes: homens (depois de realizada)';
COMMENT ON COLUMN actividades.santa_ceia.stc_mulheres IS 'Participantes: mulheres';
COMMENT ON COLUMN actividades.santa_ceia.stc_visitantes IS 'Participantes: visitantes';
CREATE UNIQUE INDEX uq_stc_igr_id_data ON actividades.santa_ceia (stc_igr_id, stc_data) WHERE stc_end_date IS NULL;
CREATE INDEX idx_stc_responsavel_mem_id ON actividades.santa_ceia (stc_responsavel_mem_id);

CREATE TRIGGER trg_stc_00_padrao BEFORE INSERT OR UPDATE ON actividades.santa_ceia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('stc', 'actividades.santa_ceia', 'stc_igr_id');
CREATE TRIGGER trg_stc_00_sem_delete BEFORE DELETE ON actividades.santa_ceia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('stc');
CREATE TRIGGER trg_stc_00_sem_truncate BEFORE TRUNCATE ON actividades.santa_ceia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('stc');
CREATE TRIGGER trg_stc_99_log AFTER UPDATE ON actividades.santa_ceia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('stc');
ALTER TABLE actividades.santa_ceia ADD CONSTRAINT fk_stc_criado_por FOREIGN KEY (stc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.santa_ceia ADD CONSTRAINT fk_stc_modificado_por FOREIGN KEY (stc_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE actividades.santa_ceia ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_stc_ler ON actividades.santa_ceia FOR SELECT USING (stc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia.ler'))::INT[]));
CREATE POLICY pol_stc_criar ON actividades.santa_ceia FOR INSERT WITH CHECK (stc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia.criar'))::INT[]));
CREATE POLICY pol_stc_alterar ON actividades.santa_ceia FOR UPDATE USING (stc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia.alterar'))::INT[])) WITH CHECK (stc_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON actividades.santa_ceia TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
CREATE INDEX idx_stc_igr_pagina ON actividades.santa_ceia (stc_igr_id, stc_id);

COMMENT ON CONSTRAINT chk_stc_numeros ON actividades.santa_ceia IS 'Os números de participantes não podem ser negativos.';
COMMENT ON CONSTRAINT chk_stc_hora ON actividades.santa_ceia IS '[hora] Escreva a hora como hh:mm (ex.: 09:30).';
COMMENT ON CONSTRAINT chk_stc_realizada ON actividades.santa_ceia IS '[homens] Para marcar como realizada, indique os homens, as mulheres e os visitantes.';
COMMENT ON INDEX actividades.uq_stc_igr_id_data IS '[data] Já há uma Santa Ceia nesta igreja neste dia.';

-- ---------------------------------------------------------------- permissões
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('actividades.santa_ceia.ler', 'Ler: Santa Ceia (agendamento e participantes)'),
  ('actividades.santa_ceia.criar', 'Criar: Santa Ceia (agendamento e participantes)'),
  ('actividades.santa_ceia.alterar', 'Alterar: Santa Ceia (agendamento e participantes)'),
  ('actividades.santa_ceia.terminar', 'Terminar (end_date): Santa Ceia (agendamento e participantes)');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pf.per_id, pm.prm_id
  FROM nucleo.perfil pf, nucleo.permissao pm
 WHERE pm.prm_codigo LIKE 'actividades.santa_ceia.%'
   AND (pf.per_codigo IN ('ADMIN', 'PASTOR', 'ANCIAO', 'SECRETARIO')
        OR (pf.per_codigo IN ('DIRECTOR_DEPARTAMENTO', 'ADMIN_ASSOCIACAO') AND pm.prm_codigo LIKE '%.ler'));

-- ---------------------------------------------------------------- regras
CREATE FUNCTION actividades.fn_stc_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.stc_estado = 'REALIZADA' AND NEW.stc_data > (now() AT TIME ZONE 'Africa/Maputo')::DATE THEN
        RAISE EXCEPTION 'Só se marca como realizada depois do dia da Santa Ceia' USING COLUMN = 'stc_estado';
    END IF;
    IF NEW.stc_responsavel_mem_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.stc_responsavel_mem_id IS DISTINCT FROM OLD.stc_responsavel_mem_id)
       AND NOT EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = NEW.stc_responsavel_mem_id AND m.mem_igr_id = NEW.stc_igr_id) THEN
        RAISE EXCEPTION 'O responsável tem de ser membro desta igreja' USING COLUMN = 'stc_responsavel_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_stc_10_validar BEFORE INSERT OR UPDATE ON actividades.santa_ceia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_stc_validar();

-- ---------------------------------------------------------------- histórico
CREATE VIEW actividades.vw_santa_ceia WITH (security_invoker = true) AS
SELECT s.stc_id, s.stc_igr_id AS igreja_id, i.igr_nome AS igreja, s.stc_data AS data, s.stc_hora AS hora, s.stc_local AS local,
       s.stc_estado AS estado, EXTRACT(YEAR FROM s.stc_data)::INT AS ano,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = s.stc_responsavel_mem_id) AS responsavel,
       s.stc_homens AS homens, s.stc_mulheres AS mulheres, s.stc_visitantes AS visitantes,
       (coalesce(s.stc_homens, 0) + coalesce(s.stc_mulheres, 0) + coalesce(s.stc_visitantes, 0))::INT AS total
  FROM actividades.santa_ceia s
  JOIN organizacao.igreja i ON i.igr_id = s.stc_igr_id
 WHERE s.stc_end_date IS NULL;
COMMENT ON VIEW actividades.vw_santa_ceia IS 'V39: celebrações da Santa Ceia com os participantes (cada um só vê as igrejas que pode ler)';
GRANT SELECT ON actividades.vw_santa_ceia TO app_igreja;

-- >>>>> V40__parentesco_na_familia.sql
-- =====================================================================
-- V40 · Relações familiares (F-SEC-03): o parentesco de cada membro com o chefe da família
--
--   membro.mem_parentesco   CHEFE, CONJUGE, FILHO, PAI_MAE, IRMAO, NETO ou OUTRO; só para quem está numa família;
--                           um só chefe por família. Ao mudar de família (ou sair), o parentesco antigo é limpo.
--   vw_membro_basico        ganha o parentesco (no fim), para a ficha da família.
--
-- As permissões não mudam: quem altera o membro altera o parentesco. Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE secretaria.membro ADD COLUMN mem_parentesco VARCHAR(10);
ALTER TABLE secretaria.membro ADD CONSTRAINT chk_mem_parentesco
    CHECK (mem_parentesco IS NULL OR (mem_fam_id IS NOT NULL AND mem_parentesco IN ('CHEFE', 'CONJUGE', 'FILHO', 'PAI_MAE', 'IRMAO', 'NETO', 'OUTRO')));
COMMENT ON COLUMN secretaria.membro.mem_parentesco IS 'Relação com o chefe da família: CHEFE, CONJUGE, FILHO, PAI_MAE, IRMAO, NETO, OUTRO (V40)';
COMMENT ON CONSTRAINT chk_mem_parentesco ON secretaria.membro IS '[parentesco] O parentesco só existe para quem está numa família (chefe, cônjuge, filho, pai/mãe, irmão, neto ou outro).';
CREATE UNIQUE INDEX uq_mem_chefe_familia ON secretaria.membro (mem_fam_id) WHERE mem_parentesco = 'CHEFE' AND mem_end_date IS NULL;
COMMENT ON INDEX secretaria.uq_mem_chefe_familia IS '[parentesco] Esta família já tem chefe: mude primeiro o parentesco do actual.';

-- mudar de família (ou sair dela) limpa o parentesco, que era em relação ao chefe da outra família
CREATE FUNCTION secretaria.fn_mem_parentesco() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.mem_fam_id IS DISTINCT FROM OLD.mem_fam_id AND NEW.mem_parentesco IS NOT DISTINCT FROM OLD.mem_parentesco THEN
        NEW.mem_parentesco := NULL;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_mem_12_parentesco BEFORE UPDATE OF mem_fam_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_parentesco();

CREATE OR REPLACE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado,
       mem_estado_civil, mem_data_nascimento, mem_conjuge_mem_id, mem_parentesco
FROM secretaria.membro WHERE mem_end_date IS NULL;

-- >>>>> V41__disciplina_confidencial_e_acessos.sql
-- =====================================================================
-- V41 · Disciplina eclesiástica (F-SEC-07, P-03): motivo confidencial com auditoria de acessos
--
--   motivo        secretaria.disciplina.dsc_motivo deixa de ser legível directamente (como o hash das senhas):
--                 grava-se como antes, mas lê-se só por secretaria.fn_disciplina_motivo(id), que confirma a permissão
--                 (secretaria.disciplina.ler na igreja do membro) e regista a consulta.
--   acessos       nucleo.acesso_confidencial (tabela nova, escrita só pelo sistema): quem consultou que dado
--                 confidencial e quando. Lêem-na o pastor e a administração da Associação.
--   histórico     o log de auditoria (fn_log_auditoria) já guardava as alterações da disciplina; passa a guardar só que o
--                 motivo mudou, sem o texto (e os registos antigos são limpos), como as senhas.
--
-- Gerado com database/gerador (defs.py: tabela acesso_confidencial, SO_ESCRITA = dsc_motivo); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- tabela nucleo.acesso_confidencial (gerada: gen.py)
CREATE TABLE nucleo.acesso_confidencial (
    aco_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    aco_usu_id INT,
    aco_igr_id INT NOT NULL,
    aco_tabela VARCHAR(80) NOT NULL,
    aco_registo_id BIGINT NOT NULL,
    aco_accao VARCHAR(20) NOT NULL,
    aco_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    aco_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    aco_criado_por INT,
    aco_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    aco_modificado_por INT,
    aco_end_date TIMESTAMPTZ,
    CONSTRAINT fk_aco_usu_id FOREIGN KEY (aco_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT fk_aco_igr_id FOREIGN KEY (aco_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_aco_end_date CHECK (aco_end_date IS NULL OR aco_end_date >= aco_criado_em)
);
COMMENT ON TABLE nucleo.acesso_confidencial IS 'Consultas a dados confidenciais (ex.: o motivo de uma censura): quem, quando, que registo (V41)';
COMMENT ON COLUMN nucleo.acesso_confidencial.aco_accao IS 'Ex.: LER_MOTIVO';
CREATE INDEX idx_aco_usu_id ON nucleo.acesso_confidencial (aco_usu_id);
CREATE INDEX idx_aco_igr_pagina ON nucleo.acesso_confidencial (aco_igr_id, aco_id);
CREATE INDEX idx_aco_igr_data ON nucleo.acesso_confidencial (aco_igr_id, aco_criado_em DESC);

CREATE TRIGGER trg_aco_00_padrao BEFORE INSERT OR UPDATE ON nucleo.acesso_confidencial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('aco', '', 'aco_igr_id');
CREATE TRIGGER trg_aco_00_sem_delete BEFORE DELETE ON nucleo.acesso_confidencial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('aco');
CREATE TRIGGER trg_aco_00_sem_truncate BEFORE TRUNCATE ON nucleo.acesso_confidencial FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('aco');
CREATE TRIGGER trg_aco_99_log AFTER UPDATE ON nucleo.acesso_confidencial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('aco');
ALTER TABLE nucleo.acesso_confidencial ADD CONSTRAINT fk_aco_criado_por FOREIGN KEY (aco_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.acesso_confidencial ADD CONSTRAINT fk_aco_modificado_por FOREIGN KEY (aco_modificado_por) REFERENCES nucleo.usuario(usu_id);

GRANT SELECT ON nucleo.acesso_confidencial TO app_igreja;              -- escrita só pelo sistema
ALTER TABLE nucleo.acesso_confidencial ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_aco_ler ON nucleo.acesso_confidencial FOR SELECT USING (aco_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('nucleo.acesso_confidencial.ler'))::INT[]));

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('nucleo.acesso_confidencial.ler', 'Ler: consultas a dados confidenciais (quem, quando, que registo)'),
  ('nucleo.acesso_confidencial.criar', 'Criar: consultas a dados confidenciais (só o sistema)'),
  ('nucleo.acesso_confidencial.alterar', 'Alterar: consultas a dados confidenciais (só o sistema)'),
  ('nucleo.acesso_confidencial.terminar', 'Terminar (end_date): consultas a dados confidenciais (só o sistema)');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pf.per_id, pm.prm_id FROM nucleo.perfil pf, nucleo.permissao pm
 WHERE pm.prm_codigo = 'nucleo.acesso_confidencial.ler' AND pf.per_codigo IN ('PASTOR', 'ADMIN_ASSOCIACAO');

-- ---------------------------------------------------------------- o motivo da censura deixa de ser legível directamente
REVOKE SELECT ON secretaria.disciplina FROM app_igreja;
GRANT SELECT (dsc_id, dsc_mem_id, dsc_vot_id, dsc_data_inicio, dsc_data_fim, dsc_encarregado_notificado, dsc_estado,
              dsc_criado_em, dsc_criado_por, dsc_modificado_em, dsc_modificado_por, dsc_end_date) ON secretaria.disciplina TO app_igreja;
COMMENT ON COLUMN secretaria.disciplina.dsc_motivo IS
    'Dado sensível: grava-se como as outras colunas, mas lê-se só por secretaria.fn_disciplina_motivo (o acesso fica registado) (V41)';

CREATE FUNCTION secretaria.fn_disciplina_motivo(p_dsc INT) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_igr    INT;
    v_motivo TEXT;
BEGIN
    SELECT m.mem_igr_id, d.dsc_motivo INTO v_igr, v_motivo
      FROM secretaria.disciplina d JOIN secretaria.membro m ON m.mem_id = d.dsc_mem_id
     WHERE d.dsc_id = p_dsc;
    -- não existe, ou existe mas não é visível: a mesma resposta (a API devolve 404)
    IF v_igr IS NULL OR NOT (v_igr = ANY (nucleo.fn_igrejas_com_permissao('secretaria.disciplina.ler'))) THEN
        RAISE EXCEPTION 'Registo de disciplina não encontrado' USING ERRCODE = 'no_data_found';
    END IF;
    INSERT INTO nucleo.acesso_confidencial (aco_usu_id, aco_igr_id, aco_tabela, aco_registo_id, aco_accao)
    VALUES (nucleo.fn_usuario_sessao(), v_igr, 'secretaria.disciplina', p_dsc, 'LER_MOTIVO');
    RETURN v_motivo;
END $$;
COMMENT ON FUNCTION secretaria.fn_disciplina_motivo(INT) IS
    'V41: o motivo de uma censura, só para quem lê a disciplina na igreja do membro; cada consulta fica em nucleo.acesso_confidencial';
REVOKE ALL ON FUNCTION secretaria.fn_disciplina_motivo(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION secretaria.fn_disciplina_motivo(INT) TO app_igreja;

-- ---------------------------------------------------------------- o histórico não guarda o texto do motivo
CREATE OR REPLACE FUNCTION nucleo.fn_log_auditoria() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    p      TEXT  := TG_ARGV[0];
    n      JSONB := to_jsonb(NEW);
    o      JSONB;
    antes  JSONB := NULL;
    depois JSONB := n;
    accao  TEXT  := TG_OP;
    k      TEXT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        o := to_jsonb(OLD);
        SELECT jsonb_object_agg(x, o -> x), jsonb_object_agg(x, n -> x)
          INTO antes, depois
          FROM jsonb_object_keys(n) x
         WHERE (o -> x) IS DISTINCT FROM (n -> x)
           AND x NOT IN (p || '_modificado_em', p || '_modificado_por');
        IF depois IS NULL THEN
            RETURN NULL;                              -- nada mudou de facto
        END IF;
        IF o ->> (p || '_end_date') IS NULL AND n ->> (p || '_end_date') IS NOT NULL THEN
            accao := 'TERMINO';
        END IF;
        IF current_setting('app.anonimizacao', true) = 'on' THEN
            antes := NULL;                            -- dados pessoais apagados: não ficam no histórico (V15)
        END IF;
    END IF;
    -- hashes de senhas e dados confidenciais nunca ficam no histórico: fica só a indicação de que mudaram (V16, V41)
    FOREACH k IN ARRAY ARRAY[p || '_senha_hash', 'dsc_motivo'] LOOP
        IF depois ? k THEN
            depois := jsonb_set(depois, ARRAY[k], CASE WHEN k = 'dsc_motivo' THEN '"(confidencial: alterado)"' ELSE '"(alterada)"' END::JSONB);
        END IF;
        IF antes ? k THEN
            antes := antes - k;
        END IF;
    END LOOP;
    INSERT INTO nucleo.log_auditoria (lau_usu_id, lau_tabela, lau_registo_id, lau_accao, lau_dados_antes, lau_dados_depois)
    VALUES (nucleo.fn_usuario_sessao(), TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            (n ->> (p || '_id'))::BIGINT, accao, antes, depois);
    RETURN NULL;
END $$;

-- limpar os motivos que já estão no log (o log é imutável: o trigger que o protege é desligado só aqui)
DO $$
DECLARE t regclass;
BEGIN
    FOR t IN SELECT 'nucleo.log_auditoria'::regclass
             UNION ALL SELECT inhrelid::regclass FROM pg_inherits WHERE inhparent = 'nucleo.log_auditoria'::regclass LOOP
        EXECUTE format('ALTER TABLE %s DISABLE TRIGGER trg_lau_00_imutavel', t);
    END LOOP;
    UPDATE nucleo.log_auditoria
       SET lau_dados_antes  = lau_dados_antes - 'dsc_motivo',
           lau_dados_depois = CASE WHEN lau_dados_depois ? 'dsc_motivo'
                                   THEN jsonb_set(lau_dados_depois, '{dsc_motivo}', '"(confidencial: alterado)"')
                                   ELSE lau_dados_depois END
     WHERE lau_tabela = 'secretaria.disciplina'
       AND (lau_dados_antes ? 'dsc_motivo' OR lau_dados_depois ? 'dsc_motivo');
    FOR t IN SELECT 'nucleo.log_auditoria'::regclass
             UNION ALL SELECT inhrelid::regclass FROM pg_inherits WHERE inhparent = 'nucleo.log_auditoria'::regclass LOOP
        EXECUTE format('ALTER TABLE %s ENABLE TRIGGER trg_lau_00_imutavel', t);
    END LOOP;
END $$;

-- >>>>> V42__tesouraria_maneio_contagem_e_sms.sql
-- =====================================================================
-- V42 · Tesouraria (F-TES): fundo de maneio, participantes da contagem e SMS com o resumo da contribuição
--
--   fundo de maneio   novo tipo de conta FUNDO_MANEIO (dinheiro à mão para despesas urgentes): valor inicial
--                     (saldo inicial), reposições (transferência de outra conta), despesas (saídas, com quem as fez e os
--                     comprovativos), saldo e histórico como qualquer conta; nunca é conta da Missão.
--   contagem          tesouraria.contagem_participante: quem participou na contagem e com que função (tesoureiro,
--                     Escola Sabatina, diácono, ancião, outro), além dos dois contadores; membro da igreja da contagem.
--   SMS               ao emitir o recibo, a mensagem leva o resumo por fundo (ex.: Dízimo 1 000,00; Oferta 500,00) e uma
--                     chave por recibo: a mesma contribuição nunca gera dois SMS (falhas de comunicação repetem o envio da
--                     fila, não o registo financeiro). Continua a exigir o consentimento do membro.
--
-- Permissões novas (tesouraria.contagem_participante.*): as mesmas das contagens. Gerado com database/gerador.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TYPE nucleo.tipo_conta_t ADD VALUE IF NOT EXISTS 'FUNDO_MANEIO';

-- o fundo de maneio, como o caixa, é dinheiro da igreja: nunca uma conta da Missão (compara como texto: o valor novo
-- não se usa na mesma transacção em que é criado)
CREATE OR REPLACE FUNCTION tesouraria.fn_cfi_validar() RETURNS trigger AS $$
BEGIN
    IF NEW.cfi_ent_id IS NOT NULL THEN
        IF NEW.cfi_tipo::TEXT IN ('CAIXA', 'FUNDO_MANEIO') THEN
            RAISE EXCEPTION 'Uma conta da Missão é uma conta bancária ou de carteira móvel, não um caixa nem um fundo de maneio';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM tesouraria.fundo WHERE fun_destino_ent_id = NEW.cfi_ent_id AND fun_end_date IS NULL) THEN
            RAISE EXCEPTION 'A entidade % não recebe nenhum fundo: não pode ter uma conta da Missão', NEW.cfi_ent_id;
        END IF;
    END IF;
    IF TG_OP = 'UPDATE' AND NEW.cfi_ent_id IS DISTINCT FROM OLD.cfi_ent_id
       AND EXISTS (SELECT 1 FROM tesouraria.transacao WHERE tra_cfi_id = NEW.cfi_id OR tra_destino_cfi_id = NEW.cfi_id) THEN
        RAISE EXCEPTION 'A conta "%" já tem movimentos: não pode passar a ser (ou deixar de ser) uma conta da Missão', NEW.cfi_nome;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------- participantes da contagem (gerada: gen.py)
CREATE TABLE tesouraria.contagem_participante (
    cpa_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cpa_cnu_id INT NOT NULL,
    cpa_mem_id INT NOT NULL,
    cpa_funcao VARCHAR(20) NOT NULL,
    cpa_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    cpa_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cpa_criado_por INT,
    cpa_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    cpa_modificado_por INT,
    cpa_end_date TIMESTAMPTZ,
    CONSTRAINT fk_cpa_cnu_id FOREIGN KEY (cpa_cnu_id) REFERENCES tesouraria.contagem_numerario(cnu_id),
    CONSTRAINT fk_cpa_mem_id FOREIGN KEY (cpa_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_cpa_funcao CHECK (cpa_funcao IN ('TESOUREIRO', 'ESCOLA_SABATINA', 'DIACONO', 'ANCIAO', 'OUTRO')),
    CONSTRAINT chk_cpa_end_date CHECK (cpa_end_date IS NULL OR cpa_end_date >= cpa_criado_em)
);
COMMENT ON TABLE tesouraria.contagem_participante IS 'Quem participou na contagem do numerário e com que função (tesoureiro, Escola Sabatina, diácono, ancião) (V42)';
COMMENT ON COLUMN tesouraria.contagem_participante.cpa_funcao IS 'TESOUREIRO, ESCOLA_SABATINA, DIACONO, ANCIAO ou OUTRO';
CREATE UNIQUE INDEX uq_cpa_cnu_id_mem_id ON tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id) WHERE cpa_end_date IS NULL;
CREATE INDEX idx_cpa_mem_id ON tesouraria.contagem_participante (cpa_mem_id);

CREATE TRIGGER trg_cpa_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.contagem_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cpa', 'tesouraria.contagem_participante', '');
CREATE TRIGGER trg_cpa_00_sem_delete BEFORE DELETE ON tesouraria.contagem_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cpa');
CREATE TRIGGER trg_cpa_00_sem_truncate BEFORE TRUNCATE ON tesouraria.contagem_participante FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cpa');
CREATE TRIGGER trg_cpa_99_log AFTER UPDATE ON tesouraria.contagem_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cpa');
ALTER TABLE tesouraria.contagem_participante ADD CONSTRAINT fk_cpa_criado_por FOREIGN KEY (cpa_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.contagem_participante ADD CONSTRAINT fk_cpa_modificado_por FOREIGN KEY (cpa_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE tesouraria.contagem_participante ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_cpa_ler ON tesouraria.contagem_participante FOR SELECT USING (EXISTS (SELECT 1 FROM tesouraria.contagem_numerario x WHERE x.cnu_id = cpa_cnu_id AND x.cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_participante.ler'))::INT[])));
CREATE POLICY pol_cpa_criar ON tesouraria.contagem_participante FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.contagem_numerario x WHERE x.cnu_id = cpa_cnu_id AND x.cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_participante.criar'))::INT[])));
CREATE POLICY pol_cpa_alterar ON tesouraria.contagem_participante FOR UPDATE USING (EXISTS (SELECT 1 FROM tesouraria.contagem_numerario x WHERE x.cnu_id = cpa_cnu_id AND x.cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_participante.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM tesouraria.contagem_numerario x WHERE x.cnu_id = cpa_cnu_id AND x.cnu_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_participante.alterar'))::INT[])));
GRANT SELECT, INSERT, UPDATE ON tesouraria.contagem_participante TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
COMMENT ON CONSTRAINT chk_cpa_funcao ON tesouraria.contagem_participante IS '[funcao] A função é tesoureiro, Escola Sabatina, diácono, ancião ou outro.';
COMMENT ON INDEX tesouraria.uq_cpa_cnu_id_mem_id IS '[membroId] Este membro já está nesta contagem.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('tesouraria.contagem_participante.ler', 'Ler: participantes da contagem do numerário'),
  ('tesouraria.contagem_participante.criar', 'Criar: participantes da contagem do numerário'),
  ('tesouraria.contagem_participante.alterar', 'Alterar: participantes da contagem do numerário'),
  ('tesouraria.contagem_participante.terminar', 'Terminar (end_date): participantes da contagem do numerário');
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'tesouraria.contagem_numerario.%'
  JOIN nucleo.permissao novo   ON novo.prm_codigo = replace(antigo.prm_codigo, 'tesouraria.contagem_numerario.', 'tesouraria.contagem_participante.')
 WHERE pp.ppe_end_date IS NULL;

-- o participante é membro da igreja da contagem (corre com os direitos do dono: quem não vê a contagem recebe a recusa
-- da RLS, "sem permissão", e não esta mensagem)
CREATE FUNCTION tesouraria.fn_cpa_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tesouraria.contagem_numerario c JOIN secretaria.membro m ON m.mem_igr_id = c.cnu_igr_id
                    WHERE c.cnu_id = NEW.cpa_cnu_id AND m.mem_id = NEW.cpa_mem_id) THEN
        RAISE EXCEPTION 'O participante tem de ser membro da igreja da contagem' USING COLUMN = 'cpa_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_cpa_10_validar BEFORE INSERT OR UPDATE OF cpa_cnu_id, cpa_mem_id ON tesouraria.contagem_participante
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cpa_validar();

-- ---------------------------------------------------------------- dinheiro em texto: "1 400,00" (sem depender da língua do servidor)
CREATE FUNCTION nucleo.fn_texto_mt(p NUMERIC) RETURNS TEXT
LANGUAGE sql IMMUTABLE
AS $$ SELECT translate(regexp_replace(to_char(p, 'FM999999999990.00'), '([0-9])(?=([0-9]{3})+[.])', '\1 ', 'g'), '.', ',') $$;
GRANT EXECUTE ON FUNCTION nucleo.fn_texto_mt(NUMERIC) TO app_igreja;

-- ---------------------------------------------------------------- SMS do recibo: o resumo por fundo, uma vez por recibo
CREATE OR REPLACE FUNCTION nucleo.fn_rec_notificar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_mem    INT;
    v_valor  NUMERIC;
    v_igreja TEXT;
    v_resumo TEXT;
    c        secretaria.contacto%ROWTYPE;
    v_canal  nucleo.canal_notificacao_t;
BEGIN
    SELECT t.tra_mem_id, t.tra_valor_total, i.igr_nome INTO v_mem, v_valor, v_igreja
      FROM tesouraria.transacao t JOIN organizacao.igreja i ON i.igr_id = t.tra_igr_id
     WHERE t.tra_id = NEW.rec_tra_id;
    IF v_mem IS NULL THEN RETURN NULL; END IF;

    SELECT * INTO c FROM secretaria.contacto
     WHERE cto_mem_id = v_mem AND cto_end_date IS NULL AND cto_estado = 'ACTIVO'
       AND cto_tipo::TEXT IN ('WHATSAPP', 'TELEFONE', 'EMAIL')
     ORDER BY cto_principal DESC, cto_id LIMIT 1;
    IF NOT FOUND THEN RETURN NULL; END IF;

    v_canal := CASE c.cto_tipo::TEXT WHEN 'WHATSAPP' THEN 'WHATSAPP' WHEN 'EMAIL' THEN 'EMAIL' ELSE 'SMS' END;
    IF NOT EXISTS (SELECT 1 FROM secretaria.consentimento
                    WHERE cns_mem_id = v_mem AND cns_end_date IS NULL AND cns_concedido
                      AND cns_tipo = ('CONTACTO_' || v_canal)::nucleo.tipo_consentimento_t) THEN
        RETURN NULL;
    END IF;

    -- o resumo por fundo (os 4 maiores), ex.: "Dízimo 1 000,00; Oferta 500,00"
    SELECT string_agg(x.nome || ' ' || nucleo.fn_texto_mt(x.valor), '; ' ORDER BY x.valor DESC)
      INTO v_resumo
      FROM (SELECT f.fun_nome AS nome, sum(l.tli_valor) AS valor
              FROM tesouraria.transacao_linha l JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id
             WHERE l.tli_tra_id = NEW.rec_tra_id AND l.tli_end_date IS NULL
             GROUP BY f.fun_nome ORDER BY sum(l.tli_valor) DESC LIMIT 4) x;

    INSERT INTO nucleo.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                    ntf_origem_tabela, ntf_origem_id, ntf_chave)
    VALUES (NEW.rec_igr_id, v_mem, v_canal, c.cto_valor, 'Recibo ' || NEW.rec_numero || '/' || NEW.rec_ano,
            v_igreja || ': recebemos a sua contribuição de ' || nucleo.fn_texto_mt(v_valor) || ' MT'
            || coalesce(' (' || v_resumo || ')', '') || '. Recibo n.º ' || NEW.rec_numero || '/' || NEW.rec_ano || '. Deus o abençoe.',
            'tesouraria.recibo', NEW.rec_id, 'recibo:' || NEW.rec_id)
    ON CONFLICT (ntf_chave) WHERE ntf_end_date IS NULL DO NOTHING;
    RETURN NULL;
END $$;

-- >>>>> V43__membro_unico_e_contagem_minima.sql
-- =====================================================================
-- V43 · Membro único (F-SEC-01, 4.4 e 18) e contagem com o mínimo de participantes (F-TES, 14.4)
--
--   membro       Antes de registar procura-se o membro em TODAS as igrejas, não só nas que o utilizador vê:
--                nucleo.fn_membro_existente (SECURITY DEFINER) devolve o mesmo membro já registado — mesmo número de
--                documento, ou o mesmo nome completo com a mesma data de nascimento. Das igrejas que o utilizador não
--                vê só diz o nome e a igreja (para pedir a transferência), nunca a ficha.
--                A base de dados recusa um segundo registo nesses casos (trigger trg_mem_05_unico, ao registar e ao
--                mudar o nome, a data de nascimento ou o documento). Nome só parecido continua a ser aviso: quem tem
--                permissão para registar confere e confirma (nada se bloqueia só pela semelhança do nome).
--                Os registos que já existam em duplicado não são tocados (o trigger só olha para o que muda).
--   contagem     Para conferir uma contagem, tem de ter pelo menos o tesoureiro, um representante da Escola Sabatina
--                e um diácono (o ancião é opcional). Depois de conferida, os participantes ficam como estavam.
--   reuniões     O ponto da agenda ganha a discussão (rpt_discussao), separada da descrição (rpt_detalhes) (17.3).
--                Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- nome comparável: minúsculas, sem acentos nem espaços a mais
CREATE FUNCTION nucleo.fn_nome_comparavel(p TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
    SELECT nullif(regexp_replace(trim(translate(lower(coalesce(p, '')),
                  'áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn')), '\s+', ' ', 'g'), '')
$$;
COMMENT ON FUNCTION nucleo.fn_nome_comparavel(TEXT) IS 'Nome para comparar: minúsculas, sem acentos, um espaço entre palavras (V43)';

-- ---------------------------------------------------------------- o mesmo membro já registado (em qualquer igreja)
CREATE FUNCTION nucleo.fn_membro_existente(p_nome TEXT, p_apelido TEXT, p_data_nascimento DATE DEFAULT NULL,
                                           p_numero_identificacao TEXT DEFAULT NULL, p_excluir_mem_id INT DEFAULT NULL)
RETURNS TABLE (mem_id INT, igr_id INT, igreja TEXT, nome TEXT, motivo TEXT, visivel BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH p AS (
        SELECT nullif(upper(regexp_replace(coalesce(p_numero_identificacao, ''), '[^A-Za-z0-9]', '', 'g')), '') AS doc,
               nucleo.fn_nome_comparavel(coalesce(p_nome, '') || ' ' || coalesce(p_apelido, '')) AS nome,
               coalesce(nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'), '{}') AS vejo
    ), achados AS (
        -- mesmo documento (5 caracteres ou mais, escrito de qualquer forma)
        SELECT m.mem_id, 'Mesmo número de documento'::TEXT AS motivo
          FROM secretaria.membro m, p
         WHERE p.doc IS NOT NULL AND length(p.doc) >= 5 AND m.mem_end_date IS NULL AND m.mem_numero_identificacao IS NOT NULL
           AND upper(regexp_replace(m.mem_numero_identificacao::TEXT, '[^A-Za-z0-9]', '', 'g')) = p.doc
        UNION
        -- mesmo nome completo e mesma data de nascimento
        SELECT m.mem_id, 'Mesmo nome e data de nascimento'
          FROM secretaria.membro m, p
         WHERE p_data_nascimento IS NOT NULL AND p.nome IS NOT NULL AND m.mem_end_date IS NULL
           AND m.mem_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento
           AND nucleo.fn_nome_comparavel(m.mem_nome || ' ' || m.mem_apelido) = p.nome
    )
    SELECT CASE WHEN m.mem_igr_id = ANY (p.vejo) THEN m.mem_id END, m.mem_igr_id, i.igr_nome::TEXT,
           (m.mem_nome || ' ' || m.mem_apelido)::TEXT, string_agg(a.motivo, '; ' ORDER BY a.motivo), m.mem_igr_id = ANY (p.vejo)
      FROM achados a
      JOIN secretaria.membro m ON m.mem_id = a.mem_id
      JOIN organizacao.igreja i ON i.igr_id = m.mem_igr_id
     CROSS JOIN p
     WHERE m.mem_id IS DISTINCT FROM p_excluir_mem_id
     GROUP BY m.mem_id, m.mem_igr_id, i.igr_nome, m.mem_nome, m.mem_apelido, p.vejo
     ORDER BY m.mem_apelido, m.mem_nome
     LIMIT 5
$$;
COMMENT ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) IS
    'O mesmo membro já registado em qualquer igreja (mesmo documento, ou mesmo nome e data de nascimento); das igrejas que o utilizador não vê só o nome e a igreja (V43)';
REVOKE ALL ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) TO app_igreja;

-- ---------------------------------------------------------------- recusa o segundo registo da mesma pessoa
CREATE FUNCTION secretaria.fn_mem_unico() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    r RECORD;
BEGIN
    IF NEW.mem_end_date IS NOT NULL THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND NEW.mem_nome IS NOT DISTINCT FROM OLD.mem_nome AND NEW.mem_apelido IS NOT DISTINCT FROM OLD.mem_apelido
       AND NEW.mem_data_nascimento IS NOT DISTINCT FROM OLD.mem_data_nascimento
       AND NEW.mem_numero_identificacao IS NOT DISTINCT FROM OLD.mem_numero_identificacao
       AND OLD.mem_end_date IS NULL THEN
        RETURN NEW;
    END IF;
    SELECT * INTO r FROM nucleo.fn_membro_existente(NEW.mem_nome, NEW.mem_apelido, NEW.mem_data_nascimento,
                                                    NEW.mem_numero_identificacao, NEW.mem_id) LIMIT 1;
    IF FOUND THEN
        RAISE EXCEPTION 'Este membro já existe: % (%), com o %. Abra o registo existente%.', r.nome, r.igreja, lower(r.motivo),
              CASE WHEN r.igr_id = NEW.mem_igr_id THEN '' ELSE ' ou peça a transferência a essa igreja' END
              USING COLUMN = CASE WHEN r.motivo LIKE 'Mesmo número%' THEN 'mem_numero_identificacao' ELSE 'mem_nome' END;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_mem_05_unico BEFORE INSERT OR UPDATE OF mem_nome, mem_apelido, mem_data_nascimento, mem_numero_identificacao, mem_end_date
    ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_unico();

-- ---------------------------------------------------------------- contagem: tesoureiro, Escola Sabatina e diácono para conferir
CREATE FUNCTION tesouraria.fn_cnu_participantes_minimos() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_falta TEXT;
BEGIN
    IF NEW.cnu_estado::TEXT = 'CONFERIDA' AND OLD.cnu_estado::TEXT = 'ABERTA' THEN
        SELECT string_agg(f.rotulo, ', ' ORDER BY f.ordem) INTO v_falta
          FROM (VALUES (1, 'TESOUREIRO', 'o tesoureiro'), (2, 'ESCOLA_SABATINA', 'o representante da Escola Sabatina'),
                       (3, 'DIACONO', 'o diácono')) AS f(ordem, funcao, rotulo)
         WHERE NOT EXISTS (SELECT 1 FROM tesouraria.contagem_participante p
                            WHERE p.cpa_cnu_id = NEW.cnu_id AND p.cpa_funcao = f.funcao AND p.cpa_end_date IS NULL);
        IF v_falta IS NOT NULL THEN
            RAISE EXCEPTION 'Para conferir, a contagem tem de ter pelo menos o tesoureiro, o representante da Escola Sabatina e o diácono. Falta: %.', v_falta;
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_cnu_20_participantes BEFORE UPDATE OF cnu_estado ON tesouraria.contagem_numerario
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cnu_participantes_minimos();

-- depois de conferida (ou depositada), os participantes não mudam: ficam no histórico como estavam
CREATE OR REPLACE FUNCTION tesouraria.fn_cpa_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tesouraria.contagem_numerario c JOIN secretaria.membro m ON m.mem_igr_id = c.cnu_igr_id
                    WHERE c.cnu_id = NEW.cpa_cnu_id AND m.mem_id = NEW.cpa_mem_id) THEN
        RAISE EXCEPTION 'O participante tem de ser membro da igreja da contagem' USING COLUMN = 'cpa_mem_id';
    END IF;
    IF EXISTS (SELECT 1 FROM tesouraria.contagem_numerario c WHERE c.cnu_id = NEW.cpa_cnu_id AND c.cnu_estado::TEXT <> 'ABERTA') THEN
        RAISE EXCEPTION 'A contagem já foi conferida: os participantes ficam como estavam';
    END IF;
    RETURN NEW;
END $$;
DROP TRIGGER trg_cpa_10_validar ON tesouraria.contagem_participante;
CREATE TRIGGER trg_cpa_10_validar BEFORE INSERT OR UPDATE ON tesouraria.contagem_participante
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cpa_validar();

-- ---------------------------------------------------------------- reuniões: a discussão de cada ponto (17.3)
ALTER TABLE secretaria.reuniao_ponto ADD COLUMN rpt_discussao TEXT;
COMMENT ON COLUMN secretaria.reuniao_ponto.rpt_discussao IS 'Resumo da discussão do ponto (o que se disse); a descrição fica em detalhes (V43)';

-- >>>>> V44__escala_do_culto_e_programacao_do_dia.sql
-- =====================================================================
-- V44 · Escala com as funções da programação do culto e a programação do dia (F-ACT)
--
--   escala        funções novas, com os nomes da programação: apresentador da Escola Sabatina, apresentador do culto,
--                 Sermão da criança, oração inicial, oração final, apresentador e meditação da JA (o pregador é o
--                 "Sermão principal"); o dia da escala ganha a família responsável pela Escola Sabatina (eds_fam_id).
--   programação   actividades.programa_dia (um por igreja e dia), programa_parte (Escola Sabatina, Transição, Culto
--                 Divino, JA…, com o apresentador) e programa_item (horas, actividade, responsável: membro, família,
--                 departamento ou texto, e destaque). Partes e itens podem estar ligados a uma função da escala
--                 (escala = PREGADOR, TRADUTOR, FAMILIA_ES…): actividades.fn_programa_preencher põe lá quem está
--                 escalado nesse dia. actividades.fn_programa_preparar cria a programação de um dia a partir do
--                 modelo (como a folha da igreja) ou copiando outro dia, e preenche-a pela escala.
--
-- Permissões novas (actividades.programa_dia/parte/item.*): as mesmas da escala (actividades.escala_plano.*).
-- Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- escala: funções da programação do culto
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_ES';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_CULTO';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'SERMAO_CRIANCA';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ORACAO_INICIAL';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ORACAO_FINAL';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_JA';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'MEDITACAO_JA';

-- nome de cada função nos lembretes por SMS (compara como texto: os valores novos são desta transacção)
CREATE OR REPLACE FUNCTION actividades.fn_funcao_escala_nome(p_funcao nucleo.funcao_escala_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_funcao::text
        WHEN 'PREGADOR' THEN 'pregador(a) do Sermão principal'
        WHEN 'ANCIAO_DO_DIA' THEN 'ancião do dia'
        WHEN 'DIACONO' THEN 'diácono'
        WHEN 'DIACONISA' THEN 'diaconisa'
        WHEN 'RECEPCAO' THEN 'recepção'
        WHEN 'MUSICA' THEN 'música'
        WHEN 'SONOPLASTIA' THEN 'sonoplastia'
        WHEN 'PROFESSOR_ES' THEN 'professor(a) da Escola Sabatina'
        WHEN 'DIRECTOR_ES' THEN 'director(a) da Escola Sabatina'
        WHEN 'LIMPEZA' THEN 'limpeza'
        WHEN 'TRADUTOR' THEN 'tradutor(a)'
        WHEN 'ACOMPANHANTE_VISITAS' THEN 'acompanhante (visitas e 2.ª oração)'
        WHEN 'ACOMPANHANTE_OFERTAS' THEN 'acompanhante (dízimos e ofertas)'
        WHEN 'ACOMPANHANTE_BOAS_VINDAS' THEN 'acompanhante (boas-vindas e 1.ª oração)'
        WHEN 'APRESENTADOR_ES' THEN 'apresentador(a) da Escola Sabatina'
        WHEN 'APRESENTADOR_CULTO' THEN 'apresentador(a) do Culto Divino'
        WHEN 'SERMAO_CRIANCA' THEN 'responsável pelo Sermão da criança'
        WHEN 'ORACAO_INICIAL' THEN 'oração inicial do culto'
        WHEN 'ORACAO_FINAL' THEN 'oração final do culto'
        WHEN 'APRESENTADOR_JA' THEN 'apresentador(a) da JA'
        WHEN 'MEDITACAO_JA' THEN 'meditação da JA'
        ELSE 'serviço' END;
$$;

-- o dia da escala: a família que faz a programação da Escola Sabatina
ALTER TABLE actividades.escala_dia ADD COLUMN eds_fam_id INT;
ALTER TABLE actividades.escala_dia ADD CONSTRAINT fk_eds_fam_id FOREIGN KEY (eds_fam_id) REFERENCES secretaria.familia(fam_id);
COMMENT ON COLUMN actividades.escala_dia.eds_fam_id IS 'Família responsável pela programação da Escola Sabatina (V44)';
CREATE INDEX idx_eds_fam_id ON actividades.escala_dia (eds_fam_id);

CREATE FUNCTION actividades.fn_eds_familia() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.eds_fam_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM secretaria.familia f JOIN actividades.escala_plano p ON p.epl_id = NEW.eds_epl_id
         WHERE f.fam_id = NEW.eds_fam_id AND f.fam_igr_id = p.epl_igr_id) THEN
        RAISE EXCEPTION 'A família tem de ser da igreja da escala' USING COLUMN = 'eds_fam_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_eds_10_familia BEFORE INSERT OR UPDATE OF eds_fam_id ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_familia();

-- ---------------------------------------------------------------- programação do dia (gerada: gen.py)
CREATE TABLE actividades.programa_dia (
    pgd_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pgd_igr_id INT NOT NULL,
    pgd_data DATE NOT NULL,
    pgd_titulo VARCHAR(150),
    pgd_observacoes VARCHAR(500),
    pgd_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pgd_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pgd_criado_por INT,
    pgd_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pgd_modificado_por INT,
    pgd_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pgd_igr_id FOREIGN KEY (pgd_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_pgd_end_date CHECK (pgd_end_date IS NULL OR pgd_end_date >= pgd_criado_em)
);

COMMENT ON COLUMN actividades.programa_dia.pgd_titulo IS 'Título da folha; por defeito, a data por extenso';
COMMENT ON COLUMN actividades.programa_dia.pgd_observacoes IS 'Nota no fim da folha (ex.: passível de ajustes e simplificação)';
CREATE UNIQUE INDEX uq_pgd_igr_id_data ON actividades.programa_dia (pgd_igr_id, pgd_data) WHERE pgd_end_date IS NULL;

CREATE TABLE actividades.programa_parte (
    ppa_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ppa_pgd_id INT NOT NULL,
    ppa_ordem SMALLINT NOT NULL DEFAULT 1,
    ppa_titulo VARCHAR(100) NOT NULL,
    ppa_rotulo VARCHAR(30) NOT NULL DEFAULT 'Apresentador',
    ppa_apresentador_mem_id INT,
    ppa_apresentador_fam_id INT,
    ppa_apresentador_texto VARCHAR(150),
    ppa_escala VARCHAR(20),
    ppa_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ppa_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppa_criado_por INT,
    ppa_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppa_modificado_por INT,
    ppa_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ppa_pgd_id FOREIGN KEY (ppa_pgd_id) REFERENCES actividades.programa_dia(pgd_id),
    CONSTRAINT fk_ppa_apresentador_mem_id FOREIGN KEY (ppa_apresentador_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_ppa_apresentador_fam_id FOREIGN KEY (ppa_apresentador_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT chk_ppa_apresentador CHECK (num_nonnulls(ppa_apresentador_mem_id, ppa_apresentador_fam_id, ppa_apresentador_texto) <= 1),
    CONSTRAINT chk_ppa_escala CHECK (ppa_escala IS NULL OR ppa_escala IN ('APRESENTADOR_ES', 'APRESENTADOR_CULTO', 'PREGADOR', 'TRADUTOR', 'SERMAO_CRIANCA', 'ORACAO_INICIAL', 'ORACAO_FINAL', 'APRESENTADOR_JA', 'MEDITACAO_JA', 'FAMILIA_ES')),
    CONSTRAINT chk_ppa_end_date CHECK (ppa_end_date IS NULL OR ppa_end_date >= ppa_criado_em)
);

COMMENT ON COLUMN actividades.programa_parte.ppa_titulo IS 'Ex.: Programação do Culto Divino';
COMMENT ON COLUMN actividades.programa_parte.ppa_rotulo IS 'Cabeçalho da coluna do apresentador (ex.: Apresentador, Transição)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_mem_id IS 'Apresentador (membro)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_fam_id IS 'Apresentador (família, ex.: Família Magaia)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_texto IS 'Apresentador escrito (visitante, grupo)';
COMMENT ON COLUMN actividades.programa_parte.ppa_escala IS 'Função da escala que preenche o apresentador (ex.: APRESENTADOR_CULTO, FAMILIA_ES)';
CREATE INDEX idx_ppa_pgd_id ON actividades.programa_parte (ppa_pgd_id);
CREATE INDEX idx_ppa_apresentador_mem_id ON actividades.programa_parte (ppa_apresentador_mem_id);
CREATE INDEX idx_ppa_apresentador_fam_id ON actividades.programa_parte (ppa_apresentador_fam_id);

CREATE TABLE actividades.programa_item (
    pit_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pit_pgd_id INT NOT NULL,
    pit_ppa_id INT NOT NULL,
    pit_ordem SMALLINT NOT NULL DEFAULT 1,
    pit_hora_inicio VARCHAR(5),
    pit_hora_fim VARCHAR(5),
    pit_actividade VARCHAR(200) NOT NULL,
    pit_responsavel_mem_id INT,
    pit_responsavel_fam_id INT,
    pit_responsavel_ide_id INT,
    pit_responsavel_texto VARCHAR(150),
    pit_escala VARCHAR(20),
    pit_destaque BOOLEAN NOT NULL DEFAULT FALSE,
    pit_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pit_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pit_criado_por INT,
    pit_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pit_modificado_por INT,
    pit_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pit_pgd_id FOREIGN KEY (pit_pgd_id) REFERENCES actividades.programa_dia(pgd_id),
    CONSTRAINT fk_pit_ppa_id FOREIGN KEY (pit_ppa_id) REFERENCES actividades.programa_parte(ppa_id),
    CONSTRAINT fk_pit_responsavel_mem_id FOREIGN KEY (pit_responsavel_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_pit_responsavel_fam_id FOREIGN KEY (pit_responsavel_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT fk_pit_responsavel_ide_id FOREIGN KEY (pit_responsavel_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT chk_pit_responsavel CHECK (num_nonnulls(pit_responsavel_mem_id, pit_responsavel_fam_id, pit_responsavel_ide_id, pit_responsavel_texto) <= 1),
    CONSTRAINT chk_pit_horas CHECK ((pit_hora_inicio IS NULL OR pit_hora_inicio ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') AND (pit_hora_fim IS NULL OR pit_hora_fim ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')),
    CONSTRAINT chk_pit_escala CHECK (pit_escala IS NULL OR pit_escala IN ('APRESENTADOR_ES', 'APRESENTADOR_CULTO', 'PREGADOR', 'TRADUTOR', 'SERMAO_CRIANCA', 'ORACAO_INICIAL', 'ORACAO_FINAL', 'APRESENTADOR_JA', 'MEDITACAO_JA', 'FAMILIA_ES')),
    CONSTRAINT chk_pit_end_date CHECK (pit_end_date IS NULL OR pit_end_date >= pit_criado_em)
);

COMMENT ON COLUMN actividades.programa_item.pit_hora_inicio IS 'Hora (hh:mm)';
COMMENT ON COLUMN actividades.programa_item.pit_hora_fim IS 'Hora (hh:mm)';
COMMENT ON COLUMN actividades.programa_item.pit_actividade IS 'Ex.: Hino inicial (H.A 509)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_mem_id IS 'Responsável (membro)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_fam_id IS 'Responsável (família)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_ide_id IS 'Responsável (departamento, ex.: Mulher Adventista)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_texto IS 'Responsável escrito (ex.: Todos, Diáconos, Monitores, um visitante)';
COMMENT ON COLUMN actividades.programa_item.pit_escala IS 'Função da escala que preenche o responsável (ex.: PREGADOR, TRADUTOR, FAMILIA_ES)';
COMMENT ON COLUMN actividades.programa_item.pit_destaque IS 'Linha em destaque na folha (ex.: Sermão principal)';
CREATE INDEX idx_pit_pgd_id ON actividades.programa_item (pit_pgd_id);
CREATE INDEX idx_pit_ppa_id ON actividades.programa_item (pit_ppa_id);
CREATE INDEX idx_pit_responsavel_mem_id ON actividades.programa_item (pit_responsavel_mem_id);
CREATE INDEX idx_pit_responsavel_fam_id ON actividades.programa_item (pit_responsavel_fam_id);
CREATE INDEX idx_pit_responsavel_ide_id ON actividades.programa_item (pit_responsavel_ide_id);

CREATE TRIGGER trg_pgd_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pgd', 'actividades.programa_dia', 'pgd_igr_id');
CREATE TRIGGER trg_pgd_00_sem_delete BEFORE DELETE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pgd');
CREATE TRIGGER trg_pgd_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_dia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pgd');
CREATE TRIGGER trg_pgd_99_log AFTER UPDATE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pgd');
ALTER TABLE actividades.programa_dia ADD CONSTRAINT fk_pgd_criado_por FOREIGN KEY (pgd_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_dia ADD CONSTRAINT fk_pgd_modificado_por FOREIGN KEY (pgd_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_ppa_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ppa', 'actividades.programa_parte', '');
CREATE TRIGGER trg_ppa_00_sem_delete BEFORE DELETE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ppa');
CREATE TRIGGER trg_ppa_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_parte FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ppa');
CREATE TRIGGER trg_ppa_99_log AFTER UPDATE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ppa');
ALTER TABLE actividades.programa_parte ADD CONSTRAINT fk_ppa_criado_por FOREIGN KEY (ppa_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_parte ADD CONSTRAINT fk_ppa_modificado_por FOREIGN KEY (ppa_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_pit_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pit', 'actividades.programa_item', '');
CREATE TRIGGER trg_pit_00_sem_delete BEFORE DELETE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pit');
CREATE TRIGGER trg_pit_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_item FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pit');
CREATE TRIGGER trg_pit_99_log AFTER UPDATE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pit');
ALTER TABLE actividades.programa_item ADD CONSTRAINT fk_pit_criado_por FOREIGN KEY (pit_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_item ADD CONSTRAINT fk_pit_modificado_por FOREIGN KEY (pit_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE actividades.programa_dia ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pgd_ler ON actividades.programa_dia FOR SELECT USING (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.ler'))::INT[]));
CREATE POLICY pol_pgd_criar ON actividades.programa_dia FOR INSERT WITH CHECK (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.criar'))::INT[]));
CREATE POLICY pol_pgd_alterar ON actividades.programa_dia FOR UPDATE USING (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.alterar'))::INT[])) WITH CHECK (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.alterar'))::INT[]));
ALTER TABLE actividades.programa_parte ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ppa_ler ON actividades.programa_parte FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.ler'))::INT[])));
CREATE POLICY pol_ppa_criar ON actividades.programa_parte FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.criar'))::INT[])));
CREATE POLICY pol_ppa_alterar ON actividades.programa_parte FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.alterar'))::INT[])));
ALTER TABLE actividades.programa_item ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pit_ler ON actividades.programa_item FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.ler'))::INT[])));
CREATE POLICY pol_pit_criar ON actividades.programa_item FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.criar'))::INT[])));
CREATE POLICY pol_pit_alterar ON actividades.programa_item FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.alterar'))::INT[])));

COMMENT ON TABLE actividades.programa_dia IS 'Programação do dia (ex.: sábado): as partes e os itens com horas e responsáveis, para imprimir (V44)';
COMMENT ON TABLE actividades.programa_parte IS 'Parte da programação do dia (ex.: Programação da Escola Sabatina, Transição, Culto Divino, JA) e o apresentador (V44)';
COMMENT ON TABLE actividades.programa_item IS 'Item da programação do dia: horas, actividade e responsável (membro, família, departamento ou texto) (V44)';
GRANT SELECT, INSERT, UPDATE ON actividades.programa_dia, actividades.programa_parte, actividades.programa_item TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
COMMENT ON INDEX actividades.uq_pgd_igr_id_data IS '[data] Já há uma programação desta igreja para este dia.';
COMMENT ON CONSTRAINT chk_ppa_apresentador ON actividades.programa_parte IS '[apresentadorMembroId] Indique só um apresentador: um membro, uma família ou o nome escrito.';
COMMENT ON CONSTRAINT chk_ppa_escala ON actividades.programa_parte IS '[escala] Função da escala desconhecida.';
COMMENT ON CONSTRAINT chk_pit_responsavel ON actividades.programa_item IS '[responsavelMembroId] Indique só um responsável: um membro, uma família, um departamento ou o nome escrito.';
COMMENT ON CONSTRAINT chk_pit_horas ON actividades.programa_item IS '[horaInicio] Escreva as horas como hh:mm (ex.: 10:30).';
COMMENT ON CONSTRAINT chk_pit_escala ON actividades.programa_item IS '[escala] Função da escala desconhecida.';

-- permissões: as mesmas da escala
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'actividades.' || t.tabela || '.' || a.accao, a.rotulo || t.descricao
  FROM (VALUES ('programa_dia', 'Programação do dia (ex.: sábado): as partes e os itens com horas e responsáveis, para imprimir (V44)'),
               ('programa_parte', 'Parte da programação do dia (ex.: Programação da Escola Sabatina, Transição, Culto Divino, JA) e o apresentador (V44)'),
               ('programa_item', 'Item da programação do dia: horas, actividade e responsável (membro, família, departamento ou texto) (V44)')) t(tabela, descricao),
       (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.escala_plano.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo IN (replace(antigo.prm_codigo, 'escala_plano', 'programa_dia'),
                                                    replace(antigo.prm_codigo, 'escala_plano', 'programa_parte'),
                                                    replace(antigo.prm_codigo, 'escala_plano', 'programa_item'))
 WHERE pp.ppe_end_date IS NULL;

-- o item pertence a uma parte do mesmo dia
CREATE FUNCTION actividades.fn_pit_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM actividades.programa_parte WHERE ppa_id = NEW.pit_ppa_id AND ppa_pgd_id = NEW.pit_pgd_id) THEN
        RAISE EXCEPTION 'A parte não é desta programação' USING COLUMN = 'pit_ppa_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_pit_10_validar BEFORE INSERT OR UPDATE OF pit_pgd_id, pit_ppa_id ON actividades.programa_item
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_pit_validar();

-- ---------------------------------------------------------------- preencher pela escala do dia
-- Partes e itens com "escala" recebem quem está escalado nessa função nesse dia (o substituto, se houver); com
-- FAMILIA_ES, a família do dia da escala. Sem ninguém escalado, fica o que lá estava. Devolve quantos mudaram.
CREATE FUNCTION actividades.fn_programa_preencher(p_pgd INT) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_igr  INT;
    v_data DATE;
    v_fam  INT;
    v_n    INT := 0;
    v_k    INT;
BEGIN
    SELECT pgd_igr_id, pgd_data INTO v_igr, v_data FROM actividades.programa_dia WHERE pgd_id = p_pgd AND pgd_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Programação % não encontrada', p_pgd USING ERRCODE = 'P0002'; END IF;

    SELECT d.eds_fam_id INTO v_fam
      FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
     WHERE p.epl_igr_id = v_igr AND d.eds_data = v_data AND d.eds_end_date IS NULL AND p.epl_end_date IS NULL
       AND d.eds_fam_id IS NOT NULL
     ORDER BY p.epl_publicada DESC, d.eds_id DESC LIMIT 1;

    -- quem está escalado em cada função nesse dia (o substituto, se houver; o primeiro, se houver mais de um)
    UPDATE actividades.programa_parte x
       SET ppa_apresentador_mem_id = t.mem_id, ppa_apresentador_fam_id = NULL, ppa_apresentador_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.ppa_pgd_id = p_pgd AND x.ppa_end_date IS NULL AND x.ppa_escala = t.funcao
       AND x.ppa_apresentador_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    UPDATE actividades.programa_item x
       SET pit_responsavel_mem_id = t.mem_id, pit_responsavel_fam_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.pit_pgd_id = p_pgd AND x.pit_end_date IS NULL AND x.pit_escala = t.funcao
       AND x.pit_responsavel_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;

    IF v_fam IS NOT NULL THEN
        UPDATE actividades.programa_parte
           SET ppa_apresentador_fam_id = v_fam, ppa_apresentador_mem_id = NULL, ppa_apresentador_texto = NULL
         WHERE ppa_pgd_id = p_pgd AND ppa_end_date IS NULL AND ppa_escala = 'FAMILIA_ES' AND ppa_apresentador_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
        UPDATE actividades.programa_item
           SET pit_responsavel_fam_id = v_fam, pit_responsavel_mem_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
         WHERE pit_pgd_id = p_pgd AND pit_end_date IS NULL AND pit_escala = 'FAMILIA_ES' AND pit_responsavel_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    END IF;
    RETURN v_n;
END $$;
COMMENT ON FUNCTION actividades.fn_programa_preencher(INT) IS 'Põe nas partes e itens ligados à escala quem está escalado nesse dia (V44)';
GRANT EXECUTE ON FUNCTION actividades.fn_programa_preencher(INT) TO app_igreja;

-- ---------------------------------------------------------------- preparar a programação de um dia
-- A partir de outro dia (copia as partes e os itens) ou, sem origem, do modelo da folha da igreja (Escola Sabatina,
-- Transição, Culto Divino, JA); depois preenche pela escala. Corre com as permissões de quem pede (RLS).
CREATE FUNCTION actividades.fn_programa_preparar(p_igr INT, p_data DATE, p_origem INT DEFAULT NULL) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_pgd   INT;
    v_parte INT;
    r       RECORD;
BEGIN
    IF p_origem IS NOT NULL AND NOT EXISTS (SELECT 1 FROM actividades.programa_dia WHERE pgd_id = p_origem AND pgd_igr_id = p_igr AND pgd_end_date IS NULL) THEN
        RAISE EXCEPTION 'A programação a copiar não existe nesta igreja' USING COLUMN = 'pgd_id';
    END IF;
    INSERT INTO actividades.programa_dia (pgd_igr_id, pgd_data, pgd_observacoes)
    VALUES (p_igr, p_data, CASE WHEN p_origem IS NULL THEN 'Passível de ajustes e simplificação'
                                ELSE (SELECT pgd_observacoes FROM actividades.programa_dia WHERE pgd_id = p_origem) END)
    RETURNING pgd_id INTO v_pgd;

    IF p_origem IS NOT NULL THEN
        FOR r IN SELECT * FROM actividades.programa_parte WHERE ppa_pgd_id = p_origem AND ppa_end_date IS NULL ORDER BY ppa_ordem, ppa_id LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_apresentador_mem_id,
                                                   ppa_apresentador_fam_id, ppa_apresentador_texto, ppa_escala)
            VALUES (v_pgd, r.ppa_ordem, r.ppa_titulo, r.ppa_rotulo, r.ppa_apresentador_mem_id, r.ppa_apresentador_fam_id,
                    r.ppa_apresentador_texto, r.ppa_escala)
            RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_mem_id, pit_responsavel_fam_id, pit_responsavel_ide_id,
                                                   pit_responsavel_texto, pit_escala, pit_destaque)
            SELECT v_pgd, v_parte, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade, pit_responsavel_mem_id,
                   pit_responsavel_fam_id, pit_responsavel_ide_id, pit_responsavel_texto, pit_escala, pit_destaque
              FROM actividades.programa_item WHERE pit_ppa_id = r.ppa_id AND pit_end_date IS NULL;
        END LOOP;
    ELSE
        FOR r IN SELECT * FROM (VALUES
            (1, 'Programação da Escola Sabatina', 'Apresentador', 'FAMILIA_ES'),
            (2, 'Transição', 'Transição', NULL),
            (3, 'Programação do Culto Divino', 'Apresentador', 'APRESENTADOR_CULTO'),
            (4, 'JA', 'Apresentador', 'APRESENTADOR_JA')) AS m(ordem, titulo, rotulo, escala) LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_escala)
            VALUES (v_pgd, r.ordem, r.titulo, r.rotulo, r.escala) RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_texto, pit_escala, pit_destaque)
            SELECT v_pgd, v_parte, i.ordem, i.inicio, i.fim, i.actividade, i.texto, i.escala, i.destaque
              FROM (VALUES
                (1, 1, '08:50', '09:00', 'Momento de louvor', 'Todos', NULL, FALSE),
                (1, 2, '09:00', '09:05', 'Hino inicial', 'Todos', NULL, FALSE),
                (1, 3, '09:05', '09:10', 'Oração inicial', NULL, 'FAMILIA_ES', FALSE),
                (1, 4, '09:10', '09:15', 'Música especial', NULL, 'FAMILIA_ES', FALSE),
                (1, 5, '09:15', '09:25', '28 Crenças', NULL, 'FAMILIA_ES', FALSE),
                (1, 6, '09:25', '09:30', 'Carta missionária', NULL, 'FAMILIA_ES', FALSE),
                (1, 7, '09:30', '09:35', 'Capítulo do dia', NULL, 'FAMILIA_ES', FALSE),
                (1, 8, '09:35', '09:40', 'Momento de testemunho / gratidão', 'Todos', NULL, FALSE),
                (1, 9, '09:40', '10:15', 'Resumo das lições', 'Monitores', NULL, TRUE),
                (1, 10, NULL, NULL, 'Oração final', NULL, 'FAMILIA_ES', FALSE),
                (2, 1, '10:15', '10:20', 'Devolução de envelopes', 'Tesouraria', NULL, FALSE),
                (2, 2, '10:20', '10:25', 'Minuto saúde', NULL, NULL, FALSE),
                (2, 3, '10:25', '10:30', 'Momento de louvor', 'Departamento de Música', NULL, FALSE),
                (3, 1, '10:30', '10:35', 'Entrada da tribuna e doxologia', 'Todos', NULL, FALSE),
                (3, 2, '10:35', '10:40', 'Boas-vindas e anúncios', 'Secretaria', NULL, FALSE),
                (3, 3, '10:40', '10:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (3, 4, '10:45', '10:50', 'Oração inicial', NULL, 'ORACAO_INICIAL', FALSE),
                (3, 5, '10:50', '10:55', 'Marca de um mordomo', 'Tesouraria', NULL, FALSE),
                (3, 6, '10:55', '11:00', 'Música especial', NULL, NULL, FALSE),
                (3, 7, '11:00', '11:05', 'Recolha das ofertas e dízimos', 'Diáconos', NULL, FALSE),
                (3, 8, '11:05', '11:10', 'Sermão da criança', NULL, 'SERMAO_CRIANCA', FALSE),
                (3, 9, '11:15', '12:15', 'Sermão principal', NULL, 'PREGADOR', TRUE),
                (3, 10, '11:15', '12:15', 'Tradutor', NULL, 'TRADUTOR', TRUE),
                (3, 11, '12:15', '12:20', 'Hino final', 'Todos', NULL, TRUE),
                (3, 12, '12:20', '12:25', 'Oração final', NULL, 'ORACAO_FINAL', FALSE),
                (3, 13, '12:30', NULL, 'Despedida', NULL, 'APRESENTADOR_CULTO', FALSE),
                (4, 1, '14:30', '14:40', 'Momento de louvor', 'Todos', NULL, TRUE),
                (4, 2, '14:40', '14:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (4, 3, '14:45', '14:50', 'Oração inicial', NULL, NULL, FALSE),
                (4, 4, '14:50', '14:55', 'Hino especial', 'Jovens', NULL, FALSE),
                (4, 5, '14:55', '15:00', 'Meditação', NULL, 'MEDITACAO_JA', FALSE),
                (4, 6, '15:00', '15:05', 'Hino especial', NULL, NULL, FALSE),
                (4, 7, '15:05', '16:05', 'Tema da tarde', NULL, NULL, FALSE),
                (4, 8, '16:05', '16:10', 'Introdução da lição', NULL, NULL, FALSE),
                (4, 9, '16:10', '16:15', 'Oração final', NULL, NULL, FALSE),
                (4, 10, '16:15', '16:20', 'Hino final', 'Todos', NULL, FALSE),
                (4, 11, '16:20', NULL, 'Despedida', NULL, 'APRESENTADOR_JA', FALSE)
              ) AS i(parte, ordem, inicio, fim, actividade, texto, escala, destaque)
             WHERE i.parte = r.ordem;
        END LOOP;
    END IF;

    PERFORM actividades.fn_programa_preencher(v_pgd);
    RETURN v_pgd;
END $$;
COMMENT ON FUNCTION actividades.fn_programa_preparar(INT, DATE, INT) IS 'Cria a programação de um dia a partir do modelo ou de outro dia e preenche-a pela escala (V44)';
GRANT EXECUTE ON FUNCTION actividades.fn_programa_preparar(INT, DATE, INT) TO app_igreja;

-- >>>>> V45__escalas_da_escola_sabatina_e_ja.sql
-- =====================================================================
-- V45 · Escalas da Escola Sabatina e da JA, definidas por cada igreja (F-ACT)
--
--   escala do culto   volta a ser só do Culto Divino (apresentador, Sermão principal, tradutor, Sermão da criança,
--                     orações) e do grupo coral: a família e as funções da ES e da JA saem da grelha.
--   tipos de escala   escala_plano.epl_tipo: CULTO, ESCOLA_SABATINA ou JA.
--   colunas           actividades.escala_coluna: cada igreja define as colunas da sua escala da Escola Sabatina e da
--                     JA (nome, ordem e se se escala um membro ou uma família) — cada igreja tem o seu modelo.
--                     A escala (actividades.escala) ganha esc_ecn_id (a coluna) e esc_fam_id (a família); o membro
--                     deixa de ser obrigatório (membro ou família, um dos dois).
--   programação       partes e itens podem ligar-se a uma coluna (ecn_id): "preencher pela escala" põe lá quem está
--                     escalado nessa coluna nesse dia. O modelo deixa a ES e a JA sem ligação (cada igreja liga a sua).
--   lembretes         nas colunas da ES/JA o SMS diz o nome da coluna (ex.: "apresentador da Escola Sabatina").
--
-- Nada se apaga: o tipo dos planos existentes é CULTO; eds_fam_id (V44) fica, sem uso na grelha.
-- Permissões novas (actividades.escala_coluna.*): as mesmas da escala. Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- tipo de escala
ALTER TABLE actividades.escala_plano ADD COLUMN epl_tipo VARCHAR(20) NOT NULL DEFAULT 'CULTO';
ALTER TABLE actividades.escala_plano ADD CONSTRAINT chk_epl_tipo CHECK (epl_tipo IN ('CULTO', 'ESCOLA_SABATINA', 'JA'));
COMMENT ON COLUMN actividades.escala_plano.epl_tipo IS 'CULTO (Culto Divino), ESCOLA_SABATINA ou JA (V45)';
COMMENT ON CONSTRAINT chk_epl_tipo ON actividades.escala_plano IS '[tipo] A escala é do Culto Divino, da Escola Sabatina ou da JA.';

-- ---------------------------------------------------------------- colunas da escala da ES e da JA (gerada: gen.py)
CREATE TABLE actividades.escala_coluna (
    ecn_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ecn_igr_id INT NOT NULL,
    ecn_tipo VARCHAR(20) NOT NULL,
    ecn_ordem SMALLINT NOT NULL DEFAULT 1,
    ecn_nome VARCHAR(80) NOT NULL,
    ecn_responsavel VARCHAR(10) NOT NULL DEFAULT 'MEMBRO',
    ecn_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ecn_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ecn_criado_por INT,
    ecn_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ecn_modificado_por INT,
    ecn_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ecn_igr_id FOREIGN KEY (ecn_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_ecn_tipo CHECK (ecn_tipo IN ('ESCOLA_SABATINA', 'JA')),
    CONSTRAINT chk_ecn_responsavel CHECK (ecn_responsavel IN ('MEMBRO', 'FAMILIA')),
    CONSTRAINT chk_ecn_end_date CHECK (ecn_end_date IS NULL OR ecn_end_date >= ecn_criado_em)
);

COMMENT ON TABLE actividades.escala_coluna IS 'Coluna da escala da Escola Sabatina ou da JA, como cada igreja a organiza (ex.: Apresentador, Carta missionária) (V45)';
COMMENT ON COLUMN actividades.escala_coluna.ecn_tipo IS 'ESCOLA_SABATINA ou JA';
COMMENT ON COLUMN actividades.escala_coluna.ecn_nome IS 'Ex.: Apresentador, Oração, Carta missionária';
COMMENT ON COLUMN actividades.escala_coluna.ecn_responsavel IS 'Quem se escala nesta coluna: MEMBRO ou FAMILIA';
CREATE UNIQUE INDEX uq_ecn_igr_id_tipo_nome ON actividades.escala_coluna (ecn_igr_id, ecn_tipo, ecn_nome) WHERE ecn_end_date IS NULL;
CREATE TRIGGER trg_ecn_00_padrao BEFORE INSERT OR UPDATE ON actividades.escala_coluna FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ecn', 'actividades.escala_coluna', 'ecn_igr_id');
CREATE TRIGGER trg_ecn_00_sem_delete BEFORE DELETE ON actividades.escala_coluna FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ecn');
CREATE TRIGGER trg_ecn_00_sem_truncate BEFORE TRUNCATE ON actividades.escala_coluna FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ecn');
CREATE TRIGGER trg_ecn_99_log AFTER UPDATE ON actividades.escala_coluna FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ecn');
ALTER TABLE actividades.escala_coluna ADD CONSTRAINT fk_ecn_criado_por FOREIGN KEY (ecn_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala_coluna ADD CONSTRAINT fk_ecn_modificado_por FOREIGN KEY (ecn_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala_coluna ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ecn_ler ON actividades.escala_coluna FOR SELECT USING (ecn_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_coluna.ler'))::INT[]));
CREATE POLICY pol_ecn_criar ON actividades.escala_coluna FOR INSERT WITH CHECK (ecn_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_coluna.criar'))::INT[]));
CREATE POLICY pol_ecn_alterar ON actividades.escala_coluna FOR UPDATE USING (ecn_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_coluna.alterar'))::INT[])) WITH CHECK (ecn_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_coluna.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON actividades.escala_coluna TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
COMMENT ON INDEX actividades.uq_ecn_igr_id_tipo_nome IS '[nome] Esta escala já tem uma coluna com este nome.';
COMMENT ON CONSTRAINT chk_ecn_tipo ON actividades.escala_coluna IS '[tipo] As colunas são da escala da Escola Sabatina ou da JA.';
COMMENT ON CONSTRAINT chk_ecn_responsavel ON actividades.escala_coluna IS '[responsavel] Escala-se um membro ou uma família.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'actividades.escala_coluna.' || a.accao, a.rotulo || 'Coluna da escala da Escola Sabatina ou da JA, como cada igreja a organiza (V45)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.escala_plano.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, 'escala_plano', 'escala_coluna')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- a escala: coluna, família, membro ou família
ALTER TABLE actividades.escala ADD COLUMN esc_ecn_id INT;
ALTER TABLE actividades.escala ADD COLUMN esc_fam_id INT;
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_ecn_id FOREIGN KEY (esc_ecn_id) REFERENCES actividades.escala_coluna(ecn_id);
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_fam_id FOREIGN KEY (esc_fam_id) REFERENCES secretaria.familia(fam_id);
COMMENT ON COLUMN actividades.escala.esc_ecn_id IS 'Coluna da escala da Escola Sabatina ou da JA (definida pela igreja) (V45)';
COMMENT ON COLUMN actividades.escala.esc_fam_id IS 'Família escalada, nas colunas por família (V45)';
COMMENT ON COLUMN actividades.escala.esc_mem_id IS 'Membro escalado (ou a família, nas colunas por família)';
CREATE INDEX idx_esc_ecn_id ON actividades.escala (esc_ecn_id);
CREATE INDEX idx_esc_fam_id ON actividades.escala (esc_fam_id);
ALTER TABLE actividades.escala ALTER COLUMN esc_mem_id DROP NOT NULL;
ALTER TABLE actividades.escala ADD CONSTRAINT chk_esc_quem CHECK (num_nonnulls(esc_mem_id, esc_fam_id) = 1);
COMMENT ON CONSTRAINT chk_esc_quem ON actividades.escala IS '[membroId] Escale um membro ou uma família (um dos dois).';
-- a mesma pessoa pode estar em duas colunas diferentes no mesmo dia; na mesma coluna e função, não
DROP INDEX actividades.uq_esc_igr_id_data_funcao_mem_id;
CREATE UNIQUE INDEX uq_esc_unico ON actividades.escala (esc_igr_id, esc_data, esc_funcao, COALESCE(esc_ecn_id, 0), COALESCE(esc_mem_id, 0), COALESCE(esc_fam_id, 0))
    WHERE esc_end_date IS NULL;
COMMENT ON INDEX actividades.uq_esc_unico IS '[membroId] Já está escalado(a) nesta função (ou coluna) neste dia.';

-- a coluna é da igreja e do tipo da escala; membro ou família conforme a coluna; a escala da ES/JA usa as colunas
CREATE FUNCTION actividades.fn_esc_coluna() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_tipo TEXT;
    c      actividades.escala_coluna%ROWTYPE;
BEGIN
    SELECT p.epl_tipo INTO v_tipo FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
     WHERE d.eds_id = NEW.esc_eds_id;
    IF NEW.esc_ecn_id IS NULL THEN
        IF coalesce(v_tipo, 'CULTO') <> 'CULTO' THEN
            RAISE EXCEPTION 'Na escala da Escola Sabatina ou da JA escolha a coluna' USING COLUMN = 'esc_ecn_id';
        END IF;
        IF NEW.esc_fam_id IS NOT NULL THEN
            RAISE EXCEPTION 'Na escala do culto escala-se um membro' USING COLUMN = 'esc_mem_id';
        END IF;
        RETURN NEW;
    END IF;
    SELECT * INTO c FROM actividades.escala_coluna WHERE ecn_id = NEW.esc_ecn_id AND ecn_end_date IS NULL;
    IF NOT FOUND OR c.ecn_igr_id <> NEW.esc_igr_id OR c.ecn_tipo IS DISTINCT FROM v_tipo THEN
        RAISE EXCEPTION 'A coluna não é desta escala' USING COLUMN = 'esc_ecn_id';
    END IF;
    IF NEW.esc_funcao::text <> 'OUTRA' THEN
        RAISE EXCEPTION 'Nas colunas da escala a função é OUTRA (o nome é o da coluna)' USING COLUMN = 'esc_funcao';
    END IF;
    IF c.ecn_responsavel = 'FAMILIA' AND NEW.esc_fam_id IS NULL THEN
        RAISE EXCEPTION 'Na coluna "%" escala-se uma família', c.ecn_nome USING COLUMN = 'esc_fam_id';
    END IF;
    IF c.ecn_responsavel = 'MEMBRO' AND NEW.esc_mem_id IS NULL THEN
        RAISE EXCEPTION 'Na coluna "%" escala-se um membro', c.ecn_nome USING COLUMN = 'esc_mem_id';
    END IF;
    IF NEW.esc_fam_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM secretaria.familia WHERE fam_id = NEW.esc_fam_id AND fam_igr_id = NEW.esc_igr_id) THEN
        RAISE EXCEPTION 'A família tem de ser desta igreja' USING COLUMN = 'esc_fam_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_esc_10_coluna BEFORE INSERT OR UPDATE OF esc_ecn_id, esc_mem_id, esc_fam_id, esc_eds_id, esc_funcao ON actividades.escala
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_esc_coluna();

-- ---------------------------------------------------------------- programação: ligar partes e itens às colunas
ALTER TABLE actividades.programa_parte ADD COLUMN ppa_ecn_id INT;
ALTER TABLE actividades.programa_parte ADD CONSTRAINT fk_ppa_ecn_id FOREIGN KEY (ppa_ecn_id) REFERENCES actividades.escala_coluna(ecn_id);
COMMENT ON COLUMN actividades.programa_parte.ppa_ecn_id IS 'Coluna da escala da Escola Sabatina ou da JA que preenche o apresentador (V45)';
CREATE INDEX idx_ppa_ecn_id ON actividades.programa_parte (ppa_ecn_id);
ALTER TABLE actividades.programa_item ADD COLUMN pit_ecn_id INT;
ALTER TABLE actividades.programa_item ADD CONSTRAINT fk_pit_ecn_id FOREIGN KEY (pit_ecn_id) REFERENCES actividades.escala_coluna(ecn_id);
COMMENT ON COLUMN actividades.programa_item.pit_ecn_id IS 'Coluna da escala da Escola Sabatina ou da JA que preenche o responsável (V45)';
CREATE INDEX idx_pit_ecn_id ON actividades.programa_item (pit_ecn_id);

CREATE OR REPLACE FUNCTION actividades.fn_programa_preencher(p_pgd INT) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_igr  INT;
    v_data DATE;
    v_fam  INT;
    v_n    INT := 0;
    v_k    INT;
BEGIN
    SELECT pgd_igr_id, pgd_data INTO v_igr, v_data FROM actividades.programa_dia WHERE pgd_id = p_pgd AND pgd_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Programação % não encontrada', p_pgd USING ERRCODE = 'P0002'; END IF;

    SELECT d.eds_fam_id INTO v_fam
      FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
     WHERE p.epl_igr_id = v_igr AND d.eds_data = v_data AND d.eds_end_date IS NULL AND p.epl_end_date IS NULL
       AND d.eds_fam_id IS NOT NULL
     ORDER BY p.epl_publicada DESC, d.eds_id DESC LIMIT 1;

    -- quem está escalado em cada função nesse dia (o substituto, se houver; o primeiro, se houver mais de um)
    UPDATE actividades.programa_parte x
       SET ppa_apresentador_mem_id = t.mem_id, ppa_apresentador_fam_id = NULL, ppa_apresentador_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_ecn_id IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.ppa_pgd_id = p_pgd AND x.ppa_end_date IS NULL AND x.ppa_escala = t.funcao
       AND x.ppa_apresentador_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    UPDATE actividades.programa_item x
       SET pit_responsavel_mem_id = t.mem_id, pit_responsavel_fam_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_ecn_id IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.pit_pgd_id = p_pgd AND x.pit_end_date IS NULL AND x.pit_escala = t.funcao
       AND x.pit_responsavel_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;

    -- as colunas das escalas da Escola Sabatina e da JA (definidas pela igreja): o membro ou a família escalados
    UPDATE actividades.programa_parte x
       SET ppa_apresentador_mem_id = t.mem_id, ppa_apresentador_fam_id = t.fam_id, ppa_apresentador_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_ecn_id) e.esc_ecn_id AS ecn_id, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id, e.esc_fam_id AS fam_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_ecn_id IS NOT NULL
               AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_ecn_id, e.esc_id) t
     WHERE x.ppa_pgd_id = p_pgd AND x.ppa_end_date IS NULL AND x.ppa_ecn_id = t.ecn_id
       AND (x.ppa_apresentador_mem_id, x.ppa_apresentador_fam_id) IS DISTINCT FROM (t.mem_id, t.fam_id);
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    UPDATE actividades.programa_item x
       SET pit_responsavel_mem_id = t.mem_id, pit_responsavel_fam_id = t.fam_id, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_ecn_id) e.esc_ecn_id AS ecn_id, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id, e.esc_fam_id AS fam_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_ecn_id IS NOT NULL
               AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_ecn_id, e.esc_id) t
     WHERE x.pit_pgd_id = p_pgd AND x.pit_end_date IS NULL AND x.pit_ecn_id = t.ecn_id
       AND (x.pit_responsavel_mem_id, x.pit_responsavel_fam_id) IS DISTINCT FROM (t.mem_id, t.fam_id);
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;

    IF v_fam IS NOT NULL THEN
        UPDATE actividades.programa_parte
           SET ppa_apresentador_fam_id = v_fam, ppa_apresentador_mem_id = NULL, ppa_apresentador_texto = NULL
         WHERE ppa_pgd_id = p_pgd AND ppa_end_date IS NULL AND ppa_escala = 'FAMILIA_ES' AND ppa_apresentador_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
        UPDATE actividades.programa_item
           SET pit_responsavel_fam_id = v_fam, pit_responsavel_mem_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
         WHERE pit_pgd_id = p_pgd AND pit_end_date IS NULL AND pit_escala = 'FAMILIA_ES' AND pit_responsavel_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    END IF;
    RETURN v_n;
END $$;

CREATE OR REPLACE FUNCTION actividades.fn_programa_preparar(p_igr INT, p_data DATE, p_origem INT DEFAULT NULL) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_pgd   INT;
    v_parte INT;
    r       RECORD;
BEGIN
    IF p_origem IS NOT NULL AND NOT EXISTS (SELECT 1 FROM actividades.programa_dia WHERE pgd_id = p_origem AND pgd_igr_id = p_igr AND pgd_end_date IS NULL) THEN
        RAISE EXCEPTION 'A programação a copiar não existe nesta igreja' USING COLUMN = 'pgd_id';
    END IF;
    INSERT INTO actividades.programa_dia (pgd_igr_id, pgd_data, pgd_observacoes)
    VALUES (p_igr, p_data, CASE WHEN p_origem IS NULL THEN 'Passível de ajustes e simplificação'
                                ELSE (SELECT pgd_observacoes FROM actividades.programa_dia WHERE pgd_id = p_origem) END)
    RETURNING pgd_id INTO v_pgd;

    IF p_origem IS NOT NULL THEN
        FOR r IN SELECT * FROM actividades.programa_parte WHERE ppa_pgd_id = p_origem AND ppa_end_date IS NULL ORDER BY ppa_ordem, ppa_id LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_apresentador_mem_id,
                                                   ppa_apresentador_fam_id, ppa_apresentador_texto, ppa_escala, ppa_ecn_id)
            VALUES (v_pgd, r.ppa_ordem, r.ppa_titulo, r.ppa_rotulo, r.ppa_apresentador_mem_id, r.ppa_apresentador_fam_id,
                    r.ppa_apresentador_texto, r.ppa_escala, r.ppa_ecn_id)
            RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_mem_id, pit_responsavel_fam_id, pit_responsavel_ide_id,
                                                   pit_responsavel_texto, pit_escala, pit_destaque, pit_ecn_id)
            SELECT v_pgd, v_parte, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade, pit_responsavel_mem_id,
                   pit_responsavel_fam_id, pit_responsavel_ide_id, pit_responsavel_texto, pit_escala, pit_destaque, pit_ecn_id
              FROM actividades.programa_item WHERE pit_ppa_id = r.ppa_id AND pit_end_date IS NULL;
        END LOOP;
    ELSE
        FOR r IN SELECT * FROM (VALUES
            (1, 'Programação da Escola Sabatina', 'Apresentador', NULL),
            (2, 'Transição', 'Transição', NULL),
            (3, 'Programação do Culto Divino', 'Apresentador', 'APRESENTADOR_CULTO'),
            (4, 'JA', 'Apresentador', NULL)) AS m(ordem, titulo, rotulo, escala) LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_escala)
            VALUES (v_pgd, r.ordem, r.titulo, r.rotulo, r.escala) RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_texto, pit_escala, pit_destaque)
            SELECT v_pgd, v_parte, i.ordem, i.inicio, i.fim, i.actividade, i.texto, i.escala, i.destaque
              FROM (VALUES
                (1, 1, '08:50', '09:00', 'Momento de louvor', 'Todos', NULL, FALSE),
                (1, 2, '09:00', '09:05', 'Hino inicial', 'Todos', NULL, FALSE),
                (1, 3, '09:05', '09:10', 'Oração inicial', NULL, NULL, FALSE),
                (1, 4, '09:10', '09:15', 'Música especial', NULL, NULL, FALSE),
                (1, 5, '09:15', '09:25', '28 Crenças', NULL, NULL, FALSE),
                (1, 6, '09:25', '09:30', 'Carta missionária', NULL, NULL, FALSE),
                (1, 7, '09:30', '09:35', 'Capítulo do dia', NULL, NULL, FALSE),
                (1, 8, '09:35', '09:40', 'Momento de testemunho / gratidão', 'Todos', NULL, FALSE),
                (1, 9, '09:40', '10:15', 'Resumo das lições', 'Monitores', NULL, TRUE),
                (1, 10, NULL, NULL, 'Oração final', NULL, NULL, FALSE),
                (2, 1, '10:15', '10:20', 'Devolução de envelopes', 'Tesouraria', NULL, FALSE),
                (2, 2, '10:20', '10:25', 'Minuto saúde', NULL, NULL, FALSE),
                (2, 3, '10:25', '10:30', 'Momento de louvor', 'Departamento de Música', NULL, FALSE),
                (3, 1, '10:30', '10:35', 'Entrada da tribuna e doxologia', 'Todos', NULL, FALSE),
                (3, 2, '10:35', '10:40', 'Boas-vindas e anúncios', 'Secretaria', NULL, FALSE),
                (3, 3, '10:40', '10:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (3, 4, '10:45', '10:50', 'Oração inicial', NULL, 'ORACAO_INICIAL', FALSE),
                (3, 5, '10:50', '10:55', 'Marca de um mordomo', 'Tesouraria', NULL, FALSE),
                (3, 6, '10:55', '11:00', 'Música especial', NULL, NULL, FALSE),
                (3, 7, '11:00', '11:05', 'Recolha das ofertas e dízimos', 'Diáconos', NULL, FALSE),
                (3, 8, '11:05', '11:10', 'Sermão da criança', NULL, 'SERMAO_CRIANCA', FALSE),
                (3, 9, '11:15', '12:15', 'Sermão principal', NULL, 'PREGADOR', TRUE),
                (3, 10, '11:15', '12:15', 'Tradutor', NULL, 'TRADUTOR', TRUE),
                (3, 11, '12:15', '12:20', 'Hino final', 'Todos', NULL, TRUE),
                (3, 12, '12:20', '12:25', 'Oração final', NULL, 'ORACAO_FINAL', FALSE),
                (3, 13, '12:30', NULL, 'Despedida', NULL, 'APRESENTADOR_CULTO', FALSE),
                (4, 1, '14:30', '14:40', 'Momento de louvor', 'Todos', NULL, TRUE),
                (4, 2, '14:40', '14:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (4, 3, '14:45', '14:50', 'Oração inicial', NULL, NULL, FALSE),
                (4, 4, '14:50', '14:55', 'Hino especial', 'Jovens', NULL, FALSE),
                (4, 5, '14:55', '15:00', 'Meditação', NULL, NULL, FALSE),
                (4, 6, '15:00', '15:05', 'Hino especial', NULL, NULL, FALSE),
                (4, 7, '15:05', '16:05', 'Tema da tarde', NULL, NULL, FALSE),
                (4, 8, '16:05', '16:10', 'Introdução da lição', NULL, NULL, FALSE),
                (4, 9, '16:10', '16:15', 'Oração final', NULL, NULL, FALSE),
                (4, 10, '16:15', '16:20', 'Hino final', 'Todos', NULL, FALSE),
                (4, 11, '16:20', NULL, 'Despedida', NULL, NULL, FALSE)
              ) AS i(parte, ordem, inicio, fim, actividade, texto, escala, destaque)
             WHERE i.parte = r.ordem;
        END LOOP;
    END IF;

    PERFORM actividades.fn_programa_preencher(v_pgd);
    RETURN v_pgd;
END $$;

-- ---------------------------------------------------------------- lembretes com o nome da coluna
CREATE OR REPLACE FUNCTION actividades.fn_lembretes_escala(p_agora timestamp with time zone DEFAULT now())
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'public'
AS $function$
DECLARE
    v_local  TIMESTAMP := p_agora AT TIME ZONE 'Africa/Maputo';
    v_hoje   DATE := (p_agora AT TIME ZONE 'Africa/Maputo')::date;
    v_dia    INT := EXTRACT(ISODOW FROM (p_agora AT TIME ZONE 'Africa/Maputo'));
    v_sabado DATE;
    v_envio  TIMESTAMPTZ;
    n INT;
BEGIN
    IF v_dia NOT IN (3, 5) OR v_local::time >= TIME '20:00' THEN
        RETURN 0;
    END IF;
    v_sabado := v_hoje + (6 - v_dia);
    v_envio := GREATEST(p_agora, (v_hoje + TIME '18:00') AT TIME ZONE 'Africa/Maputo');
    INSERT INTO nucleo.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                         ntf_agendada_para, ntf_origem_tabela, ntf_origem_id, ntf_chave)
    SELECT e.esc_igr_id, x.mem_id, 'SMS', x.telefone, 'Escala de ' || to_char(v_sabado, 'DD/MM'),
           left(i.igr_nome, 40) || ': lembrete - no sábado ' || to_char(v_sabado, 'DD/MM') || ' está escalado(a) como '
               || COALESCE(lower(c2.ecn_nome) || CASE p.epl_tipo WHEN 'ESCOLA_SABATINA' THEN ' da Escola Sabatina' WHEN 'JA' THEN ' da JA' ELSE '' END,
                           actividades.fn_funcao_escala_nome(e.esc_funcao)) || '. Deus o(a) abençoe.',
           v_envio, 'actividades.escala', e.esc_id, 'escala:' || e.esc_id || ':' || v_hoje
    FROM actividades.escala e
    JOIN organizacao.igreja i ON i.igr_id = e.esc_igr_id
    LEFT JOIN actividades.escala_dia d ON d.eds_id = e.esc_eds_id
    LEFT JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
    LEFT JOIN actividades.escala_coluna c2 ON c2.ecn_id = e.esc_ecn_id
    CROSS JOIN LATERAL (
        SELECT c.cto_mem_id AS mem_id, c.cto_valor AS telefone
        FROM secretaria.contacto c
        WHERE c.cto_mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
          AND c.cto_end_date IS NULL AND c.cto_estado = 'ACTIVO' AND c.cto_tipo IN ('TELEFONE', 'WHATSAPP')
        ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) x
    WHERE e.esc_data = v_sabado AND e.esc_end_date IS NULL
      AND e.esc_estado IN ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA')
      AND (e.esc_eds_id IS NULL
           OR (p.epl_publicada AND p.epl_end_date IS NULL AND d.eds_end_date IS NULL AND d.eds_evento IS NULL))
      AND EXISTS (SELECT 1 FROM secretaria.consentimento s
                  WHERE s.cns_mem_id = x.mem_id AND s.cns_end_date IS NULL AND s.cns_concedido
                    AND s.cns_tipo = 'CONTACTO_SMS')
    ON CONFLICT (ntf_chave) WHERE ntf_end_date IS NULL DO NOTHING;
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $function$;

-- =====================================================================
-- Fundo de construção (F-TES): tipo de fundo próprio, parte da contagem e linha das ofertas especiais
-- =====================================================================
ALTER TYPE nucleo.tipo_fundo_t ADD VALUE IF NOT EXISTS 'CONSTRUCAO';

-- um fundo próprio da igreja pode ser o da construção (compara como texto: o valor novo é desta transacção)
ALTER TABLE tesouraria.fundo DROP CONSTRAINT chk_fun_da_igreja;
ALTER TABLE tesouraria.fundo ADD CONSTRAINT chk_fun_da_igreja
    CHECK (fun_igr_id IS NULL OR (fun_percentagem_remessa = 0 AND fun_destino_ent_id IS NULL
                                  AND fun_tipo::TEXT IN ('OFERTA_ESPECIAL', 'PROJECTO', 'REAVIVAMENTO', 'CONSTRUCAO')));
COMMENT ON CONSTRAINT chk_fun_da_igreja ON tesouraria.fundo IS
    '[tipo] Um fundo próprio da igreja é uma oferta especial, um projecto, a obra de reavivamento ou a construção, e fica todo na igreja.';

-- a contagem ganha a parte do fundo de construção (as contagens antigas ficam sem ela)
ALTER TABLE tesouraria.contagem_numerario ADD COLUMN cnu_construcao DECIMAL(14,2);
COMMENT ON COLUMN tesouraria.contagem_numerario.cnu_construcao IS 'Parte do contado: fundo de construção (V45)';
ALTER TABLE tesouraria.contagem_numerario DROP CONSTRAINT chk_cnu_partes;
ALTER TABLE tesouraria.contagem_numerario ADD CONSTRAINT chk_cnu_partes CHECK (
    (cnu_dizimos IS NULL AND cnu_ofertas IS NULL AND cnu_escola_sabatina IS NULL AND cnu_outras IS NULL AND cnu_construcao IS NULL) OR
    (cnu_dizimos >= 0 AND cnu_ofertas >= 0 AND cnu_escola_sabatina >= 0 AND cnu_outras >= 0 AND COALESCE(cnu_construcao, 0) >= 0 AND
     cnu_dizimos + cnu_ofertas + cnu_escola_sabatina + cnu_outras + COALESCE(cnu_construcao, 0) = cnu_total_contado));
COMMENT ON CONSTRAINT chk_cnu_partes ON tesouraria.contagem_numerario IS
    'As partes da contagem (dízimos, ofertas, Escola Sabatina, construção, outras) têm de somar o total contado.';

-- a conferência: o lançado no fundo de construção conta à parte (sai das "outras")
CREATE OR REPLACE VIEW tesouraria.vw_contagem_conferencia WITH (security_invoker = true) AS
SELECT c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado,
       COALESCE(x.total, 0)                       AS total_lancado,
       c.cnu_total_contado - COALESCE(x.total, 0) AS diferenca,
       c.cnu_estado,
       c.cnu_dizimos, c.cnu_ofertas, c.cnu_escola_sabatina, c.cnu_outras,
       COALESCE(x.dizimos, 0)         AS dizimos_lancado,
       COALESCE(x.ofertas, 0)         AS ofertas_lancado,
       COALESCE(x.escola_sabatina, 0) AS escola_sabatina_lancado,
       COALESCE(x.outras, 0)          AS outras_lancado,
       -- V45: o fundo de construção
       c.cnu_construcao,
       COALESCE(x.construcao, 0)      AS construcao_lancado
FROM tesouraria.contagem_numerario c
LEFT JOIN LATERAL (
    SELECT SUM(l.tli_valor) AS total,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimos,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT IN ('OFERTA_COMBINADA', 'OFERTA_MISSIONARIA')) AS ofertas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT IN ('ES_MISSOES', 'ES_13_SABADO', 'ES_DESPESAS')) AS escola_sabatina,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT NOT IN ('DIZIMO', 'OFERTA_COMBINADA', 'OFERTA_MISSIONARIA',
                                                                  'ES_MISSOES', 'ES_13_SABADO', 'ES_DESPESAS', 'CONSTRUCAO')) AS outras,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'CONSTRUCAO') AS construcao
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id
    WHERE t.tra_cnu_id = c.cnu_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
) x ON TRUE
WHERE c.cnu_end_date IS NULL;

-- =====================================================================
-- Procura de membros antes de registar (F-SEC-01): nomes escritos de outra forma e o telemóvel
-- =====================================================================
-- Nome como se ouve: sem acentos, h mudo, ph→f, y→i, w→u, k/qu→c, z/ss→s, letras dobradas uma só
-- (ex.: "Cossa" e "Cosa", "Felisberto" e "Phelisberto", "Zacarias" e "Sacarias").
CREATE FUNCTION nucleo.fn_nome_fonetico(p TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
    SELECT regexp_replace(                                                  -- letras dobradas: uma só
             regexp_replace(                                                -- h no início de uma palavra
               regexp_replace(                                              -- h mudo (fica ch, nh, lh)
                 translate(replace(replace(coalesce(nucleo.fn_nome_comparavel(p), ''), 'ph', 'f'), 'qu', 'c'),
                           'ykwz', 'icus'),
                 '([^cnl ])h', '\1', 'g'),
               '(^| )h', '\1', 'g'),
             '(.)\1+', '\1', 'g')
$$;
COMMENT ON FUNCTION nucleo.fn_nome_fonetico(TEXT) IS 'Nome como se ouve, para achar o mesmo nome escrito de outra forma (V45)';

-- Os parecidos: agora também com o nome e o apelido trocados, escritos de outra forma (como se ouvem), o mesmo
-- apelido com a mesma data, e o mesmo telemóvel. Continua SECURITY INVOKER (só os membros que o utilizador vê).
DROP FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT);
CREATE FUNCTION nucleo.fn_membros_parecidos(p_nome TEXT, p_apelido TEXT, p_data_nascimento DATE DEFAULT NULL,
                                            p_naturalidade TEXT DEFAULT NULL, p_numero_identificacao TEXT DEFAULT NULL,
                                            p_excluir_mem_id INT DEFAULT NULL, p_telefone TEXT DEFAULT NULL)
RETURNS TABLE (mem_id INT, mem_igr_id INT, nome TEXT, data_nascimento DATE, naturalidade TEXT,
               numero_identificacao TEXT, estado nucleo.estado_membro_t, pontos INT, motivos TEXT[])
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH p AS (
        SELECT nucleo.fn_nome_fonetico(coalesce(p_nome, '') || ' ' || coalesce(p_apelido, '')) AS fon,
               nucleo.fn_nome_fonetico(coalesce(p_apelido, '') || ' ' || coalesce(p_nome, '')) AS fon_trocado,
               nucleo.fn_nome_fonetico(p_apelido) AS apelido,
               nullif(upper(regexp_replace(coalesce(p_numero_identificacao, ''), '[^A-Za-z0-9]', '', 'g')), '') AS doc,
               nullif(lower(trim(coalesce(p_naturalidade, ''))), '') AS nat,
               nullif(right(regexp_replace(coalesce(p_telefone, ''), '[^0-9]', '', 'g'), 9), '') AS tel
    ), candidatos AS (
        SELECT m.*,
               greatest(similarity(nucleo.fn_nome_fonetico(m.mem_nome || ' ' || m.mem_apelido), p.fon),
                        similarity(nucleo.fn_nome_fonetico(m.mem_nome || ' ' || m.mem_apelido), p.fon_trocado)) AS sim,
               (p.doc IS NOT NULL AND length(p.doc) >= 5
                AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc) AS mesmo_doc,
               (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento) AS mesma_data,
               (p.nat IS NOT NULL AND lower(trim(m.mem_naturalidade)) = p.nat) AS mesmo_local,
               (p.apelido <> '' AND nucleo.fn_nome_fonetico(m.mem_apelido) = p.apelido) AS mesmo_apelido,
               (p.tel IS NOT NULL AND length(p.tel) >= 8 AND EXISTS (
                    SELECT 1 FROM secretaria.contacto c
                     WHERE c.cto_mem_id = m.mem_id AND c.cto_end_date IS NULL AND c.cto_tipo::TEXT IN ('TELEFONE', 'WHATSAPP')
                       AND right(regexp_replace(c.cto_valor, '[^0-9]', '', 'g'), 9) = p.tel)) AS mesmo_tel
          FROM secretaria.membro m, p
         WHERE m.mem_end_date IS NULL
           AND m.mem_id IS DISTINCT FROM p_excluir_mem_id
           AND ((m.mem_nome || ' ' || m.mem_apelido) % (coalesce(p_nome, '') || ' ' || coalesce(p_apelido, ''))
                OR (m.mem_nome || ' ' || m.mem_apelido) % (coalesce(p_apelido, '') || ' ' || coalesce(p_nome, ''))
                OR (p.doc IS NOT NULL AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc)
                OR (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento)
                OR (p.tel IS NOT NULL AND m.mem_id IN (SELECT c.cto_mem_id FROM secretaria.contacto c
                                                         WHERE c.cto_end_date IS NULL AND c.cto_tipo::TEXT IN ('TELEFONE', 'WHATSAPP')
                                                           AND right(regexp_replace(c.cto_valor, '[^0-9]', '', 'g'), 9) = p.tel)))
    ), pontuados AS (
        SELECT c.*,
               (CASE WHEN c.mesmo_doc THEN 100 ELSE 0 END
              + CASE WHEN c.sim >= 0.6 THEN 40 WHEN c.sim >= 0.45 THEN 20 ELSE 0 END
              + CASE WHEN c.mesma_data THEN 30 ELSE 0 END
              + CASE WHEN c.mesma_data AND c.mesmo_apelido AND c.sim < 0.6 THEN 20 ELSE 0 END
              + CASE WHEN c.mesmo_local THEN 10 ELSE 0 END
              + CASE WHEN c.mesmo_tel THEN 40 ELSE 0 END) AS pts,
               array_remove(ARRAY[
                 CASE WHEN c.mesmo_doc THEN 'Mesmo número de documento' END,
                 CASE WHEN c.sim >= 0.6 THEN 'Nome igual ou muito parecido' WHEN c.sim >= 0.45 THEN 'Nome parecido' END,
                 CASE WHEN c.mesma_data THEN 'Mesma data de nascimento' END,
                 CASE WHEN c.mesma_data AND c.mesmo_apelido AND c.sim < 0.6 THEN 'Mesmo apelido' END,
                 CASE WHEN c.mesmo_local THEN 'Mesmo local de nascimento' END,
                 CASE WHEN c.mesmo_tel THEN 'Mesmo telemóvel' END], NULL) AS mot
          FROM candidatos c
    )
    SELECT x.mem_id, x.mem_igr_id, (x.mem_nome || ' ' || x.mem_apelido)::TEXT, x.mem_data_nascimento,
           x.mem_naturalidade::TEXT, x.mem_numero_identificacao::TEXT, x.mem_estado, x.pts, x.mot
      FROM pontuados x
     WHERE x.pts >= 40
     ORDER BY x.pts DESC, x.mem_apelido, x.mem_nome
     LIMIT 10
$$;
COMMENT ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT, TEXT) IS
    'Registos de membros parecidos (possíveis duplicados) entre os que o utilizador vê: nome como se ouve e trocado, data, documento, local e telemóvel; só aviso (V33, V45)';
REVOKE ALL ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT, TEXT) TO app_igreja;

-- >>>>> V46__painel_dos_membros.sql
-- =====================================================================
-- V46 · Painel dos membros por igreja (F-ORG, pontos 9, 12 e 16): a composição dos membros para o Painel geral
--
--   organizacao.vw_painel_membros   por igreja visível: membros (no livro como activos), interessados, sexo, faixas
--                                   etárias, estado civil (casados, união de facto, solteiros, viúvos, viúvas,
--                                   divorciados, noivos, sem estado civil) e membros sem família.
--   vw_painel_igrejas_mensal        ganha outras_saidas (falecimento, remoção, desaparecido) em cada mês: o gráfico das
--                                   entradas e saídas de membros passa a bater com as perdas do período.
-- SECURITY INVOKER: cada utilizador só conta os membros das igrejas que pode ver (RLS de secretaria.membro).
-- Os nomes das colunas não começam por três letras e "_" (a API tiraria esse "prefixo").
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE VIEW organizacao.vw_painel_membros WITH (security_invoker = true) AS
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO')                                       AS membros,
       count(*) FILTER (WHERE m.mem_estado = 'INTERESSADO')                                  AS interessados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'M')                  AS homens,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'F')                  AS mulheres,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_fam_id IS NULL)              AS activos_sem_familia,
       -- faixas etárias (membros com a data de nascimento)
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) <  INTERVAL '18 years') AS menores,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '18 years'
                                                   AND age(m.mem_data_nascimento) <  INTERVAL '36 years') AS jovens,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '36 years'
                                                   AND age(m.mem_data_nascimento) <  INTERVAL '60 years') AS adultos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '60 years') AS idosos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_data_nascimento IS NULL)    AS idade_desconhecida,
       -- estado civil
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'CASADO')      AS casados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'UNIAO_FACTO') AS uniao_facto,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'SOLTEIRO')    AS solteiros,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'VIUVO' AND m.mem_sexo = 'M') AS viuvos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'VIUVO' AND m.mem_sexo = 'F') AS viuvas,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'DIVORCIADO')  AS divorciados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'NOIVO')       AS noivos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil IS NULL)               AS estado_civil_vazio
FROM organizacao.igreja i
JOIN secretaria.membro m ON m.mem_igr_id = i.igr_id AND m.mem_end_date IS NULL
WHERE i.igr_end_date IS NULL
GROUP BY i.igr_id, i.igr_nome, i.igr_ent_id, i.igr_dst_id;
COMMENT ON VIEW organizacao.vw_painel_membros IS
    'Composição dos membros por igreja visível: sexo, idades, estado civil e sem família (V46); RLS de secretaria.membro';
GRANT SELECT ON organizacao.vw_painel_membros TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses: também as outras saídas do livro
CREATE OR REPLACE VIEW organizacao.vw_painel_igrejas_mensal WITH (security_invoker = true) AS
WITH meses AS (
    SELECT g::date AS ini, (g + INTERVAL '1 month')::date AS fim,
           EXTRACT(YEAR FROM g)::INT AS ano, EXTRACT(MONTH FROM g)::INT AS mes
    FROM generate_series(date_trunc('month', now() AT TIME ZONE 'Africa/Maputo') - INTERVAL '11 months',
                         date_trunc('month', now() AT TIME ZONE 'Africa/Maputo'), INTERVAL '1 month') g
),
desde AS (SELECT (MIN(ini)::timestamp AT TIME ZONE 'Africa/Maputo') AS t, MIN(ini) AS d FROM meses),
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
fundos AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimos,
           COUNT(DISTINCT t.tra_mem_id) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimistas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT NOT IN ('DIZIMO', 'REAVIVAMENTO')) AS ofertas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'REAVIVAMENTO') AS reavivamento
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id, EXTRACT(YEAR FROM l.mmb_data)::INT AS ano, EXTRACT(MONTH FROM l.mmb_data)::INT AS mes,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transf_entrada,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transf_saida,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS outras_saidas
    FROM secretaria.movimento_membro l, desde
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= desde.d
    GROUP BY 1, 2, 3
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id, ms.ano, ms.mes,
       COALESCE(dn.entradas, 0) AS entradas, COALESCE(dn.saidas, 0) AS saidas,
       COALESCE(z.dizimos, 0) AS dizimos, COALESCE(z.dizimistas, 0) AS dizimistas,
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida,
       COALESCE(z.ofertas, 0) AS ofertas, COALESCE(z.reavivamento, 0) AS reavivamento,
       -- V46: as outras saídas do livro (falecimento, remoção, desaparecido), para o gráfico bater com as perdas
       COALESCE(l.outras_saidas, 0) AS outras_saidas
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN fundos z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;

-- >>>>> V47__escola_sabatina_metas_e_semanas.sql
-- =====================================================================
-- V47 · Escola Sabatina (F-ES, ponto 15): metas individuais, contribuições individuais e colectivas, semanas especiais
--
--   presenca.epr_oferta              a oferta missionária de cada aluno na chamada (contribuição individual); a da
--                                    classe continua no relatório do sábado (contribuição colectiva).
--   meta_individual                  a meta de cada aluno da classe no trimestre; a meta da classe calcula-se sozinha
--                                    (alvo da oferta por sábado = soma das metas ÷ sábados do trimestre).
--   vw_metas_alunos / vw_metas_classes  o acompanhamento: meta, contribuído, identificado, presenças e cumprimento.
--   semana_especial                  semana de oração, da família, de evangelismo… com datas, para os alertas.
-- Permissões novas: as mesmas dos alvos das classes (escola_sabatina.classe_trimestre.*). Gerado com database/gerador.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- a oferta de cada aluno na chamada
ALTER TABLE escola_sabatina.presenca ADD COLUMN epr_oferta DECIMAL(12,2);
ALTER TABLE escola_sabatina.presenca ADD CONSTRAINT chk_epr_oferta CHECK (epr_oferta IS NULL OR epr_oferta >= 0);
COMMENT ON COLUMN escola_sabatina.presenca.epr_oferta IS 'Oferta missionária do aluno neste sábado (contribuição individual; V47)';
COMMENT ON CONSTRAINT chk_epr_oferta ON escola_sabatina.presenca IS '[oferta] A oferta não pode ser negativa.';

-- ---------------------------------------------------------------- metas individuais e semanas especiais (geradas: gen.py)
CREATE TABLE escola_sabatina.meta_individual (
    emt_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    emt_ect_id INT NOT NULL,
    emt_mem_id INT NOT NULL,
    emt_igr_id INT NOT NULL,
    emt_alvo_oferta DECIMAL(12,2) NOT NULL,
    emt_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    emt_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    emt_criado_por INT,
    emt_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    emt_modificado_por INT,
    emt_end_date TIMESTAMPTZ,
    CONSTRAINT fk_emt_ect_id FOREIGN KEY (emt_ect_id) REFERENCES escola_sabatina.classe_trimestre(ect_id),
    CONSTRAINT fk_emt_mem_id FOREIGN KEY (emt_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_emt_igr_id FOREIGN KEY (emt_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_emt_alvo CHECK (emt_alvo_oferta >= 0),
    CONSTRAINT chk_emt_end_date CHECK (emt_end_date IS NULL OR emt_end_date >= emt_criado_em)
);

COMMENT ON TABLE escola_sabatina.meta_individual IS 'Meta de oferta missionária de cada aluno da classe no trimestre; a da classe é a soma (V47)';
COMMENT ON COLUMN escola_sabatina.meta_individual.emt_igr_id IS 'Copiado da classe (segurança e desempenho)';
COMMENT ON COLUMN escola_sabatina.meta_individual.emt_alvo_oferta IS 'Meta do aluno para o trimestre';
CREATE UNIQUE INDEX uq_emt_ect_id_mem_id ON escola_sabatina.meta_individual (emt_ect_id, emt_mem_id) WHERE emt_end_date IS NULL;
CREATE INDEX idx_emt_mem_id ON escola_sabatina.meta_individual (emt_mem_id);
CREATE INDEX idx_emt_igr_pagina ON escola_sabatina.meta_individual (emt_igr_id, emt_id);

CREATE TABLE escola_sabatina.semana_especial (
    ese_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ese_igr_id INT NOT NULL,
    ese_tipo VARCHAR(20) NOT NULL,
    ese_nome VARCHAR(150) NOT NULL,
    ese_data_inicio DATE NOT NULL,
    ese_data_fim DATE NOT NULL,
    ese_observacoes VARCHAR(500),
    ese_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ese_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ese_criado_por INT,
    ese_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ese_modificado_por INT,
    ese_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ese_igr_id FOREIGN KEY (ese_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_ese_tipo CHECK (ese_tipo IN ('ORACAO', 'FAMILIA', 'EVANGELISMO', 'JOVENS', 'MORDOMIA', 'OUTRO')),
    CONSTRAINT chk_ese_datas CHECK (ese_data_fim >= ese_data_inicio),
    CONSTRAINT chk_ese_end_date CHECK (ese_end_date IS NULL OR ese_end_date >= ese_criado_em)
);

COMMENT ON TABLE escola_sabatina.semana_especial IS 'Programas especiais da semana (semana de oração, da família, de evangelismo…), com alerta (V47)';
COMMENT ON COLUMN escola_sabatina.semana_especial.ese_tipo IS 'ORACAO, FAMILIA, EVANGELISMO, JOVENS, MORDOMIA ou OUTRO';
COMMENT ON COLUMN escola_sabatina.semana_especial.ese_nome IS 'Ex.: Semana de Oração';
CREATE INDEX idx_ese_igr_pagina ON escola_sabatina.semana_especial (ese_igr_id, ese_id);
CREATE INDEX idx_ese_igr_datas ON escola_sabatina.semana_especial (ese_igr_id, ese_data_inicio) WHERE ese_end_date IS NULL;

CREATE TRIGGER trg_emt_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.meta_individual FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('emt', 'escola_sabatina.meta_individual', 'emt_igr_id');
CREATE TRIGGER trg_emt_00_sem_delete BEFORE DELETE ON escola_sabatina.meta_individual FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('emt');
CREATE TRIGGER trg_emt_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.meta_individual FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('emt');
CREATE TRIGGER trg_emt_99_log AFTER UPDATE ON escola_sabatina.meta_individual FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('emt');
ALTER TABLE escola_sabatina.meta_individual ADD CONSTRAINT fk_emt_criado_por FOREIGN KEY (emt_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.meta_individual ADD CONSTRAINT fk_emt_modificado_por FOREIGN KEY (emt_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_ese_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.semana_especial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ese', 'escola_sabatina.semana_especial', 'ese_igr_id');
CREATE TRIGGER trg_ese_00_sem_delete BEFORE DELETE ON escola_sabatina.semana_especial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ese');
CREATE TRIGGER trg_ese_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.semana_especial FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ese');
CREATE TRIGGER trg_ese_99_log AFTER UPDATE ON escola_sabatina.semana_especial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ese');
ALTER TABLE escola_sabatina.semana_especial ADD CONSTRAINT fk_ese_criado_por FOREIGN KEY (ese_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.semana_especial ADD CONSTRAINT fk_ese_modificado_por FOREIGN KEY (ese_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE escola_sabatina.meta_individual ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_emt_ler ON escola_sabatina.meta_individual FOR SELECT USING (emt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.meta_individual.ler'))::INT[]));
CREATE POLICY pol_emt_criar ON escola_sabatina.meta_individual FOR INSERT WITH CHECK (emt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.meta_individual.criar'))::INT[]));
CREATE POLICY pol_emt_alterar ON escola_sabatina.meta_individual FOR UPDATE USING (emt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.meta_individual.alterar'))::INT[])) WITH CHECK (emt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.meta_individual.alterar'))::INT[]));
ALTER TABLE escola_sabatina.semana_especial ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ese_ler ON escola_sabatina.semana_especial FOR SELECT USING (ese_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.semana_especial.ler'))::INT[]));
CREATE POLICY pol_ese_criar ON escola_sabatina.semana_especial FOR INSERT WITH CHECK (ese_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.semana_especial.criar'))::INT[]));
CREATE POLICY pol_ese_alterar ON escola_sabatina.semana_especial FOR UPDATE USING (ese_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.semana_especial.alterar'))::INT[])) WITH CHECK (ese_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('escola_sabatina.semana_especial.alterar'))::INT[]));

GRANT SELECT, INSERT, UPDATE ON escola_sabatina.meta_individual, escola_sabatina.semana_especial TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA escola_sabatina TO app_igreja;
COMMENT ON INDEX escola_sabatina.uq_emt_ect_id_mem_id IS '[membroId] Este aluno já tem meta nesta classe e trimestre.';
COMMENT ON CONSTRAINT chk_emt_alvo ON escola_sabatina.meta_individual IS '[alvoOferta] A meta não pode ser negativa.';
COMMENT ON CONSTRAINT chk_ese_tipo ON escola_sabatina.semana_especial IS '[tipo] Tipo de programa desconhecido.';
COMMENT ON CONSTRAINT chk_ese_datas ON escola_sabatina.semana_especial IS '[dataFim] O fim tem de ser no mesmo dia ou depois do início.';

-- permissões: as mesmas dos alvos das classes (escola_sabatina.classe_trimestre.*)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'escola_sabatina.' || t.tabela || '.' || a.accao, a.rotulo || t.descricao
  FROM (VALUES ('meta_individual', 'Meta de oferta missionária de cada aluno da classe no trimestre (V47)'),
               ('semana_especial', 'Programas especiais da semana (semana de oração, da família, de evangelismo…) (V47)')) t(tabela, descricao),
       (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'escola_sabatina.classe_trimestre.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo IN (replace(antigo.prm_codigo, 'classe_trimestre', 'meta_individual'),
                                                    replace(antigo.prm_codigo, 'classe_trimestre', 'semana_especial'))
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- meta individual: aluno da classe; a igreja vem da classe
CREATE FUNCTION escola_sabatina.fn_emt_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_ecl INT;
BEGIN
    SELECT ect_ecl_id, ect_igr_id INTO v_ecl, NEW.emt_igr_id FROM escola_sabatina.classe_trimestre WHERE ect_id = NEW.emt_ect_id;
    IF v_ecl IS NULL THEN
        RAISE EXCEPTION 'A classe deste trimestre não existe' USING COLUMN = 'emt_ect_id';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM escola_sabatina.matricula WHERE ema_ecl_id = v_ecl AND ema_mem_id = NEW.emt_mem_id AND ema_end_date IS NULL AND ema_data_saida IS NULL) THEN
        RAISE EXCEPTION 'O membro não está matriculado nesta classe' USING COLUMN = 'emt_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_emt_05_validar BEFORE INSERT OR UPDATE OF emt_ect_id, emt_mem_id ON escola_sabatina.meta_individual
    FOR EACH ROW EXECUTE FUNCTION escola_sabatina.fn_emt_validar();

-- a meta da classe é calculada: o alvo da oferta por sábado = soma das metas individuais ÷ sábados do trimestre
CREATE FUNCTION escola_sabatina.fn_emt_meta_da_classe() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_ect INT := COALESCE(NEW.emt_ect_id, OLD.emt_ect_id);
BEGIN
    UPDATE escola_sabatina.classe_trimestre ct
       SET ect_alvo_oferta_sabado = round(COALESCE((SELECT sum(m.emt_alvo_oferta) FROM escola_sabatina.meta_individual m
                                                     WHERE m.emt_ect_id = v_ect AND m.emt_end_date IS NULL), 0)
                                          / (SELECT t.etr_num_sabados FROM escola_sabatina.trimestre t WHERE t.etr_id = ct.ect_etr_id), 2)
     WHERE ct.ect_id = v_ect;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_emt_50_meta_da_classe AFTER INSERT OR UPDATE OF emt_alvo_oferta, emt_end_date, emt_ect_id ON escola_sabatina.meta_individual
    FOR EACH ROW EXECUTE FUNCTION escola_sabatina.fn_emt_meta_da_classe();

-- ---------------------------------------------------------------- acompanhamento: por aluno e por classe
-- Por aluno da classe no trimestre: a meta, o que deu (as ofertas dele na chamada) e os sábados em que esteve.
CREATE VIEW escola_sabatina.vw_metas_alunos WITH (security_invoker = true) AS
WITH dado AS (
    SELECT r.ers_ect_id AS ect_id, p.epr_mem_id AS mem_id, sum(p.epr_oferta) AS contribuido,
           count(*) FILTER (WHERE p.epr_presente) AS presencas
      FROM escola_sabatina.presenca p
      JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = p.epr_ers_id AND r.ers_end_date IS NULL
     WHERE p.epr_end_date IS NULL
     GROUP BY 1, 2
), alunos AS (
    SELECT ct.ect_id, m.ema_mem_id AS mem_id
      FROM escola_sabatina.classe_trimestre ct
      JOIN escola_sabatina.matricula m ON m.ema_ecl_id = ct.ect_ecl_id AND m.ema_end_date IS NULL AND m.ema_data_saida IS NULL
     WHERE ct.ect_end_date IS NULL
    UNION
    SELECT emt_ect_id, emt_mem_id FROM escola_sabatina.meta_individual WHERE emt_end_date IS NULL
    UNION
    SELECT ect_id, mem_id FROM dado
)
SELECT ct.ect_igr_id AS igreja_id, ct.ect_etr_id AS trimestre_id, a.ect_id AS classe_trimestre_id, a.mem_id AS membro_id,
       mb.mem_nome || ' ' || mb.mem_apelido AS nome,
       mt.emt_id AS meta_id, mt.emt_alvo_oferta AS meta, COALESCE(d.contribuido, 0) AS contribuido, COALESCE(d.presencas, 0) AS presencas,
       CASE WHEN mt.emt_alvo_oferta > 0 THEN round(COALESCE(d.contribuido, 0) / mt.emt_alvo_oferta, 4) END AS cumprimento
  FROM alunos a
  JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = a.ect_id
  JOIN secretaria.membro mb ON mb.mem_id = a.mem_id
  LEFT JOIN escola_sabatina.meta_individual mt ON mt.emt_ect_id = a.ect_id AND mt.emt_mem_id = a.mem_id AND mt.emt_end_date IS NULL
  LEFT JOIN dado d ON d.ect_id = a.ect_id AND d.mem_id = a.mem_id;
COMMENT ON VIEW escola_sabatina.vw_metas_alunos IS 'Meta individual, contribuição (chamada) e presenças de cada aluno da classe no trimestre (V47)';
GRANT SELECT ON escola_sabatina.vw_metas_alunos TO app_igreja;

-- Por classe no trimestre: a meta (a soma das individuais, ou o alvo por sábado × sábados), o contribuído (relatórios)
-- e quanto disso está identificado por aluno.
CREATE VIEW escola_sabatina.vw_metas_classes WITH (security_invoker = true) AS
SELECT ct.ect_igr_id AS igreja_id, ct.ect_etr_id AS trimestre_id, ct.ect_id AS classe_trimestre_id, c.ecl_nome AS classe,
       c.ecl_divisao AS divisao,
       (SELECT count(*) FROM escola_sabatina.matricula m WHERE m.ema_ecl_id = ct.ect_ecl_id AND m.ema_end_date IS NULL AND m.ema_data_saida IS NULL) AS alunos,
       (SELECT count(*) FROM escola_sabatina.meta_individual m WHERE m.emt_ect_id = ct.ect_id AND m.emt_end_date IS NULL) AS com_meta,
       COALESCE((SELECT sum(m.emt_alvo_oferta) FROM escola_sabatina.meta_individual m WHERE m.emt_ect_id = ct.ect_id AND m.emt_end_date IS NULL),
                ct.ect_alvo_oferta_sabado * t.etr_num_sabados) AS meta,
       COALESCE((SELECT sum(r.ers_oferta) FROM escola_sabatina.relatorio_sabado r WHERE r.ers_ect_id = ct.ect_id AND r.ers_end_date IS NULL), 0) AS contribuido,
       COALESCE((SELECT sum(p.epr_oferta) FROM escola_sabatina.presenca p JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = p.epr_ers_id
                  WHERE r.ers_ect_id = ct.ect_id AND r.ers_end_date IS NULL AND p.epr_end_date IS NULL), 0) AS identificado,
       (SELECT count(*) FROM escola_sabatina.relatorio_sabado r WHERE r.ers_ect_id = ct.ect_id AND r.ers_end_date IS NULL) AS sabados_com_relatorio,
       t.etr_num_sabados AS sabados
  FROM escola_sabatina.classe_trimestre ct
  JOIN escola_sabatina.classe c ON c.ecl_id = ct.ect_ecl_id
  JOIN escola_sabatina.trimestre t ON t.etr_id = ct.ect_etr_id
 WHERE ct.ect_end_date IS NULL;
COMMENT ON VIEW escola_sabatina.vw_metas_classes IS 'Meta da classe (soma das individuais), contribuído e identificado por aluno, no trimestre (V47)';
GRANT SELECT ON escola_sabatina.vw_metas_classes TO app_igreja;

-- >>>>> V48__acompanhamento_das_actividades.sql
-- =====================================================================
-- V48 · Acompanhamento das actividades (F-ACT): o motivo do cancelamento
--
--   actividade.act_motivo_cancelamento   obrigatório ao cancelar (o trigger recusa cancelar sem ele): as canceladas
--                                        ficam explicadas no acompanhamento da igreja e da área pastoral.
--   vw_actividades_execucao              ganha motivo_cancelamento e actualizada_em (colunas no fim).
-- Nada se apaga: as canceladas antes desta versão ficam sem motivo.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE actividades.actividade ADD COLUMN act_motivo_cancelamento VARCHAR(255);
COMMENT ON COLUMN actividades.actividade.act_motivo_cancelamento IS 'Porque foi cancelada (obrigatório ao cancelar; V48)';

CREATE FUNCTION actividades.fn_act_cancelar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.act_estado::TEXT = 'CANCELADA' AND OLD.act_estado::TEXT <> 'CANCELADA'
       AND coalesce(trim(NEW.act_motivo_cancelamento), '') = '' THEN
        RAISE EXCEPTION 'Diga porque a actividade é cancelada' USING COLUMN = 'act_motivo_cancelamento';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_act_20_cancelar BEFORE UPDATE OF act_estado ON actividades.actividade
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_act_cancelar();

-- ---------------------------------------------------------------- o programa com o motivo e a última mudança
CREATE OR REPLACE VIEW actividades.vw_actividades_execucao WITH (security_invoker = true) AS
WITH base AS (
    SELECT a.*, d.ide_igr_id AS igreja_id, dp.dep_nome AS departamento, 'IGREJA'::TEXT AS origem, NULL::INT AS distrito_id, NULL::TEXT AS distrito
      FROM actividades.actividade a
      JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
     WHERE a.act_end_date IS NULL
    UNION ALL
    SELECT a.*, i.igr_id, 'Área pastoral', 'AREA_PASTORAL', ds.dst_id, ds.dst_nome::TEXT
      FROM actividades.actividade a
      JOIN organizacao.distrito ds ON ds.dst_id = a.act_dst_id
      JOIN organizacao.igreja i ON i.igr_dst_id = ds.dst_id AND i.igr_end_date IS NULL
     WHERE a.act_end_date IS NULL
)
SELECT a.act_id, a.igreja_id, a.act_ide_id AS departamento_igreja_id, a.departamento::VARCHAR(100) AS departamento,
       a.act_nome AS nome, a.act_descricao AS descricao, a.act_objectivos AS objectivos, a.act_local AS local,
       a.act_data_inicio AS data_inicio, a.act_data_fim AS data_fim, a.act_estado AS estado,
       EXTRACT(YEAR FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT  AS ano,
       EXTRACT(MONTH FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       a.act_responsavel_mem_id AS responsavel_mem_id,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = a.act_responsavel_mem_id) AS responsavel,
       (SELECT count(*) FROM actividades.actividade_responsavel r WHERE r.acr_act_id = a.act_id AND r.acr_end_date IS NULL)::INT AS outros_responsaveis,
       a.act_valor_previsto AS valor_previsto,
       coalesce((SELECT sum(x.mat_quantidade * x.mat_preco_unitario) FROM actividades.material x
                  WHERE x.mat_act_id = a.act_id AND x.mat_end_date IS NULL), 0)::DECIMAL(14,2) AS material_previsto,
       coalesce((SELECT sum(x.des_valor_solicitado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('SUBMETIDA', 'APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_pedidas,
       coalesce((SELECT sum(x.des_valor_aprovado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_aprovadas,
       coalesce((SELECT sum(CASE WHEN t.tra_tipo = 'SAIDA' THEN l.tli_valor ELSE -l.tli_valor END)
                   FROM tesouraria.transacao_linha l JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id
                  WHERE l.tli_act_id = a.act_id AND l.tli_end_date IS NULL AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
                    AND (t.tra_tipo = 'SAIDA' OR (t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NOT NULL))), 0)::DECIMAL(14,2) AS executado,
       a.origem, a.distrito_id, a.distrito,
       -- V48: porque foi cancelada e quando mudou pela última vez (acompanhamento)
       a.act_motivo_cancelamento AS motivo_cancelamento, a.act_modificado_em AS actualizada_em
FROM base a;

-- >>>>> V49__reavivamento_por_pessoa.sql
-- =====================================================================
-- V49 · Reavivamento por pessoa: o alvo da igreja repartido por adultos e crianças, com quota ajustável
--   quota_reavivamento        a quota de uma pessoa no ano, quando o tesoureiro a muda à mão (ex.: sem rendimento).
--   vw_reavivamento_pessoas   por igreja, ano e pessoa: a quota (a ajustada, ou a parte igual do que sobra do alvo),
--                             o que já deu no fundo REAVIVAMENTO e o que falta.
-- Quem conta: os membros activos e as crianças (menos de 18 anos) registadas na igreja, activas ou interessadas.
-- O alvo é o dos "Alvos" no fundo REAVIVAMENTO desse ano (somados, se houver mais de um).
-- Permissões novas: as mesmas dos alvos (tesouraria.alvo.*). Gerado com database/gerador.
-- Também: o cartão de eleitor como tipo de documento da ficha do membro.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- documento novo na ficha do membro: cartão de eleitor
ALTER TYPE nucleo.tipo_identificacao_t ADD VALUE IF NOT EXISTS 'CARTAO_ELEITOR';

-- ---------------------------------------------------------------- tabela (gerada: gen.py)
CREATE TABLE tesouraria.quota_reavivamento (
    qrv_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    qrv_igr_id INT NOT NULL,
    qrv_mem_id INT NOT NULL,
    qrv_ano SMALLINT NOT NULL,
    qrv_valor DECIMAL(12,2) NOT NULL,
    qrv_motivo VARCHAR(255),
    qrv_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    qrv_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    qrv_criado_por INT,
    qrv_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    qrv_modificado_por INT,
    qrv_end_date TIMESTAMPTZ,
    CONSTRAINT fk_qrv_igr_id FOREIGN KEY (qrv_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_qrv_mem_id FOREIGN KEY (qrv_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_qrv_valor CHECK (qrv_valor >= 0),
    CONSTRAINT chk_qrv_ano CHECK (qrv_ano BETWEEN 2000 AND 2100),
    CONSTRAINT chk_qrv_end_date CHECK (qrv_end_date IS NULL OR qrv_end_date >= qrv_criado_em)
);
COMMENT ON TABLE tesouraria.quota_reavivamento IS 'Quota do reavivamento de uma pessoa no ano, ajustada à mão (as outras repartem o alvo; V49)';
COMMENT ON COLUMN tesouraria.quota_reavivamento.qrv_igr_id IS 'Copiado do membro (segurança e desempenho)';
COMMENT ON COLUMN tesouraria.quota_reavivamento.qrv_valor IS 'Quota da pessoa no ano';
COMMENT ON COLUMN tesouraria.quota_reavivamento.qrv_motivo IS 'Ex.: sem rendimento';
CREATE UNIQUE INDEX uq_qrv_mem_id_ano ON tesouraria.quota_reavivamento (qrv_mem_id, qrv_ano) WHERE qrv_end_date IS NULL;
CREATE INDEX idx_qrv_igr_pagina ON tesouraria.quota_reavivamento (qrv_igr_id, qrv_id);

CREATE TRIGGER trg_qrv_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.quota_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('qrv', 'tesouraria.quota_reavivamento', 'qrv_igr_id');
CREATE TRIGGER trg_qrv_00_sem_delete BEFORE DELETE ON tesouraria.quota_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('qrv');
CREATE TRIGGER trg_qrv_00_sem_truncate BEFORE TRUNCATE ON tesouraria.quota_reavivamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('qrv');
CREATE TRIGGER trg_qrv_99_log AFTER UPDATE ON tesouraria.quota_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('qrv');
ALTER TABLE tesouraria.quota_reavivamento ADD CONSTRAINT fk_qrv_criado_por FOREIGN KEY (qrv_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.quota_reavivamento ADD CONSTRAINT fk_qrv_modificado_por FOREIGN KEY (qrv_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE tesouraria.quota_reavivamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_qrv_ler ON tesouraria.quota_reavivamento FOR SELECT USING (qrv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_reavivamento.ler'))::INT[]));
CREATE POLICY pol_qrv_criar ON tesouraria.quota_reavivamento FOR INSERT WITH CHECK (qrv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_reavivamento.criar'))::INT[]));
CREATE POLICY pol_qrv_alterar ON tesouraria.quota_reavivamento FOR UPDATE USING (qrv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_reavivamento.alterar'))::INT[])) WITH CHECK (qrv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_reavivamento.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON tesouraria.quota_reavivamento TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
COMMENT ON INDEX tesouraria.uq_qrv_mem_id_ano IS '[membroId] Esta pessoa já tem quota ajustada neste ano.';
COMMENT ON CONSTRAINT chk_qrv_valor ON tesouraria.quota_reavivamento IS '[valor] A quota não pode ser negativa.';
COMMENT ON CONSTRAINT chk_qrv_ano ON tesouraria.quota_reavivamento IS '[ano] Ano inválido.';

-- permissões: as mesmas dos alvos (tesouraria.alvo.*)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'tesouraria.quota_reavivamento.' || a.accao, a.rotulo || 'Quota do reavivamento de uma pessoa no ano (V49)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'tesouraria.alvo.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, 'tesouraria.alvo.', 'tesouraria.quota_reavivamento.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- a quota é de uma pessoa da igreja; a igreja vem do membro
CREATE FUNCTION tesouraria.fn_qrv_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT mem_igr_id INTO NEW.qrv_igr_id FROM secretaria.membro WHERE mem_id = NEW.qrv_mem_id AND mem_end_date IS NULL;
    IF NEW.qrv_igr_id IS NULL THEN
        RAISE EXCEPTION 'A pessoa não existe' USING COLUMN = 'qrv_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_qrv_05_validar BEFORE INSERT OR UPDATE OF qrv_mem_id ON tesouraria.quota_reavivamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_qrv_validar();

-- ---------------------------------------------------------------- por pessoa: quota, contribuído e falta
-- quota = a ajustada, ou (alvo − soma das ajustadas) ÷ pessoas sem ajuste, para que a soma das quotas dê o alvo.
CREATE VIEW tesouraria.vw_reavivamento_pessoas WITH (security_invoker = true) AS
WITH alvos AS (
    SELECT a.alv_igr_id AS igr_id, EXTRACT(YEAR FROM a.alv_data_inicio)::INT AS ano, SUM(a.alv_valor_alvo) AS alvo
      FROM tesouraria.alvo a
      JOIN tesouraria.fundo f ON f.fun_id = a.alv_fun_id AND f.fun_tipo::TEXT = 'REAVIVAMENTO'
     WHERE a.alv_end_date IS NULL
     GROUP BY 1, 2
),
pessoas AS (
    SELECT m.mem_igr_id AS igr_id, m.mem_id, m.mem_nome, m.mem_apelido, m.mem_data_nascimento,
           (m.mem_data_nascimento IS NOT NULL AND m.mem_data_nascimento > current_date - INTERVAL '18 years') AS menor
      FROM secretaria.membro m
     WHERE m.mem_end_date IS NULL
       AND (m.mem_estado::TEXT = 'ACTIVO'
            OR (m.mem_estado::TEXT = 'INTERESSADO' AND m.mem_data_nascimento > current_date - INTERVAL '18 years'))
),
base AS (
    SELECT p.*, a.ano, a.alvo, q.qrv_id, q.qrv_valor, q.qrv_motivo
      FROM pessoas p
      JOIN alvos a ON a.igr_id = p.igr_id
      LEFT JOIN tesouraria.quota_reavivamento q ON q.qrv_mem_id = p.mem_id AND q.qrv_ano = a.ano AND q.qrv_end_date IS NULL
),
partilha AS (
    SELECT igr_id, ano,
           GREATEST(MAX(alvo) - COALESCE(SUM(qrv_valor), 0), 0) AS resto,
           COUNT(*) FILTER (WHERE qrv_id IS NULL) AS sem_ajuste
      FROM base GROUP BY 1, 2
),
dado AS (
    SELECT t.tra_mem_id AS mem_id, EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano, SUM(l.tli_valor) AS valor
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
      JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo::TEXT = 'REAVIVAMENTO'
     WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA'
       AND t.tra_estorno_tra_id IS NULL AND t.tra_mem_id IS NOT NULL
     GROUP BY 1, 2
)
SELECT b.igr_id AS igreja_id, b.ano, b.mem_id AS membro_id, b.mem_nome AS nome, b.mem_apelido AS apelido,
       b.mem_data_nascimento AS data_nascimento, b.menor, b.alvo AS alvo_igreja,
       b.qrv_id AS quota_id, b.qrv_valor AS quota_ajustada, b.qrv_motivo AS motivo,
       ROUND(COALESCE(b.qrv_valor, p.resto / NULLIF(p.sem_ajuste, 0), 0), 2) AS quota,
       COALESCE(d.valor, 0) AS contribuido,
       GREATEST(ROUND(COALESCE(b.qrv_valor, p.resto / NULLIF(p.sem_ajuste, 0), 0), 2) - COALESCE(d.valor, 0), 0) AS falta
  FROM base b
  JOIN partilha p ON p.igr_id = b.igr_id AND p.ano = b.ano
  LEFT JOIN dado d ON d.mem_id = b.mem_id AND d.ano = b.ano;
COMMENT ON VIEW tesouraria.vw_reavivamento_pessoas IS 'Reavivamento por pessoa e ano: quota (ajustada ou parte igual do alvo), contribuído e falta (V49)';
GRANT SELECT ON tesouraria.vw_reavivamento_pessoas TO app_igreja;

-- >>>>> V50__extractos_departamentos_e_fundos.sql
-- =====================================================================
-- V50 · Extractos por departamento e por fundo (mês, trimestre, semestre ou ano)
--   percentagem_departamento    a parte de cada departamento no ano (a soma não passa de 100%): reparte a doação distribuída.
--   transferencia_departamento  saldo passado de um departamento para outro.
--   adiantamento                dinheiro adiantado a um responsável do departamento, que presta contas depois.
--   fn_extracto_departamentos   por departamento: % , saldo inicial, doação directa, doação distribuída, despesas,
--                               transferências (saída e entrada), estornos, adiantamentos e saldo final.
--   fn_extracto_fundos          por fundo: saldo inicial, entradas, saídas e saldo final.
-- Doação directa = entradas com o departamento na linha. Doação distribuída = a parte da igreja nas entradas sem
-- departamento da oferta combinada e do orçamento da igreja local, repartida pela % de cada departamento nesse ano.
-- Despesas = saídas com o departamento. Estornos = movimentos de estorno com o departamento.
-- Permissões novas: as mesmas do orçamento (tesouraria.orcamento.*). Gerado com database/gerador.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- tabelas (geradas: gen.py)
CREATE TABLE tesouraria.percentagem_departamento (
    dpp_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    dpp_igr_id INT NOT NULL,
    dpp_ide_id INT NOT NULL,
    dpp_ano SMALLINT NOT NULL,
    dpp_percentagem DECIMAL(5,2) NOT NULL,
    dpp_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    dpp_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dpp_criado_por INT,
    dpp_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    dpp_modificado_por INT,
    dpp_end_date TIMESTAMPTZ,
    CONSTRAINT fk_dpp_igr_id FOREIGN KEY (dpp_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_dpp_ide_id FOREIGN KEY (dpp_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT chk_dpp_percentagem CHECK (dpp_percentagem BETWEEN 0 AND 100),
    CONSTRAINT chk_dpp_ano CHECK (dpp_ano BETWEEN 2000 AND 2100),
    CONSTRAINT chk_dpp_end_date CHECK (dpp_end_date IS NULL OR dpp_end_date >= dpp_criado_em)
);
COMMENT ON TABLE tesouraria.percentagem_departamento IS 'Parte de cada departamento no ano: reparte a doação distribuída (V50)';
COMMENT ON COLUMN tesouraria.percentagem_departamento.dpp_igr_id IS 'Copiado do departamento';
CREATE UNIQUE INDEX uq_dpp_ide_id_ano ON tesouraria.percentagem_departamento (dpp_ide_id, dpp_ano) WHERE dpp_end_date IS NULL;
CREATE INDEX idx_dpp_igr_pagina ON tesouraria.percentagem_departamento (dpp_igr_id, dpp_id);

CREATE TABLE tesouraria.transferencia_departamento (
    tdp_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tdp_igr_id INT NOT NULL,
    tdp_origem_ide_id INT NOT NULL,
    tdp_destino_ide_id INT NOT NULL,
    tdp_data DATE NOT NULL,
    tdp_valor DECIMAL(14,2) NOT NULL,
    tdp_descricao VARCHAR(255),
    tdp_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    tdp_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tdp_criado_por INT,
    tdp_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    tdp_modificado_por INT,
    tdp_end_date TIMESTAMPTZ,
    CONSTRAINT fk_tdp_igr_id FOREIGN KEY (tdp_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_tdp_origem_ide_id FOREIGN KEY (tdp_origem_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_tdp_destino_ide_id FOREIGN KEY (tdp_destino_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT chk_tdp_valor CHECK (tdp_valor > 0),
    CONSTRAINT chk_tdp_diferentes CHECK (tdp_origem_ide_id <> tdp_destino_ide_id),
    CONSTRAINT chk_tdp_end_date CHECK (tdp_end_date IS NULL OR tdp_end_date >= tdp_criado_em)
);
COMMENT ON TABLE tesouraria.transferencia_departamento IS 'Transferência de saldo entre departamentos da igreja (V50)';
COMMENT ON COLUMN tesouraria.transferencia_departamento.tdp_igr_id IS 'Copiado do departamento de origem';
CREATE INDEX idx_tdp_igr_pagina ON tesouraria.transferencia_departamento (tdp_igr_id, tdp_id);
CREATE INDEX idx_tdp_origem_ide_id ON tesouraria.transferencia_departamento (tdp_origem_ide_id);
CREATE INDEX idx_tdp_destino_ide_id ON tesouraria.transferencia_departamento (tdp_destino_ide_id);

CREATE TABLE tesouraria.adiantamento (
    adt_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    adt_igr_id INT NOT NULL,
    adt_ide_id INT NOT NULL,
    adt_mem_id INT NOT NULL,
    adt_data DATE NOT NULL,
    adt_valor DECIMAL(14,2) NOT NULL,
    adt_descricao VARCHAR(255) NOT NULL,
    adt_data_prestacao DATE,
    adt_valor_devolvido DECIMAL(14,2) NOT NULL DEFAULT 0,
    adt_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    adt_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    adt_criado_por INT,
    adt_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    adt_modificado_por INT,
    adt_end_date TIMESTAMPTZ,
    CONSTRAINT fk_adt_igr_id FOREIGN KEY (adt_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_adt_ide_id FOREIGN KEY (adt_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT fk_adt_mem_id FOREIGN KEY (adt_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_adt_valor CHECK (adt_valor > 0),
    CONSTRAINT chk_adt_devolvido CHECK (adt_valor_devolvido BETWEEN 0 AND adt_valor),
    CONSTRAINT chk_adt_prestacao CHECK (adt_data_prestacao IS NULL OR adt_data_prestacao >= adt_data),
    CONSTRAINT chk_adt_end_date CHECK (adt_end_date IS NULL OR adt_end_date >= adt_criado_em)
);
COMMENT ON TABLE tesouraria.adiantamento IS 'Dinheiro adiantado a um responsável do departamento, que presta contas depois (V50)';
COMMENT ON COLUMN tesouraria.adiantamento.adt_igr_id IS 'Copiado do departamento';
COMMENT ON COLUMN tesouraria.adiantamento.adt_mem_id IS 'Quem recebeu';
COMMENT ON COLUMN tesouraria.adiantamento.adt_data_prestacao IS 'Quando prestou contas';
COMMENT ON COLUMN tesouraria.adiantamento.adt_valor_devolvido IS 'O que sobrou e voltou ao departamento';
CREATE INDEX idx_adt_igr_pagina ON tesouraria.adiantamento (adt_igr_id, adt_id);
CREATE INDEX idx_adt_ide_id ON tesouraria.adiantamento (adt_ide_id);
CREATE INDEX idx_adt_mem_id ON tesouraria.adiantamento (adt_mem_id);

CREATE TRIGGER trg_dpp_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.percentagem_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dpp', 'tesouraria.percentagem_departamento', 'dpp_igr_id');
CREATE TRIGGER trg_dpp_00_sem_delete BEFORE DELETE ON tesouraria.percentagem_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dpp');
CREATE TRIGGER trg_dpp_00_sem_truncate BEFORE TRUNCATE ON tesouraria.percentagem_departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dpp');
CREATE TRIGGER trg_dpp_99_log AFTER UPDATE ON tesouraria.percentagem_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dpp');
ALTER TABLE tesouraria.percentagem_departamento ADD CONSTRAINT fk_dpp_criado_por FOREIGN KEY (dpp_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.percentagem_departamento ADD CONSTRAINT fk_dpp_modificado_por FOREIGN KEY (dpp_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_tdp_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.transferencia_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tdp', 'tesouraria.transferencia_departamento', 'tdp_igr_id');
CREATE TRIGGER trg_tdp_00_sem_delete BEFORE DELETE ON tesouraria.transferencia_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tdp');
CREATE TRIGGER trg_tdp_00_sem_truncate BEFORE TRUNCATE ON tesouraria.transferencia_departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tdp');
CREATE TRIGGER trg_tdp_99_log AFTER UPDATE ON tesouraria.transferencia_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tdp');
ALTER TABLE tesouraria.transferencia_departamento ADD CONSTRAINT fk_tdp_criado_por FOREIGN KEY (tdp_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.transferencia_departamento ADD CONSTRAINT fk_tdp_modificado_por FOREIGN KEY (tdp_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_adt_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.adiantamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('adt', 'tesouraria.adiantamento', 'adt_igr_id');
CREATE TRIGGER trg_adt_00_sem_delete BEFORE DELETE ON tesouraria.adiantamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('adt');
CREATE TRIGGER trg_adt_00_sem_truncate BEFORE TRUNCATE ON tesouraria.adiantamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('adt');
CREATE TRIGGER trg_adt_99_log AFTER UPDATE ON tesouraria.adiantamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('adt');
ALTER TABLE tesouraria.adiantamento ADD CONSTRAINT fk_adt_criado_por FOREIGN KEY (adt_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.adiantamento ADD CONSTRAINT fk_adt_modificado_por FOREIGN KEY (adt_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.percentagem_departamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dpp_ler ON tesouraria.percentagem_departamento FOR SELECT USING (dpp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.percentagem_departamento.ler'))::INT[]));
CREATE POLICY pol_dpp_criar ON tesouraria.percentagem_departamento FOR INSERT WITH CHECK (dpp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.percentagem_departamento.criar'))::INT[]));
CREATE POLICY pol_dpp_alterar ON tesouraria.percentagem_departamento FOR UPDATE USING (dpp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.percentagem_departamento.alterar'))::INT[])) WITH CHECK (dpp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.percentagem_departamento.alterar'))::INT[]));
ALTER TABLE tesouraria.transferencia_departamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_tdp_ler ON tesouraria.transferencia_departamento FOR SELECT USING (tdp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transferencia_departamento.ler'))::INT[]));
CREATE POLICY pol_tdp_criar ON tesouraria.transferencia_departamento FOR INSERT WITH CHECK (tdp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transferencia_departamento.criar'))::INT[]));
CREATE POLICY pol_tdp_alterar ON tesouraria.transferencia_departamento FOR UPDATE USING (tdp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transferencia_departamento.alterar'))::INT[])) WITH CHECK (tdp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transferencia_departamento.alterar'))::INT[]));
ALTER TABLE tesouraria.adiantamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_adt_ler ON tesouraria.adiantamento FOR SELECT USING (adt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.adiantamento.ler'))::INT[]));
CREATE POLICY pol_adt_criar ON tesouraria.adiantamento FOR INSERT WITH CHECK (adt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.adiantamento.criar'))::INT[]));
CREATE POLICY pol_adt_alterar ON tesouraria.adiantamento FOR UPDATE USING (adt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.adiantamento.alterar'))::INT[])) WITH CHECK (adt_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.adiantamento.alterar'))::INT[]));

GRANT SELECT, INSERT, UPDATE ON tesouraria.percentagem_departamento, tesouraria.transferencia_departamento, tesouraria.adiantamento TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
COMMENT ON INDEX tesouraria.uq_dpp_ide_id_ano IS '[departamentoIgrejaId] Este departamento já tem percentagem neste ano.';
COMMENT ON CONSTRAINT chk_dpp_percentagem ON tesouraria.percentagem_departamento IS '[percentagem] A percentagem é de 0 a 100.';
COMMENT ON CONSTRAINT chk_dpp_ano ON tesouraria.percentagem_departamento IS '[ano] Ano inválido.';
COMMENT ON CONSTRAINT chk_tdp_valor ON tesouraria.transferencia_departamento IS '[valor] O valor tem de ser maior do que zero.';
COMMENT ON CONSTRAINT chk_tdp_diferentes ON tesouraria.transferencia_departamento IS '[destinoDepartamentoIgrejaId] O destino tem de ser outro departamento.';
COMMENT ON CONSTRAINT chk_adt_valor ON tesouraria.adiantamento IS '[valor] O valor tem de ser maior do que zero.';
COMMENT ON CONSTRAINT chk_adt_devolvido ON tesouraria.adiantamento IS '[valorDevolvido] O devolvido vai de zero ao valor adiantado.';
COMMENT ON CONSTRAINT chk_adt_prestacao ON tesouraria.adiantamento IS '[dataPrestacao] A prestação de contas é no dia do adiantamento ou depois.';

-- permissões: as mesmas do orçamento (tesouraria.orcamento.*)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'tesouraria.' || t.tabela || '.' || a.accao, a.rotulo || t.descricao
  FROM (VALUES ('percentagem_departamento', 'Parte de cada departamento no ano (V50)'),
               ('transferencia_departamento', 'Transferência entre departamentos (V50)'),
               ('adiantamento', 'Adiantamento a um responsável do departamento (V50)')) t(tabela, descricao),
       (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'tesouraria.orcamento.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo IN (replace(antigo.prm_codigo, '.orcamento.', '.percentagem_departamento.'),
                                                    replace(antigo.prm_codigo, '.orcamento.', '.transferencia_departamento.'),
                                                    replace(antigo.prm_codigo, '.orcamento.', '.adiantamento.'))
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- validações: a igreja vem do departamento
CREATE FUNCTION tesouraria.fn_dpp_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_soma NUMERIC;
BEGIN
    SELECT ide_igr_id INTO NEW.dpp_igr_id FROM organizacao.igreja_departamento WHERE ide_id = NEW.dpp_ide_id;
    IF NEW.dpp_igr_id IS NULL THEN
        RAISE EXCEPTION 'O departamento não existe' USING COLUMN = 'dpp_ide_id';
    END IF;
    IF NEW.dpp_end_date IS NULL THEN
        SELECT COALESCE(SUM(dpp_percentagem), 0) INTO v_soma FROM tesouraria.percentagem_departamento
         WHERE dpp_igr_id = NEW.dpp_igr_id AND dpp_ano = NEW.dpp_ano AND dpp_end_date IS NULL AND dpp_id <> COALESCE(NEW.dpp_id, 0);
        IF v_soma + NEW.dpp_percentagem > 100 THEN
            RAISE EXCEPTION 'As percentagens dos departamentos passam de 100%% em %', NEW.dpp_ano USING COLUMN = 'dpp_percentagem';
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_dpp_05_validar BEFORE INSERT OR UPDATE ON tesouraria.percentagem_departamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_dpp_validar();

CREATE FUNCTION tesouraria.fn_tdp_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT ide_igr_id INTO NEW.tdp_igr_id FROM organizacao.igreja_departamento WHERE ide_id = NEW.tdp_origem_ide_id;
    IF NEW.tdp_igr_id IS NULL THEN
        RAISE EXCEPTION 'O departamento de origem não existe' USING COLUMN = 'tdp_origem_ide_id';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM organizacao.igreja_departamento WHERE ide_id = NEW.tdp_destino_ide_id AND ide_igr_id = NEW.tdp_igr_id) THEN
        RAISE EXCEPTION 'O destino tem de ser um departamento da mesma igreja' USING COLUMN = 'tdp_destino_ide_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_tdp_05_validar BEFORE INSERT OR UPDATE OF tdp_origem_ide_id, tdp_destino_ide_id ON tesouraria.transferencia_departamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tdp_validar();

CREATE FUNCTION tesouraria.fn_adt_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT ide_igr_id INTO NEW.adt_igr_id FROM organizacao.igreja_departamento WHERE ide_id = NEW.adt_ide_id;
    IF NEW.adt_igr_id IS NULL THEN
        RAISE EXCEPTION 'O departamento não existe' USING COLUMN = 'adt_ide_id';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM secretaria.membro WHERE mem_id = NEW.adt_mem_id AND mem_igr_id = NEW.adt_igr_id AND mem_end_date IS NULL) THEN
        RAISE EXCEPTION 'Quem recebe tem de ser membro desta igreja' USING COLUMN = 'adt_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_adt_05_validar BEFORE INSERT OR UPDATE OF adt_ide_id, adt_mem_id ON tesouraria.adiantamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_adt_validar();

-- ---------------------------------------------------------------- extracto por departamento num período
-- Todos os registos até ao fim do período; o que é antes do início vai para o saldo inicial.
CREATE FUNCTION tesouraria.fn_extracto_departamentos(p_igreja INT, p_inicio DATE, p_fim DATE)
RETURNS TABLE (departamento_igreja_id INT, departamento VARCHAR, percentagem NUMERIC, saldo_inicial NUMERIC,
               doacao_directa NUMERIC, doacao_distribuida NUMERIC, despesas NUMERIC, transf_saida NUMERIC,
               transf_entrada NUMERIC, estornos NUMERIC, adiantamentos NUMERIC, saldo_final NUMERIC)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
WITH linhas AS (
    SELECT l.tli_ide_id AS ide, (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE AS dia, t.tra_tipo::TEXT AS tipo,
           t.tra_estorno_tra_id IS NOT NULL AS estorno, l.tli_valor AS valor, f.fun_tipo::TEXT AS fundo, f.fun_percentagem_remessa AS remessa
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
      JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id
     WHERE t.tra_igr_id = p_igreja AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
       AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE <= p_fim
),
deps AS (
    SELECT d.ide_id, dp.dep_nome
      FROM organizacao.igreja_departamento d JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
     WHERE d.ide_igr_id = p_igreja AND d.ide_end_date IS NULL
),
pct AS (
    SELECT dpp_ide_id AS ide, dpp_ano AS ano, dpp_percentagem AS p FROM tesouraria.percentagem_departamento
     WHERE dpp_igr_id = p_igreja AND dpp_end_date IS NULL
),
mov AS (
    -- doação directa, despesas e estornos (linhas com o departamento)
    SELECT ide, dia, CASE WHEN estorno THEN 'EST' WHEN tipo = 'ENTRADA' THEN 'DIR' ELSE 'DES' END AS col,
           CASE WHEN tipo = 'ENTRADA' THEN valor ELSE -valor END AS v
      FROM linhas WHERE ide IS NOT NULL
    UNION ALL
    -- doação distribuída: a parte da igreja nas entradas gerais, pela % do departamento nesse ano
    SELECT pc.ide, l.dia, 'DIS', l.valor * (100 - l.remessa) / 100 * pc.p / 100
      FROM linhas l JOIN pct pc ON pc.ano = EXTRACT(YEAR FROM l.dia)
     WHERE l.ide IS NULL AND NOT l.estorno AND l.tipo = 'ENTRADA' AND l.fundo IN ('OFERTA_COMBINADA', 'ORCAMENTO_LOCAL')
    UNION ALL
    SELECT tdp_origem_ide_id, tdp_data, 'TSA', -tdp_valor FROM tesouraria.transferencia_departamento
     WHERE tdp_igr_id = p_igreja AND tdp_end_date IS NULL AND tdp_data <= p_fim
    UNION ALL
    SELECT tdp_destino_ide_id, tdp_data, 'TEN', tdp_valor FROM tesouraria.transferencia_departamento
     WHERE tdp_igr_id = p_igreja AND tdp_end_date IS NULL AND tdp_data <= p_fim
    UNION ALL
    SELECT adt_ide_id, adt_data, 'ADI', -(adt_valor - adt_valor_devolvido) FROM tesouraria.adiantamento
     WHERE adt_igr_id = p_igreja AND adt_end_date IS NULL AND adt_data <= p_fim
)
SELECT d.ide_id, d.dep_nome,
       (SELECT p FROM pct WHERE pct.ide = d.ide_id AND pct.ano = EXTRACT(YEAR FROM p_inicio)),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia < p_inicio), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'DIR'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'DIS'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'DES'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'TSA'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'TEN'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'EST'), 0), 2),
       ROUND(COALESCE(SUM(m.v) FILTER (WHERE m.dia >= p_inicio AND m.col = 'ADI'), 0), 2),
       ROUND(COALESCE(SUM(m.v), 0), 2)
  FROM deps d LEFT JOIN mov m ON m.ide = d.ide_id
 GROUP BY d.ide_id, d.dep_nome
 ORDER BY d.dep_nome
$$;
COMMENT ON FUNCTION tesouraria.fn_extracto_departamentos(INT, DATE, DATE) IS 'Extracto por departamento num período (V50)';
GRANT EXECUTE ON FUNCTION tesouraria.fn_extracto_departamentos(INT, DATE, DATE) TO app_igreja;

-- ---------------------------------------------------------------- extracto por fundo num período
CREATE FUNCTION tesouraria.fn_extracto_fundos(p_igreja INT, p_inicio DATE, p_fim DATE)
RETURNS TABLE (fundo_id INT, fundo VARCHAR, tipo TEXT, saldo_inicial NUMERIC, entradas NUMERIC, saidas NUMERIC, saldo_final NUMERIC)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
WITH linhas AS (
    SELECT l.tli_fun_id AS fun, (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE AS dia,
           CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END AS v
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
     WHERE t.tra_igr_id = p_igreja AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
       AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND (t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE <= p_fim
)
SELECT f.fun_id, f.fun_nome, f.fun_tipo::TEXT,
       ROUND(COALESCE(SUM(l.v) FILTER (WHERE l.dia < p_inicio), 0), 2),
       ROUND(COALESCE(SUM(l.v) FILTER (WHERE l.dia >= p_inicio AND l.v > 0), 0), 2),
       ROUND(COALESCE(-SUM(l.v) FILTER (WHERE l.dia >= p_inicio AND l.v < 0), 0), 2),
       ROUND(COALESCE(SUM(l.v), 0), 2)
  FROM tesouraria.fundo f JOIN linhas l ON l.fun = f.fun_id
 GROUP BY f.fun_id, f.fun_nome, f.fun_tipo
 ORDER BY f.fun_nome
$$;
COMMENT ON FUNCTION tesouraria.fn_extracto_fundos(INT, DATE, DATE) IS 'Extracto por fundo num período (V50)';
GRANT EXECUTE ON FUNCTION tesouraria.fn_extracto_fundos(INT, DATE, DATE) TO app_igreja;

-- >>>>> V51__reavivamento_escalao_e_santa_ceia.sql
-- =====================================================================
-- V51 · Reavivamento: quota por escalão (adultos e crianças) · Santa Ceia: acompanhantes do oficiante
--   quota_escalao_reavivamento  a quota fixada no ano para todos os adultos e/ou todas as crianças (vazio = automático).
--   vw_reavivamento_pessoas     a quota de cada pessoa passa a ser, por esta ordem: a ajustada à mão, a do seu escalão,
--                               ou a automática (o resto do alvo repartido igualmente pelas pessoas sem quota fixa).
--                               Nova coluna origem: AJUSTADA, ESCALAO ou AUTOMATICA.
--   santa_ceia_acompanhante     quem acompanha o oficiante (os diáconos e as diaconisas), membros da mesma igreja.
-- Permissões novas: as mesmas das quotas ajustadas (tesouraria.quota_reavivamento.*) e da Santa Ceia
-- (actividades.santa_ceia.*). Gerado com database/gerador.
-- =====================================================================

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- tabela (gerada: gen.py)
CREATE TABLE tesouraria.quota_escalao_reavivamento (
    rqe_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rqe_igr_id INT NOT NULL,
    rqe_ano SMALLINT NOT NULL,
    rqe_quota_adulto DECIMAL(12,2),
    rqe_quota_crianca DECIMAL(12,2),
    rqe_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rqe_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rqe_criado_por INT,
    rqe_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rqe_modificado_por INT,
    rqe_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rqe_igr_id FOREIGN KEY (rqe_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_rqe_valores CHECK ((rqe_quota_adulto IS NULL OR rqe_quota_adulto >= 0) AND (rqe_quota_crianca IS NULL OR rqe_quota_crianca >= 0)),
    CONSTRAINT chk_rqe_ano CHECK (rqe_ano BETWEEN 2000 AND 2100),
    CONSTRAINT chk_rqe_end_date CHECK (rqe_end_date IS NULL OR rqe_end_date >= rqe_criado_em)
);
COMMENT ON TABLE tesouraria.quota_escalao_reavivamento IS 'Quota do reavivamento fixada para todos os adultos e/ou todas as crianças no ano (V51)';
COMMENT ON COLUMN tesouraria.quota_escalao_reavivamento.rqe_quota_adulto IS 'Vazio = automático (reparte o resto do alvo)';
COMMENT ON COLUMN tesouraria.quota_escalao_reavivamento.rqe_quota_crianca IS 'Vazio = automático (reparte o resto do alvo)';
CREATE UNIQUE INDEX uq_rqe_igr_id_ano ON tesouraria.quota_escalao_reavivamento (rqe_igr_id, rqe_ano) WHERE rqe_end_date IS NULL;
CREATE TRIGGER trg_rqe_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.quota_escalao_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rqe', 'tesouraria.quota_escalao_reavivamento', 'rqe_igr_id');
CREATE TRIGGER trg_rqe_00_sem_delete BEFORE DELETE ON tesouraria.quota_escalao_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rqe');
CREATE TRIGGER trg_rqe_00_sem_truncate BEFORE TRUNCATE ON tesouraria.quota_escalao_reavivamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rqe');
CREATE TRIGGER trg_rqe_99_log AFTER UPDATE ON tesouraria.quota_escalao_reavivamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rqe');
ALTER TABLE tesouraria.quota_escalao_reavivamento ADD CONSTRAINT fk_rqe_criado_por FOREIGN KEY (rqe_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.quota_escalao_reavivamento ADD CONSTRAINT fk_rqe_modificado_por FOREIGN KEY (rqe_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.quota_escalao_reavivamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rqe_ler ON tesouraria.quota_escalao_reavivamento FOR SELECT USING (rqe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_escalao_reavivamento.ler'))::INT[]));
CREATE POLICY pol_rqe_criar ON tesouraria.quota_escalao_reavivamento FOR INSERT WITH CHECK (rqe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_escalao_reavivamento.criar'))::INT[]));
CREATE POLICY pol_rqe_alterar ON tesouraria.quota_escalao_reavivamento FOR UPDATE USING (rqe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_escalao_reavivamento.alterar'))::INT[])) WITH CHECK (rqe_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.quota_escalao_reavivamento.alterar'))::INT[]));

GRANT SELECT, INSERT, UPDATE ON tesouraria.quota_escalao_reavivamento TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
COMMENT ON INDEX tesouraria.uq_rqe_igr_id_ano IS '[ano] Esta igreja já tem as quotas por escalão neste ano.';
COMMENT ON CONSTRAINT chk_rqe_valores ON tesouraria.quota_escalao_reavivamento IS '[quotaAdulto] As quotas não podem ser negativas.';
COMMENT ON CONSTRAINT chk_rqe_ano ON tesouraria.quota_escalao_reavivamento IS '[ano] Ano inválido.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'tesouraria.quota_escalao_reavivamento.' || a.accao, a.rotulo || 'Quota do reavivamento por escalão (V51)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'tesouraria.quota_reavivamento.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, '.quota_reavivamento.', '.quota_escalao_reavivamento.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- a vista: ajustada → escalão → automática
CREATE OR REPLACE VIEW tesouraria.vw_reavivamento_pessoas WITH (security_invoker = true) AS
WITH alvos AS (
    SELECT a.alv_igr_id AS igr_id, EXTRACT(YEAR FROM a.alv_data_inicio)::INT AS ano, SUM(a.alv_valor_alvo) AS alvo
      FROM tesouraria.alvo a
      JOIN tesouraria.fundo f ON f.fun_id = a.alv_fun_id AND f.fun_tipo::TEXT = 'REAVIVAMENTO'
     WHERE a.alv_end_date IS NULL
     GROUP BY 1, 2
),
anos AS (
    SELECT igr_id, ano FROM alvos
    UNION
    SELECT rqe_igr_id, rqe_ano FROM tesouraria.quota_escalao_reavivamento WHERE rqe_end_date IS NULL
),
pessoas AS (
    SELECT m.mem_igr_id AS igr_id, m.mem_id, m.mem_nome, m.mem_apelido, m.mem_data_nascimento,
           (m.mem_data_nascimento IS NOT NULL AND m.mem_data_nascimento > current_date - INTERVAL '18 years') AS menor
      FROM secretaria.membro m
     WHERE m.mem_end_date IS NULL
       AND (m.mem_estado::TEXT = 'ACTIVO'
            OR (m.mem_estado::TEXT = 'INTERESSADO' AND m.mem_data_nascimento > current_date - INTERVAL '18 years'))
),
base AS (
    SELECT p.*, y.ano, COALESCE(a.alvo, 0) AS alvo, q.qrv_id, q.qrv_valor, q.qrv_motivo,
           CASE WHEN p.menor THEN e.rqe_quota_crianca ELSE e.rqe_quota_adulto END AS fixa
      FROM pessoas p
      JOIN anos y ON y.igr_id = p.igr_id
      LEFT JOIN alvos a ON a.igr_id = y.igr_id AND a.ano = y.ano
      LEFT JOIN tesouraria.quota_escalao_reavivamento e ON e.rqe_igr_id = y.igr_id AND e.rqe_ano = y.ano AND e.rqe_end_date IS NULL
      LEFT JOIN tesouraria.quota_reavivamento q ON q.qrv_mem_id = p.mem_id AND q.qrv_ano = y.ano AND q.qrv_end_date IS NULL
),
partilha AS (
    SELECT igr_id, ano,
           GREATEST(MAX(alvo) - COALESCE(SUM(COALESCE(qrv_valor, fixa)), 0), 0) AS resto,
           COUNT(*) FILTER (WHERE qrv_id IS NULL AND fixa IS NULL) AS sem_quota
      FROM base GROUP BY 1, 2
),
dado AS (
    SELECT t.tra_mem_id AS mem_id, EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano, SUM(l.tli_valor) AS valor
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
      JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo::TEXT = 'REAVIVAMENTO'
     WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA'
       AND t.tra_estorno_tra_id IS NULL AND t.tra_mem_id IS NOT NULL
     GROUP BY 1, 2
),
calc AS (
    SELECT b.*, ROUND(COALESCE(b.qrv_valor, b.fixa, p.resto / NULLIF(p.sem_quota, 0), 0), 2) AS q
      FROM base b JOIN partilha p ON p.igr_id = b.igr_id AND p.ano = b.ano
)
SELECT c.igr_id AS igreja_id, c.ano, c.mem_id AS membro_id, c.mem_nome AS nome, c.mem_apelido AS apelido,
       c.mem_data_nascimento AS data_nascimento, c.menor, c.alvo AS alvo_igreja,
       c.qrv_id AS quota_id, c.qrv_valor AS quota_ajustada, c.qrv_motivo AS motivo,
       c.q AS quota, COALESCE(d.valor, 0) AS contribuido, GREATEST(c.q - COALESCE(d.valor, 0), 0) AS falta,
       CASE WHEN c.qrv_id IS NOT NULL THEN 'AJUSTADA' WHEN c.fixa IS NOT NULL THEN 'ESCALAO' ELSE 'AUTOMATICA' END AS origem
  FROM calc c
  LEFT JOIN dado d ON d.mem_id = c.mem_id AND d.ano = c.ano;
COMMENT ON VIEW tesouraria.vw_reavivamento_pessoas IS 'Reavivamento por pessoa e ano: quota (ajustada, do escalão ou automática), contribuído e falta (V49, V51)';

-- ---------------------------------------------------------------- Santa Ceia: os acompanhantes (gerada: gen.py)
CREATE TABLE actividades.santa_ceia_acompanhante (
    sca_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    sca_stc_id INT NOT NULL,
    sca_igr_id INT NOT NULL,
    sca_mem_id INT NOT NULL,
    sca_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    sca_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sca_criado_por INT,
    sca_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    sca_modificado_por INT,
    sca_end_date TIMESTAMPTZ,
    CONSTRAINT fk_sca_stc_id FOREIGN KEY (sca_stc_id) REFERENCES actividades.santa_ceia(stc_id),
    CONSTRAINT fk_sca_igr_id FOREIGN KEY (sca_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_sca_mem_id FOREIGN KEY (sca_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_sca_end_date CHECK (sca_end_date IS NULL OR sca_end_date >= sca_criado_em)
);
COMMENT ON TABLE actividades.santa_ceia_acompanhante IS 'Quem acompanha o oficiante na Santa Ceia: os diáconos e as diaconisas (V51)';
COMMENT ON COLUMN actividades.santa_ceia_acompanhante.sca_igr_id IS 'Copiado da Santa Ceia';
CREATE UNIQUE INDEX uq_sca_stc_id_mem_id ON actividades.santa_ceia_acompanhante (sca_stc_id, sca_mem_id) WHERE sca_end_date IS NULL;
CREATE INDEX idx_sca_igr_pagina ON actividades.santa_ceia_acompanhante (sca_igr_id, sca_id);
CREATE INDEX idx_sca_mem_id ON actividades.santa_ceia_acompanhante (sca_mem_id);
CREATE TRIGGER trg_sca_00_padrao BEFORE INSERT OR UPDATE ON actividades.santa_ceia_acompanhante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('sca', 'actividades.santa_ceia_acompanhante', 'sca_igr_id');
CREATE TRIGGER trg_sca_00_sem_delete BEFORE DELETE ON actividades.santa_ceia_acompanhante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('sca');
CREATE TRIGGER trg_sca_00_sem_truncate BEFORE TRUNCATE ON actividades.santa_ceia_acompanhante FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('sca');
CREATE TRIGGER trg_sca_99_log AFTER UPDATE ON actividades.santa_ceia_acompanhante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('sca');
ALTER TABLE actividades.santa_ceia_acompanhante ADD CONSTRAINT fk_sca_criado_por FOREIGN KEY (sca_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.santa_ceia_acompanhante ADD CONSTRAINT fk_sca_modificado_por FOREIGN KEY (sca_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.santa_ceia_acompanhante ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_sca_ler ON actividades.santa_ceia_acompanhante FOR SELECT USING (sca_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_acompanhante.ler'))::INT[]));
CREATE POLICY pol_sca_criar ON actividades.santa_ceia_acompanhante FOR INSERT WITH CHECK (sca_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_acompanhante.criar'))::INT[]));
CREATE POLICY pol_sca_alterar ON actividades.santa_ceia_acompanhante FOR UPDATE USING (sca_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_acompanhante.alterar'))::INT[])) WITH CHECK (sca_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_acompanhante.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON actividades.santa_ceia_acompanhante TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
COMMENT ON INDEX actividades.uq_sca_stc_id_mem_id IS '[membroId] Esta pessoa já acompanha esta Santa Ceia.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'actividades.santa_ceia_acompanhante.' || a.accao, a.rotulo || 'Acompanhantes da Santa Ceia (V51)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.santa_ceia.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, '.santa_ceia.', '.santa_ceia_acompanhante.')
 WHERE pp.ppe_end_date IS NULL;

CREATE FUNCTION actividades.fn_sca_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT stc_igr_id INTO NEW.sca_igr_id FROM actividades.santa_ceia WHERE stc_id = NEW.sca_stc_id;
    IF NEW.sca_igr_id IS NULL THEN
        RAISE EXCEPTION 'A Santa Ceia não existe' USING COLUMN = 'sca_stc_id';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM secretaria.membro WHERE mem_id = NEW.sca_mem_id AND mem_igr_id = NEW.sca_igr_id AND mem_end_date IS NULL) THEN
        RAISE EXCEPTION 'O acompanhante tem de ser membro desta igreja' USING COLUMN = 'sca_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_sca_05_validar BEFORE INSERT OR UPDATE OF sca_stc_id, sca_mem_id ON actividades.santa_ceia_acompanhante
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_sca_validar();

-- >>>>> V52__santa_ceia_equipa_e_participantes.sql
-- =====================================================================
-- V52 · Santa Ceia: a equipa de apoio e os participantes pelo nome
--
--   santa_ceia_acompanhante.sca_funcao   DIACONO ou DIACONISA (Manual da Igreja: quem dirige é o pastor ou um ancião
--                                         ordenado; os diáconos e as diaconisas apoiam e servem, sem número fixo).
--                                         Diácono é homem e diaconisa é mulher, quando o sexo da ficha é conhecido.
--   santa_ceia_participante (scp)        cada membro que participou, pelo nome (os visitantes continuam só em número).
--                                         Os homens e as mulheres registados na Santa Ceia não podem ser menos do
--                                         que os nomes marcados de cada sexo.
--   vw_santa_ceia                        nova coluna nomeados (quantos participantes têm nome).
--   vw_santa_ceia_participacao           por membro e ano: em quantas celebrações (com nomes) participou, a última
--                                         e as faltas. Entram os membros activos e quem participou nesse ano.
--
-- Permissões novas (actividades.santa_ceia_participante.*): as mesmas de actividades.santa_ceia.*.
-- Tabela gerada com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- acompanhantes: a função
ALTER TABLE actividades.santa_ceia_acompanhante ADD COLUMN sca_funcao VARCHAR(20) NOT NULL DEFAULT 'DIACONO';
COMMENT ON COLUMN actividades.santa_ceia_acompanhante.sca_funcao IS 'DIACONO ou DIACONISA (V52)';
ALTER TABLE actividades.santa_ceia_acompanhante ADD CONSTRAINT chk_sca_funcao CHECK (sca_funcao IN ('DIACONO', 'DIACONISA'));
COMMENT ON CONSTRAINT chk_sca_funcao ON actividades.santa_ceia_acompanhante IS '[funcao] A função tem de ser diácono ou diaconisa.';
-- os que já existiam: as mulheres passam a diaconisas
UPDATE actividades.santa_ceia_acompanhante a SET sca_funcao = 'DIACONISA'
  FROM secretaria.membro m WHERE m.mem_id = a.sca_mem_id AND m.mem_sexo = 'F';

CREATE OR REPLACE FUNCTION actividades.fn_sca_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_sexo nucleo.sexo_t;
BEGIN
    SELECT stc_igr_id INTO NEW.sca_igr_id FROM actividades.santa_ceia WHERE stc_id = NEW.sca_stc_id;
    IF NEW.sca_igr_id IS NULL THEN
        RAISE EXCEPTION 'A Santa Ceia não existe' USING COLUMN = 'sca_stc_id';
    END IF;
    SELECT mem_sexo INTO v_sexo FROM secretaria.membro WHERE mem_id = NEW.sca_mem_id AND mem_igr_id = NEW.sca_igr_id AND mem_end_date IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O acompanhante tem de ser membro desta igreja' USING COLUMN = 'sca_mem_id';
    END IF;
    IF v_sexo = 'M' AND NEW.sca_funcao = 'DIACONISA' THEN
        RAISE EXCEPTION 'Um homem acompanha como diácono, não como diaconisa' USING COLUMN = 'sca_funcao';
    END IF;
    IF v_sexo = 'F' AND NEW.sca_funcao = 'DIACONO' THEN
        RAISE EXCEPTION 'Uma mulher acompanha como diaconisa, não como diácono' USING COLUMN = 'sca_funcao';
    END IF;
    RETURN NEW;
END $$;
DROP TRIGGER trg_sca_05_validar ON actividades.santa_ceia_acompanhante;
CREATE TRIGGER trg_sca_05_validar BEFORE INSERT OR UPDATE OF sca_stc_id, sca_mem_id, sca_funcao ON actividades.santa_ceia_acompanhante
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_sca_validar();

-- ---------------------------------------------------------------- participantes pelo nome (gerada: gen.py)
CREATE TABLE actividades.santa_ceia_participante (
    scp_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    scp_stc_id INT NOT NULL,
    scp_igr_id INT NOT NULL,
    scp_mem_id INT NOT NULL,
    scp_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    scp_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    scp_criado_por INT,
    scp_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    scp_modificado_por INT,
    scp_end_date TIMESTAMPTZ,
    CONSTRAINT fk_scp_stc_id FOREIGN KEY (scp_stc_id) REFERENCES actividades.santa_ceia(stc_id),
    CONSTRAINT fk_scp_igr_id FOREIGN KEY (scp_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_scp_mem_id FOREIGN KEY (scp_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_scp_end_date CHECK (scp_end_date IS NULL OR scp_end_date >= scp_criado_em)
);
COMMENT ON TABLE actividades.santa_ceia_participante IS 'Membro que participou na Santa Ceia, pelo nome, para o relatório de participação (V52)';
COMMENT ON COLUMN actividades.santa_ceia_participante.scp_igr_id IS 'Copiado da Santa Ceia';
CREATE UNIQUE INDEX uq_scp_stc_id_mem_id ON actividades.santa_ceia_participante (scp_stc_id, scp_mem_id) WHERE scp_end_date IS NULL;
CREATE INDEX idx_scp_igr_pagina ON actividades.santa_ceia_participante (scp_igr_id, scp_id);
CREATE INDEX idx_scp_mem_id ON actividades.santa_ceia_participante (scp_mem_id);
CREATE TRIGGER trg_scp_00_padrao BEFORE INSERT OR UPDATE ON actividades.santa_ceia_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('scp', 'actividades.santa_ceia_participante', 'scp_igr_id');
CREATE TRIGGER trg_scp_00_sem_delete BEFORE DELETE ON actividades.santa_ceia_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('scp');
CREATE TRIGGER trg_scp_00_sem_truncate BEFORE TRUNCATE ON actividades.santa_ceia_participante FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('scp');
CREATE TRIGGER trg_scp_99_log AFTER UPDATE ON actividades.santa_ceia_participante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('scp');
ALTER TABLE actividades.santa_ceia_participante ADD CONSTRAINT fk_scp_criado_por FOREIGN KEY (scp_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.santa_ceia_participante ADD CONSTRAINT fk_scp_modificado_por FOREIGN KEY (scp_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.santa_ceia_participante ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_scp_ler ON actividades.santa_ceia_participante FOR SELECT USING (scp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_participante.ler'))::INT[]));
CREATE POLICY pol_scp_criar ON actividades.santa_ceia_participante FOR INSERT WITH CHECK (scp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_participante.criar'))::INT[]));
CREATE POLICY pol_scp_alterar ON actividades.santa_ceia_participante FOR UPDATE USING (scp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_participante.alterar'))::INT[])) WITH CHECK (scp_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.santa_ceia_participante.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON actividades.santa_ceia_participante TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
COMMENT ON INDEX actividades.uq_scp_stc_id_mem_id IS '[membroId] Esta pessoa já está marcada nesta Santa Ceia.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'actividades.santa_ceia_participante.' || a.accao, a.rotulo || 'Participantes da Santa Ceia pelo nome (V52)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.santa_ceia.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, '.santa_ceia.', '.santa_ceia_participante.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- regras dos participantes
CREATE FUNCTION actividades.fn_scp_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_stc actividades.santa_ceia%ROWTYPE; v_sexo nucleo.sexo_t; v_marcados INT;
BEGIN
    SELECT * INTO v_stc FROM actividades.santa_ceia WHERE stc_id = NEW.scp_stc_id AND stc_end_date IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'A Santa Ceia não existe' USING COLUMN = 'scp_stc_id';
    END IF;
    NEW.scp_igr_id := v_stc.stc_igr_id;
    IF NEW.scp_end_date IS NOT NULL THEN
        RETURN NEW; -- desmarcar é sempre possível
    END IF;
    IF v_stc.stc_estado = 'CANCELADA' THEN
        RAISE EXCEPTION 'Esta Santa Ceia foi cancelada' USING COLUMN = 'scp_stc_id';
    END IF;
    SELECT mem_sexo INTO v_sexo FROM secretaria.membro WHERE mem_id = NEW.scp_mem_id AND mem_igr_id = NEW.scp_igr_id AND mem_end_date IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O participante tem de ser membro desta igreja (os de fora contam como visitantes)' USING COLUMN = 'scp_mem_id';
    END IF;
    -- já realizada: os nomes de cada sexo não passam dos números registados
    IF v_stc.stc_estado = 'REALIZADA' AND v_sexo IS NOT NULL THEN
        SELECT count(*) + 1 INTO v_marcados
          FROM actividades.santa_ceia_participante p JOIN secretaria.membro m ON m.mem_id = p.scp_mem_id
         WHERE p.scp_stc_id = NEW.scp_stc_id AND p.scp_end_date IS NULL AND p.scp_id IS DISTINCT FROM NEW.scp_id AND m.mem_sexo = v_sexo;
        IF v_marcados > (CASE v_sexo WHEN 'M' THEN v_stc.stc_homens ELSE v_stc.stc_mulheres END) THEN
            RAISE EXCEPTION 'Os nomes marcados passam o número de % registado nesta Santa Ceia', (CASE v_sexo WHEN 'M' THEN 'homens' ELSE 'mulheres' END)
                USING COLUMN = 'scp_mem_id';
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_scp_05_validar BEFORE INSERT OR UPDATE OF scp_stc_id, scp_mem_id, scp_end_date ON actividades.santa_ceia_participante
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_scp_validar();

-- ao registar os números: não podem ficar abaixo dos nomes marcados
CREATE FUNCTION actividades.fn_stc_participantes() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_h INT; v_m INT;
BEGIN
    IF NEW.stc_estado <> 'REALIZADA' THEN
        RETURN NEW;
    END IF;
    SELECT count(*) FILTER (WHERE m.mem_sexo = 'M'), count(*) FILTER (WHERE m.mem_sexo = 'F') INTO v_h, v_m
      FROM actividades.santa_ceia_participante p JOIN secretaria.membro m ON m.mem_id = p.scp_mem_id
     WHERE p.scp_stc_id = NEW.stc_id AND p.scp_end_date IS NULL;
    IF coalesce(NEW.stc_homens, 0) < v_h THEN
        RAISE EXCEPTION 'Estão marcados % homens pelo nome: o número de homens não pode ser menor', v_h USING COLUMN = 'stc_homens';
    END IF;
    IF coalesce(NEW.stc_mulheres, 0) < v_m THEN
        RAISE EXCEPTION 'Estão marcadas % mulheres pelo nome: o número de mulheres não pode ser menor', v_m USING COLUMN = 'stc_mulheres';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_stc_12_participantes BEFORE UPDATE OF stc_homens, stc_mulheres, stc_estado ON actividades.santa_ceia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_stc_participantes();

-- ---------------------------------------------------------------- histórico: quantos têm nome
CREATE OR REPLACE VIEW actividades.vw_santa_ceia WITH (security_invoker = true) AS
SELECT s.stc_id, s.stc_igr_id AS igreja_id, i.igr_nome AS igreja, s.stc_data AS data, s.stc_hora AS hora, s.stc_local AS local,
       s.stc_estado AS estado, EXTRACT(YEAR FROM s.stc_data)::INT AS ano,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = s.stc_responsavel_mem_id) AS responsavel,
       s.stc_homens AS homens, s.stc_mulheres AS mulheres, s.stc_visitantes AS visitantes,
       (coalesce(s.stc_homens, 0) + coalesce(s.stc_mulheres, 0) + coalesce(s.stc_visitantes, 0))::INT AS total,
       (SELECT count(*) FROM actividades.santa_ceia_participante p WHERE p.scp_stc_id = s.stc_id AND p.scp_end_date IS NULL)::INT AS nomeados
  FROM actividades.santa_ceia s
  JOIN organizacao.igreja i ON i.igr_id = s.stc_igr_id
 WHERE s.stc_end_date IS NULL;
COMMENT ON VIEW actividades.vw_santa_ceia IS 'V39, V52: celebrações da Santa Ceia com os participantes e quantos têm nome (cada um só vê as igrejas que pode ler)';

-- ---------------------------------------------------------------- relatório de participação por membro
CREATE VIEW actividades.vw_santa_ceia_participacao WITH (security_invoker = true) AS
WITH cel AS (   -- celebrações realizadas com os participantes registados pelo nome
    SELECT s.stc_igr_id AS igr_id, EXTRACT(YEAR FROM s.stc_data)::INT AS ano, count(*)::INT AS n
      FROM actividades.santa_ceia s
     WHERE s.stc_end_date IS NULL AND s.stc_estado = 'REALIZADA'
       AND EXISTS (SELECT 1 FROM actividades.santa_ceia_participante p WHERE p.scp_stc_id = s.stc_id AND p.scp_end_date IS NULL)
     GROUP BY 1, 2
), part AS (
    SELECT p.scp_mem_id AS mem_id, s.stc_igr_id AS igr_id, EXTRACT(YEAR FROM s.stc_data)::INT AS ano,
           count(*)::INT AS n, max(s.stc_data) AS ultima
      FROM actividades.santa_ceia_participante p
      JOIN actividades.santa_ceia s ON s.stc_id = p.scp_stc_id AND s.stc_end_date IS NULL AND s.stc_estado = 'REALIZADA'
     WHERE p.scp_end_date IS NULL
     GROUP BY 1, 2, 3
)
SELECT c.igr_id AS igreja_id, c.ano, m.mem_id AS membro_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       m.mem_sexo AS sexo, m.mem_estado AS estado_membro,
       c.n AS celebracoes, coalesce(p.n, 0) AS participacoes, (c.n - coalesce(p.n, 0))::INT AS faltas, p.ultima
  FROM cel c
  JOIN secretaria.membro m ON m.mem_igr_id = c.igr_id AND m.mem_end_date IS NULL
  LEFT JOIN part p ON p.mem_id = m.mem_id AND p.igr_id = c.igr_id AND p.ano = c.ano
 WHERE m.mem_estado = 'ACTIVO' OR p.n IS NOT NULL;
COMMENT ON VIEW actividades.vw_santa_ceia_participacao IS 'V52: por membro e ano, em quantas Santas Ceias (com nomes registados) participou, as faltas e a última';
GRANT SELECT ON actividades.vw_santa_ceia_participacao TO app_igreja;

-- >>>>> V53__voto_da_pessoa.sql
-- =====================================================================
-- V53 · O voto é da pessoa: o livro de membros não aceita o voto de outra pessoa
--
--   voto_membro (vtm)   as pessoas a que o voto se refere (ex.: os admitidos por baptismo nesse voto). Um voto pode
--                       referir várias pessoas (baptismo de um grupo). As pessoas são membros ou interessados da igreja
--                       da reunião em que o voto foi tomado.
--   movimento_membro    uma entrada ou saída com voto (todas menos falecimento e transferência, que se valida na carta)
--                       exige que o voto indique essa pessoa: "Admissão por baptismo de Amélia" não serve para a Rosa.
--
-- Permissões novas (secretaria.voto_membro.*): as mesmas de secretaria.voto.*.
-- Tabela gerada com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- pessoas do voto (gerada: gen.py)
CREATE TABLE secretaria.voto_membro (
    vtm_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    vtm_vot_id INT NOT NULL,
    vtm_igr_id INT NOT NULL,
    vtm_mem_id INT NOT NULL,
    vtm_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    vtm_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    vtm_criado_por INT,
    vtm_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    vtm_modificado_por INT,
    vtm_end_date TIMESTAMPTZ,
    CONSTRAINT fk_vtm_vot_id FOREIGN KEY (vtm_vot_id) REFERENCES secretaria.voto(vot_id),
    CONSTRAINT fk_vtm_igr_id FOREIGN KEY (vtm_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_vtm_mem_id FOREIGN KEY (vtm_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT chk_vtm_end_date CHECK (vtm_end_date IS NULL OR vtm_end_date >= vtm_criado_em)
);
COMMENT ON TABLE secretaria.voto_membro IS 'Pessoas a que o voto se refere (ex.: os admitidos por baptismo), para o livro não aceitar o voto de outra pessoa (V53)';
COMMENT ON COLUMN secretaria.voto_membro.vtm_igr_id IS 'Copiado da reunião do voto';
CREATE UNIQUE INDEX uq_vtm_vot_id_mem_id ON secretaria.voto_membro (vtm_vot_id, vtm_mem_id) WHERE vtm_end_date IS NULL;
CREATE INDEX idx_vtm_igr_pagina ON secretaria.voto_membro (vtm_igr_id, vtm_id);
CREATE INDEX idx_vtm_mem_id ON secretaria.voto_membro (vtm_mem_id);
CREATE TRIGGER trg_vtm_00_padrao BEFORE INSERT OR UPDATE ON secretaria.voto_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('vtm', 'secretaria.voto_membro', 'vtm_igr_id');
CREATE TRIGGER trg_vtm_00_sem_delete BEFORE DELETE ON secretaria.voto_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('vtm');
CREATE TRIGGER trg_vtm_00_sem_truncate BEFORE TRUNCATE ON secretaria.voto_membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('vtm');
CREATE TRIGGER trg_vtm_99_log AFTER UPDATE ON secretaria.voto_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('vtm');
ALTER TABLE secretaria.voto_membro ADD CONSTRAINT fk_vtm_criado_por FOREIGN KEY (vtm_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.voto_membro ADD CONSTRAINT fk_vtm_modificado_por FOREIGN KEY (vtm_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.voto_membro ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_vtm_ler ON secretaria.voto_membro FOR SELECT USING (vtm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto_membro.ler'))::INT[]));
CREATE POLICY pol_vtm_criar ON secretaria.voto_membro FOR INSERT WITH CHECK (vtm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto_membro.criar'))::INT[]));
CREATE POLICY pol_vtm_alterar ON secretaria.voto_membro FOR UPDATE USING (vtm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto_membro.alterar'))::INT[])) WITH CHECK (vtm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.voto_membro.alterar'))::INT[]));
GRANT SELECT, INSERT, UPDATE ON secretaria.voto_membro TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA secretaria TO app_igreja;
COMMENT ON INDEX secretaria.uq_vtm_vot_id_mem_id IS '[membroId] Esta pessoa já está indicada neste voto.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'secretaria.voto_membro.' || a.accao, a.rotulo || 'Pessoas a que o voto se refere (V53)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'secretaria.voto.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, '.voto.', '.voto_membro.')
 WHERE pp.ppe_end_date IS NULL;

-- a igreja vem da reunião do voto; a pessoa é dessa igreja
CREATE FUNCTION secretaria.fn_vtm_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT r.reu_igr_id INTO NEW.vtm_igr_id
      FROM secretaria.voto v JOIN secretaria.reuniao r ON r.reu_id = v.vot_reu_id
     WHERE v.vot_id = NEW.vtm_vot_id;
    IF NEW.vtm_igr_id IS NULL THEN
        RAISE EXCEPTION 'O voto não existe' USING COLUMN = 'vtm_vot_id';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM secretaria.membro WHERE mem_id = NEW.vtm_mem_id AND mem_igr_id = NEW.vtm_igr_id AND mem_end_date IS NULL) THEN
        RAISE EXCEPTION 'A pessoa do voto tem de ser membro ou interessado desta igreja' USING COLUMN = 'vtm_mem_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_vtm_05_validar BEFORE INSERT OR UPDATE OF vtm_vot_id, vtm_mem_id ON secretaria.voto_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_vtm_validar();

-- ---------------------------------------------------------------- livro: o voto tem de ser desta pessoa
CREATE FUNCTION secretaria.fn_mmb_voto_da_pessoa() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_numero TEXT; v_nome TEXT;
BEGIN
    IF NEW.mmb_tme_id IS NOT NULL OR NEW.mmb_tipo = 'FALECIMENTO' OR NEW.mmb_vot_id IS NULL THEN
        RETURN NEW;                                       -- transferências validam-se na carta; o voto em falta, em fn_mmb_validar
    END IF;
    IF NOT EXISTS (SELECT 1 FROM secretaria.voto_membro
                    WHERE vtm_vot_id = NEW.mmb_vot_id AND vtm_mem_id = NEW.mmb_mem_id AND vtm_end_date IS NULL) THEN
        SELECT vot_numero INTO v_numero FROM secretaria.voto WHERE vot_id = NEW.mmb_vot_id;
        SELECT mem_nome || ' ' || mem_apelido INTO v_nome FROM secretaria.membro WHERE mem_id = NEW.mmb_mem_id;
        RAISE EXCEPTION 'O voto n.º % não indica % entre as pessoas a que se refere: escolha o voto desta pessoa (ou acrescente-a ao voto, na reunião)', v_numero, v_nome
            USING COLUMN = 'mmb_vot_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_mmb_11_voto_da_pessoa BEFORE INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_voto_da_pessoa();

-- >>>>> V54__fluxos_de_aprovacao.sql
-- =====================================================================
-- V54 · Fluxos de aprovação e conferência: cada processo com etapas definidas, quem decide cada uma e o estado
--
--   fluxo_aprovacao (fap)    que etapas segue cada natureza de processo (DESPESA, SAIDA, CONTAGEM, ORCAMENTO,
--                            ADMISSAO_MEMBRO, REMOCAO_MEMBRO), a partir de que valor. Vazio na igreja = modelo da
--                            Associação/Missão; uma igreja com fluxo próprio para um processo deixa de usar os modelos dele.
--   fluxo_etapa (fae)        as etapas, por ordem: quem decide (PERFIL, PERMISSAO ou ORGAO que vota em reunião), o que faz
--                            (APRECIAR, CONFERIR, RECOMENDAR, APROVAR, VOTAR) e se tem de ser outra pessoa.
--   aprovacao (apv)          o processo de cada objecto: fluxo, etapa em curso e estado (EM_CURSO, APROVADO, REJEITADO,
--                            CANCELADO). Só o sistema escreve (nucleo.fn_aprovacao_*).
--   aprovacao_decisao (apd)  cada etapa decidida: quem, quando, com que voto, motivo e valor aprovado.
--
--   Iniciam-se sozinhos: despesa submetida, saída pendente sem despesa, contagem aberta, orçamento em rascunho, e o primeiro
--   voto de admissão/remoção que indica uma pessoa (voto_membro). Decide-se com nucleo.fn_aprovacao_decidir (API:
--   POST /v1/nucleo/aprovacoes/{id}/decidir); as funções antigas (fn_decidir_despesa, fn_aprovar_saida,
--   fn_aprovar_orcamento) e a mudança de estado à mão decidem a etapa em curso. O objecto só muda de estado quando a
--   última etapa aprova; uma rejeição termina o processo (contagem e orçamento recomeçam).
--   Membros: o voto decide a etapa do órgão da reunião, pela ordem do fluxo; o livro só aceita a admissão/remoção com o
--   voto de um processo aprovado.
--   Vistas: vw_aprovacoes (o que está por decidir, quem decide, se o utilizador pode) e vw_aprovacao_etapas.
--
-- Tabelas geradas com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE TYPE nucleo.processo_aprovacao_t AS ENUM ('DESPESA', 'SAIDA', 'CONTAGEM', 'ORCAMENTO', 'ADMISSAO_MEMBRO', 'REMOCAO_MEMBRO');
CREATE TYPE nucleo.accao_etapa_t        AS ENUM ('APRECIAR', 'CONFERIR', 'RECOMENDAR', 'APROVAR', 'VOTAR');
CREATE TYPE nucleo.responsavel_etapa_t  AS ENUM ('PERFIL', 'PERMISSAO', 'ORGAO');
CREATE TYPE nucleo.estado_aprovacao_t   AS ENUM ('EM_CURSO', 'APROVADO', 'REJEITADO', 'CANCELADO');

-- ---------------------------------------------------------------- tabelas (geradas: gen.py)
-- Fluxos de aprovação: que etapas segue cada natureza de processo (despesa, saída, contagem, orçamento, admissão e remoção de membros), a partir de que valor (V54)
CREATE TABLE nucleo.fluxo_aprovacao (
    fap_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    fap_igr_id INT,
    fap_processo processo_aprovacao_t NOT NULL,
    fap_nome VARCHAR(100) NOT NULL,
    fap_valor_minimo DECIMAL(14,2) NOT NULL DEFAULT 0,
    fap_descricao VARCHAR(255),
    fap_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    fap_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fap_criado_por INT,
    fap_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fap_modificado_por INT,
    fap_end_date TIMESTAMPTZ,
    CONSTRAINT chk_fap_valor_minimo CHECK (fap_valor_minimo >= 0),
    CONSTRAINT chk_fap_end_date CHECK (fap_end_date IS NULL OR fap_end_date >= fap_criado_em)
);
COMMENT ON TABLE nucleo.fluxo_aprovacao IS 'Fluxos de aprovação: que etapas segue cada natureza de processo (despesa, saída, contagem, orçamento, admissão e remoção de membros), a partir de que valor (V54)';
COMMENT ON COLUMN nucleo.fluxo_aprovacao.fap_igr_id IS 'Igreja a que o fluxo se aplica; vazio = modelo da Associação/Missão para todas as igrejas sem fluxo próprio';
COMMENT ON COLUMN nucleo.fluxo_aprovacao.fap_valor_minimo IS 'O fluxo aplica-se a partir deste valor (o de maior valor mínimo que não passe o valor do processo)';
CREATE INDEX idx_fap_igr_id ON nucleo.fluxo_aprovacao (fap_igr_id);
CREATE UNIQUE INDEX uq_fap_igr_processo_valor ON nucleo.fluxo_aprovacao (COALESCE(fap_igr_id, 0), fap_processo, fap_valor_minimo) WHERE fap_end_date IS NULL;

-- Etapas de um fluxo de aprovação, pela ordem em que se decidem: quem decide (perfil, permissão ou órgão que vota) e o que faz (V54)
CREATE TABLE nucleo.fluxo_etapa (
    fae_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    fae_fap_id INT NOT NULL,
    fae_igr_id INT,
    fae_ordem SMALLINT NOT NULL,
    fae_nome VARCHAR(100) NOT NULL,
    fae_accao accao_etapa_t NOT NULL DEFAULT 'APROVAR',
    fae_responsavel responsavel_etapa_t NOT NULL,
    fae_per_id INT,
    fae_prm_id INT,
    fae_orgao tipo_reuniao_t,
    fae_outra_pessoa BOOLEAN NOT NULL DEFAULT TRUE,
    fae_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    fae_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fae_criado_por INT,
    fae_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    fae_modificado_por INT,
    fae_end_date TIMESTAMPTZ,
    CONSTRAINT fk_fae_fap_id FOREIGN KEY (fae_fap_id) REFERENCES nucleo.fluxo_aprovacao(fap_id),
    CONSTRAINT fk_fae_per_id FOREIGN KEY (fae_per_id) REFERENCES nucleo.perfil(per_id),
    CONSTRAINT fk_fae_prm_id FOREIGN KEY (fae_prm_id) REFERENCES nucleo.permissao(prm_id),
    CONSTRAINT chk_fae_ordem CHECK (fae_ordem BETWEEN 1 AND 20),
    CONSTRAINT chk_fae_responsavel CHECK ((fae_responsavel = 'PERFIL' AND fae_per_id IS NOT NULL) OR (fae_responsavel = 'PERMISSAO' AND fae_prm_id IS NOT NULL) OR (fae_responsavel = 'ORGAO' AND fae_orgao IS NOT NULL)),
    CONSTRAINT chk_fae_end_date CHECK (fae_end_date IS NULL OR fae_end_date >= fae_criado_em)
);
COMMENT ON TABLE nucleo.fluxo_etapa IS 'Etapas de um fluxo de aprovação, pela ordem em que se decidem: quem decide (perfil, permissão ou órgão que vota) e o que faz (V54)';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_igr_id IS 'Copiado do fluxo';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_ordem IS '1 = a primeira a decidir';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_responsavel IS 'PERFIL (quem tem esse perfil na igreja), PERMISSAO (quem tem essa permissão) ou ORGAO (o órgão vota em reunião)';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_per_id IS 'Perfil que decide (responsavel = PERFIL)';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_prm_id IS 'Permissão de quem decide (responsavel = PERMISSAO)';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_orgao IS 'Órgão que vota (responsavel = ORGAO): o voto tem de ser de uma reunião deste tipo';
COMMENT ON COLUMN nucleo.fluxo_etapa.fae_outra_pessoa IS 'Quem pediu e quem já decidiu outra etapa não decide esta';
CREATE UNIQUE INDEX uq_fae_fap_id_ordem ON nucleo.fluxo_etapa (fae_fap_id, fae_ordem) WHERE fae_end_date IS NULL;
CREATE INDEX idx_fae_igr_id ON nucleo.fluxo_etapa (fae_igr_id);
CREATE INDEX idx_fae_per_id ON nucleo.fluxo_etapa (fae_per_id);
CREATE INDEX idx_fae_prm_id ON nucleo.fluxo_etapa (fae_prm_id);

-- Processos de aprovação em curso e concluídos: o objecto (despesa, saída, contagem, orçamento ou membro), o fluxo e a etapa em que está (V54)
CREATE TABLE nucleo.aprovacao (
    apv_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    apv_igr_id INT NOT NULL,
    apv_fap_id INT NOT NULL,
    apv_processo processo_aprovacao_t NOT NULL,
    apv_assunto VARCHAR(255) NOT NULL,
    apv_valor DECIMAL(14,2),
    apv_des_id INT,
    apv_tra_id BIGINT,
    apv_cnu_id INT,
    apv_orc_id INT,
    apv_mem_id INT,
    apv_pedido_por_usu_id INT,
    apv_etapa SMALLINT NOT NULL DEFAULT 1,
    apv_concluido_em TIMESTAMPTZ,
    apv_estado estado_aprovacao_t NOT NULL DEFAULT 'EM_CURSO',
    apv_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    apv_criado_por INT,
    apv_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    apv_modificado_por INT,
    apv_end_date TIMESTAMPTZ,
    CONSTRAINT fk_apv_fap_id FOREIGN KEY (apv_fap_id) REFERENCES nucleo.fluxo_aprovacao(fap_id),
    CONSTRAINT fk_apv_pedido_por_usu_id FOREIGN KEY (apv_pedido_por_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_apv_objecto CHECK (num_nonnulls(apv_des_id, apv_tra_id, apv_cnu_id, apv_orc_id, apv_mem_id) = 1),
    CONSTRAINT chk_apv_end_date CHECK (apv_end_date IS NULL OR apv_end_date >= apv_criado_em)
);
COMMENT ON TABLE nucleo.aprovacao IS 'Processos de aprovação em curso e concluídos: o objecto (despesa, saída, contagem, orçamento ou membro), o fluxo e a etapa em que está (V54)';
COMMENT ON COLUMN nucleo.aprovacao.apv_mem_id IS 'Membro a admitir ou remover';
COMMENT ON COLUMN nucleo.aprovacao.apv_pedido_por_usu_id IS 'Quem pediu (não decide as etapas com outra_pessoa)';
COMMENT ON COLUMN nucleo.aprovacao.apv_etapa IS 'Ordem da etapa actual (a próxima a decidir)';
CREATE INDEX idx_apv_igr_id ON nucleo.aprovacao (apv_igr_id);
CREATE INDEX idx_apv_fap_id ON nucleo.aprovacao (apv_fap_id);
CREATE INDEX idx_apv_des_id ON nucleo.aprovacao (apv_des_id);
CREATE INDEX idx_apv_tra_id ON nucleo.aprovacao (apv_tra_id);
CREATE INDEX idx_apv_cnu_id ON nucleo.aprovacao (apv_cnu_id);
CREATE INDEX idx_apv_orc_id ON nucleo.aprovacao (apv_orc_id);
CREATE INDEX idx_apv_mem_id ON nucleo.aprovacao (apv_mem_id);
CREATE INDEX idx_apv_pedido_por_usu_id ON nucleo.aprovacao (apv_pedido_por_usu_id);
CREATE UNIQUE INDEX uq_apv_em_curso ON nucleo.aprovacao (apv_processo, COALESCE(apv_des_id, 0), COALESCE(apv_tra_id, 0), COALESCE(apv_cnu_id, 0), COALESCE(apv_orc_id, 0), COALESCE(apv_mem_id, 0)) WHERE apv_estado = 'EM_CURSO' AND apv_end_date IS NULL;
CREATE INDEX idx_apv_igr_estado ON nucleo.aprovacao (apv_igr_id, apv_estado);

-- Decisões de cada etapa de um processo de aprovação: quem decidiu, quando, com que voto (V54)
CREATE TABLE nucleo.aprovacao_decisao (
    apd_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    apd_apv_id INT NOT NULL,
    apd_igr_id INT NOT NULL,
    apd_fae_id INT NOT NULL,
    apd_etapa SMALLINT NOT NULL,
    apd_aprovado BOOLEAN NOT NULL,
    apd_usu_id INT NOT NULL,
    apd_vot_id INT,
    apd_motivo VARCHAR(255),
    apd_valor DECIMAL(14,2),
    apd_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    apd_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    apd_criado_por INT,
    apd_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    apd_modificado_por INT,
    apd_end_date TIMESTAMPTZ,
    CONSTRAINT fk_apd_apv_id FOREIGN KEY (apd_apv_id) REFERENCES nucleo.aprovacao(apv_id),
    CONSTRAINT fk_apd_fae_id FOREIGN KEY (apd_fae_id) REFERENCES nucleo.fluxo_etapa(fae_id),
    CONSTRAINT fk_apd_usu_id FOREIGN KEY (apd_usu_id) REFERENCES nucleo.usuario(usu_id),
    CONSTRAINT chk_apd_end_date CHECK (apd_end_date IS NULL OR apd_end_date >= apd_criado_em)
);
COMMENT ON TABLE nucleo.aprovacao_decisao IS 'Decisões de cada etapa de um processo de aprovação: quem decidiu, quando, com que voto (V54)';
COMMENT ON COLUMN nucleo.aprovacao_decisao.apd_usu_id IS 'Quem decidiu ou registou a decisão do órgão';
COMMENT ON COLUMN nucleo.aprovacao_decisao.apd_vot_id IS 'Voto do órgão (etapas ORGAO)';
COMMENT ON COLUMN nucleo.aprovacao_decisao.apd_valor IS 'Valor aprovado, quando a etapa o reduz';
CREATE UNIQUE INDEX uq_apd_apv_id_etapa ON nucleo.aprovacao_decisao (apd_apv_id, apd_etapa) WHERE apd_end_date IS NULL;
CREATE INDEX idx_apd_igr_id ON nucleo.aprovacao_decisao (apd_igr_id);
CREATE INDEX idx_apd_fae_id ON nucleo.aprovacao_decisao (apd_fae_id);
CREATE INDEX idx_apd_usu_id ON nucleo.aprovacao_decisao (apd_usu_id);
CREATE INDEX idx_apd_vot_id ON nucleo.aprovacao_decisao (apd_vot_id);

-- chaves estrangeiras para as tabelas dos outros módulos
ALTER TABLE nucleo.fluxo_aprovacao ADD CONSTRAINT fk_fap_igr_id FOREIGN KEY (fap_igr_id) REFERENCES organizacao.igreja(igr_id);
ALTER TABLE nucleo.fluxo_etapa ADD CONSTRAINT fk_fae_igr_id FOREIGN KEY (fae_igr_id) REFERENCES organizacao.igreja(igr_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_igr_id FOREIGN KEY (apv_igr_id) REFERENCES organizacao.igreja(igr_id);
ALTER TABLE nucleo.aprovacao_decisao ADD CONSTRAINT fk_apd_igr_id FOREIGN KEY (apd_igr_id) REFERENCES organizacao.igreja(igr_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_mem_id FOREIGN KEY (apv_mem_id) REFERENCES secretaria.membro(mem_id);
ALTER TABLE nucleo.aprovacao_decisao ADD CONSTRAINT fk_apd_vot_id FOREIGN KEY (apd_vot_id) REFERENCES secretaria.voto(vot_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_orc_id FOREIGN KEY (apv_orc_id) REFERENCES tesouraria.orcamento(orc_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_des_id FOREIGN KEY (apv_des_id) REFERENCES tesouraria.despesa(des_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_cnu_id FOREIGN KEY (apv_cnu_id) REFERENCES tesouraria.contagem_numerario(cnu_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_tra_id FOREIGN KEY (apv_tra_id) REFERENCES tesouraria.transacao(tra_id);

-- ---------------------------------------------------------------- comportamento comum e segurança (gerados)
CREATE TRIGGER trg_fap_00_padrao BEFORE INSERT OR UPDATE ON nucleo.fluxo_aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fap', 'nucleo.fluxo_aprovacao', 'fap_igr_id');
CREATE TRIGGER trg_fap_00_sem_delete BEFORE DELETE ON nucleo.fluxo_aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fap');
CREATE TRIGGER trg_fap_00_sem_truncate BEFORE TRUNCATE ON nucleo.fluxo_aprovacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fap');
CREATE TRIGGER trg_fap_01_comum BEFORE UPDATE ON nucleo.fluxo_aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('fap', 'nucleo.fluxo_aprovacao', 'fap_igr_id');
CREATE TRIGGER trg_fap_99_log AFTER UPDATE ON nucleo.fluxo_aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fap');
ALTER TABLE nucleo.fluxo_aprovacao ADD CONSTRAINT fk_fap_criado_por FOREIGN KEY (fap_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.fluxo_aprovacao ADD CONSTRAINT fk_fap_modificado_por FOREIGN KEY (fap_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_fae_00_padrao BEFORE INSERT OR UPDATE ON nucleo.fluxo_etapa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fae', 'nucleo.fluxo_etapa', 'fae_igr_id');
CREATE TRIGGER trg_fae_00_sem_delete BEFORE DELETE ON nucleo.fluxo_etapa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fae');
CREATE TRIGGER trg_fae_00_sem_truncate BEFORE TRUNCATE ON nucleo.fluxo_etapa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fae');
CREATE TRIGGER trg_fae_01_comum BEFORE UPDATE ON nucleo.fluxo_etapa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_terminar_comum('fae', 'nucleo.fluxo_etapa', 'fae_igr_id');
CREATE TRIGGER trg_fae_99_log AFTER UPDATE ON nucleo.fluxo_etapa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fae');
ALTER TABLE nucleo.fluxo_etapa ADD CONSTRAINT fk_fae_criado_por FOREIGN KEY (fae_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.fluxo_etapa ADD CONSTRAINT fk_fae_modificado_por FOREIGN KEY (fae_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_apv_00_padrao BEFORE INSERT OR UPDATE ON nucleo.aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('apv', '', '');
CREATE TRIGGER trg_apv_00_sem_delete BEFORE DELETE ON nucleo.aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('apv');
CREATE TRIGGER trg_apv_00_sem_truncate BEFORE TRUNCATE ON nucleo.aprovacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('apv');
CREATE TRIGGER trg_apv_99_log AFTER UPDATE ON nucleo.aprovacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('apv');
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_criado_por FOREIGN KEY (apv_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_modificado_por FOREIGN KEY (apv_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_apd_00_padrao BEFORE INSERT OR UPDATE ON nucleo.aprovacao_decisao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('apd', '', '');
CREATE TRIGGER trg_apd_00_sem_delete BEFORE DELETE ON nucleo.aprovacao_decisao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('apd');
CREATE TRIGGER trg_apd_00_sem_truncate BEFORE TRUNCATE ON nucleo.aprovacao_decisao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('apd');
CREATE TRIGGER trg_apd_99_log AFTER UPDATE ON nucleo.aprovacao_decisao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('apd');
ALTER TABLE nucleo.aprovacao_decisao ADD CONSTRAINT fk_apd_criado_por FOREIGN KEY (apd_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.aprovacao_decisao ADD CONSTRAINT fk_apd_modificado_por FOREIGN KEY (apd_modificado_por) REFERENCES nucleo.usuario(usu_id);
REVOKE INSERT, UPDATE ON nucleo.aprovacao_decisao FROM app_igreja;
REVOKE INSERT, UPDATE ON nucleo.aprovacao FROM app_igreja;
ALTER TABLE nucleo.fluxo_aprovacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_fap_ler ON nucleo.fluxo_aprovacao FOR SELECT USING (fap_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_aprovacao.ler'))::INT[])) OR (fap_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('nucleo.fluxo_aprovacao.ler'))));
CREATE POLICY pol_fap_criar ON nucleo.fluxo_aprovacao FOR INSERT WITH CHECK (fap_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_aprovacao.criar'))::INT[])) OR (fap_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_aprovacao.criar'))));
CREATE POLICY pol_fap_alterar ON nucleo.fluxo_aprovacao FOR UPDATE USING (fap_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_aprovacao.alterar'))::INT[])) OR (fap_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_aprovacao.alterar')))) WITH CHECK (fap_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_aprovacao.alterar'))::INT[])) OR (fap_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_aprovacao.alterar'))));
CREATE POLICY pol_fap_proprio ON nucleo.fluxo_aprovacao FOR SELECT USING (TRUE);
ALTER TABLE nucleo.fluxo_etapa ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_fae_ler ON nucleo.fluxo_etapa FOR SELECT USING (fae_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_etapa.ler'))::INT[])) OR (fae_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_global('nucleo.fluxo_etapa.ler'))));
CREATE POLICY pol_fae_criar ON nucleo.fluxo_etapa FOR INSERT WITH CHECK (fae_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_etapa.criar'))::INT[])) OR (fae_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_etapa.criar'))));
CREATE POLICY pol_fae_alterar ON nucleo.fluxo_etapa FOR UPDATE USING (fae_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_etapa.alterar'))::INT[])) OR (fae_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_etapa.alterar')))) WITH CHECK (fae_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('nucleo.fluxo_etapa.alterar'))::INT[])) OR (fae_igr_id IS NULL AND (SELECT nucleo.fn_tem_permissao_comum('nucleo.fluxo_etapa.alterar'))));
CREATE POLICY pol_fae_proprio ON nucleo.fluxo_etapa FOR SELECT USING (TRUE);
ALTER TABLE nucleo.aprovacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_apv_ler ON nucleo.aprovacao FOR SELECT USING ((apv_processo = 'DESPESA' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.ler'))::INT[])) OR (apv_processo = 'SAIDA' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler'))::INT[])) OR (apv_processo = 'CONTAGEM' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.ler'))::INT[])) OR (apv_processo = 'ORCAMENTO' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.ler'))::INT[])) OR (apv_processo IN ('ADMISSAO_MEMBRO', 'REMOCAO_MEMBRO') AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.ler'))::INT[])));
ALTER TABLE nucleo.aprovacao_decisao ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_apd_ler ON nucleo.aprovacao_decisao FOR SELECT USING (EXISTS (SELECT 1 FROM nucleo.aprovacao a WHERE a.apv_id = apd_apv_id));
GRANT SELECT ON nucleo.fluxo_aprovacao, nucleo.fluxo_etapa, nucleo.aprovacao, nucleo.aprovacao_decisao TO app_igreja;
GRANT INSERT, UPDATE ON nucleo.fluxo_aprovacao, nucleo.fluxo_etapa TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA nucleo TO app_igreja;

-- ---------------------------------------------------------------- frases das restrições (V29)
COMMENT ON CONSTRAINT chk_fap_valor_minimo ON nucleo.fluxo_aprovacao IS '[valorMinimo] O valor mínimo não pode ser negativo.';
COMMENT ON INDEX nucleo.uq_fap_igr_processo_valor IS '[valorMinimo] Já existe um fluxo para este processo a partir deste valor.';
COMMENT ON CONSTRAINT chk_fae_ordem ON nucleo.fluxo_etapa IS '[ordem] A ordem da etapa vai de 1 a 20.';
COMMENT ON CONSTRAINT chk_fae_responsavel ON nucleo.fluxo_etapa IS '[responsavel] Indique quem decide: o perfil, a permissão ou o órgão, conforme o tipo de responsável.';
COMMENT ON INDEX nucleo.uq_fae_fap_id_ordem IS '[ordem] Este fluxo já tem uma etapa com esta ordem.';
COMMENT ON CONSTRAINT chk_apv_objecto ON nucleo.aprovacao IS 'Um processo de aprovação refere-se a um só objecto (despesa, saída, contagem, orçamento ou membro).';
COMMENT ON INDEX nucleo.uq_apv_em_curso IS 'Este objecto já tem um processo de aprovação em curso.';
COMMENT ON INDEX nucleo.uq_apd_apv_id_etapa IS 'Esta etapa já foi decidida.';

-- ---------------------------------------------------------------- permissões novas
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'nucleo.' || t.tabela || '.' || a.accao, a.rotulo || t.descricao
  FROM (VALUES ('fluxo_aprovacao', 'Fluxos de aprovação (etapas por natureza do processo e valor) (V54)'),
               ('fluxo_etapa', 'Etapas dos fluxos de aprovação (V54)')) t(tabela, descricao)
 CROSS JOIN (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo)
UNION ALL SELECT 'nucleo.aprovacao.ler', 'Ler: Processos de aprovação (V54)'
UNION ALL SELECT 'nucleo.aprovacao_decisao.ler', 'Ler: Decisões das etapas de aprovação (V54)';

-- configuram os fluxos: o administrador e o pastor na igreja; a administração da Associação nos modelos
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT p.per_id, m.prm_id
  FROM nucleo.perfil p JOIN nucleo.permissao m ON m.prm_codigo LIKE 'nucleo.fluxo\_%'
 WHERE p.per_codigo IN ('ADMIN', 'PASTOR', 'ADMIN_ASSOCIACAO')
UNION ALL
SELECT p.per_id, m.prm_id
  FROM nucleo.perfil p JOIN nucleo.permissao m ON m.prm_codigo IN ('nucleo.aprovacao.ler', 'nucleo.aprovacao_decisao.ler')
 WHERE p.per_codigo IN ('PASTOR', 'ADMIN_ASSOCIACAO');

-- ---------------------------------------------------------------- quem pode decidir uma etapa
-- (como nucleo.fn_igrejas_com_permissao, mas para qualquer utilizador e não só o da sessão)
CREATE FUNCTION nucleo.fn_usuario_tem_perfil(p_usu INT, p_per INT, p_igr INT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT EXISTS (SELECT 1 FROM nucleo.usuario_igreja u
                    WHERE u.uig_usu_id = p_usu AND u.uig_per_id = p_per AND u.uig_igr_id = p_igr
                      AND u.uig_estado = 'ACTIVO' AND u.uig_end_date IS NULL)
        OR EXISTS (SELECT 1 FROM nucleo.usuario_entidade u JOIN organizacao.igreja i ON i.igr_ent_id = u.uen_ent_id
                    WHERE u.uen_usu_id = p_usu AND u.uen_per_id = p_per AND i.igr_id = p_igr
                      AND u.uen_estado = 'ACTIVO' AND u.uen_end_date IS NULL)
        OR EXISTS (SELECT 1 FROM organizacao.distrito d
                     JOIN organizacao.igreja i ON i.igr_dst_id = d.dst_id
                     JOIN nucleo.perfil pf ON pf.per_id = p_per AND pf.per_codigo = 'PASTOR'
                    WHERE d.dst_pastor_usu_id = p_usu AND i.igr_id = p_igr AND d.dst_end_date IS NULL);
$$;

CREATE FUNCTION nucleo.fn_usuario_tem_permissao(p_usu INT, p_codigo TEXT, p_igr INT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT EXISTS (SELECT 1 FROM nucleo.perfil_permissao pp
                     JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id AND pm.prm_codigo = p_codigo AND pm.prm_end_date IS NULL
                    WHERE pp.ppe_end_date IS NULL AND nucleo.fn_usuario_tem_perfil(p_usu, pp.ppe_per_id, p_igr));
$$;

CREATE FUNCTION nucleo.fn_usuario_pode_etapa(p_usu INT, p_fae INT, p_igr INT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT CASE e.fae_responsavel
               WHEN 'PERFIL' THEN nucleo.fn_usuario_tem_perfil(p_usu, e.fae_per_id, p_igr)
               WHEN 'PERMISSAO' THEN nucleo.fn_usuario_tem_permissao(p_usu, (SELECT prm_codigo FROM nucleo.permissao WHERE prm_id = e.fae_prm_id), p_igr)
               ELSE FALSE END                                 -- ORGAO: decide o órgão, por voto
      FROM nucleo.fluxo_etapa e WHERE e.fae_id = p_fae;
$$;

CREATE FUNCTION nucleo.fn_orgao_nome(p_orgao nucleo.tipo_reuniao_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_orgao
               WHEN 'JUNTA_DIRECTIVA' THEN 'Conselho da Igreja (junta directiva)'
               WHEN 'REUNIAO_REGULAR' THEN 'Igreja em reunião regular'
               WHEN 'ASSEMBLEIA_ADMINISTRATIVA' THEN 'Igreja em reunião administrativa'
               WHEN 'COMISSAO_NOMEACOES' THEN 'Comissão de nomeações'
               WHEN 'CONSELHO_ES' THEN 'Conselho da Escola Sabatina'
           END;
$$;

-- nome de um perfil para mostrar ("Ancião"); os perfis criados pelos utilizadores mostram o nome que têm
CREATE FUNCTION nucleo.fn_perfil_rotulo(p_per INT) RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT CASE per_codigo
               WHEN 'ADMIN' THEN 'Administrador' WHEN 'PASTOR' THEN 'Pastor' WHEN 'ANCIAO' THEN 'Ancião'
               WHEN 'SECRETARIO' THEN 'Secretário' WHEN 'TESOUREIRO' THEN 'Tesoureiro'
               WHEN 'DIRECTOR_ES' THEN 'Director da Escola Sabatina' WHEN 'SECRETARIO_ES' THEN 'Secretário da Escola Sabatina'
               WHEN 'DIRECTOR_DEPARTAMENTO' THEN 'Director de departamento' WHEN 'MEMBRO' THEN 'Membro'
               WHEN 'ADMIN_ASSOCIACAO' THEN 'Administração da Associação' WHEN 'TESOUREIRO_ASSOCIACAO' THEN 'Tesoureiro da Associação'
               WHEN 'SECRETARIO_ASSOCIACAO' THEN 'Secretário da Associação' WHEN 'INTEGRACAO' THEN 'Integração'
               ELSE per_nome END
      FROM nucleo.perfil WHERE per_id = p_per;
$$;

-- nome de um utilizador para mostrar (quem pediu, quem decidiu): o do membro ligado, senão o da conta. Quem vê o processo
-- vê quem decidiu, mesmo sem poder ler a lista de utilizadores.
CREATE FUNCTION nucleo.fn_nome_usuario(p_usu INT) RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT COALESCE(NULLIF(trim(concat_ws(' ', m.mem_nome, m.mem_apelido)), ''), u.usu_nome, u.usu_email, u.usu_telefone)
      FROM nucleo.usuario u LEFT JOIN secretaria.membro m ON m.mem_id = u.usu_mem_id
     WHERE u.usu_id = p_usu;
$$;

-- quem decide, em palavras: "Tesoureiro", "Pastor ou Ancião", "Conselho da Igreja (junta directiva)"
CREATE FUNCTION nucleo.fn_etapa_quem(p_fae INT) RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT CASE e.fae_responsavel
               WHEN 'PERFIL' THEN nucleo.fn_perfil_rotulo(e.fae_per_id)
               WHEN 'PERMISSAO' THEN COALESCE(
                   (SELECT string_agg(nucleo.fn_perfil_rotulo(pf.per_id), ' ou ' ORDER BY pf.per_id)
                      FROM nucleo.perfil_permissao pp JOIN nucleo.perfil pf ON pf.per_id = pp.ppe_per_id AND pf.per_end_date IS NULL
                     WHERE pp.ppe_prm_id = e.fae_prm_id AND pp.ppe_end_date IS NULL AND pf.per_ambito = 'IGREJA'),
                   (SELECT COALESCE(prm_descricao, prm_codigo) FROM nucleo.permissao WHERE prm_id = e.fae_prm_id))
               ELSE nucleo.fn_orgao_nome(e.fae_orgao) END
      FROM nucleo.fluxo_etapa e WHERE e.fae_id = p_fae;
$$;

-- os nomes de quem pode decidir a etapa nesta igreja (utilizadores da igreja e o pastor do distrito)
CREATE FUNCTION nucleo.fn_etapa_responsaveis(p_fae INT, p_igr INT) RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT string_agg(DISTINCT x.nome, ', ')
      FROM (SELECT nucleo.fn_nome_usuario(u.usu_id) AS nome
              FROM nucleo.usuario u
             WHERE u.usu_end_date IS NULL AND u.usu_estado = 'ACTIVO'
               AND (u.usu_id IN (SELECT g.uig_usu_id FROM nucleo.usuario_igreja g
                                  WHERE g.uig_igr_id = p_igr AND g.uig_estado = 'ACTIVO' AND g.uig_end_date IS NULL)
                    OR u.usu_id IN (SELECT d.dst_pastor_usu_id FROM organizacao.distrito d JOIN organizacao.igreja i ON i.igr_dst_id = d.dst_id
                                     WHERE i.igr_id = p_igr AND d.dst_end_date IS NULL))
               AND nucleo.fn_usuario_pode_etapa(u.usu_id, p_fae, p_igr)) x;
$$;

-- permissão de quem regista a decisão de um órgão (além de quem regista votos)
CREATE FUNCTION nucleo.fn_aprovacao_permissao(p_processo nucleo.processo_aprovacao_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_processo
               WHEN 'DESPESA' THEN 'tesouraria.despesa.aprovar'
               WHEN 'SAIDA' THEN 'tesouraria.transacao.aprovar'
               WHEN 'CONTAGEM' THEN 'tesouraria.contagem_numerario.alterar'
               WHEN 'ORCAMENTO' THEN 'tesouraria.orcamento.aprovar'
               ELSE 'secretaria.movimento_membro.criar' END;
$$;

-- ---------------------------------------------------------------- escolher o fluxo e iniciar o processo
-- O fluxo da igreja, se tiver algum para o processo; senão o modelo da Associação (igr_id vazio). Dos que se aplicam,
-- o de maior valor mínimo que não passe o valor. Um fluxo sem etapas activas não conta.
CREATE FUNCTION nucleo.fn_fluxo_escolher(p_processo nucleo.processo_aprovacao_t, p_igr INT, p_valor NUMERIC) RETURNS INT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH validos AS (
        SELECT f.* FROM nucleo.fluxo_aprovacao f
         WHERE f.fap_processo = p_processo AND f.fap_end_date IS NULL AND f.fap_estado = 'ACTIVO'
           AND (f.fap_igr_id = p_igr OR f.fap_igr_id IS NULL)
           AND EXISTS (SELECT 1 FROM nucleo.fluxo_etapa e WHERE e.fae_fap_id = f.fap_id AND e.fae_end_date IS NULL))
    SELECT v.fap_id FROM validos v
     WHERE (v.fap_igr_id = p_igr OR NOT EXISTS (SELECT 1 FROM validos w WHERE w.fap_igr_id = p_igr))
       AND v.fap_valor_minimo <= COALESCE(p_valor, 0)
     ORDER BY v.fap_valor_minimo DESC LIMIT 1;
$$;

CREATE FUNCTION nucleo.fn_aprovacao_iniciar(p_processo nucleo.processo_aprovacao_t, p_igr INT, p_assunto TEXT, p_valor NUMERIC,
                                            p_pedido INT, p_des INT DEFAULT NULL, p_tra BIGINT DEFAULT NULL, p_cnu INT DEFAULT NULL,
                                            p_orc INT DEFAULT NULL, p_mem INT DEFAULT NULL) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_fap INT; v_etapa SMALLINT; v_id INT;
BEGIN
    v_fap := nucleo.fn_fluxo_escolher(p_processo, p_igr, p_valor);
    IF v_fap IS NULL THEN
        RETURN NULL;                                       -- sem fluxo: ficam as regras de antes (uma aprovação)
    END IF;
    SELECT min(fae_ordem) INTO v_etapa FROM nucleo.fluxo_etapa WHERE fae_fap_id = v_fap AND fae_end_date IS NULL;
    INSERT INTO nucleo.aprovacao (apv_igr_id, apv_fap_id, apv_processo, apv_assunto, apv_valor, apv_pedido_por_usu_id, apv_etapa,
                                  apv_des_id, apv_tra_id, apv_cnu_id, apv_orc_id, apv_mem_id)
    VALUES (p_igr, v_fap, p_processo, left(COALESCE(NULLIF(trim(p_assunto), ''), p_processo::TEXT), 255), p_valor, p_pedido, v_etapa,
            p_des, p_tra, p_cnu, p_orc, p_mem)
    RETURNING apv_id INTO v_id;
    RETURN v_id;
END $$;

-- a etapa por decidir (se a etapa guardada foi terminada na configuração, a seguinte)
CREATE FUNCTION nucleo.fn_aprovacao_etapa(p_apv INT) RETURNS nucleo.fluxo_etapa
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT e.* FROM nucleo.aprovacao a
      JOIN nucleo.fluxo_etapa e ON e.fae_fap_id = a.apv_fap_id AND e.fae_end_date IS NULL AND e.fae_ordem >= a.apv_etapa
     WHERE a.apv_id = p_apv
     ORDER BY e.fae_ordem LIMIT 1;
$$;

-- "etapa 1 de 2 — Apreciação do tesoureiro (Tesoureiro: Ana Matos)"
CREATE FUNCTION nucleo.fn_aprovacao_falta(p_apv INT) RETURNS TEXT
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE a nucleo.aprovacao%ROWTYPE; e nucleo.fluxo_etapa; v_total INT; v_nomes TEXT;
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv;
    e := nucleo.fn_aprovacao_etapa(p_apv);
    IF e.fae_id IS NULL THEN RETURN 'nenhuma etapa'; END IF;
    SELECT count(*) INTO v_total FROM nucleo.fluxo_etapa WHERE fae_fap_id = a.apv_fap_id AND fae_end_date IS NULL;
    v_nomes := nucleo.fn_etapa_responsaveis(e.fae_id, a.apv_igr_id);
    RETURN format('etapa %s de %s — %s (%s%s)',
                  (SELECT count(*) FROM nucleo.fluxo_etapa WHERE fae_fap_id = a.apv_fap_id AND fae_end_date IS NULL AND fae_ordem <= e.fae_ordem),
                  v_total, e.fae_nome, nucleo.fn_etapa_quem(e.fae_id),
                  CASE WHEN e.fae_responsavel = 'ORGAO' THEN ', por voto em reunião'
                       WHEN v_nomes IS NULL THEN ': ninguém tem este perfil na igreja'
                       ELSE ': ' || v_nomes END);
END $$;

-- ---------------------------------------------------------------- aplicar a decisão final ao objecto
-- Corre depois de o processo ficar APROVADO ou REJEITADO. As guardas dos objectos (trg_*_09_fluxo e as aprovações de
-- V7) reconhecem a mudança pelo processo concluído nesta transacção (nucleo.fn_aprovacao_concluida_agora).
CREATE FUNCTION nucleo.fn_aprovacao_concluida_agora(p_processo nucleo.processo_aprovacao_t, p_id BIGINT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT EXISTS (SELECT 1 FROM nucleo.aprovacao a
                    WHERE a.apv_processo = p_processo AND a.apv_estado IN ('APROVADO', 'REJEITADO') AND a.apv_concluido_em = now()
                      AND a.apv_end_date IS NULL
                      AND p_id = CASE p_processo WHEN 'DESPESA' THEN a.apv_des_id WHEN 'SAIDA' THEN a.apv_tra_id
                                                 WHEN 'CONTAGEM' THEN a.apv_cnu_id WHEN 'ORCAMENTO' THEN a.apv_orc_id ELSE a.apv_mem_id END);
$$;

CREATE FUNCTION nucleo.fn_aprovacao_aplicar(p_apv INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE a nucleo.aprovacao%ROWTYPE; d nucleo.aprovacao_decisao%ROWTYPE; v_vot INT;
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv;
    SELECT * INTO d FROM nucleo.aprovacao_decisao WHERE apd_apv_id = p_apv AND apd_end_date IS NULL ORDER BY apd_etapa DESC LIMIT 1;
    SELECT apd_vot_id INTO v_vot FROM nucleo.aprovacao_decisao
     WHERE apd_apv_id = p_apv AND apd_end_date IS NULL AND apd_vot_id IS NOT NULL ORDER BY apd_etapa DESC LIMIT 1;
    IF a.apv_processo = 'DESPESA' THEN
        UPDATE tesouraria.despesa
           SET des_estado = CASE WHEN a.apv_estado = 'APROVADO' THEN 'APROVADA' ELSE 'REJEITADA' END::nucleo.estado_despesa_t,
               des_valor_aprovado = CASE WHEN a.apv_estado = 'APROVADO' THEN COALESCE(a.apv_valor, des_valor_solicitado) END,
               des_motivo_rejeicao = CASE WHEN a.apv_estado = 'REJEITADO'
                                          THEN COALESCE(d.apd_motivo, 'Rejeitada na etapa ' || d.apd_etapa || ' do fluxo de aprovação') END,
               des_vot_id = COALESCE(v_vot, des_vot_id)
         WHERE des_id = a.apv_des_id AND des_estado = 'SUBMETIDA';
    ELSIF a.apv_processo = 'SAIDA' AND a.apv_estado = 'APROVADO' THEN
        UPDATE tesouraria.transacao SET tra_aprovado_por_usu_id = nucleo.fn_usuario_sessao()
         WHERE tra_id = a.apv_tra_id AND tra_estado = 'PENDENTE';
    ELSIF a.apv_processo = 'CONTAGEM' THEN
        IF a.apv_estado = 'APROVADO' THEN
            UPDATE tesouraria.contagem_numerario SET cnu_estado = 'CONFERIDA', cnu_conferido_por_usu_id = nucleo.fn_usuario_sessao()
             WHERE cnu_id = a.apv_cnu_id AND cnu_estado = 'ABERTA';
        ELSE                                               -- recontar: a conferência recomeça
            PERFORM nucleo.fn_aprovacao_iniciar('CONTAGEM', a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_cnu => a.apv_cnu_id);
        END IF;
    ELSIF a.apv_processo = 'ORCAMENTO' THEN
        IF a.apv_estado = 'APROVADO' THEN
            UPDATE tesouraria.orcamento SET orc_estado = 'APROVADO', orc_vot_id = COALESCE(v_vot, orc_vot_id)
             WHERE orc_id = a.apv_orc_id AND orc_estado = 'RASCUNHO';
        ELSE                                               -- rever o orçamento e voltar a submeter
            PERFORM nucleo.fn_aprovacao_iniciar('ORCAMENTO', a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_orc => a.apv_orc_id);
        END IF;
    END IF;
    -- admissão e remoção: o livro de membros verifica o processo aprovado (secretaria.fn_mmb_fluxo)
END $$;

-- ---------------------------------------------------------------- decidir a etapa em curso
-- Etapa PERFIL / PERMISSAO: decide quem tem o perfil (ou a permissão) na igreja; se a etapa pede outra pessoa, nem quem
-- pediu nem quem já decidiu outra etapa. Etapa ORGAO: decide o órgão, pelo voto de uma reunião desse tipo na igreja (a
-- decisão é o resultado do voto); regista-o quem regista votos ou tem a permissão de aprovar o objecto.
CREATE FUNCTION nucleo.fn_aprovacao_registar(p_apv INT, p_aprovar BOOLEAN, p_vot INT, p_motivo TEXT, p_valor NUMERIC,
                                             p_aplicar BOOLEAN) RETURNS nucleo.estado_aprovacao_t
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    a nucleo.aprovacao%ROWTYPE; e nucleo.fluxo_etapa; v secretaria.voto%ROWTYPE; r secretaria.reuniao%ROWTYPE;
    v_usr INT := nucleo.fn_usuario_sessao(); v_aprovado BOOLEAN := p_aprovar; v_prox SMALLINT; v_estado nucleo.estado_aprovacao_t;
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv AND apv_end_date IS NULL FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O processo de aprovação não existe' USING ERRCODE = 'P0002';
    END IF;
    IF a.apv_estado <> 'EM_CURSO' THEN
        RAISE EXCEPTION 'Este processo de aprovação já terminou (%)', lower(a.apv_estado::TEXT);
    END IF;
    IF v_usr IS NULL THEN
        RAISE EXCEPTION 'Sem utilizador identificado na sessão (app.usuario_id)';
    END IF;
    e := nucleo.fn_aprovacao_etapa(p_apv);
    IF e.fae_id IS NULL THEN
        RAISE EXCEPTION 'O fluxo deste processo já não tem etapas por decidir: reveja a configuração do fluxo';
    END IF;

    IF e.fae_responsavel = 'ORGAO' THEN
        IF p_vot IS NULL THEN
            RAISE EXCEPTION 'A etapa «%» decide-se por voto: % (indique o voto da reunião)', e.fae_nome, nucleo.fn_orgao_nome(e.fae_orgao)
                USING COLUMN = 'apd_vot_id';
        END IF;
        SELECT * INTO v FROM secretaria.voto WHERE vot_id = p_vot AND vot_end_date IS NULL;
        SELECT * INTO r FROM secretaria.reuniao WHERE reu_id = v.vot_reu_id AND reu_end_date IS NULL;
        IF v.vot_id IS NULL OR r.reu_id IS NULL OR r.reu_igr_id <> a.apv_igr_id THEN
            RAISE EXCEPTION 'O voto indicado não existe nesta igreja' USING COLUMN = 'apd_vot_id';
        END IF;
        IF r.reu_tipo <> e.fae_orgao THEN
            RAISE EXCEPTION 'A etapa «%» decide-se por voto: %; o voto n.º % é de outra reunião (%)',
                e.fae_nome, nucleo.fn_orgao_nome(e.fae_orgao), v.vot_numero, nucleo.fn_orgao_nome(r.reu_tipo) USING COLUMN = 'apd_vot_id';
        END IF;
        IF r.reu_estado::TEXT = 'CANCELADA' THEN
            RAISE EXCEPTION 'A reunião do voto n.º % foi cancelada', v.vot_numero USING COLUMN = 'apd_vot_id';
        END IF;
        IF v.vot_estado = 'ADIADO' THEN
            RAISE EXCEPTION 'O voto n.º % foi adiado: a etapa «%» continua por decidir', v.vot_numero, e.fae_nome USING COLUMN = 'apd_vot_id';
        END IF;
        IF a.apv_mem_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM secretaria.voto_membro
                                                     WHERE vtm_vot_id = p_vot AND vtm_mem_id = a.apv_mem_id AND vtm_end_date IS NULL) THEN
            RAISE EXCEPTION 'O voto n.º % não indica a pessoa deste processo', v.vot_numero USING COLUMN = 'apd_vot_id';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.aprovacao_decisao WHERE apd_apv_id = p_apv AND apd_vot_id = p_vot AND apd_end_date IS NULL) THEN
            RAISE EXCEPTION 'O voto n.º % já decidiu outra etapa deste processo', v.vot_numero USING COLUMN = 'apd_vot_id';
        END IF;
        IF NOT (nucleo.fn_tem_permissao(nucleo.fn_aprovacao_permissao(a.apv_processo), a.apv_igr_id)
                OR nucleo.fn_tem_permissao('secretaria.voto.criar', a.apv_igr_id)) THEN
            RAISE EXCEPTION 'Sem permissão para registar a decisão de % nesta igreja', nucleo.fn_orgao_nome(e.fae_orgao)
                USING ERRCODE = 'insufficient_privilege';
        END IF;
        v_aprovado := v.vot_estado = 'APROVADO';           -- decide o órgão, não quem regista
    ELSE
        IF NOT (nucleo.fn_e_super_admin() OR nucleo.fn_usuario_pode_etapa(v_usr, e.fae_id, a.apv_igr_id)) THEN
            RAISE EXCEPTION 'A etapa «%» cabe a: %', e.fae_nome,
                nucleo.fn_etapa_quem(e.fae_id) || COALESCE(' (' || nucleo.fn_etapa_responsaveis(e.fae_id, a.apv_igr_id) || ')', '')
                USING ERRCODE = 'insufficient_privilege';
        END IF;
        IF e.fae_outra_pessoa AND (v_usr = a.apv_pedido_por_usu_id
                                   OR EXISTS (SELECT 1 FROM nucleo.aprovacao_decisao WHERE apd_apv_id = p_apv AND apd_usu_id = v_usr
                                                 AND apd_vot_id IS NULL AND apd_end_date IS NULL)) THEN
            RAISE EXCEPTION 'A etapa «%» tem de ser decidida por outra pessoa: quem pediu, ou já decidiu outra etapa, não a decide', e.fae_nome;
        END IF;
        IF p_aprovar IS NULL THEN
            RAISE EXCEPTION 'Indique se aprova ou rejeita' USING COLUMN = 'apd_aprovado';
        END IF;
        IF NOT p_aprovar AND NULLIF(trim(p_motivo), '') IS NULL THEN
            RAISE EXCEPTION 'Indique o motivo da rejeição' USING COLUMN = 'apd_motivo';
        END IF;
    END IF;
    IF p_valor IS NOT NULL AND (a.apv_valor IS NULL OR p_valor <= 0 OR p_valor > a.apv_valor) THEN
        RAISE EXCEPTION 'O valor aprovado tem de ser maior que zero e não pode passar o valor pedido (%)', a.apv_valor USING COLUMN = 'apd_valor';
    END IF;

    INSERT INTO nucleo.aprovacao_decisao (apd_apv_id, apd_igr_id, apd_fae_id, apd_etapa, apd_aprovado, apd_usu_id, apd_vot_id, apd_motivo, apd_valor)
    VALUES (p_apv, a.apv_igr_id, e.fae_id, e.fae_ordem, v_aprovado, v_usr, p_vot, NULLIF(trim(p_motivo), ''),
            CASE WHEN v_aprovado THEN p_valor END);
    IF NOT v_aprovado THEN
        UPDATE nucleo.aprovacao SET apv_estado = 'REJEITADO', apv_etapa = e.fae_ordem, apv_concluido_em = now() WHERE apv_id = p_apv;
    ELSE
        SELECT min(fae_ordem) INTO v_prox FROM nucleo.fluxo_etapa
         WHERE fae_fap_id = a.apv_fap_id AND fae_end_date IS NULL AND fae_ordem > e.fae_ordem;
        UPDATE nucleo.aprovacao
           SET apv_etapa = COALESCE(v_prox, e.fae_ordem), apv_valor = COALESCE(p_valor, apv_valor),
               apv_estado = CASE WHEN v_prox IS NULL THEN 'APROVADO' ELSE 'EM_CURSO' END::nucleo.estado_aprovacao_t,
               apv_concluido_em = CASE WHEN v_prox IS NULL THEN now() END
         WHERE apv_id = p_apv;
    END IF;
    SELECT apv_estado INTO v_estado FROM nucleo.aprovacao WHERE apv_id = p_apv;
    IF p_aplicar AND v_estado <> 'EM_CURSO' THEN
        PERFORM nucleo.fn_aprovacao_aplicar(p_apv);
    END IF;
    RETURN v_estado;
END $$;

-- API: POST /v1/nucleo/aprovacoes/{id}/decidir
CREATE FUNCTION nucleo.fn_aprovacao_decidir(p_apv INT, p_aprovar BOOLEAN, p_vot INT DEFAULT NULL, p_motivo TEXT DEFAULT NULL,
                                            p_valor NUMERIC DEFAULT NULL) RETURNS nucleo.estado_aprovacao_t
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    -- quem não vê o processo recebe "não existe" (404), como na RLS
    IF NOT EXISTS (SELECT 1 FROM nucleo.aprovacao a WHERE a.apv_id = p_apv AND a.apv_end_date IS NULL
                      AND a.apv_igr_id = ANY (nucleo.fn_igrejas_com_permissao(
                          CASE a.apv_processo WHEN 'DESPESA' THEN 'tesouraria.despesa.ler' WHEN 'SAIDA' THEN 'tesouraria.transacao.ler'
                                              WHEN 'CONTAGEM' THEN 'tesouraria.contagem_numerario.ler' WHEN 'ORCAMENTO' THEN 'tesouraria.orcamento.ler'
                                              ELSE 'secretaria.movimento_membro.ler' END))) THEN
        RAISE EXCEPTION 'O processo de aprovação não existe' USING ERRCODE = 'P0002';
    END IF;
    RETURN nucleo.fn_aprovacao_registar(p_apv, p_aprovar, p_vot, p_motivo, p_valor, TRUE);
END $$;

-- o utilizador da sessão pode decidir a etapa em curso? (botões do ecrã; a decisão verifica de novo)
CREATE FUNCTION nucleo.fn_aprovacao_pode_decidir(p_apv INT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE a nucleo.aprovacao%ROWTYPE; e nucleo.fluxo_etapa; v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv AND apv_estado = 'EM_CURSO' AND apv_end_date IS NULL;
    IF NOT FOUND OR v_usr IS NULL THEN RETURN FALSE; END IF;
    e := nucleo.fn_aprovacao_etapa(p_apv);
    IF e.fae_id IS NULL THEN RETURN FALSE; END IF;
    IF e.fae_responsavel = 'ORGAO' THEN
        RETURN nucleo.fn_tem_permissao(nucleo.fn_aprovacao_permissao(a.apv_processo), a.apv_igr_id)
            OR nucleo.fn_tem_permissao('secretaria.voto.criar', a.apv_igr_id);
    END IF;
    IF NOT (nucleo.fn_e_super_admin() OR nucleo.fn_usuario_pode_etapa(v_usr, e.fae_id, a.apv_igr_id)) THEN RETURN FALSE; END IF;
    RETURN NOT (e.fae_outra_pessoa AND (v_usr = a.apv_pedido_por_usu_id
                OR EXISTS (SELECT 1 FROM nucleo.aprovacao_decisao WHERE apd_apv_id = p_apv AND apd_usu_id = v_usr
                              AND apd_vot_id IS NULL AND apd_end_date IS NULL)));
END $$;

-- Mudar o estado do objecto à mão (PATCH estado, como antes de V54) conta como decidir a etapa em curso, se for a última e
-- não for de um órgão (ou se for de um órgão e vier o voto). Com mais etapas por decidir, a mudança é recusada e diz o que falta.
CREATE FUNCTION nucleo.fn_aprovacao_mudanca_directa(p_apv INT, p_aprovar BOOLEAN, p_vot INT, p_motivo TEXT, p_valor NUMERIC, p_objecto TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE a nucleo.aprovacao%ROWTYPE; e nucleo.fluxo_etapa; v_restam INT;
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv;
    e := nucleo.fn_aprovacao_etapa(p_apv);
    SELECT count(*) INTO v_restam FROM nucleo.fluxo_etapa WHERE fae_fap_id = a.apv_fap_id AND fae_end_date IS NULL AND fae_ordem >= e.fae_ordem;
    IF p_aprovar AND (v_restam > 1 OR (e.fae_responsavel = 'ORGAO' AND p_vot IS NULL)) THEN
        RAISE EXCEPTION '% segue o fluxo «%» e ainda não está aprovado: falta a %. Decida em Aprovações.',
            p_objecto, (SELECT fap_nome FROM nucleo.fluxo_aprovacao WHERE fap_id = a.apv_fap_id), nucleo.fn_aprovacao_falta(p_apv);
    END IF;
    PERFORM nucleo.fn_aprovacao_registar(p_apv, p_aprovar, CASE WHEN e.fae_responsavel = 'ORGAO' THEN p_vot END, p_motivo, p_valor, FALSE);
END $$;

-- o processo em curso de um objecto
CREATE FUNCTION nucleo.fn_aprovacao_em_curso(p_processo nucleo.processo_aprovacao_t, p_id BIGINT) RETURNS INT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT a.apv_id FROM nucleo.aprovacao a
     WHERE a.apv_processo = p_processo AND a.apv_estado = 'EM_CURSO' AND a.apv_end_date IS NULL
       AND p_id = CASE p_processo WHEN 'DESPESA' THEN a.apv_des_id WHEN 'SAIDA' THEN a.apv_tra_id
                                  WHEN 'CONTAGEM' THEN a.apv_cnu_id WHEN 'ORCAMENTO' THEN a.apv_orc_id ELSE a.apv_mem_id END;
$$;

CREATE FUNCTION nucleo.fn_aprovacao_cancelar(p_processo nucleo.processo_aprovacao_t, p_id BIGINT) RETURNS VOID
LANGUAGE sql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    UPDATE nucleo.aprovacao SET apv_estado = 'CANCELADO', apv_concluido_em = now()
     WHERE apv_id = nucleo.fn_aprovacao_em_curso(p_processo, p_id);
$$;

-- ================================================================ despesas
CREATE FUNCTION tesouraria.fn_des_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.des_estado = 'SUBMETIDA' AND NEW.des_end_date IS NULL THEN
        PERFORM nucleo.fn_aprovacao_iniciar('DESPESA', NEW.des_igr_id, 'Despesa: ' || NEW.des_descricao, NEW.des_valor_solicitado,
                                            NEW.des_solicitado_por_usu_id, p_des => NEW.des_id);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_des_50_fluxo_iniciar AFTER INSERT ON tesouraria.despesa
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_des_fluxo_iniciar();

CREATE FUNCTION tesouraria.fn_des_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_apv INT := nucleo.fn_aprovacao_em_curso('DESPESA', OLD.des_id);
BEGIN
    IF v_apv IS NULL THEN RETURN NEW; END IF;
    IF OLD.des_estado = 'SUBMETIDA' AND NEW.des_estado IN ('APROVADA', 'REJEITADA') THEN
        PERFORM nucleo.fn_aprovacao_mudanca_directa(v_apv, NEW.des_estado = 'APROVADA', NEW.des_vot_id, NEW.des_motivo_rejeicao,
                                                    NEW.des_valor_aprovado, 'A despesa');
    ELSIF NEW.des_estado = 'CANCELADA' OR NEW.des_end_date IS NOT NULL THEN
        PERFORM nucleo.fn_aprovacao_cancelar('DESPESA', OLD.des_id);
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_des_09_fluxo BEFORE UPDATE OF des_estado, des_end_date ON tesouraria.despesa
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_des_fluxo();

-- igual à de V7; a decisão final de um fluxo (V54) já verificou quem decide cada etapa
CREATE OR REPLACE FUNCTION tesouraria.fn_des_aprovacao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.des_estado IN ('APROVADA', 'REJEITADA') AND (TG_OP = 'INSERT' OR OLD.des_estado IS DISTINCT FROM NEW.des_estado) THEN
        IF TG_OP = 'INSERT' OR NOT nucleo.fn_aprovacao_concluida_agora('DESPESA', NEW.des_id) THEN
            PERFORM nucleo.fn_exigir('tesouraria.despesa.aprovar', NEW.des_igr_id);
        END IF;
        NEW.des_aprovado_por_usu_id := COALESCE(nucleo.fn_usuario_sessao(), NEW.des_aprovado_por_usu_id);
        NEW.des_aprovado_em := now();
    END IF;
    RETURN NEW;
END $$;

-- igual à de V16, mas com fluxo decide a etapa em curso (com várias etapas, chama-se uma vez por etapa)
CREATE OR REPLACE FUNCTION tesouraria.fn_decidir_despesa(p_des INT, p_aprovar BOOLEAN, p_valor NUMERIC DEFAULT NULL,
                                                         p_motivo TEXT DEFAULT NULL) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE d tesouraria.despesa%ROWTYPE; v_apv INT;
BEGIN
    SELECT * INTO d FROM tesouraria.despesa WHERE des_id = p_des AND des_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR d.des_estado <> 'SUBMETIDA' THEN RAISE EXCEPTION 'Só se decide uma despesa submetida'; END IF;
    v_apv := nucleo.fn_aprovacao_em_curso('DESPESA', p_des);
    IF v_apv IS NOT NULL THEN
        PERFORM nucleo.fn_aprovacao_registar(v_apv, p_aprovar, NULL, p_motivo, p_valor, TRUE);
        RETURN;
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.despesa.aprovar', d.des_igr_id);
    UPDATE tesouraria.despesa
       SET des_estado = CASE WHEN p_aprovar THEN 'APROVADA' ELSE 'REJEITADA' END::nucleo.estado_despesa_t,
           des_valor_aprovado = CASE WHEN p_aprovar THEN COALESCE(p_valor, d.des_valor_solicitado) END,
           des_motivo_rejeicao = CASE WHEN NOT p_aprovar THEN p_motivo END
     WHERE des_id = p_des;
END $$;

-- ================================================================ saídas de dinheiro (sem despesa aprovada)
CREATE FUNCTION tesouraria.fn_tra_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    PERFORM nucleo.fn_aprovacao_iniciar('SAIDA', NEW.tra_igr_id,
        CASE WHEN NEW.tra_estorno_tra_id IS NOT NULL THEN 'Estorno: ' ELSE 'Saída: ' END
            || COALESCE(NULLIF(NEW.tra_descricao, ''), NEW.tra_beneficiario, 'sem descrição'),
        NEW.tra_valor_total, nucleo.fn_usuario_sessao(), p_tra => NEW.tra_id);
    RETURN NULL;
END $$;
CREATE TRIGGER trg_tra_50_fluxo_iniciar AFTER INSERT ON tesouraria.transacao FOR EACH ROW
    WHEN (NEW.tra_tipo = 'SAIDA' AND NEW.tra_estado = 'PENDENTE' AND NEW.tra_des_id IS NULL AND NEW.tra_aprovado_por_usu_id IS NULL
          AND NEW.tra_end_date IS NULL)
    EXECUTE FUNCTION tesouraria.fn_tra_fluxo_iniciar();

CREATE FUNCTION tesouraria.fn_tra_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_apv INT := nucleo.fn_aprovacao_em_curso('SAIDA', OLD.tra_id);
BEGIN
    IF v_apv IS NULL THEN RETURN NEW; END IF;
    IF NEW.tra_aprovado_por_usu_id IS NOT NULL AND OLD.tra_aprovado_por_usu_id IS NULL THEN
        PERFORM nucleo.fn_aprovacao_mudanca_directa(v_apv, TRUE, NULL, NULL, NULL, 'A saída');
    ELSIF NEW.tra_estado <> 'PENDENTE' OR NEW.tra_des_id IS NOT NULL OR NEW.tra_end_date IS NOT NULL THEN
        -- confirmada sem aprovação (só remessa à Missão), paga por uma despesa aprovada, anulada ou terminada
        PERFORM nucleo.fn_aprovacao_cancelar('SAIDA', OLD.tra_id);
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_tra_09_fluxo BEFORE UPDATE OF tra_aprovado_por_usu_id, tra_estado, tra_des_id, tra_end_date ON tesouraria.transacao
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_fluxo();

-- fn_tra_validar (V7) exige "tesouraria.transacao.aprovar" a quem aprova; com fluxo, a última etapa pode ser de outro perfil
-- ou de um órgão, e o fluxo já verificou quem decide. Troca-se só essa linha na função de V7.
DO $$
DECLARE v_def TEXT := pg_get_functiondef('tesouraria.fn_tra_validar()'::regprocedure);
        v_de TEXT := 'PERFORM nucleo.fn_exigir(''tesouraria.transacao.aprovar'', NEW.tra_igr_id);';
BEGIN
    IF position(v_de IN v_def) = 0 THEN
        RAISE EXCEPTION 'V54: tesouraria.fn_tra_validar mudou; rever a troca da verificação de "aprovar"';
    END IF;
    EXECUTE replace(v_def, v_de,
        'IF TG_OP = ''INSERT'' OR NOT nucleo.fn_aprovacao_concluida_agora(''SAIDA'', NEW.tra_id) THEN ' || v_de || ' END IF;');
END $$;

-- igual à de V16, mas com fluxo decide a etapa em curso
CREATE OR REPLACE FUNCTION tesouraria.fn_aprovar_saida(p_tra BIGINT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE r tesouraria.transacao%ROWTYPE; v_apv INT;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = p_tra AND tra_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR r.tra_tipo <> 'SAIDA' OR r.tra_estado <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Só se aprova uma saída pendente';
    END IF;
    v_apv := nucleo.fn_aprovacao_em_curso('SAIDA', p_tra);
    IF v_apv IS NOT NULL THEN
        PERFORM nucleo.fn_aprovacao_registar(v_apv, TRUE, NULL, NULL, NULL, TRUE);
        RETURN;
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.transacao.aprovar', r.tra_igr_id);
    UPDATE tesouraria.transacao SET tra_aprovado_por_usu_id = nucleo.fn_usuario_sessao() WHERE tra_id = p_tra;
END $$;

-- ================================================================ contagem do numerário (conferência)
CREATE FUNCTION tesouraria.fn_cnu_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.cnu_estado::TEXT = 'ABERTA' AND NEW.cnu_end_date IS NULL THEN
        PERFORM nucleo.fn_aprovacao_iniciar('CONTAGEM', NEW.cnu_igr_id,
            'Contagem de ' || to_char(NEW.cnu_data, 'DD/MM/YYYY') || COALESCE(' · ' || NULLIF(NEW.cnu_ocasiao, ''), ''),
            NEW.cnu_total_contado, nucleo.fn_usuario_sessao(), p_cnu => NEW.cnu_id);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_cnu_50_fluxo_iniciar AFTER INSERT ON tesouraria.contagem_numerario
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cnu_fluxo_iniciar();

CREATE FUNCTION tesouraria.fn_cnu_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_apv INT := nucleo.fn_aprovacao_em_curso('CONTAGEM', OLD.cnu_id);
BEGIN
    IF OLD.cnu_estado::TEXT = 'ABERTA' AND NEW.cnu_estado::TEXT = 'CONFERIDA' THEN
        IF nucleo.fn_aprovacao_concluida_agora('CONTAGEM', OLD.cnu_id) THEN
            RETURN NEW;                                    -- conferida pelo fluxo (fn_aprovacao_aplicar)
        END IF;
        IF v_apv IS NULL THEN                              -- contagem anterior a V54
            v_apv := nucleo.fn_aprovacao_iniciar('CONTAGEM', OLD.cnu_igr_id, 'Contagem de ' || to_char(OLD.cnu_data, 'DD/MM/YYYY'),
                                                 OLD.cnu_total_contado, OLD.cnu_criado_por, p_cnu => OLD.cnu_id);
        END IF;
        IF v_apv IS NOT NULL THEN
            PERFORM nucleo.fn_aprovacao_mudanca_directa(v_apv, TRUE, NULL, NULL, NULL, 'A contagem');
        END IF;
        NEW.cnu_conferido_por_usu_id := COALESCE(nucleo.fn_usuario_sessao(), NEW.cnu_conferido_por_usu_id);
    ELSIF v_apv IS NOT NULL AND NEW.cnu_end_date IS NOT NULL THEN
        PERFORM nucleo.fn_aprovacao_cancelar('CONTAGEM', OLD.cnu_id);
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_cnu_09_fluxo BEFORE UPDATE OF cnu_estado, cnu_end_date ON tesouraria.contagem_numerario
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cnu_fluxo();

-- ================================================================ orçamento
CREATE FUNCTION tesouraria.fn_orc_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.orc_estado = 'RASCUNHO' AND NEW.orc_end_date IS NULL THEN
        PERFORM nucleo.fn_aprovacao_iniciar('ORCAMENTO', NEW.orc_igr_id,
            'Orçamento de ' || NEW.orc_ano || COALESCE(' · ' || (SELECT d.dep_nome FROM organizacao.igreja_departamento i
                                                                   JOIN organizacao.departamento d ON d.dep_id = i.ide_dep_id
                                                                  WHERE i.ide_id = NEW.orc_ide_id), ''),
            NULL, nucleo.fn_usuario_sessao(), p_orc => NEW.orc_id);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_orc_50_fluxo_iniciar AFTER INSERT ON tesouraria.orcamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_orc_fluxo_iniciar();

CREATE FUNCTION tesouraria.fn_orc_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_apv INT := nucleo.fn_aprovacao_em_curso('ORCAMENTO', OLD.orc_id);
BEGIN
    IF v_apv IS NULL THEN RETURN NEW; END IF;
    IF OLD.orc_estado = 'RASCUNHO' AND NEW.orc_estado = 'APROVADO' THEN
        PERFORM nucleo.fn_aprovacao_mudanca_directa(v_apv, TRUE, NEW.orc_vot_id, NULL, NULL, 'O orçamento');
    ELSIF NEW.orc_end_date IS NOT NULL OR NEW.orc_estado = 'ENCERRADO' THEN
        PERFORM nucleo.fn_aprovacao_cancelar('ORCAMENTO', OLD.orc_id);
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_orc_09_fluxo BEFORE UPDATE OF orc_estado, orc_end_date ON tesouraria.orcamento
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_orc_fluxo();

CREATE OR REPLACE FUNCTION tesouraria.fn_orc_aprovacao() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.orc_estado = 'APROVADO' AND (TG_OP = 'INSERT' OR OLD.orc_estado IS DISTINCT FROM NEW.orc_estado)
       AND (TG_OP = 'INSERT' OR NOT nucleo.fn_aprovacao_concluida_agora('ORCAMENTO', NEW.orc_id)) THEN
        PERFORM nucleo.fn_exigir('tesouraria.orcamento.aprovar', NEW.orc_igr_id);
    END IF;
    RETURN NEW;
END $$;

-- igual à de V16, mas com fluxo decide a etapa em curso (o voto decide as etapas de órgão)
CREATE OR REPLACE FUNCTION tesouraria.fn_aprovar_orcamento(p_orc INT, p_vot INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE o tesouraria.orcamento%ROWTYPE; v_apv INT;
BEGIN
    SELECT * INTO o FROM tesouraria.orcamento WHERE orc_id = p_orc AND orc_end_date IS NULL FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Orçamento inexistente'; END IF;
    v_apv := nucleo.fn_aprovacao_em_curso('ORCAMENTO', p_orc);
    IF v_apv IS NOT NULL THEN
        PERFORM nucleo.fn_aprovacao_registar(v_apv, TRUE, p_vot, NULL, NULL, TRUE);
        RETURN;
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.orcamento.aprovar', o.orc_igr_id);
    UPDATE tesouraria.orcamento SET orc_estado = 'APROVADO', orc_vot_id = p_vot WHERE orc_id = p_orc;
END $$;

-- ================================================================ admissão e remoção de membros (votos)
-- O voto de admissão ou remoção que indica uma pessoa (voto_membro) decide a etapa em curso do processo dessa pessoa
-- (e inicia-o, se não houver). Um voto de uma reunião que não é a da etapa em curso é recusado: a sequência é a do fluxo
-- (ex.: o Conselho da Igreja recomenda, depois a Igreja vota em reunião administrativa).
CREATE FUNCTION secretaria.fn_aprovacao_pelo_voto(p_vot INT, p_mem INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v secretaria.voto%ROWTYPE; r secretaria.reuniao%ROWTYPE; v_proc nucleo.processo_aprovacao_t; v_apv INT; e nucleo.fluxo_etapa;
    v_nome TEXT;
BEGIN
    SELECT * INTO v FROM secretaria.voto WHERE vot_id = p_vot AND vot_end_date IS NULL;
    IF NOT FOUND OR v.vot_estado = 'ADIADO' THEN RETURN; END IF;
    v_proc := CASE v.vot_tipo WHEN 'ADMISSAO' THEN 'ADMISSAO_MEMBRO' WHEN 'REMOCAO' THEN 'REMOCAO_MEMBRO' END;
    IF v_proc IS NULL THEN RETURN; END IF;
    IF EXISTS (SELECT 1 FROM nucleo.aprovacao_decisao d JOIN nucleo.aprovacao a ON a.apv_id = d.apd_apv_id
                WHERE d.apd_vot_id = p_vot AND a.apv_mem_id = p_mem AND d.apd_end_date IS NULL) THEN
        RETURN;                                            -- este voto já decidiu a etapa desta pessoa
    END IF;
    SELECT * INTO r FROM secretaria.reuniao WHERE reu_id = v.vot_reu_id;
    SELECT trim(concat_ws(' ', mem_nome, mem_apelido)) INTO v_nome FROM secretaria.membro WHERE mem_id = p_mem;
    v_apv := nucleo.fn_aprovacao_em_curso(v_proc, p_mem);
    IF v_apv IS NULL THEN
        v_apv := nucleo.fn_aprovacao_iniciar(v_proc, r.reu_igr_id,
                     CASE v_proc WHEN 'ADMISSAO_MEMBRO' THEN 'Admissão de ' ELSE 'Remoção de ' END || v_nome,
                     NULL, nucleo.fn_usuario_sessao(), p_mem => p_mem);
        IF v_apv IS NULL THEN RETURN; END IF;              -- igreja sem fluxo: só a regra do voto (V4)
    END IF;
    e := nucleo.fn_aprovacao_etapa(v_apv);
    IF e.fae_responsavel <> 'ORGAO' OR e.fae_orgao <> r.reu_tipo THEN
        RAISE EXCEPTION 'A % de % segue o fluxo «%»: a etapa em curso é a %. O voto n.º % (%) não a decide.',
            CASE v_proc WHEN 'ADMISSAO_MEMBRO' THEN 'admissão' ELSE 'remoção' END, v_nome,
            (SELECT f.fap_nome FROM nucleo.aprovacao a JOIN nucleo.fluxo_aprovacao f ON f.fap_id = a.apv_fap_id WHERE a.apv_id = v_apv),
            nucleo.fn_aprovacao_falta(v_apv), v.vot_numero, nucleo.fn_orgao_nome(r.reu_tipo)
            USING COLUMN = 'vtm_vot_id';
    END IF;
    PERFORM nucleo.fn_aprovacao_registar(v_apv, NULL, p_vot, NULL, NULL, TRUE);
END $$;

CREATE FUNCTION secretaria.fn_vtm_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.vtm_end_date IS NULL THEN
        PERFORM secretaria.fn_aprovacao_pelo_voto(NEW.vtm_vot_id, NEW.vtm_mem_id);
    END IF;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_vtm_50_fluxo AFTER INSERT ON secretaria.voto_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_vtm_fluxo();

-- um voto adiado que depois se decide (estado APROVADO ou REJEITADO) decide as etapas das pessoas que indica
CREATE FUNCTION secretaria.fn_vot_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE p RECORD;
BEGIN
    FOR p IN SELECT vtm_mem_id FROM secretaria.voto_membro WHERE vtm_vot_id = NEW.vot_id AND vtm_end_date IS NULL LOOP
        PERFORM secretaria.fn_aprovacao_pelo_voto(NEW.vot_id, p.vtm_mem_id);
    END LOOP;
    RETURN NULL;
END $$;
CREATE TRIGGER trg_vot_50_fluxo AFTER UPDATE OF vot_estado ON secretaria.voto
    FOR EACH ROW WHEN (OLD.vot_estado IS DISTINCT FROM NEW.vot_estado) EXECUTE FUNCTION secretaria.fn_vot_fluxo();

-- livro de membros: com fluxo para a admissão (ou remoção), o voto do movimento tem de ser de um processo aprovado
CREATE FUNCTION secretaria.fn_mmb_fluxo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_proc nucleo.processo_aprovacao_t; v_apv INT; v_fap INT; v_nome TEXT;
BEGIN
    v_proc := CASE WHEN NEW.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE') THEN 'ADMISSAO_MEMBRO'
                   WHEN NEW.mmb_tipo IN ('REMOCAO_PEDIDO', 'REMOCAO_DISCIPLINA', 'DESAPARECIDO') THEN 'REMOCAO_MEMBRO' END;
    IF v_proc IS NULL OR NEW.mmb_tme_id IS NOT NULL OR NEW.mmb_vot_id IS NULL THEN
        RETURN NEW;
    END IF;
    IF EXISTS (SELECT 1 FROM nucleo.aprovacao a JOIN nucleo.aprovacao_decisao d ON d.apd_apv_id = a.apv_id AND d.apd_end_date IS NULL
                WHERE a.apv_processo = v_proc AND a.apv_mem_id = NEW.mmb_mem_id AND a.apv_estado = 'APROVADO'
                  AND a.apv_end_date IS NULL AND d.apd_vot_id = NEW.mmb_vot_id) THEN
        RETURN NEW;
    END IF;
    SELECT trim(concat_ws(' ', mem_nome, mem_apelido)) INTO v_nome FROM secretaria.membro WHERE mem_id = NEW.mmb_mem_id;
    v_apv := nucleo.fn_aprovacao_em_curso(v_proc, NEW.mmb_mem_id);
    IF v_apv IS NOT NULL THEN
        RAISE EXCEPTION 'A % de % ainda não terminou o fluxo de aprovação: falta a %',
            CASE v_proc WHEN 'ADMISSAO_MEMBRO' THEN 'admissão' ELSE 'remoção' END, v_nome, nucleo.fn_aprovacao_falta(v_apv)
            USING COLUMN = 'mmb_vot_id';
    END IF;
    v_fap := nucleo.fn_fluxo_escolher(v_proc, NEW.mmb_igr_id, 0);
    IF v_fap IS NULL THEN
        RETURN NEW;                                        -- igreja sem fluxo: só a regra do voto (V4)
    END IF;
    RAISE EXCEPTION 'A % de % segue o fluxo «%» (%): o voto indicado não é de um processo aprovado. Registe os votos pela ordem do fluxo.',
        CASE v_proc WHEN 'ADMISSAO_MEMBRO' THEN 'admissão' ELSE 'remoção' END, v_nome,
        (SELECT fap_nome FROM nucleo.fluxo_aprovacao WHERE fap_id = v_fap),
        (SELECT string_agg(e.fae_ordem || '. ' || e.fae_nome, ', ' ORDER BY e.fae_ordem) FROM nucleo.fluxo_etapa e
          WHERE e.fae_fap_id = v_fap AND e.fae_end_date IS NULL)
        USING COLUMN = 'mmb_vot_id';
END $$;
CREATE TRIGGER trg_mmb_12_fluxo BEFORE INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_fluxo();

-- ================================================================ etapas: a igreja copia-se do fluxo
CREATE FUNCTION nucleo.fn_fae_igreja() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    SELECT fap_igr_id INTO NEW.fae_igr_id FROM nucleo.fluxo_aprovacao WHERE fap_id = NEW.fae_fap_id;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_fae_05_igreja BEFORE INSERT OR UPDATE OF fae_fap_id ON nucleo.fluxo_etapa
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_fae_igreja();

-- o fluxo não muda de igreja nem de processo depois de criado (as etapas e os processos dependem disso)
CREATE FUNCTION nucleo.fn_fap_fixo() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.fap_igr_id IS DISTINCT FROM OLD.fap_igr_id OR NEW.fap_processo IS DISTINCT FROM OLD.fap_processo THEN
        RAISE EXCEPTION 'A igreja e o processo de um fluxo não mudam: termine este fluxo e crie outro';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_fap_05_fixo BEFORE UPDATE OF fap_igr_id, fap_processo ON nucleo.fluxo_aprovacao
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_fap_fixo();

-- ================================================================ vistas: o que está por aprovar e em que etapa
CREATE VIEW nucleo.vw_aprovacoes WITH (security_invoker = true) AS
SELECT a.apv_id AS id, a.apv_igr_id AS igreja_id, i.igr_nome AS igreja, a.apv_processo AS processo, a.apv_assunto AS assunto,
       a.apv_valor AS valor, a.apv_estado AS estado, f.fap_id AS fluxo_id, f.fap_nome AS fluxo,
       (SELECT count(*) FROM nucleo.fluxo_etapa x WHERE x.fae_fap_id = a.apv_fap_id AND x.fae_end_date IS NULL
           AND x.fae_ordem <= COALESCE(e.fae_ordem, a.apv_etapa))::INT AS etapa,
       (SELECT count(*) FROM nucleo.fluxo_etapa x WHERE x.fae_fap_id = a.apv_fap_id AND x.fae_end_date IS NULL)::INT AS total_etapas,
       e.fae_id AS etapa_id, e.fae_nome AS etapa_nome, e.fae_accao AS etapa_accao, e.fae_responsavel AS responsavel_tipo,
       e.fae_orgao AS orgao, nucleo.fn_etapa_quem(e.fae_id) AS responsavel,
       CASE WHEN a.apv_estado = 'EM_CURSO' AND e.fae_responsavel <> 'ORGAO' THEN nucleo.fn_etapa_responsaveis(e.fae_id, a.apv_igr_id) END AS responsaveis,
       (a.apv_estado = 'EM_CURSO' AND nucleo.fn_aprovacao_pode_decidir(a.apv_id)) AS pode_decidir,
       a.apv_des_id AS despesa_id, a.apv_tra_id AS transacao_id, a.apv_cnu_id AS contagem_id, a.apv_orc_id AS orcamento_id,
       a.apv_mem_id AS membro_id,
       nucleo.fn_nome_usuario(a.apv_pedido_por_usu_id) AS pedido_por,
       a.apv_criado_em AS criado_em, a.apv_concluido_em AS concluido_em
  FROM nucleo.aprovacao a
  JOIN organizacao.igreja i ON i.igr_id = a.apv_igr_id
  JOIN nucleo.fluxo_aprovacao f ON f.fap_id = a.apv_fap_id
  LEFT JOIN LATERAL (SELECT x.* FROM nucleo.fluxo_etapa x
                      WHERE x.fae_fap_id = a.apv_fap_id
                        AND ((a.apv_estado = 'EM_CURSO' AND x.fae_end_date IS NULL AND x.fae_ordem >= a.apv_etapa)
                             OR (a.apv_estado <> 'EM_CURSO' AND x.fae_ordem = a.apv_etapa))
                      ORDER BY x.fae_ordem LIMIT 1) e ON TRUE
 WHERE a.apv_end_date IS NULL;
COMMENT ON VIEW nucleo.vw_aprovacoes IS 'Processos de aprovação: estado, etapa em curso, quem decide (e os nomes) e se o utilizador da sessão pode decidir (V54)';

-- as etapas de cada processo: decididas (quem, quando, com que voto), a em curso e as pendentes
CREATE VIEW nucleo.vw_aprovacao_etapas WITH (security_invoker = true) AS
SELECT a.apv_id AS aprovacao_id, e.fae_id AS etapa_id, e.fae_ordem AS ordem, e.fae_nome AS nome, e.fae_accao AS accao,
       e.fae_responsavel AS responsavel_tipo, e.fae_orgao AS orgao, nucleo.fn_etapa_quem(e.fae_id) AS responsavel,
       CASE WHEN d.apd_id IS NOT NULL THEN CASE WHEN d.apd_aprovado THEN 'APROVADA' ELSE 'REJEITADA' END
            WHEN a.apv_estado = 'EM_CURSO' AND e.fae_ordem = (SELECT min(y.fae_ordem) FROM nucleo.fluxo_etapa y
                                                               WHERE y.fae_fap_id = a.apv_fap_id AND y.fae_end_date IS NULL AND y.fae_ordem >= a.apv_etapa)
                 THEN 'EM_CURSO'
            WHEN a.apv_estado = 'EM_CURSO' THEN 'PENDENTE'
            ELSE 'NAO_DECIDIDA' END AS situacao,
       CASE WHEN d.apd_id IS NULL AND a.apv_estado = 'EM_CURSO' AND e.fae_responsavel <> 'ORGAO'
            THEN nucleo.fn_etapa_responsaveis(e.fae_id, a.apv_igr_id) END AS responsaveis,
       nucleo.fn_nome_usuario(d.apd_usu_id) AS decidido_por,
       d.apd_criado_em AS decidido_em, v.vot_numero AS voto_numero, d.apd_vot_id AS voto_id, d.apd_motivo AS motivo,
       d.apd_valor AS valor_aprovado
  FROM nucleo.aprovacao a
  JOIN nucleo.fluxo_etapa e ON e.fae_fap_id = a.apv_fap_id
  LEFT JOIN nucleo.aprovacao_decisao d ON d.apd_apv_id = a.apv_id AND d.apd_fae_id = e.fae_id AND d.apd_end_date IS NULL
  LEFT JOIN secretaria.voto v ON v.vot_id = d.apd_vot_id
 WHERE a.apv_end_date IS NULL AND (e.fae_end_date IS NULL OR d.apd_id IS NOT NULL);
COMMENT ON VIEW nucleo.vw_aprovacao_etapas IS 'Etapas de cada processo de aprovação: decididas, em curso e pendentes (V54)';

GRANT SELECT ON nucleo.vw_aprovacoes, nucleo.vw_aprovacao_etapas TO app_igreja;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nucleo, secretaria, tesouraria TO app_igreja;

-- ================================================================ fluxos por defeito (modelos da Associação/Missão)
-- Cada igreja pode ter os seus (ecrã Fluxos de aprovação): com um fluxo próprio para um processo, os modelos deixam de
-- se aplicar a esse processo nessa igreja. Valores em meticais; ajustáveis.
DO $$
DECLARE f INT;
    p_tes INT := (SELECT per_id FROM nucleo.perfil WHERE per_codigo = 'TESOUREIRO');
    m_des INT := (SELECT prm_id FROM nucleo.permissao WHERE prm_codigo = 'tesouraria.despesa.aprovar');
    m_tra INT := (SELECT prm_id FROM nucleo.permissao WHERE prm_codigo = 'tesouraria.transacao.aprovar');
BEGIN
    -- despesas: o tesoureiro aprecia (fundo e orçamento); decide quem aprova despesas, o Conselho ou a Igreja, pelo valor
    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('DESPESA', 'Despesa corrente', 0, 'Até 10 000 MT: o tesoureiro aprecia e o pastor ou um ancião aprova') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id, fae_prm_id, fae_outra_pessoa) VALUES
        (f, 1, 'Apreciação do tesoureiro', 'APRECIAR', 'PERFIL', p_tes, NULL, FALSE),
        (f, 2, 'Aprovação do pastor ou ancião', 'APROVAR', 'PERMISSAO', NULL, m_des, TRUE);

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('DESPESA', 'Despesa do Conselho', 10000, 'De 10 000 MT: o tesoureiro aprecia e o Conselho da Igreja vota') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id, fae_orgao, fae_outra_pessoa) VALUES
        (f, 1, 'Apreciação do tesoureiro', 'APRECIAR', 'PERFIL', p_tes, NULL, FALSE),
        (f, 2, 'Voto do Conselho da Igreja', 'VOTAR', 'ORGAO', NULL, 'JUNTA_DIRECTIVA', TRUE);

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('DESPESA', 'Despesa extraordinária', 100000, 'De 100 000 MT: o tesoureiro aprecia, o Conselho recomenda e a Igreja vota em reunião administrativa')
    RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id, fae_orgao, fae_outra_pessoa) VALUES
        (f, 1, 'Apreciação do tesoureiro', 'APRECIAR', 'PERFIL', p_tes, NULL, FALSE),
        (f, 2, 'Recomendação do Conselho da Igreja', 'RECOMENDAR', 'ORGAO', NULL, 'JUNTA_DIRECTIVA', TRUE),
        (f, 3, 'Voto da Igreja em reunião administrativa', 'VOTAR', 'ORGAO', NULL, 'ASSEMBLEIA_ADMINISTRATIVA', TRUE);

    -- saídas sem despesa aprovada (e estornos): outra pessoa aprova; a partir de 10 000 MT também o Conselho
    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('SAIDA', 'Saída de dinheiro', 0, 'O pastor ou um ancião aprova (nunca quem registou)') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_prm_id, fae_outra_pessoa) VALUES
        (f, 1, 'Aprovação do pastor ou ancião', 'APROVAR', 'PERMISSAO', m_tra, TRUE);

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('SAIDA', 'Saída do Conselho', 10000, 'De 10 000 MT: o pastor ou um ancião aprecia e o Conselho da Igreja vota') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_prm_id, fae_orgao, fae_outra_pessoa) VALUES
        (f, 1, 'Apreciação do pastor ou ancião', 'APRECIAR', 'PERMISSAO', m_tra, NULL, TRUE),
        (f, 2, 'Voto do Conselho da Igreja', 'VOTAR', 'ORGAO', NULL, 'JUNTA_DIRECTIVA', TRUE);

    -- contagem: o tesoureiro confere (contou com o diácono e o representante da Escola Sabatina)
    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('CONTAGEM', 'Conferência da contagem', 0, 'O tesoureiro confere o lançado com o contado') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id, fae_outra_pessoa) VALUES
        (f, 1, 'Conferência do tesoureiro', 'CONFERIR', 'PERFIL', p_tes, FALSE);

    -- orçamento: o Conselho recomenda, a Igreja aprova em reunião administrativa
    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('ORCAMENTO', 'Orçamento anual', 0, 'O Conselho da Igreja recomenda e a Igreja aprova em reunião administrativa') RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_orgao) VALUES
        (f, 1, 'Recomendação do Conselho da Igreja', 'RECOMENDAR', 'ORGAO', 'JUNTA_DIRECTIVA'),
        (f, 2, 'Aprovação da Igreja em reunião administrativa', 'VOTAR', 'ORGAO', 'ASSEMBLEIA_ADMINISTRATIVA');

    -- membros: o Conselho da Igreja aprecia e vota; depois a Igreja vota em reunião administrativa
    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('ADMISSAO_MEMBRO', 'Admissão de membro', 0, 'Baptismo, rebaptismo e profissão de fé: o Conselho da Igreja vota e depois a Igreja, em reunião administrativa')
    RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_orgao) VALUES
        (f, 1, 'Voto do Conselho da Igreja', 'RECOMENDAR', 'ORGAO', 'JUNTA_DIRECTIVA'),
        (f, 2, 'Voto da Igreja em reunião administrativa', 'VOTAR', 'ORGAO', 'ASSEMBLEIA_ADMINISTRATIVA');

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('REMOCAO_MEMBRO', 'Remoção de membro', 0, 'Remoção a pedido, por disciplina ou por desaparecimento: o Conselho recomenda e a Igreja vota em reunião administrativa')
    RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_orgao) VALUES
        (f, 1, 'Recomendação do Conselho da Igreja', 'RECOMENDAR', 'ORGAO', 'JUNTA_DIRECTIVA'),
        (f, 2, 'Voto da Igreja em reunião administrativa', 'VOTAR', 'ORGAO', 'ASSEMBLEIA_ADMINISTRATIVA');
END $$;

-- os processos que já estavam à espera quando esta migração correu entram no fluxo (despesas submetidas, saídas pendentes,
-- contagens abertas e orçamentos em rascunho)
SELECT nucleo.fn_aprovacao_iniciar('DESPESA', des_igr_id, 'Despesa: ' || des_descricao, des_valor_solicitado, des_solicitado_por_usu_id, p_des => des_id)
  FROM tesouraria.despesa WHERE des_estado = 'SUBMETIDA' AND des_end_date IS NULL;
SELECT nucleo.fn_aprovacao_iniciar('SAIDA', tra_igr_id, 'Saída: ' || COALESCE(NULLIF(tra_descricao, ''), tra_beneficiario, 'sem descrição'),
                                   tra_valor_total, tra_criado_por, p_tra => tra_id)
  FROM tesouraria.transacao
 WHERE tra_tipo = 'SAIDA' AND tra_estado = 'PENDENTE' AND tra_des_id IS NULL AND tra_aprovado_por_usu_id IS NULL AND tra_end_date IS NULL;
SELECT nucleo.fn_aprovacao_iniciar('CONTAGEM', cnu_igr_id, 'Contagem de ' || to_char(cnu_data, 'DD/MM/YYYY'), cnu_total_contado, cnu_criado_por, p_cnu => cnu_id)
  FROM tesouraria.contagem_numerario WHERE cnu_estado::TEXT = 'ABERTA' AND cnu_end_date IS NULL;
SELECT nucleo.fn_aprovacao_iniciar('ORCAMENTO', orc_igr_id, 'Orçamento de ' || orc_ano, NULL, orc_criado_por, p_orc => orc_id)
  FROM tesouraria.orcamento WHERE orc_estado = 'RASCUNHO' AND orc_end_date IS NULL;

-- >>>>> V55__processos_estorno_e_maneio.sql
-- =====================================================================
-- V55 · Processos de aprovação novos: ESTORNO e MANEIO (só os valores do enum)
--
-- Um valor novo de enum não se pode usar na mesma transacção em que é criado; as regras que os usam estão na V56.
-- =====================================================================
ALTER TYPE nucleo.processo_aprovacao_t ADD VALUE IF NOT EXISTS 'ESTORNO';
ALTER TYPE nucleo.processo_aprovacao_t ADD VALUE IF NOT EXISTS 'MANEIO';

-- >>>>> V56__despesas_pelo_conselho_e_fundo_de_maneio.sql
-- =====================================================================
-- V56 · Todo o dinheiro que sai passa pelo Conselho e pela Igreja; fundo de maneio reposto todos os meses
--
--   despesas e saídas   qualquer valor: 1. o tesoureiro aprecia, 2. o Conselho da Igreja vota, 3. a Igreja vota em
--                       reunião administrativa. O pastor e o ancião deixam de aprovar (os modelos de V54 terminam; os
--                       processos em curso recomeçam no fluxo novo).
--   estornos            processo próprio (ESTORNO): corrigem uma entrada errada; o pastor ou um ancião confirma.
--   fundo de maneio     conta_financeira.cfi_valor_maneio = o valor definido pela igreja. reposicao_maneio (rpm): cada
--                       mês pede-se a reposição do que foi gasto (valor definido menos o saldo); se não foi usado, não
--                       há reposição; se as despesas passaram o valor, repõe-se o gasto. O Conselho vota (processo
--                       MANEIO); depois tesouraria.fn_repor_maneio faz a transferência. Só entra dinheiro no fundo de
--                       maneio por uma reposição aprovada; as saídas do fundo de maneio não precisam de outra aprovação.
--
-- Tabela gerada com database/gerador (defs.py); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- reposição do fundo de maneio (gerada: gen.py)
-- Reposição mensal do fundo de maneio: repõe-se só o gasto (o valor definido menos o saldo), aprovada pelo Conselho da Igreja; depois de aprovada, uma transferência repõe o dinheiro (V56)
CREATE TABLE tesouraria.reposicao_maneio (
    rpm_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rpm_igr_id INT NOT NULL,
    rpm_cfi_id INT NOT NULL,
    rpm_ano SMALLINT NOT NULL,
    rpm_mes SMALLINT NOT NULL,
    rpm_valor_fundo DECIMAL(14,2),
    rpm_saldo DECIMAL(14,2),
    rpm_gasto DECIMAL(14,2),
    rpm_valor DECIMAL(14,2) NOT NULL,
    rpm_observacoes VARCHAR(255),
    rpm_tra_id BIGINT,
    rpm_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    rpm_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpm_criado_por INT,
    rpm_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    rpm_modificado_por INT,
    rpm_end_date TIMESTAMPTZ,
    CONSTRAINT fk_rpm_igr_id FOREIGN KEY (rpm_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT fk_rpm_cfi_id FOREIGN KEY (rpm_cfi_id) REFERENCES tesouraria.conta_financeira(cfi_id),
    CONSTRAINT chk_rpm_mes CHECK (rpm_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_rpm_valor CHECK (rpm_valor > 0),
    CONSTRAINT chk_rpm_end_date CHECK (rpm_end_date IS NULL OR rpm_end_date >= rpm_criado_em)
);
COMMENT ON TABLE tesouraria.reposicao_maneio IS 'Reposição mensal do fundo de maneio: repõe-se só o gasto (o valor definido menos o saldo), aprovada pelo Conselho da Igreja; depois de aprovada, uma transferência repõe o dinheiro (V56)';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_cfi_id IS 'A conta do fundo de maneio';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_valor_fundo IS 'O valor definido do fundo, quando se pediu (preenchido pela base de dados)';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_saldo IS 'Saldo do fundo quando se pediu (preenchido pela base de dados)';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_gasto IS 'O que se gastou: valor do fundo menos o saldo; é o máximo a repor (preenchido pela base de dados)';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_valor IS 'Valor a repor (até ao gasto)';
COMMENT ON COLUMN tesouraria.reposicao_maneio.rpm_tra_id IS 'Transferência que repôs o dinheiro (tesouraria.fn_repor_maneio)';
CREATE INDEX idx_rpm_igr_pagina ON tesouraria.reposicao_maneio (rpm_igr_id, rpm_id);
CREATE INDEX idx_rpm_cfi_id ON tesouraria.reposicao_maneio (rpm_cfi_id);
CREATE INDEX idx_rpm_tra_id ON tesouraria.reposicao_maneio (rpm_tra_id);

CREATE TRIGGER trg_rpm_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.reposicao_maneio FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rpm', 'tesouraria.reposicao_maneio', 'rpm_igr_id');
CREATE TRIGGER trg_rpm_00_sem_delete BEFORE DELETE ON tesouraria.reposicao_maneio FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rpm');
CREATE TRIGGER trg_rpm_00_sem_truncate BEFORE TRUNCATE ON tesouraria.reposicao_maneio FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rpm');
CREATE TRIGGER trg_rpm_99_log AFTER UPDATE ON tesouraria.reposicao_maneio FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rpm');
ALTER TABLE tesouraria.reposicao_maneio ADD CONSTRAINT fk_rpm_criado_por FOREIGN KEY (rpm_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.reposicao_maneio ADD CONSTRAINT fk_rpm_modificado_por FOREIGN KEY (rpm_modificado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.reposicao_maneio ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_rpm_ler ON tesouraria.reposicao_maneio FOR SELECT USING (rpm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.reposicao_maneio.ler'))::INT[]));
CREATE POLICY pol_rpm_criar ON tesouraria.reposicao_maneio FOR INSERT WITH CHECK (rpm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.reposicao_maneio.criar'))::INT[]));
CREATE POLICY pol_rpm_alterar ON tesouraria.reposicao_maneio FOR UPDATE USING (rpm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.reposicao_maneio.alterar'))::INT[])) WITH CHECK (rpm_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.reposicao_maneio.alterar'))::INT[]));

-- chaves estrangeiras e permissões da tabela nova
ALTER TABLE tesouraria.reposicao_maneio ADD CONSTRAINT fk_rpm_tra_id FOREIGN KEY (rpm_tra_id) REFERENCES tesouraria.transacao(tra_id);
GRANT SELECT, INSERT, UPDATE ON tesouraria.reposicao_maneio TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA tesouraria TO app_igreja;
COMMENT ON CONSTRAINT chk_rpm_mes ON tesouraria.reposicao_maneio IS '[mes] O mês vai de 1 a 12.';
COMMENT ON CONSTRAINT chk_rpm_valor ON tesouraria.reposicao_maneio IS '[valor] O valor a repor tem de ser maior que zero.';

INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'tesouraria.reposicao_maneio.' || a.accao, a.rotulo || 'Reposição mensal do fundo de maneio (V56)'
  FROM (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
-- quem tem cada permissão das contas tem a mesma da reposição (tesoureiro pede; os outros lêem)
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'tesouraria.conta\_financeira.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo = replace(antigo.prm_codigo, '.conta_financeira.', '.reposicao_maneio.')
 WHERE pp.ppe_end_date IS NULL;

-- ---------------------------------------------------------------- o valor do fundo de maneio (definido pela igreja)
ALTER TABLE tesouraria.conta_financeira ADD COLUMN cfi_valor_maneio DECIMAL(14,2);
COMMENT ON COLUMN tesouraria.conta_financeira.cfi_valor_maneio IS 'Fundo de maneio: o valor definido pela igreja; cada mês repõe-se só o que foi gasto (V56)';
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT chk_cfi_valor_maneio
    CHECK (cfi_valor_maneio IS NULL OR (cfi_valor_maneio > 0 AND cfi_tipo::TEXT = 'FUNDO_MANEIO'));
COMMENT ON CONSTRAINT chk_cfi_valor_maneio ON tesouraria.conta_financeira IS '[valorManeio] O valor do fundo de maneio é maior que zero e só existe numa conta do tipo fundo de maneio.';

-- ---------------------------------------------------------------- processos: a reposição do maneio é um objecto
ALTER TABLE nucleo.aprovacao ADD COLUMN apv_rpm_id INT;
COMMENT ON COLUMN nucleo.aprovacao.apv_rpm_id IS 'Reposição mensal do fundo de maneio (V56)';
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT fk_apv_rpm_id FOREIGN KEY (apv_rpm_id) REFERENCES tesouraria.reposicao_maneio(rpm_id);
CREATE INDEX idx_apv_rpm_id ON nucleo.aprovacao (apv_rpm_id);
ALTER TABLE nucleo.aprovacao DROP CONSTRAINT chk_apv_objecto;
ALTER TABLE nucleo.aprovacao ADD CONSTRAINT chk_apv_objecto
    CHECK (num_nonnulls(apv_des_id, apv_tra_id, apv_cnu_id, apv_orc_id, apv_mem_id, apv_rpm_id) = 1);
COMMENT ON CONSTRAINT chk_apv_objecto ON nucleo.aprovacao IS 'Um processo de aprovação refere-se a um só objecto (despesa, saída, contagem, orçamento, membro ou reposição do maneio).';
DROP INDEX nucleo.uq_apv_em_curso;
CREATE UNIQUE INDEX uq_apv_em_curso ON nucleo.aprovacao (apv_processo, COALESCE(apv_des_id, 0), COALESCE(apv_tra_id, 0), COALESCE(apv_cnu_id, 0),
    COALESCE(apv_orc_id, 0), COALESCE(apv_mem_id, 0), COALESCE(apv_rpm_id, 0)) WHERE apv_estado = 'EM_CURSO' AND apv_end_date IS NULL;
COMMENT ON INDEX nucleo.uq_apv_em_curso IS 'Este objecto já tem um processo de aprovação em curso.';

DROP POLICY pol_apv_ler ON nucleo.aprovacao;
CREATE POLICY pol_apv_ler ON nucleo.aprovacao FOR SELECT USING (
    (apv_processo = 'DESPESA' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.despesa.ler'))::INT[]))
 OR (apv_processo IN ('SAIDA', 'ESTORNO', 'MANEIO') AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler'))::INT[]))
 OR (apv_processo = 'CONTAGEM' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.contagem_numerario.ler'))::INT[]))
 OR (apv_processo = 'ORCAMENTO' AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('tesouraria.orcamento.ler'))::INT[]))
 OR (apv_processo IN ('ADMISSAO_MEMBRO', 'REMOCAO_MEMBRO') AND apv_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.movimento_membro.ler'))::INT[])));

-- ---------------------------------------------------------------- motor (V54) com os processos novos
CREATE OR REPLACE FUNCTION nucleo.fn_aprovacao_permissao(p_processo nucleo.processo_aprovacao_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_processo
               WHEN 'DESPESA' THEN 'tesouraria.despesa.aprovar'
               WHEN 'SAIDA' THEN 'tesouraria.transacao.aprovar'
               WHEN 'ESTORNO' THEN 'tesouraria.transacao.aprovar'
               WHEN 'MANEIO' THEN 'tesouraria.transacao.aprovar'
               WHEN 'CONTAGEM' THEN 'tesouraria.contagem_numerario.alterar'
               WHEN 'ORCAMENTO' THEN 'tesouraria.orcamento.aprovar'
               ELSE 'secretaria.movimento_membro.criar' END;
$$;

-- o objecto de um processo; SAIDA também encontra os estornos (o mesmo objecto: uma transacção de saída)
CREATE OR REPLACE FUNCTION nucleo.fn_aprovacao_concluida_agora(p_processo nucleo.processo_aprovacao_t, p_id BIGINT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT EXISTS (SELECT 1 FROM nucleo.aprovacao a
                    WHERE (a.apv_processo = p_processo OR (p_processo = 'SAIDA' AND a.apv_processo = 'ESTORNO'))
                      AND a.apv_estado IN ('APROVADO', 'REJEITADO') AND a.apv_concluido_em = now() AND a.apv_end_date IS NULL
                      AND p_id = CASE a.apv_processo WHEN 'DESPESA' THEN a.apv_des_id WHEN 'SAIDA' THEN a.apv_tra_id WHEN 'ESTORNO' THEN a.apv_tra_id
                                                     WHEN 'CONTAGEM' THEN a.apv_cnu_id WHEN 'ORCAMENTO' THEN a.apv_orc_id
                                                     WHEN 'MANEIO' THEN a.apv_rpm_id ELSE a.apv_mem_id END);
$$;

CREATE OR REPLACE FUNCTION nucleo.fn_aprovacao_em_curso(p_processo nucleo.processo_aprovacao_t, p_id BIGINT) RETURNS INT
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT a.apv_id FROM nucleo.aprovacao a
     WHERE (a.apv_processo = p_processo OR (p_processo = 'SAIDA' AND a.apv_processo = 'ESTORNO'))
       AND a.apv_estado = 'EM_CURSO' AND a.apv_end_date IS NULL
       AND p_id = CASE a.apv_processo WHEN 'DESPESA' THEN a.apv_des_id WHEN 'SAIDA' THEN a.apv_tra_id WHEN 'ESTORNO' THEN a.apv_tra_id
                                      WHEN 'CONTAGEM' THEN a.apv_cnu_id WHEN 'ORCAMENTO' THEN a.apv_orc_id
                                      WHEN 'MANEIO' THEN a.apv_rpm_id ELSE a.apv_mem_id END;
$$;

-- igual à de V54, com a reposição do maneio (p_rpm); a assinatura muda, por isso sai a antiga
DROP FUNCTION nucleo.fn_aprovacao_iniciar(nucleo.processo_aprovacao_t, INT, TEXT, NUMERIC, INT, INT, BIGINT, INT, INT, INT);
CREATE FUNCTION nucleo.fn_aprovacao_iniciar(p_processo nucleo.processo_aprovacao_t, p_igr INT, p_assunto TEXT, p_valor NUMERIC,
                                            p_pedido INT, p_des INT DEFAULT NULL, p_tra BIGINT DEFAULT NULL, p_cnu INT DEFAULT NULL,
                                            p_orc INT DEFAULT NULL, p_mem INT DEFAULT NULL, p_rpm INT DEFAULT NULL) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_fap INT; v_etapa SMALLINT; v_id INT;
BEGIN
    v_fap := nucleo.fn_fluxo_escolher(p_processo, p_igr, p_valor);
    IF v_fap IS NULL THEN
        RETURN NULL;                                       -- sem fluxo: ficam as regras de antes (uma aprovação)
    END IF;
    SELECT min(fae_ordem) INTO v_etapa FROM nucleo.fluxo_etapa WHERE fae_fap_id = v_fap AND fae_end_date IS NULL;
    INSERT INTO nucleo.aprovacao (apv_igr_id, apv_fap_id, apv_processo, apv_assunto, apv_valor, apv_pedido_por_usu_id, apv_etapa,
                                  apv_des_id, apv_tra_id, apv_cnu_id, apv_orc_id, apv_mem_id, apv_rpm_id)
    VALUES (p_igr, v_fap, p_processo, left(COALESCE(NULLIF(trim(p_assunto), ''), p_processo::TEXT), 255), p_valor, p_pedido, v_etapa,
            p_des, p_tra, p_cnu, p_orc, p_mem, p_rpm)
    RETURNING apv_id INTO v_id;
    RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION nucleo.fn_aprovacao_aplicar(p_apv INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE a nucleo.aprovacao%ROWTYPE; d nucleo.aprovacao_decisao%ROWTYPE; v_vot INT;
BEGIN
    SELECT * INTO a FROM nucleo.aprovacao WHERE apv_id = p_apv;
    SELECT * INTO d FROM nucleo.aprovacao_decisao WHERE apd_apv_id = p_apv AND apd_end_date IS NULL ORDER BY apd_etapa DESC LIMIT 1;
    SELECT apd_vot_id INTO v_vot FROM nucleo.aprovacao_decisao
     WHERE apd_apv_id = p_apv AND apd_end_date IS NULL AND apd_vot_id IS NOT NULL ORDER BY apd_etapa DESC LIMIT 1;
    IF a.apv_processo = 'DESPESA' THEN
        UPDATE tesouraria.despesa
           SET des_estado = CASE WHEN a.apv_estado = 'APROVADO' THEN 'APROVADA' ELSE 'REJEITADA' END::nucleo.estado_despesa_t,
               des_valor_aprovado = CASE WHEN a.apv_estado = 'APROVADO' THEN COALESCE(a.apv_valor, des_valor_solicitado) END,
               des_motivo_rejeicao = CASE WHEN a.apv_estado = 'REJEITADO'
                                          THEN COALESCE(d.apd_motivo, 'Rejeitada na etapa ' || d.apd_etapa || ' do fluxo de aprovação') END,
               des_vot_id = COALESCE(v_vot, des_vot_id)
         WHERE des_id = a.apv_des_id AND des_estado = 'SUBMETIDA';
    ELSIF a.apv_processo IN ('SAIDA', 'ESTORNO') AND a.apv_estado = 'APROVADO' THEN
        UPDATE tesouraria.transacao SET tra_aprovado_por_usu_id = nucleo.fn_usuario_sessao()
         WHERE tra_id = a.apv_tra_id AND tra_estado = 'PENDENTE';
    ELSIF a.apv_processo = 'CONTAGEM' THEN
        IF a.apv_estado = 'APROVADO' THEN
            UPDATE tesouraria.contagem_numerario SET cnu_estado = 'CONFERIDA', cnu_conferido_por_usu_id = nucleo.fn_usuario_sessao()
             WHERE cnu_id = a.apv_cnu_id AND cnu_estado = 'ABERTA';
        ELSE
            PERFORM nucleo.fn_aprovacao_iniciar('CONTAGEM', a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_cnu => a.apv_cnu_id);
        END IF;
    ELSIF a.apv_processo = 'ORCAMENTO' THEN
        IF a.apv_estado = 'APROVADO' THEN
            UPDATE tesouraria.orcamento SET orc_estado = 'APROVADO', orc_vot_id = COALESCE(v_vot, orc_vot_id)
             WHERE orc_id = a.apv_orc_id AND orc_estado = 'RASCUNHO';
        ELSE
            PERFORM nucleo.fn_aprovacao_iniciar('ORCAMENTO', a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_orc => a.apv_orc_id);
        END IF;
    END IF;
    -- MANEIO: aprovada, repõe-se com tesouraria.fn_repor_maneio; rejeitada, pode pedir-se outra (tesouraria.fn_rpm_validar)
    -- admissão e remoção: o livro de membros verifica o processo aprovado (secretaria.fn_mmb_fluxo)
END $$;

CREATE OR REPLACE FUNCTION nucleo.fn_aprovacao_decidir(p_apv INT, p_aprovar BOOLEAN, p_vot INT DEFAULT NULL, p_motivo TEXT DEFAULT NULL,
                                                       p_valor NUMERIC DEFAULT NULL) RETURNS nucleo.estado_aprovacao_t
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    -- quem não vê o processo recebe "não existe" (404), como na RLS
    IF NOT EXISTS (SELECT 1 FROM nucleo.aprovacao a WHERE a.apv_id = p_apv AND a.apv_end_date IS NULL
                      AND a.apv_igr_id = ANY (nucleo.fn_igrejas_com_permissao(
                          CASE a.apv_processo WHEN 'DESPESA' THEN 'tesouraria.despesa.ler'
                                              WHEN 'SAIDA' THEN 'tesouraria.transacao.ler' WHEN 'ESTORNO' THEN 'tesouraria.transacao.ler'
                                              WHEN 'MANEIO' THEN 'tesouraria.transacao.ler'
                                              WHEN 'CONTAGEM' THEN 'tesouraria.contagem_numerario.ler' WHEN 'ORCAMENTO' THEN 'tesouraria.orcamento.ler'
                                              ELSE 'secretaria.movimento_membro.ler' END))) THEN
        RAISE EXCEPTION 'O processo de aprovação não existe' USING ERRCODE = 'P0002';
    END IF;
    RETURN nucleo.fn_aprovacao_registar(p_apv, p_aprovar, p_vot, p_motivo, p_valor, TRUE);
END $$;

-- ---------------------------------------------------------------- saídas: estornos à parte; as do fundo de maneio já estão aprovadas
-- Uma saída do fundo de maneio paga uma despesa urgente com o dinheiro que o Conselho aprovou na reposição: não precisa
-- de outra aprovação. Um estorno corrige uma entrada errada (não gasta dinheiro da igreja): segue o processo ESTORNO.
CREATE OR REPLACE FUNCTION tesouraria.fn_tra_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tesouraria.conta_financeira WHERE cfi_id = NEW.tra_cfi_id AND cfi_tipo::TEXT = 'FUNDO_MANEIO') THEN
        RETURN NULL;
    END IF;
    PERFORM nucleo.fn_aprovacao_iniciar(
        CASE WHEN NEW.tra_estorno_tra_id IS NOT NULL THEN 'ESTORNO' ELSE 'SAIDA' END::nucleo.processo_aprovacao_t, NEW.tra_igr_id,
        CASE WHEN NEW.tra_estorno_tra_id IS NOT NULL THEN 'Estorno: ' ELSE 'Saída: ' END
            || COALESCE(NULLIF(NEW.tra_descricao, ''), NEW.tra_beneficiario, 'sem descrição'),
        NEW.tra_valor_total, nucleo.fn_usuario_sessao(), p_tra => NEW.tra_id);
    RETURN NULL;
END $$;

-- fn_tra_soma_linhas (V7) pede aprovação a toda a saída confirmada sem despesa; as do fundo de maneio ficam de fora.
DO $$
DECLARE v_def TEXT := pg_get_functiondef('tesouraria.fn_tra_soma_linhas()'::regprocedure);
        v_de TEXT := 'r.tra_des_id IS NULL AND r.tra_aprovado_por_usu_id IS NULL';
BEGIN
    IF position(v_de IN v_def) = 0 THEN
        RAISE EXCEPTION 'V56: tesouraria.fn_tra_soma_linhas mudou; rever a excepção do fundo de maneio';
    END IF;
    EXECUTE replace(v_def, v_de, v_de || ' AND NOT EXISTS (SELECT 1 FROM tesouraria.conta_financeira cm'
        || ' WHERE cm.cfi_id = r.tra_cfi_id AND cm.cfi_tipo::TEXT = ''FUNDO_MANEIO'')');
END $$;

-- ---------------------------------------------------------------- reposição mensal do fundo de maneio
-- Repõe-se só o que foi gasto: o valor definido menos o saldo. Se o fundo não foi usado, não há reposição; se as despesas
-- passaram o valor do fundo (saldo negativo), repõe-se o gasto, mais do que o valor definido. Uma reposição de cada vez.
CREATE FUNCTION tesouraria.fn_rpm_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE c tesouraria.conta_financeira%ROWTYPE; v_saldo NUMERIC;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF (NEW.rpm_cfi_id, NEW.rpm_ano, NEW.rpm_mes, NEW.rpm_valor, NEW.rpm_igr_id) IS DISTINCT FROM
           (OLD.rpm_cfi_id, OLD.rpm_ano, OLD.rpm_mes, OLD.rpm_valor, OLD.rpm_igr_id)
           OR (NEW.rpm_valor_fundo, NEW.rpm_saldo, NEW.rpm_gasto) IS DISTINCT FROM (OLD.rpm_valor_fundo, OLD.rpm_saldo, OLD.rpm_gasto) THEN
            RAISE EXCEPTION 'A reposição pedida não muda: termine-a e peça outra';
        END IF;
        IF NEW.rpm_tra_id IS DISTINCT FROM OLD.rpm_tra_id THEN
            IF OLD.rpm_tra_id IS NOT NULL THEN
                RAISE EXCEPTION 'Esta reposição já foi feita (transacção %)', OLD.rpm_tra_id;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM nucleo.aprovacao WHERE apv_rpm_id = NEW.rpm_id AND apv_estado = 'APROVADO' AND apv_end_date IS NULL) THEN
                RAISE EXCEPTION 'A reposição ainda não foi aprovada pelo Conselho da Igreja';
            END IF;
            IF NOT EXISTS (SELECT 1 FROM tesouraria.transacao WHERE tra_id = NEW.rpm_tra_id AND tra_tipo = 'TRANSFERENCIA'
                              AND tra_destino_cfi_id = NEW.rpm_cfi_id AND tra_valor_total = NEW.rpm_valor AND tra_end_date IS NULL) THEN
                RAISE EXCEPTION 'A reposição faz-se com uma transferência para o fundo de maneio do valor aprovado (%)', NEW.rpm_valor
                    USING COLUMN = 'rpm_tra_id';
            END IF;
        END IF;
        RETURN NEW;
    END IF;
    SELECT * INTO c FROM tesouraria.conta_financeira WHERE cfi_id = NEW.rpm_cfi_id AND cfi_end_date IS NULL;
    IF NOT FOUND OR c.cfi_tipo::TEXT <> 'FUNDO_MANEIO' THEN
        RAISE EXCEPTION 'A reposição é de uma conta do tipo fundo de maneio' USING COLUMN = 'rpm_cfi_id';
    END IF;
    NEW.rpm_igr_id := c.cfi_igr_id;
    IF c.cfi_valor_maneio IS NULL THEN
        RAISE EXCEPTION 'Defina primeiro o valor do fundo de maneio "%" (a igreja decide o valor)', c.cfi_nome USING COLUMN = 'rpm_cfi_id';
    END IF;
    IF EXISTS (SELECT 1 FROM tesouraria.reposicao_maneio r
                WHERE r.rpm_cfi_id = NEW.rpm_cfi_id AND r.rpm_end_date IS NULL AND r.rpm_tra_id IS NULL
                  AND NOT EXISTS (SELECT 1 FROM nucleo.aprovacao a WHERE a.apv_rpm_id = r.rpm_id AND a.apv_estado IN ('REJEITADO', 'CANCELADO'))) THEN
        RAISE EXCEPTION 'Já há uma reposição deste fundo pedida ou aprovada e ainda não feita: termine-a antes de pedir outra';
    END IF;
    IF EXISTS (SELECT 1 FROM tesouraria.reposicao_maneio r
                WHERE r.rpm_cfi_id = NEW.rpm_cfi_id AND r.rpm_ano = NEW.rpm_ano AND r.rpm_mes = NEW.rpm_mes AND r.rpm_end_date IS NULL
                  AND NOT EXISTS (SELECT 1 FROM nucleo.aprovacao a WHERE a.apv_rpm_id = r.rpm_id AND a.apv_estado IN ('REJEITADO', 'CANCELADO'))) THEN
        RAISE EXCEPTION 'O fundo de maneio já foi reposto em %/%: uma reposição por mês', lpad(NEW.rpm_mes::TEXT, 2, '0'), NEW.rpm_ano
            USING COLUMN = 'rpm_mes';
    END IF;
    SELECT saldo INTO v_saldo FROM tesouraria.vw_saldo_conta WHERE cfi_id = NEW.rpm_cfi_id;
    NEW.rpm_valor_fundo := c.cfi_valor_maneio;
    NEW.rpm_saldo := COALESCE(v_saldo, 0);
    NEW.rpm_gasto := c.cfi_valor_maneio - COALESCE(v_saldo, 0);
    IF NEW.rpm_gasto <= 0 THEN
        RAISE EXCEPTION 'O fundo de maneio não foi usado (saldo % de %): não há reposição a aprovar',
            nucleo.fn_texto_mt(NEW.rpm_saldo), nucleo.fn_texto_mt(c.cfi_valor_maneio) USING COLUMN = 'rpm_valor';
    END IF;
    IF NEW.rpm_valor > NEW.rpm_gasto THEN
        RAISE EXCEPTION 'Só se repõe o que foi gasto: até % (o fundo é de % e tem %)',
            nucleo.fn_texto_mt(NEW.rpm_gasto), nucleo.fn_texto_mt(c.cfi_valor_maneio), nucleo.fn_texto_mt(NEW.rpm_saldo) USING COLUMN = 'rpm_valor';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_rpm_05_validar BEFORE INSERT OR UPDATE ON tesouraria.reposicao_maneio
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_rpm_validar();

CREATE FUNCTION tesouraria.fn_rpm_fluxo_iniciar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    PERFORM nucleo.fn_aprovacao_iniciar('MANEIO', NEW.rpm_igr_id,
        'Reposição do fundo de maneio de ' || lpad(NEW.rpm_mes::TEXT, 2, '0') || '/' || NEW.rpm_ano, NEW.rpm_valor,
        nucleo.fn_usuario_sessao(), p_rpm => NEW.rpm_id);
    RETURN NULL;
END $$;
CREATE TRIGGER trg_rpm_50_fluxo_iniciar AFTER INSERT ON tesouraria.reposicao_maneio
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_rpm_fluxo_iniciar();

-- terminar uma reposição por fazer cancela o processo
CREATE FUNCTION tesouraria.fn_rpm_terminar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.rpm_tra_id IS NOT NULL THEN
        RAISE EXCEPTION 'Esta reposição já foi feita: para a corrigir, estorne a transferência';
    END IF;
    PERFORM nucleo.fn_aprovacao_cancelar('MANEIO', NEW.rpm_id);
    RETURN NEW;
END $$;
CREATE TRIGGER trg_rpm_09_terminar BEFORE UPDATE OF rpm_end_date ON tesouraria.reposicao_maneio
    FOR EACH ROW WHEN (OLD.rpm_end_date IS NULL AND NEW.rpm_end_date IS NOT NULL) EXECUTE FUNCTION tesouraria.fn_rpm_terminar();

-- Fazer a reposição aprovada: transferência confirmada da conta de origem para o fundo de maneio, pelo valor aprovado.
CREATE FUNCTION tesouraria.fn_repor_maneio(p_rpm INT, p_origem INT, p_data TIMESTAMPTZ DEFAULT now()) RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE r tesouraria.reposicao_maneio%ROWTYPE; o tesouraria.conta_financeira%ROWTYPE; v_tra BIGINT;
BEGIN
    SELECT * INTO r FROM tesouraria.reposicao_maneio WHERE rpm_id = p_rpm AND rpm_end_date IS NULL FOR UPDATE;
    IF NOT FOUND OR NOT (r.rpm_igr_id = ANY (nucleo.fn_igrejas_com_permissao('tesouraria.reposicao_maneio.ler'))) THEN
        RAISE EXCEPTION 'A reposição não existe' USING ERRCODE = 'P0002';
    END IF;
    PERFORM nucleo.fn_exigir('tesouraria.transacao.criar', r.rpm_igr_id);
    IF r.rpm_tra_id IS NOT NULL THEN
        RAISE EXCEPTION 'Esta reposição já foi feita (transacção %)', r.rpm_tra_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM nucleo.aprovacao WHERE apv_rpm_id = p_rpm AND apv_estado = 'APROVADO' AND apv_end_date IS NULL) THEN
        RAISE EXCEPTION 'A reposição ainda não foi aprovada: falta a %',
            COALESCE(nucleo.fn_aprovacao_falta(nucleo.fn_aprovacao_em_curso('MANEIO', p_rpm)), 'aprovação');
    END IF;
    SELECT * INTO o FROM tesouraria.conta_financeira WHERE cfi_id = p_origem AND cfi_end_date IS NULL;
    IF NOT FOUND OR o.cfi_igr_id <> r.rpm_igr_id OR o.cfi_ent_id IS NOT NULL OR o.cfi_tipo::TEXT = 'FUNDO_MANEIO' THEN
        RAISE EXCEPTION 'O dinheiro sai de uma conta da igreja (caixa, banco ou carteira móvel), não de outro fundo de maneio nem da conta da Missão'
            USING COLUMN = 'tra_cfi_id';
    END IF;
    INSERT INTO tesouraria.transacao (tra_igr_id, tra_tipo, tra_metodo, tra_estado, tra_valor_total, tra_cfi_id, tra_destino_cfi_id,
                                      tra_descricao, tra_data_hora)
    VALUES (r.rpm_igr_id, 'TRANSFERENCIA',
            CASE o.cfi_tipo::TEXT WHEN 'BANCO' THEN 'BANCO' WHEN 'MPESA' THEN 'MPESA' WHEN 'EMOLA' THEN 'EMOLA' ELSE 'NUMERARIO' END::nucleo.metodo_pagamento_t,
            'CONFIRMADA', r.rpm_valor, p_origem, r.rpm_cfi_id,
            'Reposição do fundo de maneio de ' || lpad(r.rpm_mes::TEXT, 2, '0') || '/' || r.rpm_ano, COALESCE(p_data, now()))
    RETURNING tra_id INTO v_tra;
    UPDATE tesouraria.reposicao_maneio SET rpm_tra_id = v_tra WHERE rpm_id = p_rpm;
    RETURN v_tra;
END $$;

-- Dinheiro só entra no fundo de maneio por uma reposição aprovada (verificado no COMMIT: a transferência e a ligação à
-- reposição gravam-se na mesma transacção).
CREATE FUNCTION tesouraria.fn_tra_maneio_reposto() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE r tesouraria.transacao%ROWTYPE;
BEGIN
    SELECT * INTO r FROM tesouraria.transacao WHERE tra_id = NEW.tra_id;
    IF r.tra_tipo = 'TRANSFERENCIA' AND r.tra_estado = 'CONFIRMADA' AND r.tra_end_date IS NULL
       AND EXISTS (SELECT 1 FROM tesouraria.conta_financeira WHERE cfi_id = r.tra_destino_cfi_id AND cfi_tipo::TEXT = 'FUNDO_MANEIO')
       AND NOT EXISTS (SELECT 1 FROM tesouraria.reposicao_maneio WHERE rpm_tra_id = r.tra_id) THEN
        RAISE EXCEPTION 'O fundo de maneio só se repõe com uma reposição aprovada pelo Conselho da Igreja (Contas → Fundo de maneio → Pedir reposição)';
    END IF;
    RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER trg_tra_91_maneio AFTER INSERT OR UPDATE OF tra_estado, tra_destino_cfi_id, tra_end_date ON tesouraria.transacao
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_tra_maneio_reposto();

-- ---------------------------------------------------------------- acompanhamento: a reposição do maneio (coluna nova no fim)
CREATE OR REPLACE VIEW nucleo.vw_aprovacoes WITH (security_invoker = true) AS
SELECT a.apv_id AS id, a.apv_igr_id AS igreja_id, i.igr_nome AS igreja, a.apv_processo AS processo, a.apv_assunto AS assunto,
       a.apv_valor AS valor, a.apv_estado AS estado, f.fap_id AS fluxo_id, f.fap_nome AS fluxo,
       (SELECT count(*) FROM nucleo.fluxo_etapa x WHERE x.fae_fap_id = a.apv_fap_id AND x.fae_end_date IS NULL
           AND x.fae_ordem <= COALESCE(e.fae_ordem, a.apv_etapa))::INT AS etapa,
       (SELECT count(*) FROM nucleo.fluxo_etapa x WHERE x.fae_fap_id = a.apv_fap_id AND x.fae_end_date IS NULL)::INT AS total_etapas,
       e.fae_id AS etapa_id, e.fae_nome AS etapa_nome, e.fae_accao AS etapa_accao, e.fae_responsavel AS responsavel_tipo,
       e.fae_orgao AS orgao, nucleo.fn_etapa_quem(e.fae_id) AS responsavel,
       CASE WHEN a.apv_estado = 'EM_CURSO' AND e.fae_responsavel <> 'ORGAO' THEN nucleo.fn_etapa_responsaveis(e.fae_id, a.apv_igr_id) END AS responsaveis,
       (a.apv_estado = 'EM_CURSO' AND nucleo.fn_aprovacao_pode_decidir(a.apv_id)) AS pode_decidir,
       a.apv_des_id AS despesa_id, a.apv_tra_id AS transacao_id, a.apv_cnu_id AS contagem_id, a.apv_orc_id AS orcamento_id,
       a.apv_mem_id AS membro_id,
       nucleo.fn_nome_usuario(a.apv_pedido_por_usu_id) AS pedido_por,
       a.apv_criado_em AS criado_em, a.apv_concluido_em AS concluido_em,
       a.apv_rpm_id AS reposicao_id
  FROM nucleo.aprovacao a
  JOIN organizacao.igreja i ON i.igr_id = a.apv_igr_id
  JOIN nucleo.fluxo_aprovacao f ON f.fap_id = a.apv_fap_id
  LEFT JOIN LATERAL (SELECT x.* FROM nucleo.fluxo_etapa x
                      WHERE x.fae_fap_id = a.apv_fap_id
                        AND ((a.apv_estado = 'EM_CURSO' AND x.fae_end_date IS NULL AND x.fae_ordem >= a.apv_etapa)
                             OR (a.apv_estado <> 'EM_CURSO' AND x.fae_ordem = a.apv_etapa))
                      ORDER BY x.fae_ordem LIMIT 1) e ON TRUE
 WHERE a.apv_end_date IS NULL;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA nucleo, tesouraria TO app_igreja;

-- ================================================================ fluxos novos (modelos da Associação/Missão)
-- Todo o dinheiro que sai dos fundos da igreja: o tesoureiro aprecia, o Conselho da Igreja vota e por fim a Igreja vota em
-- reunião administrativa, seja qual for o valor. O pastor e o ancião não aprovam despesas nem saídas.
-- Estorno (corrige uma entrada lançada por engano): o pastor ou um ancião confirma (outra pessoa).
-- Reposição mensal do fundo de maneio: o Conselho da Igreja vota.
UPDATE nucleo.fluxo_etapa SET fae_end_date = now()
 WHERE fae_end_date IS NULL AND fae_fap_id IN (SELECT fap_id FROM nucleo.fluxo_aprovacao
                                                WHERE fap_igr_id IS NULL AND fap_processo IN ('DESPESA', 'SAIDA') AND fap_end_date IS NULL);
UPDATE nucleo.fluxo_aprovacao SET fap_end_date = now()
 WHERE fap_igr_id IS NULL AND fap_processo IN ('DESPESA', 'SAIDA') AND fap_end_date IS NULL;

DO $$
DECLARE f INT; p TEXT;
    p_tes INT := (SELECT per_id FROM nucleo.perfil WHERE per_codigo = 'TESOUREIRO');
    m_tra INT := (SELECT prm_id FROM nucleo.permissao WHERE prm_codigo = 'tesouraria.transacao.aprovar');
BEGIN
    FOREACH p IN ARRAY ARRAY['DESPESA', 'SAIDA'] LOOP
        INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
        VALUES (p::nucleo.processo_aprovacao_t, CASE p WHEN 'DESPESA' THEN 'Despesa da igreja' ELSE 'Saída de dinheiro' END, 0,
                'Qualquer valor: o tesoureiro aprecia, o Conselho da Igreja vota e a Igreja vota em reunião administrativa')
        RETURNING fap_id INTO f;
        INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id, fae_orgao, fae_outra_pessoa) VALUES
            (f, 1, 'Apreciação do tesoureiro', 'APRECIAR', 'PERFIL', p_tes, NULL, FALSE),
            (f, 2, 'Voto do Conselho da Igreja', 'RECOMENDAR', 'ORGAO', NULL, 'JUNTA_DIRECTIVA', TRUE),
            (f, 3, 'Voto da Igreja em reunião administrativa', 'VOTAR', 'ORGAO', NULL, 'ASSEMBLEIA_ADMINISTRATIVA', TRUE);
    END LOOP;

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('ESTORNO', 'Estorno', 0, 'Corrige uma entrada lançada por engano: o pastor ou um ancião confirma (nunca quem registou)')
    RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_prm_id, fae_outra_pessoa) VALUES
        (f, 1, 'Confirmação do pastor ou ancião', 'APROVAR', 'PERMISSAO', m_tra, TRUE);

    INSERT INTO nucleo.fluxo_aprovacao (fap_processo, fap_nome, fap_valor_minimo, fap_descricao)
    VALUES ('MANEIO', 'Reposição do fundo de maneio', 0, 'Todos os meses repõe-se o que foi gasto; o Conselho da Igreja vota')
    RETURNING fap_id INTO f;
    INSERT INTO nucleo.fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_orgao) VALUES
        (f, 1, 'Voto do Conselho da Igreja', 'VOTAR', 'ORGAO', 'JUNTA_DIRECTIVA');
END $$;

-- Os processos de despesa e de saída que estavam em curso com os modelos antigos recomeçam no fluxo novo (os já decididos
-- ficam como estavam). As saídas do fundo de maneio deixam de precisar de aprovação.
DO $$
DECLARE a RECORD;
BEGIN
    FOR a IN SELECT x.* FROM nucleo.aprovacao x JOIN nucleo.fluxo_aprovacao f ON f.fap_id = x.apv_fap_id
              WHERE x.apv_estado = 'EM_CURSO' AND x.apv_end_date IS NULL AND x.apv_processo IN ('DESPESA', 'SAIDA')
                AND f.fap_igr_id IS NULL AND f.fap_end_date IS NOT NULL LOOP
        UPDATE nucleo.aprovacao SET apv_estado = 'CANCELADO', apv_concluido_em = now() WHERE apv_id = a.apv_id;
        IF a.apv_des_id IS NOT NULL THEN
            PERFORM nucleo.fn_aprovacao_iniciar('DESPESA', a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_des => a.apv_des_id);
        ELSIF NOT EXISTS (SELECT 1 FROM tesouraria.transacao t JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id
                           WHERE t.tra_id = a.apv_tra_id AND c.cfi_tipo::TEXT = 'FUNDO_MANEIO') THEN
            PERFORM nucleo.fn_aprovacao_iniciar(
                CASE WHEN (SELECT tra_estorno_tra_id FROM tesouraria.transacao WHERE tra_id = a.apv_tra_id) IS NOT NULL
                     THEN 'ESTORNO' ELSE 'SAIDA' END::nucleo.processo_aprovacao_t,
                a.apv_igr_id, a.apv_assunto, a.apv_valor, a.apv_pedido_por_usu_id, p_tra => a.apv_tra_id);
        END IF;
    END LOOP;
END $$;

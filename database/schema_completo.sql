-- =====================================================================
-- Sistema de Gestão da Igreja Adventista · esquema completo (script único)
-- GERADO por scripts/gerar-schema-completo.sh a partir de database/migrations
-- (V1__base.sql … V24__nome_dos_depositos_a_missao.sql). NÃO EDITAR À MÃO.
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

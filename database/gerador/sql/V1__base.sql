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

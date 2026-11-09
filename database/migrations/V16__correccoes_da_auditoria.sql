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

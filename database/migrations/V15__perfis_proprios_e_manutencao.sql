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

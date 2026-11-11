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

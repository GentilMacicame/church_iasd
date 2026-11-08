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

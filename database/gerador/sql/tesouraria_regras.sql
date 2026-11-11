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

-- ---------------------------------------------------------------- conta da Missão (V21)
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

-- Se uma conta é da Missão. SECURITY DEFINER: o membro sem perfil não lê as contas, mas vê nas suas contribuições
-- que pagou na Missão (só se revela isto, nada da conta).
CREATE FUNCTION tesouraria.fn_conta_da_missao(p_cfi INT) RETURNS BOOLEAN
SECURITY DEFINER SET search_path = tesouraria, pg_temp AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM tesouraria.conta_financeira WHERE cfi_id = p_cfi AND cfi_ent_id IS NOT NULL);
END $$ LANGUAGE plpgsql STABLE;
REVOKE ALL ON FUNCTION tesouraria.fn_conta_da_missao(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_conta_da_missao(INT) TO app_igreja;

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
CREATE INDEX idx_rem_igr_periodo ON tesouraria.remessa (rem_igr_id, rem_ent_id, rem_ano, rem_mes);
CREATE UNIQUE INDEX uq_rem_preparada ON tesouraria.remessa (rem_igr_id, rem_ent_id, rem_ano, rem_mes)
    WHERE rem_end_date IS NULL AND rem_estado = 'PREPARADA';

-- ---------------------------------------------------------------- 5. fundos da igreja e "outras despesas" (V23)
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

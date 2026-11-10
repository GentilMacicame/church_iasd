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

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

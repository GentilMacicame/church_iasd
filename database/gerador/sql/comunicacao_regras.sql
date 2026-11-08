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

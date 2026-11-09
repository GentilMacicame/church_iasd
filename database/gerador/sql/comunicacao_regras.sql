-- Regras de comunicação ---------------------------------------------------

-- Ao emitir um recibo, envia-o ao membro pelo contacto principal (se tiver consentimento)
CREATE FUNCTION nucleo.fn_rec_notificar() RETURNS trigger AS $$
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

    INSERT INTO nucleo.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                         ntf_origem_tabela, ntf_origem_id)
    VALUES (NEW.rec_igr_id, v_mem, v_canal, c.cto_valor, 'Recibo ' || NEW.rec_numero || '/' || NEW.rec_ano,
            'Recebemos a sua contribuição de ' || to_char(v_valor, 'FM999G999G990D00') || ' MT. Recibo n.º '
            || NEW.rec_numero || '/' || NEW.rec_ano || '. Deus o abençoe.',
            'tesouraria.recibo', NEW.rec_id);
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rec_10_notificar
    AFTER INSERT ON tesouraria.recibo
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_rec_notificar();

-- Envio da fila (V17) ------------------------------------------------------
-- A tarefa da API (sem utilizador) reserva até p_limite SMS por enviar. A reserva conta a tentativa e adia a
-- mensagem 10 minutos: se a API parar a meio, a mensagem volta à fila em vez de se perder ou sair duas vezes.
CREATE FUNCTION nucleo.fn_notificacoes_reservar(p_limite INT DEFAULT 50)
RETURNS TABLE (id BIGINT, destino VARCHAR, mensagem TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    UPDATE nucleo.notificacao n
       SET ntf_tentativas = n.ntf_tentativas + 1, ntf_agendada_para = now() + INTERVAL '10 minutes'
     WHERE n.ntf_id IN (SELECT x.ntf_id FROM nucleo.notificacao x
                        WHERE x.ntf_estado = 'PENDENTE' AND x.ntf_end_date IS NULL AND x.ntf_canal = 'SMS'
                          AND x.ntf_agendada_para <= now()
                        ORDER BY x.ntf_agendada_para LIMIT p_limite
                        FOR UPDATE SKIP LOCKED)
    RETURNING n.ntf_id, n.ntf_destino, n.ntf_mensagem;
END $$;

-- Resultado do envio: ENVIADA; ou o erro, e nova tentativa daqui a 15 minutos (à 5.ª tentativa fica FALHADA)
CREATE FUNCTION nucleo.fn_notificacao_resultado(p_id BIGINT, p_enviada BOOLEAN, p_erro TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE nucleo.notificacao
       SET ntf_estado = CASE WHEN p_enviada THEN 'ENVIADA' WHEN ntf_tentativas >= 5 THEN 'FALHADA' ELSE 'PENDENTE' END
                        ::nucleo.estado_notificacao_t,
           ntf_enviada_em = CASE WHEN p_enviada THEN now() END,
           ntf_erro = CASE WHEN p_enviada THEN NULL ELSE left(p_erro, 500) END,
           ntf_agendada_para = CASE WHEN p_enviada THEN ntf_agendada_para ELSE now() + INTERVAL '15 minutes' END
     WHERE ntf_id = p_id;
END $$;

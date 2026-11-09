-- Regras das escalas (V17) ------------------------------------------------

-- Nome de cada função para as mensagens (compara como texto: funciona na mesma transacção que acrescenta valores ao tipo)
CREATE FUNCTION actividades.fn_funcao_escala_nome(p_funcao nucleo.funcao_escala_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_funcao::text
        WHEN 'PREGADOR' THEN 'pregador(a)'
        WHEN 'ANCIAO_DO_DIA' THEN 'ancião do dia'
        WHEN 'DIACONO' THEN 'diácono'
        WHEN 'DIACONISA' THEN 'diaconisa'
        WHEN 'RECEPCAO' THEN 'recepção'
        WHEN 'MUSICA' THEN 'música'
        WHEN 'SONOPLASTIA' THEN 'sonoplastia'
        WHEN 'PROFESSOR_ES' THEN 'professor(a) da Escola Sabatina'
        WHEN 'DIRECTOR_ES' THEN 'director(a) da Escola Sabatina'
        WHEN 'LIMPEZA' THEN 'limpeza'
        WHEN 'TRADUTOR' THEN 'tradutor(a)'
        WHEN 'ACOMPANHANTE_VISITAS' THEN 'acompanhante (visitas e 2.ª oração)'
        WHEN 'ACOMPANHANTE_OFERTAS' THEN 'acompanhante (dízimos e ofertas)'
        WHEN 'ACOMPANHANTE_BOAS_VINDAS' THEN 'acompanhante (boas-vindas e 1.ª oração)'
        ELSE 'serviço' END;
$$;

-- Escala ligada a um dia do plano: a data e a igreja vêm do dia (não se escrevem duas vezes)
CREATE FUNCTION actividades.fn_esc_dia() RETURNS trigger AS $$
BEGIN
    IF NEW.esc_eds_id IS NOT NULL THEN
        SELECT d.eds_data, p.epl_igr_id INTO NEW.esc_data, NEW.esc_igr_id
        FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
        WHERE d.eds_id = NEW.esc_eds_id;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_esc_05_dia
    BEFORE INSERT OR UPDATE OF esc_eds_id, esc_data, esc_igr_id ON actividades.escala
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_esc_dia();

-- Dia da escala: dentro do período do plano
CREATE FUNCTION actividades.fn_eds_validar() RETURNS trigger AS $$
DECLARE p actividades.escala_plano%ROWTYPE;
BEGIN
    SELECT * INTO p FROM actividades.escala_plano WHERE epl_id = NEW.eds_epl_id;
    IF NEW.eds_data < p.epl_data_inicio OR NEW.eds_data > p.epl_data_fim THEN
        RAISE EXCEPTION 'O dia % está fora do período da escala (% a %)', to_char(NEW.eds_data, 'DD/MM/YYYY'),
            to_char(p.epl_data_inicio, 'DD/MM/YYYY'), to_char(p.epl_data_fim, 'DD/MM/YYYY');
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_eds_10_validar
    BEFORE INSERT OR UPDATE ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_validar();

-- Mudou a data do dia: as escalas desse dia acompanham
CREATE FUNCTION actividades.fn_eds_data() RETURNS trigger AS $$
BEGIN
    UPDATE actividades.escala SET esc_data = NEW.eds_data
     WHERE esc_eds_id = NEW.eds_id AND esc_end_date IS NULL AND esc_data IS DISTINCT FROM NEW.eds_data;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_eds_20_data
    AFTER UPDATE OF eds_data ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_data();

-- Elaborar a escala: cria um dia para cada sábado (ou outro dia da semana, 1 = segunda … 7 = domingo) do período
-- que ainda não tenha dia. Corre com as permissões de quem a chama (RLS de escala_dia). Devolve quantos criou.
CREATE FUNCTION actividades.fn_gerar_dias_escala(p_epl INT, p_dia_semana INT DEFAULT 6) RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE p actividades.escala_plano%ROWTYPE; n INT;
BEGIN
    IF p_dia_semana NOT BETWEEN 1 AND 7 THEN RAISE EXCEPTION 'Dia da semana inválido: % (1 = segunda … 7 = domingo)', p_dia_semana; END IF;
    SELECT * INTO p FROM actividades.escala_plano WHERE epl_id = p_epl AND epl_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Escala inexistente'; END IF;
    INSERT INTO actividades.escala_dia (eds_epl_id, eds_data)
    SELECT p_epl, d::date FROM generate_series(p.epl_data_inicio, p.epl_data_fim, INTERVAL '1 day') d
    WHERE EXTRACT(ISODOW FROM d) = p_dia_semana
      AND NOT EXISTS (SELECT 1 FROM actividades.escala_dia x
                      WHERE x.eds_epl_id = p_epl AND x.eds_data = d::date AND x.eds_end_date IS NULL);
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;

-- Lembretes por SMS a quem está escalado: à quarta e à sexta, para o sábado seguinte, às 18:00 (hora de Maputo).
-- Só escalas publicadas (ou escalas soltas, sem plano), dias sem evento especial, quem tem telefone e deu
-- consentimento para SMS. Quem substitui recebe no lugar do escalado. Corre de hora a hora (tarefa da API):
-- a chave da notificação impede repetições; depois das 20:00 já não cria (não se mandam SMS à noite).
-- Devolve quantas mensagens pôs na fila (nucleo.notificacao).
CREATE FUNCTION actividades.fn_lembretes_escala(p_agora TIMESTAMPTZ DEFAULT now()) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_local  TIMESTAMP := p_agora AT TIME ZONE 'Africa/Maputo';
    v_hoje   DATE := (p_agora AT TIME ZONE 'Africa/Maputo')::date;
    v_dia    INT := EXTRACT(ISODOW FROM (p_agora AT TIME ZONE 'Africa/Maputo'));
    v_sabado DATE;
    v_envio  TIMESTAMPTZ;
    n INT;
BEGIN
    IF v_dia NOT IN (3, 5) OR v_local::time >= TIME '20:00' THEN
        RETURN 0;
    END IF;
    v_sabado := v_hoje + (6 - v_dia);
    v_envio := GREATEST(p_agora, (v_hoje + TIME '18:00') AT TIME ZONE 'Africa/Maputo');
    INSERT INTO nucleo.notificacao (ntf_igr_id, ntf_mem_id, ntf_canal, ntf_destino, ntf_assunto, ntf_mensagem,
                                         ntf_agendada_para, ntf_origem_tabela, ntf_origem_id, ntf_chave)
    SELECT e.esc_igr_id, x.mem_id, 'SMS', x.telefone, 'Escala de ' || to_char(v_sabado, 'DD/MM'),
           left(i.igr_nome, 40) || ': lembrete - no sábado ' || to_char(v_sabado, 'DD/MM') || ' está escalado(a) como '
               || actividades.fn_funcao_escala_nome(e.esc_funcao) || '. Deus o(a) abençoe.',
           v_envio, 'actividades.escala', e.esc_id, 'escala:' || e.esc_id || ':' || v_hoje
    FROM actividades.escala e
    JOIN organizacao.igreja i ON i.igr_id = e.esc_igr_id
    LEFT JOIN actividades.escala_dia d ON d.eds_id = e.esc_eds_id
    LEFT JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
    CROSS JOIN LATERAL (
        SELECT c.cto_mem_id AS mem_id, c.cto_valor AS telefone
        FROM secretaria.contacto c
        WHERE c.cto_mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
          AND c.cto_end_date IS NULL AND c.cto_estado = 'ACTIVO' AND c.cto_tipo IN ('TELEFONE', 'WHATSAPP')
        ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) x
    WHERE e.esc_data = v_sabado AND e.esc_end_date IS NULL
      AND e.esc_estado IN ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA')
      AND (e.esc_eds_id IS NULL
           OR (p.epl_publicada AND p.epl_end_date IS NULL AND d.eds_end_date IS NULL AND d.eds_evento IS NULL))
      AND EXISTS (SELECT 1 FROM secretaria.consentimento s
                  WHERE s.cns_mem_id = x.mem_id AND s.cns_end_date IS NULL AND s.cns_concedido
                    AND s.cns_tipo = 'CONTACTO_SMS')
    ON CONFLICT (ntf_chave) WHERE ntf_end_date IS NULL DO NOTHING;
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;

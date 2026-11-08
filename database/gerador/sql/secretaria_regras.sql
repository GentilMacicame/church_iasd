-- Regras da secretaria (Manual da Igreja) -------------------------------

-- Verifica um voto: aprovado, da igreja certa e num tipo de reunião permitido
CREATE FUNCTION secretaria.fn_voto_valido(p_vot BIGINT, p_igr INT, p_tipos nucleo.tipo_reuniao_t[],
                                          p_exige_segunda_leitura BOOLEAN DEFAULT FALSE) RETURNS TEXT AS $$
DECLARE r RECORD;
BEGIN
    SELECT v.vot_estado, v.vot_leitura, u.reu_igr_id, u.reu_tipo INTO r
    FROM secretaria.voto v JOIN secretaria.reuniao u ON u.reu_id = v.vot_reu_id
    WHERE v.vot_id = p_vot AND v.vot_end_date IS NULL;
    IF NOT FOUND THEN RETURN 'o voto não existe'; END IF;
    IF r.vot_estado <> 'APROVADO' THEN RETURN 'o voto não foi aprovado'; END IF;
    IF r.reu_igr_id <> p_igr THEN RETURN 'o voto é de outra igreja'; END IF;
    IF NOT (r.reu_tipo = ANY (p_tipos)) THEN
        RETURN format('o voto foi tomado em %s; este acto exige %s', r.reu_tipo, array_to_string(p_tipos, ' ou '));
    END IF;
    IF p_exige_segunda_leitura AND r.vot_leitura <> 2 THEN
        RETURN 'é preciso a votação na segunda leitura (primeira leitura numa semana, voto na seguinte)';
    END IF;
    RETURN NULL;
END $$ LANGUAGE plpgsql STABLE;

CREATE FUNCTION secretaria.fn_em_censura(p_mem INT, p_data DATE) RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT 1 FROM secretaria.disciplina
                   WHERE dsc_mem_id = p_mem AND dsc_end_date IS NULL
                     AND p_data >= dsc_data_inicio AND p_data < dsc_data_fim);
$$ LANGUAGE sql STABLE;

-- O estado e a igreja do membro só mudam através do livro de membros;
-- aprovar o registo de um membro exige a permissão "validar"
CREATE FUNCTION secretaria.fn_mem_proteger() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.mem_estado, NEW.mem_igr_id) IS DISTINCT FROM (OLD.mem_estado, OLD.mem_igr_id)
       AND current_setting('app.via_movimento', true) IS DISTINCT FROM 'on' THEN
        RAISE EXCEPTION 'O estado e a igreja do membro só mudam com um movimento no livro de membros (secretaria.movimento_membro)';
    END IF;
    IF (TG_OP = 'INSERT' AND NEW.mem_validacao <> 'PENDENTE')
       OR (TG_OP = 'UPDATE' AND NEW.mem_validacao IS DISTINCT FROM OLD.mem_validacao) THEN
        PERFORM nucleo.fn_exigir('secretaria.membro.validar', NEW.mem_igr_id);
        NEW.mem_validado_por_usu_id := COALESCE(nucleo.fn_usuario_sessao(), NEW.mem_validado_por_usu_id);
        NEW.mem_data_validacao := now();
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mem_10_proteger
    BEFORE INSERT OR UPDATE ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_proteger();

-- Movimento no livro de membros: valida o voto e aplica-o ao membro
CREATE FUNCTION secretaria.fn_mmb_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    reg  nucleo.tipo_reuniao_t[] := ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[];
BEGIN
    IF NEW.mmb_tme_id IS NOT NULL OR NEW.mmb_tipo = 'FALECIMENTO' THEN
        RETURN NEW;                                       -- transferências validam-se na carta
    END IF;
    erro := secretaria.fn_voto_valido(NEW.mmb_vot_id, NEW.mmb_igr_id,
        CASE NEW.mmb_tipo
            WHEN 'REMOCAO_PEDIDO'     THEN ARRAY['JUNTA_DIRECTIVA', 'REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            WHEN 'REMOCAO_DISCIPLINA' THEN ARRAY['ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            WHEN 'DESAPARECIDO'       THEN ARRAY['ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]
            ELSE reg END);
    IF erro IS NOT NULL THEN
        RAISE EXCEPTION 'Movimento % do membro %: %', NEW.mmb_tipo, NEW.mmb_mem_id, erro;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mmb_10_validar
    BEFORE INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_validar();

-- Corre com privilégios do sistema: quem pode registar o movimento pode aplicá-lo ao membro
CREATE FUNCTION secretaria.fn_mmb_aplicar() RETURNS trigger AS $$
BEGIN
    PERFORM set_config('app.via_movimento', 'on', true);
    IF NEW.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA') THEN
        UPDATE secretaria.membro
           SET mem_estado = 'ACTIVO', mem_igr_id = NEW.mmb_igr_id,
               mem_data_entrada = NEW.mmb_data, mem_modo_entrada = NEW.mmb_tipo
         WHERE mem_id = NEW.mmb_mem_id;
    ELSIF NEW.mmb_tipo = 'TRANSFERENCIA_SAIDA' THEN
        UPDATE secretaria.membro SET mem_estado = 'TRANSFERIDO', mem_fam_id = NULL WHERE mem_id = NEW.mmb_mem_id;
    ELSE
        UPDATE secretaria.membro
           SET mem_estado = CASE NEW.mmb_tipo WHEN 'FALECIMENTO'  THEN 'FALECIDO'
                                              WHEN 'DESAPARECIDO' THEN 'DESAPARECIDO'
                                              ELSE 'REMOVIDO' END::nucleo.estado_membro_t
         WHERE mem_id = NEW.mmb_mem_id;
        -- quem deixa de ser membro deixa os cargos
        UPDATE secretaria.oficial SET ofi_data_fim = NEW.mmb_data
         WHERE ofi_mem_id = NEW.mmb_mem_id AND ofi_data_fim IS NULL AND ofi_end_date IS NULL;
    END IF;
    PERFORM set_config('app.via_movimento', 'off', true);
    RETURN NULL;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_mmb_20_aplicar
    AFTER INSERT ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_aplicar();

CREATE FUNCTION secretaria.fn_mmb_imutavel() RETURNS trigger AS $$
BEGIN
    IF (NEW.mmb_mem_id, NEW.mmb_igr_id, NEW.mmb_tipo, NEW.mmb_data, NEW.mmb_vot_id)
       IS DISTINCT FROM (OLD.mmb_mem_id, OLD.mmb_igr_id, OLD.mmb_tipo, OLD.mmb_data, OLD.mmb_vot_id) THEN
        RAISE EXCEPTION 'Um movimento do livro de membros não se altera; registe um novo movimento';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mmb_10_imutavel
    BEFORE UPDATE ON secretaria.movimento_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mmb_imutavel();

-- Carta de transferência
CREATE FUNCTION secretaria.fn_tme_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    reg  nucleo.tipo_reuniao_t[] := ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[];
    v_estado nucleo.estado_membro_t;
BEGIN
    IF NEW.tme_estado = 'CARTA_EMITIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CARTA_EMITIDA') THEN
        PERFORM nucleo.fn_exigir('secretaria.transferencia_membro.emitir_carta', NEW.tme_origem_igr_id);
        SELECT mem_estado INTO v_estado FROM secretaria.membro WHERE mem_id = NEW.tme_mem_id;
        IF v_estado <> 'ACTIVO' THEN
            RAISE EXCEPTION 'Só se emite carta a um membro activo (estado actual: %)', v_estado;
        END IF;
        IF secretaria.fn_em_censura(NEW.tme_mem_id, NEW.tme_carta_emitida_em) THEN
            RAISE EXCEPTION 'Um membro sob censura não pode receber carta de transferência';
        END IF;
        erro := secretaria.fn_voto_valido(NEW.tme_origem_vot_id, NEW.tme_origem_igr_id, reg, TRUE);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Carta de transferência: %', erro; END IF;
    END IF;
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA') THEN
        PERFORM nucleo.fn_exigir('secretaria.transferencia_membro.aceitar', COALESCE(NEW.tme_destino_igr_id, NEW.tme_origem_igr_id));
    END IF;
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA')
       AND NEW.tme_destino_igr_id IS NOT NULL THEN
        erro := secretaria.fn_voto_valido(NEW.tme_destino_vot_id, NEW.tme_destino_igr_id, reg, TRUE);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Aceitação da transferência: %', erro; END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tme_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.transferencia_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_tme_validar();

-- Ao concluir: saída na origem e entrada no destino (as duas igrejas ficam com o registo).
-- SECURITY DEFINER porque mexe nas duas igrejas, que um utilizador normalmente não vê ao mesmo tempo.
CREATE FUNCTION secretaria.fn_tme_concluir() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF NEW.tme_estado = 'CONCLUIDA' AND (TG_OP = 'INSERT' OR OLD.tme_estado <> 'CONCLUIDA') THEN
        INSERT INTO secretaria.movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_tme_id)
        VALUES (NEW.tme_mem_id, NEW.tme_origem_igr_id, 'TRANSFERENCIA_SAIDA', NEW.tme_aceite_em, NEW.tme_id);
        IF NEW.tme_destino_igr_id IS NOT NULL THEN
            INSERT INTO secretaria.movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id, mmb_tme_id)
            VALUES (NEW.tme_mem_id, NEW.tme_destino_igr_id, 'TRANSFERENCIA_ENTRADA', NEW.tme_aceite_em,
                    NEW.tme_destino_vot_id, NEW.tme_id);
        END IF;
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_tme_20_concluir
    AFTER INSERT OR UPDATE ON secretaria.transferencia_membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_tme_concluir();

-- Censura: voto da igreja, encarregado avisado se for menor, e o membro deixa os cargos
CREATE FUNCTION secretaria.fn_dsc_validar() RETURNS trigger AS $$
DECLARE
    erro TEXT;
    v_nasc DATE; v_igr INT;
BEGIN
    SELECT mem_data_nascimento, mem_igr_id INTO v_nasc, v_igr FROM secretaria.membro WHERE mem_id = NEW.dsc_mem_id;
    erro := secretaria.fn_voto_valido(NEW.dsc_vot_id, v_igr,
            ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]);
    IF erro IS NOT NULL THEN RAISE EXCEPTION 'Censura: %', erro; END IF;
    IF v_nasc > NEW.dsc_data_inicio - INTERVAL '18 years' AND NOT NEW.dsc_encarregado_notificado THEN
        RAISE EXCEPTION 'O membro é menor: os pais ou encarregado têm de ser avisados';
    END IF;
    IF TG_OP = 'INSERT' THEN
        UPDATE secretaria.oficial SET ofi_data_fim = NEW.dsc_data_inicio
         WHERE ofi_mem_id = NEW.dsc_mem_id AND ofi_data_fim IS NULL AND ofi_end_date IS NULL;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dsc_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.disciplina
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_dsc_validar();

-- Eleição: membro activo da igreja, sem censura, voto de eleição aprovado
CREATE FUNCTION secretaria.fn_ofi_validar() RETURNS trigger AS $$
DECLARE
    v_exige BOOLEAN; m RECORD; erro TEXT;
BEGIN
    IF NEW.ofi_data_fim IS NOT NULL AND TG_OP = 'UPDATE' AND OLD.ofi_data_fim IS NULL THEN
        RETURN NEW;                                       -- fim de mandato: sempre permitido
    END IF;
    SELECT car_exige_membro INTO v_exige FROM organizacao.cargo WHERE car_id = NEW.ofi_car_id;
    SELECT mem_estado, mem_igr_id INTO m FROM secretaria.membro WHERE mem_id = NEW.ofi_mem_id;
    IF v_exige AND (m.mem_estado <> 'ACTIVO' OR m.mem_igr_id <> NEW.ofi_igr_id) THEN
        RAISE EXCEPTION 'Este cargo exige um membro activo desta igreja';
    END IF;
    IF secretaria.fn_em_censura(NEW.ofi_mem_id, NEW.ofi_data_inicio) THEN
        RAISE EXCEPTION 'Um membro sob censura não pode ocupar cargos';
    END IF;
    IF NEW.ofi_vot_id IS NOT NULL THEN
        erro := secretaria.fn_voto_valido(NEW.ofi_vot_id, NEW.ofi_igr_id,
                ARRAY['REUNIAO_REGULAR', 'ASSEMBLEIA_ADMINISTRATIVA']::nucleo.tipo_reuniao_t[]);
        IF erro IS NOT NULL THEN RAISE EXCEPTION 'Eleição: %', erro; END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ofi_10_validar
    BEFORE INSERT OR UPDATE ON secretaria.oficial
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_ofi_validar();

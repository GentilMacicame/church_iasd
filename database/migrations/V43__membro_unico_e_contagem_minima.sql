-- =====================================================================
-- V43 · Membro único (F-SEC-01, 4.4 e 18) e contagem com o mínimo de participantes (F-TES, 14.4)
--
--   membro       Antes de registar procura-se o membro em TODAS as igrejas, não só nas que o utilizador vê:
--                nucleo.fn_membro_existente (SECURITY DEFINER) devolve o mesmo membro já registado — mesmo número de
--                documento, ou o mesmo nome completo com a mesma data de nascimento. Das igrejas que o utilizador não
--                vê só diz o nome e a igreja (para pedir a transferência), nunca a ficha.
--                A base de dados recusa um segundo registo nesses casos (trigger trg_mem_05_unico, ao registar e ao
--                mudar o nome, a data de nascimento ou o documento). Nome só parecido continua a ser aviso: quem tem
--                permissão para registar confere e confirma (nada se bloqueia só pela semelhança do nome).
--                Os registos que já existam em duplicado não são tocados (o trigger só olha para o que muda).
--   contagem     Para conferir uma contagem, tem de ter pelo menos o tesoureiro, um representante da Escola Sabatina
--                e um diácono (o ancião é opcional). Depois de conferida, os participantes ficam como estavam.
--   reuniões     O ponto da agenda ganha a discussão (rpt_discussao), separada da descrição (rpt_detalhes) (17.3).
--                Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- nome comparável: minúsculas, sem acentos nem espaços a mais
CREATE FUNCTION nucleo.fn_nome_comparavel(p TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
    SELECT nullif(regexp_replace(trim(translate(lower(coalesce(p, '')),
                  'áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn')), '\s+', ' ', 'g'), '')
$$;
COMMENT ON FUNCTION nucleo.fn_nome_comparavel(TEXT) IS 'Nome para comparar: minúsculas, sem acentos, um espaço entre palavras (V43)';

-- ---------------------------------------------------------------- o mesmo membro já registado (em qualquer igreja)
CREATE FUNCTION nucleo.fn_membro_existente(p_nome TEXT, p_apelido TEXT, p_data_nascimento DATE DEFAULT NULL,
                                           p_numero_identificacao TEXT DEFAULT NULL, p_excluir_mem_id INT DEFAULT NULL)
RETURNS TABLE (mem_id INT, igr_id INT, igreja TEXT, nome TEXT, motivo TEXT, visivel BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH p AS (
        SELECT nullif(upper(regexp_replace(coalesce(p_numero_identificacao, ''), '[^A-Za-z0-9]', '', 'g')), '') AS doc,
               nucleo.fn_nome_comparavel(coalesce(p_nome, '') || ' ' || coalesce(p_apelido, '')) AS nome,
               coalesce(nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'), '{}') AS vejo
    ), achados AS (
        -- mesmo documento (5 caracteres ou mais, escrito de qualquer forma)
        SELECT m.mem_id, 'Mesmo número de documento'::TEXT AS motivo
          FROM secretaria.membro m, p
         WHERE p.doc IS NOT NULL AND length(p.doc) >= 5 AND m.mem_end_date IS NULL AND m.mem_numero_identificacao IS NOT NULL
           AND upper(regexp_replace(m.mem_numero_identificacao::TEXT, '[^A-Za-z0-9]', '', 'g')) = p.doc
        UNION
        -- mesmo nome completo e mesma data de nascimento
        SELECT m.mem_id, 'Mesmo nome e data de nascimento'
          FROM secretaria.membro m, p
         WHERE p_data_nascimento IS NOT NULL AND p.nome IS NOT NULL AND m.mem_end_date IS NULL
           AND m.mem_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento
           AND nucleo.fn_nome_comparavel(m.mem_nome || ' ' || m.mem_apelido) = p.nome
    )
    SELECT CASE WHEN m.mem_igr_id = ANY (p.vejo) THEN m.mem_id END, m.mem_igr_id, i.igr_nome::TEXT,
           (m.mem_nome || ' ' || m.mem_apelido)::TEXT, string_agg(a.motivo, '; ' ORDER BY a.motivo), m.mem_igr_id = ANY (p.vejo)
      FROM achados a
      JOIN secretaria.membro m ON m.mem_id = a.mem_id
      JOIN organizacao.igreja i ON i.igr_id = m.mem_igr_id
     CROSS JOIN p
     WHERE m.mem_id IS DISTINCT FROM p_excluir_mem_id
     GROUP BY m.mem_id, m.mem_igr_id, i.igr_nome, m.mem_nome, m.mem_apelido, p.vejo
     ORDER BY m.mem_apelido, m.mem_nome
     LIMIT 5
$$;
COMMENT ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) IS
    'O mesmo membro já registado em qualquer igreja (mesmo documento, ou mesmo nome e data de nascimento); das igrejas que o utilizador não vê só o nome e a igreja (V43)';
REVOKE ALL ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_membro_existente(TEXT, TEXT, DATE, TEXT, INT) TO app_igreja;

-- ---------------------------------------------------------------- recusa o segundo registo da mesma pessoa
CREATE FUNCTION secretaria.fn_mem_unico() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    r RECORD;
BEGIN
    IF NEW.mem_end_date IS NOT NULL THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND NEW.mem_nome IS NOT DISTINCT FROM OLD.mem_nome AND NEW.mem_apelido IS NOT DISTINCT FROM OLD.mem_apelido
       AND NEW.mem_data_nascimento IS NOT DISTINCT FROM OLD.mem_data_nascimento
       AND NEW.mem_numero_identificacao IS NOT DISTINCT FROM OLD.mem_numero_identificacao
       AND OLD.mem_end_date IS NULL THEN
        RETURN NEW;
    END IF;
    SELECT * INTO r FROM nucleo.fn_membro_existente(NEW.mem_nome, NEW.mem_apelido, NEW.mem_data_nascimento,
                                                    NEW.mem_numero_identificacao, NEW.mem_id) LIMIT 1;
    IF FOUND THEN
        RAISE EXCEPTION 'Este membro já existe: % (%), com o %. Abra o registo existente%.', r.nome, r.igreja, lower(r.motivo),
              CASE WHEN r.igr_id = NEW.mem_igr_id THEN '' ELSE ' ou peça a transferência a essa igreja' END
              USING COLUMN = CASE WHEN r.motivo LIKE 'Mesmo número%' THEN 'mem_numero_identificacao' ELSE 'mem_nome' END;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_mem_05_unico BEFORE INSERT OR UPDATE OF mem_nome, mem_apelido, mem_data_nascimento, mem_numero_identificacao, mem_end_date
    ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_unico();

-- ---------------------------------------------------------------- contagem: tesoureiro, Escola Sabatina e diácono para conferir
CREATE FUNCTION tesouraria.fn_cnu_participantes_minimos() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_falta TEXT;
BEGIN
    IF NEW.cnu_estado::TEXT = 'CONFERIDA' AND OLD.cnu_estado::TEXT = 'ABERTA' THEN
        SELECT string_agg(f.rotulo, ', ' ORDER BY f.ordem) INTO v_falta
          FROM (VALUES (1, 'TESOUREIRO', 'o tesoureiro'), (2, 'ESCOLA_SABATINA', 'o representante da Escola Sabatina'),
                       (3, 'DIACONO', 'o diácono')) AS f(ordem, funcao, rotulo)
         WHERE NOT EXISTS (SELECT 1 FROM tesouraria.contagem_participante p
                            WHERE p.cpa_cnu_id = NEW.cnu_id AND p.cpa_funcao = f.funcao AND p.cpa_end_date IS NULL);
        IF v_falta IS NOT NULL THEN
            RAISE EXCEPTION 'Para conferir, a contagem tem de ter pelo menos o tesoureiro, o representante da Escola Sabatina e o diácono. Falta: %.', v_falta;
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_cnu_20_participantes BEFORE UPDATE OF cnu_estado ON tesouraria.contagem_numerario
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cnu_participantes_minimos();

-- depois de conferida (ou depositada), os participantes não mudam: ficam no histórico como estavam
CREATE OR REPLACE FUNCTION tesouraria.fn_cpa_validar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tesouraria.contagem_numerario c JOIN secretaria.membro m ON m.mem_igr_id = c.cnu_igr_id
                    WHERE c.cnu_id = NEW.cpa_cnu_id AND m.mem_id = NEW.cpa_mem_id) THEN
        RAISE EXCEPTION 'O participante tem de ser membro da igreja da contagem' USING COLUMN = 'cpa_mem_id';
    END IF;
    IF EXISTS (SELECT 1 FROM tesouraria.contagem_numerario c WHERE c.cnu_id = NEW.cpa_cnu_id AND c.cnu_estado::TEXT <> 'ABERTA') THEN
        RAISE EXCEPTION 'A contagem já foi conferida: os participantes ficam como estavam';
    END IF;
    RETURN NEW;
END $$;
DROP TRIGGER trg_cpa_10_validar ON tesouraria.contagem_participante;
CREATE TRIGGER trg_cpa_10_validar BEFORE INSERT OR UPDATE ON tesouraria.contagem_participante
    FOR EACH ROW EXECUTE FUNCTION tesouraria.fn_cpa_validar();

-- ---------------------------------------------------------------- reuniões: a discussão de cada ponto (17.3)
ALTER TABLE secretaria.reuniao_ponto ADD COLUMN rpt_discussao TEXT;
COMMENT ON COLUMN secretaria.reuniao_ponto.rpt_discussao IS 'Resumo da discussão do ponto (o que se disse); a descrição fica em detalhes (V43)';

-- =====================================================================
-- V33 · Ficha completa do membro (F-SEC-01): cônjuge ligado, casamento, trabalho, endereço postal,
--       conversão, ex-membro, telefone fixo e aviso de registos parecidos (possíveis duplicados)
--
--   membro     colunas novas, todas opcionais (ex_membro tem FALSE por defeito): os registos existentes
--              não mudam. O baptismo anterior de um ex-membro é uma linha de secretaria.baptismo sem
--              rebaptismo (o baptismo actual fica como rebaptismo): não há coluna nova para ele.
--   cônjuge    mem_conjuge_mem_id liga dois registos de membros (não se cria outro registo para o cônjuge).
--              A ligação é recíproca: ao ligar A → B, B fica ligado a A (se B estiver livre); ao desligar,
--              desliga-se dos dois lados. Um membro já ligado a outro cônjuge não pode ser escolhido.
--   contacto   novo tipo TELEFONE_FIXO. TELEFONE continua a ser o telemóvel (celular), o único que recebe SMS.
--   parecidos  nucleo.fn_membros_parecidos(...): membros visíveis com o mesmo documento, ou nome parecido e a
--              mesma data de nascimento / local de nascimento. Só avisa (a API devolve a lista e o
--              utilizador confirma); não bloqueia o registo.
--   vistas     vw_membro_basico ganha estado civil, data de nascimento e cônjuge (indicadores e escolha do
--              cônjuge); vw_membros_lista é a lista para exportar (CSV/PDF).
--
-- Permissões: não mudam. Quem lê ou altera o membro (RLS por igreja) lê ou altera estes campos.
-- Gerado com database/gerador (defs.py, sql/V1__base.sql); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TYPE nucleo.tipo_contacto_t ADD VALUE IF NOT EXISTS 'TELEFONE_FIXO';

-- ---------------------------------------------------------------- membro
ALTER TABLE secretaria.membro
    ADD COLUMN mem_outro_documento VARCHAR(100),
    ADD COLUMN mem_ex_membro BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN mem_endereco_postal VARCHAR(150),
    ADD COLUMN mem_codigo_postal VARCHAR(20),
    ADD COLUMN mem_local_trabalho VARCHAR(150),
    ADD COLUMN mem_data_casamento DATE,
    ADD COLUMN mem_conjuge_mem_id INT,
    ADD COLUMN mem_nome_conjuge VARCHAR(150),
    ADD COLUMN mem_dependentes SMALLINT,
    ADD COLUMN mem_religiao_anterior VARCHAR(100),
    ADD COLUMN mem_metodo_conversao VARCHAR(100),
    ADD CONSTRAINT fk_mem_conjuge_mem_id FOREIGN KEY (mem_conjuge_mem_id) REFERENCES secretaria.membro(mem_id),
    ADD CONSTRAINT chk_mem_conjuge CHECK (mem_conjuge_mem_id IS NULL OR mem_conjuge_mem_id <> mem_id),
    ADD CONSTRAINT chk_mem_dependentes CHECK (mem_dependentes IS NULL OR mem_dependentes BETWEEN 0 AND 50),
    ADD CONSTRAINT chk_mem_casamento CHECK (mem_data_casamento IS NULL OR mem_data_nascimento IS NULL OR mem_data_casamento > mem_data_nascimento);

COMMENT ON COLUMN secretaria.membro.mem_outro_documento IS 'Outro documento além do principal (tipo e número, ex.: NUIT 400123456)';
COMMENT ON COLUMN secretaria.membro.mem_ex_membro IS 'Já foi membro da IASD (o baptismo anterior fica em baptismo, sem rebaptismo) (V33)';
COMMENT ON COLUMN secretaria.membro.mem_endereco_postal IS 'Endereço para correspondência (caixa postal, rua)';
COMMENT ON COLUMN secretaria.membro.mem_local_trabalho IS 'Onde trabalha (empresa ou instituição)';
COMMENT ON COLUMN secretaria.membro.mem_conjuge_mem_id IS 'Cônjuge que é membro (no sistema): liga os dois registos, sem criar outro (V33)';
COMMENT ON COLUMN secretaria.membro.mem_nome_conjuge IS 'Nome do cônjuge que não está no sistema';
COMMENT ON COLUMN secretaria.membro.mem_dependentes IS 'Número de dependentes a cargo';
COMMENT ON COLUMN secretaria.membro.mem_metodo_conversao IS 'Como conheceu a mensagem (estudo bíblico, evangelismo, família, rádio/TV, ...)';

COMMENT ON CONSTRAINT chk_mem_conjuge ON secretaria.membro IS '[conjugeMembroId] O membro não pode ser o seu próprio cônjuge.';
COMMENT ON CONSTRAINT chk_mem_dependentes ON secretaria.membro IS '[dependentes] O número de dependentes tem de estar entre 0 e 50.';
COMMENT ON CONSTRAINT chk_mem_casamento ON secretaria.membro IS '[dataCasamento] A data do casamento tem de ser depois da data de nascimento.';

CREATE INDEX idx_mem_conjuge_mem_id ON secretaria.membro (mem_conjuge_mem_id);
-- procura de registos parecidos: pelo documento (sem espaços nem traços) e pela data de nascimento
CREATE INDEX idx_mem_documento ON secretaria.membro (upper(regexp_replace(mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')))
    WHERE mem_numero_identificacao IS NOT NULL AND mem_end_date IS NULL;
CREATE INDEX idx_mem_nascimento ON secretaria.membro (mem_data_nascimento)
    WHERE mem_data_nascimento IS NOT NULL AND mem_end_date IS NULL;

-- ---------------------------------------------------------------- cônjuge: escolha válida e ligação recíproca
CREATE FUNCTION secretaria.fn_mem_conjuge_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_outro INT;
    v_nome  TEXT;
BEGIN
    IF NEW.mem_conjuge_mem_id IS NULL
       OR (TG_OP = 'UPDATE' AND NEW.mem_conjuge_mem_id IS NOT DISTINCT FROM OLD.mem_conjuge_mem_id) THEN
        RETURN NEW;
    END IF;
    SELECT mem_conjuge_mem_id, mem_nome || ' ' || mem_apelido INTO v_outro, v_nome
      FROM secretaria.membro WHERE mem_id = NEW.mem_conjuge_mem_id;
    IF v_outro IS NOT NULL AND v_outro <> NEW.mem_id THEN
        RAISE EXCEPTION '% já está ligado(a) a outro cônjuge. Desligue primeiro esse registo.', v_nome
            USING COLUMN = 'mem_conjuge_mem_id';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_mem_15_conjuge
    BEFORE INSERT OR UPDATE OF mem_conjuge_mem_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_conjuge_validar();

-- Liga (ou desliga) o outro lado. Corre com as permissões de quem altera: se não puder ver ou alterar o
-- registo do cônjuge (outra igreja), esse lado fica como estava.
CREATE FUNCTION secretaria.fn_mem_conjuge_reciproco() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.mem_conjuge_mem_id IS NOT NULL
       AND OLD.mem_conjuge_mem_id IS DISTINCT FROM NEW.mem_conjuge_mem_id THEN
        UPDATE secretaria.membro SET mem_conjuge_mem_id = NULL
         WHERE mem_id = OLD.mem_conjuge_mem_id AND mem_conjuge_mem_id = NEW.mem_id;
    END IF;
    IF NEW.mem_conjuge_mem_id IS NOT NULL THEN
        UPDATE secretaria.membro SET mem_conjuge_mem_id = NEW.mem_id
         WHERE mem_id = NEW.mem_conjuge_mem_id AND mem_conjuge_mem_id IS NULL;
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_mem_50_conjuge_reciproco
    AFTER INSERT OR UPDATE OF mem_conjuge_mem_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_conjuge_reciproco();

-- ---------------------------------------------------------------- registos parecidos (possíveis duplicados)
-- Pontos: mesmo documento 100; nome igual ou muito parecido 40 (parecido 20); mesma data de nascimento 30;
-- mesmo local de nascimento 10. Devolve os que somam 40 ou mais (os mais parecidos primeiro, até 10).
-- SECURITY INVOKER: cada utilizador só compara com os membros que pode ver (RLS).
CREATE FUNCTION nucleo.fn_membros_parecidos(p_nome TEXT, p_apelido TEXT, p_data_nascimento DATE DEFAULT NULL,
                                            p_naturalidade TEXT DEFAULT NULL, p_numero_identificacao TEXT DEFAULT NULL,
                                            p_excluir_mem_id INT DEFAULT NULL)
RETURNS TABLE (mem_id INT, mem_igr_id INT, nome TEXT, data_nascimento DATE, naturalidade TEXT,
               numero_identificacao TEXT, estado nucleo.estado_membro_t, pontos INT, motivos TEXT[])
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH p AS (
        SELECT lower(trim(coalesce(p_nome, '') || ' ' || coalesce(p_apelido, ''))) AS nome,
               nullif(upper(regexp_replace(coalesce(p_numero_identificacao, ''), '[^A-Za-z0-9]', '', 'g')), '') AS doc,
               nullif(lower(trim(coalesce(p_naturalidade, ''))), '') AS nat
    ), candidatos AS (
        SELECT m.*, similarity(lower(m.mem_nome || ' ' || m.mem_apelido), p.nome) AS sim,
               (p.doc IS NOT NULL AND length(p.doc) >= 5
                AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc) AS mesmo_doc,
               (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento) AS mesma_data,
               (p.nat IS NOT NULL AND lower(trim(m.mem_naturalidade)) = p.nat) AS mesmo_local
          FROM secretaria.membro m, p
         WHERE m.mem_end_date IS NULL
           AND m.mem_id IS DISTINCT FROM p_excluir_mem_id
           AND ((m.mem_nome || ' ' || m.mem_apelido) % (coalesce(p_nome, '') || ' ' || coalesce(p_apelido, ''))
                OR (p.doc IS NOT NULL AND upper(regexp_replace(m.mem_numero_identificacao, '[^A-Za-z0-9]', '', 'g')) = p.doc)
                OR (p_data_nascimento IS NOT NULL AND m.mem_data_nascimento = p_data_nascimento))
    ), pontuados AS (
        SELECT c.*,
               (CASE WHEN c.mesmo_doc THEN 100 ELSE 0 END
              + CASE WHEN c.sim >= 0.6 THEN 40 WHEN c.sim >= 0.45 THEN 20 ELSE 0 END
              + CASE WHEN c.mesma_data THEN 30 ELSE 0 END
              + CASE WHEN c.mesmo_local THEN 10 ELSE 0 END) AS pts,
               array_remove(ARRAY[
                 CASE WHEN c.mesmo_doc THEN 'Mesmo número de documento' END,
                 CASE WHEN c.sim >= 0.6 THEN 'Nome igual ou muito parecido' WHEN c.sim >= 0.45 THEN 'Nome parecido' END,
                 CASE WHEN c.mesma_data THEN 'Mesma data de nascimento' END,
                 CASE WHEN c.mesmo_local THEN 'Mesmo local de nascimento' END], NULL) AS mot
          FROM candidatos c
    )
    SELECT x.mem_id, x.mem_igr_id, (x.mem_nome || ' ' || x.mem_apelido)::TEXT, x.mem_data_nascimento,
           x.mem_naturalidade::TEXT, x.mem_numero_identificacao::TEXT, x.mem_estado, x.pts, x.mot
      FROM pontuados x
     WHERE x.pts >= 40
     ORDER BY x.pts DESC, x.mem_apelido, x.mem_nome
     LIMIT 10
$$;
COMMENT ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) IS
    'Registos de membros parecidos (possíveis duplicados) entre os que o utilizador vê: só aviso, não bloqueia (V33)';
REVOKE ALL ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_membros_parecidos(TEXT, TEXT, DATE, TEXT, TEXT, INT) TO app_igreja;

-- ---------------------------------------------------------------- vistas
-- Colunas novas só no fim (CREATE OR REPLACE mantém as que já existem)
CREATE OR REPLACE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado,
       mem_estado_civil, mem_data_nascimento, mem_conjuge_mem_id
FROM secretaria.membro WHERE mem_end_date IS NULL;

-- Lista dos membros para exportar (CSV/PDF): os campos mais usados, o contacto principal e o baptismo
CREATE VIEW secretaria.vw_membros_lista WITH (security_invoker = true) AS
SELECT m.mem_id, m.mem_igr_id,
       m.mem_nome || ' ' || m.mem_apelido AS nome,
       m.mem_sexo AS sexo, m.mem_data_nascimento AS data_nascimento,
       date_part('year', age(m.mem_data_nascimento))::INT AS idade,
       m.mem_estado_civil AS estado_civil, m.mem_estado AS estado,
       (SELECT c.cto_valor FROM secretaria.contacto c
         WHERE c.cto_mem_id = m.mem_id AND c.cto_end_date IS NULL AND c.cto_tipo IN ('TELEFONE', 'WHATSAPP')
         ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) AS telemovel,
       (SELECT c.cto_valor FROM secretaria.contacto c
         WHERE c.cto_mem_id = m.mem_id AND c.cto_end_date IS NULL AND c.cto_tipo = 'EMAIL'
         ORDER BY c.cto_principal DESC, c.cto_id LIMIT 1) AS email,
       m.mem_bairro AS bairro, m.mem_cidade_distrito AS cidade,
       m.mem_profissao AS profissao,
       f.fam_nome AS familia,
       (SELECT min(b.bap_data) FROM secretaria.baptismo b WHERE b.bap_mem_id = m.mem_id AND b.bap_end_date IS NULL) AS data_baptismo,
       m.mem_data_entrada AS data_entrada
FROM secretaria.membro m
LEFT JOIN secretaria.familia f ON f.fam_id = m.mem_fam_id
WHERE m.mem_end_date IS NULL;
COMMENT ON VIEW secretaria.vw_membros_lista IS 'Lista dos membros para exportar (V33); RLS das tabelas por baixo';
GRANT SELECT ON secretaria.vw_membros_lista TO app_igreja;

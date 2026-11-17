-- =====================================================================
-- V40 · Relações familiares (F-SEC-03): o parentesco de cada membro com o chefe da família
--
--   membro.mem_parentesco   CHEFE, CONJUGE, FILHO, PAI_MAE, IRMAO, NETO ou OUTRO; só para quem está numa família;
--                           um só chefe por família. Ao mudar de família (ou sair), o parentesco antigo é limpo.
--   vw_membro_basico        ganha o parentesco (no fim), para a ficha da família.
--
-- As permissões não mudam: quem altera o membro altera o parentesco. Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE secretaria.membro ADD COLUMN mem_parentesco VARCHAR(10);
ALTER TABLE secretaria.membro ADD CONSTRAINT chk_mem_parentesco
    CHECK (mem_parentesco IS NULL OR (mem_fam_id IS NOT NULL AND mem_parentesco IN ('CHEFE', 'CONJUGE', 'FILHO', 'PAI_MAE', 'IRMAO', 'NETO', 'OUTRO')));
COMMENT ON COLUMN secretaria.membro.mem_parentesco IS 'Relação com o chefe da família: CHEFE, CONJUGE, FILHO, PAI_MAE, IRMAO, NETO, OUTRO (V40)';
COMMENT ON CONSTRAINT chk_mem_parentesco ON secretaria.membro IS '[parentesco] O parentesco só existe para quem está numa família (chefe, cônjuge, filho, pai/mãe, irmão, neto ou outro).';
CREATE UNIQUE INDEX uq_mem_chefe_familia ON secretaria.membro (mem_fam_id) WHERE mem_parentesco = 'CHEFE' AND mem_end_date IS NULL;
COMMENT ON INDEX secretaria.uq_mem_chefe_familia IS '[parentesco] Esta família já tem chefe: mude primeiro o parentesco do actual.';

-- mudar de família (ou sair dela) limpa o parentesco, que era em relação ao chefe da outra família
CREATE FUNCTION secretaria.fn_mem_parentesco() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.mem_fam_id IS DISTINCT FROM OLD.mem_fam_id AND NEW.mem_parentesco IS NOT DISTINCT FROM OLD.mem_parentesco THEN
        NEW.mem_parentesco := NULL;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_mem_12_parentesco BEFORE UPDATE OF mem_fam_id ON secretaria.membro
    FOR EACH ROW EXECUTE FUNCTION secretaria.fn_mem_parentesco();

CREATE OR REPLACE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado,
       mem_estado_civil, mem_data_nascimento, mem_conjuge_mem_id, mem_parentesco
FROM secretaria.membro WHERE mem_end_date IS NULL;

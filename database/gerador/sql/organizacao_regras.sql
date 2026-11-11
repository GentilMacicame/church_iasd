-- ---------------------------------------------------------------- organização: regras
-- V26: o distrito administrativo da igreja pertence à província indicada. Sem província, vem a do distrito.
CREATE FUNCTION organizacao.fn_igr_provincia_distrito() RETURNS trigger AS $$
DECLARE v_prv INT;
BEGIN
    IF NEW.igr_dad_id IS NOT NULL THEN
        SELECT dad_prv_id INTO v_prv FROM organizacao.distrito_administrativo WHERE dad_id = NEW.igr_dad_id;
        IF NEW.igr_prv_id IS NULL THEN
            NEW.igr_prv_id := v_prv;
        ELSIF NEW.igr_prv_id IS DISTINCT FROM v_prv THEN
            RAISE EXCEPTION 'O distrito escolhido não pertence a essa província';
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_igr_20_provincia_distrito BEFORE INSERT OR UPDATE OF igr_prv_id, igr_dad_id ON organizacao.igreja
    FOR EACH ROW EXECUTE FUNCTION organizacao.fn_igr_provincia_distrito();

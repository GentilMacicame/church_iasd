-- Regras de acesso ---------------------------------------------------------

-- Utilizadores: ninguém se torna super_admin sozinho; só se gere quem está em igrejas que se administram
CREATE FUNCTION nucleo.fn_usu_proteger() RETURNS trigger AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');      -- só passa na instalação/manutenção
        RETURN NEW;
    END IF;
    IF NEW.usu_super_admin AND (TG_OP = 'INSERT' OR NOT OLD.usu_super_admin) AND NOT nucleo.fn_e_super_admin() THEN
        RAISE EXCEPTION 'Só um super-administrador pode criar outro';
    END IF;
    IF TG_OP = 'INSERT' THEN
        PERFORM nucleo.fn_exigir('nucleo.usuario.criar');
        RETURN NEW;
    END IF;
    IF OLD.usu_id = v_usr THEN
        -- a própria pessoa muda nome, contactos e senha, mas não o estado nem a ligação ao membro
        IF (NEW.usu_estado, NEW.usu_mem_id, NEW.usu_super_admin) IS DISTINCT FROM (OLD.usu_estado, OLD.usu_mem_id, OLD.usu_super_admin)
           AND NOT nucleo.fn_e_super_admin() THEN
            RAISE EXCEPTION 'Não pode alterar o seu próprio estado, membro ou nível de acesso';
        END IF;
        RETURN NEW;
    END IF;
    PERFORM nucleo.fn_exigir('nucleo.usuario.alterar');
    IF NOT nucleo.fn_e_super_admin() THEN
        IF OLD.usu_super_admin THEN
            RAISE EXCEPTION 'Só um super-administrador altera outro super-administrador';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_igreja u
                   WHERE u.uig_usu_id = OLD.usu_id AND u.uig_end_date IS NULL
                     AND NOT nucleo.fn_tem_permissao('nucleo.usuario.alterar', u.uig_igr_id)) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis em igrejas que não administra';
        END IF;
        IF EXISTS (SELECT 1 FROM nucleo.usuario_entidade e
                   WHERE e.uen_usu_id = OLD.usu_id AND e.uen_end_date IS NULL
                     AND e.uen_ent_id NOT IN (SELECT nucleo.fn_entidades_com_permissao('nucleo.usuario.alterar'))) THEN
            RAISE EXCEPTION 'Este utilizador tem perfis numa Associação/Missão que não administra';
        END IF;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usu_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_usu_proteger();

-- Atribuir perfis numa igreja: não a si próprio e só perfis cujas permissões já tem nessa igreja
CREATE FUNCTION nucleo.fn_uig_proteger() RETURNS trigger AS $$
DECLARE v_falta TEXT;
BEGIN
    IF (SELECT per_ambito FROM nucleo.perfil WHERE per_id = NEW.uig_per_id) <> 'IGREJA' THEN
        RAISE EXCEPTION 'Este perfil é de Associação/Missão: atribua-o em nucleo.usuario_entidade';
    END IF;
    IF nucleo.fn_usuario_sessao() IS NULL OR nucleo.fn_e_super_admin() THEN RETURN NEW; END IF;
    IF NEW.uig_usu_id = nucleo.fn_usuario_sessao() THEN
        RAISE EXCEPTION 'Ninguém altera os seus próprios perfis';
    END IF;
    SELECT string_agg(pm.prm_codigo, ', ') INTO v_falta
    FROM nucleo.perfil_permissao pp JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id
    WHERE pp.ppe_per_id = NEW.uig_per_id AND pp.ppe_end_date IS NULL
      AND NOT nucleo.fn_tem_permissao(pm.prm_codigo, NEW.uig_igr_id);
    IF v_falta IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode dar um perfil com permissões que não tem nesta igreja: %', left(v_falta, 300)
            USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_uig_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario_igreja
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_uig_proteger();

CREATE FUNCTION nucleo.fn_uen_proteger() RETURNS trigger AS $$
DECLARE v_falta TEXT;
BEGIN
    IF (SELECT per_ambito FROM nucleo.perfil WHERE per_id = NEW.uen_per_id) <> 'ENTIDADE' THEN
        RAISE EXCEPTION 'Este perfil é de igreja: atribua-o em nucleo.usuario_igreja';
    END IF;
    IF nucleo.fn_usuario_sessao() IS NULL OR nucleo.fn_e_super_admin() THEN RETURN NEW; END IF;
    IF NEW.uen_usu_id = nucleo.fn_usuario_sessao() THEN
        RAISE EXCEPTION 'Ninguém altera os seus próprios perfis';
    END IF;
    SELECT string_agg(pm.prm_codigo, ', ') INTO v_falta
    FROM nucleo.perfil_permissao pp JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id
    WHERE pp.ppe_per_id = NEW.uen_per_id AND pp.ppe_end_date IS NULL
      AND NEW.uen_ent_id NOT IN (SELECT nucleo.fn_entidades_com_permissao(pm.prm_codigo));
    IF v_falta IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode dar um perfil com permissões que não tem nesta Associação/Missão: %', left(v_falta, 300)
            USING ERRCODE = 'insufficient_privilege';
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_uen_10_proteger
    BEFORE INSERT OR UPDATE ON nucleo.usuario_entidade
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_uen_proteger();

-- Login: a API obtém o hash da senha por esta função (a coluna da senha não é legível directamente)
CREATE FUNCTION nucleo.fn_credenciais(p_login TEXT)
RETURNS TABLE (usu_id INT, senha_hash VARCHAR, estado nucleo.estado_registo_t)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT u.usu_id, u.usu_senha_hash, u.usu_estado
    FROM nucleo.usuario u
    WHERE (u.usu_email = p_login OR u.usu_telefone = p_login) AND u.usu_end_date IS NULL;
$$;

-- O que o utilizador da sessão pode fazer (para a API mostrar ou esconder menus e botões)
CREATE FUNCTION nucleo.fn_minhas_permissoes()
RETURNS TABLE (codigo VARCHAR, igr_id INT)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT pm.prm_codigo, i
    FROM nucleo.permissao pm, unnest(nucleo.fn_igrejas_com_permissao(pm.prm_codigo)) i
    WHERE pm.prm_end_date IS NULL;
$$;

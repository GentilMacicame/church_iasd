-- =====================================================================
-- V32 · Códigos fixos em vez de nomes, e permissões do super-administrador intocáveis
--
--   1. Perfis: código fixo (per_codigo). O acesso do pastor do distrito dependia do NOME do perfil
--      (per_nome = 'PASTOR', em nucleo.fn_igrejas_com_permissao, chamada em todas as verificações de permissão):
--      mudar o nome do perfil tirava o acesso aos pastores sem qualquer erro. Agora depende do código, que não muda.
--      O nome passa a ser só o texto mostrado. Os perfis do sistema (com código) não se terminam nem mudam de âmbito.
--   2. Códigos das categorias e das permissões não se alteram depois de criados. As regras e a API identificam
--      categorias pelo código (D1 remessas, D9 outras despesas, R3 ofertas da Escola Sabatina) e as permissões pelo
--      código (secretaria.membro.ler, ...): o código é o identificador estável; o nome/descrição pode mudar.
--   3. Super-administrador: as suas permissões não se alteram pelo sistema. Ninguém (nem outro super-administrador,
--      nem o próprio) lhe retira o acesso total, o inactiva ou o termina. Só a manutenção da base (sem utilizador
--      na sessão, como dono das tabelas) o pode fazer, por exemplo quando a pessoa sai da organização.
--
-- Nota sobre os ENUM (tra_tipo = 'ENTRADA', mmb_tipo = 'BAPTISMO', ...): não são pesquisas por nome. Cada linha guarda
-- o identificador interno do valor (4 bytes) e a comparação é tão rápida como entre inteiros; não mudam aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- 1. código fixo dos perfis (gerado: gen.py)
ALTER TABLE nucleo.perfil ADD COLUMN per_codigo VARCHAR(30);
COMMENT ON COLUMN nucleo.perfil.per_codigo IS 'Código fixo dos perfis do sistema (ADMIN, PASTOR, ...): não muda, ao contrário do nome; vazio nos perfis criados pelos utilizadores (V32)';
CREATE UNIQUE INDEX uq_per_codigo ON nucleo.perfil (per_codigo) WHERE per_end_date IS NULL;
COMMENT ON INDEX nucleo.uq_per_codigo IS '[codigo] Já existe um perfil com este código.';

-- os 13 perfis do sistema: o código é o nome que tinham (carga única)
UPDATE nucleo.perfil SET per_codigo = per_nome
 WHERE per_end_date IS NULL
   AND per_nome IN ('ADMIN', 'PASTOR', 'ANCIAO', 'SECRETARIO', 'TESOUREIRO', 'DIRECTOR_ES', 'SECRETARIO_ES',
                    'DIRECTOR_DEPARTAMENTO', 'MEMBRO', 'ADMIN_ASSOCIACAO', 'TESOUREIRO_ASSOCIACAO',
                    'SECRETARIO_ASSOCIACAO', 'INTEGRACAO');

CREATE FUNCTION nucleo.fn_per_proteger() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.per_codigo IS NOT NULL AND nucleo.fn_usuario_sessao() IS NOT NULL THEN
            RAISE EXCEPTION 'O código de um perfil do sistema só é definido pelo sistema (deixe o código vazio)';
        END IF;
        RETURN NEW;
    END IF;
    IF NEW.per_codigo IS DISTINCT FROM OLD.per_codigo THEN
        RAISE EXCEPTION 'O código de um perfil não se altera';
    END IF;
    IF OLD.per_codigo IS NOT NULL AND nucleo.fn_usuario_sessao() IS NOT NULL THEN
        IF NEW.per_end_date IS NOT NULL AND OLD.per_end_date IS NULL THEN
            RAISE EXCEPTION 'Os perfis do sistema não se terminam';
        END IF;
        IF NEW.per_ambito IS DISTINCT FROM OLD.per_ambito THEN
            RAISE EXCEPTION 'O âmbito de um perfil do sistema não se altera';
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_per_10_proteger BEFORE INSERT OR UPDATE ON nucleo.perfil
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_per_proteger();

-- igual à de V1, com uma diferença: o pastor do distrito reconhece-se pelo código do perfil, não pelo nome
CREATE OR REPLACE FUNCTION nucleo.fn_igrejas_com_permissao(p_codigo TEXT) RETURNS INT[]
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL THEN RETURN ARRAY[]::INT[]; END IF;
    IF nucleo.fn_e_super_admin() THEN
        RETURN ARRAY(SELECT igr_id FROM organizacao.igreja WHERE igr_end_date IS NULL);
    END IF;
    RETURN ARRAY(
        WITH perm AS (
            SELECT pp.ppe_per_id AS per_id
            FROM nucleo.permissao pm
            JOIN nucleo.perfil_permissao pp ON pp.ppe_prm_id = pm.prm_id AND pp.ppe_end_date IS NULL
            WHERE pm.prm_codigo = p_codigo AND pm.prm_end_date IS NULL
        )
        SELECT u.uig_igr_id
          FROM nucleo.usuario_igreja u JOIN perm ON perm.per_id = u.uig_per_id
         WHERE u.uig_usu_id = v_usr AND u.uig_estado = 'ACTIVO' AND u.uig_end_date IS NULL
        UNION
        SELECT i.igr_id
          FROM organizacao.distrito d
          JOIN organizacao.igreja i ON i.igr_dst_id = d.dst_id AND i.igr_end_date IS NULL
         WHERE d.dst_pastor_usu_id = v_usr AND d.dst_end_date IS NULL
           AND EXISTS (SELECT 1 FROM nucleo.perfil pf JOIN perm ON perm.per_id = pf.per_id
                        WHERE pf.per_codigo = 'PASTOR' AND pf.per_end_date IS NULL)
        UNION
        SELECT i.igr_id
          FROM nucleo.fn_entidades_com_permissao(p_codigo) e
          JOIN organizacao.igreja i ON i.igr_ent_id = e AND i.igr_end_date IS NULL);
END $$;

-- ---------------------------------------------------------------- 2. códigos de categorias e permissões
CREATE FUNCTION nucleo.fn_codigo_imutavel() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_coluna TEXT := TG_ARGV[0];
BEGIN
    IF (to_jsonb(NEW) ->> v_coluna) IS DISTINCT FROM (to_jsonb(OLD) ->> v_coluna) THEN
        RAISE EXCEPTION 'O código não se altera depois de criado (é o identificador usado pelas regras): termine este registo e crie outro';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_cat_10_codigo_fixo BEFORE UPDATE OF cat_codigo ON tesouraria.categoria
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_codigo_imutavel('cat_codigo');
CREATE TRIGGER trg_prm_10_codigo_fixo BEFORE UPDATE OF prm_codigo ON nucleo.permissao
    FOR EACH ROW EXECUTE FUNCTION nucleo.fn_codigo_imutavel('prm_codigo');

-- ---------------------------------------------------------------- 3. super-administrador
-- igual à de V2, com uma regra nova no início das alterações: o super-administrador fica como está
CREATE OR REPLACE FUNCTION nucleo.fn_usu_proteger() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
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
    -- V32: as permissões do super-administrador não se alteram (nem pelo próprio, nem por outro super-administrador)
    IF OLD.usu_super_admin AND (NEW.usu_super_admin IS DISTINCT FROM OLD.usu_super_admin
                                OR NEW.usu_estado IS DISTINCT FROM OLD.usu_estado
                                OR (NEW.usu_end_date IS NOT NULL AND OLD.usu_end_date IS NULL)) THEN
        RAISE EXCEPTION 'As permissões do super-administrador não podem ser alteradas (nem o acesso total, nem o estado)'
            USING ERRCODE = 'insufficient_privilege';
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
END $$;

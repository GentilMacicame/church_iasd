-- =====================================================================
-- V35 · Actividades da área pastoral (F-ACT, F-ORG): actividades do distrito pastoral nos calendários das igrejas
--
--   actividade   pertence OU a um departamento de uma igreja (act_ide_id: actividade local) OU a um distrito
--                pastoral (act_dst_id: área pastoral) — nunca aos dois nem a nenhum (chk_act_origem).
--   acesso       actividades.fn_acesso_distrito(distrito, permissão):
--                  ler     → quem tem a permissão numa igreja do distrito (aparecem no calendário de todas elas);
--                  criar, alterar, terminar → o pastor do distrito (perfil PASTOR com a permissão), quem a tem ao
--                            nível da Associação/Missão do distrito, ou o super-administrador.
--                Um director de departamento de uma igreja não cria nem altera actividades do distrito.
--   políticas    actividade, material e actividade_responsavel: a regra local de antes OU a do distrito.
--   regras       responsável de uma actividade do distrito: membro de uma igreja do distrito.
--   conflitos    as actividades do distrito contam nos conflitos de cada igreja do distrito.
--   programa     vw_actividades_execucao inclui, para cada igreja, as actividades do seu distrito, com a origem
--                (IGREJA ou AREA_PASTORAL) e o distrito (colunas novas no fim).
--
-- Gerado com database/gerador (defs.py, seguranca_gen.py: marcador {C}); as regras são escritas aqui.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- acesso às actividades de um distrito
CREATE FUNCTION actividades.fn_acesso_distrito(p_dst INT, p_codigo TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_usr INT := nucleo.fn_usuario_sessao();
BEGIN
    IF v_usr IS NULL OR p_dst IS NULL THEN RETURN FALSE; END IF;
    IF nucleo.fn_e_super_admin() THEN RETURN TRUE; END IF;
    -- ler: as igrejas do distrito vêem as actividades da área pastoral
    IF p_codigo LIKE '%.ler' AND EXISTS (
        SELECT 1 FROM organizacao.igreja i
         WHERE i.igr_dst_id = p_dst AND i.igr_end_date IS NULL
           AND i.igr_id = ANY (nucleo.fn_igrejas_com_permissao(p_codigo))) THEN
        RETURN TRUE;
    END IF;
    -- o pastor do distrito (se o perfil PASTOR tiver a permissão)
    IF EXISTS (SELECT 1 FROM organizacao.distrito d
                WHERE d.dst_id = p_dst AND d.dst_end_date IS NULL AND d.dst_pastor_usu_id = v_usr)
       AND EXISTS (SELECT 1 FROM nucleo.perfil pf
                     JOIN nucleo.perfil_permissao pp ON pp.ppe_per_id = pf.per_id AND pp.ppe_end_date IS NULL
                     JOIN nucleo.permissao pm ON pm.prm_id = pp.ppe_prm_id AND pm.prm_end_date IS NULL
                    WHERE pf.per_codigo = 'PASTOR' AND pf.per_end_date IS NULL AND pm.prm_codigo = p_codigo) THEN
        RETURN TRUE;
    END IF;
    -- quem tem a permissão ao nível da Associação/Missão do distrito
    RETURN EXISTS (SELECT 1 FROM organizacao.distrito d
                    WHERE d.dst_id = p_dst AND d.dst_ent_id IN (SELECT nucleo.fn_entidades_com_permissao(p_codigo)));
END $$;
COMMENT ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) IS
    'V35: acesso às actividades da área pastoral (ler: igrejas do distrito; escrever: pastor do distrito, Associação, super-administrador)';
REVOKE ALL ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION actividades.fn_acesso_distrito(INT, TEXT) TO app_igreja;

-- ---------------------------------------------------------------- actividade: local ou da área pastoral
ALTER TABLE actividades.actividade ALTER COLUMN act_ide_id DROP NOT NULL;
ALTER TABLE actividades.actividade ADD COLUMN act_dst_id INT;
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_dst_id FOREIGN KEY (act_dst_id) REFERENCES organizacao.distrito(dst_id);
ALTER TABLE actividades.actividade ADD CONSTRAINT chk_act_origem CHECK ((act_ide_id IS NULL) <> (act_dst_id IS NULL));
COMMENT ON COLUMN actividades.actividade.act_ide_id IS 'Departamento da igreja (actividade local); vazio nas da área pastoral (V35)';
COMMENT ON COLUMN actividades.actividade.act_dst_id IS 'Distrito pastoral: actividade da área pastoral, nos calendários de todas as igrejas do distrito (V35)';
COMMENT ON CONSTRAINT chk_act_origem ON actividades.actividade IS
    'A actividade é de um departamento da igreja ou da área pastoral (distrito), não das duas nem de nenhuma.';
CREATE INDEX idx_act_dst_id ON actividades.actividade (act_dst_id);

-- ---------------------------------------------------------------- políticas (geradas: gen.py)
DROP POLICY pol_act_ler ON actividades.actividade;
DROP POLICY pol_act_criar ON actividades.actividade;
DROP POLICY pol_act_alterar ON actividades.actividade;
DROP POLICY pol_mat_ler ON actividades.material;
DROP POLICY pol_mat_criar ON actividades.material;
DROP POLICY pol_mat_alterar ON actividades.material;
DROP POLICY pol_acr_ler ON actividades.actividade_responsavel;
DROP POLICY pol_acr_criar ON actividades.actividade_responsavel;
DROP POLICY pol_acr_alterar ON actividades.actividade_responsavel;
CREATE POLICY pol_act_ler ON actividades.actividade FOR SELECT USING ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.ler'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.ler')));
CREATE POLICY pol_act_criar ON actividades.actividade FOR INSERT WITH CHECK ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.criar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.criar')));
CREATE POLICY pol_act_alterar ON actividades.actividade FOR UPDATE USING ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.alterar'))) WITH CHECK ((act_ide_id IS NOT NULL AND EXISTS (SELECT 1 FROM organizacao.igreja_departamento d WHERE d.ide_id = act_ide_id AND d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade.alterar'))::INT[])))) OR (act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(act_dst_id, 'actividades.actividade.alterar')));
CREATE POLICY pol_mat_ler ON actividades.material FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.ler'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.ler')))));
CREATE POLICY pol_mat_criar ON actividades.material FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.criar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.criar')))));
CREATE POLICY pol_mat_alterar ON actividades.material FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.alterar'))))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = mat_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.material.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.material.alterar')))));
CREATE POLICY pol_acr_ler ON actividades.actividade_responsavel FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.ler'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.ler')))));
CREATE POLICY pol_acr_criar ON actividades.actividade_responsavel FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.criar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.criar')))));
CREATE POLICY pol_acr_alterar ON actividades.actividade_responsavel FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.alterar'))))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.actividade a LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = acr_act_id AND (d.ide_igr_id = ANY (((SELECT nucleo.fn_igrejas_com_permissao('actividades.actividade_responsavel.alterar'))::INT[])) OR (a.act_dst_id IS NOT NULL AND actividades.fn_acesso_distrito(a.act_dst_id, 'actividades.actividade_responsavel.alterar')))));

-- ---------------------------------------------------------------- responsável: membro da igreja (ou do distrito)
CREATE OR REPLACE FUNCTION actividades.fn_acr_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_ide INT;
    v_dst INT;
    v_igr_mem INT;
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.acr_act_id, NEW.acr_mem_id) IS NOT DISTINCT FROM (OLD.acr_act_id, OLD.acr_mem_id) THEN
        RETURN NEW;
    END IF;
    SELECT act_ide_id, act_dst_id INTO v_ide, v_dst FROM actividades.actividade WHERE act_id = NEW.acr_act_id;
    SELECT mem_igr_id INTO v_igr_mem FROM secretaria.membro WHERE mem_id = NEW.acr_mem_id;
    IF v_dst IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM organizacao.igreja WHERE igr_id = v_igr_mem AND igr_dst_id = v_dst) THEN
            RAISE EXCEPTION 'O responsável tem de ser membro de uma igreja do distrito' USING COLUMN = 'acr_mem_id';
        END IF;
    ELSIF v_igr_mem IS DISTINCT FROM (SELECT ide_igr_id FROM organizacao.igreja_departamento WHERE ide_id = v_ide) THEN
        RAISE EXCEPTION 'O responsável tem de ser membro da igreja da actividade' USING COLUMN = 'acr_mem_id';
    END IF;
    RETURN NEW;
END $$;

-- ---------------------------------------------------------------- conflitos: também as actividades do distrito
CREATE OR REPLACE FUNCTION actividades.fn_conflitos_actividade(p_igr INT, p_inicio TIMESTAMPTZ, p_fim TIMESTAMPTZ DEFAULT NULL,
                                                              p_excluir_act_id INT DEFAULT NULL)
RETURNS TABLE (act_id INT, nome TEXT, departamento TEXT, data_inicio TIMESTAMPTZ, data_fim TIMESTAMPTZ, local TEXT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT a.act_id, a.act_nome::TEXT,
           coalesce(dp.dep_nome, 'Área pastoral (' || ds.dst_nome || ')')::TEXT,
           a.act_data_inicio, a.act_data_fim, a.act_local::TEXT
      FROM actividades.actividade a
      LEFT JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      LEFT JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
      LEFT JOIN organizacao.distrito ds ON ds.dst_id = a.act_dst_id
     WHERE (d.ide_igr_id = p_igr
            OR a.act_dst_id = (SELECT i.igr_dst_id FROM organizacao.igreja i WHERE i.igr_id = p_igr))
       AND a.act_end_date IS NULL AND a.act_estado <> 'CANCELADA'
       AND a.act_id IS DISTINCT FROM p_excluir_act_id
       AND a.act_data_inicio < coalesce(p_fim, p_inicio + INTERVAL '2 hours')
       AND p_inicio < coalesce(a.act_data_fim, a.act_data_inicio + INTERVAL '2 hours')
     ORDER BY a.act_data_inicio
$$;

-- ---------------------------------------------------------------- programa: locais e da área pastoral
-- Mesmas colunas de V34 e, no fim, a origem e o distrito. As do distrito aparecem em cada igreja do distrito.
CREATE OR REPLACE VIEW actividades.vw_actividades_execucao WITH (security_invoker = true) AS
WITH base AS (
    SELECT a.*, d.ide_igr_id AS igreja_id, dp.dep_nome AS departamento, 'IGREJA'::TEXT AS origem, NULL::INT AS distrito_id, NULL::TEXT AS distrito
      FROM actividades.actividade a
      JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id
      JOIN organizacao.departamento dp ON dp.dep_id = d.ide_dep_id
     WHERE a.act_end_date IS NULL
    UNION ALL
    SELECT a.*, i.igr_id, 'Área pastoral', 'AREA_PASTORAL', ds.dst_id, ds.dst_nome::TEXT
      FROM actividades.actividade a
      JOIN organizacao.distrito ds ON ds.dst_id = a.act_dst_id
      JOIN organizacao.igreja i ON i.igr_dst_id = ds.dst_id AND i.igr_end_date IS NULL
     WHERE a.act_end_date IS NULL
)
SELECT a.act_id, a.igreja_id, a.act_ide_id AS departamento_igreja_id, a.departamento::VARCHAR(100) AS departamento,
       a.act_nome AS nome, a.act_descricao AS descricao, a.act_objectivos AS objectivos, a.act_local AS local,
       a.act_data_inicio AS data_inicio, a.act_data_fim AS data_fim, a.act_estado AS estado,
       EXTRACT(YEAR FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT  AS ano,
       EXTRACT(MONTH FROM a.act_data_inicio AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       a.act_responsavel_mem_id AS responsavel_mem_id,
       (SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = a.act_responsavel_mem_id) AS responsavel,
       (SELECT count(*) FROM actividades.actividade_responsavel r WHERE r.acr_act_id = a.act_id AND r.acr_end_date IS NULL)::INT AS outros_responsaveis,
       a.act_valor_previsto AS valor_previsto,
       coalesce((SELECT sum(x.mat_quantidade * x.mat_preco_unitario) FROM actividades.material x
                  WHERE x.mat_act_id = a.act_id AND x.mat_end_date IS NULL), 0)::DECIMAL(14,2) AS material_previsto,
       coalesce((SELECT sum(x.des_valor_solicitado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('SUBMETIDA', 'APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_pedidas,
       coalesce((SELECT sum(x.des_valor_aprovado) FROM tesouraria.despesa x
                  WHERE x.des_act_id = a.act_id AND x.des_end_date IS NULL AND x.des_estado IN ('APROVADA', 'PAGA')), 0)::DECIMAL(14,2) AS despesas_aprovadas,
       coalesce((SELECT sum(CASE WHEN t.tra_tipo = 'SAIDA' THEN l.tli_valor ELSE -l.tli_valor END)
                   FROM tesouraria.transacao_linha l JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id
                  WHERE l.tli_act_id = a.act_id AND l.tli_end_date IS NULL AND t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA'
                    AND (t.tra_tipo = 'SAIDA' OR (t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NOT NULL))), 0)::DECIMAL(14,2) AS executado,
       a.origem, a.distrito_id, a.distrito
FROM base a;

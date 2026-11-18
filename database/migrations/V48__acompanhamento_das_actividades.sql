-- =====================================================================
-- V48 · Acompanhamento das actividades (F-ACT): o motivo do cancelamento
--
--   actividade.act_motivo_cancelamento   obrigatório ao cancelar (o trigger recusa cancelar sem ele): as canceladas
--                                        ficam explicadas no acompanhamento da igreja e da área pastoral.
--   vw_actividades_execucao              ganha motivo_cancelamento e actualizada_em (colunas no fim).
-- Nada se apaga: as canceladas antes desta versão ficam sem motivo.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE actividades.actividade ADD COLUMN act_motivo_cancelamento VARCHAR(255);
COMMENT ON COLUMN actividades.actividade.act_motivo_cancelamento IS 'Porque foi cancelada (obrigatório ao cancelar; V48)';

CREATE FUNCTION actividades.fn_act_cancelar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.act_estado::TEXT = 'CANCELADA' AND OLD.act_estado::TEXT <> 'CANCELADA'
       AND coalesce(trim(NEW.act_motivo_cancelamento), '') = '' THEN
        RAISE EXCEPTION 'Diga porque a actividade é cancelada' USING COLUMN = 'act_motivo_cancelamento';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_act_20_cancelar BEFORE UPDATE OF act_estado ON actividades.actividade
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_act_cancelar();

-- ---------------------------------------------------------------- o programa com o motivo e a última mudança
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
       a.origem, a.distrito_id, a.distrito,
       -- V48: porque foi cancelada e quando mudou pela última vez (acompanhamento)
       a.act_motivo_cancelamento AS motivo_cancelamento, a.act_modificado_em AS actualizada_em
FROM base a;

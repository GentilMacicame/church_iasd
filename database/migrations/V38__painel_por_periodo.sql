-- =====================================================================
-- V38 · Dashboard geral por período (F-ORG, P-13): membros activos e inactivos, dízimos, ofertas, obra de
--       reavivamento, fidelidade contributiva e movimento de membros, igreja a igreja
--
--   fundo        novo tipo REAVIVAMENTO: fundo próprio da igreja (100% da igreja) para a obra de reavivamento, com
--                alvo anual (V36: +5%). Assim soma-se e compara-se entre igrejas.
--   período      organizacao.fn_painel_periodo(início, fim): uma linha por igreja visível (RLS), no período escolhido:
--                  membros        estado ACTIVO no livro;
--                  inactivos      membros sem presença na ES nem contribuição há 6 meses (V36); activos = o resto;
--                  dízimos        entradas confirmadas no fundo DIZIMO (também as pagas directamente na Missão);
--                  ofertas        as outras entradas confirmadas, menos o reavivamento (sem estornos);
--                  reavivamento   entradas no fundo REAVIVAMENTO;
--                  contribuintes  membros ACTIVO que contribuíram (eles ou a família) no período: fidelidade =
--                                 contribuintes / membros;
--                  entradas e perdas de membros no livro (baptismo, profissão de fé, transferência; transferência,
--                  falecimento, remoção, desaparecido).
--                SECURITY INVOKER: cada número só conta o que o utilizador pode ler (ve_membros, ve_tesouraria dizem
--                se pode, para o ecrã mostrar "sem acesso" em vez de zero).
--   mensal       vw_painel_igrejas_mensal ganha as ofertas e o reavivamento (colunas no fim).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- O valor novo não se usa nesta transacção (só como texto): o db-migrar aplica cada migração numa transacção.
ALTER TYPE nucleo.tipo_fundo_t ADD VALUE IF NOT EXISTS 'REAVIVAMENTO';

ALTER TABLE tesouraria.fundo DROP CONSTRAINT chk_fun_da_igreja;
ALTER TABLE tesouraria.fundo ADD CONSTRAINT chk_fun_da_igreja
    CHECK (fun_igr_id IS NULL OR (fun_percentagem_remessa = 0 AND fun_destino_ent_id IS NULL
                                  AND fun_tipo::TEXT IN ('OFERTA_ESPECIAL', 'PROJECTO', 'REAVIVAMENTO')));
COMMENT ON CONSTRAINT chk_fun_da_igreja ON tesouraria.fundo IS
    '[tipo] Um fundo próprio da igreja é uma oferta especial, um projecto ou a obra de reavivamento, e fica todo na igreja.';

-- ---------------------------------------------------------------- painel por período
CREATE FUNCTION organizacao.fn_painel_periodo(p_inicio DATE, p_fim DATE)
RETURNS TABLE (igr_id INT, nome TEXT, entidade_id INT, entidade TEXT, distrito_pastoral_id INT, distrito_pastoral TEXT,
               ve_membros BOOLEAN, ve_tesouraria BOOLEAN,
               membros INT, activos INT, inactivos INT, interessados INT,
               dizimos DECIMAL(14,2), ofertas DECIMAL(14,2), reavivamento DECIMAL(14,2), contribuintes INT,
               entradas_membros INT, perdas_membros INT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH per AS (
        SELECT (p_inicio::timestamp AT TIME ZONE 'Africa/Maputo') AS de,
               ((p_fim + 1)::timestamp AT TIME ZONE 'Africa/Maputo') AS ate
    ),
    acesso AS (
        SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.ler')   AS membros,
               nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler') AS tesouraria
    ),
    mem AS (
        SELECT m.mem_igr_id AS igr_id,
               count(*) FILTER (WHERE m.mem_estado = 'ACTIVO')      AS membros,
               count(*) FILTER (WHERE m.mem_estado = 'INTERESSADO') AS interessados
          FROM secretaria.membro m WHERE m.mem_end_date IS NULL GROUP BY 1
    ),
    linhas AS (
        SELECT t.tra_igr_id AS igr_id, t.tra_mem_id, t.tra_fam_id, f.fun_tipo::TEXT AS tipo, l.tli_valor AS valor
          FROM tesouraria.transacao t
          JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
          JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id, per
         WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
           AND t.tra_data_hora >= per.de AND t.tra_data_hora < per.ate
    ),
    din AS (
        SELECT igr_id,
               sum(valor) FILTER (WHERE tipo = 'DIZIMO') AS dizimos,
               sum(valor) FILTER (WHERE tipo NOT IN ('DIZIMO', 'REAVIVAMENTO')) AS ofertas,
               sum(valor) FILTER (WHERE tipo = 'REAVIVAMENTO') AS reavivamento
          FROM linhas GROUP BY 1
    ),
    contrib AS (
        SELECT m.mem_igr_id AS igr_id, count(DISTINCT m.mem_id) AS contribuintes
          FROM secretaria.membro m
         WHERE m.mem_end_date IS NULL AND m.mem_estado = 'ACTIVO'
           AND EXISTS (SELECT 1 FROM linhas x WHERE x.tra_mem_id = m.mem_id OR (m.mem_fam_id IS NOT NULL AND x.tra_fam_id = m.mem_fam_id))
         GROUP BY 1
    ),
    livro AS (
        SELECT l.mmb_igr_id AS igr_id,
               count(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA')) AS entradas,
               count(*) FILTER (WHERE l.mmb_tipo IN ('TRANSFERENCIA_SAIDA', 'FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS perdas
          FROM secretaria.movimento_membro l
         WHERE l.mmb_end_date IS NULL AND l.mmb_data BETWEEN p_inicio AND p_fim
         GROUP BY 1
    )
    SELECT i.igr_id, i.igr_nome::TEXT, i.igr_ent_id, e.ent_nome::TEXT, i.igr_dst_id, d.dst_nome::TEXT,
           i.igr_id = ANY (a.membros), i.igr_id = ANY (a.tesouraria),
           coalesce(m.membros, 0)::INT,
           (coalesce(m.membros, 0) - coalesce(ina.n, 0))::INT,
           coalesce(ina.n, 0)::INT,
           coalesce(m.interessados, 0)::INT,
           coalesce(dn.dizimos, 0)::DECIMAL(14,2), coalesce(dn.ofertas, 0)::DECIMAL(14,2), coalesce(dn.reavivamento, 0)::DECIMAL(14,2),
           coalesce(c.contribuintes, 0)::INT,
           coalesce(lv.entradas, 0)::INT, coalesce(lv.perdas, 0)::INT
      FROM organizacao.igreja i
      CROSS JOIN acesso a
      JOIN organizacao.entidade e ON e.ent_id = i.igr_ent_id
      LEFT JOIN organizacao.distrito d ON d.dst_id = i.igr_dst_id
      LEFT JOIN mem m ON m.igr_id = i.igr_id
      LEFT JOIN din dn ON dn.igr_id = i.igr_id
      LEFT JOIN contrib c ON c.igr_id = i.igr_id
      LEFT JOIN livro lv ON lv.igr_id = i.igr_id
      LEFT JOIN LATERAL (SELECT count(*) AS n FROM secretaria.fn_participacao_membros(i.igr_id) p WHERE p.inactivo) ina ON i.igr_id = ANY (a.membros)
     WHERE i.igr_end_date IS NULL
     ORDER BY i.igr_nome
$$;
COMMENT ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) IS
    'V38: dashboard por igreja visível no período (membros, activos, inactivos, dízimos, ofertas, reavivamento, contribuintes, entradas e perdas)';
REVOKE ALL ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION organizacao.fn_painel_periodo(DATE, DATE) TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses: também ofertas e reavivamento
CREATE OR REPLACE VIEW organizacao.vw_painel_igrejas_mensal WITH (security_invoker = true) AS
WITH meses AS (
    SELECT g::date AS ini, (g + INTERVAL '1 month')::date AS fim,
           EXTRACT(YEAR FROM g)::INT AS ano, EXTRACT(MONTH FROM g)::INT AS mes
    FROM generate_series(date_trunc('month', now() AT TIME ZONE 'Africa/Maputo') - INTERVAL '11 months',
                         date_trunc('month', now() AT TIME ZONE 'Africa/Maputo'), INTERVAL '1 month') g
),
desde AS (SELECT (MIN(ini)::timestamp AT TIME ZONE 'Africa/Maputo') AS t, MIN(ini) AS d FROM meses),
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA') AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
fundos AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimos,
           COUNT(DISTINCT t.tra_mem_id) FILTER (WHERE f.fun_tipo::TEXT = 'DIZIMO') AS dizimistas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT NOT IN ('DIZIMO', 'REAVIVAMENTO')) AS ofertas,
           SUM(l.tli_valor) FILTER (WHERE f.fun_tipo::TEXT = 'REAVIVAMENTO') AS reavivamento
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id, desde
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= desde.t
    GROUP BY 1, 2, 3
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id, EXTRACT(YEAR FROM l.mmb_data)::INT AS ano, EXTRACT(MONTH FROM l.mmb_data)::INT AS mes,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transf_entrada,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transf_saida
    FROM secretaria.movimento_membro l, desde
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= desde.d
    GROUP BY 1, 2, 3
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id, ms.ano, ms.mes,
       COALESCE(dn.entradas, 0) AS entradas, COALESCE(dn.saidas, 0) AS saidas,
       COALESCE(z.dizimos, 0) AS dizimos, COALESCE(z.dizimistas, 0) AS dizimistas,
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida,
       COALESCE(z.ofertas, 0) AS ofertas, COALESCE(z.reavivamento, 0) AS reavivamento
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN fundos z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;

-- =====================================================================
-- V46 · Painel dos membros por igreja (F-ORG, pontos 9, 12 e 16): a composição dos membros para o Painel geral
--
--   organizacao.vw_painel_membros   por igreja visível: membros (no livro como activos), interessados, sexo, faixas
--                                   etárias, estado civil (casados, união de facto, solteiros, viúvos, viúvas,
--                                   divorciados, noivos, sem estado civil) e membros sem família.
--   vw_painel_igrejas_mensal        ganha outras_saidas (falecimento, remoção, desaparecido) em cada mês: o gráfico das
--                                   entradas e saídas de membros passa a bater com as perdas do período.
-- SECURITY INVOKER: cada utilizador só conta os membros das igrejas que pode ver (RLS de secretaria.membro).
-- Os nomes das colunas não começam por três letras e "_" (a API tiraria esse "prefixo").
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE VIEW organizacao.vw_painel_membros WITH (security_invoker = true) AS
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO')                                       AS membros,
       count(*) FILTER (WHERE m.mem_estado = 'INTERESSADO')                                  AS interessados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'M')                  AS homens,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'F')                  AS mulheres,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_fam_id IS NULL)              AS activos_sem_familia,
       -- faixas etárias (membros com a data de nascimento)
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) <  INTERVAL '18 years') AS menores,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '18 years'
                                                   AND age(m.mem_data_nascimento) <  INTERVAL '36 years') AS jovens,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '36 years'
                                                   AND age(m.mem_data_nascimento) <  INTERVAL '60 years') AS adultos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND age(m.mem_data_nascimento) >= INTERVAL '60 years') AS idosos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_data_nascimento IS NULL)    AS idade_desconhecida,
       -- estado civil
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'CASADO')      AS casados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'UNIAO_FACTO') AS uniao_facto,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'SOLTEIRO')    AS solteiros,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'VIUVO' AND m.mem_sexo = 'M') AS viuvos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'VIUVO' AND m.mem_sexo = 'F') AS viuvas,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'DIVORCIADO')  AS divorciados,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil::TEXT = 'NOIVO')       AS noivos,
       count(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_estado_civil IS NULL)               AS estado_civil_vazio
FROM organizacao.igreja i
JOIN secretaria.membro m ON m.mem_igr_id = i.igr_id AND m.mem_end_date IS NULL
WHERE i.igr_end_date IS NULL
GROUP BY i.igr_id, i.igr_nome, i.igr_ent_id, i.igr_dst_id;
COMMENT ON VIEW organizacao.vw_painel_membros IS
    'Composição dos membros por igreja visível: sexo, idades, estado civil e sem família (V46); RLS de secretaria.membro';
GRANT SELECT ON organizacao.vw_painel_membros TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses: também as outras saídas do livro
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
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transf_saida,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS outras_saidas
    FROM secretaria.movimento_membro l, desde
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= desde.d
    GROUP BY 1, 2, 3
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_ent_id AS entidade_id, i.igr_dst_id AS distrito_pastoral_id, ms.ano, ms.mes,
       COALESCE(dn.entradas, 0) AS entradas, COALESCE(dn.saidas, 0) AS saidas,
       COALESCE(z.dizimos, 0) AS dizimos, COALESCE(z.dizimistas, 0) AS dizimistas,
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida,
       COALESCE(z.ofertas, 0) AS ofertas, COALESCE(z.reavivamento, 0) AS reavivamento,
       -- V46: as outras saídas do livro (falecimento, remoção, desaparecido), para o gráfico bater com as perdas
       COALESCE(l.outras_saidas, 0) AS outras_saidas
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN fundos z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;

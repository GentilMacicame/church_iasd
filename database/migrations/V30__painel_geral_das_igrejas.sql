-- V30 · Painel geral das igrejas (direcção: Associação/Missão, pastor do distrito, super-administrador)
--
-- Uma linha por igreja com os indicadores-chave (membros, transferências, dizimistas, situação financeira) e a série
-- dos últimos 12 meses, para comparar as igrejas. As vistas correm com os direitos de quem consulta
-- (security_invoker): cada utilizador só vê as igrejas a que tem acesso. O pastor do distrito tem o perfil PASTOR
-- em todas as igrejas do seu distrito (nucleo.fn_igrejas_com_permissao), por isso vê só essas; a Associação vê as
-- suas; o super-administrador, todas. Nada se calcula na API: a base de dados decide quem vê o quê.
--
-- Os números de cada área só contam onde o utilizador as pode ler; ve_membros e ve_tesouraria dizem se pode
-- (para o ecrã mostrar "sem acesso" em vez de zero).

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- indicadores por igreja
CREATE VIEW organizacao.vw_painel_igrejas WITH (security_invoker = true) AS
WITH ref AS (
    SELECT date_trunc('year',  now() AT TIME ZONE 'Africa/Maputo')::date AS ini_ano,
           date_trunc('month', now() AT TIME ZONE 'Africa/Maputo')::date AS ini_mes
),
acesso AS (
    SELECT (SELECT nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'))   AS membros,
           (SELECT nucleo.fn_igrejas_com_permissao('tesouraria.transacao.ler')) AS tesouraria
),
membros AS (
    SELECT m.mem_igr_id AS igr_id,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO')                       AS activos,
           COUNT(*) FILTER (WHERE m.mem_estado = 'INTERESSADO')                  AS interessados,
           COUNT(*) FILTER (WHERE m.mem_estado = 'TRANSFERIDO')                  AS transferidos,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'F')  AS mulheres,
           COUNT(*) FILTER (WHERE m.mem_estado = 'ACTIVO' AND m.mem_sexo = 'M')  AS homens
    FROM secretaria.membro m
    WHERE m.mem_end_date IS NULL
    GROUP BY 1
),
livro AS (
    SELECT l.mmb_igr_id AS igr_id,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE')) AS admissoes_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_ENTRADA')                    AS transf_entrada_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo = 'TRANSFERENCIA_SAIDA')                      AS transf_saida_ano,
           COUNT(*) FILTER (WHERE l.mmb_tipo IN ('FALECIMENTO', 'REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO', 'DESAPARECIDO')) AS outras_saidas_ano
    FROM secretaria.movimento_membro l, ref
    WHERE l.mmb_end_date IS NULL AND l.mmb_data >= ref.ini_ano
    GROUP BY 1
),
pendentes AS (
    SELECT t.tme_origem_igr_id AS igr_id, COUNT(*) AS transf_pendentes
    FROM secretaria.transferencia_membro t
    WHERE t.tme_end_date IS NULL AND t.tme_estado IN ('PEDIDA', 'CARTA_EMITIDA')
    GROUP BY 1
),
-- dinheiro da igreja: entradas e saídas confirmadas nas contas da igreja (não a conta da Missão)
dinheiro AS (
    SELECT t.tra_igr_id AS igr_id,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA' AND t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS entradas_mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA'   AND t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS saidas_mes,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'ENTRADA') AS entradas_ano,
           SUM(t.tra_valor_total) FILTER (WHERE t.tra_tipo = 'SAIDA')   AS saidas_ano
    FROM tesouraria.transacao t
    JOIN tesouraria.conta_financeira c ON c.cfi_id = t.tra_cfi_id AND c.cfi_ent_id IS NULL, ref
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo IN ('ENTRADA', 'SAIDA')
      AND t.tra_data_hora >= (ref.ini_ano::timestamp AT TIME ZONE 'Africa/Maputo')
    GROUP BY 1
),
-- dizimistas: membros (e famílias) com dízimo confirmado este ano, também os pagos directamente na Missão
dizimo AS (
    SELECT t.tra_igr_id AS igr_id,
           COUNT(DISTINCT t.tra_mem_id) AS dizimistas,
           COUNT(DISTINCT t.tra_fam_id) AS familias_dizimistas,
           SUM(l.tli_valor) AS dizimos_ano,
           SUM(l.tli_valor) FILTER (WHERE t.tra_data_hora >= (ref.ini_mes::timestamp AT TIME ZONE 'Africa/Maputo')) AS dizimos_mes
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo = 'DIZIMO', ref
    WHERE t.tra_end_date IS NULL AND t.tra_estado = 'CONFIRMADA' AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
      AND t.tra_data_hora >= (ref.ini_ano::timestamp AT TIME ZONE 'Africa/Maputo')
    GROUP BY 1
),
saldo AS (
    SELECT s.cfi_igr_id AS igr_id, SUM(s.saldo) AS saldo
    FROM tesouraria.vw_saldo_conta s
    WHERE s.entidade_id IS NULL
    GROUP BY 1
),
-- o que falta depositar na conta da Missão, dos meses já terminados
remeter AS (
    SELECT d.igr_id, SUM(GREATEST(d.em_falta, 0)) AS por_remeter
    FROM tesouraria.vw_remessa_devida d, ref
    WHERE make_date(d.ano, d.mes, 1) < ref.ini_mes
    GROUP BY 1
)
SELECT i.igr_id, i.igr_nome AS nome, i.igr_tipo AS tipo, i.igr_ent_id AS entidade_id, e.ent_nome AS entidade,
       i.igr_dst_id AS distrito_pastoral_id, d.dst_nome AS distrito_pastoral, p.prv_nome AS provincia,
       (i.igr_id = ANY (a.membros))    AS ve_membros,
       (i.igr_id = ANY (a.tesouraria)) AS ve_tesouraria,
       COALESCE(m.activos, 0)       AS membros_activos,
       COALESCE(m.interessados, 0)  AS interessados,
       COALESCE(m.mulheres, 0)      AS mulheres,
       COALESCE(m.homens, 0)        AS homens,
       COALESCE(m.transferidos, 0)  AS transferidos,
       COALESCE(l.transf_saida_ano, 0)   AS transf_saida_ano,
       COALESCE(l.transf_entrada_ano, 0) AS transf_entrada_ano,
       COALESCE(pd.transf_pendentes, 0)  AS transf_pendentes,
       COALESCE(l.admissoes_ano, 0)      AS admissoes_ano,
       COALESCE(l.outras_saidas_ano, 0)  AS outras_saidas_ano,
       COALESCE(z.dizimistas, 0)          AS dizimistas,
       COALESCE(z.familias_dizimistas, 0) AS familias_dizimistas,
       ROUND(COALESCE(z.dizimistas, 0)::NUMERIC / NULLIF(m.activos, 0), 4) AS pct_dizimistas,
       COALESCE(z.dizimos_ano, 0) AS dizimos_ano,
       COALESCE(z.dizimos_mes, 0) AS dizimos_mes,
       COALESCE(dn.entradas_mes, 0) AS entradas_mes,
       COALESCE(dn.saidas_mes, 0)   AS saidas_mes,
       COALESCE(dn.entradas_ano, 0) AS entradas_ano,
       COALESCE(dn.saidas_ano, 0)   AS saidas_ano,
       COALESCE(dn.entradas_ano, 0) - COALESCE(dn.saidas_ano, 0) AS resultado_ano,
       COALESCE(s.saldo, 0)         AS saldo,
       COALESCE(r.por_remeter, 0)   AS por_remeter
FROM organizacao.igreja i
CROSS JOIN acesso a
JOIN organizacao.entidade e          ON e.ent_id = i.igr_ent_id
LEFT JOIN organizacao.distrito d     ON d.dst_id = i.igr_dst_id
LEFT JOIN organizacao.provincia p    ON p.prv_id = i.igr_prv_id
LEFT JOIN membros m   ON m.igr_id = i.igr_id
LEFT JOIN livro l     ON l.igr_id = i.igr_id
LEFT JOIN pendentes pd ON pd.igr_id = i.igr_id
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id
LEFT JOIN dizimo z    ON z.igr_id = i.igr_id
LEFT JOIN saldo s     ON s.igr_id = i.igr_id
LEFT JOIN remeter r   ON r.igr_id = i.igr_id
WHERE i.igr_end_date IS NULL;
COMMENT ON VIEW organizacao.vw_painel_igrejas IS
    'Painel geral: por igreja visível ao utilizador, membros, transferências, dizimistas e situação financeira do ano (V30)';
GRANT SELECT ON organizacao.vw_painel_igrejas TO app_igreja;

-- ---------------------------------------------------------------- últimos 12 meses por igreja (gráficos)
CREATE VIEW organizacao.vw_painel_igrejas_mensal WITH (security_invoker = true) AS
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
dizimo AS (
    SELECT t.tra_igr_id AS igr_id,
           EXTRACT(YEAR FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
           EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
           SUM(l.tli_valor) AS dizimos, COUNT(DISTINCT t.tra_mem_id) AS dizimistas
    FROM tesouraria.transacao t
    JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
    JOIN tesouraria.fundo f ON f.fun_id = l.tli_fun_id AND f.fun_tipo = 'DIZIMO', desde
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
       COALESCE(l.admissoes, 0) AS admissoes, COALESCE(l.transf_entrada, 0) AS transf_entrada, COALESCE(l.transf_saida, 0) AS transf_saida
FROM organizacao.igreja i
CROSS JOIN meses ms
LEFT JOIN dinheiro dn ON dn.igr_id = i.igr_id AND dn.ano = ms.ano AND dn.mes = ms.mes
LEFT JOIN dizimo z    ON z.igr_id = i.igr_id AND z.ano = ms.ano AND z.mes = ms.mes
LEFT JOIN livro l     ON l.igr_id = i.igr_id AND l.ano = ms.ano AND l.mes = ms.mes
WHERE i.igr_end_date IS NULL;
COMMENT ON VIEW organizacao.vw_painel_igrejas_mensal IS
    'Painel geral: últimos 12 meses por igreja visível (entradas, saídas, dízimos, dizimistas, admissões, transferências) (V30)';
GRANT SELECT ON organizacao.vw_painel_igrejas_mensal TO app_igreja;

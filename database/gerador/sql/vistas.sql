-- =====================================================================
-- Vistas por módulo (security_invoker: respeitam a segurança por igreja)
-- Registos com end_date não entram nas contas.
-- =====================================================================

-- ================================================================ secretaria
CREATE VIEW secretaria.vw_familia_resumo WITH (security_invoker = true) AS
SELECT f.fam_id, f.fam_igr_id, f.fam_nome,
       COUNT(m.mem_id)                                         AS membros_activos,
       COUNT(m.mem_id) FILTER (WHERE m.mem_modo_entrada IN ('BAPTISMO', 'REBAPTISMO')
                               OR EXISTS (SELECT 1 FROM secretaria.baptismo b
                                          WHERE b.bap_mem_id = m.mem_id AND b.bap_end_date IS NULL)) AS baptizados
FROM secretaria.familia f
LEFT JOIN secretaria.membro m ON m.mem_fam_id = f.fam_id AND m.mem_end_date IS NULL AND m.mem_estado = 'ACTIVO'
WHERE f.fam_end_date IS NULL
GROUP BY f.fam_id, f.fam_igr_id, f.fam_nome;

CREATE VIEW secretaria.vw_membro_basico WITH (security_invoker = true) AS
SELECT mem_id, mem_igr_id, mem_fam_id, mem_nome, mem_apelido, mem_sexo, mem_estado
FROM secretaria.membro WHERE mem_end_date IS NULL;

-- Relatório mensal do secretário à Associação/Missão: entradas e saídas do livro de membros
CREATE VIEW secretaria.vw_relatorio_mensal_membros WITH (security_invoker = true) AS
SELECT m.mmb_igr_id AS igr_id,
       EXTRACT(YEAR FROM m.mmb_data)::INT  AS ano,
       EXTRACT(MONTH FROM m.mmb_data)::INT AS mes,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'BAPTISMO')              AS baptismos,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'REBAPTISMO')            AS rebaptismos,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'PROFISSAO_FE')          AS profissoes_de_fe,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'TRANSFERENCIA_ENTRADA') AS transferencias_entrada,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'TRANSFERENCIA_SAIDA')   AS transferencias_saida,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'FALECIMENTO')           AS falecimentos,
       COUNT(*) FILTER (WHERE m.mmb_tipo IN ('REMOCAO_DISCIPLINA', 'REMOCAO_PEDIDO')) AS remocoes,
       COUNT(*) FILTER (WHERE m.mmb_tipo = 'DESAPARECIDO')          AS desaparecidos,
       COUNT(*) FILTER (WHERE m.mmb_tipo IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA'))
     - COUNT(*) FILTER (WHERE m.mmb_tipo NOT IN ('BAPTISMO', 'REBAPTISMO', 'PROFISSAO_FE', 'TRANSFERENCIA_ENTRADA')) AS variacao
FROM secretaria.movimento_membro m
WHERE m.mmb_end_date IS NULL
GROUP BY 1, 2, 3;

-- Cartas emitidas ainda por concluir (válidas 6 meses)
CREATE VIEW secretaria.vw_cartas_pendentes WITH (security_invoker = true) AS
SELECT t.tme_id, t.tme_origem_igr_id, t.tme_destino_igr_id, t.tme_destino_externo,
       m.mem_nome || ' ' || m.mem_apelido AS membro, t.tme_carta_emitida_em,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date AS valida_ate,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date < CURRENT_DATE AS expirada
FROM secretaria.transferencia_membro t
JOIN secretaria.membro m ON m.mem_id = t.tme_mem_id
WHERE t.tme_end_date IS NULL AND t.tme_estado = 'CARTA_EMITIDA';

CREATE VIEW secretaria.vw_censuras_activas WITH (security_invoker = true) AS
SELECT d.dsc_id, m.mem_igr_id, d.dsc_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       d.dsc_data_inicio, d.dsc_data_fim
FROM secretaria.disciplina d
JOIN secretaria.membro m ON m.mem_id = d.dsc_mem_id
WHERE d.dsc_end_date IS NULL AND CURRENT_DATE >= d.dsc_data_inicio AND CURRENT_DATE < d.dsc_data_fim;

-- Mandatos que terminam nos próximos 60 dias (para a comissão de nomeações)
CREATE VIEW secretaria.vw_mandatos_a_terminar WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, c.car_nome AS cargo, m.mem_nome || ' ' || m.mem_apelido AS membro,
       o.ofi_data_inicio, COALESCE(o.ofi_fim_previsto, (o.ofi_data_inicio + make_interval(years => c.car_mandato_anos))::date) AS fim_previsto
FROM secretaria.oficial o
JOIN organizacao.cargo c ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m ON m.mem_id = o.ofi_mem_id
WHERE o.ofi_end_date IS NULL AND o.ofi_data_fim IS NULL
  AND COALESCE(o.ofi_fim_previsto, (o.ofi_data_inicio + make_interval(years => c.car_mandato_anos))::date) < CURRENT_DATE + 60;

-- Conselho da igreja: os oficiais (com cargo do conselho ou não), o contacto principal e o estado do mandato
CREATE VIEW secretaria.vw_conselho WITH (security_invoker = true) AS
SELECT o.ofi_id, o.ofi_igr_id, o.ofi_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       c.car_id AS cargo_id, c.car_nome AS cargo, c.car_conselho AS do_conselho,
       o.ofi_data_inicio, o.ofi_fim_previsto, o.ofi_data_fim,
       (SELECT ct.cto_valor FROM secretaria.contacto ct
         WHERE ct.cto_mem_id = o.ofi_mem_id AND ct.cto_end_date IS NULL
         ORDER BY ct.cto_principal DESC, (ct.cto_tipo = 'TELEFONE') DESC, ct.cto_id LIMIT 1) AS contacto,
       CASE WHEN o.ofi_data_inicio > CURRENT_DATE THEN 'FUTURO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE THEN 'TERMINADO'
            WHEN COALESCE(o.ofi_data_fim, o.ofi_fim_previsto) < CURRENT_DATE + 60 THEN 'A_TERMINAR'
            ELSE 'ACTIVO' END AS estado_mandato
FROM secretaria.oficial o
JOIN organizacao.cargo c   ON c.car_id = o.ofi_car_id
JOIN secretaria.membro m   ON m.mem_id = o.ofi_mem_id
WHERE o.ofi_end_date IS NULL;


CREATE VIEW secretaria.vw_menores_pendentes WITH (security_invoker = true) AS
SELECT m.mem_id, m.mem_igr_id, m.mem_nome, m.mem_apelido, m.mem_data_nascimento,
       (m.mem_encarregado_mem_id IS NULL) AS falta_encarregado,
       NOT EXISTS (SELECT 1 FROM secretaria.consentimento c
                   WHERE c.cns_mem_id = m.mem_id AND c.cns_end_date IS NULL
                     AND c.cns_tipo = 'DADOS_PESSOAIS' AND c.cns_concedido
                     AND c.cns_concedido_por_mem_id IS NOT NULL) AS falta_consentimento
FROM secretaria.membro m
WHERE m.mem_end_date IS NULL
  AND m.mem_data_nascimento > CURRENT_DATE - INTERVAL '18 years'
  AND (m.mem_encarregado_mem_id IS NULL
       OR NOT EXISTS (SELECT 1 FROM secretaria.consentimento c
                      WHERE c.cns_mem_id = m.mem_id AND c.cns_end_date IS NULL
                        AND c.cns_tipo = 'DADOS_PESSOAIS' AND c.cns_concedido
                        AND c.cns_concedido_por_mem_id IS NOT NULL));

-- ================================================================ actividades
CREATE VIEW actividades.vw_escala_proximas WITH (security_invoker = true) AS
SELECT e.esc_id, e.esc_igr_id, e.esc_data, e.esc_funcao,
       m.mem_nome || ' ' || m.mem_apelido AS membro, e.esc_estado
FROM actividades.escala e
JOIN secretaria.membro m ON m.mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
WHERE e.esc_end_date IS NULL AND e.esc_data BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
  AND e.esc_estado IN ('PREVISTA', 'CONFIRMADA', 'SUBSTITUIDA');

-- ================================================================ escola_sabatina
CREATE VIEW escola_sabatina.vw_resumo_classe WITH (security_invoker = true) AS
SELECT ct.ect_id, ct.ect_etr_id, ct.ect_igr_id, c.ecl_nome AS classe, c.ecl_divisao AS divisao,
       (ct.ect_estado = 'ACTIVO')                                  AS activa,
       TRIM(CONCAT(p.mem_nome, ' ', p.mem_apelido))                AS professor,
       COUNT(r.ers_id)                                             AS sabados_registados,
       ROUND(AVG(r.ers_membros_matriculados), 2)                   AS media_matriculados,
       ROUND(AVG(r.ers_membros_presentes), 2)                      AS media_presentes,
       SUM(r.ers_membros_presentes)::NUMERIC / NULLIF(SUM(r.ers_membros_matriculados), 0) AS pct_presenca,
       SUM(r.ers_estudo_diario)::NUMERIC     / NULLIF(SUM(r.ers_membros_presentes), 0)    AS pct_estudo_diario,
       COALESCE(SUM(r.ers_visitantes), 0)                          AS visitantes,
       ROUND(AVG(r.ers_filiais), 2)                                AS media_filiais,
       COALESCE(SUM(r.ers_oferta), 0)                              AS ofertas,
       ct.ect_alvo_oferta_sabado * COUNT(r.ers_id)                 AS alvo_ofertas,
       COALESCE(SUM(r.ers_oferta), 0) / NULLIF(ct.ect_alvo_oferta_sabado * COUNT(r.ers_id), 0) AS pct_alvo_ofertas,
       COALESCE(SUM(r.ers_oferta_13_sabado), 0)                    AS oferta_13_sabado,
       COALESCE(SUM(r.ers_oferta_despesas), 0)                     AS oferta_despesas,
       (SELECT COUNT(*) FROM secretaria.baptismo b WHERE b.bap_ect_id = ct.ect_id AND b.bap_end_date IS NULL) AS baptismos,
       ct.ect_alvo_baptismos                                       AS alvo_baptismos,
       ct.ect_alvo_membros                                         AS alvo_membros
FROM escola_sabatina.classe_trimestre ct
JOIN escola_sabatina.classe c                ON c.ecl_id = ct.ect_ecl_id
LEFT JOIN secretaria.membro p                ON p.mem_id = ct.ect_professor_mem_id
LEFT JOIN escola_sabatina.relatorio_sabado r ON r.ers_ect_id = ct.ect_id AND r.ers_end_date IS NULL
WHERE ct.ect_end_date IS NULL AND c.ecl_end_date IS NULL
GROUP BY ct.ect_id, ct.ect_etr_id, ct.ect_igr_id, c.ecl_nome, c.ecl_divisao, ct.ect_estado, p.mem_nome, p.mem_apelido,
         ct.ect_alvo_oferta_sabado, ct.ect_alvo_baptismos, ct.ect_alvo_membros;

CREATE VIEW escola_sabatina.vw_classificacao WITH (security_invoker = true) AS
WITH pesos AS (
    SELECT t.etr_id,
           COALESCE(ct.epc_peso_presenca,   cd.epc_peso_presenca,   0.30) AS wp,
           COALESCE(ct.epc_peso_estudo,     cd.epc_peso_estudo,     0.30) AS we,
           COALESCE(ct.epc_peso_ofertas,    cd.epc_peso_ofertas,    0.25) AS wo,
           COALESCE(ct.epc_peso_visitantes, cd.epc_peso_visitantes, 0.15) AS wv,
           COALESCE(ct.epc_limite_ofertas,  cd.epc_limite_ofertas,  1.20) AS lim
    FROM escola_sabatina.trimestre t
    LEFT JOIN escola_sabatina.pontuacao_config ct ON ct.epc_etr_id = t.etr_id AND ct.epc_end_date IS NULL
    LEFT JOIN escola_sabatina.pontuacao_config cd ON cd.epc_etr_id IS NULL    AND cd.epc_end_date IS NULL
),
base AS (
    SELECT r.*, MAX(r.visitantes) OVER (PARTITION BY r.ect_etr_id, r.ect_igr_id) AS max_visitantes
    FROM escola_sabatina.vw_resumo_classe r
    WHERE r.activa AND r.sabados_registados > 0
),
pont AS (
    SELECT b.*,
           ROUND(100 * (
               p.wp * LEAST(COALESCE(b.pct_presenca, 0), 1)
             + p.we * LEAST(COALESCE(b.pct_estudo_diario, 0), 1)
             + p.wo * LEAST(COALESCE(b.pct_alvo_ofertas, 0), p.lim) / p.lim
             + p.wv * COALESCE(b.visitantes::NUMERIC / NULLIF(b.max_visitantes, 0), 0)), 1) AS pontuacao
    FROM base b JOIN pesos p ON p.etr_id = b.ect_etr_id
)
SELECT ect_id, ect_etr_id, ect_igr_id, classe, divisao, professor, pontuacao,
       RANK() OVER w                                               AS lugar,
       ROUND(pct_presenca      - AVG(pct_presenca)      OVER g, 4) AS dif_presenca_media,
       ROUND(pct_estudo_diario - AVG(pct_estudo_diario) OVER g, 4) AS dif_estudo_media,
       ROUND(ofertas - AVG(ofertas) OVER g, 2)                     AS dif_ofertas_media,
       MAX(pontuacao) OVER g - pontuacao                           AS pontos_atras_do_1o,
       CASE WHEN pontuacao >= AVG(pontuacao) OVER g THEN 'Acima da média' ELSE 'Abaixo da média' END AS situacao
FROM pont
WINDOW w AS (PARTITION BY ect_etr_id, ect_igr_id ORDER BY pontuacao DESC),
       g AS (PARTITION BY ect_etr_id, ect_igr_id);

-- Relatório trimestral (painel) por igreja
CREATE VIEW escola_sabatina.vw_painel WITH (security_invoker = true) AS
SELECT t.etr_id, t.etr_ano AS ano, t.etr_numero AS trimestre, r.ect_igr_id AS igr_id,
       COUNT(*)                            AS classes_activas,
       ROUND(SUM(r.media_matriculados), 1) AS membros,
       ROUND(AVG(r.pct_presenca), 4)       AS presenca_media,
       ROUND(AVG(r.pct_estudo_diario), 4)  AS estudo_diario_medio,
       SUM(r.ofertas)                      AS ofertas_missionarias,
       SUM(r.oferta_13_sabado)             AS oferta_13_sabado,
       SUM(r.oferta_despesas)              AS oferta_despesas,
       SUM(r.visitantes)                   AS visitantes,
       SUM(r.baptismos)                    AS baptismos,
       SUM(r.alvo_baptismos)               AS alvo_baptismos
FROM escola_sabatina.vw_resumo_classe r
JOIN escola_sabatina.trimestre t ON t.etr_id = r.ect_etr_id
WHERE r.activa AND r.sabados_registados > 0
GROUP BY t.etr_id, t.etr_ano, t.etr_numero, r.ect_igr_id;

-- Relatório trimestral consolidado por Associação/Missão e por divisão da ES
CREATE VIEW escola_sabatina.vw_relatorio_associacao WITH (security_invoker = true) AS
SELECT i.igr_ent_id AS ent_id, r.ect_etr_id AS etr_id, r.divisao,
       COUNT(DISTINCT r.ect_igr_id)        AS igrejas,
       COUNT(*)                            AS classes,
       ROUND(SUM(r.media_matriculados), 1) AS matriculados,
       ROUND(SUM(r.media_presentes), 1)    AS presentes,
       SUM(r.ofertas)                      AS ofertas_missionarias,
       SUM(r.oferta_13_sabado)             AS oferta_13_sabado,
       SUM(r.baptismos)                    AS baptismos
FROM escola_sabatina.vw_resumo_classe r
JOIN organizacao.igreja i ON i.igr_id = r.ect_igr_id
WHERE r.activa
GROUP BY 1, 2, 3;

CREATE VIEW escola_sabatina.vw_evolucao_sabado WITH (security_invoker = true) AS
SELECT ct.ect_etr_id, ct.ect_igr_id, s.esa_numero AS sabado, s.esa_data AS data, c.ecl_nome AS classe,
       r.ers_membros_presentes::NUMERIC / NULLIF(r.ers_membros_matriculados, 0) AS pct_presenca,
       r.ers_estudo_diario::NUMERIC / NULLIF(r.ers_membros_presentes, 0)        AS pct_estudo_diario,
       r.ers_oferta                                                              AS oferta,
       r.ers_oferta / NULLIF(ct.ect_alvo_oferta_sabado, 0)                       AS pct_alvo_oferta
FROM escola_sabatina.relatorio_sabado r
JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = r.ers_ect_id
JOIN escola_sabatina.classe c            ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s            ON s.esa_id = r.ers_esa_id
WHERE r.ers_end_date IS NULL AND ct.ect_estado = 'ACTIVO';

CREATE VIEW escola_sabatina.vw_relatorios_em_falta WITH (security_invoker = true) AS
SELECT ct.ect_igr_id, c.ecl_nome AS classe, s.esa_numero AS sabado, s.esa_data AS data,
       ct.ect_secretario_mem_id, ct.ect_professor_mem_id
FROM escola_sabatina.classe_trimestre ct
JOIN escola_sabatina.classe c ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s ON s.esa_etr_id = ct.ect_etr_id AND s.esa_end_date IS NULL
WHERE ct.ect_end_date IS NULL AND ct.ect_estado = 'ACTIVO' AND s.esa_data < CURRENT_DATE
  AND NOT EXISTS (SELECT 1 FROM escola_sabatina.relatorio_sabado r
                  WHERE r.ers_ect_id = ct.ect_id AND r.ers_esa_id = s.esa_id AND r.ers_end_date IS NULL);

CREATE VIEW escola_sabatina.vw_conferencia_ofertas WITH (security_invoker = true) AS
SELECT r.ers_id, r.ers_igr_id, c.ecl_nome AS classe, s.esa_data AS data,
       r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas AS oferta_relatorio,
       t.tra_valor_total AS lancado_tesouraria, t.tra_estado AS estado_lancamento,
       CASE WHEN r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas = 0 THEN 'Sem oferta'
            WHEN t.tra_id IS NULL THEN 'Por lançar'
            WHEN t.tra_estado <> 'CONFIRMADA' THEN 'Lançamento por confirmar'
            WHEN t.tra_valor_total <> r.ers_oferta + r.ers_oferta_13_sabado + r.ers_oferta_despesas THEN 'Valores diferentes'
            ELSE 'Conferido' END AS situacao
FROM escola_sabatina.relatorio_sabado r
JOIN escola_sabatina.classe_trimestre ct ON ct.ect_id = r.ers_ect_id
JOIN escola_sabatina.classe c            ON c.ecl_id = ct.ect_ecl_id
JOIN escola_sabatina.sabado s            ON s.esa_id = r.ers_esa_id
LEFT JOIN tesouraria.transacao t         ON t.tra_id = r.ers_tra_id
WHERE r.ers_end_date IS NULL;

CREATE VIEW escola_sabatina.vw_visitantes_a_anonimizar WITH (security_invoker = true) AS
SELECT v.evi_id, r.ers_igr_id, v.evi_nome, s.esa_data AS data_visita
FROM escola_sabatina.visitante v
JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = v.evi_ers_id
JOIN escola_sabatina.sabado s           ON s.esa_id = r.ers_esa_id
WHERE v.evi_end_date IS NULL AND v.evi_anonimizado_em IS NULL AND v.evi_tornou_se_mem_id IS NULL
  AND s.esa_data < CURRENT_DATE - INTERVAL '12 months';

-- ================================================================ tesouraria
-- Saldos a partir das tabelas pré-calculadas (rápido mesmo com milhões de movimentos)
CREATE VIEW tesouraria.vw_saldo_conta WITH (security_invoker = true) AS
SELECT c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda,
       c.cfi_saldo_inicial + COALESCE(SUM(s.sdc_entradas - s.sdc_saidas), 0) AS saldo,
       c.cfi_ent_id AS entidade_id
FROM tesouraria.conta_financeira c
LEFT JOIN tesouraria.saldo_diario_conta s
       ON s.sdc_cfi_id = c.cfi_id AND s.sdc_end_date IS NULL AND s.sdc_data >= c.cfi_data_saldo_inicial
WHERE c.cfi_end_date IS NULL
GROUP BY c.cfi_id, c.cfi_igr_id, c.cfi_nome, c.cfi_tipo, c.cfi_moeda, c.cfi_saldo_inicial, c.cfi_ent_id;


-- Pago directamente na conta da Missão, por igreja, entidade, mês e fundo (estornos descontam)
CREATE VIEW tesouraria.vw_pago_na_missao WITH (security_invoker = true) AS
SELECT t.tra_igr_id AS igr_id, c.cfi_ent_id AS ent_id, c.cfi_moeda AS moeda,
       EXTRACT(YEAR  FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
       EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS mes,
       l.tli_fun_id AS fun_id,
       SUM(CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END) AS pago
FROM tesouraria.conta_financeira c
JOIN tesouraria.transacao t       ON t.tra_cfi_id = c.cfi_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
WHERE c.cfi_ent_id IS NOT NULL
GROUP BY 1, 2, 3, 4, 5, 6;
COMMENT ON VIEW tesouraria.vw_pago_na_missao IS 'Contribuições pagas directamente na conta da Associação/Missão (já lá estão: contam como remetidas)';

-- Quanto se deve à Associação/Missão por mês e fundo (estornos de entradas descontam)
CREATE VIEW tesouraria.vw_remessa_devida WITH (security_invoker = true) AS
WITH recebido AS (
    SELECT s.sdf_igr_id AS igr_id, f.fun_id, f.fun_destino_ent_id AS ent_id,
           EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
           SUM(s.sdf_entradas - s.sdf_estornos_entradas) AS recebido,
           ROUND(SUM(s.sdf_entradas - s.sdf_estornos_entradas) * f.fun_percentagem_remessa / 100, 2) AS devido
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL AND f.fun_percentagem_remessa > 0
    GROUP BY 1, 2, 3, 4, 5, f.fun_percentagem_remessa
),
remetido AS (
    SELECT r.rem_igr_id AS igr_id, r.rem_ent_id AS ent_id, r.rem_ano AS ano, r.rem_mes AS mes,
           rl.rml_fun_id AS fun_id, SUM(rl.rml_valor) AS remetido
    FROM tesouraria.remessa r
    JOIN tesouraria.remessa_linha rl ON rl.rml_rem_id = r.rem_id AND rl.rml_end_date IS NULL
    WHERE r.rem_end_date IS NULL AND r.rem_estado IN ('ENVIADA', 'CONFIRMADA')
    GROUP BY 1, 2, 3, 4, 5
),
directo AS (
    SELECT igr_id, ent_id, ano, mes, fun_id, SUM(pago) AS pago_directo
    FROM tesouraria.vw_pago_na_missao GROUP BY 1, 2, 3, 4, 5
)
SELECT rc.*, COALESCE(rm.remetido, 0) AS remetido,
       rc.devido - COALESCE(rm.remetido, 0) - COALESCE(d.pago_directo, 0) AS em_falta,
       rc.fun_id AS fundo_id, f.fun_nome AS fundo_nome, f.fun_codigo AS fundo_codigo, rc.ent_id AS entidade_id,
       COALESCE(d.pago_directo, 0) AS pago_directo
FROM recebido rc
LEFT JOIN remetido rm USING (igr_id, ent_id, ano, mes, fun_id)
LEFT JOIN directo d   USING (igr_id, ent_id, ano, mes, fun_id)
JOIN tesouraria.fundo f ON f.fun_id = rc.fun_id;

-- saldo = o que está nas contas da igreja (o pago na Missão não conta); disponivel = o que a igreja pode gastar
CREATE VIEW tesouraria.vw_saldo_fundo WITH (security_invoker = true) AS
WITH base AS (
    SELECT s.sdf_igr_id AS igr_id, s.sdf_moeda AS moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito,
           f.fun_percentagem_remessa,
           SUM(s.sdf_entradas + s.sdf_estornos_saidas) AS entradas,
           SUM(s.sdf_saidas + s.sdf_estornos_entradas) AS saidas
    FROM tesouraria.saldo_diario_fundo s
    JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
    WHERE s.sdf_end_date IS NULL
    GROUP BY s.sdf_igr_id, s.sdf_moeda, f.fun_id, f.fun_codigo, f.fun_nome, f.fun_tipo, f.fun_restrito, f.fun_percentagem_remessa
),
directo AS (
    SELECT igr_id, moeda, fun_id, SUM(pago) AS pago FROM tesouraria.vw_pago_na_missao GROUP BY 1, 2, 3
),
devido AS (
    SELECT igr_id, fun_id, SUM(em_falta) AS por_remeter FROM tesouraria.vw_remessa_devida GROUP BY 1, 2
),
calc AS (
    SELECT b.*, b.entradas - b.saidas - COALESCE(d.pago, 0) AS saldo, COALESCE(d.pago, 0) AS na_associacao,
           CASE WHEN b.moeda = 'MZN' THEN COALESCE(p.por_remeter, 0) ELSE 0 END AS por_remeter
    FROM base b
    LEFT JOIN directo d ON d.igr_id = b.igr_id AND d.moeda = b.moeda AND d.fun_id = b.fun_id
    LEFT JOIN devido p  ON p.igr_id = b.igr_id AND p.fun_id = b.fun_id
)
SELECT igr_id, moeda, fun_id, fun_codigo, fun_nome, fun_tipo, fun_restrito, entradas, saidas, saldo,
       (fun_restrito AND saldo < 0) AS alerta_restrito,
       fun_id AS fundo_id, fun_percentagem_remessa AS percentagem_remessa, na_associacao, por_remeter,
       LEAST(saldo, saldo - por_remeter) AS disponivel
FROM calc;

CREATE VIEW tesouraria.vw_execucao_orcamento WITH (security_invoker = true) AS
SELECT o.orc_id, o.orc_igr_id, o.orc_ano, d.dep_nome AS departamento,
       c.cat_codigo, c.cat_nome AS categoria, c.cat_tipo,
       ol.orl_valor_previsto                         AS previsto,
       COALESCE(rl.valor, 0)                         AS realizado,
       ol.orl_valor_previsto - COALESCE(rl.valor, 0) AS diferenca,
       ROUND(COALESCE(rl.valor, 0) / NULLIF(ol.orl_valor_previsto, 0) * 100, 1) AS pct_execucao
FROM tesouraria.orcamento o
JOIN tesouraria.orcamento_linha ol ON ol.orl_orc_id = o.orc_id AND ol.orl_end_date IS NULL
JOIN tesouraria.categoria c        ON c.cat_id = ol.orl_cat_id
LEFT JOIN organizacao.igreja_departamento ide ON ide.ide_id = o.orc_ide_id
LEFT JOIN organizacao.departamento d          ON d.dep_id = ide.ide_dep_id
LEFT JOIN LATERAL (
    SELECT SUM(l.tli_valor) AS valor
    FROM tesouraria.transacao_linha l
    JOIN tesouraria.transacao t ON t.tra_id = l.tli_tra_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
    WHERE l.tli_end_date IS NULL AND l.tli_igr_id = o.orc_igr_id AND l.tli_cat_id = ol.orl_cat_id
      AND (o.orc_ide_id IS NULL OR l.tli_ide_id = o.orc_ide_id)
      AND t.tra_data_hora >= make_date(o.orc_ano, 1, 1) AND t.tra_data_hora < make_date(o.orc_ano + 1, 1, 1)
) rl ON TRUE
WHERE o.orc_end_date IS NULL;

CREATE VIEW tesouraria.vw_contagem_conferencia WITH (security_invoker = true) AS
SELECT c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado,
       COALESCE(SUM(t.tra_valor_total), 0)                       AS total_lancado,
       c.cnu_total_contado - COALESCE(SUM(t.tra_valor_total), 0) AS diferenca,
       c.cnu_estado
FROM tesouraria.contagem_numerario c
LEFT JOIN tesouraria.transacao t ON t.tra_cnu_id = c.cnu_id AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
WHERE c.cnu_end_date IS NULL
GROUP BY c.cnu_id, c.cnu_igr_id, c.cnu_data, c.cnu_ocasiao, c.cnu_total_contado, c.cnu_estado;

CREATE VIEW tesouraria.vw_despesas_por_pagar WITH (security_invoker = true) AS
SELECT d.des_id, d.des_igr_id, d.des_descricao, d.des_valor_aprovado, d.des_aprovado_em,
       CURRENT_DATE - d.des_aprovado_em::date AS dias_desde_aprovacao
FROM tesouraria.despesa d
WHERE d.des_end_date IS NULL AND d.des_estado = 'APROVADA';

CREATE VIEW tesouraria.vw_contribuicoes_membro WITH (security_invoker = true) AS
SELECT t.tra_igr_id, t.tra_mem_id, t.tra_fam_id, t.tra_id, t.tra_data_hora, t.tra_metodo,
       f.fun_nome AS fundo,
       CASE WHEN t.tra_tipo = 'ENTRADA' THEN l.tli_valor ELSE -l.tli_valor END AS valor,
       (t.tra_estorno_tra_id IS NOT NULL) AS estorno, r.rec_ano, r.rec_numero,
       EXTRACT(YEAR  FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS periodo_ano,
       EXTRACT(MONTH FROM t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS periodo_mes,
       l.tli_fun_id AS fundo_id, tesouraria.fn_conta_da_missao(t.tra_cfi_id) AS pago_na_missao, t.tra_referencia AS referencia
FROM tesouraria.transacao t
JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
JOIN tesouraria.fundo f           ON f.fun_id = l.tli_fun_id
LEFT JOIN tesouraria.recibo r     ON r.rec_tra_id = t.tra_id AND r.rec_end_date IS NULL
WHERE (t.tra_tipo = 'ENTRADA' OR t.tra_estorno_tra_id IS NOT NULL)
  AND t.tra_estado = 'CONFIRMADA' AND t.tra_end_date IS NULL
  AND (t.tra_mem_id IS NOT NULL OR t.tra_fam_id IS NOT NULL);

CREATE VIEW tesouraria.vw_extracto_anual WITH (security_invoker = true) AS
SELECT tra_igr_id, tra_mem_id, tra_fam_id,
       EXTRACT(YEAR FROM tra_data_hora AT TIME ZONE 'Africa/Maputo')::INT AS ano,
       fundo, COUNT(DISTINCT tra_id) FILTER (WHERE NOT estorno) AS entregas, SUM(valor) AS total
FROM tesouraria.vw_contribuicoes_membro
GROUP BY 1, 2, 3, 4, 5;

CREATE VIEW tesouraria.vw_progresso_alvo WITH (security_invoker = true) AS
SELECT a.alv_id, a.alv_igr_id, f.fun_nome AS fundo, a.alv_valor_alvo,
       COALESCE(SUM(s.sdf_entradas - s.sdf_estornos_entradas), 0) AS arrecadado,
       ROUND(COALESCE(SUM(s.sdf_entradas - s.sdf_estornos_entradas), 0) / a.alv_valor_alvo * 100, 1) AS percentagem
FROM tesouraria.alvo a
JOIN tesouraria.fundo f ON f.fun_id = a.alv_fun_id
LEFT JOIN tesouraria.saldo_diario_fundo s
       ON s.sdf_fun_id = a.alv_fun_id AND s.sdf_igr_id = a.alv_igr_id AND s.sdf_end_date IS NULL
      AND s.sdf_data BETWEEN a.alv_data_inicio AND a.alv_data_fim
WHERE a.alv_end_date IS NULL
GROUP BY a.alv_id, a.alv_igr_id, f.fun_nome, a.alv_valor_alvo;

CREATE VIEW tesouraria.vw_extrato_por_reconciliar WITH (security_invoker = true) AS
SELECT e.*, c.cfi_nome AS conta
FROM tesouraria.extrato_linha e
JOIN tesouraria.conta_financeira c ON c.cfi_id = e.ext_cfi_id
WHERE e.ext_end_date IS NULL AND e.ext_tra_id IS NULL;

-- ================================================================ pagamentos e comunicação
CREATE VIEW tesouraria.vw_mpesa_pendentes WITH (security_invoker = true) AS
SELECT p.pmp_id, p.pmp_tra_id, p.pmp_third_party_reference, p.pmp_pedido_em,
       p.pmp_tentativas_consulta, p.pmp_ultima_consulta_em
FROM tesouraria.pagamento_mpesa p
JOIN tesouraria.transacao t ON t.tra_id = p.pmp_tra_id
WHERE p.pmp_end_date IS NULL AND p.pmp_respondido_em IS NULL AND t.tra_estado = 'PENDENTE'
  AND p.pmp_pedido_em < now() - INTERVAL '5 minutes';

CREATE VIEW nucleo.vw_notificacoes_a_enviar WITH (security_invoker = true) AS
SELECT * FROM nucleo.notificacao
WHERE ntf_end_date IS NULL AND ntf_estado = 'PENDENTE' AND ntf_agendada_para <= now()
ORDER BY ntf_agendada_para;

-- ================================================================ escala (V17)
-- A escala como no papel afixado na igreja: um dia por linha e uma coluna por função.
-- Vista do sistema (não security_invoker) com a regra de quem vê escrita aqui: quem tem
-- actividades.escala_plano.ler nessa igreja, ou o membro da igreja se a escala estiver publicada
-- (os nomes dos escalados fazem parte da escala publicada).
CREATE VIEW actividades.vw_escala_grelha WITH (security_barrier = true) AS
SELECT p.epl_id AS plano_id, p.epl_igr_id AS igreja_id, p.epl_titulo AS titulo, p.epl_publicada AS publicada,
       d.eds_id AS dia_id, d.eds_data AS data, d.eds_evento AS evento,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'PREGADOR') AS pregador,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'TRADUTOR') AS tradutor,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_VISITAS') AS acompanhante_visitas,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_OFERTAS') AS acompanhante_ofertas,
       string_agg(m.mem_nome || ' ' || m.mem_apelido, ', ') FILTER (WHERE e.esc_funcao::text = 'ACOMPANHANTE_BOAS_VINDAS') AS acompanhante_boas_vindas,
       string_agg(actividades.fn_funcao_escala_nome(e.esc_funcao) || ': ' || m.mem_nome || ' ' || m.mem_apelido, '; ')
           FILTER (WHERE e.esc_funcao::text NOT IN ('PREGADOR', 'TRADUTOR', 'ACOMPANHANTE_VISITAS', 'ACOMPANHANTE_OFERTAS',
                                                     'ACOMPANHANTE_BOAS_VINDAS')) AS outras_funcoes,
       d.eds_grupo_coral AS grupo_coral, dep.dep_nome AS departamento, d.eds_observacoes AS observacoes
FROM actividades.escala_dia d
JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
LEFT JOIN actividades.escala e ON e.esc_eds_id = d.eds_id AND e.esc_end_date IS NULL
LEFT JOIN secretaria.membro m ON m.mem_id = COALESCE(e.esc_substituto_mem_id, e.esc_mem_id)
LEFT JOIN organizacao.igreja_departamento ide ON ide.ide_id = d.eds_ide_id
LEFT JOIN organizacao.departamento dep ON dep.dep_id = ide.ide_dep_id
WHERE d.eds_end_date IS NULL AND p.epl_end_date IS NULL
  AND (p.epl_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.escala_plano.ler'))::INT[])
       OR (p.epl_publicada AND p.epl_igr_id = (SELECT m2.mem_igr_id FROM secretaria.membro m2
                                               WHERE m2.mem_id = (SELECT nucleo.fn_membro_sessao()))))
GROUP BY p.epl_id, p.epl_igr_id, p.epl_titulo, p.epl_publicada, d.eds_id, d.eds_data, d.eds_evento,
         d.eds_grupo_coral, dep.dep_nome, d.eds_observacoes;

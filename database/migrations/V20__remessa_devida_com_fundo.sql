-- =====================================================================
-- V20 · Remessa devida: o fundo e a entidade com nomes que a API não confunde (F-TES-10, P-09)
--
-- Na API, o nome JSON de uma coluna é o nome sem o prefixo de 3 letras; igr_id, fun_id e ent_id davam todos
-- "id" e o relatório GET /v1/tesouraria/remessas-devidas não dizia de que fundo era cada valor. A vista
-- ganha, no fim, fundo_id, fundo_nome, fundo_codigo e entidade_id (→ fundoId, fundoNome, fundoCodigo,
-- entidadeId). As colunas antigas ficam iguais e na mesma ordem (nada do que já as usa muda).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE OR REPLACE VIEW tesouraria.vw_remessa_devida WITH (security_invoker = true) AS
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
)
SELECT rc.*, COALESCE(rm.remetido, 0) AS remetido, rc.devido - COALESCE(rm.remetido, 0) AS em_falta,
       rc.fun_id AS fundo_id, f.fun_nome AS fundo_nome, f.fun_codigo AS fundo_codigo, rc.ent_id AS entidade_id
FROM recebido rc
LEFT JOIN remetido rm USING (igr_id, ent_id, ano, mes, fun_id)
JOIN tesouraria.fundo f ON f.fun_id = rc.fun_id;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V49: reavivamento por pessoa. O alvo da igreja 1 no fundo REAVIVAMENTO reparte-se igualmente pelas pessoas que contam
-- (membros activos e crianças activas ou interessadas); a quota de uma pessoa pode ajustar-se e as outras repartem o resto.
-- 1 = administrador; 2 = tesoureiro; 7 = secretário da ES (não vê). 960 Paulo (igreja 1).

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '1', false) \g /dev/null

\echo '1. o fundo do reavivamento da igreja 1 e o alvo de 2026'
INSERT INTO tesouraria.fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo) VALUES (1, 'REAV-T', 'Reavivamento (teste)', 'REAVIVAMENTO') RETURNING fun_nome;
INSERT INTO tesouraria.alvo (alv_igr_id, alv_fun_id, alv_valor_alvo, alv_data_inicio, alv_data_fim)
SELECT 1, fun_id, 12000, '2026-01-01', '2026-12-31' FROM tesouraria.fundo WHERE fun_codigo = 'REAV-T' RETURNING alv_valor_alvo;

\echo '2. sem ajustes: todas as quotas iguais e a soma dá o alvo'
SELECT count(*) > 0 AS ha_pessoas, count(DISTINCT quota) AS quotas_diferentes, round(sum(quota)) = 12000 AS soma_e_o_alvo
  FROM tesouraria.vw_reavivamento_pessoas WHERE igreja_id = 1 AND ano = 2026;

\echo '3. o Paulo fica com 0 (sem rendimento): os outros repartem o alvo; a soma continua a dar o alvo'
INSERT INTO tesouraria.quota_reavivamento (qrv_mem_id, qrv_igr_id, qrv_ano, qrv_valor, qrv_motivo) VALUES (960, 999, 2026, 0, 'Sem rendimento')
RETURNING qrv_igr_id AS igreja_copiada_do_membro, qrv_valor;
SELECT quota, quota_ajustada, motivo FROM tesouraria.vw_reavivamento_pessoas WHERE membro_id = 960 AND ano = 2026;
SELECT count(DISTINCT quota) FILTER (WHERE quota_id IS NULL) AS quotas_dos_outros, round(sum(quota)) = 12000 AS soma_e_o_alvo
  FROM tesouraria.vw_reavivamento_pessoas WHERE igreja_id = 1 AND ano = 2026;
\echo '   repetida no mesmo ano, negativa e de pessoa que não existe: recusadas'
INSERT INTO tesouraria.quota_reavivamento (qrv_mem_id, qrv_igr_id, qrv_ano, qrv_valor) VALUES (960, 1, 2026, 10);
UPDATE tesouraria.quota_reavivamento SET qrv_valor = -1 WHERE qrv_mem_id = 960;
INSERT INTO tesouraria.quota_reavivamento (qrv_mem_id, qrv_igr_id, qrv_ano, qrv_valor) VALUES (999999, 1, 2026, 10);

\echo '4. o tesoureiro ajusta quotas; o secretário da ES nem as vê'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE tesouraria.quota_reavivamento SET qrv_valor = 50 WHERE qrv_mem_id = 960 RETURNING qrv_valor;
SELECT set_config('app.usuario_id', '7', false) \g /dev/null
SELECT count(*) AS quotas_que_ve FROM tesouraria.quota_reavivamento;

\echo '5. V51: adultos com quota fixa de 400; as crianças (automáticas) repartem o resto do alvo; o Paulo continua ajustado'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO tesouraria.quota_escalao_reavivamento (rqe_igr_id, rqe_ano, rqe_quota_adulto) VALUES (1, 2026, 400) RETURNING rqe_quota_adulto, rqe_quota_crianca;
SELECT origem, menor, count(*) > 0 AS ha, count(DISTINCT quota) AS quotas_diferentes, min(quota) = 400 OR origem <> 'ESCALAO' AS adulto_400
  FROM tesouraria.vw_reavivamento_pessoas WHERE igreja_id = 1 AND ano = 2026 GROUP BY origem, menor ORDER BY origem, menor;
\echo '   as crianças também fixas (100): ninguém fica automático; repetir o ano e valor negativo recusados'
UPDATE tesouraria.quota_escalao_reavivamento SET rqe_quota_crianca = 100 WHERE rqe_igr_id = 1 AND rqe_ano = 2026;
SELECT count(*) FILTER (WHERE origem = 'AUTOMATICA') AS automaticas FROM tesouraria.vw_reavivamento_pessoas WHERE igreja_id = 1 AND ano = 2026;
INSERT INTO tesouraria.quota_escalao_reavivamento (rqe_igr_id, rqe_ano, rqe_quota_adulto) VALUES (1, 2026, 10);
UPDATE tesouraria.quota_escalao_reavivamento SET rqe_quota_adulto = -1 WHERE rqe_igr_id = 1;
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V48: cancelar uma actividade exige o motivo; o programa mostra-o.
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
\echo '1. uma actividade planeada da igreja 1'
INSERT INTO actividades.actividade (act_ide_id, act_nome, act_data_inicio, act_valor_previsto)
SELECT ide_id, 'Feira de saúde V48', '2026-12-12 09:00+02', 1500 FROM organizacao.igreja_departamento WHERE ide_igr_id = 1 ORDER BY ide_id LIMIT 1
RETURNING act_nome, act_estado;
\echo '2. cancelar sem motivo: recusado; com motivo: cancelada'
UPDATE actividades.actividade SET act_estado = 'CANCELADA' WHERE act_nome = 'Feira de saúde V48';
UPDATE actividades.actividade SET act_estado = 'CANCELADA', act_motivo_cancelamento = 'Chuvas fortes' WHERE act_nome = 'Feira de saúde V48'
RETURNING act_estado, act_motivo_cancelamento;
\echo '3. no programa, com o motivo'
SELECT nome, estado, motivo_cancelamento, actualizada_em IS NOT NULL AS com_data FROM actividades.vw_actividades_execucao WHERE nome = 'Feira de saúde V48';
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V41: o motivo da censura lê-se só por uma função que regista a consulta; o histórico não guarda o texto.
-- Dos testes anteriores: censura 1 do Rui (101, igreja 1); 950 = secretário da igreja 1; 2 = tesoureiro da igreja 1;
-- 5 = pastor do distrito 1 (igreja 1).

SET ROLE app_igreja;

\echo '1. secretário (autorizado): grava o motivo como antes'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE secretaria.disciplina SET dsc_motivo = 'Motivo confidencial de teste' WHERE dsc_id = 1;
\echo '   mas não o lê directamente (nem numa lista); o resto da censura sim'
SELECT dsc_motivo FROM secretaria.disciplina WHERE dsc_id = 1;
SELECT dsc_id, dsc_data_inicio, dsc_data_fim FROM secretaria.disciplina WHERE dsc_id = 1;
\echo '   lê-o pela função, que regista a consulta'
SELECT secretaria.fn_disciplina_motivo(1) AS motivo;

\echo '2. tesoureiro (sem acesso à disciplina): a função responde que não existe e não fica registo dele'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT secretaria.fn_disciplina_motivo(1);
SELECT count(*) AS ve_acessos FROM nucleo.acesso_confidencial;

\echo '3. pastor: vê quem consultou o motivo, quando e que registo'
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT aco_usu_id, aco_igr_id, aco_tabela, aco_registo_id, aco_accao FROM nucleo.acesso_confidencial ORDER BY aco_id;
\echo '   ninguém escreve no registo de acessos à mão'
INSERT INTO nucleo.acesso_confidencial (aco_igr_id, aco_tabela, aco_registo_id, aco_accao) VALUES (1, 'x', 1, 'LER_MOTIVO');
RESET ROLE;

\echo '4. o histórico de alterações não guarda o texto do motivo'
SELECT lau_accao, lau_dados_depois ->> 'dsc_motivo' AS motivo_no_log, lau_dados_antes ? 'dsc_motivo' AS antes_tem_motivo
  FROM nucleo.log_auditoria WHERE lau_tabela = 'secretaria.disciplina' AND lau_registo_id = 1 ORDER BY lau_id DESC LIMIT 1;

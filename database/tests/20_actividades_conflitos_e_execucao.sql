\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V34: actividades com objectivos, vários responsáveis, conflitos de calendário e execução financeira.
-- Dos testes anteriores: 11 = director do Ministério Jovem (igreja 1), 2 = tesoureiro da igreja 1,
-- 4 = tesoureiro da igreja 2; departamento 1 = Ministério Jovem da igreja 1; 961 = membro da igreja 1,
-- 100 = membro da igreja 2.

SET ROLE app_igreja;
SET TIME ZONE 'Africa/Maputo';

\echo '1. director do departamento (autorizado): regista a actividade com objectivos e material'
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
INSERT INTO actividades.actividade (act_ide_id, act_nome, act_data_inicio, act_data_fim, act_local, act_valor_previsto, act_objectivos)
VALUES (1, 'Acampamento de jovens', '2026-12-05 09:00', '2026-12-05 12:00', 'Igreja', 5000, 'Formar 30 jovens em liderança')
RETURNING act_nome, act_objectivos;
INSERT INTO actividades.material (mat_act_id, mat_descricao, mat_quantidade, mat_preco_unitario)
SELECT act_id, 'Tendas', 2, 750 FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens';

\echo '2. outros responsáveis: um membro da igreja entra; um de outra igreja é recusado; o mesmo duas vezes também'
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id, acr_funcao)
SELECT act_id, 961, 'Logística' FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens'
RETURNING acr_mem_id, acr_funcao;
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id)
SELECT act_id, 100 FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens';
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id)
SELECT act_id, 961 FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens';

\echo '3. conflito: outra actividade às 10:00 do mesmo dia sobrepõe-se ao acampamento'
SELECT nome, departamento, to_char(data_inicio, 'DD/MM HH24:MI') AS inicio
  FROM actividades.fn_conflitos_actividade(1, '2026-12-05 10:00', '2026-12-05 11:00');
\echo '   datas livres sugeridas (dias seguintes, à mesma hora)'
SELECT to_char(data_inicio, 'DD/MM HH24:MI') AS inicio, to_char(data_fim, 'HH24:MI') AS fim
  FROM actividades.fn_datas_alternativas(1, '2026-12-05 10:00', '2026-12-05 11:00');
\echo '   à tarde não há conflito; sem hora de fim conta 2 horas (11:30 ainda conflitua)'
SELECT count(*) AS conflitos_tarde FROM actividades.fn_conflitos_actividade(1, '2026-12-05 13:00', '2026-12-05 14:00');
SELECT count(*) AS conflitos_sem_fim FROM actividades.fn_conflitos_actividade(1, '2026-12-05 11:30');
\echo '   o conflito só avisa: a segunda actividade grava-se na mesma (quem a regista confirma)'
INSERT INTO actividades.actividade (act_ide_id, act_nome, act_data_inicio, act_data_fim)
VALUES (1, 'Ensaio do coro', '2026-12-05 10:00', '2026-12-05 11:00') RETURNING act_nome;
\echo '   ao editar o acampamento, não conflitua consigo próprio (só com o ensaio)'
SELECT nome FROM actividades.fn_conflitos_actividade(1, '2026-12-05 09:00', '2026-12-05 12:00',
       (SELECT act_id FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens'));
\echo '   cancelada deixa de contar'
UPDATE actividades.actividade SET act_estado = 'CANCELADA' WHERE act_nome = 'Ensaio do coro';
SELECT count(*) AS conflitos FROM actividades.fn_conflitos_actividade(1, '2026-12-05 10:00', '2026-12-05 11:00',
       (SELECT act_id FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens'));

\echo '4. programa anual e execução: previsto, material, despesas e executado'
SELECT nome, departamento, ano, mes, estado, responsavel, outros_responsaveis, valor_previsto, material_previsto,
       despesas_aprovadas, executado
  FROM actividades.vw_actividades_execucao WHERE igreja_id = 1 ORDER BY data_inicio, nome;

\echo '5. tesoureiro da igreja 1 (lê actividades, não gere responsáveis): vê o programa, não acrescenta responsáveis'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS actividades_no_programa FROM actividades.vw_actividades_execucao WHERE igreja_id = 1;
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id)
SELECT act_id, 960 FROM actividades.actividade WHERE act_nome = 'Acampamento de jovens';

\echo '6. tesoureiro da igreja 2: não vê as actividades da igreja 1 nem os seus conflitos'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS actividades_no_programa FROM actividades.vw_actividades_execucao WHERE igreja_id = 1;
SELECT count(*) AS conflitos FROM actividades.fn_conflitos_actividade(1, '2026-12-05 10:00', '2026-12-05 11:00');
RESET ROLE;

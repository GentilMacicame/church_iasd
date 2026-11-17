\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
SET TIME ZONE 'Africa/Maputo';
-- V35: actividades da área pastoral (distrito), vistas por todas as igrejas do distrito.
-- Dos testes anteriores: distrito 1 (Distrito Centro) com o pastor 5 e a igreja 1; 11 = director do Ministério Jovem
-- da igreja 1; 4 = tesoureiro da igreja 2; 970 = administração da Associação; igreja 9 = outro distrito.
-- Aqui a igreja 2 passa a ser do distrito 1 e cria-se um membro na igreja 9.
UPDATE organizacao.igreja SET igr_dst_id = 1 WHERE igr_id = 2;
INSERT INTO secretaria.membro (mem_id, mem_igr_id, mem_nome, mem_apelido) OVERRIDING SYSTEM VALUE VALUES (2101, 9, 'Ana', 'Longe');

SET ROLE app_igreja;

\echo '1. pastor do distrito (autorizado): cria uma actividade da área pastoral'
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
INSERT INTO actividades.actividade (act_dst_id, act_nome, act_data_inicio, act_data_fim, act_local, act_valor_previsto)
VALUES (1, 'Campanha distrital', '2026-12-12 15:00', '2026-12-12 18:00', 'Estádio', 20000)
RETURNING act_nome, act_dst_id, act_ide_id;

\echo '2. origem: de um departamento OU do distrito, não das duas nem de nenhuma'
INSERT INTO actividades.actividade (act_ide_id, act_dst_id, act_nome, act_data_inicio) VALUES (1, 1, 'As duas', '2026-12-20 09:00');
INSERT INTO actividades.actividade (act_nome, act_data_inicio) VALUES ('Nenhuma', '2026-12-20 09:00');

\echo '3. responsável: membro de uma igreja do distrito entra; de outro distrito não'
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id, acr_funcao)
SELECT act_id, 100, 'Música' FROM actividades.actividade WHERE act_nome = 'Campanha distrital' RETURNING acr_mem_id, acr_funcao;
INSERT INTO actividades.actividade_responsavel (acr_act_id, acr_mem_id)
SELECT act_id, 2101 FROM actividades.actividade WHERE act_nome = 'Campanha distrital';

\echo '4. director de um departamento da igreja 1 (não autorizado): vê a actividade do distrito, mas não a cria nem altera'
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
SELECT nome, departamento, origem, distrito FROM actividades.vw_actividades_execucao
 WHERE igreja_id = 1 AND origem = 'AREA_PASTORAL';
INSERT INTO actividades.actividade (act_dst_id, act_nome, act_data_inicio) VALUES (1, 'Outra distrital', '2026-12-19 09:00');
UPDATE actividades.actividade SET act_nome = 'Mudada' WHERE act_nome = 'Campanha distrital';
SELECT act_nome AS continua FROM actividades.actividade WHERE act_dst_id = 1;
\echo '   conta nos conflitos da igreja 1'
SELECT nome, departamento FROM actividades.fn_conflitos_actividade(1, '2026-12-12 16:00', '2026-12-12 17:00');

\echo '5. tesoureiro da igreja 2 (mesmo distrito): a actividade aparece no programa e nos conflitos da igreja 2'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT nome, origem FROM actividades.vw_actividades_execucao WHERE igreja_id = 2;
SELECT nome, departamento FROM actividades.fn_conflitos_actividade(2, '2026-12-12 16:00');

\echo '6. administração da Associação sem a permissão de criar actividades: não cria'
SELECT set_config('app.usuario_id', '970', false) \g /dev/null
INSERT INTO actividades.actividade (act_dst_id, act_nome, act_data_inicio) VALUES (1, 'Da Associação', '2026-12-19 09:00');

\echo '7. as actividades locais continuam como antes: a da igreja 1 não aparece à igreja 2'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS locais_da_igreja_1 FROM actividades.actividade WHERE act_ide_id = 1;
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- dados: um sábado com mais de 12 meses, com um visitante que não se tornou membro e outro que sim
INSERT INTO escola_sabatina.trimestre (etr_id, etr_ano, etr_numero, etr_data_inicio, etr_data_fim, etr_num_sabados)
VALUES (100, 2025, 1, '2025-01-04', '2025-03-29', 13);
INSERT INTO escola_sabatina.sabado (esa_id, esa_etr_id, esa_numero, esa_data) VALUES (100, 100, 1, '2025-01-04');
INSERT INTO escola_sabatina.classe_trimestre (ect_id, ect_ecl_id, ect_etr_id) VALUES (100, 1, 100);
INSERT INTO escola_sabatina.relatorio_sabado (ers_id, ers_ect_id, ers_esa_id, ers_membros_matriculados, ers_membros_presentes)
VALUES (100, 100, 100, 10, 5);
INSERT INTO escola_sabatina.visitante (evi_id, evi_ers_id, evi_nome, evi_telefone) VALUES (100, 100, 'Maria Visitante', '+258841111111');
INSERT INTO escola_sabatina.visitante (evi_id, evi_ers_id, evi_nome, evi_telefone, evi_tornou_se_mem_id)
VALUES (101, 100, 'João Novo Membro', '+258842222222', (SELECT min(mem_id) FROM secretaria.membro));

SET ROLE app_igreja;

\echo '1. tesoureiro (2) vê os seus próprios perfis; não vê os do ancião (3)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT uig_usu_id, uig_igr_id, (SELECT per_nome FROM nucleo.perfil WHERE per_id = uig_per_id) AS perfil
  FROM nucleo.usuario_igreja WHERE uig_end_date IS NULL ORDER BY uig_usu_id, uig_igr_id;
SELECT count(*) AS perfis_do_anciao FROM nucleo.usuario_igreja WHERE uig_usu_id = 3;

\echo '2. sem utilizador na sessão não se vê nenhum perfil'
SELECT set_config('app.usuario_id', '', false) \g /dev/null
SELECT count(*) AS perfis FROM nucleo.usuario_igreja;

\echo '3. a API cria as partições do log (tarefa mensal) sem ser dona das tabelas'
SELECT nucleo.fn_criar_particoes_log(3) IS NOT NULL AS particoes_ok;

\echo '4. anonimização: o visitante antigo perde nome e telefone; o que se tornou membro fica igual'
SELECT escola_sabatina.fn_anonimizar_visitantes() >= 1 AS anonimizou;
RESET ROLE;
SELECT evi_id, evi_nome, evi_telefone, evi_anonimizado_em IS NOT NULL AS anonimizado
  FROM escola_sabatina.visitante WHERE evi_id IN (100, 101) ORDER BY evi_id;

\echo '5. o log da anonimização não guarda o nome antigo'
SELECT lau_accao, lau_dados_antes IS NULL AS sem_valores_antigos, lau_dados_depois ->> 'evi_nome' AS nome_depois
  FROM nucleo.log_auditoria WHERE lau_tabela = 'escola_sabatina.visitante' AND lau_registo_id = 100;
SELECT count(*) AS logs_com_o_nome FROM nucleo.log_auditoria WHERE lau_dados_antes::text LIKE '%Maria Visitante%';

\echo '6. correr outra vez não volta a mexer no mesmo visitante'
SET ROLE app_igreja;
SELECT count(*) AS ja_anonimizados_de_novo FROM escola_sabatina.vw_visitantes_a_anonimizar WHERE evi_id = 100;
RESET ROLE;

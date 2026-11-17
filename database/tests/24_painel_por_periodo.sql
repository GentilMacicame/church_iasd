\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V38: dashboard por período (membros activos e inactivos, dízimos, ofertas, reavivamento, contribuintes, entradas e
-- perdas de membros) e o fundo REAVIVAMENTO.
-- Dos testes anteriores: 2 = tesoureiro da igreja 1; 4 = tesoureiro da igreja 2; 5 = pastor do distrito 1 (igrejas 1 e
-- 2); 13002 = sem perfil. Dízimos da igreja 1 no 4.º trimestre de 2026: Tito (103) 500 + 1000; Ana (100) na igreja 2.

SET ROLE app_igreja;

\echo '1. tesoureiro da igreja 1: cria o fundo da obra de reavivamento (fundo próprio da igreja)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO tesouraria.fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo)
VALUES (1, 'I1-REAV', 'Obra de reavivamento', 'REAVIVAMENTO') RETURNING fun_codigo, fun_tipo, fun_percentagem_remessa;
\echo '   um fundo da igreja não pode ser dízimo (o dízimo é da Missão)'
INSERT INTO tesouraria.fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo) VALUES (1, 'I1-X', 'Dízimo próprio', 'DIZIMO');

\echo '2. painel do 4.º trimestre de 2026 visto pelo tesoureiro da igreja 1: só a sua igreja (o dinheiro conta onde foi lançado)'
SELECT nome, ve_membros, ve_tesouraria, dizimos, ofertas, reavivamento, contribuintes
  FROM organizacao.fn_painel_periodo('2026-10-01', '2026-12-31') ORDER BY igr_id;

\echo '3. pastor do distrito: as duas igrejas do distrito, com membros, inactivos, dinheiro e movimento do livro'
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT igr_id, membros, activos + inactivos = membros AS soma_certa, dizimos, ofertas, contribuintes,
       round(contribuintes::NUMERIC / NULLIF(membros, 0), 2) AS fidelidade, entradas_membros, perdas_membros
  FROM organizacao.fn_painel_periodo('2026-10-01', '2026-12-31') ORDER BY igr_id;
\echo '   só Dezembro: menos dízimos'
SELECT igr_id, dizimos FROM organizacao.fn_painel_periodo('2026-12-01', '2026-12-31') ORDER BY igr_id;

\echo '4. sem perfil: nenhuma igreja'
SELECT set_config('app.usuario_id', '13002', false) \g /dev/null
SELECT count(*) AS igrejas FROM organizacao.fn_painel_periodo('2026-01-01', '2026-12-31');
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V27: o directório de igrejas mostra a todos os utilizadores o nome e a localização das igrejas (para escolher o
-- destino de uma transferência), sem abrir os dados das outras igrejas.
-- Dos testes anteriores: 980 = ADMIN da igreja 1; igreja 2 = Igreja da Matola (outra igreja).

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '980', false);
\echo '1. o administrador da igreja 1 vê a igreja 2 no directório (nome e Associação)'
SELECT nome, entidade FROM vw_directorio_igrejas WHERE igr_id = 2;
\echo '   mas não vê os dados da igreja 2 (0 linhas na tabela)'
SELECT count(*) AS igreja_2_na_tabela FROM igreja WHERE igr_id = 2;
SELECT count(*) AS membros_da_igreja_2 FROM membro WHERE mem_igr_id = 2;
\echo '2. sem sessão: o directório não mostra nada'
SELECT set_config('app.usuario_id', '', false);
SELECT count(*) AS sem_sessao FROM vw_directorio_igrejas;
RESET ROLE;

\echo '3. transferência pedida da igreja 1 para a igreja 2: o secretário da igreja 2 vê quem vai receber'
INSERT INTO nucleo.usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES (13001, 'Secretário da igreja 2', 'sec2.v27@teste.local', 'x');
INSERT INTO nucleo.usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) SELECT 13001, 2, per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO';
INSERT INTO transferencia_membro (tme_mem_id, tme_origem_igr_id, tme_destino_igr_id, tme_data_pedido)
SELECT mem_id, 1, 2, DATE '2026-11-01' FROM membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO' AND mem_end_date IS NULL ORDER BY mem_id LIMIT 1;
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '13001', false);
SELECT membro IS NOT NULL AS ve_o_nome, origem, destino, tme_estado FROM vw_transferencias WHERE tme_data_pedido = DATE '2026-11-01';
\echo '   mas o membro continua invisível na tabela (é da igreja 1)'
SELECT count(*) AS membro_na_tabela FROM membro m JOIN transferencia_membro t ON t.tme_mem_id = m.mem_id WHERE t.tme_data_pedido = DATE '2026-11-01';
\echo '4. um utilizador sem perfil nas duas igrejas não vê a transferência (mas vê o directório)'
RESET ROLE;
SELECT set_config('app.usuario_id', '', false) AS sem_sessao_para_criar;
INSERT INTO nucleo.usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES (13002, 'Sem perfil', 'semperfil.v27@teste.local', 'x');
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '13002', false);
SELECT count(*) AS transferencias_vistas FROM vw_transferencias;
SELECT count(*) > 0 AS ve_o_directorio FROM vw_directorio_igrejas;
RESET ROLE;

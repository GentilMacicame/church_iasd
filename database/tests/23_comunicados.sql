\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V37: comunicados da igreja, do distrito pastoral e da Associação; quem publica e quem lê.
-- Dos testes anteriores: 950 = secretário da igreja 1; 2 = tesoureiro da igreja 1; 8 = Tito (membro 103, igreja 1);
-- 4 = tesoureiro da igreja 2; 5 = pastor do distrito 1 (igrejas 1 e 2, desde o teste 21); 970 = Associação 1;
-- igreja 9 = outro distrito.

SET ROLE app_igreja;
-- quem lê: os títulos que cada utilizador vê
CREATE TEMP VIEW vejo AS SELECT string_agg(cmc_titulo, ' | ' ORDER BY cmc_titulo) AS titulos FROM nucleo.comunicado;

\echo '1. secretário (autorizado): publica para os membros da igreja 1 e guarda um rascunho'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publicar_em)
VALUES (1, 'Santa Ceia no sábado', 'Haverá Santa Ceia no culto de sábado.', 'PUBLICADO', now() - INTERVAL '1 hour')
RETURNING cmc_titulo, cmc_publico, cmc_estado;
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo) VALUES (1, 'Rascunho da igreja', 'Por rever');
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publico, cmc_publicar_em)
VALUES (1, 'Reunião da liderança', 'Só para quem tem cargo.', 'PUBLICADO', 'LIDERANCA', now() - INTERVAL '1 hour');
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publicar_em, cmc_valido_ate)
VALUES (1, 'Já expirou', 'x', 'PUBLICADO', now() - INTERVAL '10 days', now() - INTERVAL '1 day');
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publicar_em)
VALUES (1, 'Ainda não começou', 'x', 'PUBLICADO', now() + INTERVAL '10 days');
SELECT titulos AS secretario_ve FROM vejo;
\echo '   validade antes da publicação, emissor duplo, igrejas escolhidas num comunicado da igreja: recusados'
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo, cmc_publicar_em, cmc_valido_ate)
VALUES (1, 'x', 'x', '2026-12-10', '2026-12-01');
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_dst_id, cmc_titulo, cmc_conteudo) VALUES (1, 1, 'x', 'x');
INSERT INTO nucleo.comunicado_igreja (cmi_cmc_id, cmi_igr_id)
SELECT cmc_id, 1 FROM nucleo.comunicado WHERE cmc_titulo = 'Santa Ceia no sábado';
\echo '   o secretário de uma igreja não publica pelo distrito'
INSERT INTO nucleo.comunicado (cmc_dst_id, cmc_titulo, cmc_conteudo) VALUES (1, 'Do distrito?', 'x');

\echo '2. tesoureiro da igreja 1 (só lê): vê os publicados em vigor (também os da liderança), não os rascunhos; não publica'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT titulos AS tesoureiro_ve FROM vejo;
INSERT INTO nucleo.comunicado (cmc_igr_id, cmc_titulo, cmc_conteudo) VALUES (1, 'Do tesoureiro', 'x');

\echo '3. membro com sessão (Tito, igreja 1): vê só os publicados para MEMBROS'
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT titulos AS membro_ve FROM vejo;

\echo '4. pastor do distrito: publica para o distrito; depois restringe à igreja 2; a igreja de outro distrito é recusada'
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
INSERT INTO nucleo.comunicado (cmc_dst_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publicar_em)
VALUES (1, 'Campanha distrital', 'Todas as igrejas do distrito.', 'PUBLICADO', now() - INTERVAL '1 hour') RETURNING cmc_titulo;
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT titulos AS membro_ve FROM vejo;
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
INSERT INTO nucleo.comunicado_igreja (cmi_cmc_id, cmi_igr_id)
SELECT cmc_id, 2 FROM nucleo.comunicado WHERE cmc_titulo = 'Campanha distrital' RETURNING cmi_igr_id;
INSERT INTO nucleo.comunicado_igreja (cmi_cmc_id, cmi_igr_id)
SELECT cmc_id, 9 FROM nucleo.comunicado WHERE cmc_titulo = 'Campanha distrital';
\echo '   agora só para a igreja 2: o Tito (igreja 1) deixa de o ver; o tesoureiro da igreja 2 vê-o'
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT titulos AS membro_ve FROM vejo;
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT titulos AS tesoureiro_igreja_2_ve FROM vejo;

\echo '5. Associação: publica para a liderança de todas as suas igrejas'
SELECT set_config('app.usuario_id', '970', false) \g /dev/null
INSERT INTO nucleo.comunicado (cmc_ent_id, cmc_titulo, cmc_conteudo, cmc_estado, cmc_publico, cmc_publicar_em)
VALUES (1, 'Circular da Missão', 'Relatórios até dia 10.', 'PUBLICADO', 'LIDERANCA', now() - INTERVAL '1 hour') RETURNING cmc_titulo;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT titulos AS tesoureiro_ve FROM vejo;
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT titulos AS membro_ve FROM vejo;

\echo '6. sem perfil nem membro: não vê nada'
SELECT set_config('app.usuario_id', '13002', false) \g /dev/null
SELECT coalesce(titulos, '(nada)') AS sem_perfil_ve FROM vejo;
RESET ROLE;

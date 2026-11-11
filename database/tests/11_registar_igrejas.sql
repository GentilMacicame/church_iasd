\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V25: registar igrejas. Antes ninguém conseguia (a igreja nova não estava na lista do utilizador).
-- Dos testes anteriores: 1 = super-administrador; 970 = ADMIN_ASSOCIACAO da entidade 1; entidade 2 = outra Missão.
-- Aqui: 980 = administrador (perfil ADMIN) da igreja 1; 981 = o novo administrador da igreja registada.

SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES
  (980, 'Admin da igreja 1', 'admin.igreja1.v25@x', 'h'), (981, 'Admin da igreja nova', 'admin.nova.v25@x', 'h');
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (980, 1, (SELECT per_id FROM perfil WHERE per_nome = 'ADMIN'));

-- os testes anteriores inserem igrejas com id explícito: o contador avança para não repetir ids
SELECT setval(pg_get_serial_sequence('organizacao.igreja', 'igr_id'), (SELECT max(igr_id) FROM organizacao.igreja)) \g /dev/null
SET ROLE app_igreja;
\echo '1. super-administrador (autorizado): regista a igreja e dá-lhe um administrador'
INSERT INTO igreja (igr_ent_id, igr_nome, igr_endereco) VALUES (1, 'Igreja do Bairro Novo', 'Rua 1, Maputo') RETURNING igr_nome, igr_ent_id, igr_tipo;
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id)
SELECT 981, igr_id, (SELECT per_id FROM perfil WHERE per_nome = 'ADMIN') FROM igreja WHERE igr_nome = 'Igreja do Bairro Novo'
RETURNING (SELECT per_nome FROM perfil WHERE per_id = uig_per_id) AS perfil;

\echo '2. administração da Associação 1 (autorizada na sua Associação): regista; noutra Missão, recusado'
SELECT set_config('app.usuario_id', '970', false) \g /dev/null
INSERT INTO igreja (igr_ent_id, igr_nome) VALUES (1, 'Grupo da Machava') RETURNING igr_nome;
INSERT INTO igreja (igr_ent_id, igr_nome) VALUES (2, 'Igreja de outra Missão');

\echo '3. administrador de uma igreja (não autorizado): não regista igrejas'
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
INSERT INTO igreja (igr_ent_id, igr_nome) VALUES (1, 'Igreja criada pelo admin da igreja 1');

\echo '4. o novo administrador vê a sua igreja (e só tem perfil nela)'
SELECT set_config('app.usuario_id', '981', false) \g /dev/null
SELECT igr_nome FROM igreja ORDER BY igr_nome;
RESET ROLE;

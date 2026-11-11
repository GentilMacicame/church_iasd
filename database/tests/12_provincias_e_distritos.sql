\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V26: províncias, distritos administrativos e localidade das igrejas.
-- Dos testes anteriores: 2 = tesoureiro da igreja 1; 970 = ADMIN_ASSOCIACAO da entidade 1; 980 = ADMIN da igreja 1.

SET ROLE app_igreja;
\echo '1. tesoureiro (qualquer utilizador): lê as províncias e os distritos'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS provincias FROM provincia;
SELECT count(*) AS distritos_de_gaza FROM distrito_administrativo d JOIN provincia p ON p.prv_id = d.dad_prv_id WHERE p.prv_nome = 'Gaza';
\echo '   não autorizado: o administrador de uma igreja não cria nem altera províncias (recusado / 0 linhas)'
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
INSERT INTO provincia (prv_nome) VALUES ('Província inventada');
UPDATE provincia SET prv_codigo = 'XXX' WHERE prv_nome = 'Gaza';

\echo '2. autorizado: a administração da Associação acrescenta um distrito'
SELECT set_config('app.usuario_id', '970', false) \g /dev/null
INSERT INTO distrito_administrativo (dad_prv_id, dad_nome) SELECT prv_id, 'Distrito novo de teste' FROM provincia WHERE prv_nome = 'Niassa' RETURNING dad_nome;

\echo '3. igreja com o distrito: a província vem sozinha; distrito de outra província: recusado'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO igreja (igr_ent_id, igr_nome, igr_dad_id, igr_localidade)
SELECT 1, 'Igreja de Chókwè', dad_id, 'Bairro 3' FROM distrito_administrativo WHERE dad_nome = 'Chókwè'
RETURNING igr_nome, (SELECT prv_nome FROM provincia WHERE prv_id = igr_prv_id) AS provincia, igr_localidade;
INSERT INTO igreja (igr_ent_id, igr_nome, igr_prv_id, igr_dad_id)
SELECT 1, 'Igreja trocada', (SELECT prv_id FROM provincia WHERE prv_nome = 'Tete'), dad_id FROM distrito_administrativo WHERE dad_nome = 'Chókwè';
RESET ROLE;

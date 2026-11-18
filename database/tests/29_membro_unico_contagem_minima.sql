\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V43: o mesmo membro não se regista duas vezes (em nenhuma igreja) e a contagem só se confere com o tesoureiro, o
-- representante da Escola Sabatina e o diácono.
-- Dos testes anteriores: 6 = secretário da igreja 1; 2 = tesoureiro da igreja 1; 100 Ana Cossa (igreja 2, 1980-01-01);
-- 900 Elisa Fumo (igreja 1, documento 110100000000A); contagem 9231 (igreja 1, aberta) com o tesoureiro 960 e o diácono 103.

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '6', false) \g /dev/null

\echo '1. procurar antes de registar: a Ana Cossa existe noutra igreja (só o nome e a igreja, sem a ficha)'
SELECT mem_id IS NULL AS sem_ficha, nome, motivo, visivel FROM nucleo.fn_membro_existente('ana', 'Côssa', '1980-01-01');
\echo '   o documento escrito de outra forma também a encontra (Elisa, da própria igreja: com a ficha)'
SELECT mem_id, nome, motivo, visivel FROM nucleo.fn_membro_existente('Outra', 'Pessoa', NULL, '1101-0000-0000 a');
\echo '   só o nome igual, sem data nem documento: não é o mesmo membro (fica para o aviso de parecidos)'
SELECT count(*) AS existentes FROM nucleo.fn_membro_existente('Ana', 'Cossa');

\echo '2. registar a mesma pessoa: recusado (mesmo nome e data; mesmo documento)'
INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento) VALUES (1, 'ANA', 'cossa', '1980-01-01');
INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_numero_identificacao) VALUES (1, 'Elsa', 'Fumo', '110100000000a');

\echo '3. homónimo com outra data de nascimento: registado; mudar-lhe a data para a da Ana: recusado'
INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento) VALUES (1, 'Ana', 'Cossa', '1999-09-09')
RETURNING mem_nome, mem_apelido, mem_data_nascimento;
UPDATE secretaria.membro SET mem_data_nascimento = '1980-01-01' WHERE mem_igr_id = 1 AND mem_nome = 'Ana' AND mem_apelido = 'Cossa';
\echo '   editar outro campo de um membro já existente não volta a comparar'
UPDATE secretaria.membro SET mem_profissao = 'Professora' WHERE mem_igr_id = 1 AND mem_nome = 'Ana' AND mem_apelido = 'Cossa' RETURNING mem_profissao;

\echo '4. conferir a contagem sem o representante da Escola Sabatina: recusado'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE tesouraria.contagem_numerario SET cnu_estado = 'CONFERIDA' WHERE cnu_id = 9231;
\echo '   com o representante da Escola Sabatina: conferida'
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 961, 'ESCOLA_SABATINA') RETURNING cpa_funcao;
UPDATE tesouraria.contagem_numerario SET cnu_estado = 'CONFERIDA' WHERE cnu_id = 9231 RETURNING cnu_estado;

\echo '5. depois de conferida, os participantes não mudam'
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 900, 'ANCIAO');
UPDATE tesouraria.contagem_participante SET cpa_end_date = now() WHERE cpa_cnu_id = 9231 AND cpa_mem_id = 961;
RESET ROLE;

\echo '6. reuniões: o secretário regista a discussão do ponto, separada da descrição'
-- os testes anteriores inseriram reuniões e pontos com o id escrito à mão: as sequências avançam para lá deles
SELECT setval(pg_get_serial_sequence('secretaria.reuniao', 'reu_id'), (SELECT max(reu_id) FROM secretaria.reuniao)) \g /dev/null
SELECT setval(pg_get_serial_sequence('secretaria.reuniao_ponto', 'rpt_id'), (SELECT max(rpt_id) FROM secretaria.reuniao_ponto)) \g /dev/null
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
INSERT INTO secretaria.reuniao (reu_igr_id, reu_tipo, reu_data, reu_numero)
SELECT 1, reu_tipo, '2026-11-20 18:00+02', '2026-V43' FROM secretaria.reuniao WHERE reu_id = (SELECT min(reu_id) FROM secretaria.reuniao) RETURNING reu_numero;
INSERT INTO secretaria.reuniao_ponto (rpt_reu_id, rpt_assunto, rpt_detalhes, rpt_discussao)
SELECT reu_id, 'Obras no templo', 'Orçamento de 50 000,00', 'Pediu-se um segundo orçamento' FROM secretaria.reuniao WHERE reu_numero = '2026-V43'
RETURNING rpt_assunto, rpt_detalhes, rpt_discussao;
RESET ROLE;

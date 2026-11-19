\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V53: o livro de membros não aceita o voto de outra pessoa.
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO membro (mem_id, mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento, mem_estado) VALUES
 (3801, 1, 'Rosa', 'Macamo', '1995-02-02', 'INTERESSADO'), (3802, 1, 'Amélia', 'Chirindza', '1996-03-03', 'INTERESSADO'),
 (3803, 1, 'Paulo', 'Nhaca', '1997-04-04', 'INTERESSADO');
INSERT INTO reuniao (reu_id, reu_igr_id, reu_tipo, reu_data) VALUES (3801, 1, 'REUNIAO_REGULAR', '2026-11-07 11:00+02');
INSERT INTO voto (vot_id, vot_reu_id, vot_numero, vot_tipo, vot_assunto, vot_leitura) VALUES
 (3801, 3801, '2026-381', 'ADMISSAO', 'Admissão por baptismo de Amélia Chirindza', 1),
 (3802, 3801, '2026-382', 'ADMISSAO', 'Admissão por baptismo de Paulo Nhaca e Rosa Macamo', 1);

\echo '1. pessoas do voto: a Amélia num voto, o Paulo e a Rosa noutro; repetida e de outra igreja recusadas'
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3801, 999, 3802) RETURNING vtm_igr_id AS igreja_copiada;
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3802, 1, 3803), (3802, 1, 3801);
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3801, 1, 3802);
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3801, 1, (SELECT mem_id FROM membro WHERE mem_igr_id <> 1 ORDER BY mem_id LIMIT 1));

\echo '2. a Rosa com o voto da Amélia: recusado'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (3801, 1, 'BAPTISMO', '2026-11-07', 3801);
SELECT mem_estado FROM membro WHERE mem_id = 3801;

\echo '3. a Rosa e o Paulo com o voto do grupo, a Amélia com o seu: aceites'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (3801, 1, 'BAPTISMO', '2026-11-07', 3802), (3803, 1, 'BAPTISMO', '2026-11-07', 3802), (3802, 1, 'BAPTISMO', '2026-11-07', 3801);
SELECT mem_nome, mem_estado FROM membro WHERE mem_id IN (3801, 3802, 3803) ORDER BY mem_id;

\echo '4. falecimento continua sem voto'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data) VALUES (3803, 1, 'FALECIMENTO', '2026-11-10');
SELECT mem_estado FROM membro WHERE mem_id = 3803;

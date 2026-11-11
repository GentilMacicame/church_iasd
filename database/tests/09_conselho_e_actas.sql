\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V22: conselho da igreja (mandatos), presenças e pontos da agenda das reuniões, acta aprovada fechada.
-- Dos testes anteriores: 950 = secretário da igreja 1, 2 = tesoureiro da igreja 1, 4 = tesoureiro da igreja 2;
-- 900 e 901 = membros da igreja 1. Aqui: 960 e 961 = membros activos da igreja 1.

SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO membro (mem_id, mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento, mem_estado) VALUES
  (960, 1, 'Paulo', 'Mabjaia', '1970-02-02', 'ACTIVO'), (961, 1, 'Joana', 'Cumbe', '1982-07-07', 'ACTIVO');
INSERT INTO contacto (cto_mem_id, cto_tipo, cto_valor, cto_principal) VALUES (960, 'TELEFONE', '+258843330000', true);
\echo '0. a igreja 1 define mandatos de 2 anos (fora dos limites: recusado)'
UPDATE organizacao.igreja SET igr_mandato_anos = 2 WHERE igr_id = 1;
UPDATE organizacao.igreja SET igr_mandato_anos = 9 WHERE igr_id = 1;

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '950', false) \g /dev/null

\echo '1. secretário (autorizado): elege o secretário e um ancião; o fim previsto sai da duração da igreja'
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_data_inicio)
SELECT 960, car_id, 1, '2026-01-01' FROM organizacao.cargo WHERE car_nome = 'Secretário(a) da igreja'
RETURNING ofi_data_inicio, ofi_fim_previsto;
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_data_inicio, ofi_fim_previsto)
SELECT 961, car_id, 1, '2025-01-01', '2025-12-31' FROM organizacao.cargo WHERE car_nome = 'Ancião'
RETURNING ofi_data_inicio, ofi_fim_previsto;
\echo '   fim previsto antes do início: recusado'
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_data_inicio, ofi_fim_previsto)
SELECT 961, car_id, 1, '2026-01-01', '2025-06-30' FROM organizacao.cargo WHERE car_nome = 'Diácono';

\echo '2. o conselho: cargo, contacto e estado do mandato'
SELECT membro, cargo, do_conselho, ofi_fim_previsto, contacto, estado_mandato
  FROM vw_conselho WHERE ofi_igr_id = 1 ORDER BY membro;

\echo '3. reunião do conselho com presenças e agenda'
INSERT INTO reuniao (reu_id, reu_igr_id, reu_tipo, reu_data, reu_numero, reu_presidida_por_mem_id, reu_secretario_mem_id)
VALUES (90, 1, 'JUNTA_DIRECTIVA', '2026-11-08 15:00+02', '2026-07', 961, 960) RETURNING reu_numero, reu_estado;
INSERT INTO reuniao_presenca (rpr_reu_id, rpr_mem_id, rpr_presente, rpr_funcao) VALUES (90, 960, true, 'Secretário(a) da igreja');
INSERT INTO reuniao_presenca (rpr_reu_id, rpr_mem_id, rpr_presente, rpr_funcao, rpr_justificacao) VALUES (90, 961, false, 'Ancião', 'Doente');
\echo '   a mesma pessoa duas vezes: recusado'
INSERT INTO reuniao_presenca (rpr_reu_id, rpr_mem_id) VALUES (90, 960);
INSERT INTO reuniao_ponto (rpt_reu_id, rpt_ordem, rpt_assunto, rpt_detalhes, rpt_discutido, rpt_votado, rpt_a_favor, rpt_contra, rpt_abstencoes, rpt_deliberacao, rpt_estado)
VALUES (90, 1, 'Pintura da fachada', 'Orçamento de 12 000 MT', true, true, 8, 1, 0, 'Aprovada a pintura; a tesouraria abre a despesa', 'APROVADO');
INSERT INTO reuniao_ponto (rpt_reu_id, rpt_ordem, rpt_assunto, rpt_estado) VALUES (90, 2, 'Programa do 13.º sábado', 'PENDENTE');
\echo '   votos num ponto que não foi a votos: recusado'
INSERT INTO reuniao_ponto (rpt_reu_id, rpt_ordem, rpt_assunto, rpt_votado, rpt_a_favor) VALUES (90, 3, 'Teste', false, 5);
SELECT rpr_mem_id, rpr_presente, rpr_funcao, rpr_justificacao FROM reuniao_presenca WHERE rpr_reu_id = 90 ORDER BY rpr_mem_id;
SELECT rpt_ordem, rpt_assunto, rpt_votado, rpt_a_favor, rpt_contra, rpt_estado FROM reuniao_ponto WHERE rpt_reu_id = 90 ORDER BY rpt_ordem;

\echo '4. acta aprovada: presenças e pontos ficam fechados'
UPDATE reuniao SET reu_estado = 'ACTA_APROVADA', reu_encerrada_em = '2026-11-08 17:10+02', reu_encerramento = 'Oração final pelo ancião' WHERE reu_id = 90;
INSERT INTO reuniao_ponto (rpt_reu_id, rpt_ordem, rpt_assunto) VALUES (90, 3, 'Ponto fora de tempo');
UPDATE reuniao_presenca SET rpr_presente = true WHERE rpr_reu_id = 90 AND rpr_mem_id = 961;

\echo '5. tesoureiro da igreja 1 (não autorizado): não vê presenças nem pontos e não os regista'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS ve_presencas FROM reuniao_presenca WHERE rpr_reu_id = 90;
SELECT count(*) AS ve_pontos FROM reuniao_ponto WHERE rpt_reu_id = 90;
INSERT INTO reuniao_ponto (rpt_reu_id, rpt_assunto) VALUES (90, 'Sem permissão');

\echo '6. tesoureiro de outra igreja: não vê o conselho da igreja 1'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS ve_conselho FROM vw_conselho WHERE ofi_igr_id = 1;
RESET ROLE;

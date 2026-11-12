\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V31: mandatos (período com duração) e, dentro de cada um, os oficiais no conselho ou na direcção.
-- Dos testes anteriores: 980 = ADMIN da igreja 1 (gere os oficiais); 2 = tesoureiro da igreja 1 (não gere).

SET ROLE app_igreja;
\echo '1. autorizado: o administrador da igreja 1 cria o mandato de 2030'
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
INSERT INTO mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim) VALUES (1, 'Mandato 2030', '2030-01-01', '2030-12-31')
RETURNING mdt_nome, mdt_data_inicio, mdt_data_fim;
\echo '   um mandato que se sobrepõe: recusado; fim antes do início: recusado'
INSERT INTO mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim) VALUES (1, 'Mandato a meio', '2030-06-01', '2031-05-31');
INSERT INTO mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim) VALUES (1, 'Mandato ao contrário', '2032-12-31', '2032-01-01');

\echo '2. oficiais no mandato: início e fim previsto vêm do mandato; o órgão vem do cargo (ou indica-se)'
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_mdt_id)
SELECT (SELECT min(mem_id) FROM membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO'), car_id, 1, (SELECT mdt_id FROM mandato WHERE mdt_nome = 'Mandato 2030')
  FROM cargo WHERE car_nome = 'Ancião';
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_mdt_id)
SELECT (SELECT max(mem_id) FROM membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO'), car_id, 1, (SELECT mdt_id FROM mandato WHERE mdt_nome = 'Mandato 2030')
  FROM cargo WHERE NOT car_conselho ORDER BY car_id LIMIT 1;
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_mdt_id, ofi_orgao)
SELECT (SELECT max(mem_id) FROM membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO'), car_id, 1, (SELECT mdt_id FROM mandato WHERE mdt_nome = 'Mandato 2030'), 'CONSELHO'
  FROM cargo WHERE NOT car_conselho ORDER BY car_id OFFSET 1 LIMIT 1;
SELECT orgao, count(*) AS oficiais, min(ofi_data_inicio) AS inicio, max(ofi_fim_previsto) AS fim_previsto
  FROM vw_conselho WHERE mandato = 'Mandato 2030' GROUP BY orgao ORDER BY orgao;
\echo '   órgão inválido: recusado'
UPDATE oficial SET ofi_orgao = 'COMISSAO' WHERE ofi_mdt_id = (SELECT mdt_id FROM mandato WHERE mdt_nome = 'Mandato 2030');

\echo '3. o mandato passa a acabar mais tarde: os oficiais acompanham'
UPDATE mandato SET mdt_data_fim = '2031-06-30' WHERE mdt_nome = 'Mandato 2030';
SELECT DISTINCT ofi_fim_previsto FROM oficial WHERE ofi_mdt_id = (SELECT mdt_id FROM mandato WHERE mdt_nome = 'Mandato 2030');
RESET ROLE;

\echo '4. mandato de outra igreja: o oficial da igreja 1 não entra nele (nem o vê)'
INSERT INTO mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim)
SELECT max(igr_id), 'Mandato de outra igreja (teste 17)', '2030-01-01', '2030-12-31' FROM igreja WHERE igr_id <> 1
RETURNING mdt_id AS outro \gset
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_mdt_id)
SELECT (SELECT min(mem_id) FROM membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO'), car_id, 1,
:outro
  FROM cargo WHERE car_nome = 'Ancião';

\echo '5. não autorizado: o tesoureiro não cria mandatos (recusado) e o mandato da outra igreja não é visível'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO mandato (mdt_igr_id, mdt_nome, mdt_data_inicio, mdt_data_fim) VALUES (1, 'Mandato do tesoureiro', '2040-01-01', '2040-12-31');
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
SELECT count(*) AS ve_mandato_de_outra_igreja FROM mandato WHERE mdt_nome = 'Mandato de outra igreja (teste 17)';
RESET ROLE;

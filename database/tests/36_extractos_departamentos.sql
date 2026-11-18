\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V50: extractos por departamento e por fundo. Igreja 1: dois departamentos (os de menor id), 1 = administrador,
-- 2 = tesoureiro, 7 = secretário da ES (não vê). 960 Paulo (igreja 1).
SELECT setval(pg_get_serial_sequence('organizacao.igreja_departamento', 'ide_id'), (SELECT max(ide_id) FROM organizacao.igreja_departamento)) \g /dev/null
INSERT INTO organizacao.igreja_departamento (ide_igr_id, ide_dep_id)
SELECT 1, dep_id FROM organizacao.departamento
 WHERE dep_id NOT IN (SELECT ide_dep_id FROM organizacao.igreja_departamento WHERE ide_igr_id = 1) ORDER BY dep_id LIMIT 1;
CREATE TEMP TABLE d AS SELECT ide_id, row_number() OVER (ORDER BY ide_id) AS n FROM organizacao.igreja_departamento WHERE ide_igr_id = 1 AND ide_end_date IS NULL ORDER BY ide_id LIMIT 2;
GRANT SELECT ON d TO app_igreja;

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '1', false) \g /dev/null

\echo '1. percentagens de 2026: 60% e 40%; passar o 1.º a 61% daria 101%: recusado'
INSERT INTO tesouraria.percentagem_departamento (dpp_ide_id, dpp_igr_id, dpp_ano, dpp_percentagem)
SELECT ide_id, 999, 2026, CASE n WHEN 1 THEN 60 ELSE 40 END FROM d RETURNING dpp_igr_id AS igreja_copiada, dpp_percentagem;
UPDATE tesouraria.percentagem_departamento SET dpp_percentagem = 61 WHERE dpp_ide_id = (SELECT ide_id FROM d WHERE n = 1);

\echo '2. transferência de 500 do 1.º para o 2.º; para o próprio departamento é recusada'
INSERT INTO tesouraria.transferencia_departamento (tdp_origem_ide_id, tdp_destino_ide_id, tdp_igr_id, tdp_data, tdp_valor, tdp_descricao)
SELECT (SELECT ide_id FROM d WHERE n = 1), (SELECT ide_id FROM d WHERE n = 2), 999, '2026-11-05', 500, 'Teste' RETURNING tdp_valor;
INSERT INTO tesouraria.transferencia_departamento (tdp_origem_ide_id, tdp_destino_ide_id, tdp_igr_id, tdp_data, tdp_valor)
SELECT ide_id, ide_id, 1, '2026-11-05', 10 FROM d WHERE n = 1;

\echo '3. adiantamento de 300 ao Paulo pelo 2.º; devolve 100 na prestação de contas; devolver mais do que recebeu é recusado'
INSERT INTO tesouraria.adiantamento (adt_ide_id, adt_igr_id, adt_mem_id, adt_data, adt_valor, adt_descricao)
SELECT ide_id, 999, 960, '2026-11-06', 300, 'Material do retiro' FROM d WHERE n = 2 RETURNING adt_valor;
UPDATE tesouraria.adiantamento SET adt_data_prestacao = '2026-11-10', adt_valor_devolvido = 100 WHERE adt_mem_id = 960 RETURNING adt_valor_devolvido;
UPDATE tesouraria.adiantamento SET adt_valor_devolvido = 400 WHERE adt_mem_id = 960;

\echo '4. extracto de Novembro de 2026: transferências e adiantamentos nas colunas; o saldo final fecha'
SELECT d.n, e.percentagem, e.transf_saida, e.transf_entrada, e.adiantamentos,
       e.saldo_final = e.saldo_inicial + e.doacao_directa + e.doacao_distribuida + e.despesas + e.transf_saida + e.transf_entrada + e.estornos + e.adiantamentos AS fecha
  FROM tesouraria.fn_extracto_departamentos(1, '2026-11-01', '2026-11-30') e JOIN d ON d.ide_id = e.departamento_igreja_id ORDER BY d.n;
\echo '   no mês seguinte a transferência e o adiantamento já estão no saldo inicial'
SELECT d.n, e.transf_saida, e.transf_entrada, e.adiantamentos
  FROM tesouraria.fn_extracto_departamentos(1, '2026-12-01', '2026-12-31') e JOIN d ON d.ide_id = e.departamento_igreja_id ORDER BY d.n;

\echo '5. extracto por fundo do ano: o saldo final fecha em cada fundo'
SELECT count(*) > 0 AS ha_fundos, bool_and(saldo_final = saldo_inicial + entradas - saidas) AS fecha
  FROM tesouraria.fn_extracto_fundos(1, '2026-01-01', '2026-12-31');

\echo '6. o tesoureiro regista transferências; o secretário da ES não vê os adiantamentos'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS adiantamentos_que_ve FROM tesouraria.adiantamento;
SELECT set_config('app.usuario_id', '7', false) \g /dev/null
SELECT count(*) AS adiantamentos_que_ve FROM tesouraria.adiantamento;
RESET ROLE;

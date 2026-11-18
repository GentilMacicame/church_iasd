\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V44: as funções da programação do culto na escala, a família da Escola Sabatina no dia da escala e a programação do
-- dia (preparar do modelo ou de outro dia, preencher pela escala).
-- Dos testes anteriores: 6 = secretário da igreja 1; 2 = tesoureiro da igreja 1; 960 Paulo e 961 Joana (igreja 1);
-- 2201 Família Langa (igreja 1). Aqui cria-se uma família da igreja 2, para a recusa.
INSERT INTO secretaria.familia (fam_id, fam_igr_id, fam_nome) OVERRIDING SYSTEM VALUE VALUES (3001, 2, 'Família de outra igreja');

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '6', false) \g /dev/null

\echo '1. escala de dezembro: o dia 05/12 com a família da Escola Sabatina e as funções do culto'
INSERT INTO actividades.escala_plano (epl_igr_id, epl_titulo, epl_data_inicio, epl_data_fim)
VALUES (1, 'Escala do culto V44', '2026-12-01', '2026-12-31') RETURNING epl_titulo;
INSERT INTO actividades.escala_dia (eds_epl_id, eds_data, eds_fam_id)
SELECT epl_id, '2026-12-05', 2201 FROM actividades.escala_plano WHERE epl_titulo = 'Escala do culto V44' RETURNING eds_data, eds_fam_id;
\echo '   uma família de outra igreja: recusada'
INSERT INTO actividades.escala_dia (eds_epl_id, eds_data, eds_fam_id)
SELECT epl_id, '2026-12-12', 3001 FROM actividades.escala_plano WHERE epl_titulo = 'Escala do culto V44';
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_mem_id)
SELECT d.eds_id, f.funcao::nucleo.funcao_escala_t, f.mem
  FROM actividades.escala_dia d, (VALUES ('APRESENTADOR_CULTO', 961), ('PREGADOR', 960), ('SERMAO_CRIANCA', 961)) f(funcao, mem)
 WHERE d.eds_data = '2026-12-05' AND d.eds_fam_id = 2201
RETURNING esc_funcao, esc_mem_id, actividades.fn_funcao_escala_nome(esc_funcao) AS nome_no_sms;

\echo '2. preparar a programação de 05/12 a partir do modelo: partes, itens e quem a escala põe'
SELECT actividades.fn_programa_preparar(1, '2026-12-05') IS NOT NULL AS preparada;
SELECT p.ppa_ordem, p.ppa_titulo, p.ppa_apresentador_mem_id, p.ppa_apresentador_fam_id, count(i.pit_id) AS itens
  FROM actividades.programa_parte p JOIN actividades.programa_dia d ON d.pgd_id = p.ppa_pgd_id
  LEFT JOIN actividades.programa_item i ON i.pit_ppa_id = p.ppa_id
 WHERE d.pgd_data = '2026-12-05' GROUP BY 1, 2, 3, 4 ORDER BY 1;
SELECT i.pit_hora_inicio, i.pit_actividade, i.pit_responsavel_mem_id, i.pit_responsavel_fam_id, i.pit_responsavel_texto, i.pit_destaque
  FROM actividades.programa_item i JOIN actividades.programa_dia d ON d.pgd_id = i.pit_pgd_id
  JOIN actividades.programa_parte p ON p.ppa_id = i.pit_ppa_id
 WHERE d.pgd_data = '2026-12-05' AND p.ppa_ordem = 3 ORDER BY i.pit_ordem LIMIT 9;
\echo '   a mesma igreja e o mesmo dia outra vez: recusado'
SELECT actividades.fn_programa_preparar(1, '2026-12-05');

\echo '3. ajustar: um item com dois responsáveis é recusado; horas mal escritas também'
UPDATE actividades.programa_item SET pit_responsavel_texto = 'Visitante' WHERE pit_actividade = 'Sermão principal'
   AND pit_pgd_id = (SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2026-12-05');
UPDATE actividades.programa_item SET pit_hora_inicio = '11h15' WHERE pit_actividade = 'Sermão principal'
   AND pit_pgd_id = (SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2026-12-05');

\echo '4. mudar o pregador na escala e voltar a preencher: só muda o que vem da escala'
UPDATE actividades.escala SET esc_mem_id = 961 WHERE esc_funcao = 'PREGADOR' AND esc_data = '2026-12-05';
SELECT actividades.fn_programa_preencher((SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2026-12-05')) AS mudaram;

\echo '5. copiar para 12/12: as mesmas partes e itens'
SELECT actividades.fn_programa_preparar(1, '2026-12-12', (SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2026-12-05')) IS NOT NULL AS copiada;
SELECT d.pgd_data, count(DISTINCT p.ppa_id) AS partes, count(i.pit_id) AS itens
  FROM actividades.programa_dia d JOIN actividades.programa_parte p ON p.ppa_pgd_id = d.pgd_id
  JOIN actividades.programa_item i ON i.pit_ppa_id = p.ppa_id
 GROUP BY 1 ORDER BY 1;

\echo '6. o tesoureiro não prepara programações'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT actividades.fn_programa_preparar(1, '2026-12-19');
RESET ROLE;

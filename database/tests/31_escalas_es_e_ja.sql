\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V45: escalas da Escola Sabatina e da JA com as colunas que cada igreja define (membro ou família), ligação à
-- programação do dia e o nome da coluna no SMS.
-- Dos testes anteriores: 6 = secretário da igreja 1; 2 = tesoureiro; 103 Tito (igreja 1, com telemóvel e consentimento);
-- 960 Paulo (igreja 1); 2201 Família Langa (igreja 1); 3001 família da igreja 2.

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '6', false) \g /dev/null

\echo '1. as colunas da escala da Escola Sabatina desta igreja: apresentador (membro) e família da programação'
INSERT INTO actividades.escala_coluna (ecn_igr_id, ecn_tipo, ecn_ordem, ecn_nome, ecn_responsavel)
VALUES (1, 'ESCOLA_SABATINA', 1, 'Família da programação', 'FAMILIA'), (1, 'ESCOLA_SABATINA', 2, 'Apresentador', 'MEMBRO'),
       (1, 'JA', 1, 'Apresentador', 'MEMBRO')
RETURNING ecn_tipo, ecn_nome, ecn_responsavel;
\echo '   a mesma coluna duas vezes, e um tipo desconhecido: recusados'
INSERT INTO actividades.escala_coluna (ecn_igr_id, ecn_tipo, ecn_nome) VALUES (1, 'ESCOLA_SABATINA', 'Apresentador');
INSERT INTO actividades.escala_coluna (ecn_igr_id, ecn_tipo, ecn_nome) VALUES (1, 'CULTO', 'Porteiro');

\echo '2. a escala da Escola Sabatina de janeiro (publicada) e o sábado 09/01'
INSERT INTO actividades.escala_plano (epl_igr_id, epl_titulo, epl_tipo, epl_data_inicio, epl_data_fim, epl_publicada)
VALUES (1, 'Escala da Escola Sabatina', 'ESCOLA_SABATINA', '2027-01-01', '2027-01-31', TRUE) RETURNING epl_titulo, epl_tipo;
INSERT INTO actividades.escala_dia (eds_epl_id, eds_data)
SELECT epl_id, '2027-01-09' FROM actividades.escala_plano WHERE epl_titulo = 'Escala da Escola Sabatina' RETURNING eds_data;

\echo '3. escalar: a família na coluna da família, o Tito na do apresentador'
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_ecn_id, esc_fam_id)
SELECT d.eds_id, 'OUTRA', c.ecn_id, 2201 FROM actividades.escala_dia d, actividades.escala_coluna c
 WHERE d.eds_data = '2027-01-09' AND c.ecn_nome = 'Família da programação' RETURNING esc_data, esc_fam_id;
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_ecn_id, esc_mem_id)
SELECT d.eds_id, 'OUTRA', c.ecn_id, 103 FROM actividades.escala_dia d, actividades.escala_coluna c
 WHERE d.eds_data = '2027-01-09' AND c.ecn_tipo = 'ESCOLA_SABATINA' AND c.ecn_nome = 'Apresentador' RETURNING esc_data, esc_mem_id;
\echo '   recusados: sem coluna; um membro na coluna da família; a coluna da JA; uma família de outra igreja'
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_mem_id)
SELECT eds_id, 'PREGADOR', 960 FROM actividades.escala_dia WHERE eds_data = '2027-01-09';
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_ecn_id, esc_mem_id)
SELECT d.eds_id, 'OUTRA', c.ecn_id, 960 FROM actividades.escala_dia d, actividades.escala_coluna c
 WHERE d.eds_data = '2027-01-09' AND c.ecn_nome = 'Família da programação';
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_ecn_id, esc_mem_id)
SELECT d.eds_id, 'OUTRA', c.ecn_id, 960 FROM actividades.escala_dia d, actividades.escala_coluna c
 WHERE d.eds_data = '2027-01-09' AND c.ecn_tipo = 'JA';
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_ecn_id, esc_fam_id)
SELECT d.eds_id, 'OUTRA', c.ecn_id, 3001 FROM actividades.escala_dia d, actividades.escala_coluna c
 WHERE d.eds_data = '2027-01-09' AND c.ecn_nome = 'Família da programação';
\echo '   na escala do culto não se escala uma família'
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_fam_id)
SELECT eds_id, 'PREGADOR', 2201 FROM actividades.escala_dia WHERE eds_data = '2026-12-05';

\echo '4. programação de 09/01: o modelo já não liga a ES; liga-se o apresentador da ES à coluna e preenche-se'
SELECT actividades.fn_programa_preparar(1, '2027-01-09') IS NOT NULL AS preparada;
SELECT p.ppa_titulo, p.ppa_escala, p.ppa_apresentador_fam_id FROM actividades.programa_parte p JOIN actividades.programa_dia d ON d.pgd_id = p.ppa_pgd_id
 WHERE d.pgd_data = '2027-01-09' AND p.ppa_ordem IN (1, 4) ORDER BY p.ppa_ordem;
UPDATE actividades.programa_parte SET ppa_ecn_id = (SELECT ecn_id FROM actividades.escala_coluna WHERE ecn_nome = 'Família da programação')
 WHERE ppa_ordem = 1 AND ppa_pgd_id = (SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2027-01-09');
UPDATE actividades.programa_item SET pit_ecn_id = (SELECT ecn_id FROM actividades.escala_coluna WHERE ecn_tipo = 'ESCOLA_SABATINA' AND ecn_nome = 'Apresentador')
 WHERE pit_actividade = 'Oração inicial' AND pit_ppa_id = (SELECT ppa_id FROM actividades.programa_parte p JOIN actividades.programa_dia d ON d.pgd_id = p.ppa_pgd_id
                                                         WHERE d.pgd_data = '2027-01-09' AND p.ppa_ordem = 1);
SELECT actividades.fn_programa_preencher((SELECT pgd_id FROM actividades.programa_dia WHERE pgd_data = '2027-01-09')) AS mudaram;
SELECT p.ppa_titulo, p.ppa_apresentador_fam_id, i.pit_actividade, i.pit_responsavel_mem_id
  FROM actividades.programa_parte p JOIN actividades.programa_item i ON i.pit_ppa_id = p.ppa_id
  JOIN actividades.programa_dia d ON d.pgd_id = p.ppa_pgd_id
 WHERE d.pgd_data = '2027-01-09' AND i.pit_actividade = 'Oração inicial' AND p.ppa_ordem = 1;
RESET ROLE;

\echo '5. lembrete de quarta-feira: o Tito recebe o SMS com o nome da coluna (a família não recebe SMS)'
SELECT actividades.fn_lembretes_escala('2027-01-06 10:00+02') >= 1 AS criou;
SELECT ntf_mem_id, regexp_replace(ntf_mensagem, '^.*: lembrete', 'lembrete') AS mensagem FROM nucleo.notificacao
 WHERE ntf_origem_tabela = 'actividades.escala' AND ntf_mensagem LIKE '%09/01%' ORDER BY ntf_id;

\echo '6. procurar antes de registar: o nome como se ouve, trocado, e o telemóvel'
SELECT nucleo.fn_nome_fonetico('Phelisberto Côssa') AS a, nucleo.fn_nome_fonetico('Felisberto Cosa') AS b,
       nucleo.fn_nome_fonetico('Zacarias Hélder') AS c, nucleo.fn_nome_fonetico('Sacarias Elder') AS d;
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
\echo '   o Paulo Mabjaia escrito "Mabjaya Paulo" (trocado e com y) e a mesma data: provável'
SELECT nome, pontos >= 70 AS provavel, motivos FROM nucleo.fn_membros_parecidos('Mabjaya', 'Paulo', '1970-02-02');
\echo '   o mesmo telemóvel do Tito, com outro nome: aparece, como aviso'
SELECT nome, motivos FROM nucleo.fn_membros_parecidos('Outro', 'Nome', NULL, NULL, NULL, NULL, '84 111 2233');
RESET ROLE;

\echo '7. fundo de construção: tipo próprio da igreja; a contagem tem a parte e confere-a à parte'
UPDATE tesouraria.fundo SET fun_tipo = 'CONSTRUCAO', fun_nome = 'Construção'
 WHERE fun_igr_id = 1 AND fun_tipo = 'PROJECTO' AND fun_id = (SELECT min(fun_id) FROM tesouraria.fundo WHERE fun_igr_id = 1 AND fun_tipo = 'PROJECTO')
RETURNING fun_tipo, fun_nome;
INSERT INTO tesouraria.fundo (fun_codigo, fun_nome, fun_tipo, fun_igr_id)
SELECT 'CONSTR-' || 1, 'Construção', 'CONSTRUCAO', 1 WHERE NOT EXISTS (SELECT 1 FROM tesouraria.fundo WHERE fun_igr_id = 1 AND fun_tipo = 'CONSTRUCAO')
RETURNING fun_tipo, fun_nome;
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO tesouraria.contagem_numerario (cnu_igr_id, cnu_cfi_id, cnu_data, cnu_contador1_mem_id, cnu_contador2_mem_id, cnu_total_contado,
                                           cnu_dizimos, cnu_ofertas, cnu_escola_sabatina, cnu_outras, cnu_construcao)
SELECT 1, cfi_id, '2027-01-09', 960, 961, 1500, 1000, 200, 100, 0, 200 FROM tesouraria.conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' ORDER BY cfi_id LIMIT 1
RETURNING cnu_total_contado, cnu_construcao;
\echo '   as partes têm de somar o total (com a construção)'
INSERT INTO tesouraria.contagem_numerario (cnu_igr_id, cnu_cfi_id, cnu_data, cnu_contador1_mem_id, cnu_contador2_mem_id, cnu_total_contado,
                                           cnu_dizimos, cnu_ofertas, cnu_escola_sabatina, cnu_outras, cnu_construcao)
SELECT 1, cfi_id, '2027-01-16', 960, 961, 1500, 1000, 200, 100, 0, 100 FROM tesouraria.conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' ORDER BY cfi_id LIMIT 1;
SELECT cnu_construcao, construcao_lancado, cnu_outras, outras_lancado FROM tesouraria.vw_contagem_conferencia WHERE cnu_data = '2027-01-09';
RESET ROLE;

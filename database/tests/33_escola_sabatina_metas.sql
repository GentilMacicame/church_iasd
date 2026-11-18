\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V47: metas individuais (a da classe calcula-se), ofertas de cada aluno na chamada, acompanhamento e semanas especiais.
-- Dos testes anteriores: classe "Grupo 1" (classe_trimestre 1, 14 sábados, relatório 3 aberto); 1 = administrador e
-- 7 = secretário da ES da igreja 1 (só lê os alvos, como as metas: quem os define é o director da ES); 2 = tesoureiro; 960 Paulo, 961 Joana e 103 Tito (igreja 1). Aqui matriculam-se o Paulo e a Joana.
INSERT INTO escola_sabatina.matricula (ema_ecl_id, ema_mem_id)
SELECT ect_ecl_id, x FROM escola_sabatina.classe_trimestre, (VALUES (960), (961)) v(x) WHERE ect_id = 1;
SELECT setval(pg_get_serial_sequence('escola_sabatina.presenca', 'epr_id'), (SELECT coalesce(max(epr_id), 1) FROM escola_sabatina.presenca)) \g /dev/null

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '1', false) \g /dev/null

\echo '1. metas individuais do trimestre: Paulo 1 400,00 e Joana 700,00; a meta da classe calcula-se (2 100 ÷ 14 sábados)'
INSERT INTO escola_sabatina.meta_individual (emt_ect_id, emt_mem_id, emt_igr_id, emt_alvo_oferta)
VALUES (1, 960, 1, 1400), (1, 961, 1, 700) RETURNING emt_mem_id, emt_alvo_oferta;
SELECT ect_alvo_oferta_sabado AS alvo_por_sabado FROM escola_sabatina.classe_trimestre WHERE ect_id = 1;
\echo '   o Tito não está matriculado nesta classe: recusado; e uma meta negativa também'
INSERT INTO escola_sabatina.meta_individual (emt_ect_id, emt_mem_id, emt_igr_id, emt_alvo_oferta) VALUES (1, 103, 1, 500);
UPDATE escola_sabatina.meta_individual SET emt_alvo_oferta = -1 WHERE emt_ect_id = 1 AND emt_mem_id = 961;
\echo '   a Joana passa a 1 400,00: a meta da classe acompanha'
UPDATE escola_sabatina.meta_individual SET emt_alvo_oferta = 1400 WHERE emt_ect_id = 1 AND emt_mem_id = 961;
SELECT ect_alvo_oferta_sabado AS alvo_por_sabado FROM escola_sabatina.classe_trimestre WHERE ect_id = 1;

\echo '2. a chamada com a oferta de cada aluno (relatório 3); oferta negativa recusada'
INSERT INTO escola_sabatina.presenca (epr_ers_id, epr_mem_id, epr_igr_id, epr_presente, epr_estudou_licao, epr_oferta)
VALUES (3, 960, 1, TRUE, TRUE, 100), (3, 961, 1, TRUE, FALSE, 50) RETURNING epr_mem_id, epr_oferta;
UPDATE escola_sabatina.presenca SET epr_oferta = -5 WHERE epr_ers_id = 3 AND epr_mem_id = 960;

\echo '3. acompanhamento por aluno e por classe'
SELECT nome, meta, contribuido, presencas, cumprimento FROM escola_sabatina.vw_metas_alunos WHERE classe_trimestre_id = 1 ORDER BY nome;
SELECT classe, alunos, com_meta, meta, identificado, contribuido >= identificado AS colectivo_inclui_individual
  FROM escola_sabatina.vw_metas_classes WHERE classe_trimestre_id = 1;

\echo '4. semanas especiais: a semana de oração; tipo desconhecido e datas trocadas recusados'
INSERT INTO escola_sabatina.semana_especial (ese_igr_id, ese_tipo, ese_nome, ese_data_inicio, ese_data_fim)
VALUES (1, 'ORACAO', 'Semana de Oração', '2026-11-07', '2026-11-14') RETURNING ese_tipo, ese_nome;
INSERT INTO escola_sabatina.semana_especial (ese_igr_id, ese_tipo, ese_nome, ese_data_inicio, ese_data_fim) VALUES (1, 'FESTA', 'Festa', '2026-12-01', '2026-12-02');
INSERT INTO escola_sabatina.semana_especial (ese_igr_id, ese_tipo, ese_nome, ese_data_inicio, ese_data_fim) VALUES (1, 'FAMILIA', 'Semana da Família', '2026-12-10', '2026-12-01');

\echo '5. o tesoureiro e o secretário da ES não definem metas (o secretário da ES vê-as)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO escola_sabatina.meta_individual (emt_ect_id, emt_mem_id, emt_igr_id, emt_alvo_oferta) VALUES (1, 960, 1, 10);
SELECT set_config('app.usuario_id', '7', false) \g /dev/null
INSERT INTO escola_sabatina.meta_individual (emt_ect_id, emt_mem_id, emt_igr_id, emt_alvo_oferta) VALUES (1, 960, 1, 10);
SELECT count(*) AS metas_que_ve FROM escola_sabatina.meta_individual WHERE emt_ect_id = 1;
RESET ROLE;

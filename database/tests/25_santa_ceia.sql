\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V39: Santa Ceia (agendamento e participantes).
-- Dos testes anteriores: 950 = secretário da igreja 1; 11 = director de departamento da igreja 1; 2 = tesoureiro da
-- igreja 1; 4 = tesoureiro da igreja 2; 960 = Paulo Mabjaia (membro da igreja 1); 100 = Ana Cossa (igreja 2).

SET ROLE app_igreja;

\echo '1. secretário (autorizado): agenda a Santa Ceia e regista uma já realizada'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_hora, stc_local, stc_responsavel_mem_id, stc_observacoes)
VALUES (1, '2099-01-03', '09:30', 'Templo', 960, 'Lava-pés antes') RETURNING stc_data, stc_estado;
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_local, stc_estado, stc_homens, stc_mulheres, stc_visitantes)
VALUES (1, '2026-10-03', 'Templo', 'REALIZADA', 30, 45, 6) RETURNING stc_data, stc_estado;

\echo '2. regras: realizada sem números, data futura como realizada, números negativos, duas no mesmo dia, responsável de outra igreja'
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_estado) VALUES (1, '2026-07-04', 'REALIZADA');
UPDATE actividades.santa_ceia SET stc_estado = 'REALIZADA', stc_homens = 1, stc_mulheres = 1, stc_visitantes = 0 WHERE stc_data = '2099-01-03';
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_homens) VALUES (1, '2026-04-04', -1);
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data) VALUES (1, '2099-01-03');
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_responsavel_mem_id) VALUES (1, '2099-04-03', 100);

\echo '3. histórico com o total de participantes'
SELECT igreja, data, estado, responsavel, homens, mulheres, visitantes, total FROM actividades.vw_santa_ceia
 WHERE igreja_id = 1 ORDER BY data;

\echo '4. director de departamento: lê, mas não agenda'
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
SELECT count(*) AS ve FROM actividades.santa_ceia WHERE stc_igr_id = 1;
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data) VALUES (1, '2099-07-03');

\echo '5. tesoureiro da igreja 1 e da igreja 2: não vêem'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS tesoureiro_1 FROM actividades.vw_santa_ceia;
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS tesoureiro_2 FROM actividades.vw_santa_ceia;

\echo '6. V51: acompanhantes (diáconos) da Santa Ceia agendada; repetido e de outra igreja recusados'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id)
SELECT stc_id, 999, 960 FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_estado = 'AGENDADA' ORDER BY stc_id LIMIT 1 RETURNING sca_igr_id AS igreja_copiada;
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id)
SELECT stc_id, 1, 960 FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_estado = 'AGENDADA' ORDER BY stc_id LIMIT 1;
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id)
SELECT stc_id, 1, (SELECT mem_id FROM secretaria.membro WHERE mem_igr_id <> 1 ORDER BY mem_id LIMIT 1) FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_estado = 'AGENDADA' ORDER BY stc_id LIMIT 1;
RESET ROLE;

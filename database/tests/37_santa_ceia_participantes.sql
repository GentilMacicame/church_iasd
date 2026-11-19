\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V52: Santa Ceia — função dos acompanhantes (diácono/diaconisa) e participantes pelo nome com o relatório por membro.
-- 950 = secretário da igreja 1; 2 = tesoureiro da igreja 1 (não lê a Santa Ceia).

-- dois homens e duas mulheres activos da igreja 1, para o teste
UPDATE secretaria.membro m SET mem_sexo = CASE WHEN x.r <= 2 THEN 'M' ELSE 'F' END::nucleo.sexo_t
  FROM (SELECT mem_id, row_number() OVER (ORDER BY mem_id) AS r FROM secretaria.membro
         WHERE mem_igr_id = 1 AND mem_end_date IS NULL AND mem_estado = 'ACTIVO' AND mem_id <> 960) x
 WHERE m.mem_id = x.mem_id AND x.r <= 4;
CREATE TEMP TABLE t_mem AS
SELECT * FROM (SELECT mem_id, mem_sexo, row_number() OVER (PARTITION BY mem_sexo ORDER BY mem_id) AS n
                 FROM secretaria.membro WHERE mem_igr_id = 1 AND mem_end_date IS NULL AND mem_estado = 'ACTIVO' AND mem_sexo IS NOT NULL) x
 WHERE n <= 2;
GRANT SELECT ON t_mem TO app_igreja;
SELECT mem_sexo, count(*) FROM t_mem GROUP BY 1 ORDER BY 1;

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
INSERT INTO actividades.santa_ceia (stc_igr_id, stc_data, stc_local) VALUES (1, '2026-08-01', 'Templo') RETURNING stc_estado;

\echo '1. acompanhantes: um diácono e uma diaconisa; função trocada e função inválida recusadas'
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id, sca_funcao)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'M' AND n = 1), 'DIACONO' FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01' RETURNING sca_funcao;
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id, sca_funcao)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'F' AND n = 1), 'DIACONISA' FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01' RETURNING sca_funcao;
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id, sca_funcao)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'M' AND n = 2), 'DIACONISA' FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';
INSERT INTO actividades.santa_ceia_acompanhante (sca_stc_id, sca_igr_id, sca_mem_id, sca_funcao)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'M' AND n = 2), 'ANCIAO' FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';

\echo '2. participantes pelo nome (ainda agendada): três marcados; repetido e de outra igreja recusados'
INSERT INTO actividades.santa_ceia_participante (scp_stc_id, scp_igr_id, scp_mem_id)
SELECT s.stc_id, 999, t.mem_id FROM actividades.santa_ceia s, t_mem t
 WHERE s.stc_igr_id = 1 AND s.stc_data = '2026-08-01' AND NOT (t.mem_sexo = 'F' AND t.n = 2);
SELECT DISTINCT scp_igr_id AS igreja_copiada FROM actividades.santa_ceia_participante;
INSERT INTO actividades.santa_ceia_participante (scp_stc_id, scp_igr_id, scp_mem_id)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'M' AND n = 1) FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';
INSERT INTO actividades.santa_ceia_participante (scp_stc_id, scp_igr_id, scp_mem_id)
SELECT stc_id, 1, (SELECT mem_id FROM secretaria.membro WHERE mem_igr_id <> 1 ORDER BY mem_id LIMIT 1) FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';

\echo '3. realizada com menos homens do que os nomes: recusada; com os números certos: aceite'
UPDATE actividades.santa_ceia SET stc_estado = 'REALIZADA', stc_homens = 1, stc_mulheres = 5, stc_visitantes = 2 WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';
UPDATE actividades.santa_ceia SET stc_estado = 'REALIZADA', stc_homens = 2, stc_mulheres = 1, stc_visitantes = 2 WHERE stc_igr_id = 1 AND stc_data = '2026-08-01' RETURNING stc_estado;

\echo '4. já realizada: marcar mais uma mulher do que as registadas é recusado'
INSERT INTO actividades.santa_ceia_participante (scp_stc_id, scp_igr_id, scp_mem_id)
SELECT stc_id, 1, (SELECT mem_id FROM t_mem WHERE mem_sexo = 'F' AND n = 2) FROM actividades.santa_ceia WHERE stc_igr_id = 1 AND stc_data = '2026-08-01';

\echo '5. histórico com os nomeados e relatório por membro'
SELECT data, homens, mulheres, visitantes, total, nomeados FROM actividades.vw_santa_ceia WHERE igreja_id = 1 AND data = '2026-08-01';
SELECT t.mem_sexo, t.n, v.celebracoes, v.participacoes, v.faltas, v.ultima
  FROM actividades.vw_santa_ceia_participacao v JOIN t_mem t ON t.mem_id = v.membro_id
 WHERE v.igreja_id = 1 AND v.ano = 2026 ORDER BY t.mem_sexo, t.n;

\echo '6. desmarcar é sempre possível; o tesoureiro não vê os participantes'
UPDATE actividades.santa_ceia_participante SET scp_end_date = now()
 WHERE scp_mem_id = (SELECT mem_id FROM t_mem WHERE mem_sexo = 'M' AND n = 2) AND scp_end_date IS NULL RETURNING scp_end_date IS NOT NULL AS desmarcado;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) AS tesoureiro FROM actividades.santa_ceia_participante;
RESET ROLE;

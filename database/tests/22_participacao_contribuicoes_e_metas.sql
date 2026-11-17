\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V36: participação (inactivos), dízimo lançado em nome do membro e da família, estado civil NOIVO, metas +5%.
-- Dos testes anteriores: 950 = secretário da igreja 1, 2 = tesoureiro da igreja 1, 4 = tesoureiro da igreja 2;
-- 103 Tito Langa (igreja 1, ACTIVO) deu dízimo a 03/10/2026 e a 08/12/2026; 961 Joana Cumbe (igreja 1, ACTIVO).
-- Aqui: a família 2201 (Família Langa) com o Tito, e um membro activo sem participação (2202).
INSERT INTO secretaria.familia (fam_id, fam_igr_id, fam_nome) OVERRIDING SYSTEM VALUE VALUES (2201, 1, 'Família Langa');
UPDATE secretaria.membro SET mem_fam_id = 2201 WHERE mem_id = 103;
INSERT INTO secretaria.membro (mem_id, mem_igr_id, mem_nome, mem_apelido, mem_estado) OVERRIDING SYSTEM VALUE
VALUES (2202, 1, 'Rui', 'Sem Participação', 'ACTIVO');

SET ROLE app_igreja;

\echo '1. secretário: estado civil NOIVO'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE secretaria.membro SET mem_estado_civil = 'NOIVO' WHERE mem_id = 961 RETURNING mem_estado_civil;

\echo '2. participação: o Tito participou (dízimo); o Rui nunca participou = inactivo (janela larga, para não depender da data)'
SELECT p.mem_id, p.ultima_participacao, p.inactivo FROM secretaria.fn_participacao_membros(1, 1200) p
 WHERE p.mem_id IN (103, 2202) ORDER BY p.mem_id;
\echo '   quem não lê os membros da igreja 1 não recebe nada'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS linhas FROM secretaria.fn_participacao_membros(1);

\echo '3. dízimo da Família Langa em Dezembro: o Tito já deu em nome próprio (aviso, não bloqueia)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT tra_id, quem, dizimo FROM tesouraria.fn_contribuicoes_sobrepostas(NULL, 2201, '2026-12-15');
\echo '   noutro mês não há sobreposição; a Joana (sem família) também não'
SELECT count(*) AS janeiro FROM tesouraria.fn_contribuicoes_sobrepostas(NULL, 2201, '2027-01-10');
SELECT count(*) AS joana FROM tesouraria.fn_contribuicoes_sobrepostas(961, NULL, '2026-12-15');
\echo '   tesoureiro de outra igreja: não vê os movimentos da igreja 1'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS outra_igreja FROM tesouraria.fn_contribuicoes_sobrepostas(NULL, 2201, '2026-12-15');

\echo '4. meta anual: alvo de 2026 da oferta de gratidão (fundo da igreja) e sugestão para 2027 = +5%'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO tesouraria.alvo (alv_igr_id, alv_fun_id, alv_descricao, alv_valor_alvo, alv_data_inicio, alv_data_fim)
VALUES (1, 11, 'Meta 2026', 10000, '2026-01-01', '2026-12-31') RETURNING alv_valor_alvo;
SELECT tesouraria.fn_alvo_sugerido(1, 11, 2027) AS sugerido_2027, tesouraria.fn_alvo_sugerido(1, 11, 2028) AS sugerido_2028;
\echo '   o arrecadado do dízimo mês a mês (registo mensal e acumulado)'
SELECT ano, mes, arrecadado FROM tesouraria.vw_fundo_mensal WHERE igreja_id = 1 AND fundo_id = 1 ORDER BY ano, mes;
RESET ROLE;

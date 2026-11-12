\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V30: painel geral das igrejas. Cada um vê só as igrejas a que tem acesso (vistas security_invoker).
-- Dos testes anteriores: 1 = super-administrador; 5 = pastor do distrito 1 (teste 01); 2 = tesoureiro da igreja 1;
-- 13002 = utilizador sem perfil (teste 13). Só se mostram valores que não dependem da data do teste.

\echo '0. uma igreja num outro distrito, para o pastor do distrito 1 não a ver'
INSERT INTO distrito (dst_id, dst_ent_id, dst_nome) VALUES (1601, 1, 'Distrito do teste 16') ON CONFLICT DO NOTHING;
INSERT INTO igreja (igr_ent_id, igr_nome, igr_dst_id) VALUES (1, 'Igreja de outro distrito (teste 16)', 1601) RETURNING igr_nome;

SET ROLE app_igreja;
\echo '1. pastor do distrito: vê só as igrejas do seu distrito, com membros e tesouraria'
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT nome, distrito_pastoral, ve_membros, ve_tesouraria, membros_activos >= 0 AS tem_membros
  FROM organizacao.vw_painel_igrejas ORDER BY nome;
SELECT count(*) FILTER (WHERE distrito_pastoral_id IS DISTINCT FROM 1) AS igrejas_fora_do_distrito
  FROM organizacao.vw_painel_igrejas;
\echo '   e a série mensal: 12 meses por igreja'
SELECT count(*) / NULLIF(count(DISTINCT igr_id), 0) AS meses_por_igreja,
       count(*) FILTER (WHERE nome LIKE '%outro distrito%') AS linhas_de_fora
  FROM organizacao.vw_painel_igrejas_mensal;

\echo '2. super-administrador: vê todas as igrejas (incluindo a do outro distrito)'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
SELECT count(*) = (SELECT count(*) FROM organizacao.igreja WHERE igr_end_date IS NULL) AS ve_todas,
       bool_or(nome LIKE '%outro distrito%') AS ve_a_de_fora
  FROM organizacao.vw_painel_igrejas;

\echo '3. tesoureiro da igreja 1: só a sua igreja'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT igr_id, ve_membros, ve_tesouraria FROM organizacao.vw_painel_igrejas ORDER BY igr_id;

\echo '4. não autorizado: utilizador sem perfil não vê nenhuma igreja'
SELECT set_config('app.usuario_id', '13002', false) \g /dev/null
SELECT count(*) AS igrejas FROM organizacao.vw_painel_igrejas;
SELECT count(*) AS linhas_mensais FROM organizacao.vw_painel_igrejas_mensal;
RESET ROLE;

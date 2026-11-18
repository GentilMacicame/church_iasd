\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V46: a composição dos membros por igreja (Painel geral). Cada utilizador só conta as igrejas que vê.
SET ROLE app_igreja;
\echo '1. o secretário da igreja 1: só a sua igreja, com o sexo, as idades, o estado civil e os sem família'
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
SELECT igr_id, membros >= homens + mulheres AS soma_sexo, membros = menores + jovens + adultos + idosos + idade_desconhecida AS soma_idades,
       membros = casados + uniao_facto + solteiros + viuvos + viuvas + divorciados + noivos + estado_civil_vazio
            + (SELECT count(*) FROM secretaria.membro WHERE mem_igr_id = 1 AND mem_estado = 'ACTIVO' AND mem_estado_civil::text = 'VIUVO' AND mem_sexo IS NULL) AS soma_civil,
       activos_sem_familia <= membros AS sem_familia_ok
  FROM organizacao.vw_painel_membros ORDER BY igr_id;
\echo '2. o tesoureiro de outra igreja não vê os membros da igreja 1'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS igrejas_da_1 FROM organizacao.vw_painel_membros WHERE igr_id = 1;
RESET ROLE;

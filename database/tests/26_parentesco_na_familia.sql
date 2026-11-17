\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V40: parentesco de cada membro com o chefe da família.
-- Dos testes anteriores: 950 = secretário da igreja 1; 2 = tesoureiro da igreja 1; família 2201 (Família Langa) com o
-- Tito (103); 960 Paulo e 961 Joana (igreja 1).

SET ROLE app_igreja;

\echo '1. secretário (autorizado): o Paulo e a Joana entram na Família Langa, com o parentesco'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE secretaria.membro SET mem_parentesco = 'CHEFE' WHERE mem_id = 103;
UPDATE secretaria.membro SET mem_fam_id = 2201, mem_parentesco = 'FILHO' WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_fam_id = 2201, mem_parentesco = 'OUTRO' WHERE mem_id = 961;
SELECT mem_id, mem_parentesco FROM secretaria.vw_membro_basico WHERE mem_fam_id = 2201 ORDER BY mem_id;

\echo '2. regras: dois chefes, valor desconhecido, parentesco sem família'
UPDATE secretaria.membro SET mem_parentesco = 'CHEFE' WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_parentesco = 'PRIMO' WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_parentesco = 'FILHO' WHERE mem_id = 902;

\echo '3. a Joana sai da família: o parentesco é limpo (era em relação ao chefe desta família)'
UPDATE secretaria.membro SET mem_fam_id = NULL WHERE mem_id = 961;
SELECT mem_fam_id, mem_parentesco FROM secretaria.membro WHERE mem_id = 961;

\echo '4. tesoureiro (não autorizado a alterar membros): não muda o parentesco'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE secretaria.membro SET mem_parentesco = 'NETO' WHERE mem_id = 960;
SELECT mem_parentesco AS continua FROM secretaria.membro WHERE mem_id = 960;
RESET ROLE;

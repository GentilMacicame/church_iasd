\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V28: a reunião regista quem fez a meditação (membro ou convidado), o hino e quem fez a primeira e a última oração.
-- Dos testes anteriores: 980 = ADMIN da igreja 1 (pode alterar reuniões); 13002 = utilizador sem perfil.

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '980', false);
\echo '1. o administrador da igreja 1 regista a meditação, o hino e as orações'
UPDATE reuniao SET reu_meditacao_mem_id = (SELECT min(mem_id) FROM membro WHERE mem_igr_id = 1),
                   reu_hino = 'Hino 123 — Castelo forte',
                   reu_oracao_inicial_mem_id = (SELECT min(mem_id) FROM membro WHERE mem_igr_id = 1),
                   reu_oracao_final_mem_id = (SELECT max(mem_id) FROM membro WHERE mem_igr_id = 1)
 WHERE reu_id = (SELECT min(reu_id) FROM reuniao WHERE reu_igr_id = 1 AND reu_estado <> 'ACTA_APROVADA');
SELECT reu_hino, reu_meditacao_mem_id IS NOT NULL AS meditacao, reu_oracao_inicial_mem_id IS NOT NULL AS primeira,
       reu_oracao_final_mem_id IS NOT NULL AS ultima
  FROM reuniao WHERE reu_hino IS NOT NULL;
\echo '2. meditação de um membro E de um convidado ao mesmo tempo: recusado'
UPDATE reuniao SET reu_meditacao_convidado = 'Pastor do distrito' WHERE reu_hino IS NOT NULL;
\echo '3. um convidado em vez do membro: aceite'
UPDATE reuniao SET reu_meditacao_mem_id = NULL, reu_meditacao_convidado = 'Pastor do distrito' WHERE reu_hino IS NOT NULL;
SELECT reu_meditacao_convidado FROM reuniao WHERE reu_hino IS NOT NULL;
\echo '4. um utilizador sem perfil não altera a reunião (0 linhas: não a vê)'
SELECT set_config('app.usuario_id', '13002', false);
UPDATE reuniao SET reu_hino = 'Outro' WHERE reu_hino IS NOT NULL;
RESET ROLE;
SELECT reu_hino AS hino_continua FROM reuniao WHERE reu_hino IS NOT NULL;

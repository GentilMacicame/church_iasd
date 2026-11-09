\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V19: ficha completa do membro e baptismo ligado à igreja e ao pastor.
-- Dos testes anteriores: 950 = secretário da igreja 1, 2 = tesoureiro da igreja 1, 4 = tesoureiro da igreja 2;
-- 900 e 901 = membros da igreja 1.

SET ROLE app_igreja;

\echo '1. secretário (autorizado): preenche a ficha da Elisa'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE secretaria.membro
   SET mem_naturalidade = 'Xai-Xai, Gaza', mem_nacionalidade = 'Moçambicana',
       mem_tipo_identificacao = 'BI', mem_numero_identificacao = '110100000000A',
       mem_profissao = 'Professora', mem_escolaridade = 'SUPERIOR',
       mem_nome_pai = 'João Fumo', mem_nome_mae = 'Maria Cossa',
       mem_provincia = 'Maputo', mem_cidade_distrito = 'Matola', mem_bairro = 'Machava',
       mem_quarteirao = '12', mem_numero_casa = '34'
 WHERE mem_id = 900;
SELECT mem_naturalidade, mem_tipo_identificacao, mem_escolaridade, mem_nome_mae, mem_bairro, mem_numero_casa
  FROM secretaria.membro WHERE mem_id = 900;

\echo '2. valor que não existe na lista: recusado'
UPDATE secretaria.membro SET mem_escolaridade = 'DOUTORAMENTO' WHERE mem_id = 900;

\echo '3. a alteração fica no histórico (só os campos que mudaram)'
RESET ROLE;
SELECT lau_accao, lau_dados_depois ? 'mem_bairro' AS bairro_no_log, lau_dados_depois ? 'mem_nome' AS nome_no_log
  FROM nucleo.log_auditoria WHERE lau_tabela = 'secretaria.membro' AND lau_registo_id = 900 ORDER BY lau_id DESC LIMIT 1;
SET ROLE app_igreja;

\echo '4. secretário: baptismo da Teresa na igreja 1, pelo pastor com conta no sistema'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
INSERT INTO secretaria.baptismo (bap_mem_id, bap_data, bap_local, bap_oficiante, bap_local_igr_id, bap_oficiante_usu_id)
VALUES (901, '2026-08-15', 'Rio Matola', 'Pr. António Mabjaia', 1, 1)
RETURNING bap_local_igr_id, bap_oficiante_usu_id;
\echo '   igreja que não existe: recusado'
INSERT INTO secretaria.baptismo (bap_mem_id, bap_data, bap_local_igr_id) VALUES (900, '2026-08-15', 999999);

\echo '5. tesoureiro da igreja 1 (não autorizado a alterar): lê a ficha, mas a alteração não passa'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT mem_bairro FROM secretaria.membro WHERE mem_id = 900;
UPDATE secretaria.membro SET mem_bairro = 'Outro' WHERE mem_id = 900;
SELECT mem_bairro AS bairro_continua FROM secretaria.membro WHERE mem_id = 900;
INSERT INTO secretaria.membro (mem_igr_id, mem_nome, mem_apelido, mem_bairro) VALUES (1, 'Novo', 'Membro', 'Machava');

\echo '6. tesoureiro de outra igreja: não vê a ficha nem o baptismo'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS ve_a_ficha FROM secretaria.membro WHERE mem_id = 900;
SELECT count(*) AS ve_o_baptismo FROM secretaria.baptismo WHERE bap_mem_id = 901;
RESET ROLE;

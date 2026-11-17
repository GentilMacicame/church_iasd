\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V42: fundo de maneio, participantes da contagem e SMS do recibo com o resumo por fundo (uma vez por recibo).
-- Dos testes anteriores: 2 = tesoureiro da igreja 1; 4 = tesoureiro da igreja 2; contagem 9231 (igreja 1, aberta);
-- 960 Paulo (igreja 1); 100 Ana (igreja 2); movimento 501 = dízimo 1000 + oferta 400 do Tito (103), confirmado.
-- Aqui o Tito recebe um telemóvel e o consentimento para SMS (como o secretário faria na ficha).
INSERT INTO secretaria.contacto (cto_mem_id, cto_tipo, cto_valor, cto_principal) VALUES (103, 'TELEFONE', '+258841112233', TRUE);
INSERT INTO secretaria.consentimento (cns_mem_id, cns_tipo, cns_concedido) VALUES (103, 'CONTACTO_SMS', TRUE);
-- os testes anteriores inseriram contas com o id escrito à mão: a sequência avança para lá delas
SELECT setval(pg_get_serial_sequence('tesouraria.conta_financeira', 'cfi_id'), (SELECT max(cfi_id) FROM tesouraria.conta_financeira)) \g /dev/null

SET ROLE app_igreja;

\echo '1. tesoureiro (autorizado): abre o fundo de maneio com 5 000,00'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO tesouraria.conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, cfi_saldo_inicial, cfi_data_saldo_inicial)
VALUES (1, 'FUNDO_MANEIO', 'Fundo de maneio', 5000, '2026-11-01') RETURNING cfi_tipo, cfi_nome, cfi_saldo_inicial;
SELECT cfi_nome, saldo FROM tesouraria.vw_saldo_conta WHERE cfi_nome = 'Fundo de maneio';
\echo '   um fundo de maneio não pode ser conta da Missão'
INSERT INTO tesouraria.conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial, cfi_ent_id)
VALUES (1, 'FUNDO_MANEIO', 'Maneio da Missão', '2026-11-01', 1);

\echo '2. participantes da contagem: tesoureiro e diácono; de outra igreja e função desconhecida recusados'
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 960, 'TESOUREIRO'), (9231, 103, 'DIACONO')
RETURNING cpa_mem_id, cpa_funcao;
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 100, 'ANCIAO');
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 961, 'CONTABILISTA');

\echo '3. recibo do movimento do Tito: o SMS leva o resumo por fundo e a chave do recibo'
INSERT INTO tesouraria.recibo (rec_tra_id, rec_igr_id, rec_ano, rec_numero)
VALUES (501, 1, 2026, tesouraria.fn_proximo_recibo(1, 2026)) RETURNING rec_ano;
RESET ROLE;
SELECT ntf_canal, ntf_destino, regexp_replace(ntf_mensagem, 'Recibo n.º [0-9]+/', 'Recibo n.º N/') AS mensagem,
       ntf_chave LIKE 'recibo:%' AS tem_chave, ntf_estado
  FROM nucleo.notificacao WHERE ntf_origem_tabela = 'tesouraria.recibo' AND ntf_mem_id = 103;
SET ROLE app_igreja;

\echo '4. tesoureiro de outra igreja: não vê a contagem nem os participantes'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS participantes FROM tesouraria.contagem_participante WHERE cpa_cnu_id = 9231;
INSERT INTO tesouraria.contagem_participante (cpa_cnu_id, cpa_mem_id, cpa_funcao) VALUES (9231, 961, 'OUTRO');
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V21: dízimos e ofertas do sábado, pagamentos directos na conta da Missão e a parte da igreja nas ofertas.
-- Dos testes anteriores: entidade 1 recebe os fundos da Associação (dízimo 100%, oferta combinada 50%),
-- 2 = tesoureiro da igreja 1, 3 = ancião da igreja 1, 4 = tesoureiro da igreja 2; 100 e 103 = membros da igreja 1;
-- conta 2 = caixa da igreja 1. Tudo em Dezembro de 2026 (mês sem movimentos dos outros testes).

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null

\echo '1. tesoureiro (autorizado): regista a conta bancária da Missão'
INSERT INTO conta_financeira (cfi_id, cfi_igr_id, cfi_tipo, cfi_nome, cfi_banco, cfi_numero, cfi_data_saldo_inicial, cfi_ent_id)
VALUES (50, 1, 'BANCO', 'Conta da Missão (BIM)', 'BIM', '123456789', '2026-01-01', 1) RETURNING cfi_nome, cfi_ent_id;
\echo '   um caixa não pode ser conta da Missão; nem uma entidade que não recebe fundos'
INSERT INTO conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial, cfi_ent_id) VALUES (1, 'CAIXA', 'Caixa da Missão', '2026-01-01', 1);
INSERT INTO conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial, cfi_ent_id) VALUES (1, 'BANCO', 'Outra', '2026-01-01', 2);

\echo '2. sábado: dízimos e ofertas no caixa da igreja (dízimo 2000, oferta combinada 600)'
BEGIN;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_estado, tra_valor_total, tra_cfi_id, tra_mem_id, tra_data_hora)
VALUES (500, 'ENTRADA', 'NUMERARIO', 'CONFIRMADA', 2600, 2, 100, '2026-12-05 11:00+02');
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor) VALUES
 (500, (SELECT fun_id FROM fundo WHERE fun_codigo = 'DIZ'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'R1'), 2000),
 (500, (SELECT fun_id FROM fundo WHERE fun_codigo = 'OCOMB'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'R2'), 600);
COMMIT;

\echo '3. o Tito pagou dízimo 1000 e oferta 400 na conta da Missão e mandou o comprovativo'
\echo '   sem a referência do comprovativo: recusado'
BEGIN;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_estado, tra_valor_total, tra_cfi_id, tra_mem_id, tra_data_hora)
VALUES (501, 'ENTRADA', 'BANCO', 'CONFIRMADA', 1400, 50, 103, '2026-12-08 09:00+02');
ROLLBACK;
BEGIN;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_estado, tra_valor_total, tra_cfi_id, tra_mem_id, tra_referencia, tra_data_hora)
VALUES (501, 'ENTRADA', 'BANCO', 'CONFIRMADA', 1400, 50, 103, 'BIM-778812', '2026-12-08 09:00+02');
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor) VALUES
 (501, (SELECT fun_id FROM fundo WHERE fun_codigo = 'DIZ'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'R1'), 1000),
 (501, (SELECT fun_id FROM fundo WHERE fun_codigo = 'OCOMB'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'R2'), 400);
COMMIT;
SELECT tra_id, tra_referencia, tra_estado FROM transacao WHERE tra_id = 501;
\echo '   um fundo que fica na igreja (orçamento local) não entra na conta da Missão: recusado'
BEGIN;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_mem_id, tra_referencia, tra_data_hora)
VALUES (502, 'ENTRADA', 'BANCO', 100, 50, 103, 'BIM-1', '2026-12-08 09:00+02');
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
VALUES (502, (SELECT fun_id FROM fundo WHERE fun_codigo = 'OLOC'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'R2'), 100);
COMMIT;
\echo '   a igreja não paga nada a partir da conta da Missão, nem transfere para ela'
INSERT INTO transacao (tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_beneficiario, tra_data_hora)
VALUES ('SAIDA', 'BANCO', 100, 50, 'Alguém', '2026-12-08 09:00+02');
INSERT INTO transacao (tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_destino_cfi_id, tra_data_hora)
VALUES ('TRANSFERENCIA', 'BANCO', 100, 2, 50, '2026-12-08 09:00+02');

\echo '4. remessa devida de Dezembro: dízimo 3000 (1000 já pago na Missão), oferta 1000 (50% = 500, 400 já na Missão)'
SELECT fundo_codigo, recebido, devido, remetido, pago_directo, em_falta
  FROM vw_remessa_devida WHERE igr_id = 1 AND ano = 2026 AND mes = 12 ORDER BY fundo_codigo;
\echo '   a contribuição do Tito aparece como paga na Missão, com o comprovativo'
SELECT fundo, valor, pago_na_missao, referencia FROM vw_contribuicoes_membro
 WHERE tra_igr_id = 1 AND periodo_ano = 2026 AND periodo_mes = 12 AND tra_mem_id = 103 ORDER BY fundo;
\echo '   saldo da conta da Missão: marcado com a entidade (não é dinheiro da igreja)'
SELECT cfi_nome, saldo, entidade_id FROM vw_saldo_conta WHERE cfi_id = 50;

\echo '5. parte da igreja na oferta combinada'
SELECT disponivel AS disponivel_ocomb FROM vw_saldo_fundo WHERE igr_id = 1 AND fun_codigo = 'OCOMB' \gset
\echo '   saída de 1 MT acima da parte da igreja, aprovada pelo ancião: recusada ao confirmar'
BEGIN;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_beneficiario, tra_data_hora)
VALUES (510, 'SAIDA', 'NUMERARIO', :disponivel_ocomb + 1, 2, 'Ferragem', '2026-12-10 10:00+02');
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
VALUES (510, (SELECT fun_id FROM fundo WHERE fun_codigo = 'OCOMB'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'D3'), :disponivel_ocomb + 1);
COMMIT;
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(510) IS NOT NULL AS aprovada;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE transacao SET tra_estado = 'CONFIRMADA' WHERE tra_id = 510;
SELECT tra_estado AS continua FROM transacao WHERE tra_id = 510;
\echo '   a mesma saída pelo valor exacto da parte da igreja: confirmada'
BEGIN;
UPDATE transacao_linha SET tli_valor = :disponivel_ocomb WHERE tli_tra_id = 510;
UPDATE transacao SET tra_valor_total = :disponivel_ocomb WHERE tra_id = 510;
COMMIT;
UPDATE transacao SET tra_estado = 'CONFIRMADA' WHERE tra_id = 510;
SELECT tra_estado FROM transacao WHERE tra_id = 510;
SELECT fun_codigo, por_remeter, disponivel FROM vw_saldo_fundo WHERE igr_id = 1 AND fun_codigo = 'OCOMB';

\echo '6. remessa complementar: duas preparadas do mesmo mês (a segunda falha); depois de enviada a primeira, outra (passa)'
INSERT INTO remessa (rem_id, rem_igr_id, rem_ent_id, rem_ano, rem_mes) VALUES (90, 1, 1, 2026, 12);
INSERT INTO remessa (rem_id, rem_igr_id, rem_ent_id, rem_ano, rem_mes) VALUES (92, 1, 1, 2026, 12);
UPDATE remessa SET rem_estado = 'ENVIADA', rem_enviada_em = '2026-12-31' WHERE rem_id = 90;
INSERT INTO remessa (rem_id, rem_igr_id, rem_ent_id, rem_ano, rem_mes) VALUES (91, 1, 1, 2026, 12) RETURNING rem_id, rem_estado;

\echo '7. o Tito (membro sem perfil) vê nas suas contribuições que pagou na Missão'
-- 8 = utilizador do Tito (membro 103), do teste 02
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT fundo, valor, pago_na_missao FROM vw_contribuicoes_membro WHERE periodo_ano = 2026 AND periodo_mes = 12 ORDER BY fundo;
SELECT count(*) AS ve_contas FROM conta_financeira;

\echo '8. tesoureiro de outra igreja (não autorizado): não vê a conta da Missão da igreja 1 nem lança nela'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS ve_a_conta FROM conta_financeira WHERE cfi_id = 50;
SELECT count(*) AS ve_pagamentos FROM vw_pago_na_missao WHERE igr_id = 1;
INSERT INTO transacao (tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_referencia, tra_data_hora)
VALUES ('ENTRADA', 'BANCO', 100, 50, 'X', '2026-12-08 09:00+02');
RESET ROLE;

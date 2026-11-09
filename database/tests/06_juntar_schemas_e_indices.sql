\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V18: pagamentos → tesouraria, comunicacao → nucleo; índices (igreja, id).
-- Utilizadores dos testes anteriores: 2 = tesoureiro da igreja 1, 3 = ancião da igreja 1, 950 = secretário da igreja 1.

\echo '1. seis schemas (pagamentos e comunicacao já não existem)'
SELECT string_agg(nspname, ', ' ORDER BY nspname) AS schemas FROM pg_namespace
 WHERE nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'pagamentos', 'comunicacao');

\echo '2. códigos de permissão com o schema novo'
SELECT count(*) FILTER (WHERE prm_codigo ~ '^(pagamentos|comunicacao)\.') AS codigos_antigos,
       count(*) FILTER (WHERE prm_codigo ~ '^tesouraria\.(pagamento_mpesa|mpesa_callback_log|pagamento_bancario)\.') AS mpesa_e_bancos,
       count(*) FILTER (WHERE prm_codigo LIKE 'nucleo.notificacao.%') AS fila_mensagens
  FROM nucleo.permissao;

\echo '3. quem tem as permissões que mudaram de nome (iguais às de antes da V18)'
SELECT p.per_nome,
       count(*) FILTER (WHERE m.prm_codigo LIKE 'tesouraria.pagamento_mpesa.%') AS mpesa,
       count(*) FILTER (WHERE m.prm_codigo LIKE 'tesouraria.pagamento_bancario.%') AS bancos,
       count(*) FILTER (WHERE m.prm_codigo LIKE 'nucleo.notificacao.%') AS fila
  FROM nucleo.perfil_permissao pp JOIN nucleo.perfil p ON p.per_id = pp.ppe_per_id
  JOIN nucleo.permissao m ON m.prm_id = pp.ppe_prm_id
 WHERE pp.ppe_end_date IS NULL
   AND m.prm_codigo ~ '^(tesouraria\.(pagamento_mpesa|mpesa_callback_log|pagamento_bancario)|nucleo\.notificacao)\.'
 GROUP BY p.per_nome ORDER BY p.per_nome;

\echo '4. nada ficou a apontar para os schemas antigos (funções, políticas, triggers)'
SELECT (SELECT count(*) FROM pg_proc WHERE prosrc ~ '\m(pagamentos|comunicacao)\.'
                                          OR array_to_string(proconfig, ',') ~ '\m(pagamentos|comunicacao)\M') AS funcoes,
       (SELECT count(*) FROM pg_policies WHERE coalesce(qual, '') || coalesce(with_check, '') ~ '(pagamentos|comunicacao)\.') AS politicas,
       (SELECT count(*) FROM pg_trigger WHERE encode(tgargs, 'escape') ~ '(pagamentos|comunicacao)\.') AS triggers;

\echo '5. índices (igreja, id) no lugar dos índices (igreja)'
SELECT count(*) FILTER (WHERE indexname LIKE 'idx\_%\_igr\_pagina') AS novos,
       count(*) FILTER (WHERE indexname ~ '^idx_(uig|fam|mem|reu|mmb|ofi|epl|ect|ers|epr|alv|orc|des|cnu|tra|tli|sdc|ntf)_igr_id$') AS antigos
  FROM pg_indexes;

SET ROLE app_igreja;

\echo '6. tesoureiro (autorizado): vê a fila de mensagens da igreja e termina uma mensagem'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT count(*) > 0 AS ve_a_fila FROM nucleo.notificacao;
SELECT min(ntf_id) AS ntf FROM nucleo.notificacao WHERE ntf_end_date IS NULL \gset
UPDATE nucleo.notificacao SET ntf_end_date = now() WHERE ntf_id = :ntf;
SELECT ntf_end_date IS NOT NULL AS terminada FROM nucleo.notificacao WHERE ntf_id = :ntf;

\echo '7. tesoureiro: regista e termina o detalhe bancário de um movimento'
SELECT min(tra_id) AS tra FROM tesouraria.transacao WHERE tra_igr_id = 1 \gset
INSERT INTO tesouraria.pagamento_bancario (pba_tra_id, pba_banco, pba_nib, pba_titular)
VALUES (:tra, 'BCI', '000800000000000000001', 'Igreja 1') RETURNING pba_tra_id = :tra AS registado;
UPDATE tesouraria.pagamento_bancario SET pba_end_date = now() WHERE pba_tra_id = :tra;
SELECT count(*) AS terminados FROM tesouraria.pagamento_bancario WHERE pba_tra_id = :tra AND pba_end_date IS NOT NULL;
SELECT count(*) AS permissoes_mpesa_e_bancos FROM nucleo.fn_minhas_permissoes()
 WHERE codigo ~ '^tesouraria\.(pagamento_mpesa|mpesa_callback_log|pagamento_bancario)\.';

\echo '8. ancião (não autorizado): lê a tesouraria, mas não os pagamentos electrónicos nem a fila'
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT count(*) > 0 AS ve_movimentos FROM tesouraria.transacao;
SELECT count(*) AS ve_pagamentos_bancarios FROM tesouraria.pagamento_bancario;
SELECT count(*) AS ve_a_fila FROM nucleo.notificacao;
INSERT INTO tesouraria.pagamento_bancario (pba_tra_id, pba_nib, pba_titular) VALUES (:tra, '000800000000000000002', 'Ancião');
SELECT count(*) AS permissoes_mpesa_e_bancos FROM nucleo.fn_minhas_permissoes()
 WHERE codigo ~ '^tesouraria\.(pagamento_mpesa|mpesa_callback_log|pagamento_bancario)\.';

\echo '9. secretário (não autorizado): não vê a fila nem consegue terminar mensagens'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
SELECT count(*) AS ve_a_fila FROM nucleo.notificacao;
UPDATE nucleo.notificacao SET ntf_end_date = now() WHERE ntf_end_date IS NULL;
INSERT INTO nucleo.notificacao (ntf_igr_id, ntf_canal, ntf_destino, ntf_mensagem) VALUES (1, 'SMS', '+258840000000', 'teste');
RESET ROLE;
\echo '10. só a mensagem que o tesoureiro terminou está terminada'
SELECT count(*) AS terminadas FROM nucleo.notificacao WHERE ntf_end_date IS NOT NULL;

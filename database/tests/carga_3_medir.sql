SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;
\timing off
SELECT 'transacoes' t, count(*) FROM tesouraria.transacao UNION ALL SELECT 'linhas', count(*) FROM tesouraria.transacao_linha
UNION ALL SELECT 'log_auditoria', count(*) FROM nucleo.log_auditoria UNION ALL SELECT 'saldo_diario_fundo', count(*) FROM tesouraria.saldo_diario_fundo;
SELECT pg_size_pretty(pg_database_size(current_database())) tamanho_bd;
SET ROLE app_igreja;
SELECT set_config('app.usuario_id','50',false) \g /dev/null
\timing on
\echo '--- tesoureiro da igreja 150: saldos das contas (tabela pré-calculada)'
SELECT cfi_nome, saldo FROM vw_saldo_conta;
\echo '--- saldos por fundo'
SELECT fun_codigo, saldo FROM vw_saldo_fundo;
\echo '--- remessa devida (24 meses)'
SELECT count(*), sum(em_falta) FROM vw_remessa_devida;
\echo '--- últimos 50 movimentos'
SELECT count(*) FROM (SELECT tra_id FROM transacao ORDER BY tra_data_hora DESC LIMIT 50) x;
\echo '--- declaração anual de um membro'
SELECT * FROM vw_extracto_anual WHERE tra_mem_id = (SELECT min(mem_id) FROM membro WHERE mem_igr_id=150) AND ano = 2025;
\echo '--- mesmo saldo calculado directamente dos movimentos (sem pré-cálculo), para comparar'
SELECT sum(CASE WHEN tra_tipo='ENTRADA' THEN tra_valor_total ELSE -tra_valor_total END) FROM transacao WHERE tra_estado='CONFIRMADA';
RESET ROLE;
\echo '--- Associação (super-admin, 150 igrejas): totais por fundo, só pré-calculado'
SELECT set_config('app.usuario_id','1',false) \g /dev/null
SELECT fun_codigo, sum(saldo) FROM vw_saldo_fundo GROUP BY 1;
\echo '--- Associação: mesmo total directamente das 750 mil linhas'
SELECT tli_fun_id, sum(tli_valor) FROM transacao_linha GROUP BY 1;

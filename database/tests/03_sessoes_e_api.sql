\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
SET ROLE app_igreja;
\echo '1. a API não lê as tabelas de sessão'
SELECT count(*) FROM nucleo.sessao;
\echo '2. 10 falhas bloqueiam o login'
SELECT nucleo.fn_login_falhou('tes@x') FROM generate_series(1,10) \g /dev/null
SELECT nucleo.fn_login_bloqueado_ate('TES@x') IS NOT NULL AS bloqueado;
\echo '3. login certo: abre sessão, desbloqueia, regista último login'
SELECT nucleo.fn_abrir_sessao(2, 'hashA', '10.0.0.1', 'Firefox') AS sessao;
SELECT nucleo.fn_login_bloqueado_ate('tes@x') IS NULL AS desbloqueado, current_setting('app.usuario_id', true) AS sessao_de;
\echo '4. renovar: OK; o mesmo token logo a seguir (outro separador do navegador): CONCORRENTE, não termina nada (V16)'
SELECT * FROM nucleo.fn_renovar_sessao('hashA', 'hashB');
SELECT * FROM nucleo.fn_renovar_sessao('hashA', 'hashC');
\echo '4b. passados 10 segundos, reutilizar o token antigo é roubo: REUTILIZADA e termina tudo; o novo deixa de servir'
SELECT pg_sleep(11) \g /dev/null
SELECT * FROM nucleo.fn_renovar_sessao('hashA', 'hashC');
SELECT * FROM nucleo.fn_renovar_sessao('hashB', 'hashD');
SELECT * FROM nucleo.fn_renovar_sessao('nao-existe', 'x');
\echo '5. recuperar senha: código errado conta tentativas; certo muda a senha'
SELECT * FROM nucleo.fn_pedir_recuperacao('tes@x', 'cod123');
SELECT nucleo.fn_redefinir_senha('tes@x', 'errado', 'novohash');
SELECT nucleo.fn_redefinir_senha('tes@x', 'cod123', 'novohash');
SELECT nucleo.fn_redefinir_senha('tes@x', 'cod123', 'outro');
SELECT * FROM nucleo.fn_credenciais('tes@x');
\echo '6. pedido repetido: guarda e devolve a mesma resposta; repetir a chave falha'
SELECT set_config('app.usuario_id','2',false) \g /dev/null
SELECT nucleo.fn_idempotencia_guardar('11111111-1111-1111-1111-111111111111', 'POST', '/v1/tesouraria/transacoes', 201, '{"id": 99}');
SELECT * FROM nucleo.fn_idempotencia_obter('11111111-1111-1111-1111-111111111111');
SELECT nucleo.fn_idempotencia_guardar('11111111-1111-1111-1111-111111111111', 'POST', '/v1/tesouraria/transacoes', 201, '{"id": 100}');
\echo '7. tesoureiro liga ofertas a um relatório da ES (relatório 2 da classe 1); secretário da ES não pode'
BEGIN; INSERT INTO tesouraria.transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_anonimo,tra_data_hora) VALUES (50,'ENTRADA','NUMERARIO','CONFIRMADA',600,2,true,'2026-10-03 12:00+02');
INSERT INTO tesouraria.transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (50,(SELECT fun_id FROM tesouraria.fundo WHERE fun_codigo='ESM'),3,600); COMMIT;
SELECT escola_sabatina.fn_ligar_ofertas((SELECT ers_id FROM escola_sabatina.relatorio_sabado WHERE ers_ect_id=1 AND ers_esa_id=2), 50);
SELECT set_config('app.usuario_id','7',false) \g /dev/null
SELECT escola_sabatina.fn_ligar_ofertas((SELECT ers_id FROM escola_sabatina.relatorio_sabado WHERE ers_ect_id=1 AND ers_esa_id=2), 50);
UPDATE escola_sabatina.relatorio_sabado SET ers_estado='FECHADO' WHERE ers_ect_id=1 AND ers_esa_id=2;
SELECT ers_estado, ers_tra_id FROM escola_sabatina.relatorio_sabado WHERE ers_ect_id=1 AND ers_esa_id=2;
RESET ROLE;

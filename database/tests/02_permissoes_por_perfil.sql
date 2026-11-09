\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;
SELECT set_config('app.usuario_id','1',false) \g /dev/null
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash, usu_mem_id) VALUES
 (6,'Secretária','sec@x','h',NULL),(7,'Secretário ES','ses@x','h',NULL),(8,'Tito (membro)','tito@x','h',103),
 (9,'Admin igreja','adm@x','h',NULL),(10,'Tesoureira Associação','tas@x','h',NULL),(11,'Director Jovens','dj@x','h',NULL),(12,'Novo','novo@x','h',NULL);
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) SELECT u, 1, (SELECT per_id FROM perfil WHERE per_nome = p)
 FROM (VALUES (6,'SECRETARIO'),(7,'SECRETARIO_ES'),(9,'ADMIN'),(11,'DIRECTOR_DEPARTAMENTO')) x(u,p);
INSERT INTO usuario_entidade (uen_usu_id, uen_ent_id, uen_per_id) VALUES (10, 1, (SELECT per_id FROM perfil WHERE per_nome='TESOUREIRO_ASSOCIACAO'));
INSERT INTO igreja_departamento (ide_id, ide_igr_id, ide_dep_id) VALUES (1, 1, (SELECT dep_id FROM departamento WHERE dep_nome='Ministério Jovem'));
INSERT INTO conta_financeira (cfi_id, cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial) VALUES (9,2,'CAIXA','Caixa Matola','2026-01-01');
SET ROLE app_igreja;

\echo '=== TESOUREIRO (igreja 1)'
SELECT set_config('app.usuario_id','2',false) \g /dev/null
SELECT (SELECT count(*) FROM transacao) transacoes, (SELECT count(*) FROM disciplina) disciplina, (SELECT count(*) FROM movimento_membro) livro_membros, (SELECT count(*) FROM log_auditoria) log;
INSERT INTO membro (mem_igr_id, mem_nome, mem_apelido) VALUES (1,'X','Y');
SELECT usu_senha_hash FROM usuario LIMIT 1;
INSERT INTO saldo_diario_conta (sdc_cfi_id, sdc_igr_id, sdc_data) VALUES (1,1,'2026-01-01');
BEGIN; INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id,tra_data_hora) VALUES (20,'SAIDA','NUMERARIO',100,2,'2026-10-20 10:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (20,(SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'),(SELECT cat_id FROM categoria WHERE cat_codigo='D2'),100); COMMIT;
SELECT tesouraria.fn_aprovar_saida(20);
INSERT INTO transacao (tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id) VALUES ('ENTRADA','NUMERARIO',10,9);
UPDATE transacao SET tra_end_date = now() WHERE tra_id = 20;
\echo '   (terminou a saída pendente 20: tem tesouraria.transacao.terminar)'
BEGIN; INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id,tra_data_hora) VALUES (21,'SAIDA','NUMERARIO',100,2,'2026-11-01 10:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (21,(SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'),(SELECT cat_id FROM categoria WHERE cat_codigo='D2'),100); COMMIT;
INSERT INTO remessa (rem_id, rem_igr_id, rem_ent_id, rem_ano, rem_mes, rem_estado) VALUES (1,1,1,2026,10,'ENVIADA');
SELECT tesouraria.fn_confirmar_remessa(1);

\echo '=== ANCIÃO (igreja 1)'
SELECT set_config('app.usuario_id','3',false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(21);
INSERT INTO transacao (tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id) VALUES ('ENTRADA','NUMERARIO',10,2);
INSERT INTO fecho_periodo (fpe_igr_id, fpe_ano, fpe_mes) VALUES (1, 2026, 9);
UPDATE fecho_periodo SET fpe_end_date = now() WHERE fpe_igr_id = 1 AND fpe_mes = 9;
SELECT 'ancião fechou e reabriu Setembro' ok;

\echo '=== TESOUREIRO confirma a saída aprovada pelo ancião'
SELECT set_config('app.usuario_id','2',false) \g /dev/null
UPDATE transacao SET tra_estado = 'CONFIRMADA' WHERE tra_id = 21;
SELECT tra_estado, tra_aprovado_por_usu_id FROM transacao WHERE tra_id = 21;

\echo '=== TESOUREIRA DA ASSOCIAÇÃO (Associação 1)'
SELECT set_config('app.usuario_id','10',false) \g /dev/null
SELECT (SELECT count(DISTINCT tra_igr_id) FROM transacao) igrejas_visiveis, (SELECT count(*) FROM membro) membros;
SELECT tesouraria.fn_confirmar_remessa(1);
SELECT rem_estado FROM remessa WHERE rem_id = 1;
INSERT INTO transacao (tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id) VALUES ('ENTRADA','NUMERARIO',10,2);

\echo '=== SECRETÁRIA (igreja 1)'
SELECT set_config('app.usuario_id','6',false) \g /dev/null
SELECT (SELECT count(*) FROM disciplina) disciplina, (SELECT count(*) FROM transacao) transacoes, (SELECT count(*) FROM movimento_membro) livro;
INSERT INTO membro (mem_id, mem_igr_id, mem_nome, mem_apelido) VALUES (300, 1, 'Nova', 'Interessada');
UPDATE membro SET mem_validacao = 'APROVADO' WHERE mem_id = 300;
SELECT mem_validacao, mem_validado_por_usu_id FROM membro WHERE mem_id = 300;
INSERT INTO transacao (tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id) VALUES ('ENTRADA','NUMERARIO',10,2);

\echo '=== SECRETÁRIO DA ES (igreja 1)'
SELECT set_config('app.usuario_id','7',false) \g /dev/null
UPDATE relatorio_sabado SET ers_tra_id = 5, ers_estado = 'FECHADO' WHERE ers_ect_id = 1 AND ers_esa_id = 1;
SELECT ers_estado FROM relatorio_sabado WHERE ers_ect_id = 1 AND ers_esa_id = 1;
UPDATE relatorio_sabado SET ers_estado = 'ABERTO' WHERE ers_ect_id = 1 AND ers_esa_id = 1;
UPDATE relatorio_sabado SET ers_end_date = now() WHERE ers_ect_id = 2 AND ers_esa_id = 2;
SELECT (SELECT count(*) FROM transacao) transacoes;

\echo '=== DIRECTOR DE DEPARTAMENTO (igreja 1)'
SELECT set_config('app.usuario_id','11',false) \g /dev/null
INSERT INTO despesa (des_id, des_igr_id, des_ide_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
VALUES (10, 1, 1, (SELECT cat_id FROM categoria WHERE cat_codigo='D4'), (SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'), 'Acampamento de jovens', 3000, 11);
SELECT tesouraria.fn_decidir_despesa(10, true);
SELECT set_config('app.usuario_id','3',false) \g /dev/null
SELECT tesouraria.fn_decidir_despesa(10, true, 2500);
SELECT des_estado, des_valor_aprovado, des_aprovado_por_usu_id FROM despesa WHERE des_id = 10;

\echo '=== MEMBRO sem perfil (Tito, membro 103)'
SELECT set_config('app.usuario_id','8',false) \g /dev/null
SELECT (SELECT count(*) FROM membro) membros_visiveis, (SELECT string_agg(mem_nome, ',') FROM membro) quem,
       (SELECT count(*) FROM transacao) as minhas_transacoes, (SELECT sum(valor) FROM vw_contribuicoes_membro) total_contribuido;
UPDATE usuario SET usu_telefone = '+258840000000' WHERE usu_id = 8;
UPDATE usuario SET usu_super_admin = true WHERE usu_id = 8;

\echo '=== ADMIN da igreja 1'
SELECT set_config('app.usuario_id','9',false) \g /dev/null
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (12, 1, (SELECT per_id FROM perfil WHERE per_nome='TESOUREIRO'));
SELECT 'admin deu TESOUREIRO ao utilizador 12' ok;
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (12, 1, (SELECT per_id FROM perfil WHERE per_nome='PASTOR'));
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (9, 1, (SELECT per_id FROM perfil WHERE per_nome='TESOUREIRO'));
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (12, 2, (SELECT per_id FROM perfil WHERE per_nome='TESOUREIRO'));
UPDATE usuario SET usu_super_admin = true WHERE usu_id = 12;
UPDATE usuario SET usu_senha_hash = 'novo' WHERE usu_id = 4;
SELECT (SELECT count(*) FROM disciplina) disciplina_visivel, (SELECT count(*) FROM log_auditoria) log_visivel;
\echo '=== o que o tesoureiro pode fazer (para a API montar o menu)'
SELECT set_config('app.usuario_id','2',false) \g /dev/null
SELECT count(*) permissoes, count(*) FILTER (WHERE codigo LIKE 'tesouraria.%') de_tesouraria FROM nucleo.fn_minhas_permissoes();
RESET ROLE;

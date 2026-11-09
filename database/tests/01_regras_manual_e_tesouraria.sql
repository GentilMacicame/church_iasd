\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;
SELECT set_config('app.usuario_id','1',false) \g /dev/null
INSERT INTO entidade (ent_id, ent_tipo, ent_nome) VALUES (2,'MISSAO','Missão de teste');
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES (2,'Tesoureiro','tes@x','h'),(3,'Ancião','anc@x','h'),(4,'Tesoureiro Matola','tes2@x','h'),(5,'Pastor','pr@x','h');
INSERT INTO distrito (dst_id, dst_ent_id, dst_nome, dst_pastor_usu_id) VALUES (1,1,'Distrito Centro',5);
UPDATE igreja SET igr_dst_id = 1 WHERE igr_id = 1;
INSERT INTO igreja (igr_id, igr_ent_id, igr_nome) VALUES (2, 1, 'Igreja da Matola');
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (2,1,5),(3,1,3),(4,2,5);
INSERT INTO membro (mem_id, mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento, mem_estado) VALUES (100,1,'Ana','Cossa','1980-01-01','ACTIVO'),(101,1,'Rui','Mabote','1975-05-05','ACTIVO'),(102,1,'Lia','Cossa','2012-03-03','INTERESSADO'),(103,1,'Tito','Langa','1990-01-01','INTERESSADO'),(200,2,'Zé','Matola','1990-01-01','ACTIVO');

\echo '== SECRETARIA'
INSERT INTO reuniao (reu_id, reu_igr_id, reu_tipo, reu_data) VALUES (1,1,'JUNTA_DIRECTIVA','2026-10-04 15:00+02'),(2,1,'REUNIAO_REGULAR','2026-10-10 11:00+02'),(3,1,'REUNIAO_REGULAR','2026-10-17 11:00+02'),(4,2,'REUNIAO_REGULAR','2026-11-07 11:00+02'),(5,1,'ASSEMBLEIA_ADMINISTRATIVA','2026-10-24 15:00+02');
INSERT INTO voto (vot_id, vot_reu_id, vot_numero, vot_tipo, vot_assunto, vot_leitura) VALUES
 (1,1,'J-001','ADMISSAO','Recomenda baptismo de Tito',1),
 (2,2,'2026-010','ADMISSAO','Admissão de Tito por baptismo',1),
 (3,2,'2026-011','TRANSFERENCIA','Carta para Ana (1ª leitura)',1),
 (4,3,'2026-012','TRANSFERENCIA','Carta para Ana (votação)',2),
 (5,4,'2026-020','TRANSFERENCIA','Aceitar Ana (votação)',2),
 (6,5,'2026-030','DISCIPLINA','Censura a Rui',1),
 (7,3,'2026-013','ELEICAO','Relatório da comissão de nomeações',2);
\echo '1. admitir por voto da junta (deve falhar: a junta só recomenda)'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (103,1,'BAPTISMO','2026-10-10',1);
\echo '2. admitir com voto da igreja (passa) e mudar estado à mão (falha)'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (103,1,'BAPTISMO','2026-10-10',2);
SELECT mem_estado, mem_modo_entrada, mem_data_entrada FROM membro WHERE mem_id=103;
UPDATE membro SET mem_estado='REMOVIDO' WHERE mem_id=103;
\echo '3. carta com voto só da 1ª leitura (falha); com a votação (passa)'
INSERT INTO transferencia_membro (tme_id, tme_mem_id, tme_origem_igr_id, tme_destino_igr_id) VALUES (1,100,1,2);
UPDATE transferencia_membro SET tme_estado='CARTA_EMITIDA', tme_origem_vot_id=3, tme_carta_emitida_em='2026-10-17' WHERE tme_id=1;
UPDATE transferencia_membro SET tme_estado='CARTA_EMITIDA', tme_origem_vot_id=4, tme_carta_emitida_em='2026-10-17' WHERE tme_id=1;
SELECT mem_igr_id, mem_estado FROM membro WHERE mem_id=100;
\echo '4. aceitar 7 meses depois (falha: carta válida 6 meses); aceitar a tempo (passa)'
UPDATE transferencia_membro SET tme_estado='CONCLUIDA', tme_destino_vot_id=5, tme_aceite_em='2027-05-20' WHERE tme_id=1;
UPDATE transferencia_membro SET tme_estado='CONCLUIDA', tme_destino_vot_id=5, tme_aceite_em='2026-11-07' WHERE tme_id=1;
SELECT mem_igr_id, mem_estado, mem_modo_entrada FROM membro WHERE mem_id=100;
SELECT mmb_igr_id, mmb_tipo FROM movimento_membro WHERE mmb_mem_id=100 ORDER BY mmb_id;
\echo '5. eleger Rui (passa); censurar Rui -> perde o cargo; carta para Rui sob censura (falha); reeleger (falha)'
INSERT INTO oficial (ofi_id, ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_vot_id, ofi_data_inicio) VALUES (1,101,(SELECT car_id FROM cargo WHERE car_nome='Ancião'),1,7,'2027-01-01');
INSERT INTO disciplina (dsc_mem_id, dsc_vot_id, dsc_data_inicio, dsc_data_fim) VALUES (101,6,'2027-02-01','2027-06-01');
SELECT ofi_data_fim FROM oficial WHERE ofi_id=1;
INSERT INTO transferencia_membro (tme_mem_id, tme_origem_igr_id, tme_destino_externo, tme_estado, tme_origem_vot_id, tme_carta_emitida_em) VALUES (101,1,'Igreja do Maputo','CARTA_EMITIDA',4,'2027-03-01');
INSERT INTO oficial (ofi_mem_id, ofi_car_id, ofi_igr_id, ofi_vot_id, ofi_data_inicio) VALUES (101,(SELECT car_id FROM cargo WHERE car_nome='Diácono'),1,7,'2027-03-01');
\echo '6. censura de 14 meses (falha) e censura a menor sem avisar encarregado (falha)'
INSERT INTO disciplina (dsc_mem_id, dsc_vot_id, dsc_data_inicio, dsc_data_fim) VALUES (103,6,'2027-01-01','2028-03-01');
UPDATE membro SET mem_data_nascimento='2012-01-01' WHERE mem_id=103;
INSERT INTO disciplina (dsc_mem_id, dsc_vot_id, dsc_data_inicio, dsc_data_fim) VALUES (103,6,'2027-01-01','2027-03-01');
\echo '7. falecimento sem voto (passa)'
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data) VALUES (101,1,'FALECIMENTO','2027-07-01');
SELECT * FROM vw_relatorio_mensal_membros ORDER BY ano, mes;

\echo '== TESOURARIA'
SELECT tesouraria.fn_criar_fundos_padrao(1, 50);
INSERT INTO conta_financeira (cfi_id, cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial) VALUES (1,1,'MPESA','M-Pesa','2026-09-01'),(2,1,'CAIXA','Caixa','2026-09-01'),(3,1,'BANCO','BCI','2026-09-01');
SELECT set_config('app.usuario_id','2',false) \g /dev/null
\echo '8. dízimo + ofertas num só M-Pesa (passa)'
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_mem_id,tra_data_hora) VALUES (1,'ENTRADA','MPESA','CONFIRMADA',650,1,103,'2026-10-03 10:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (1,(SELECT fun_id FROM fundo WHERE fun_codigo='DIZ'),1,500),(1,(SELECT fun_id FROM fundo WHERE fun_codigo='OCOMB'),2,100),(1,(SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'),2,50);
COMMIT;
\echo '9. gastar o dízimo na igreja (falha); remeter o dízimo à Associação (passa)'
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_data_hora) VALUES (2,'SAIDA','MPESA','CONFIRMADA',100,1,'2026-10-04 10:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (2,(SELECT fun_id FROM fundo WHERE fun_codigo='DIZ'),(SELECT cat_id FROM categoria WHERE cat_codigo='D3'),100);
COMMIT;
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_data_hora) VALUES (3,'SAIDA','MPESA','CONFIRMADA',500,1,'2026-10-31 10:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (3,(SELECT fun_id FROM fundo WHERE fun_codigo='DIZ'),(SELECT cat_id FROM categoria WHERE cat_codigo='D1'),500);
COMMIT;
\echo '10. fundo da Associação com percentagem errada (falha)'
INSERT INTO fundo (fun_codigo, fun_nome, fun_tipo, fun_percentagem_remessa, fun_destino_ent_id) VALUES ('X','Dízimo errado','DIZIMO',80,1);
\echo '11. ES: fechar relatório com ofertas misturadas num fundo (falha); separadas (passa)'
UPDATE escola_sabatina.relatorio_sabado SET ers_oferta_despesas = 50 WHERE ers_ect_id=1 AND ers_esa_id=1;
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_anonimo,tra_data_hora) VALUES (4,'ENTRADA','NUMERARIO','CONFIRMADA',400,2,true,'2026-09-26 12:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (4,(SELECT fun_id FROM fundo WHERE fun_codigo='ESM'),3,400);
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_anonimo,tra_data_hora) VALUES (5,'ENTRADA','NUMERARIO','CONFIRMADA',400,2,true,'2026-09-26 12:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (5,(SELECT fun_id FROM fundo WHERE fun_codigo='ESM'),3,350),(5,(SELECT fun_id FROM fundo WHERE fun_codigo='ESD'),3,50);
COMMIT;
UPDATE escola_sabatina.relatorio_sabado SET ers_tra_id=4, ers_estado='FECHADO' WHERE ers_ect_id=1 AND ers_esa_id=1;
UPDATE escola_sabatina.relatorio_sabado SET ers_tra_id=5, ers_estado='FECHADO' WHERE ers_ect_id=1 AND ers_esa_id=1;
SELECT ers_estado FROM escola_sabatina.relatorio_sabado WHERE ers_ect_id=1 AND ers_esa_id=1;
\echo '12. estorno sem aprovação (falha); com aprovação do ancião (passa); transferência caixa->banco'
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_estorno_tra_id,tra_mem_id,tra_data_hora) VALUES (6,'SAIDA','MPESA','CONFIRMADA',50,1,1,103,'2026-10-05 09:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (6,(SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'),2,50);
COMMIT;
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id,tra_estorno_tra_id,tra_mem_id,tra_data_hora) VALUES (6,'SAIDA','MPESA',50,1,1,103,'2026-10-05 09:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (6,(SELECT fun_id FROM fundo WHERE fun_codigo='OLOC'),2,50);
COMMIT;
SELECT set_config('app.usuario_id','3',false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(6);
SELECT set_config('app.usuario_id','2',false) \g /dev/null
UPDATE transacao SET tra_estado='CONFIRMADA' WHERE tra_id=6;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_estado,tra_valor_total,tra_cfi_id,tra_destino_cfi_id,tra_data_hora) VALUES (7,'TRANSFERENCIA','BANCO','CONFIRMADA',600,2,3,'2026-10-05 09:00+02');
\echo '13. pendente -> confirmada mais tarde também entra nos saldos'
BEGIN;
INSERT INTO transacao (tra_id,tra_tipo,tra_metodo,tra_valor_total,tra_cfi_id,tra_mem_id,tra_data_hora) VALUES (8,'ENTRADA','MPESA',200,1,100,'2026-10-06 09:00+02');
INSERT INTO transacao_linha (tli_tra_id,tli_fun_id,tli_cat_id,tli_valor) VALUES (8,(SELECT fun_id FROM fundo WHERE fun_codigo='DIZ'),1,200);
COMMIT;
UPDATE transacao SET tra_estado='CONFIRMADA' WHERE tra_id=8;
\echo '== saldos pré-calculados vs. recálculo a partir dos movimentos'
SELECT cfi_nome, saldo FROM vw_saldo_conta ORDER BY cfi_id;
SELECT fun_codigo, entradas, saidas, saldo FROM vw_saldo_fundo ORDER BY fun_id;
CREATE TEMP TABLE antes AS SELECT fun_codigo k, saldo FROM vw_saldo_fundo UNION ALL SELECT cfi_nome, saldo FROM vw_saldo_conta;
SELECT set_config('app.usuario_id','1',false) \g /dev/null
SELECT tesouraria.fn_recalcular_saldos(1);
CREATE TEMP TABLE depois AS SELECT fun_codigo k, saldo FROM vw_saldo_fundo UNION ALL SELECT cfi_nome, saldo FROM vw_saldo_conta;
SELECT (SELECT count(*) FROM depois) linhas, CASE WHEN NOT EXISTS ((SELECT * FROM antes EXCEPT SELECT * FROM depois) UNION (SELECT * FROM depois EXCEPT SELECT * FROM antes))
       THEN 'saldos pré-calculados = recálculo completo' ELSE 'DIFERENÇAS' END AS verificacao;
SELECT fun_id, ano, mes, recebido, devido, remetido, em_falta FROM vw_remessa_devida ORDER BY 1,2,3;

\echo '== SEGURANÇA'
SET ROLE app_igreja;
SELECT set_config('app.usuario_id','4',false) \g /dev/null
SELECT 'tesoureiro Matola' quem, (SELECT string_agg(mem_nome, ',' ORDER BY mem_nome) FROM membro) membros, (SELECT count(*) FROM transacao) transacoes;
SELECT set_config('app.usuario_id','5',false) \g /dev/null
SELECT 'pastor distrital' quem, (SELECT count(*) FROM membro) membros, (SELECT count(*) FROM transacao) transacoes, (SELECT count(*) FROM igreja) igrejas;
SELECT set_config('app.usuario_id','2',false) \g /dev/null
DELETE FROM transacao_linha;
RESET ROLE;

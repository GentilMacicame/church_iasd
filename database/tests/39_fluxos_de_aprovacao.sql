\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V54: fluxos de aprovação e conferência. Utilizadores dos testes 01/02 na igreja 1: 2 tesoureiro, 3 ancião, 5 pastor do
-- distrito, 6 secretária, 9 administrador, 11 director de departamento, 8 Tito (membro, sem perfil).
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO membro (mem_id, mem_igr_id, mem_nome, mem_apelido, mem_data_nascimento, mem_estado) VALUES
 (3901, 1, 'Celeste', 'Mondlane', '1993-05-05', 'INTERESSADO'), (3902, 1, 'Jaime', 'Tembe', '1980-06-06', 'ACTIVO');
INSERT INTO reuniao (reu_id, reu_igr_id, reu_tipo, reu_data) VALUES (3900, 1, 'JUNTA_DIRECTIVA', '2026-11-14 15:00+02'),
 (3901, 1, 'ASSEMBLEIA_ADMINISTRATIVA', '2026-11-21 11:00+02'), (3902, 1, 'REUNIAO_REGULAR', '2026-11-21 11:00+02');
INSERT INTO voto (vot_id, vot_reu_id, vot_numero, vot_tipo, vot_assunto) VALUES
 (3900, 3900, 'J-390', 'ADMISSAO', 'Recomenda o baptismo de Celeste Mondlane'),
 (3901, 3901, '2026-391', 'ADMISSAO', 'Admissão por baptismo de Celeste Mondlane'),
 (3903, 3900, 'J-391', 'FINANCEIRO', 'Compra de cadeiras para o templo'),
 (3904, 3902, '2026-392', 'FINANCEIRO', 'Compra de cadeiras (reunião regular)'),
 (3905, 3900, 'J-392', 'FINANCEIRO', 'Pintura da igreja (rejeitada)');
SET ROLE app_igreja;

\echo '1. modelos da Associação: um fluxo por natureza e valor, com as etapas por ordem'
SELECT f.fap_processo, f.fap_nome, f.fap_valor_minimo, string_agg(e.fae_ordem || '. ' || e.fae_nome || ' [' || e.fae_responsavel || ']', ' → ' ORDER BY e.fae_ordem) AS etapas
  FROM fluxo_aprovacao f JOIN fluxo_etapa e ON e.fae_fap_id = f.fap_id AND e.fae_end_date IS NULL
 WHERE f.fap_igr_id IS NULL GROUP BY f.fap_id ORDER BY f.fap_processo, f.fap_valor_minimo;

\echo '2. despesa de 3 000 (director pede): fluxo «Despesa corrente», etapa 1 do tesoureiro, com o nome de quem decide'
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
INSERT INTO despesa (des_id, des_igr_id, des_ide_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
VALUES (3901, 1, 1, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D4'), (SELECT fun_id FROM fundo WHERE fun_codigo = 'OLOC'), 'Material do clube', 3000, 11);
SELECT fluxo, etapa, total_etapas, etapa_nome, responsavel, responsaveis, pode_decidir FROM vw_aprovacoes WHERE despesa_id = 3901;
\echo '   o director (quem pediu, sem o perfil) não decide; a mudança à mão diz o que falta'
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true);
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
UPDATE despesa SET des_estado = 'APROVADA', des_valor_aprovado = 3000 WHERE des_id = 3901;
\echo '   o ancião também não aprecia (é do tesoureiro); o tesoureiro aprecia; o ancião aprova'
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true);
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT pode_decidir FROM vw_aprovacoes WHERE despesa_id = 3901;
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true);
\echo '   o tesoureiro já decidiu: não decide a etapa 2 (outra pessoa)'
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true);
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true, NULL, NULL, 2800);
SELECT des_estado, des_valor_aprovado, des_aprovado_por_usu_id FROM despesa WHERE des_id = 3901;
SELECT ordem, nome, situacao, decidido_por, valor_aprovado FROM vw_aprovacao_etapas
 WHERE aprovacao_id = (SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901) ORDER BY ordem;
\echo '   concluído: não se decide outra vez'
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3901), true);

\echo '3. despesa de 15 000: fluxo «Despesa do Conselho» (o tesoureiro aprecia, o Conselho vota)'
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
INSERT INTO despesa (des_id, des_igr_id, des_ide_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
VALUES (3902, 1, 1, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D4'), (SELECT fun_id FROM fundo WHERE fun_codigo = 'OLOC'), 'Cadeiras do templo', 15000, 11);
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT tesouraria.fn_decidir_despesa(3902, true);
SELECT fluxo, etapa, etapa_nome, responsavel, responsaveis, pode_decidir FROM vw_aprovacoes WHERE despesa_id = 3902;
\echo '   o ancião sem voto (recusado), com o voto de uma reunião regular (recusado), com o voto do Conselho (aprovada)'
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT tesouraria.fn_decidir_despesa(3902, true);
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3902), true, 3904);
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3902), true, 3903);
SELECT des_estado, des_valor_aprovado, des_vot_id FROM despesa WHERE des_id = 3902;
\echo '   o mesmo voto não decide outra despesa à toa: a decisão é a do voto (rejeitado → despesa rejeitada)'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
RESET ROLE;
UPDATE voto SET vot_estado = 'REJEITADO' WHERE vot_id = 3905;
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '11', false) \g /dev/null
INSERT INTO despesa (des_id, des_igr_id, des_ide_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
VALUES (3903, 1, 1, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D4'), (SELECT fun_id FROM fundo WHERE fun_codigo = 'OLOC'), 'Pintura', 20000, 11);
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT tesouraria.fn_decidir_despesa(3903, false);
SELECT tesouraria.fn_decidir_despesa(3903, true);
\echo '   a secretária regista votos mas não vê despesas: "não existe"; o ancião regista o voto do Conselho'
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
SELECT fn_aprovacao_decidir((SELECT apv_id FROM aprovacao WHERE apv_des_id = 3903), true, 3905);
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT fn_aprovacao_decidir((SELECT id FROM vw_aprovacoes WHERE despesa_id = 3903), true, 3905);
SELECT des_estado, des_motivo_rejeicao FROM despesa WHERE des_id = 3903;

\echo '4. quem não tem permissão de ler despesas não vê os processos (Tito, membro sem perfil); a decisão dá "não existe"'
SELECT set_config('app.usuario_id', '8', false) \g /dev/null
SELECT count(*) AS processos_visiveis FROM vw_aprovacoes;
SELECT fn_aprovacao_decidir((SELECT apv_id FROM aprovacao LIMIT 1), true);
SELECT fn_aprovacao_decidir(1, true);
\echo '   e ninguém escreve nos processos directamente'
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
UPDATE aprovacao SET apv_estado = 'APROVADO';
INSERT INTO aprovacao_decisao (apd_apv_id, apd_igr_id, apd_fae_id, apd_etapa, apd_aprovado, apd_usu_id) VALUES (1, 1, 1, 1, true, 3);

\echo '5. admissão de membro: a Igreja não vota antes do Conselho; depois do Conselho, sim; o livro aceita'
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3901, 1, 3901);
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (3901, 1, 'BAPTISMO', '2026-11-21', 3901);
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3900, 1, 3901);
SELECT estado, etapa, etapa_nome, responsavel FROM vw_aprovacoes WHERE membro_id = 3901;
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (3901, 1, 'BAPTISMO', '2026-11-21', 3900);
INSERT INTO voto_membro (vtm_vot_id, vtm_igr_id, vtm_mem_id) VALUES (3901, 1, 3901);
SELECT estado, etapa, total_etapas FROM vw_aprovacoes WHERE membro_id = 3901;
SELECT ordem, nome, situacao, voto_numero FROM vw_aprovacao_etapas
 WHERE aprovacao_id = (SELECT id FROM vw_aprovacoes WHERE membro_id = 3901) ORDER BY ordem;
INSERT INTO movimento_membro (mmb_mem_id, mmb_igr_id, mmb_tipo, mmb_data, mmb_vot_id) VALUES (3901, 1, 'BAPTISMO', '2026-11-21', 3901);
SELECT mem_estado, mem_modo_entrada FROM membro WHERE mem_id = 3901;

\echo '6. fluxo próprio da igreja: o tesoureiro não configura; o pastor sim; o modelo comum só a Associação'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO fluxo_aprovacao (fap_igr_id, fap_processo, fap_nome) VALUES (1, 'SAIDA', 'Saída da igreja 1');
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
INSERT INTO fluxo_aprovacao (fap_igr_id, fap_processo, fap_nome) VALUES (NULL, 'SAIDA', 'Modelo do pastor');
INSERT INTO fluxo_aprovacao (fap_id, fap_igr_id, fap_processo, fap_nome) VALUES (3900, 1, 'SAIDA', 'Saída da igreja 1') RETURNING fap_nome;
INSERT INTO fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_responsavel) VALUES (3900, 1, 'Sem responsável', 'PERFIL');
INSERT INTO fluxo_etapa (fae_fap_id, fae_ordem, fae_nome, fae_accao, fae_responsavel, fae_per_id) VALUES
 (3900, 1, 'Visto do secretário', 'APRECIAR', 'PERFIL', (SELECT per_id FROM perfil WHERE per_codigo = 'SECRETARIO')),
 (3900, 2, 'Aprovação do pastor', 'APROVAR', 'PERFIL', (SELECT per_id FROM perfil WHERE per_codigo = 'PASTOR'))
RETURNING fae_ordem, fae_igr_id;
UPDATE fluxo_aprovacao SET fap_igr_id = 2 WHERE fap_id = 3900;
\echo '   a saída nova da igreja 1 segue o fluxo da igreja (não o modelo); o ancião já não aprova sozinho'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
BEGIN;
INSERT INTO transacao (tra_id, tra_igr_id, tra_tipo, tra_metodo, tra_valor_total, tra_cfi_id, tra_descricao, tra_data_hora)
VALUES (3901, 1, 'SAIDA', 'NUMERARIO', 500, 2, 'Água e luz', '2026-11-20 10:00+02');
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
VALUES (3901, (SELECT fun_id FROM fundo WHERE fun_codigo = 'OLOC'), (SELECT cat_id FROM categoria WHERE cat_codigo = 'D2'), 500);
COMMIT;
SELECT fluxo, etapa, total_etapas, etapa_nome, responsaveis FROM vw_aprovacoes WHERE transacao_id = 3901;
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(3901);
SELECT set_config('app.usuario_id', '6', false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(3901);
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT tesouraria.fn_aprovar_saida(3901);
SELECT tra_aprovado_por_usu_id, (SELECT estado FROM vw_aprovacoes WHERE transacao_id = 3901) AS processo FROM transacao WHERE tra_id = 3901;

\echo '7. contagem: o processo de conferência começa com a contagem; o ancião (só lê) não confere'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO contagem_numerario (cnu_id, cnu_igr_id, cnu_cfi_id, cnu_data, cnu_contador1_mem_id, cnu_contador2_mem_id, cnu_total_contado)
VALUES (3901, 1, 2, '2026-11-21', 102, 3902, 900);
SELECT processo, fluxo, etapa_nome, responsavel, pode_decidir FROM vw_aprovacoes WHERE contagem_id = 3901;
SELECT set_config('app.usuario_id', '3', false) \g /dev/null
SELECT fn_aprovacao_decidir((SELECT apv_id FROM aprovacao WHERE apv_cnu_id = 3901), true);
\echo '   um terminar cancela o processo'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE contagem_numerario SET cnu_end_date = now() WHERE cnu_id = 3901;
SELECT apv_estado FROM aprovacao WHERE apv_cnu_id = 3901;
RESET ROLE;

\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V23: as tabelas comuns (fundos gerais, plano de contas, calendário, lição) só se mudam ao nível da Associação;
-- cada igreja tem as suas ofertas e projectos (100% da igreja).
-- Dos testes anteriores: 2 = tesoureiro da igreja 1, 4 = tesoureiro da igreja 2, 1 = super-administrador.
-- Aqui: 970 = administrador da Associação 1 (perfil ADMIN_ASSOCIACAO em usuario_entidade).

SELECT set_config('app.usuario_id', '1', false) \g /dev/null
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES (970, 'Admin da Associação', 'admin.assoc.v23@x', 'h');
INSERT INTO usuario_entidade (uen_usu_id, uen_ent_id, uen_per_id) VALUES (970, 1, (SELECT per_id FROM perfil WHERE per_nome = 'ADMIN_ASSOCIACAO'));

SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
\echo '1. tesoureiro de igreja (não autorizado) nas linhas comuns: nada muda (0 linhas) e criar é recusado'
UPDATE categoria SET cat_e_remessa = true WHERE cat_tipo = 'DESPESA' AND NOT cat_e_remessa;
UPDATE fundo SET fun_percentagem_remessa = 0 WHERE fun_igr_id IS NULL AND fun_tipo = 'OFERTA_COMBINADA';
UPDATE fundo SET fun_end_date = now() WHERE fun_igr_id IS NULL;
INSERT INTO fundo (fun_codigo, fun_nome, fun_tipo) VALUES ('V23GERAL', 'Fundo geral do tesoureiro', 'OFERTA_ESPECIAL');
INSERT INTO categoria (cat_codigo, cat_nome, cat_tipo, cat_e_remessa) VALUES ('V23CAT', 'Categoria do tesoureiro', 'DESPESA', true);
\echo '   continua igual: só a categoria de remessa original; oferta combinada 50%; fundos gerais activos'
SELECT (SELECT count(*) FROM categoria WHERE cat_e_remessa) AS categorias_de_remessa,
       (SELECT fun_percentagem_remessa FROM fundo WHERE fun_igr_id IS NULL AND fun_tipo = 'OFERTA_COMBINADA' LIMIT 1) AS oferta_combinada,
       (SELECT count(*) FROM fundo WHERE fun_igr_id IS NULL AND fun_end_date IS NOT NULL) AS gerais_terminados;

\echo '2. tesoureiro (autorizado na sua igreja): cria as ofertas da igreja'
INSERT INTO fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo, fun_restrito) VALUES
  (1, 'I1-CONSTRUCAO', 'Construção do templo', 'PROJECTO', true),
  (1, 'I1-GRATIDAO', 'Oferta de gratidão', 'OFERTA_ESPECIAL', false)
RETURNING fun_codigo, fun_nome, fun_tipo, fun_restrito, fun_percentagem_remessa;
\echo '   oferta da igreja com parte para a Missão ou de outro tipo: recusado'
INSERT INTO fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo, fun_percentagem_remessa, fun_destino_ent_id) VALUES (1, 'I1-X', 'Meio-meio', 'OFERTA_ESPECIAL', 50, 1);
INSERT INTO fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo) VALUES (1, 'I1-Y', 'Dízimo da igreja', 'DIZIMO');
\echo '   na igreja de outro: recusado'
INSERT INTO fundo (fun_igr_id, fun_codigo, fun_nome, fun_tipo) VALUES (2, 'I2-Z', 'Oferta de outra igreja', 'OFERTA_ESPECIAL');

\echo '3. a oferta da igreja recebe entradas e é da igreja (sem remessa)'
BEGIN;
INSERT INTO transacao (tra_id, tra_igr_id, tra_cfi_id, tra_tipo, tra_metodo, tra_valor_total, tra_data_hora, tra_anonimo)
SELECT 9230, 1, cfi_id, 'ENTRADA', 'NUMERARIO', 300, '2026-11-07 10:00+02', true FROM conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' AND cfi_ent_id IS NULL ORDER BY cfi_id LIMIT 1;
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
SELECT 9230, fun_id, (SELECT cat_id FROM categoria WHERE cat_tipo = 'RECEITA' ORDER BY cat_id LIMIT 1), 300 FROM fundo WHERE fun_codigo = 'I1-CONSTRUCAO';
COMMIT;
SELECT f.fun_nome, l.tli_valor, f.fun_percentagem_remessa FROM transacao_linha l JOIN fundo f ON f.fun_id = l.tli_fun_id WHERE l.tli_tra_id = 9230;

\echo '3b. despesa "Outras despesas" sem dizer qual: recusada; dizendo, aceite e paga pelo fundo da igreja'
INSERT INTO despesa (des_igr_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
SELECT 1, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D9'), fun_id, 'Bandeiras para o desfile', 450, 2 FROM fundo WHERE fun_codigo = 'I1-CONSTRUCAO';
INSERT INTO despesa (des_igr_id, des_cat_id, des_fun_id, des_descricao, des_outra_categoria, des_valor_solicitado, des_solicitado_por_usu_id)
SELECT 1, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D9'), fun_id, 'Blocos e cimento', 'Material de construção', 450, 2 FROM fundo WHERE fun_codigo = 'I1-CONSTRUCAO'
RETURNING des_descricao, des_outra_categoria, des_valor_solicitado;
\echo '   o fundo de uma igreja na despesa de outra: recusado'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
INSERT INTO despesa (des_igr_id, des_cat_id, des_fun_id, des_descricao, des_valor_solicitado, des_solicitado_por_usu_id)
SELECT 2, (SELECT cat_id FROM categoria WHERE cat_codigo = 'D3'), fun_id, 'Obra', 100, 4 FROM fundo WHERE fun_igr_id = 1 LIMIT 1;
SELECT set_config('app.usuario_id', '2', false) \g /dev/null

\echo '3c. contagem por partes: a soma tem de dar o total; a conferência compara cada parte com o lançado'
INSERT INTO contagem_numerario (cnu_igr_id, cnu_cfi_id, cnu_data, cnu_contador1_mem_id, cnu_contador2_mem_id, cnu_total_contado, cnu_dizimos, cnu_ofertas, cnu_escola_sabatina, cnu_outras)
SELECT 1, cfi_id, '2026-11-14', 960, 961, 1000, 500, 200, 100, 100 FROM conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' AND cfi_ent_id IS NULL ORDER BY cfi_id LIMIT 1;
INSERT INTO contagem_numerario (cnu_id, cnu_igr_id, cnu_cfi_id, cnu_data, cnu_contador1_mem_id, cnu_contador2_mem_id, cnu_total_contado, cnu_dizimos, cnu_ofertas, cnu_escola_sabatina, cnu_outras)
SELECT 9231, 1, cfi_id, '2026-11-14', 960, 961, 1000, 500, 200, 200, 100 FROM conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' AND cfi_ent_id IS NULL ORDER BY cfi_id LIMIT 1
RETURNING cnu_total_contado, cnu_dizimos, cnu_ofertas, cnu_escola_sabatina, cnu_outras;
BEGIN;
INSERT INTO transacao (tra_id, tra_igr_id, tra_cfi_id, tra_cnu_id, tra_tipo, tra_metodo, tra_valor_total, tra_data_hora, tra_anonimo)
SELECT 9232, 1, cfi_id, 9231, 'ENTRADA', 'NUMERARIO', 700, '2026-11-14 10:00+02', true FROM conta_financeira WHERE cfi_igr_id = 1 AND cfi_tipo = 'CAIXA' AND cfi_ent_id IS NULL ORDER BY cfi_id LIMIT 1;
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
SELECT 9232, fun_id, (SELECT cat_id FROM categoria WHERE cat_codigo = 'R1'), 500 FROM fundo WHERE fun_tipo = 'DIZIMO' AND fun_igr_id IS NULL;
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
SELECT 9232, fun_id, (SELECT cat_id FROM categoria WHERE cat_codigo = 'R3'), 200 FROM fundo WHERE fun_tipo = 'ES_MISSOES' AND fun_igr_id IS NULL;
COMMIT;
UPDATE transacao SET tra_estado = 'CONFIRMADA' WHERE tra_id = 9232;
SELECT cnu_total_contado, total_lancado, diferenca, cnu_dizimos, dizimos_lancado, cnu_ofertas, ofertas_lancado, cnu_escola_sabatina, escola_sabatina_lancado
  FROM vw_contagem_conferencia WHERE cnu_id = 9231;

\echo '4. tesoureiro da igreja 2 (não autorizado na igreja 1): não termina a oferta da igreja 1'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
UPDATE fundo SET fun_end_date = now() WHERE fun_codigo = 'I1-GRATIDAO';
\echo '   o tesoureiro da igreja 1 termina-a (autorizado)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE fundo SET fun_end_date = now() WHERE fun_codigo = 'I1-GRATIDAO' RETURNING fun_codigo, fun_end_date IS NOT NULL AS terminado;

\echo '5. administrador da Associação (autorizado): muda o plano comum e cria um fundo geral'
SELECT set_config('app.usuario_id', '970', false) \g /dev/null
INSERT INTO fundo (fun_codigo, fun_nome, fun_tipo) VALUES ('V23GERAL', 'Oferta especial da Missão', 'OFERTA_ESPECIAL') RETURNING fun_codigo, fun_igr_id;
UPDATE fundo SET fun_end_date = now() WHERE fun_codigo = 'V23GERAL' RETURNING fun_codigo, fun_end_date IS NOT NULL AS terminado;
INSERT INTO categoria (cat_codigo, cat_nome, cat_tipo) VALUES ('V23CAT', 'Categoria da Missão', 'DESPESA') RETURNING cat_codigo;

RESET ROLE;

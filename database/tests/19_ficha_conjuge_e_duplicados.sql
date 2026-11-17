\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V33: ficha completa do membro, cônjuge ligado (recíproco), telefone fixo e registos parecidos.
-- Dos testes anteriores: 950 = secretário da igreja 1, 2 = tesoureiro da igreja 1, 4 = tesoureiro da igreja 2;
-- 960 Paulo Mabjaia e 961 Joana Cumbe = membros activos da igreja 1; 900 Elisa Fumo (BI 110100000000A);
-- 100 Ana Cossa = membro da igreja 2.

SET ROLE app_igreja;

\echo '1. secretário (autorizado): preenche os campos novos do Paulo'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE secretaria.membro
   SET mem_ex_membro = TRUE, mem_outro_documento = 'NUIT 400123456', mem_endereco_postal = 'CP 1234',
       mem_codigo_postal = '1100', mem_local_trabalho = 'Escola Secundária da Matola', mem_dependentes = 3,
       mem_religiao_anterior = 'Católica', mem_metodo_conversao = 'Estudo bíblico',
       mem_estado_civil = 'CASADO', mem_data_casamento = '1995-12-09'
 WHERE mem_id = 960;
SELECT mem_ex_membro, mem_outro_documento, mem_local_trabalho, mem_dependentes, mem_metodo_conversao, mem_data_casamento
  FROM secretaria.membro WHERE mem_id = 960;

\echo '2. valores fora das regras: recusados (dependentes, casamento antes do nascimento, o próprio como cônjuge)'
UPDATE secretaria.membro SET mem_dependentes = -1 WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_data_casamento = '1960-01-01' WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_conjuge_mem_id = 960 WHERE mem_id = 960;

\echo '3. cônjuge: ligar o Paulo à Joana liga também a Joana ao Paulo (sem segundo registo)'
UPDATE secretaria.membro SET mem_conjuge_mem_id = 961 WHERE mem_id = 960;
SELECT mem_id, mem_conjuge_mem_id FROM secretaria.membro WHERE mem_id IN (960, 961) ORDER BY mem_id;

\echo '4. a Joana já está ligada: outro membro não a pode escolher como cônjuge'
UPDATE secretaria.membro SET mem_conjuge_mem_id = 961 WHERE mem_id = 103;

\echo '5. desligar de um lado desliga dos dois'
UPDATE secretaria.membro SET mem_conjuge_mem_id = NULL WHERE mem_id = 961;
SELECT mem_id, mem_conjuge_mem_id FROM secretaria.membro WHERE mem_id IN (960, 961) ORDER BY mem_id;
UPDATE secretaria.membro SET mem_conjuge_mem_id = 961 WHERE mem_id = 960;

\echo '6. telefone fixo: novo tipo de contacto'
INSERT INTO secretaria.contacto (cto_mem_id, cto_tipo, cto_valor) VALUES (960, 'TELEFONE_FIXO', '+258 21 123 456')
RETURNING cto_tipo, cto_valor;

\echo '7. registos parecidos: mesmo documento (escrito com espaços), nome e data de nascimento'
SELECT nome, pontos, motivos FROM nucleo.fn_membros_parecidos('Elisa', 'Fumo', NULL, NULL, '1101 0000 0000-a');
SELECT nome, pontos, motivos FROM nucleo.fn_membros_parecidos('Paulo', 'Mabjaia', '1970-02-02');
\echo '   só o nome parecido: aparece como possível, não bloqueia nada'
SELECT nome, pontos, motivos FROM nucleo.fn_membros_parecidos('Paulo', 'Mabjaya');
\echo '   a editar o próprio registo: não se compara consigo'
SELECT count(*) AS parecidos FROM nucleo.fn_membros_parecidos('Paulo', 'Mabjaia', '1970-02-02', NULL, NULL, 960);
\echo '   nada parecido'
SELECT count(*) AS parecidos FROM nucleo.fn_membros_parecidos('Xavier', 'Nhantumbo', '2001-01-01');

\echo '8. a lista para exportar e a vista básica com os campos novos'
SELECT nome, estado_civil, telemovel, email FROM secretaria.vw_membros_lista WHERE mem_id = 960;
SELECT mem_estado_civil, mem_data_nascimento, mem_conjuge_mem_id FROM secretaria.vw_membro_basico WHERE mem_id = 960;

\echo '9. tesoureiro da igreja 1 (não autorizado a alterar): lê, mas não altera'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
SELECT mem_local_trabalho FROM secretaria.membro WHERE mem_id = 960;
UPDATE secretaria.membro SET mem_local_trabalho = 'Outro' WHERE mem_id = 960;
SELECT mem_local_trabalho AS continua FROM secretaria.membro WHERE mem_id = 960;

\echo '10. tesoureiro da igreja 2: não vê o Paulo, nem como parecido nem na lista'
SELECT set_config('app.usuario_id', '4', false) \g /dev/null
SELECT count(*) AS parecidos FROM nucleo.fn_membros_parecidos('Paulo', 'Mabjaia', '1970-02-02');
SELECT count(*) AS na_lista FROM secretaria.vw_membros_lista WHERE mem_id = 960;
RESET ROLE;

\echo '11. a frase de cada restrição nova está no COMMENT (a API devolve-a)'
SELECT conname, obj_description(oid, 'pg_constraint') AS frase FROM pg_constraint
 WHERE conname IN ('chk_mem_conjuge', 'chk_mem_dependentes', 'chk_mem_casamento') ORDER BY conname;

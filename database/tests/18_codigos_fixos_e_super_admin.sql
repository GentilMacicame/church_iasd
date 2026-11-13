\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V32: códigos fixos (perfis, categorias, permissões) e permissões do super-administrador intocáveis.
-- Dos testes anteriores: 1 = super-administrador; 5 = pastor do distrito 1; 980 = ADMIN da igreja 1; 2 = tesoureiro.

\echo '1. os perfis do sistema têm código (igual ao nome que tinham)'
SELECT count(*) AS perfis_com_codigo, count(*) FILTER (WHERE per_codigo = per_nome) AS codigo_igual_ao_nome
  FROM perfil WHERE per_codigo IS NOT NULL AND per_end_date IS NULL;

\echo '2. o pastor do distrito mantém o acesso quando o perfil PASTOR muda de nome'
SET ROLE app_igreja;
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT cardinality(nucleo.fn_igrejas_com_permissao('secretaria.membro.ler')) AS igrejas_do_pastor_antes \gset
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
UPDATE perfil SET per_nome = 'Pastor distrital' WHERE per_codigo = 'PASTOR';
SELECT set_config('app.usuario_id', '5', false) \g /dev/null
SELECT cardinality(nucleo.fn_igrejas_com_permissao('secretaria.membro.ler')) = :igrejas_do_pastor_antes AS pastor_mantem_as_igrejas,
       :igrejas_do_pastor_antes > 0 AS tinha_igrejas;

\echo '3. autorizado (super-administrador): o código do perfil não muda; perfis do sistema não se terminam'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
UPDATE perfil SET per_codigo = 'PASTOR_2' WHERE per_codigo = 'PASTOR';
UPDATE perfil SET per_end_date = now() WHERE per_codigo = 'PASTOR';
UPDATE perfil SET per_ambito = 'ENTIDADE' WHERE per_codigo = 'PASTOR';
\echo '   perfil novo com código: recusado; sem código: aceite'
INSERT INTO perfil (per_nome, per_codigo) VALUES ('Perfil inventado', 'INVENTADO');
INSERT INTO perfil (per_nome) VALUES ('Coordenador (teste 18)') RETURNING per_nome, per_codigo;
UPDATE perfil SET per_nome = 'PASTOR' WHERE per_codigo = 'PASTOR';
\echo '   não autorizado: o tesoureiro não muda o nome do perfil (nenhuma linha alterada)'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
UPDATE perfil SET per_nome = 'Pastor do tesoureiro' WHERE per_codigo = 'PASTOR';
SELECT per_nome FROM perfil WHERE per_codigo = 'PASTOR';

\echo '4. o código da categoria não muda (R3 = ofertas da Escola Sabatina); o nome sim'
SELECT set_config('app.usuario_id', '1', false) \g /dev/null
UPDATE categoria SET cat_codigo = 'R3X' WHERE cat_codigo = 'R3';
UPDATE categoria SET cat_nome = cat_nome WHERE cat_codigo = 'R3';
SELECT count(*) AS categoria_r3 FROM categoria WHERE cat_codigo = 'R3' AND cat_end_date IS NULL;
\echo '   nem o código de uma permissão'
UPDATE permissao SET prm_codigo = 'secretaria.membro.ver' WHERE prm_codigo = 'secretaria.membro.ler';

\echo '5. super-administrador: ninguém lhe muda as permissões'
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash, usu_super_admin)
VALUES (1800, 'Segundo super-administrador', 'super2@igreja.local', 'x', TRUE) RETURNING usu_nome, usu_super_admin;
\echo '   outro super-administrador não lhe retira o acesso total, não o inactiva nem o termina'
UPDATE usuario SET usu_super_admin = FALSE WHERE usu_email = 'super2@igreja.local';
UPDATE usuario SET usu_estado = 'INACTIVO' WHERE usu_email = 'super2@igreja.local';
UPDATE usuario SET usu_end_date = now() WHERE usu_email = 'super2@igreja.local';
\echo '   o próprio também não; mas muda os seus contactos'
UPDATE usuario SET usu_super_admin = FALSE WHERE usu_id = 1;
UPDATE usuario SET usu_estado = 'INACTIVO' WHERE usu_id = 1;
UPDATE usuario SET usu_telefone = '+258849990001' WHERE usu_id = 1;
\echo '   não autorizado: o administrador da igreja não toca no super-administrador'
SELECT set_config('app.usuario_id', '980', false) \g /dev/null
UPDATE usuario SET usu_super_admin = FALSE WHERE usu_email = 'super2@igreja.local';
RESET ROLE;
SELECT usu_nome, usu_super_admin, usu_estado, usu_end_date IS NULL AS activo FROM usuario
 WHERE usu_id = 1 OR usu_email = 'super2@igreja.local' ORDER BY usu_id;

\echo '6. manutenção da base (sem utilizador na sessão): pode retirar o acesso total'
SELECT set_config('app.usuario_id', '', false) \g /dev/null
UPDATE usuario SET usu_super_admin = FALSE WHERE usu_email = 'super2@igreja.local';
SELECT usu_nome, usu_super_admin FROM usuario WHERE usu_email = 'super2@igreja.local';

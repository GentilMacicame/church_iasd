\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
-- V29: cada restrição tem a frase em português no COMMENT; a API lê-as com nucleo.fn_mensagens_restricoes().

\echo '1. a API (app_igreja) lê as frases: CHECK e índices únicos'
SET ROLE app_igreja;
SELECT nome, mensagem FROM nucleo.fn_mensagens_restricoes()
 WHERE nome IN ('chk_ers_numeros', 'uq_ema_activa', 'uq_ers_ect_id_esa_id', 'chk_tra_quem_regista_nao_aprova')
 ORDER BY nome;
RESET ROLE;

\echo '2. todos os CHECK com significado (não os chk_*_end_date) têm frase'
SELECT DISTINCT c.conname AS check_sem_frase
  FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace JOIN pg_class t ON t.oid = c.conrelid
 WHERE c.contype = 'c' AND NOT t.relispartition
   AND n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
   AND c.conname NOT LIKE 'chk\_%\_end\_date' AND c.conname <> 'chk_lau_accao'
   AND obj_description(c.oid, 'pg_constraint') IS NULL
 ORDER BY 1;

\echo '3. todos os únicos da Escola Sabatina têm frase'
SELECT i.relname AS unico_sem_frase
  FROM pg_index x JOIN pg_class i ON i.oid = x.indexrelid JOIN pg_namespace n ON n.oid = i.relnamespace
 WHERE x.indisunique AND NOT x.indisprimary AND n.nspname = 'escola_sabatina'
   AND obj_description(i.oid, 'pg_class') IS NULL;

\echo '4. quem não é app_igreja não chama a função'
CREATE ROLE teste_sem_acesso NOLOGIN;
SET ROLE teste_sem_acesso;
SELECT count(*) FROM nucleo.fn_mensagens_restricoes();
RESET ROLE;
DROP ROLE teste_sem_acesso;

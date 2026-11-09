-- =====================================================================
-- V18 · Menos schemas e índices para as listagens por igreja
--
-- 1. Os schemas com 1 e 3 tabelas passam para o módulo a que pertencem (ficam 6 schemas):
--      pagamentos.pagamento_mpesa, mpesa_callback_log, pagamento_bancario, vw_mpesa_pendentes → tesouraria
--      comunicacao.notificacao, vw_notificacoes_a_enviar                                     → nucleo
--    Os códigos de permissão mudam com o schema (pagamentos.pagamento_mpesa.ler → tesouraria.pagamento_mpesa.ler);
--    os perfis continuam com exactamente as mesmas permissões (são ligados pelo id, não pelo código).
--    Os registos antigos do log de auditoria guardam o nome antigo da tabela (o log não se altera).
--
-- 2. Listagens por igreja (a API pede sempre igrejaId e ordena por id, com cursor): o índice (igreja) passa
--    a (igreja, id) nas 18 tabelas que crescem com o uso. A página seguinte sai directamente do índice, em vez
--    de ler e ordenar todos os registos da igreja. Medido com a carga de database/tests/carga_*.sql.
--
-- Gerado a partir de database/gerador (defs.py, gen.py); o estado final é igual ao que o gerador produz.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- ---------------------------------------------------------------- 1. mover para tesouraria e nucleo
ALTER TABLE pagamentos.pagamento_mpesa    SET SCHEMA tesouraria;
ALTER TABLE pagamentos.mpesa_callback_log SET SCHEMA tesouraria;
ALTER TABLE pagamentos.pagamento_bancario SET SCHEMA tesouraria;
ALTER VIEW  pagamentos.vw_mpesa_pendentes SET SCHEMA tesouraria;
ALTER FUNCTION pagamentos.fn_pmp_validar() SET SCHEMA tesouraria;

ALTER TABLE comunicacao.notificacao              SET SCHEMA nucleo;
ALTER VIEW  comunicacao.vw_notificacoes_a_enviar SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_rec_notificar() SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_notificacoes_reservar(INT) SET SCHEMA nucleo;
ALTER FUNCTION comunicacao.fn_notificacao_resultado(BIGINT, BOOLEAN, TEXT) SET SCHEMA nucleo;

-- O que guarda os nomes antigos em texto: corpo das funções, códigos de permissão nas políticas RLS e nos
-- triggers-padrão (o "terminar" exige <schema>.<tabela>.terminar), e o catálogo de permissões.
DO $$
DECLARE
    r   RECORD;
    def TEXT;
    sql TEXT;
BEGIN
    -- funções (plpgsql guarda o corpo em texto)
    FOR r IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
               AND p.prosrc ~ '\m(pagamentos|comunicacao)\.' LOOP
        def := pg_get_functiondef(r.oid);
        def := regexp_replace(def, '\mpagamentos\.', 'tesouraria.', 'g');
        def := regexp_replace(def, '\mcomunicacao\.', 'nucleo.', 'g');
        EXECUTE def;
    END LOOP;

    -- políticas RLS: os códigos de permissão são texto
    FOR r IN SELECT schemaname, tablename, policyname, qual, with_check FROM pg_policies
             WHERE coalesce(qual, '') || coalesce(with_check, '') ~ '\m(pagamentos|comunicacao)\.' LOOP
        sql := format('ALTER POLICY %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
        IF r.qual IS NOT NULL THEN
            sql := sql || ' USING (' || regexp_replace(regexp_replace(r.qual, '\mpagamentos\.', 'tesouraria.', 'g'),
                                                       '\mcomunicacao\.', 'nucleo.', 'g') || ')';
        END IF;
        IF r.with_check IS NOT NULL THEN
            sql := sql || ' WITH CHECK (' || regexp_replace(regexp_replace(r.with_check, '\mpagamentos\.', 'tesouraria.', 'g'),
                                                            '\mcomunicacao\.', 'nucleo.', 'g') || ')';
        END IF;
        EXECUTE sql;
    END LOOP;

    -- triggers-padrão com o código da tabela nos argumentos
    FOR r IN SELECT t.oid, t.tgname, t.tgrelid::regclass AS tabela FROM pg_trigger t
             WHERE NOT t.tgisinternal AND encode(t.tgargs, 'escape') ~ '(^|\\000)(pagamentos|comunicacao)\.' LOOP
        def := pg_get_triggerdef(r.oid);
        def := regexp_replace(def, '''pagamentos\.', '''tesouraria.', 'g');
        def := regexp_replace(def, '''comunicacao\.', '''nucleo.', 'g');
        EXECUTE format('DROP TRIGGER %I ON %s', r.tgname, r.tabela);
        EXECUTE def;
    END LOOP;
END $$;

UPDATE nucleo.permissao
   SET prm_codigo = regexp_replace(regexp_replace(prm_codigo, '^pagamentos\.', 'tesouraria.'), '^comunicacao\.', 'nucleo.')
 WHERE prm_codigo ~ '^(pagamentos|comunicacao)\.';

-- search_path das funções, da base e dos utilizadores da API (sem os dois schemas)
DO $$
DECLARE
    r RECORD;
    novo CONSTANT TEXT := 'nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public';
    cfg TEXT;
BEGIN
    FOR r IN SELECT p.oid::regprocedure AS sig FROM pg_proc p
             WHERE array_to_string(p.proconfig, ',') ~ 'search_path=.*\m(pagamentos|comunicacao)\M' LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = %s', r.sig, novo);
    END LOOP;
    FOR r IN SELECT s.setrole, s.setdatabase, c AS cfg FROM pg_db_role_setting s, unnest(s.setconfig) c
             WHERE c ~ '^search_path=.*\m(pagamentos|comunicacao)\M'
               AND (s.setdatabase = 0 OR s.setdatabase = (SELECT oid FROM pg_database WHERE datname = current_database())) LOOP
        cfg := regexp_replace(substr(r.cfg, length('search_path=') + 1), ',\s*(pagamentos|comunicacao)\M', '', 'g');
        IF r.setrole = 0 THEN
            EXECUTE format('ALTER DATABASE %I SET search_path = %s', current_database(), cfg);
        ELSIF r.setdatabase = 0 THEN
            EXECUTE format('ALTER ROLE %I SET search_path = %s', (SELECT rolname FROM pg_roles WHERE oid = r.setrole), cfg);
        ELSE
            EXECUTE format('ALTER ROLE %I IN DATABASE %I SET search_path = %s',
                           (SELECT rolname FROM pg_roles WHERE oid = r.setrole), current_database(), cfg);
        END IF;
    END LOOP;
END $$;

-- vazios: se ainda tiverem alguma coisa, a migração pára aqui (e nada do que está acima fica feito)
DROP SCHEMA pagamentos;
DROP SCHEMA comunicacao;

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- 2. índices (igreja, id) para as listagens
-- O índice novo começa pela igreja: serve também a chave estrangeira e as políticas RLS, por isso substitui o
-- índice simples (igreja).
CREATE INDEX idx_uig_igr_pagina ON nucleo.usuario_igreja (uig_igr_id, uig_id);
CREATE INDEX idx_fam_igr_pagina ON secretaria.familia (fam_igr_id, fam_id);
CREATE INDEX idx_mem_igr_pagina ON secretaria.membro (mem_igr_id, mem_id);
CREATE INDEX idx_reu_igr_pagina ON secretaria.reuniao (reu_igr_id, reu_id);
CREATE INDEX idx_mmb_igr_pagina ON secretaria.movimento_membro (mmb_igr_id, mmb_id);
CREATE INDEX idx_ofi_igr_pagina ON secretaria.oficial (ofi_igr_id, ofi_id);
CREATE INDEX idx_epl_igr_pagina ON actividades.escala_plano (epl_igr_id, epl_id);
CREATE INDEX idx_ect_igr_pagina ON escola_sabatina.classe_trimestre (ect_igr_id, ect_id);
CREATE INDEX idx_ers_igr_pagina ON escola_sabatina.relatorio_sabado (ers_igr_id, ers_id);
CREATE INDEX idx_epr_igr_pagina ON escola_sabatina.presenca (epr_igr_id, epr_id);
CREATE INDEX idx_alv_igr_pagina ON tesouraria.alvo (alv_igr_id, alv_id);
CREATE INDEX idx_orc_igr_pagina ON tesouraria.orcamento (orc_igr_id, orc_id);
CREATE INDEX idx_des_igr_pagina ON tesouraria.despesa (des_igr_id, des_id);
CREATE INDEX idx_cnu_igr_pagina ON tesouraria.contagem_numerario (cnu_igr_id, cnu_id);
CREATE INDEX idx_tra_igr_pagina ON tesouraria.transacao (tra_igr_id, tra_id);
CREATE INDEX idx_tli_igr_pagina ON tesouraria.transacao_linha (tli_igr_id, tli_id);
CREATE INDEX idx_sdc_igr_pagina ON tesouraria.saldo_diario_conta (sdc_igr_id, sdc_id);
CREATE INDEX idx_ntf_igr_pagina ON nucleo.notificacao (ntf_igr_id, ntf_id);

DROP INDEX nucleo.idx_uig_igr_id;
DROP INDEX secretaria.idx_fam_igr_id;
DROP INDEX secretaria.idx_mem_igr_id;
DROP INDEX secretaria.idx_reu_igr_id;
DROP INDEX secretaria.idx_mmb_igr_id;
DROP INDEX secretaria.idx_ofi_igr_id;
DROP INDEX actividades.idx_epl_igr_id;
DROP INDEX escola_sabatina.idx_ect_igr_id;
DROP INDEX escola_sabatina.idx_ers_igr_id;
DROP INDEX escola_sabatina.idx_epr_igr_id;
DROP INDEX tesouraria.idx_alv_igr_id;
DROP INDEX tesouraria.idx_orc_igr_id;
DROP INDEX tesouraria.idx_des_igr_id;
DROP INDEX tesouraria.idx_cnu_igr_id;
DROP INDEX tesouraria.idx_tra_igr_id;
DROP INDEX tesouraria.idx_tli_igr_id;
DROP INDEX tesouraria.idx_sdc_igr_id;
DROP INDEX nucleo.idx_ntf_igr_id;

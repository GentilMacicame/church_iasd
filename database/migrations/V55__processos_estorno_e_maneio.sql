-- =====================================================================
-- V55 · Processos de aprovação novos: ESTORNO e MANEIO (só os valores do enum)
--
-- Um valor novo de enum não se pode usar na mesma transacção em que é criado; as regras que os usam estão na V56.
-- =====================================================================
ALTER TYPE nucleo.processo_aprovacao_t ADD VALUE IF NOT EXISTS 'ESTORNO';
ALTER TYPE nucleo.processo_aprovacao_t ADD VALUE IF NOT EXISTS 'MANEIO';

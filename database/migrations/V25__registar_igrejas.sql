-- =====================================================================
-- V25 · Registar igrejas (F-ORG-01, P-13)
--
-- Problema: ninguém conseguia registar uma igreja, nem o super-administrador. A política de INSERT exigia que o
-- id da igreja nova estivesse em fn_igrejas_com_permissao(...), mas essa lista só tem as igrejas que já existem.
--
-- Agora regista uma igreja o super-administrador, ou quem tem organizacao.igreja.criar ao nível da
-- Associação/Missão a que a igreja pertence (perfil em usuario_entidade, ex.: ADMIN_ASSOCIACAO). Ter a permissão
-- numa igreja (perfil de igreja) não chega para criar outras. A leitura ganha a mesma regra (pela Associação da igreja):
-- o INSERT ... RETURNING da API lê a linha nova, que ainda não está na lista de igrejas do utilizador.
-- =====================================================================
DROP POLICY pol_igr_criar ON organizacao.igreja;
CREATE POLICY pol_igr_criar ON organizacao.igreja FOR INSERT WITH CHECK ((SELECT nucleo.fn_e_super_admin()) OR igr_ent_id IN (SELECT nucleo.fn_entidades_com_permissao('organizacao.igreja.criar')));
CREATE POLICY pol_igr_ler_associacao ON organizacao.igreja FOR SELECT USING ((SELECT nucleo.fn_e_super_admin()) OR igr_ent_id IN (SELECT nucleo.fn_entidades_com_permissao('organizacao.igreja.ler')));

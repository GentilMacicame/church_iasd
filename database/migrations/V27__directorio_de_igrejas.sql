-- =====================================================================
-- V27 · Directório de igrejas e transferências vistas pelas duas igrejas (F-SEC-06, P-02)
--
-- Para pedir uma carta de transferência, a igreja de origem escolhe a igreja de destino; mas um secretário só vê
-- (RLS) a sua igreja. O directório mostra a QUALQUER utilizador com sessão só o nome, o tipo, a Associação/Missão e
-- a localização de cada igreja activa — informação pública, sem membros, dinheiro nem outros dados da igreja.
-- A vista NÃO é security_invoker de propósito (corre com os direitos do dono, que não está sujeito à RLS) e mostra
-- apenas estas colunas.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

CREATE VIEW organizacao.vw_directorio_igrejas AS
SELECT i.igr_id, i.igr_nome AS nome, i.igr_tipo AS tipo, i.igr_ent_id, e.ent_nome AS entidade,
       p.prv_nome AS provincia, d.dad_nome AS distrito, i.igr_localidade AS localidade
FROM organizacao.igreja i
JOIN organizacao.entidade e ON e.ent_id = i.igr_ent_id
LEFT JOIN organizacao.provincia p ON p.prv_id = i.igr_prv_id
LEFT JOIN organizacao.distrito_administrativo d ON d.dad_id = i.igr_dad_id
WHERE i.igr_end_date IS NULL AND nucleo.fn_usuario_sessao() IS NOT NULL;
COMMENT ON VIEW organizacao.vw_directorio_igrejas IS 'Directório público de igrejas (nome, tipo, Associação, localização) para escolher o destino de uma transferência (V27)';
GRANT SELECT ON organizacao.vw_directorio_igrejas TO app_igreja;

-- Transferências vistas pelas duas igrejas (P-02): a igreja de destino tem de saber QUEM vai receber, mas a RLS
-- não lhe mostra o membro (ainda é da igreja de origem). Esta vista (também com os direitos do dono) mostra o nome
-- do membro e das duas igrejas, só nas transferências de uma igreja em que o utilizador pode ler transferências.
CREATE VIEW secretaria.vw_transferencias AS
SELECT t.tme_id, t.tme_mem_id, m.mem_nome || ' ' || m.mem_apelido AS membro,
       t.tme_origem_igr_id, io.igr_nome AS origem,
       t.tme_destino_igr_id, COALESCE(id.igr_nome, t.tme_destino_externo) AS destino, t.tme_destino_externo,
       t.tme_data_pedido, t.tme_origem_vot_id, t.tme_carta_emitida_em,
       (t.tme_carta_emitida_em + INTERVAL '6 months')::date AS valida_ate,
       COALESCE((t.tme_carta_emitida_em + INTERVAL '6 months')::date < CURRENT_DATE, FALSE) AS expirada,
       t.tme_destino_vot_id, t.tme_aceite_em, t.tme_observacoes, t.tme_estado
FROM secretaria.transferencia_membro t
JOIN secretaria.membro m       ON m.mem_id = t.tme_mem_id
JOIN organizacao.igreja io     ON io.igr_id = t.tme_origem_igr_id
LEFT JOIN organizacao.igreja id ON id.igr_id = t.tme_destino_igr_id
WHERE t.tme_end_date IS NULL
  AND (t.tme_origem_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[])
       OR t.tme_destino_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('secretaria.transferencia_membro.ler'))::INT[]));
COMMENT ON VIEW secretaria.vw_transferencias IS 'Transferências de membros com o nome do membro e das duas igrejas, para a origem e o destino (V27)';
GRANT SELECT ON secretaria.vw_transferencias TO app_igreja;

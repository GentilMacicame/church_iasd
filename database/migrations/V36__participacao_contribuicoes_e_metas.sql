-- =====================================================================
-- V36 · Decisões pendentes do plano: participação (membros inactivos), contribuições lançadas duas vezes
--       (membro e família), estado civil "noivo" e metas anuais com +5% (ex.: obra de reavivamento)
--
--   estado civil   novo valor NOIVO.
--   participação   secretaria.fn_participacao_membros(igreja): para cada membro, a data da última participação
--                  (presença na Escola Sabatina ou contribuição dele ou da família) e se está INACTIVO: estado
--                  ACTIVO no livro sem participação nos últimos 6 meses. O estado no livro não muda (só por voto).
--                  Só para quem lê os membros da igreja; devolve datas, nunca valores.
--   duplicados     tesouraria.fn_contribuicoes_sobrepostas(membro, família, data): dízimos do mesmo mês já lançados
--                  em nome da família do membro (ou, para uma família, em nome dos seus membros). Só avisa.
--   metas          tesouraria.fn_alvo_sugerido(igreja, fundo, ano): o alvo do ano anterior + 5% (o utilizador
--                  pode ajustar). O histórico é o próprio alvo de cada ano (e o log de auditoria).
--                  tesouraria.vw_fundo_mensal: o arrecadado por fundo, mês a mês (registo mensal e acumulado no ano).
--
-- A obra de reavivamento é um fundo próprio da igreja (Fundos e ofertas) com um alvo por ano: não há tabela nova.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TYPE nucleo.estado_civil_t ADD VALUE IF NOT EXISTS 'NOIVO';

-- ---------------------------------------------------------------- participação dos membros
CREATE FUNCTION secretaria.fn_participacao_membros(p_igr INT, p_meses INT DEFAULT 6)
RETURNS TABLE (mem_id INT, ultima_participacao DATE, inactivo BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    WITH membros AS (
        SELECT m.mem_id, m.mem_fam_id, m.mem_estado
          FROM secretaria.membro m
         WHERE m.mem_igr_id = p_igr AND m.mem_end_date IS NULL
           AND p_igr = ANY (nucleo.fn_igrejas_com_permissao('secretaria.membro.ler'))
    ), datas AS (
        SELECT x.mem_id, x.mem_estado,
               greatest(
                 (SELECT max(s.esa_data) FROM escola_sabatina.presenca p
                    JOIN escola_sabatina.relatorio_sabado r ON r.ers_id = p.epr_ers_id
                    JOIN escola_sabatina.sabado s ON s.esa_id = r.ers_esa_id
                   WHERE p.epr_mem_id = x.mem_id AND p.epr_presente AND p.epr_end_date IS NULL),
                 (SELECT max((t.tra_data_hora AT TIME ZONE 'Africa/Maputo')::DATE) FROM tesouraria.transacao t
                   WHERE (t.tra_mem_id = x.mem_id OR (x.mem_fam_id IS NOT NULL AND t.tra_fam_id = x.mem_fam_id))
                     AND t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL
                     AND t.tra_estado IN ('PENDENTE', 'CONFIRMADA') AND t.tra_end_date IS NULL)) AS ultima
          FROM membros x
    )
    SELECT d.mem_id, d.ultima,
           d.mem_estado = 'ACTIVO' AND (d.ultima IS NULL OR d.ultima < (current_date - make_interval(months => p_meses)))
      FROM datas d
$$;
COMMENT ON FUNCTION secretaria.fn_participacao_membros(INT, INT) IS
    'V36: membros ACTIVO sem presença na ES nem contribuição nos últimos meses = inactivos (indicador; o estado no livro não muda)';
REVOKE ALL ON FUNCTION secretaria.fn_participacao_membros(INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION secretaria.fn_participacao_membros(INT, INT) TO app_igreja;

-- ---------------------------------------------------------------- dízimo do mesmo mês em nome do membro e da família
-- SECURITY INVOKER: só encontra os movimentos que o utilizador pode ler (RLS).
CREATE FUNCTION tesouraria.fn_contribuicoes_sobrepostas(p_mem INT, p_fam INT, p_data DATE)
RETURNS TABLE (tra_id BIGINT, data_hora TIMESTAMPTZ, quem TEXT, dizimo DECIMAL(14,2), recibo TEXT)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT t.tra_id, t.tra_data_hora,
           coalesce((SELECT m.mem_nome || ' ' || m.mem_apelido FROM secretaria.membro m WHERE m.mem_id = t.tra_mem_id),
                    (SELECT f.fam_nome FROM secretaria.familia f WHERE f.fam_id = t.tra_fam_id))::TEXT,
           sum(l.tli_valor)::DECIMAL(14,2),
           (SELECT r.rec_numero || '/' || r.rec_ano FROM tesouraria.recibo r WHERE r.rec_tra_id = t.tra_id AND r.rec_end_date IS NULL)
      FROM tesouraria.transacao t
      JOIN tesouraria.transacao_linha l ON l.tli_tra_id = t.tra_id AND l.tli_end_date IS NULL
      JOIN tesouraria.fundo fu ON fu.fun_id = l.tli_fun_id AND fu.fun_tipo = 'DIZIMO'
     WHERE t.tra_tipo = 'ENTRADA' AND t.tra_estorno_tra_id IS NULL AND t.tra_end_date IS NULL
       AND t.tra_estado IN ('PENDENTE', 'CONFIRMADA')
       AND date_trunc('month', t.tra_data_hora AT TIME ZONE 'Africa/Maputo') = date_trunc('month', p_data::TIMESTAMP)
       AND (
            -- a contribuir um membro: a família dele já entregou o dízimo neste mês
            (p_mem IS NOT NULL AND t.tra_fam_id = (SELECT m.mem_fam_id FROM secretaria.membro m WHERE m.mem_id = p_mem))
            -- a contribuir uma família: um dos membros dela já entregou em nome próprio
         OR (p_fam IS NOT NULL AND t.tra_mem_id IN (SELECT m.mem_id FROM secretaria.membro m
                                                     WHERE m.mem_fam_id = p_fam AND m.mem_end_date IS NULL)))
     GROUP BY t.tra_id
     ORDER BY t.tra_data_hora
$$;
COMMENT ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) IS
    'V36: dízimos do mesmo mês já lançados em nome da família do membro (ou dos membros da família): só aviso';
REVOKE ALL ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_contribuicoes_sobrepostas(INT, INT, DATE) TO app_igreja;

-- ---------------------------------------------------------------- metas anuais: +5% sobre o alvo do ano anterior
CREATE FUNCTION tesouraria.fn_alvo_sugerido(p_igr INT, p_fun INT, p_ano INT)
RETURNS DECIMAL(14,2)
LANGUAGE sql STABLE
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
    SELECT round(a.alv_valor_alvo * 1.05, 2)
      FROM tesouraria.alvo a
     WHERE a.alv_igr_id = p_igr AND a.alv_fun_id = p_fun AND a.alv_end_date IS NULL
       AND EXTRACT(YEAR FROM a.alv_data_inicio) = p_ano - 1
     ORDER BY a.alv_data_inicio DESC, a.alv_id DESC
     LIMIT 1
$$;
COMMENT ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) IS
    'V36: meta do ano = alvo do ano anterior + 5% (sugestão; o utilizador autorizado pode ajustar)';
REVOKE ALL ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tesouraria.fn_alvo_sugerido(INT, INT, INT) TO app_igreja;

-- arrecadado por fundo, mês a mês (sem estornos)
CREATE VIEW tesouraria.vw_fundo_mensal WITH (security_invoker = true) AS
SELECT s.sdf_igr_id AS igreja_id, s.sdf_fun_id AS fundo_id, f.fun_nome AS fundo,
       EXTRACT(YEAR FROM s.sdf_data)::INT AS ano, EXTRACT(MONTH FROM s.sdf_data)::INT AS mes,
       sum(s.sdf_entradas - s.sdf_estornos_entradas)::DECIMAL(14,2) AS arrecadado
  FROM tesouraria.saldo_diario_fundo s
  JOIN tesouraria.fundo f ON f.fun_id = s.sdf_fun_id
 WHERE s.sdf_end_date IS NULL
 GROUP BY s.sdf_igr_id, s.sdf_fun_id, f.fun_nome, EXTRACT(YEAR FROM s.sdf_data), EXTRACT(MONTH FROM s.sdf_data);
COMMENT ON VIEW tesouraria.vw_fundo_mensal IS 'V36: arrecadado por fundo e mês (ex.: obra de reavivamento: registo mensal e acumulado no ano)';
GRANT SELECT ON tesouraria.vw_fundo_mensal TO app_igreja;

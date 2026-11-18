-- =====================================================================
-- V44 · Escala com as funções da programação do culto e a programação do dia (F-ACT)
--
--   escala        funções novas, com os nomes da programação: apresentador da Escola Sabatina, apresentador do culto,
--                 Sermão da criança, oração inicial, oração final, apresentador e meditação da JA (o pregador é o
--                 "Sermão principal"); o dia da escala ganha a família responsável pela Escola Sabatina (eds_fam_id).
--   programação   actividades.programa_dia (um por igreja e dia), programa_parte (Escola Sabatina, Transição, Culto
--                 Divino, JA…, com o apresentador) e programa_item (horas, actividade, responsável: membro, família,
--                 departamento ou texto, e destaque). Partes e itens podem estar ligados a uma função da escala
--                 (escala = PREGADOR, TRADUTOR, FAMILIA_ES…): actividades.fn_programa_preencher põe lá quem está
--                 escalado nesse dia. actividades.fn_programa_preparar cria a programação de um dia a partir do
--                 modelo (como a folha da igreja) ou copiando outro dia, e preenche-a pela escala.
--
-- Permissões novas (actividades.programa_dia/parte/item.*): as mesmas da escala (actividades.escala_plano.*).
-- Gerado com database/gerador (defs.py).
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- ---------------------------------------------------------------- escala: funções da programação do culto
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_ES';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_CULTO';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'SERMAO_CRIANCA';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ORACAO_INICIAL';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'ORACAO_FINAL';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'APRESENTADOR_JA';
ALTER TYPE nucleo.funcao_escala_t ADD VALUE IF NOT EXISTS 'MEDITACAO_JA';

-- nome de cada função nos lembretes por SMS (compara como texto: os valores novos são desta transacção)
CREATE OR REPLACE FUNCTION actividades.fn_funcao_escala_nome(p_funcao nucleo.funcao_escala_t) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_funcao::text
        WHEN 'PREGADOR' THEN 'pregador(a) do Sermão principal'
        WHEN 'ANCIAO_DO_DIA' THEN 'ancião do dia'
        WHEN 'DIACONO' THEN 'diácono'
        WHEN 'DIACONISA' THEN 'diaconisa'
        WHEN 'RECEPCAO' THEN 'recepção'
        WHEN 'MUSICA' THEN 'música'
        WHEN 'SONOPLASTIA' THEN 'sonoplastia'
        WHEN 'PROFESSOR_ES' THEN 'professor(a) da Escola Sabatina'
        WHEN 'DIRECTOR_ES' THEN 'director(a) da Escola Sabatina'
        WHEN 'LIMPEZA' THEN 'limpeza'
        WHEN 'TRADUTOR' THEN 'tradutor(a)'
        WHEN 'ACOMPANHANTE_VISITAS' THEN 'acompanhante (visitas e 2.ª oração)'
        WHEN 'ACOMPANHANTE_OFERTAS' THEN 'acompanhante (dízimos e ofertas)'
        WHEN 'ACOMPANHANTE_BOAS_VINDAS' THEN 'acompanhante (boas-vindas e 1.ª oração)'
        WHEN 'APRESENTADOR_ES' THEN 'apresentador(a) da Escola Sabatina'
        WHEN 'APRESENTADOR_CULTO' THEN 'apresentador(a) do Culto Divino'
        WHEN 'SERMAO_CRIANCA' THEN 'responsável pelo Sermão da criança'
        WHEN 'ORACAO_INICIAL' THEN 'oração inicial do culto'
        WHEN 'ORACAO_FINAL' THEN 'oração final do culto'
        WHEN 'APRESENTADOR_JA' THEN 'apresentador(a) da JA'
        WHEN 'MEDITACAO_JA' THEN 'meditação da JA'
        ELSE 'serviço' END;
$$;

-- o dia da escala: a família que faz a programação da Escola Sabatina
ALTER TABLE actividades.escala_dia ADD COLUMN eds_fam_id INT;
ALTER TABLE actividades.escala_dia ADD CONSTRAINT fk_eds_fam_id FOREIGN KEY (eds_fam_id) REFERENCES secretaria.familia(fam_id);
COMMENT ON COLUMN actividades.escala_dia.eds_fam_id IS 'Família responsável pela programação da Escola Sabatina (V44)';
CREATE INDEX idx_eds_fam_id ON actividades.escala_dia (eds_fam_id);

CREATE FUNCTION actividades.fn_eds_familia() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NEW.eds_fam_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM secretaria.familia f JOIN actividades.escala_plano p ON p.epl_id = NEW.eds_epl_id
         WHERE f.fam_id = NEW.eds_fam_id AND f.fam_igr_id = p.epl_igr_id) THEN
        RAISE EXCEPTION 'A família tem de ser da igreja da escala' USING COLUMN = 'eds_fam_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_eds_10_familia BEFORE INSERT OR UPDATE OF eds_fam_id ON actividades.escala_dia
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_eds_familia();

-- ---------------------------------------------------------------- programação do dia (gerada: gen.py)
CREATE TABLE actividades.programa_dia (
    pgd_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pgd_igr_id INT NOT NULL,
    pgd_data DATE NOT NULL,
    pgd_titulo VARCHAR(150),
    pgd_observacoes VARCHAR(500),
    pgd_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pgd_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pgd_criado_por INT,
    pgd_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pgd_modificado_por INT,
    pgd_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pgd_igr_id FOREIGN KEY (pgd_igr_id) REFERENCES organizacao.igreja(igr_id),
    CONSTRAINT chk_pgd_end_date CHECK (pgd_end_date IS NULL OR pgd_end_date >= pgd_criado_em)
);

COMMENT ON COLUMN actividades.programa_dia.pgd_titulo IS 'Título da folha; por defeito, a data por extenso';
COMMENT ON COLUMN actividades.programa_dia.pgd_observacoes IS 'Nota no fim da folha (ex.: passível de ajustes e simplificação)';
CREATE UNIQUE INDEX uq_pgd_igr_id_data ON actividades.programa_dia (pgd_igr_id, pgd_data) WHERE pgd_end_date IS NULL;

CREATE TABLE actividades.programa_parte (
    ppa_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ppa_pgd_id INT NOT NULL,
    ppa_ordem SMALLINT NOT NULL DEFAULT 1,
    ppa_titulo VARCHAR(100) NOT NULL,
    ppa_rotulo VARCHAR(30) NOT NULL DEFAULT 'Apresentador',
    ppa_apresentador_mem_id INT,
    ppa_apresentador_fam_id INT,
    ppa_apresentador_texto VARCHAR(150),
    ppa_escala VARCHAR(20),
    ppa_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    ppa_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppa_criado_por INT,
    ppa_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ppa_modificado_por INT,
    ppa_end_date TIMESTAMPTZ,
    CONSTRAINT fk_ppa_pgd_id FOREIGN KEY (ppa_pgd_id) REFERENCES actividades.programa_dia(pgd_id),
    CONSTRAINT fk_ppa_apresentador_mem_id FOREIGN KEY (ppa_apresentador_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_ppa_apresentador_fam_id FOREIGN KEY (ppa_apresentador_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT chk_ppa_apresentador CHECK (num_nonnulls(ppa_apresentador_mem_id, ppa_apresentador_fam_id, ppa_apresentador_texto) <= 1),
    CONSTRAINT chk_ppa_escala CHECK (ppa_escala IS NULL OR ppa_escala IN ('APRESENTADOR_ES', 'APRESENTADOR_CULTO', 'PREGADOR', 'TRADUTOR', 'SERMAO_CRIANCA', 'ORACAO_INICIAL', 'ORACAO_FINAL', 'APRESENTADOR_JA', 'MEDITACAO_JA', 'FAMILIA_ES')),
    CONSTRAINT chk_ppa_end_date CHECK (ppa_end_date IS NULL OR ppa_end_date >= ppa_criado_em)
);

COMMENT ON COLUMN actividades.programa_parte.ppa_titulo IS 'Ex.: Programação do Culto Divino';
COMMENT ON COLUMN actividades.programa_parte.ppa_rotulo IS 'Cabeçalho da coluna do apresentador (ex.: Apresentador, Transição)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_mem_id IS 'Apresentador (membro)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_fam_id IS 'Apresentador (família, ex.: Família Magaia)';
COMMENT ON COLUMN actividades.programa_parte.ppa_apresentador_texto IS 'Apresentador escrito (visitante, grupo)';
COMMENT ON COLUMN actividades.programa_parte.ppa_escala IS 'Função da escala que preenche o apresentador (ex.: APRESENTADOR_CULTO, FAMILIA_ES)';
CREATE INDEX idx_ppa_pgd_id ON actividades.programa_parte (ppa_pgd_id);
CREATE INDEX idx_ppa_apresentador_mem_id ON actividades.programa_parte (ppa_apresentador_mem_id);
CREATE INDEX idx_ppa_apresentador_fam_id ON actividades.programa_parte (ppa_apresentador_fam_id);

CREATE TABLE actividades.programa_item (
    pit_id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    pit_pgd_id INT NOT NULL,
    pit_ppa_id INT NOT NULL,
    pit_ordem SMALLINT NOT NULL DEFAULT 1,
    pit_hora_inicio VARCHAR(5),
    pit_hora_fim VARCHAR(5),
    pit_actividade VARCHAR(200) NOT NULL,
    pit_responsavel_mem_id INT,
    pit_responsavel_fam_id INT,
    pit_responsavel_ide_id INT,
    pit_responsavel_texto VARCHAR(150),
    pit_escala VARCHAR(20),
    pit_destaque BOOLEAN NOT NULL DEFAULT FALSE,
    pit_estado estado_registo_t NOT NULL DEFAULT 'ACTIVO',
    pit_criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pit_criado_por INT,
    pit_modificado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    pit_modificado_por INT,
    pit_end_date TIMESTAMPTZ,
    CONSTRAINT fk_pit_pgd_id FOREIGN KEY (pit_pgd_id) REFERENCES actividades.programa_dia(pgd_id),
    CONSTRAINT fk_pit_ppa_id FOREIGN KEY (pit_ppa_id) REFERENCES actividades.programa_parte(ppa_id),
    CONSTRAINT fk_pit_responsavel_mem_id FOREIGN KEY (pit_responsavel_mem_id) REFERENCES secretaria.membro(mem_id),
    CONSTRAINT fk_pit_responsavel_fam_id FOREIGN KEY (pit_responsavel_fam_id) REFERENCES secretaria.familia(fam_id),
    CONSTRAINT fk_pit_responsavel_ide_id FOREIGN KEY (pit_responsavel_ide_id) REFERENCES organizacao.igreja_departamento(ide_id),
    CONSTRAINT chk_pit_responsavel CHECK (num_nonnulls(pit_responsavel_mem_id, pit_responsavel_fam_id, pit_responsavel_ide_id, pit_responsavel_texto) <= 1),
    CONSTRAINT chk_pit_horas CHECK ((pit_hora_inicio IS NULL OR pit_hora_inicio ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') AND (pit_hora_fim IS NULL OR pit_hora_fim ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')),
    CONSTRAINT chk_pit_escala CHECK (pit_escala IS NULL OR pit_escala IN ('APRESENTADOR_ES', 'APRESENTADOR_CULTO', 'PREGADOR', 'TRADUTOR', 'SERMAO_CRIANCA', 'ORACAO_INICIAL', 'ORACAO_FINAL', 'APRESENTADOR_JA', 'MEDITACAO_JA', 'FAMILIA_ES')),
    CONSTRAINT chk_pit_end_date CHECK (pit_end_date IS NULL OR pit_end_date >= pit_criado_em)
);

COMMENT ON COLUMN actividades.programa_item.pit_hora_inicio IS 'Hora (hh:mm)';
COMMENT ON COLUMN actividades.programa_item.pit_hora_fim IS 'Hora (hh:mm)';
COMMENT ON COLUMN actividades.programa_item.pit_actividade IS 'Ex.: Hino inicial (H.A 509)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_mem_id IS 'Responsável (membro)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_fam_id IS 'Responsável (família)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_ide_id IS 'Responsável (departamento, ex.: Mulher Adventista)';
COMMENT ON COLUMN actividades.programa_item.pit_responsavel_texto IS 'Responsável escrito (ex.: Todos, Diáconos, Monitores, um visitante)';
COMMENT ON COLUMN actividades.programa_item.pit_escala IS 'Função da escala que preenche o responsável (ex.: PREGADOR, TRADUTOR, FAMILIA_ES)';
COMMENT ON COLUMN actividades.programa_item.pit_destaque IS 'Linha em destaque na folha (ex.: Sermão principal)';
CREATE INDEX idx_pit_pgd_id ON actividades.programa_item (pit_pgd_id);
CREATE INDEX idx_pit_ppa_id ON actividades.programa_item (pit_ppa_id);
CREATE INDEX idx_pit_responsavel_mem_id ON actividades.programa_item (pit_responsavel_mem_id);
CREATE INDEX idx_pit_responsavel_fam_id ON actividades.programa_item (pit_responsavel_fam_id);
CREATE INDEX idx_pit_responsavel_ide_id ON actividades.programa_item (pit_responsavel_ide_id);

CREATE TRIGGER trg_pgd_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pgd', 'actividades.programa_dia', 'pgd_igr_id');
CREATE TRIGGER trg_pgd_00_sem_delete BEFORE DELETE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pgd');
CREATE TRIGGER trg_pgd_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_dia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pgd');
CREATE TRIGGER trg_pgd_99_log AFTER UPDATE ON actividades.programa_dia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pgd');
ALTER TABLE actividades.programa_dia ADD CONSTRAINT fk_pgd_criado_por FOREIGN KEY (pgd_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_dia ADD CONSTRAINT fk_pgd_modificado_por FOREIGN KEY (pgd_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_ppa_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ppa', 'actividades.programa_parte', '');
CREATE TRIGGER trg_ppa_00_sem_delete BEFORE DELETE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ppa');
CREATE TRIGGER trg_ppa_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_parte FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ppa');
CREATE TRIGGER trg_ppa_99_log AFTER UPDATE ON actividades.programa_parte FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ppa');
ALTER TABLE actividades.programa_parte ADD CONSTRAINT fk_ppa_criado_por FOREIGN KEY (ppa_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_parte ADD CONSTRAINT fk_ppa_modificado_por FOREIGN KEY (ppa_modificado_por) REFERENCES nucleo.usuario(usu_id);
CREATE TRIGGER trg_pit_00_padrao BEFORE INSERT OR UPDATE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pit', 'actividades.programa_item', '');
CREATE TRIGGER trg_pit_00_sem_delete BEFORE DELETE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pit');
CREATE TRIGGER trg_pit_00_sem_truncate BEFORE TRUNCATE ON actividades.programa_item FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pit');
CREATE TRIGGER trg_pit_99_log AFTER UPDATE ON actividades.programa_item FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pit');
ALTER TABLE actividades.programa_item ADD CONSTRAINT fk_pit_criado_por FOREIGN KEY (pit_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.programa_item ADD CONSTRAINT fk_pit_modificado_por FOREIGN KEY (pit_modificado_por) REFERENCES nucleo.usuario(usu_id);

ALTER TABLE actividades.programa_dia ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pgd_ler ON actividades.programa_dia FOR SELECT USING (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.ler'))::INT[]));
CREATE POLICY pol_pgd_criar ON actividades.programa_dia FOR INSERT WITH CHECK (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.criar'))::INT[]));
CREATE POLICY pol_pgd_alterar ON actividades.programa_dia FOR UPDATE USING (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.alterar'))::INT[])) WITH CHECK (pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_dia.alterar'))::INT[]));
ALTER TABLE actividades.programa_parte ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_ppa_ler ON actividades.programa_parte FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.ler'))::INT[])));
CREATE POLICY pol_ppa_criar ON actividades.programa_parte FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.criar'))::INT[])));
CREATE POLICY pol_ppa_alterar ON actividades.programa_parte FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = ppa_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_parte.alterar'))::INT[])));
ALTER TABLE actividades.programa_item ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_pit_ler ON actividades.programa_item FOR SELECT USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.ler'))::INT[])));
CREATE POLICY pol_pit_criar ON actividades.programa_item FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.criar'))::INT[])));
CREATE POLICY pol_pit_alterar ON actividades.programa_item FOR UPDATE USING (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.alterar'))::INT[]))) WITH CHECK (EXISTS (SELECT 1 FROM actividades.programa_dia x WHERE x.pgd_id = pit_pgd_id AND x.pgd_igr_id = ANY ((SELECT nucleo.fn_igrejas_com_permissao('actividades.programa_item.alterar'))::INT[])));

COMMENT ON TABLE actividades.programa_dia IS 'Programação do dia (ex.: sábado): as partes e os itens com horas e responsáveis, para imprimir (V44)';
COMMENT ON TABLE actividades.programa_parte IS 'Parte da programação do dia (ex.: Programação da Escola Sabatina, Transição, Culto Divino, JA) e o apresentador (V44)';
COMMENT ON TABLE actividades.programa_item IS 'Item da programação do dia: horas, actividade e responsável (membro, família, departamento ou texto) (V44)';
GRANT SELECT, INSERT, UPDATE ON actividades.programa_dia, actividades.programa_parte, actividades.programa_item TO app_igreja;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA actividades TO app_igreja;
COMMENT ON INDEX actividades.uq_pgd_igr_id_data IS '[data] Já há uma programação desta igreja para este dia.';
COMMENT ON CONSTRAINT chk_ppa_apresentador ON actividades.programa_parte IS '[apresentadorMembroId] Indique só um apresentador: um membro, uma família ou o nome escrito.';
COMMENT ON CONSTRAINT chk_ppa_escala ON actividades.programa_parte IS '[escala] Função da escala desconhecida.';
COMMENT ON CONSTRAINT chk_pit_responsavel ON actividades.programa_item IS '[responsavelMembroId] Indique só um responsável: um membro, uma família, um departamento ou o nome escrito.';
COMMENT ON CONSTRAINT chk_pit_horas ON actividades.programa_item IS '[horaInicio] Escreva as horas como hh:mm (ex.: 10:30).';
COMMENT ON CONSTRAINT chk_pit_escala ON actividades.programa_item IS '[escala] Função da escala desconhecida.';

-- permissões: as mesmas da escala
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao)
SELECT 'actividades.' || t.tabela || '.' || a.accao, a.rotulo || t.descricao
  FROM (VALUES ('programa_dia', 'Programação do dia (ex.: sábado): as partes e os itens com horas e responsáveis, para imprimir (V44)'),
               ('programa_parte', 'Parte da programação do dia (ex.: Programação da Escola Sabatina, Transição, Culto Divino, JA) e o apresentador (V44)'),
               ('programa_item', 'Item da programação do dia: horas, actividade e responsável (membro, família, departamento ou texto) (V44)')) t(tabela, descricao),
       (VALUES ('ler', 'Ler: '), ('criar', 'Criar: '), ('alterar', 'Alterar: '), ('terminar', 'Terminar (end_date): ')) a(accao, rotulo);
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT pp.ppe_per_id, novo.prm_id
  FROM nucleo.perfil_permissao pp
  JOIN nucleo.permissao antigo ON antigo.prm_id = pp.ppe_prm_id AND antigo.prm_codigo LIKE 'actividades.escala_plano.%'
  JOIN nucleo.permissao novo ON novo.prm_codigo IN (replace(antigo.prm_codigo, 'escala_plano', 'programa_dia'),
                                                    replace(antigo.prm_codigo, 'escala_plano', 'programa_parte'),
                                                    replace(antigo.prm_codigo, 'escala_plano', 'programa_item'))
 WHERE pp.ppe_end_date IS NULL;

-- o item pertence a uma parte do mesmo dia
CREATE FUNCTION actividades.fn_pit_validar() RETURNS trigger
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM actividades.programa_parte WHERE ppa_id = NEW.pit_ppa_id AND ppa_pgd_id = NEW.pit_pgd_id) THEN
        RAISE EXCEPTION 'A parte não é desta programação' USING COLUMN = 'pit_ppa_id';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER trg_pit_10_validar BEFORE INSERT OR UPDATE OF pit_pgd_id, pit_ppa_id ON actividades.programa_item
    FOR EACH ROW EXECUTE FUNCTION actividades.fn_pit_validar();

-- ---------------------------------------------------------------- preencher pela escala do dia
-- Partes e itens com "escala" recebem quem está escalado nessa função nesse dia (o substituto, se houver); com
-- FAMILIA_ES, a família do dia da escala. Sem ninguém escalado, fica o que lá estava. Devolve quantos mudaram.
CREATE FUNCTION actividades.fn_programa_preencher(p_pgd INT) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_igr  INT;
    v_data DATE;
    v_fam  INT;
    v_n    INT := 0;
    v_k    INT;
BEGIN
    SELECT pgd_igr_id, pgd_data INTO v_igr, v_data FROM actividades.programa_dia WHERE pgd_id = p_pgd AND pgd_end_date IS NULL;
    IF NOT FOUND THEN RAISE EXCEPTION 'Programação % não encontrada', p_pgd USING ERRCODE = 'P0002'; END IF;

    SELECT d.eds_fam_id INTO v_fam
      FROM actividades.escala_dia d JOIN actividades.escala_plano p ON p.epl_id = d.eds_epl_id
     WHERE p.epl_igr_id = v_igr AND d.eds_data = v_data AND d.eds_end_date IS NULL AND p.epl_end_date IS NULL
       AND d.eds_fam_id IS NOT NULL
     ORDER BY p.epl_publicada DESC, d.eds_id DESC LIMIT 1;

    -- quem está escalado em cada função nesse dia (o substituto, se houver; o primeiro, se houver mais de um)
    UPDATE actividades.programa_parte x
       SET ppa_apresentador_mem_id = t.mem_id, ppa_apresentador_fam_id = NULL, ppa_apresentador_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.ppa_pgd_id = p_pgd AND x.ppa_end_date IS NULL AND x.ppa_escala = t.funcao
       AND x.ppa_apresentador_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    UPDATE actividades.programa_item x
       SET pit_responsavel_mem_id = t.mem_id, pit_responsavel_fam_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
      FROM (SELECT DISTINCT ON (e.esc_funcao::text) e.esc_funcao::text AS funcao, COALESCE(e.esc_substituto_mem_id, e.esc_mem_id) AS mem_id
              FROM actividades.escala e
             WHERE e.esc_igr_id = v_igr AND e.esc_data = v_data AND e.esc_end_date IS NULL AND e.esc_estado::text <> 'FALTOU'
             ORDER BY e.esc_funcao::text, e.esc_id) t
     WHERE x.pit_pgd_id = p_pgd AND x.pit_end_date IS NULL AND x.pit_escala = t.funcao
       AND x.pit_responsavel_mem_id IS DISTINCT FROM t.mem_id;
    GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;

    IF v_fam IS NOT NULL THEN
        UPDATE actividades.programa_parte
           SET ppa_apresentador_fam_id = v_fam, ppa_apresentador_mem_id = NULL, ppa_apresentador_texto = NULL
         WHERE ppa_pgd_id = p_pgd AND ppa_end_date IS NULL AND ppa_escala = 'FAMILIA_ES' AND ppa_apresentador_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
        UPDATE actividades.programa_item
           SET pit_responsavel_fam_id = v_fam, pit_responsavel_mem_id = NULL, pit_responsavel_ide_id = NULL, pit_responsavel_texto = NULL
         WHERE pit_pgd_id = p_pgd AND pit_end_date IS NULL AND pit_escala = 'FAMILIA_ES' AND pit_responsavel_fam_id IS DISTINCT FROM v_fam;
        GET DIAGNOSTICS v_k = ROW_COUNT; v_n := v_n + v_k;
    END IF;
    RETURN v_n;
END $$;
COMMENT ON FUNCTION actividades.fn_programa_preencher(INT) IS 'Põe nas partes e itens ligados à escala quem está escalado nesse dia (V44)';
GRANT EXECUTE ON FUNCTION actividades.fn_programa_preencher(INT) TO app_igreja;

-- ---------------------------------------------------------------- preparar a programação de um dia
-- A partir de outro dia (copia as partes e os itens) ou, sem origem, do modelo da folha da igreja (Escola Sabatina,
-- Transição, Culto Divino, JA); depois preenche pela escala. Corre com as permissões de quem pede (RLS).
CREATE FUNCTION actividades.fn_programa_preparar(p_igr INT, p_data DATE, p_origem INT DEFAULT NULL) RETURNS INT
LANGUAGE plpgsql
SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public
AS $$
DECLARE
    v_pgd   INT;
    v_parte INT;
    r       RECORD;
BEGIN
    IF p_origem IS NOT NULL AND NOT EXISTS (SELECT 1 FROM actividades.programa_dia WHERE pgd_id = p_origem AND pgd_igr_id = p_igr AND pgd_end_date IS NULL) THEN
        RAISE EXCEPTION 'A programação a copiar não existe nesta igreja' USING COLUMN = 'pgd_id';
    END IF;
    INSERT INTO actividades.programa_dia (pgd_igr_id, pgd_data, pgd_observacoes)
    VALUES (p_igr, p_data, CASE WHEN p_origem IS NULL THEN 'Passível de ajustes e simplificação'
                                ELSE (SELECT pgd_observacoes FROM actividades.programa_dia WHERE pgd_id = p_origem) END)
    RETURNING pgd_id INTO v_pgd;

    IF p_origem IS NOT NULL THEN
        FOR r IN SELECT * FROM actividades.programa_parte WHERE ppa_pgd_id = p_origem AND ppa_end_date IS NULL ORDER BY ppa_ordem, ppa_id LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_apresentador_mem_id,
                                                   ppa_apresentador_fam_id, ppa_apresentador_texto, ppa_escala)
            VALUES (v_pgd, r.ppa_ordem, r.ppa_titulo, r.ppa_rotulo, r.ppa_apresentador_mem_id, r.ppa_apresentador_fam_id,
                    r.ppa_apresentador_texto, r.ppa_escala)
            RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_mem_id, pit_responsavel_fam_id, pit_responsavel_ide_id,
                                                   pit_responsavel_texto, pit_escala, pit_destaque)
            SELECT v_pgd, v_parte, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade, pit_responsavel_mem_id,
                   pit_responsavel_fam_id, pit_responsavel_ide_id, pit_responsavel_texto, pit_escala, pit_destaque
              FROM actividades.programa_item WHERE pit_ppa_id = r.ppa_id AND pit_end_date IS NULL;
        END LOOP;
    ELSE
        FOR r IN SELECT * FROM (VALUES
            (1, 'Programação da Escola Sabatina', 'Apresentador', 'FAMILIA_ES'),
            (2, 'Transição', 'Transição', NULL),
            (3, 'Programação do Culto Divino', 'Apresentador', 'APRESENTADOR_CULTO'),
            (4, 'JA', 'Apresentador', 'APRESENTADOR_JA')) AS m(ordem, titulo, rotulo, escala) LOOP
            INSERT INTO actividades.programa_parte (ppa_pgd_id, ppa_ordem, ppa_titulo, ppa_rotulo, ppa_escala)
            VALUES (v_pgd, r.ordem, r.titulo, r.rotulo, r.escala) RETURNING ppa_id INTO v_parte;
            INSERT INTO actividades.programa_item (pit_pgd_id, pit_ppa_id, pit_ordem, pit_hora_inicio, pit_hora_fim, pit_actividade,
                                                   pit_responsavel_texto, pit_escala, pit_destaque)
            SELECT v_pgd, v_parte, i.ordem, i.inicio, i.fim, i.actividade, i.texto, i.escala, i.destaque
              FROM (VALUES
                (1, 1, '08:50', '09:00', 'Momento de louvor', 'Todos', NULL, FALSE),
                (1, 2, '09:00', '09:05', 'Hino inicial', 'Todos', NULL, FALSE),
                (1, 3, '09:05', '09:10', 'Oração inicial', NULL, 'FAMILIA_ES', FALSE),
                (1, 4, '09:10', '09:15', 'Música especial', NULL, 'FAMILIA_ES', FALSE),
                (1, 5, '09:15', '09:25', '28 Crenças', NULL, 'FAMILIA_ES', FALSE),
                (1, 6, '09:25', '09:30', 'Carta missionária', NULL, 'FAMILIA_ES', FALSE),
                (1, 7, '09:30', '09:35', 'Capítulo do dia', NULL, 'FAMILIA_ES', FALSE),
                (1, 8, '09:35', '09:40', 'Momento de testemunho / gratidão', 'Todos', NULL, FALSE),
                (1, 9, '09:40', '10:15', 'Resumo das lições', 'Monitores', NULL, TRUE),
                (1, 10, NULL, NULL, 'Oração final', NULL, 'FAMILIA_ES', FALSE),
                (2, 1, '10:15', '10:20', 'Devolução de envelopes', 'Tesouraria', NULL, FALSE),
                (2, 2, '10:20', '10:25', 'Minuto saúde', NULL, NULL, FALSE),
                (2, 3, '10:25', '10:30', 'Momento de louvor', 'Departamento de Música', NULL, FALSE),
                (3, 1, '10:30', '10:35', 'Entrada da tribuna e doxologia', 'Todos', NULL, FALSE),
                (3, 2, '10:35', '10:40', 'Boas-vindas e anúncios', 'Secretaria', NULL, FALSE),
                (3, 3, '10:40', '10:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (3, 4, '10:45', '10:50', 'Oração inicial', NULL, 'ORACAO_INICIAL', FALSE),
                (3, 5, '10:50', '10:55', 'Marca de um mordomo', 'Tesouraria', NULL, FALSE),
                (3, 6, '10:55', '11:00', 'Música especial', NULL, NULL, FALSE),
                (3, 7, '11:00', '11:05', 'Recolha das ofertas e dízimos', 'Diáconos', NULL, FALSE),
                (3, 8, '11:05', '11:10', 'Sermão da criança', NULL, 'SERMAO_CRIANCA', FALSE),
                (3, 9, '11:15', '12:15', 'Sermão principal', NULL, 'PREGADOR', TRUE),
                (3, 10, '11:15', '12:15', 'Tradutor', NULL, 'TRADUTOR', TRUE),
                (3, 11, '12:15', '12:20', 'Hino final', 'Todos', NULL, TRUE),
                (3, 12, '12:20', '12:25', 'Oração final', NULL, 'ORACAO_FINAL', FALSE),
                (3, 13, '12:30', NULL, 'Despedida', NULL, 'APRESENTADOR_CULTO', FALSE),
                (4, 1, '14:30', '14:40', 'Momento de louvor', 'Todos', NULL, TRUE),
                (4, 2, '14:40', '14:45', 'Hino inicial', 'Todos', NULL, FALSE),
                (4, 3, '14:45', '14:50', 'Oração inicial', NULL, NULL, FALSE),
                (4, 4, '14:50', '14:55', 'Hino especial', 'Jovens', NULL, FALSE),
                (4, 5, '14:55', '15:00', 'Meditação', NULL, 'MEDITACAO_JA', FALSE),
                (4, 6, '15:00', '15:05', 'Hino especial', NULL, NULL, FALSE),
                (4, 7, '15:05', '16:05', 'Tema da tarde', NULL, NULL, FALSE),
                (4, 8, '16:05', '16:10', 'Introdução da lição', NULL, NULL, FALSE),
                (4, 9, '16:10', '16:15', 'Oração final', NULL, NULL, FALSE),
                (4, 10, '16:15', '16:20', 'Hino final', 'Todos', NULL, FALSE),
                (4, 11, '16:20', NULL, 'Despedida', NULL, 'APRESENTADOR_JA', FALSE)
              ) AS i(parte, ordem, inicio, fim, actividade, texto, escala, destaque)
             WHERE i.parte = r.ordem;
        END LOOP;
    END IF;

    PERFORM actividades.fn_programa_preencher(v_pgd);
    RETURN v_pgd;
END $$;
COMMENT ON FUNCTION actividades.fn_programa_preparar(INT, DATE, INT) IS 'Cria a programação de um dia a partir do modelo ou de outro dia e preenche-a pela escala (V44)';
GRANT EXECUTE ON FUNCTION actividades.fn_programa_preparar(INT, DATE, INT) TO app_igreja;

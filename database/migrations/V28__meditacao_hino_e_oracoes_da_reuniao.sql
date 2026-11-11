-- =====================================================================
-- V28 · Reuniões: meditação, hino e orações (F-SEC-04)
--
-- A acta regista quem fez a meditação (um membro desta igreja ou um convidado, ex.: o pastor do distrito), o hino
-- entoado e quem fez a primeira e a última oração. Colunas opcionais: as reuniões antigas ficam como estão.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

ALTER TABLE secretaria.reuniao
  ADD COLUMN reu_meditacao_mem_id INT,
  ADD COLUMN reu_meditacao_convidado VARCHAR(150),
  ADD COLUMN reu_hino VARCHAR(150),
  ADD COLUMN reu_oracao_inicial_mem_id INT,
  ADD COLUMN reu_oracao_final_mem_id INT,
  ADD CONSTRAINT fk_reu_meditacao_mem_id FOREIGN KEY (reu_meditacao_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT fk_reu_oracao_inicial_mem_id FOREIGN KEY (reu_oracao_inicial_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT fk_reu_oracao_final_mem_id FOREIGN KEY (reu_oracao_final_mem_id) REFERENCES secretaria.membro(mem_id),
  ADD CONSTRAINT chk_reu_meditacao CHECK (NOT (reu_meditacao_mem_id IS NOT NULL AND reu_meditacao_convidado IS NOT NULL));

COMMENT ON COLUMN secretaria.reuniao.reu_meditacao_mem_id IS 'Quem fez a meditação (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_meditacao_convidado IS 'Quem fez a meditação, se não for membro desta igreja (ex.: pastor do distrito) (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_hino IS 'Hino entoado, ex.: "Hino 123 — Castelo forte" (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_oracao_inicial_mem_id IS 'Quem fez a primeira oração (V28)';
COMMENT ON COLUMN secretaria.reuniao.reu_oracao_final_mem_id IS 'Quem fez a última oração (V28)';

CREATE INDEX idx_reu_meditacao_mem_id ON secretaria.reuniao (reu_meditacao_mem_id);
CREATE INDEX idx_reu_oracao_inicial_mem_id ON secretaria.reuniao (reu_oracao_inicial_mem_id);
CREATE INDEX idx_reu_oracao_final_mem_id ON secretaria.reuniao (reu_oracao_final_mem_id);

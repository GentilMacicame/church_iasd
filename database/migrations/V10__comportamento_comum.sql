-- =====================================================================
-- V10 · Comportamento comum a todas as tabelas
--   criado/modificado automáticos; DELETE e TRUNCATE proibidos
--   auditoria: cada alteração e término guarda só os campos que mudaram. As inserções não
--   se duplicam no log: a própria linha guarda quem a criou e quando, e nunca é apagada.
-- =====================================================================
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

CREATE TRIGGER trg_per_00_padrao BEFORE INSERT OR UPDATE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('per', 'nucleo.perfil', '');
CREATE TRIGGER trg_per_00_sem_delete BEFORE DELETE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('per');
CREATE TRIGGER trg_per_00_sem_truncate BEFORE TRUNCATE ON nucleo.perfil FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('per');
CREATE TRIGGER trg_per_99_log AFTER UPDATE ON nucleo.perfil FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('per');
ALTER TABLE nucleo.perfil ADD CONSTRAINT fk_per_criado_por FOREIGN KEY (per_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.perfil ADD CONSTRAINT fk_per_modificado_por FOREIGN KEY (per_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_prm_00_padrao BEFORE INSERT OR UPDATE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('prm', 'nucleo.permissao', '');
CREATE TRIGGER trg_prm_00_sem_delete BEFORE DELETE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('prm');
CREATE TRIGGER trg_prm_00_sem_truncate BEFORE TRUNCATE ON nucleo.permissao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('prm');
CREATE TRIGGER trg_prm_99_log AFTER UPDATE ON nucleo.permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('prm');
ALTER TABLE nucleo.permissao ADD CONSTRAINT fk_prm_criado_por FOREIGN KEY (prm_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.permissao ADD CONSTRAINT fk_prm_modificado_por FOREIGN KEY (prm_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ppe_00_padrao BEFORE INSERT OR UPDATE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ppe', 'nucleo.perfil_permissao', '');
CREATE TRIGGER trg_ppe_00_sem_delete BEFORE DELETE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ppe');
CREATE TRIGGER trg_ppe_00_sem_truncate BEFORE TRUNCATE ON nucleo.perfil_permissao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ppe');
CREATE TRIGGER trg_ppe_99_log AFTER UPDATE ON nucleo.perfil_permissao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ppe');
ALTER TABLE nucleo.perfil_permissao ADD CONSTRAINT fk_ppe_criado_por FOREIGN KEY (ppe_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.perfil_permissao ADD CONSTRAINT fk_ppe_modificado_por FOREIGN KEY (ppe_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_usu_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('usu', 'nucleo.usuario', '');
CREATE TRIGGER trg_usu_00_sem_delete BEFORE DELETE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('usu');
CREATE TRIGGER trg_usu_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('usu');
CREATE TRIGGER trg_usu_99_log AFTER UPDATE ON nucleo.usuario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('usu');
ALTER TABLE nucleo.usuario ADD CONSTRAINT fk_usu_criado_por FOREIGN KEY (usu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario ADD CONSTRAINT fk_usu_modificado_por FOREIGN KEY (usu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_uig_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('uig', 'nucleo.usuario_igreja', 'uig_igr_id');
CREATE TRIGGER trg_uig_00_sem_delete BEFORE DELETE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('uig');
CREATE TRIGGER trg_uig_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario_igreja FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('uig');
CREATE TRIGGER trg_uig_99_log AFTER UPDATE ON nucleo.usuario_igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('uig');
ALTER TABLE nucleo.usuario_igreja ADD CONSTRAINT fk_uig_criado_por FOREIGN KEY (uig_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario_igreja ADD CONSTRAINT fk_uig_modificado_por FOREIGN KEY (uig_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_uen_00_padrao BEFORE INSERT OR UPDATE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('uen', 'nucleo.usuario_entidade', '');
CREATE TRIGGER trg_uen_00_sem_delete BEFORE DELETE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('uen');
CREATE TRIGGER trg_uen_00_sem_truncate BEFORE TRUNCATE ON nucleo.usuario_entidade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('uen');
CREATE TRIGGER trg_uen_99_log AFTER UPDATE ON nucleo.usuario_entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('uen');
ALTER TABLE nucleo.usuario_entidade ADD CONSTRAINT fk_uen_criado_por FOREIGN KEY (uen_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.usuario_entidade ADD CONSTRAINT fk_uen_modificado_por FOREIGN KEY (uen_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_lau_00_padrao BEFORE INSERT OR UPDATE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('lau', '', '');
CREATE TRIGGER trg_lau_00_sem_delete BEFORE DELETE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('lau');
CREATE TRIGGER trg_lau_00_sem_truncate BEFORE TRUNCATE ON nucleo.log_auditoria FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('lau');
CREATE TRIGGER trg_lau_00_imutavel BEFORE UPDATE ON nucleo.log_auditoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_imutavel();
ALTER TABLE nucleo.log_auditoria ADD CONSTRAINT fk_lau_criado_por FOREIGN KEY (lau_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE nucleo.log_auditoria ADD CONSTRAINT fk_lau_modificado_por FOREIGN KEY (lau_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ent_00_padrao BEFORE INSERT OR UPDATE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ent', 'organizacao.entidade', '');
CREATE TRIGGER trg_ent_00_sem_delete BEFORE DELETE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ent');
CREATE TRIGGER trg_ent_00_sem_truncate BEFORE TRUNCATE ON organizacao.entidade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ent');
CREATE TRIGGER trg_ent_99_log AFTER UPDATE ON organizacao.entidade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ent');
ALTER TABLE organizacao.entidade ADD CONSTRAINT fk_ent_criado_por FOREIGN KEY (ent_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.entidade ADD CONSTRAINT fk_ent_modificado_por FOREIGN KEY (ent_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dst_00_padrao BEFORE INSERT OR UPDATE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dst', 'organizacao.distrito', '');
CREATE TRIGGER trg_dst_00_sem_delete BEFORE DELETE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dst');
CREATE TRIGGER trg_dst_00_sem_truncate BEFORE TRUNCATE ON organizacao.distrito FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dst');
CREATE TRIGGER trg_dst_99_log AFTER UPDATE ON organizacao.distrito FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dst');
ALTER TABLE organizacao.distrito ADD CONSTRAINT fk_dst_criado_por FOREIGN KEY (dst_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.distrito ADD CONSTRAINT fk_dst_modificado_por FOREIGN KEY (dst_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_igr_00_padrao BEFORE INSERT OR UPDATE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('igr', 'organizacao.igreja', 'igr_id');
CREATE TRIGGER trg_igr_00_sem_delete BEFORE DELETE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('igr');
CREATE TRIGGER trg_igr_00_sem_truncate BEFORE TRUNCATE ON organizacao.igreja FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('igr');
CREATE TRIGGER trg_igr_99_log AFTER UPDATE ON organizacao.igreja FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('igr');
ALTER TABLE organizacao.igreja ADD CONSTRAINT fk_igr_criado_por FOREIGN KEY (igr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.igreja ADD CONSTRAINT fk_igr_modificado_por FOREIGN KEY (igr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dep_00_padrao BEFORE INSERT OR UPDATE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dep', 'organizacao.departamento', '');
CREATE TRIGGER trg_dep_00_sem_delete BEFORE DELETE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dep');
CREATE TRIGGER trg_dep_00_sem_truncate BEFORE TRUNCATE ON organizacao.departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dep');
CREATE TRIGGER trg_dep_99_log AFTER UPDATE ON organizacao.departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dep');
ALTER TABLE organizacao.departamento ADD CONSTRAINT fk_dep_criado_por FOREIGN KEY (dep_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.departamento ADD CONSTRAINT fk_dep_modificado_por FOREIGN KEY (dep_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ide_00_padrao BEFORE INSERT OR UPDATE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ide', 'organizacao.igreja_departamento', 'ide_igr_id');
CREATE TRIGGER trg_ide_00_sem_delete BEFORE DELETE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ide');
CREATE TRIGGER trg_ide_00_sem_truncate BEFORE TRUNCATE ON organizacao.igreja_departamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ide');
CREATE TRIGGER trg_ide_99_log AFTER UPDATE ON organizacao.igreja_departamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ide');
ALTER TABLE organizacao.igreja_departamento ADD CONSTRAINT fk_ide_criado_por FOREIGN KEY (ide_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.igreja_departamento ADD CONSTRAINT fk_ide_modificado_por FOREIGN KEY (ide_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_car_00_padrao BEFORE INSERT OR UPDATE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('car', 'organizacao.cargo', '');
CREATE TRIGGER trg_car_00_sem_delete BEFORE DELETE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('car');
CREATE TRIGGER trg_car_00_sem_truncate BEFORE TRUNCATE ON organizacao.cargo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('car');
CREATE TRIGGER trg_car_99_log AFTER UPDATE ON organizacao.cargo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('car');
ALTER TABLE organizacao.cargo ADD CONSTRAINT fk_car_criado_por FOREIGN KEY (car_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE organizacao.cargo ADD CONSTRAINT fk_car_modificado_por FOREIGN KEY (car_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fam_00_padrao BEFORE INSERT OR UPDATE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fam', 'secretaria.familia', 'fam_igr_id');
CREATE TRIGGER trg_fam_00_sem_delete BEFORE DELETE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fam');
CREATE TRIGGER trg_fam_00_sem_truncate BEFORE TRUNCATE ON secretaria.familia FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fam');
CREATE TRIGGER trg_fam_99_log AFTER UPDATE ON secretaria.familia FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fam');
ALTER TABLE secretaria.familia ADD CONSTRAINT fk_fam_criado_por FOREIGN KEY (fam_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.familia ADD CONSTRAINT fk_fam_modificado_por FOREIGN KEY (fam_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mem_00_padrao BEFORE INSERT OR UPDATE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mem', 'secretaria.membro', 'mem_igr_id');
CREATE TRIGGER trg_mem_00_sem_delete BEFORE DELETE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mem');
CREATE TRIGGER trg_mem_00_sem_truncate BEFORE TRUNCATE ON secretaria.membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mem');
CREATE TRIGGER trg_mem_99_log AFTER UPDATE ON secretaria.membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mem');
ALTER TABLE secretaria.membro ADD CONSTRAINT fk_mem_criado_por FOREIGN KEY (mem_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.membro ADD CONSTRAINT fk_mem_modificado_por FOREIGN KEY (mem_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cto_00_padrao BEFORE INSERT OR UPDATE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cto', 'secretaria.contacto', '');
CREATE TRIGGER trg_cto_00_sem_delete BEFORE DELETE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cto');
CREATE TRIGGER trg_cto_00_sem_truncate BEFORE TRUNCATE ON secretaria.contacto FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cto');
CREATE TRIGGER trg_cto_99_log AFTER UPDATE ON secretaria.contacto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cto');
ALTER TABLE secretaria.contacto ADD CONSTRAINT fk_cto_criado_por FOREIGN KEY (cto_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.contacto ADD CONSTRAINT fk_cto_modificado_por FOREIGN KEY (cto_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cns_00_padrao BEFORE INSERT OR UPDATE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cns', 'secretaria.consentimento', '');
CREATE TRIGGER trg_cns_00_sem_delete BEFORE DELETE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cns');
CREATE TRIGGER trg_cns_00_sem_truncate BEFORE TRUNCATE ON secretaria.consentimento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cns');
CREATE TRIGGER trg_cns_99_log AFTER UPDATE ON secretaria.consentimento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cns');
ALTER TABLE secretaria.consentimento ADD CONSTRAINT fk_cns_criado_por FOREIGN KEY (cns_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.consentimento ADD CONSTRAINT fk_cns_modificado_por FOREIGN KEY (cns_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_reu_00_padrao BEFORE INSERT OR UPDATE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('reu', 'secretaria.reuniao', 'reu_igr_id');
CREATE TRIGGER trg_reu_00_sem_delete BEFORE DELETE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('reu');
CREATE TRIGGER trg_reu_00_sem_truncate BEFORE TRUNCATE ON secretaria.reuniao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('reu');
CREATE TRIGGER trg_reu_99_log AFTER UPDATE ON secretaria.reuniao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('reu');
ALTER TABLE secretaria.reuniao ADD CONSTRAINT fk_reu_criado_por FOREIGN KEY (reu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.reuniao ADD CONSTRAINT fk_reu_modificado_por FOREIGN KEY (reu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_vot_00_padrao BEFORE INSERT OR UPDATE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('vot', 'secretaria.voto', '');
CREATE TRIGGER trg_vot_00_sem_delete BEFORE DELETE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('vot');
CREATE TRIGGER trg_vot_00_sem_truncate BEFORE TRUNCATE ON secretaria.voto FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('vot');
CREATE TRIGGER trg_vot_99_log AFTER UPDATE ON secretaria.voto FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('vot');
ALTER TABLE secretaria.voto ADD CONSTRAINT fk_vot_criado_por FOREIGN KEY (vot_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.voto ADD CONSTRAINT fk_vot_modificado_por FOREIGN KEY (vot_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mmb_00_padrao BEFORE INSERT OR UPDATE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mmb', 'secretaria.movimento_membro', 'mmb_igr_id');
CREATE TRIGGER trg_mmb_00_sem_delete BEFORE DELETE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mmb');
CREATE TRIGGER trg_mmb_00_sem_truncate BEFORE TRUNCATE ON secretaria.movimento_membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mmb');
CREATE TRIGGER trg_mmb_99_log AFTER UPDATE ON secretaria.movimento_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mmb');
ALTER TABLE secretaria.movimento_membro ADD CONSTRAINT fk_mmb_criado_por FOREIGN KEY (mmb_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.movimento_membro ADD CONSTRAINT fk_mmb_modificado_por FOREIGN KEY (mmb_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tme_00_padrao BEFORE INSERT OR UPDATE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tme', 'secretaria.transferencia_membro', '');
CREATE TRIGGER trg_tme_00_sem_delete BEFORE DELETE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tme');
CREATE TRIGGER trg_tme_00_sem_truncate BEFORE TRUNCATE ON secretaria.transferencia_membro FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tme');
CREATE TRIGGER trg_tme_99_log AFTER UPDATE ON secretaria.transferencia_membro FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tme');
ALTER TABLE secretaria.transferencia_membro ADD CONSTRAINT fk_tme_criado_por FOREIGN KEY (tme_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.transferencia_membro ADD CONSTRAINT fk_tme_modificado_por FOREIGN KEY (tme_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_dsc_00_padrao BEFORE INSERT OR UPDATE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('dsc', 'secretaria.disciplina', '');
CREATE TRIGGER trg_dsc_00_sem_delete BEFORE DELETE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('dsc');
CREATE TRIGGER trg_dsc_00_sem_truncate BEFORE TRUNCATE ON secretaria.disciplina FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('dsc');
CREATE TRIGGER trg_dsc_99_log AFTER UPDATE ON secretaria.disciplina FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('dsc');
ALTER TABLE secretaria.disciplina ADD CONSTRAINT fk_dsc_criado_por FOREIGN KEY (dsc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.disciplina ADD CONSTRAINT fk_dsc_modificado_por FOREIGN KEY (dsc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ofi_00_padrao BEFORE INSERT OR UPDATE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ofi', 'secretaria.oficial', 'ofi_igr_id');
CREATE TRIGGER trg_ofi_00_sem_delete BEFORE DELETE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ofi');
CREATE TRIGGER trg_ofi_00_sem_truncate BEFORE TRUNCATE ON secretaria.oficial FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ofi');
CREATE TRIGGER trg_ofi_99_log AFTER UPDATE ON secretaria.oficial FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ofi');
ALTER TABLE secretaria.oficial ADD CONSTRAINT fk_ofi_criado_por FOREIGN KEY (ofi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.oficial ADD CONSTRAINT fk_ofi_modificado_por FOREIGN KEY (ofi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_bap_00_padrao BEFORE INSERT OR UPDATE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('bap', 'secretaria.baptismo', '');
CREATE TRIGGER trg_bap_00_sem_delete BEFORE DELETE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('bap');
CREATE TRIGGER trg_bap_00_sem_truncate BEFORE TRUNCATE ON secretaria.baptismo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('bap');
CREATE TRIGGER trg_bap_99_log AFTER UPDATE ON secretaria.baptismo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('bap');
ALTER TABLE secretaria.baptismo ADD CONSTRAINT fk_bap_criado_por FOREIGN KEY (bap_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE secretaria.baptismo ADD CONSTRAINT fk_bap_modificado_por FOREIGN KEY (bap_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_act_00_padrao BEFORE INSERT OR UPDATE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('act', 'actividades.actividade', '');
CREATE TRIGGER trg_act_00_sem_delete BEFORE DELETE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('act');
CREATE TRIGGER trg_act_00_sem_truncate BEFORE TRUNCATE ON actividades.actividade FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('act');
CREATE TRIGGER trg_act_99_log AFTER UPDATE ON actividades.actividade FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('act');
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_criado_por FOREIGN KEY (act_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.actividade ADD CONSTRAINT fk_act_modificado_por FOREIGN KEY (act_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mat_00_padrao BEFORE INSERT OR UPDATE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mat', 'actividades.material', '');
CREATE TRIGGER trg_mat_00_sem_delete BEFORE DELETE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mat');
CREATE TRIGGER trg_mat_00_sem_truncate BEFORE TRUNCATE ON actividades.material FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mat');
CREATE TRIGGER trg_mat_99_log AFTER UPDATE ON actividades.material FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mat');
ALTER TABLE actividades.material ADD CONSTRAINT fk_mat_criado_por FOREIGN KEY (mat_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.material ADD CONSTRAINT fk_mat_modificado_por FOREIGN KEY (mat_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_esc_00_padrao BEFORE INSERT OR UPDATE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('esc', 'actividades.escala', 'esc_igr_id');
CREATE TRIGGER trg_esc_00_sem_delete BEFORE DELETE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('esc');
CREATE TRIGGER trg_esc_00_sem_truncate BEFORE TRUNCATE ON actividades.escala FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('esc');
CREATE TRIGGER trg_esc_99_log AFTER UPDATE ON actividades.escala FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('esc');
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_criado_por FOREIGN KEY (esc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE actividades.escala ADD CONSTRAINT fk_esc_modificado_por FOREIGN KEY (esc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_etr_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('etr', 'escola_sabatina.trimestre', '');
CREATE TRIGGER trg_etr_00_sem_delete BEFORE DELETE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('etr');
CREATE TRIGGER trg_etr_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.trimestre FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('etr');
CREATE TRIGGER trg_etr_99_log AFTER UPDATE ON escola_sabatina.trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('etr');
ALTER TABLE escola_sabatina.trimestre ADD CONSTRAINT fk_etr_criado_por FOREIGN KEY (etr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.trimestre ADD CONSTRAINT fk_etr_modificado_por FOREIGN KEY (etr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_esa_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('esa', 'escola_sabatina.sabado', '');
CREATE TRIGGER trg_esa_00_sem_delete BEFORE DELETE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('esa');
CREATE TRIGGER trg_esa_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.sabado FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('esa');
CREATE TRIGGER trg_esa_99_log AFTER UPDATE ON escola_sabatina.sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('esa');
ALTER TABLE escola_sabatina.sabado ADD CONSTRAINT fk_esa_criado_por FOREIGN KEY (esa_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.sabado ADD CONSTRAINT fk_esa_modificado_por FOREIGN KEY (esa_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ecl_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ecl', 'escola_sabatina.classe', 'ecl_igr_id');
CREATE TRIGGER trg_ecl_00_sem_delete BEFORE DELETE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ecl');
CREATE TRIGGER trg_ecl_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.classe FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ecl');
CREATE TRIGGER trg_ecl_99_log AFTER UPDATE ON escola_sabatina.classe FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ecl');
ALTER TABLE escola_sabatina.classe ADD CONSTRAINT fk_ecl_criado_por FOREIGN KEY (ecl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.classe ADD CONSTRAINT fk_ecl_modificado_por FOREIGN KEY (ecl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ect_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ect', 'escola_sabatina.classe_trimestre', 'ect_igr_id');
CREATE TRIGGER trg_ect_00_sem_delete BEFORE DELETE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ect');
CREATE TRIGGER trg_ect_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.classe_trimestre FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ect');
CREATE TRIGGER trg_ect_99_log AFTER UPDATE ON escola_sabatina.classe_trimestre FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ect');
ALTER TABLE escola_sabatina.classe_trimestre ADD CONSTRAINT fk_ect_criado_por FOREIGN KEY (ect_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.classe_trimestre ADD CONSTRAINT fk_ect_modificado_por FOREIGN KEY (ect_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ema_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ema', 'escola_sabatina.matricula', '');
CREATE TRIGGER trg_ema_00_sem_delete BEFORE DELETE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ema');
CREATE TRIGGER trg_ema_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.matricula FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ema');
CREATE TRIGGER trg_ema_99_log AFTER UPDATE ON escola_sabatina.matricula FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ema');
ALTER TABLE escola_sabatina.matricula ADD CONSTRAINT fk_ema_criado_por FOREIGN KEY (ema_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.matricula ADD CONSTRAINT fk_ema_modificado_por FOREIGN KEY (ema_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ers_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ers', 'escola_sabatina.relatorio_sabado', 'ers_igr_id');
CREATE TRIGGER trg_ers_00_sem_delete BEFORE DELETE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ers');
CREATE TRIGGER trg_ers_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.relatorio_sabado FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ers');
CREATE TRIGGER trg_ers_99_log AFTER UPDATE ON escola_sabatina.relatorio_sabado FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ers');
ALTER TABLE escola_sabatina.relatorio_sabado ADD CONSTRAINT fk_ers_criado_por FOREIGN KEY (ers_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.relatorio_sabado ADD CONSTRAINT fk_ers_modificado_por FOREIGN KEY (ers_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_epr_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('epr', 'escola_sabatina.presenca', 'epr_igr_id');
CREATE TRIGGER trg_epr_00_sem_delete BEFORE DELETE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('epr');
CREATE TRIGGER trg_epr_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.presenca FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('epr');
CREATE TRIGGER trg_epr_99_log AFTER UPDATE ON escola_sabatina.presenca FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('epr');
ALTER TABLE escola_sabatina.presenca ADD CONSTRAINT fk_epr_criado_por FOREIGN KEY (epr_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.presenca ADD CONSTRAINT fk_epr_modificado_por FOREIGN KEY (epr_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_evi_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('evi', 'escola_sabatina.visitante', '');
CREATE TRIGGER trg_evi_00_sem_delete BEFORE DELETE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('evi');
CREATE TRIGGER trg_evi_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.visitante FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('evi');
CREATE TRIGGER trg_evi_99_log AFTER UPDATE ON escola_sabatina.visitante FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('evi');
ALTER TABLE escola_sabatina.visitante ADD CONSTRAINT fk_evi_criado_por FOREIGN KEY (evi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.visitante ADD CONSTRAINT fk_evi_modificado_por FOREIGN KEY (evi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_epc_00_padrao BEFORE INSERT OR UPDATE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('epc', 'escola_sabatina.pontuacao_config', '');
CREATE TRIGGER trg_epc_00_sem_delete BEFORE DELETE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('epc');
CREATE TRIGGER trg_epc_00_sem_truncate BEFORE TRUNCATE ON escola_sabatina.pontuacao_config FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('epc');
CREATE TRIGGER trg_epc_99_log AFTER UPDATE ON escola_sabatina.pontuacao_config FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('epc');
ALTER TABLE escola_sabatina.pontuacao_config ADD CONSTRAINT fk_epc_criado_por FOREIGN KEY (epc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE escola_sabatina.pontuacao_config ADD CONSTRAINT fk_epc_modificado_por FOREIGN KEY (epc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cfi_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cfi', 'tesouraria.conta_financeira', 'cfi_igr_id');
CREATE TRIGGER trg_cfi_00_sem_delete BEFORE DELETE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cfi');
CREATE TRIGGER trg_cfi_00_sem_truncate BEFORE TRUNCATE ON tesouraria.conta_financeira FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cfi');
CREATE TRIGGER trg_cfi_99_log AFTER UPDATE ON tesouraria.conta_financeira FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cfi');
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT fk_cfi_criado_por FOREIGN KEY (cfi_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.conta_financeira ADD CONSTRAINT fk_cfi_modificado_por FOREIGN KEY (cfi_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fun_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fun', 'tesouraria.fundo', '');
CREATE TRIGGER trg_fun_00_sem_delete BEFORE DELETE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fun');
CREATE TRIGGER trg_fun_00_sem_truncate BEFORE TRUNCATE ON tesouraria.fundo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fun');
CREATE TRIGGER trg_fun_99_log AFTER UPDATE ON tesouraria.fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fun');
ALTER TABLE tesouraria.fundo ADD CONSTRAINT fk_fun_criado_por FOREIGN KEY (fun_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.fundo ADD CONSTRAINT fk_fun_modificado_por FOREIGN KEY (fun_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cof_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cof', 'tesouraria.calendario_oferta', '');
CREATE TRIGGER trg_cof_00_sem_delete BEFORE DELETE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cof');
CREATE TRIGGER trg_cof_00_sem_truncate BEFORE TRUNCATE ON tesouraria.calendario_oferta FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cof');
CREATE TRIGGER trg_cof_99_log AFTER UPDATE ON tesouraria.calendario_oferta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cof');
ALTER TABLE tesouraria.calendario_oferta ADD CONSTRAINT fk_cof_criado_por FOREIGN KEY (cof_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.calendario_oferta ADD CONSTRAINT fk_cof_modificado_por FOREIGN KEY (cof_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cat_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cat', 'tesouraria.categoria', '');
CREATE TRIGGER trg_cat_00_sem_delete BEFORE DELETE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cat');
CREATE TRIGGER trg_cat_00_sem_truncate BEFORE TRUNCATE ON tesouraria.categoria FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cat');
CREATE TRIGGER trg_cat_99_log AFTER UPDATE ON tesouraria.categoria FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cat');
ALTER TABLE tesouraria.categoria ADD CONSTRAINT fk_cat_criado_por FOREIGN KEY (cat_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.categoria ADD CONSTRAINT fk_cat_modificado_por FOREIGN KEY (cat_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_alv_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('alv', 'tesouraria.alvo', 'alv_igr_id');
CREATE TRIGGER trg_alv_00_sem_delete BEFORE DELETE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('alv');
CREATE TRIGGER trg_alv_00_sem_truncate BEFORE TRUNCATE ON tesouraria.alvo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('alv');
CREATE TRIGGER trg_alv_99_log AFTER UPDATE ON tesouraria.alvo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('alv');
ALTER TABLE tesouraria.alvo ADD CONSTRAINT fk_alv_criado_por FOREIGN KEY (alv_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.alvo ADD CONSTRAINT fk_alv_modificado_por FOREIGN KEY (alv_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_orc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('orc', 'tesouraria.orcamento', 'orc_igr_id');
CREATE TRIGGER trg_orc_00_sem_delete BEFORE DELETE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('orc');
CREATE TRIGGER trg_orc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.orcamento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('orc');
CREATE TRIGGER trg_orc_99_log AFTER UPDATE ON tesouraria.orcamento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('orc');
ALTER TABLE tesouraria.orcamento ADD CONSTRAINT fk_orc_criado_por FOREIGN KEY (orc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.orcamento ADD CONSTRAINT fk_orc_modificado_por FOREIGN KEY (orc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_orl_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('orl', 'tesouraria.orcamento_linha', '');
CREATE TRIGGER trg_orl_00_sem_delete BEFORE DELETE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('orl');
CREATE TRIGGER trg_orl_00_sem_truncate BEFORE TRUNCATE ON tesouraria.orcamento_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('orl');
CREATE TRIGGER trg_orl_99_log AFTER UPDATE ON tesouraria.orcamento_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('orl');
ALTER TABLE tesouraria.orcamento_linha ADD CONSTRAINT fk_orl_criado_por FOREIGN KEY (orl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.orcamento_linha ADD CONSTRAINT fk_orl_modificado_por FOREIGN KEY (orl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_des_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('des', 'tesouraria.despesa', 'des_igr_id');
CREATE TRIGGER trg_des_00_sem_delete BEFORE DELETE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('des');
CREATE TRIGGER trg_des_00_sem_truncate BEFORE TRUNCATE ON tesouraria.despesa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('des');
CREATE TRIGGER trg_des_99_log AFTER UPDATE ON tesouraria.despesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('des');
ALTER TABLE tesouraria.despesa ADD CONSTRAINT fk_des_criado_por FOREIGN KEY (des_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.despesa ADD CONSTRAINT fk_des_modificado_por FOREIGN KEY (des_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_cnu_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('cnu', 'tesouraria.contagem_numerario', 'cnu_igr_id');
CREATE TRIGGER trg_cnu_00_sem_delete BEFORE DELETE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('cnu');
CREATE TRIGGER trg_cnu_00_sem_truncate BEFORE TRUNCATE ON tesouraria.contagem_numerario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('cnu');
CREATE TRIGGER trg_cnu_99_log AFTER UPDATE ON tesouraria.contagem_numerario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('cnu');
ALTER TABLE tesouraria.contagem_numerario ADD CONSTRAINT fk_cnu_criado_por FOREIGN KEY (cnu_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.contagem_numerario ADD CONSTRAINT fk_cnu_modificado_por FOREIGN KEY (cnu_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tra_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tra', 'tesouraria.transacao', 'tra_igr_id');
CREATE TRIGGER trg_tra_00_sem_delete BEFORE DELETE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tra');
CREATE TRIGGER trg_tra_00_sem_truncate BEFORE TRUNCATE ON tesouraria.transacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tra');
CREATE TRIGGER trg_tra_99_log AFTER UPDATE ON tesouraria.transacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tra');
ALTER TABLE tesouraria.transacao ADD CONSTRAINT fk_tra_criado_por FOREIGN KEY (tra_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.transacao ADD CONSTRAINT fk_tra_modificado_por FOREIGN KEY (tra_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_tli_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('tli', 'tesouraria.transacao_linha', 'tli_igr_id');
CREATE TRIGGER trg_tli_00_sem_delete BEFORE DELETE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('tli');
CREATE TRIGGER trg_tli_00_sem_truncate BEFORE TRUNCATE ON tesouraria.transacao_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('tli');
CREATE TRIGGER trg_tli_99_log AFTER UPDATE ON tesouraria.transacao_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('tli');
ALTER TABLE tesouraria.transacao_linha ADD CONSTRAINT fk_tli_criado_por FOREIGN KEY (tli_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.transacao_linha ADD CONSTRAINT fk_tli_modificado_por FOREIGN KEY (tli_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_sdc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.saldo_diario_conta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('sdc', '', 'sdc_igr_id');
CREATE TRIGGER trg_sdc_00_sem_delete BEFORE DELETE ON tesouraria.saldo_diario_conta FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('sdc');
CREATE TRIGGER trg_sdc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.saldo_diario_conta FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('sdc');
ALTER TABLE tesouraria.saldo_diario_conta ADD CONSTRAINT fk_sdc_criado_por FOREIGN KEY (sdc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.saldo_diario_conta ADD CONSTRAINT fk_sdc_modificado_por FOREIGN KEY (sdc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_sdf_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.saldo_diario_fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('sdf', '', 'sdf_igr_id');
CREATE TRIGGER trg_sdf_00_sem_delete BEFORE DELETE ON tesouraria.saldo_diario_fundo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('sdf');
CREATE TRIGGER trg_sdf_00_sem_truncate BEFORE TRUNCATE ON tesouraria.saldo_diario_fundo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('sdf');
ALTER TABLE tesouraria.saldo_diario_fundo ADD CONSTRAINT fk_sdf_criado_por FOREIGN KEY (sdf_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.saldo_diario_fundo ADD CONSTRAINT fk_sdf_modificado_por FOREIGN KEY (sdf_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rec_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rec', 'tesouraria.recibo', 'rec_igr_id');
CREATE TRIGGER trg_rec_00_sem_delete BEFORE DELETE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rec');
CREATE TRIGGER trg_rec_00_sem_truncate BEFORE TRUNCATE ON tesouraria.recibo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rec');
CREATE TRIGGER trg_rec_99_log AFTER UPDATE ON tesouraria.recibo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rec');
ALTER TABLE tesouraria.recibo ADD CONSTRAINT fk_rec_criado_por FOREIGN KEY (rec_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.recibo ADD CONSTRAINT fk_rec_modificado_por FOREIGN KEY (rec_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_doc_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('doc', 'tesouraria.documento', '');
CREATE TRIGGER trg_doc_00_sem_delete BEFORE DELETE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('doc');
CREATE TRIGGER trg_doc_00_sem_truncate BEFORE TRUNCATE ON tesouraria.documento FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('doc');
CREATE TRIGGER trg_doc_99_log AFTER UPDATE ON tesouraria.documento FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('doc');
ALTER TABLE tesouraria.documento ADD CONSTRAINT fk_doc_criado_por FOREIGN KEY (doc_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.documento ADD CONSTRAINT fk_doc_modificado_por FOREIGN KEY (doc_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rem_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rem', 'tesouraria.remessa', 'rem_igr_id');
CREATE TRIGGER trg_rem_00_sem_delete BEFORE DELETE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rem');
CREATE TRIGGER trg_rem_00_sem_truncate BEFORE TRUNCATE ON tesouraria.remessa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rem');
CREATE TRIGGER trg_rem_99_log AFTER UPDATE ON tesouraria.remessa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rem');
ALTER TABLE tesouraria.remessa ADD CONSTRAINT fk_rem_criado_por FOREIGN KEY (rem_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.remessa ADD CONSTRAINT fk_rem_modificado_por FOREIGN KEY (rem_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_rml_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('rml', 'tesouraria.remessa_linha', '');
CREATE TRIGGER trg_rml_00_sem_delete BEFORE DELETE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('rml');
CREATE TRIGGER trg_rml_00_sem_truncate BEFORE TRUNCATE ON tesouraria.remessa_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('rml');
CREATE TRIGGER trg_rml_99_log AFTER UPDATE ON tesouraria.remessa_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('rml');
ALTER TABLE tesouraria.remessa_linha ADD CONSTRAINT fk_rml_criado_por FOREIGN KEY (rml_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.remessa_linha ADD CONSTRAINT fk_rml_modificado_por FOREIGN KEY (rml_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_fpe_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('fpe', 'tesouraria.fecho_periodo', 'fpe_igr_id');
CREATE TRIGGER trg_fpe_00_sem_delete BEFORE DELETE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('fpe');
CREATE TRIGGER trg_fpe_00_sem_truncate BEFORE TRUNCATE ON tesouraria.fecho_periodo FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('fpe');
CREATE TRIGGER trg_fpe_99_log AFTER UPDATE ON tesouraria.fecho_periodo FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('fpe');
ALTER TABLE tesouraria.fecho_periodo ADD CONSTRAINT fk_fpe_criado_por FOREIGN KEY (fpe_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.fecho_periodo ADD CONSTRAINT fk_fpe_modificado_por FOREIGN KEY (fpe_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ext_00_padrao BEFORE INSERT OR UPDATE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ext', 'tesouraria.extrato_linha', '');
CREATE TRIGGER trg_ext_00_sem_delete BEFORE DELETE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ext');
CREATE TRIGGER trg_ext_00_sem_truncate BEFORE TRUNCATE ON tesouraria.extrato_linha FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ext');
CREATE TRIGGER trg_ext_99_log AFTER UPDATE ON tesouraria.extrato_linha FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ext');
ALTER TABLE tesouraria.extrato_linha ADD CONSTRAINT fk_ext_criado_por FOREIGN KEY (ext_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE tesouraria.extrato_linha ADD CONSTRAINT fk_ext_modificado_por FOREIGN KEY (ext_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_pmp_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pmp', 'pagamentos.pagamento_mpesa', '');
CREATE TRIGGER trg_pmp_00_sem_delete BEFORE DELETE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pmp');
CREATE TRIGGER trg_pmp_00_sem_truncate BEFORE TRUNCATE ON pagamentos.pagamento_mpesa FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pmp');
CREATE TRIGGER trg_pmp_99_log AFTER UPDATE ON pagamentos.pagamento_mpesa FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pmp');
ALTER TABLE pagamentos.pagamento_mpesa ADD CONSTRAINT fk_pmp_criado_por FOREIGN KEY (pmp_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.pagamento_mpesa ADD CONSTRAINT fk_pmp_modificado_por FOREIGN KEY (pmp_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_mcl_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('mcl', 'pagamentos.mpesa_callback_log', '');
CREATE TRIGGER trg_mcl_00_sem_delete BEFORE DELETE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('mcl');
CREATE TRIGGER trg_mcl_00_sem_truncate BEFORE TRUNCATE ON pagamentos.mpesa_callback_log FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('mcl');
CREATE TRIGGER trg_mcl_99_log AFTER UPDATE ON pagamentos.mpesa_callback_log FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('mcl');
ALTER TABLE pagamentos.mpesa_callback_log ADD CONSTRAINT fk_mcl_criado_por FOREIGN KEY (mcl_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.mpesa_callback_log ADD CONSTRAINT fk_mcl_modificado_por FOREIGN KEY (mcl_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_pba_00_padrao BEFORE INSERT OR UPDATE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('pba', 'pagamentos.pagamento_bancario', '');
CREATE TRIGGER trg_pba_00_sem_delete BEFORE DELETE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('pba');
CREATE TRIGGER trg_pba_00_sem_truncate BEFORE TRUNCATE ON pagamentos.pagamento_bancario FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('pba');
CREATE TRIGGER trg_pba_99_log AFTER UPDATE ON pagamentos.pagamento_bancario FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('pba');
ALTER TABLE pagamentos.pagamento_bancario ADD CONSTRAINT fk_pba_criado_por FOREIGN KEY (pba_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE pagamentos.pagamento_bancario ADD CONSTRAINT fk_pba_modificado_por FOREIGN KEY (pba_modificado_por) REFERENCES nucleo.usuario(usu_id);

CREATE TRIGGER trg_ntf_00_padrao BEFORE INSERT OR UPDATE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_campos_padrao('ntf', 'comunicacao.notificacao', 'ntf_igr_id');
CREATE TRIGGER trg_ntf_00_sem_delete BEFORE DELETE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_proibir_delete('ntf');
CREATE TRIGGER trg_ntf_00_sem_truncate BEFORE TRUNCATE ON comunicacao.notificacao FOR EACH STATEMENT EXECUTE FUNCTION nucleo.fn_proibir_delete('ntf');
CREATE TRIGGER trg_ntf_99_log AFTER UPDATE ON comunicacao.notificacao FOR EACH ROW EXECUTE FUNCTION nucleo.fn_log_auditoria('ntf');
ALTER TABLE comunicacao.notificacao ADD CONSTRAINT fk_ntf_criado_por FOREIGN KEY (ntf_criado_por) REFERENCES nucleo.usuario(usu_id);
ALTER TABLE comunicacao.notificacao ADD CONSTRAINT fk_ntf_modificado_por FOREIGN KEY (ntf_modificado_por) REFERENCES nucleo.usuario(usu_id);

-- Todas as funções do sistema resolvem nomes sempre da mesma forma, seja quem for que as chama
DO $$
DECLARE f RECORD;
BEGIN
    FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'pagamentos', 'comunicacao') LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public', f.sig);
    END LOOP;
    -- As funções de trigger validam com os privilégios do sistema (vêem todos os dados de que
    -- precisam para decidir); quem pode fazer o quê decide-se sempre pelo utilizador da sessão
    -- (políticas RLS da operação original e nucleo.fn_exigir).
    FOR f IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria', 'pagamentos', 'comunicacao')
               AND p.prorettype = 'trigger'::regtype LOOP
        EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER', f.sig);
    END LOOP;
END $$;

SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;
SELECT set_config('app.usuario_id','1',false);
INSERT INTO igreja (igr_id, igr_ent_id, igr_nome) SELECT g, 1, 'Igreja ' || g FROM generate_series(10, 309) g;
SELECT setval(pg_get_serial_sequence('secretaria.membro','mem_id'), 1000);
INSERT INTO membro (mem_igr_id, mem_nome, mem_apelido, mem_estado) SELECT i, 'Nome' || m, 'Apelido' || i, 'ACTIVO' FROM generate_series(10, 309) i, generate_series(1,150) m;
-- 300 igrejas, 150 membros cada, 3 contas cada
SELECT setval(pg_get_serial_sequence('tesouraria.conta_financeira','cfi_id'), 100);
INSERT INTO conta_financeira (cfi_igr_id, cfi_tipo, cfi_nome, cfi_data_saldo_inicial) SELECT i, t::tipo_conta_t, t, '2024-01-01' FROM generate_series(10,309) i, unnest(ARRAY['MPESA','CAIXA','BANCO']) t;
SELECT setval(pg_get_serial_sequence('nucleo.usuario','usu_id'), 100);
INSERT INTO usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES (50, 'Tesoureiro igreja 150', 'carga@x', 'h');
INSERT INTO usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id) VALUES (50, 150, (SELECT per_id FROM perfil WHERE per_nome='TESOUREIRO'));

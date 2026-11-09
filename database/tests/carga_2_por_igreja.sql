SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;
SELECT set_config('app.usuario_id','1',false) \g /dev/null
BEGIN;
CREATE TEMP TABLE novos ON COMMIT DROP AS
SELECT nextval(pg_get_serial_sequence('tesouraria.transacao','tra_id')) AS id, g,
       (SELECT cfi_id FROM conta_financeira WHERE cfi_igr_id = :igr AND cfi_tipo = 'MPESA') AS cfi,
       (SELECT min(mem_id) FROM membro WHERE mem_igr_id = :igr) + (g % 150) AS mem,
       (100 + (g * 37) % 2000)::numeric AS total,
       timestamptz '2024-01-06 10:00+02' + (g % 730) * interval '1 day' AS quando
FROM generate_series(1, :n) g;
INSERT INTO transacao (tra_id, tra_tipo, tra_metodo, tra_estado, tra_valor_total, tra_cfi_id, tra_mem_id, tra_data_hora)
SELECT id, 'ENTRADA', 'MPESA', 'CONFIRMADA', total, cfi, mem, quando FROM novos;
INSERT INTO transacao_linha (tli_tra_id, tli_fun_id, tli_cat_id, tli_valor)
SELECT id, :diz, 1, round(total * 0.8, 2) FROM novos
UNION ALL SELECT id, :oloc, 2, total - round(total * 0.8, 2) FROM novos;
COMMIT;

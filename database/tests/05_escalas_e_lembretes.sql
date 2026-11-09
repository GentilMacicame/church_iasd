\set ON_ERROR_STOP 0
\set VERBOSITY terse
SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, public;

-- dados (como administrador): três membros da escala de pregação, um secretário e um membro sem perfil
INSERT INTO secretaria.membro (mem_id, mem_igr_id, mem_nome, mem_apelido) VALUES
  (900, 1, 'Elisa', 'Fumo'), (901, 1, 'Teresa', 'Chichongue'), (902, 1, 'Gabriel', 'Langa');
INSERT INTO secretaria.contacto (cto_mem_id, cto_tipo, cto_valor, cto_principal) VALUES
  (900, 'TELEFONE', '+258841110000', true), (901, 'TELEFONE', '+258842220000', true);
-- só a Elisa deu consentimento para SMS; o Gabriel não tem telefone
INSERT INTO secretaria.consentimento (cns_mem_id, cns_tipo, cns_concedido) VALUES (900, 'CONTACTO_SMS', true);
INSERT INTO nucleo.usuario (usu_id, usu_nome, usu_email, usu_senha_hash) VALUES
  (950, 'Secretário', 'sec.escala@x', 'h'), (951, 'Gabriel Langa', 'gabriel@x', 'h');
UPDATE nucleo.usuario SET usu_mem_id = 902 WHERE usu_id = 951;
INSERT INTO nucleo.usuario_igreja (uig_usu_id, uig_igr_id, uig_per_id)
  SELECT 950, 1, per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO';

SET ROLE app_igreja;

\echo '1. o secretário elabora a escala do IV trimestre e gera os sábados'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
INSERT INTO actividades.escala_plano (epl_id, epl_igr_id, epl_titulo, epl_data_inicio, epl_data_fim, epl_local_emissao,
                                      epl_secretario_mem_id)
VALUES (1, 1, 'Escala de Pregação', '2026-10-01', '2026-12-31', 'Matola', 902);
SELECT actividades.fn_gerar_dias_escala(1) AS sabados_criados;
SELECT actividades.fn_gerar_dias_escala(1) AS criados_de_novo;
UPDATE actividades.escala_dia SET eds_evento = 'Simpósio da Teologia' WHERE eds_epl_id = 1 AND eds_data = '2026-10-31';
UPDATE actividades.escala_dia SET eds_grupo_coral = 'MA' WHERE eds_epl_id = 1 AND eds_data = '2026-10-17';

\echo '2. dia fora do período da escala: recusado'
INSERT INTO actividades.escala_dia (eds_epl_id, eds_data) VALUES (1, '2027-01-02');

\echo '3. pregador, tradutor e acompanhante do dia 17/10: a data e a igreja vêm do dia'
INSERT INTO actividades.escala (esc_eds_id, esc_funcao, esc_mem_id)
SELECT d.eds_id, f.funcao::nucleo.funcao_escala_t, f.mem
FROM actividades.escala_dia d, (VALUES ('PREGADOR', 900), ('TRADUTOR', 901), ('ACOMPANHANTE_VISITAS', 902)) f(funcao, mem)
WHERE d.eds_epl_id = 1 AND d.eds_data = '2026-10-17';
SELECT esc_funcao, esc_mem_id, to_char(esc_data, 'DD/MM/YYYY') AS data, esc_igr_id
  FROM actividades.escala WHERE esc_eds_id IS NOT NULL ORDER BY esc_mem_id;

\echo '4. o tesoureiro não elabora escalas nem vê a escala por publicar'
SELECT set_config('app.usuario_id', '2', false) \g /dev/null
INSERT INTO actividades.escala_plano (epl_igr_id, epl_titulo, epl_data_inicio, epl_data_fim)
VALUES (1, 'Outra', '2026-10-01', '2026-12-31');
SELECT count(*) AS planos_visiveis FROM actividades.escala_plano;

\echo '5. o membro (sem perfil) não vê a escala por publicar nem pode escalar ninguém'
SELECT set_config('app.usuario_id', '951', false) \g /dev/null
SELECT count(*) AS dias_visiveis FROM actividades.vw_escala_grelha WHERE plano_id = 1;
INSERT INTO actividades.escala (esc_igr_id, esc_data, esc_funcao, esc_mem_id) VALUES (1, '2026-10-24', 'PREGADOR', 902);

\echo '6. escala por publicar: na quarta não há lembretes'
SELECT actividades.fn_lembretes_escala('2026-10-14 10:00+02') AS lembretes;

\echo '7. o secretário publica: o membro vê a escala com os nomes, como no papel afixado'
SELECT set_config('app.usuario_id', '950', false) \g /dev/null
UPDATE actividades.escala_plano SET epl_publicada = true WHERE epl_id = 1;
SELECT set_config('app.usuario_id', '951', false) \g /dev/null
SELECT to_char(data, 'DD/MM') AS data, evento, pregador, tradutor, acompanhante_visitas, grupo_coral
  FROM actividades.vw_escala_grelha WHERE plano_id = 1 AND data IN ('2026-10-17', '2026-10-31') ORDER BY data;
SELECT count(*) AS escalas_que_o_membro_ve FROM actividades.escala WHERE esc_eds_id IS NOT NULL;

\echo '8. lembretes: quarta e sexta, uma vez por dia, só a quem tem telefone e consentimento'
SELECT actividades.fn_lembretes_escala('2026-10-14 10:00+02') AS quarta;
SELECT actividades.fn_lembretes_escala('2026-10-14 15:00+02') AS quarta_de_novo;
SELECT actividades.fn_lembretes_escala('2026-10-15 10:00+02') AS quinta;
SELECT actividades.fn_lembretes_escala('2026-10-16 21:00+02') AS sexta_depois_das_20h;
SELECT actividades.fn_lembretes_escala('2026-10-16 09:00+02') AS sexta;
RESET ROLE;
SELECT ntf_destino, ntf_mensagem, to_char(ntf_agendada_para AT TIME ZONE 'Africa/Maputo', 'DD/MM HH24:MI') AS envio, ntf_estado
  FROM nucleo.notificacao WHERE ntf_origem_tabela = 'actividades.escala' ORDER BY ntf_id;

\echo '9. envio: a fila reserva cada SMS uma vez; enviado → ENVIADA; erro → volta a tentar'
SET ROLE app_igreja;
SELECT count(*) > 0 AS reservou FROM nucleo.fn_notificacoes_reservar(100);
SELECT count(*) AS reservadas_de_novo FROM nucleo.fn_notificacoes_reservar(100);
RESET ROLE;
SELECT min(ntf_id) AS sms_quarta, max(ntf_id) AS sms_sexta FROM nucleo.notificacao
 WHERE ntf_origem_tabela = 'actividades.escala' \gset
SET ROLE app_igreja;
SELECT nucleo.fn_notificacao_resultado(:sms_quarta, true) \g /dev/null
SELECT nucleo.fn_notificacao_resultado(:sms_sexta, false, 'operadora indisponível') \g /dev/null
RESET ROLE;
SELECT right(ntf_chave, 10) AS dia, ntf_estado, ntf_tentativas, ntf_erro, ntf_enviada_em IS NOT NULL AS enviada
  FROM nucleo.notificacao WHERE ntf_origem_tabela = 'actividades.escala' ORDER BY ntf_id;

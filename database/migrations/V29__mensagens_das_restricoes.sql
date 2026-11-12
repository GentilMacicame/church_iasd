-- V29 · Mensagens das restrições em português
--
-- Até aqui uma recusa por CHECK ou por único chegava ao utilizador como "Valor não permitido (chk_ers_numeros)"
-- ou "Já existe um registo com estes dados". Agora cada restrição tem a frase no seu COMMENT, e a API lê-as no
-- arranque (nucleo.fn_mensagens_restricoes) para responder com ela. A base de dados continua a decidir; passa a
-- explicar também. Quem acrescentar uma restrição deve acrescentar o COMMENT.
--
-- Formato do comentário: "[campoJson] Mensagem" (o campo é opcional; com ele o erro aparece junto ao campo).
-- Os CHECK genéricos "<pfx>_end_date >= <pfx>_criado_em" têm uma frase comum na API.

-- ---------------------------------------------------------------- função lida pela API no arranque
CREATE FUNCTION nucleo.fn_mensagens_restricoes()
RETURNS TABLE (nome TEXT, mensagem TEXT)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = pg_catalog AS $$
    SELECT c.conname::text, d.description
      FROM pg_constraint c
      JOIN pg_namespace n ON n.oid = c.connamespace
      JOIN pg_description d ON d.objoid = c.oid AND d.classoid = 'pg_constraint'::regclass
     WHERE n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
    UNION
    SELECT i.relname::text, d.description
      FROM pg_index x
      JOIN pg_class i ON i.oid = x.indexrelid
      JOIN pg_namespace n ON n.oid = i.relnamespace
      JOIN pg_description d ON d.objoid = i.oid AND d.classoid = 'pg_class'::regclass
     WHERE x.indisunique
       AND n.nspname IN ('nucleo', 'organizacao', 'secretaria', 'actividades', 'escola_sabatina', 'tesouraria')
$$;
COMMENT ON FUNCTION nucleo.fn_mensagens_restricoes() IS
    'Frase em português de cada restrição (COMMENT ON CONSTRAINT / INDEX), lida pela API para traduzir os erros 23514 e 23505';
REVOKE ALL ON FUNCTION nucleo.fn_mensagens_restricoes() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION nucleo.fn_mensagens_restricoes() TO app_igreja;

-- ---------------------------------------------------------------- Escola Sabatina
COMMENT ON CONSTRAINT chk_ers_numeros ON escola_sabatina.relatorio_sabado IS
    'Os números do relatório não batem: os presentes não podem ser mais do que os matriculados, quem estudou a lição não pode ser mais do que os presentes, e visitantes e filiais não podem ser negativos.';
COMMENT ON CONSTRAINT chk_ers_ofertas ON escola_sabatina.relatorio_sabado IS
    'As ofertas não podem ser negativas.';
COMMENT ON CONSTRAINT chk_epr_estudo ON escola_sabatina.presenca IS
    'Só quem esteve presente pode ser marcado como tendo estudado a lição.';
COMMENT ON CONSTRAINT chk_ect_alvos ON escola_sabatina.classe_trimestre IS
    'Os alvos não podem ser negativos e o alvo de estudo diário tem de estar entre 0% e 100%.';
COMMENT ON CONSTRAINT chk_ema_datas ON escola_sabatina.matricula IS
    '[dataSaida] A data de saída da classe não pode ser anterior à data de entrada.';
COMMENT ON CONSTRAINT chk_epc_soma ON escola_sabatina.pontuacao_config IS
    'Os quatro pesos da pontuação (presença, estudo, ofertas e visitantes) têm de somar 100%.';
COMMENT ON CONSTRAINT chk_epc_limite ON escola_sabatina.pontuacao_config IS
    '[limiteOfertas] O limite das ofertas tem de ser pelo menos 100% do alvo.';
COMMENT ON CONSTRAINT chk_esa_numero ON escola_sabatina.sabado IS
    '[numero] O número do sábado tem de estar entre 1 e 14.';
COMMENT ON CONSTRAINT chk_esa_sabado ON escola_sabatina.sabado IS
    '[data] A data indicada não é um sábado.';
COMMENT ON CONSTRAINT chk_etr_datas ON escola_sabatina.trimestre IS
    '[dataFim] O fim do trimestre tem de ser depois do início.';
COMMENT ON CONSTRAINT chk_etr_numero ON escola_sabatina.trimestre IS
    '[numero] O trimestre tem de ser o 1.º, 2.º, 3.º ou 4.º.';
COMMENT ON CONSTRAINT chk_etr_sabados ON escola_sabatina.trimestre IS
    'Um trimestre tem 13 ou 14 sábados; confirme as datas de início e de fim.';

COMMENT ON INDEX escola_sabatina.uq_ecl_igr_id_nome IS '[nome] Já existe uma classe com este nome nesta igreja.';
COMMENT ON INDEX escola_sabatina.uq_ect_ecl_id_etr_id IS 'Esta classe já está configurada para este trimestre.';
COMMENT ON INDEX escola_sabatina.uq_ema_activa IS '[membroId] Este membro já está matriculado noutra classe; tire-o primeiro dessa classe.';
COMMENT ON INDEX escola_sabatina.uq_epc_defeito IS 'Já existem pesos por defeito; altere-os em vez de criar outros.';
COMMENT ON INDEX escola_sabatina.uq_epc_trimestre IS 'Este trimestre já tem pesos próprios; altere-os em vez de criar outros.';
COMMENT ON INDEX escola_sabatina.uq_epr_ers_id_mem_id IS '[membroId] Este membro já está na chamada deste relatório.';
COMMENT ON INDEX escola_sabatina.uq_ers_ect_id_esa_id IS 'Esta classe já tem relatório neste sábado.';
COMMENT ON INDEX escola_sabatina.uq_esa_13 IS 'Este trimestre já tem um 13.º sábado marcado; desmarque-o primeiro.';
COMMENT ON INDEX escola_sabatina.uq_esa_data IS '[data] Já existe um sábado com esta data.';
COMMENT ON INDEX escola_sabatina.uq_esa_etr_id_numero IS '[numero] Este trimestre já tem um sábado com este número.';
COMMENT ON INDEX escola_sabatina.uq_etr_ano_numero IS 'Este trimestre já existe para esse ano.';

-- ---------------------------------------------------------------- Tesouraria
COMMENT ON CONSTRAINT chk_alv ON tesouraria.alvo IS 'O valor do alvo tem de ser maior que zero e o fim não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_cnu_contadores_diferentes ON tesouraria.contagem_numerario IS
    '[contador2MembroId] A contagem exige dois contadores diferentes.';
COMMENT ON CONSTRAINT chk_cnu_partes ON tesouraria.contagem_numerario IS
    'As partes da contagem (dízimos, ofertas, Escola Sabatina, outras) têm de somar o total contado.';
COMMENT ON CONSTRAINT chk_cnu_total ON tesouraria.contagem_numerario IS '[totalContado] O total contado não pode ser negativo.';
COMMENT ON CONSTRAINT chk_des_aprovacao ON tesouraria.despesa IS 'Uma despesa aprovada ou paga tem de ter quem a aprovou e o valor aprovado.';
COMMENT ON CONSTRAINT chk_des_quem_pede_nao_aprova ON tesouraria.despesa IS 'Quem pede a despesa não a pode aprovar.';
COMMENT ON CONSTRAINT chk_des_rejeicao ON tesouraria.despesa IS '[motivoRejeicao] Para rejeitar a despesa, indique o motivo.';
COMMENT ON CONSTRAINT chk_des_valores ON tesouraria.despesa IS 'Os valores da despesa têm de ser maiores que zero e o aprovado não pode passar o pedido.';
COMMENT ON CONSTRAINT chk_doc_dono ON tesouraria.documento IS 'O comprovativo tem de estar ligado a um movimento ou a uma despesa.';
COMMENT ON CONSTRAINT chk_fpe_mes ON tesouraria.fecho_periodo IS '[mes] O mês tem de estar entre 1 e 12.';
COMMENT ON CONSTRAINT chk_fun_associacao ON tesouraria.fundo IS 'Dízimo, oferta missionária e ofertas da Escola Sabatina para as missões são fundos da Associação, não da igreja.';
COMMENT ON CONSTRAINT chk_fun_da_igreja ON tesouraria.fundo IS 'Um fundo próprio da igreja fica 100% na igreja: não tem parte da Missão nem destino.';
COMMENT ON CONSTRAINT chk_fun_local ON tesouraria.fundo IS 'Este tipo de fundo só pode ser da igreja.';
COMMENT ON CONSTRAINT chk_fun_remessa ON tesouraria.fundo IS '[percentagemRemessa] A parte da Missão tem de estar entre 0% e 100%.';
COMMENT ON CONSTRAINT chk_orc_aprovado ON tesouraria.orcamento IS 'Para aprovar o orçamento é preciso o voto da igreja.';
COMMENT ON CONSTRAINT chk_orl_valor ON tesouraria.orcamento_linha IS '[valorPrevisto] O valor previsto não pode ser negativo.';
COMMENT ON CONSTRAINT chk_pmp_direccao ON tesouraria.pagamento_mpesa IS 'Direcção do pagamento M-Pesa inválida.';
COMMENT ON CONSTRAINT chk_rem_mes ON tesouraria.remessa IS '[mes] O mês tem de estar entre 1 e 12.';
COMMENT ON CONSTRAINT chk_rml_valor ON tesouraria.remessa_linha IS '[valor] O valor não pode ser negativo.';
COMMENT ON CONSTRAINT chk_tli_valor ON tesouraria.transacao_linha IS '[valor] Cada linha tem de ter um valor maior que zero.';
COMMENT ON CONSTRAINT chk_tra_anonimo ON tesouraria.transacao IS 'Uma contribuição anónima não pode ter membro nem família.';
COMMENT ON CONSTRAINT chk_tra_contagem ON tesouraria.transacao IS 'Só uma entrada em numerário pode ficar ligada a uma contagem.';
COMMENT ON CONSTRAINT chk_tra_despesa ON tesouraria.transacao IS 'Só uma saída pode pagar uma despesa.';
COMMENT ON CONSTRAINT chk_tra_quem_regista_nao_aprova ON tesouraria.transacao IS 'Quem regista o movimento não o pode aprovar; tem de ser outra pessoa.';
COMMENT ON CONSTRAINT chk_tra_transferencia ON tesouraria.transacao IS 'Uma transferência precisa da conta de destino, diferente da de origem.';
COMMENT ON CONSTRAINT chk_tra_valor ON tesouraria.transacao IS '[valorTotal] O valor tem de ser maior que zero.';

COMMENT ON INDEX tesouraria.uq_cat_codigo IS '[codigo] Já existe uma categoria com este código.';
COMMENT ON INDEX tesouraria.uq_cfi_igr_id_nome IS '[nome] Já existe uma conta com este nome nesta igreja.';
COMMENT ON INDEX tesouraria.uq_fpe_igr_id_ano_mes IS 'Este mês já foi fechado.';
COMMENT ON INDEX tesouraria.uq_fun_codigo IS '[codigo] Já existe um fundo com este código.';
COMMENT ON INDEX tesouraria.uq_orc IS 'Já existe um orçamento para este ano.';
COMMENT ON INDEX tesouraria.uq_orl_orc_id_cat_id IS '[categoriaId] Esta categoria já está no orçamento.';
COMMENT ON INDEX tesouraria.uq_rec_tra_id IS 'Este movimento já tem recibo.';
COMMENT ON INDEX tesouraria.uq_rem_preparada IS 'Já existe um depósito à Missão por enviar para este mês.';
COMMENT ON INDEX tesouraria.uq_rml_rem_id_fun_id IS '[fundoId] Este fundo já está neste depósito.';
COMMENT ON INDEX tesouraria.uq_ext_cfi_id_data_referencia_valor IS 'Esta linha do extracto já foi importada.';

-- ---------------------------------------------------------------- Secretaria
COMMENT ON CONSTRAINT chk_cto_dono ON secretaria.contacto IS 'O contacto tem de ser de um membro ou da igreja (não dos dois).';
COMMENT ON CONSTRAINT chk_dsc_duracao ON secretaria.disciplina IS '[dataFim] A censura dura de 1 dia a 12 meses: o fim tem de ser depois do início e até um ano depois.';
COMMENT ON CONSTRAINT chk_mem_encarregado ON secretaria.membro IS '[encarregadoMembroId] O membro não pode ser o seu próprio encarregado de educação.';
COMMENT ON CONSTRAINT chk_mmb_voto ON secretaria.movimento_membro IS '[votoId] Este movimento no livro de membros exige o voto que o autoriza.';
COMMENT ON CONSTRAINT chk_ofi_datas ON secretaria.oficial IS '[dataFim] O fim do mandato não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_ofi_fim_previsto ON secretaria.oficial IS '[fimPrevisto] O fim previsto do mandato não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_reu_meditacao ON secretaria.reuniao IS 'A meditação é de um membro ou de um convidado, não dos dois.';
COMMENT ON CONSTRAINT chk_rpt_contagens ON secretaria.reuniao_ponto IS 'Os votos a favor, contra e abstenções não podem ser negativos.';
COMMENT ON CONSTRAINT chk_rpt_votacao ON secretaria.reuniao_ponto IS 'Só um ponto votado pode ter votos a favor, contra ou abstenções.';
COMMENT ON CONSTRAINT chk_tme_carta ON secretaria.transferencia_membro IS 'A carta de transferência tem de ter a data e o voto em que foi emitida.';
COMMENT ON CONSTRAINT chk_tme_conclusao ON secretaria.transferencia_membro IS 'A transferência só se conclui depois de aceite pela igreja de destino.';
COMMENT ON CONSTRAINT chk_tme_destino ON secretaria.transferencia_membro IS 'Indique a igreja de destino (do sistema ou de fora).';
COMMENT ON CONSTRAINT chk_tme_diferente ON secretaria.transferencia_membro IS '[destinoIgrejaId] A igreja de destino tem de ser diferente da de origem.';
COMMENT ON CONSTRAINT chk_tme_validade ON secretaria.transferencia_membro IS 'A carta de transferência só é válida 6 meses: já não pode ser aceite.';
COMMENT ON CONSTRAINT chk_vot_leitura ON secretaria.voto IS '[leitura] A leitura do voto é a 1.ª ou a 2.ª.';

COMMENT ON INDEX secretaria.uq_bap_mem IS 'Este membro já tem o baptismo registado.';
COMMENT ON INDEX secretaria.uq_reu_igr_id_numero IS '[numero] Já existe uma reunião com este número.';
COMMENT ON INDEX secretaria.uq_rpr_reu_id_mem_id IS '[membroId] Este membro já está nas presenças desta reunião.';
COMMENT ON INDEX secretaria.uq_vot_reu_id_numero IS '[numero] Já existe um voto com este número nesta reunião.';

-- ---------------------------------------------------------------- Actividades, organização e núcleo
COMMENT ON CONSTRAINT chk_act_datas ON actividades.actividade IS '[dataFim] O fim da actividade não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_epl_datas ON actividades.escala_plano IS '[dataFim] O fim da escala não pode ser antes do início.';
COMMENT ON CONSTRAINT chk_car_mandato ON organizacao.cargo IS '[mandatoAnos] O mandato do cargo é de 1 ou 2 anos.';
COMMENT ON CONSTRAINT chk_igr_mae ON organizacao.igreja IS '[maeIgrejaId] Um grupo ou filial precisa da igreja-mãe.';
COMMENT ON CONSTRAINT chk_igr_mandato ON organizacao.igreja IS '[mandatoAnos] A duração dos mandatos tem de estar entre 1 e 5 anos.';
COMMENT ON CONSTRAINT chk_per_ambito ON nucleo.perfil IS '[ambito] O âmbito do perfil é a igreja ou a Associação.';
COMMENT ON CONSTRAINT chk_usu_contacto ON nucleo.usuario IS 'O utilizador precisa de e-mail ou telefone para entrar.';

COMMENT ON INDEX actividades.uq_eds_epl_id_data IS '[data] Esta escala já tem este dia.';
COMMENT ON INDEX actividades.uq_esc_igr_id_data_funcao_mem_id IS 'Este membro já está escalado nesta função neste dia.';
COMMENT ON INDEX organizacao.uq_car_nome IS '[nome] Já existe um cargo com este nome.';
COMMENT ON INDEX organizacao.uq_dep_nome IS '[nome] Já existe um departamento com este nome.';
COMMENT ON INDEX organizacao.uq_dst_ent_id_nome IS '[nome] Já existe um distrito com este nome nesta Associação.';
COMMENT ON INDEX organizacao.uq_ide_igr_id_dep_id IS 'Este departamento já está nesta igreja.';
COMMENT ON INDEX nucleo.uq_per_nome IS '[nome] Já existe um perfil com este nome.';
COMMENT ON INDEX nucleo.uq_usu_email IS '[email] Já existe um utilizador com este e-mail.';
COMMENT ON INDEX nucleo.uq_usu_email_ci IS '[email] Já existe um utilizador com este e-mail.';
COMMENT ON INDEX nucleo.uq_usu_telefone IS '[telefone] Já existe um utilizador com este telefone.';
COMMENT ON INDEX nucleo.uq_usu_mem_id IS '[membroId] Este membro já tem uma conta de utilizador.';
COMMENT ON INDEX nucleo.uq_uig_usu_id_igr_id_per_id IS 'O utilizador já tem este perfil nesta igreja.';
COMMENT ON INDEX nucleo.uq_uen_usu_id_ent_id_per_id IS 'O utilizador já tem este perfil nesta Associação.';

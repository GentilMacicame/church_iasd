# Definição única do esquema v4 (módulos = schemas PostgreSQL).
# Colunas escritas SEM prefixo; o gerador acrescenta "<prefixo>_".
# "fk:tabela" cria chave estrangeira para <schema>.<tabela>.<pfx>_id.
# Em checks e índices, "@x" passa a "<prefixo>_x" e "{t}" ao nome qualificado da tabela.

REG = ('estado_registo_t', "'ACTIVO'")

class T:
    def __init__(self, name, p, desc, cols, uniq=(), checks=(), estado=REG, big=False, extra=(),
                 cache=False, partition=None):
        self.name, self.p, self.desc, self.cols = name, p, desc, cols
        self.uniq, self.checks, self.estado, self.big, self.extra = uniq, checks, estado, big, extra
        self.cache, self.partition = cache, partition
        self.schema = None

NN = 'NOT NULL'
MODULES = []
def M(fname, schema, title, desc, tables):
    for t in tables: t.schema = schema
    MODULES.append((fname, schema, title, desc, tables))

# ======================================================================= nucleo
M('V2__nucleo', 'nucleo', 'Núcleo: acesso e auditoria',
  'Utilizadores, perfis, permissões e o histórico de todas as alterações.', [
 T('perfil', 'per', 'Perfis de acesso (Admin, Secretário, Tesoureiro, ...)', [
   ('nome', 'VARCHAR(50)', NN), ('descricao', 'VARCHAR(255)'),
   ('ambito', 'VARCHAR(10)', "NOT NULL DEFAULT 'IGREJA'", 'IGREJA ou ENTIDADE (Associação/Missão)')],
   uniq=[['nome']], checks=[('chk_per_ambito', "@ambito IN ('IGREJA', 'ENTIDADE')")]),
 T('permissao', 'prm', 'Permissões elementares (ex.: transacao.aprovar)', [
   ('codigo', 'VARCHAR(80)', NN), ('descricao', 'VARCHAR(255)')], uniq=[['codigo']]),
 T('perfil_permissao', 'ppe', 'Que permissões cada perfil tem', [
   ('per_id', 'fk:perfil', NN), ('prm_id', 'fk:permissao', NN)], uniq=[['per_id', 'prm_id']]),
 T('usuario', 'usu', 'Contas de acesso ao sistema', [
   ('mem_id', 'fk:membro'), ('nome', 'VARCHAR(150)'), ('email', 'VARCHAR(150)'), ('telefone', 'VARCHAR(20)'),
   ('senha_hash', 'VARCHAR(255)', NN, 'bcrypt/argon2, nunca texto'),
   ('super_admin', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'Vê todas as igrejas'),
   ('ultimo_login', 'TIMESTAMPTZ')],
   uniq=[['mem_id'], ['email'], ['telefone']],
   checks=[('chk_usu_contacto', '@email IS NOT NULL OR @telefone IS NOT NULL')]),
 T('usuario_igreja', 'uig', 'Perfil de cada utilizador em cada igreja (base da segurança por igreja)', [
   ('usu_id', 'fk:usuario', NN), ('igr_id', 'fk:igreja', NN), ('per_id', 'fk:perfil', NN)],
   uniq=[['usu_id', 'igr_id', 'per_id']], extra=['CREATE INDEX idx_uig_sessao ON {t} (@usu_id) INCLUDE (@igr_id) WHERE @end_date IS NULL']),
 T('usuario_entidade', 'uen', 'Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)', [
   ('usu_id', 'fk:usuario', NN), ('ent_id', 'fk:entidade', NN), ('per_id', 'fk:perfil', NN)],
   uniq=[['usu_id', 'ent_id', 'per_id']]),
 T('log_auditoria', 'lau', 'Histórico de alterações (só os campos que mudaram); particionado por mês', [
   ('usu_id', 'fk:usuario'), ('tabela', 'VARCHAR(80)', NN), ('registo_id', 'BIGINT', NN),
   ('accao', 'VARCHAR(10)', NN), ('dados_antes', 'JSONB'), ('dados_depois', 'JSONB')],
   checks=[('chk_lau_accao', "@accao IN ('INSERT', 'UPDATE', 'TERMINO')")], big=True,
   partition='@criado_em',
   extra=['CREATE INDEX idx_lau_registo ON {t} (@tabela, @registo_id)',
          'CREATE INDEX idx_lau_data ON {t} USING BRIN (@criado_em)']),
])

# ======================================================================= organizacao
M('V3__organizacao', 'organizacao', 'Organização',
  'Estrutura da denominação (Associação/Missão, distritos, igrejas e grupos), departamentos e cargos.', [
 T('entidade', 'ent', 'Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão', [
   ('pai_ent_id', 'fk:entidade'), ('tipo', 'tipo_entidade_t', NN), ('nome', 'VARCHAR(150)', NN),
   ('sigla', 'VARCHAR(20)'), ('data_criacao', 'DATE')]),
 T('distrito', 'dst', 'Distritos pastorais de uma Associação/Missão', [
   ('ent_id', 'fk:entidade', NN), ('nome', 'VARCHAR(100)', NN),
   ('pastor_usu_id', 'fk:usuario', '', 'Pastor distrital')], uniq=[['ent_id', 'nome']]),
 T('igreja', 'igr', 'Igrejas organizadas, grupos organizados e grupos/filiais', [
   ('ent_id', 'fk:entidade', NN, 'Associação/Missão a que pertence'), ('dst_id', 'fk:distrito'),
   ('tipo', 'tipo_igreja_t', "NOT NULL DEFAULT 'IGREJA_ORGANIZADA'"),
   ('mae_igr_id', 'fk:igreja', '', 'Igreja-mãe de um grupo ou filial'),
   ('nome', 'VARCHAR(150)', NN), ('codigo_acms', 'VARCHAR(30)', '', 'Código no sistema da Associação (ACMS/eAdventist)'),
   ('data_organizacao', 'DATE'), ('endereco', 'VARCHAR(255)'),
   ('latitude', 'DECIMAL(9,6)'), ('longitude', 'DECIMAL(9,6)')],
   uniq=[['codigo_acms']],
   checks=[('chk_igr_mae', "@tipo = 'IGREJA_ORGANIZADA' OR @mae_igr_id IS NOT NULL OR @tipo = 'GRUPO_ORGANIZADO'")]),
 T('departamento', 'dep', 'Departamentos e ministérios (Manual da Igreja)', [
   ('nome', 'VARCHAR(100)', NN), ('descricao', 'VARCHAR(255)')], uniq=[['nome']]),
 T('igreja_departamento', 'ide', 'Departamento a funcionar numa igreja', [
   ('igr_id', 'fk:igreja', NN), ('dep_id', 'fk:departamento', NN)], uniq=[['igr_id', 'dep_id']]),
 T('cargo', 'car', 'Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)', [
   ('dep_id', 'fk:departamento', '', 'NULL = cargo geral da igreja'),
   ('nome', 'VARCHAR(100)', NN), ('mandato_anos', 'SMALLINT', 'NOT NULL DEFAULT 1', 'Duração habitual do mandato'),
   ('exige_membro', 'BOOLEAN', 'NOT NULL DEFAULT TRUE', 'Só membros em situação regular')],
   uniq=[['nome']], checks=[('chk_car_mandato', '@mandato_anos IN (1, 2)')]),
])

# ======================================================================= secretaria
M('V4__secretaria', 'secretaria', 'Secretaria',
  'Membros, famílias, reuniões e votos, movimentos do livro de membros, transferências, disciplina e eleições.', [
 T('familia', 'fam', 'Agregados familiares', [
   ('igr_id', 'fk:igreja', NN), ('nome', 'VARCHAR(150)', NN), ('morada', 'VARCHAR(255)')]),
 T('membro', 'mem', 'Membros, interessados e visitantes regulares (estado muda só por movimento)', [
   ('igr_id', 'fk:igreja', NN), ('fam_id', 'fk:familia'),
   ('nome', 'VARCHAR(100)', NN), ('apelido', 'VARCHAR(100)', NN),
   ('data_nascimento', 'DATE'), ('sexo', 'sexo_t'), ('estado_civil', 'estado_civil_t'),
   ('morada', 'VARCHAR(255)'),
   ('data_entrada', 'DATE', '', 'Data do voto de admissão nesta igreja'),
   ('modo_entrada', 'tipo_movimento_t'),
   ('encarregado_mem_id', 'fk:membro', '', 'Encarregado de educação (menores)'),
   ('validacao', 'estado_validacao_t', "NOT NULL DEFAULT 'PENDENTE'"),
   ('validado_por_usu_id', 'fk:usuario'), ('data_validacao', 'TIMESTAMPTZ')],
   checks=[('chk_mem_encarregado', '@encarregado_mem_id IS NULL OR @encarregado_mem_id <> mem_id')],
   estado=('estado_membro_t', "'INTERESSADO'"),
   extra=['CREATE INDEX idx_mem_igr_estado ON {t} (@igr_id, @estado) WHERE @end_date IS NULL',
          'CREATE INDEX idx_mem_nome ON {t} (lower(@apelido), lower(@nome))']),
 T('contacto', 'cto', 'Telefones, e-mails e WhatsApp de membros ou igrejas', [
   ('mem_id', 'fk:membro'), ('igr_id', 'fk:igreja'),
   ('tipo', 'tipo_contacto_t', NN), ('valor', 'VARCHAR(150)', NN),
   ('principal', 'BOOLEAN', 'NOT NULL DEFAULT FALSE')],
   checks=[('chk_cto_dono', '(@mem_id IS NOT NULL) <> (@igr_id IS NOT NULL)')]),
 T('consentimento', 'cns', 'Consentimentos para tratamento de dados (menores: dado pelo encarregado)', [
   ('mem_id', 'fk:membro', NN), ('tipo', 'tipo_consentimento_t', NN),
   ('concedido', 'BOOLEAN', NN), ('data', 'DATE', 'NOT NULL DEFAULT CURRENT_DATE'),
   ('concedido_por_mem_id', 'fk:membro'), ('observacoes', 'VARCHAR(255)')]),
 T('reuniao', 'reu', 'Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES', [
   ('igr_id', 'fk:igreja', NN), ('tipo', 'tipo_reuniao_t', NN), ('data', 'TIMESTAMPTZ', NN),
   ('local', 'VARCHAR(150)'), ('presidida_por_mem_id', 'fk:membro'), ('secretario_mem_id', 'fk:membro'),
   ('quorum_presentes', 'SMALLINT'), ('acta_url', 'VARCHAR(500)')],
   estado=('estado_reuniao_t', "'CONVOCADA'")),
 T('voto', 'vot', 'Votos registados em acta (admissões, transferências, remoções, eleições, finanças)', [
   ('reu_id', 'fk:reuniao', NN), ('numero', 'VARCHAR(20)', NN, 'Número do voto na acta, ex.: 2026-015'),
   ('tipo', 'tipo_voto_t', NN), ('assunto', 'VARCHAR(255)', NN), ('texto', 'TEXT'),
   ('leitura', 'SMALLINT', 'NOT NULL DEFAULT 1', '1 = primeira leitura, 2 = votação na semana seguinte'),
   ('a_favor', 'SMALLINT'), ('contra', 'SMALLINT'), ('abstencoes', 'SMALLINT')],
   uniq=[['reu_id', 'numero']], checks=[('chk_vot_leitura', '@leitura IN (1, 2)')],
   estado=('resultado_voto_t', "'APROVADO'")),
 T('movimento_membro', 'mmb', 'Livro de membros: cada entrada e saída, com o voto que a autoriza', [
   ('mem_id', 'fk:membro', NN), ('igr_id', 'fk:igreja', NN), ('tipo', 'tipo_movimento_t', NN),
   ('data', 'DATE', NN), ('vot_id', 'fk:voto', '', 'Obrigatório excepto falecimento'),
   ('tme_id', 'fk:transferencia_membro'), ('observacoes', 'VARCHAR(255)')],
   checks=[('chk_mmb_voto', "@tipo = 'FALECIMENTO' OR @vot_id IS NOT NULL OR @tme_id IS NOT NULL")],
   extra=['CREATE INDEX idx_mmb_igr_data ON {t} (@igr_id, @data)']),
 T('transferencia_membro', 'tme', 'Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)', [
   ('mem_id', 'fk:membro', NN), ('origem_igr_id', 'fk:igreja', NN), ('destino_igr_id', 'fk:igreja'),
   ('destino_externo', 'VARCHAR(150)', '', 'Igreja fora do sistema'),
   ('data_pedido', 'DATE', 'NOT NULL DEFAULT CURRENT_DATE'),
   ('origem_vot_id', 'fk:voto', '', 'Voto da igreja de origem que concede a carta'),
   ('carta_emitida_em', 'DATE'),
   ('destino_vot_id', 'fk:voto', '', 'Voto da igreja de destino que aceita o membro'),
   ('aceite_em', 'DATE'), ('observacoes', 'VARCHAR(255)')],
   checks=[('chk_tme_destino', '@destino_igr_id IS NOT NULL OR @destino_externo IS NOT NULL'),
           ('chk_tme_diferente', '@destino_igr_id IS NULL OR @destino_igr_id <> @origem_igr_id'),
           ('chk_tme_carta', "@estado IN ('PEDIDA', 'RECUSADA') OR (@origem_vot_id IS NOT NULL AND @carta_emitida_em IS NOT NULL)"),
           ('chk_tme_validade', "@aceite_em IS NULL OR @aceite_em <= @carta_emitida_em + INTERVAL '6 months'"),
           ('chk_tme_conclusao', "@estado <> 'CONCLUIDA' OR (@aceite_em IS NOT NULL AND (@destino_igr_id IS NULL OR @destino_vot_id IS NOT NULL))")],
   estado=('estado_transferencia_t', "'PEDIDA'")),
 T('disciplina', 'dsc', 'Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura', [
   ('mem_id', 'fk:membro', NN), ('vot_id', 'fk:voto', NN), ('data_inicio', 'DATE', NN), ('data_fim', 'DATE', NN),
   ('encarregado_notificado', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'Obrigatório para menores'),
   ('motivo', 'TEXT', '', 'Dado sensível: só secretário, pastor e anciãos')],
   checks=[('chk_dsc_duracao', "@data_fim > @data_inicio AND @data_fim <= @data_inicio + INTERVAL '12 months'")]),
 T('oficial', 'ofi', 'Eleições e mandatos: quem ocupou que cargo e quando', [
   ('mem_id', 'fk:membro', NN), ('car_id', 'fk:cargo', NN), ('igr_id', 'fk:igreja', NN),
   ('vot_id', 'fk:voto', '', 'Voto da igreja que aprovou o relatório da comissão de nomeações'),
   ('data_inicio', 'DATE', NN), ('data_fim', 'DATE')],
   checks=[('chk_ofi_datas', '@data_fim IS NULL OR @data_fim >= @data_inicio')]),
 T('baptismo', 'bap', 'Baptismos e rebaptismos', [
   ('mem_id', 'fk:membro', NN), ('data', 'DATE', NN), ('local', 'VARCHAR(150)'),
   ('oficiante', 'VARCHAR(150)', '', 'Pastor ordenado que baptizou'),
   ('rebaptismo', 'BOOLEAN', 'NOT NULL DEFAULT FALSE'),
   ('ect_id', 'fk:classe_trimestre', '', 'Classe da ES que preparou o candidato')],
   extra=['CREATE UNIQUE INDEX uq_bap_mem ON {t} (@mem_id) WHERE NOT @rebaptismo AND @end_date IS NULL']),
])

# ======================================================================= actividades
M('V5__actividades', 'actividades', 'Actividades e escalas',
  'Programas dos departamentos, material necessário e escalas de serviço.', [
 T('actividade', 'act', 'Actividades e eventos dos departamentos', [
   ('ide_id', 'fk:igreja_departamento', NN), ('responsavel_mem_id', 'fk:membro'),
   ('nome', 'VARCHAR(150)', NN), ('descricao', 'TEXT'), ('local', 'VARCHAR(255)'),
   ('data_inicio', 'TIMESTAMPTZ', NN), ('data_fim', 'TIMESTAMPTZ'),
   ('data_hora_lembrete', 'TIMESTAMPTZ'), ('valor_previsto', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0')],
   checks=[('chk_act_datas', '@data_fim IS NULL OR @data_fim >= @data_inicio')],
   estado=('estado_actividade_t', "'PLANEADA'")),
 T('material', 'mat', 'Material necessário para uma actividade', [
   ('act_id', 'fk:actividade', NN), ('descricao', 'VARCHAR(255)', NN),
   ('quantidade', 'DECIMAL(10,2)', 'NOT NULL DEFAULT 1'),
   ('preco_unitario', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0')]),
 T('escala', 'esc', 'Escalas de serviço (pregador, diáconos, recepção, ...)', [
   ('igr_id', 'fk:igreja', NN), ('data', 'DATE', NN), ('funcao', 'funcao_escala_t', NN),
   ('mem_id', 'fk:membro', NN), ('act_id', 'fk:actividade'),
   ('substituto_mem_id', 'fk:membro'), ('observacoes', 'VARCHAR(255)')],
   uniq=[['igr_id', 'data', 'funcao', 'mem_id']], estado=('estado_escala_t', "'PREVISTA'")),
])

# ======================================================================= escola_sabatina
M('V6__escola_sabatina', 'escola_sabatina', 'Escola Sabatina',
  'Trimestres, sábados, classes (unidades de acção) por divisão, relatórios, chamada, visitantes e pontuação.', [
 T('trimestre', 'etr', 'Trimestres da lição', [
   ('ano', 'SMALLINT', NN), ('numero', 'SMALLINT', NN), ('tema_licao', 'VARCHAR(200)'),
   ('data_inicio', 'DATE', NN), ('data_fim', 'DATE', NN), ('num_sabados', 'SMALLINT', NN)],
   uniq=[['ano', 'numero']],
   checks=[('chk_etr_numero', '@numero BETWEEN 1 AND 4'), ('chk_etr_sabados', '@num_sabados IN (13, 14)'),
           ('chk_etr_datas', '@data_fim > @data_inicio')]),
 T('sabado', 'esa', 'Sábados de cada trimestre', [
   ('etr_id', 'fk:trimestre', NN), ('numero', 'SMALLINT', NN), ('data', 'DATE', NN),
   ('decimo_terceiro', 'BOOLEAN', 'NOT NULL DEFAULT FALSE')],
   uniq=[['etr_id', 'numero'], ['data']],
   checks=[('chk_esa_numero', '@numero BETWEEN 1 AND 14'), ('chk_esa_sabado', 'EXTRACT(ISODOW FROM @data) = 6')],
   extra=['CREATE UNIQUE INDEX uq_esa_13 ON {t} (@etr_id) WHERE @decimo_terceiro AND @end_date IS NULL']),
 T('classe', 'ecl', 'Classes / unidades de acção, por divisão da Escola Sabatina', [
   ('igr_id', 'fk:igreja', NN), ('nome', 'VARCHAR(100)', NN),
   ('divisao', 'es_divisao_t', "NOT NULL DEFAULT 'ADULTOS'"), ('local_reuniao', 'VARCHAR(150)')],
   uniq=[['igr_id', 'nome']]),
 T('classe_trimestre', 'ect', 'Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)', [
   ('ecl_id', 'fk:classe', NN), ('etr_id', 'fk:trimestre', NN),
   ('igr_id', 'fk:igreja', NN, 'Copiado da classe (segurança e desempenho)'),
   ('professor_mem_id', 'fk:membro'), ('auxiliar_mem_id', 'fk:membro'), ('secretario_mem_id', 'fk:membro'),
   ('alvo_membros', 'SMALLINT', 'NOT NULL DEFAULT 0'),
   ('alvo_estudo_diario', 'DECIMAL(5,4)', 'NOT NULL DEFAULT 1'),
   ('alvo_filiais', 'SMALLINT', 'NOT NULL DEFAULT 0'),
   ('alvo_oferta_sabado', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0', 'Alvo da oferta missionária por sábado'),
   ('alvo_baptismos', 'SMALLINT', 'NOT NULL DEFAULT 0')],
   uniq=[['ecl_id', 'etr_id']],
   checks=[('chk_ect_alvos', '@alvo_membros >= 0 AND @alvo_estudo_diario BETWEEN 0 AND 1 AND @alvo_oferta_sabado >= 0')],
   extra=['CREATE INDEX idx_ect_igr_etr ON {t} (@igr_id, @etr_id) WHERE @end_date IS NULL']),
 T('matricula', 'ema', 'Inscrição nas classes (histórico); membros e não membros', [
   ('ecl_id', 'fk:classe', NN), ('mem_id', 'fk:membro', NN),
   ('data_entrada', 'DATE', 'NOT NULL DEFAULT CURRENT_DATE'), ('data_saida', 'DATE')],
   checks=[('chk_ema_datas', '@data_saida IS NULL OR @data_saida >= @data_entrada')],
   extra=['CREATE UNIQUE INDEX uq_ema_activa ON {t} (@mem_id) WHERE @data_saida IS NULL AND @end_date IS NULL']),
 T('relatorio_sabado', 'ers', 'Relatório de cada classe em cada sábado (linha da folha "Grupo N")', [
   ('ect_id', 'fk:classe_trimestre', NN), ('esa_id', 'fk:sabado', NN),
   ('igr_id', 'fk:igreja', NN, 'Copiado da classe (segurança e desempenho)'),
   ('membros_matriculados', 'SMALLINT', NN, 'M.M. (se vier vazio, é calculado pelas matrículas)'),
   ('membros_presentes', 'SMALLINT', NN, 'M.P. (recalculado quando há chamada nominal)'),
   ('estudo_diario', 'SMALLINT', 'NOT NULL DEFAULT 0', 'E.D.'),
   ('visitantes', 'SMALLINT', 'NOT NULL DEFAULT 0'), ('filiais', 'SMALLINT', 'NOT NULL DEFAULT 0'),
   ('oferta', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0', 'Oferta missionária (vai toda para as missões)'),
   ('oferta_13_sabado', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0'),
   ('oferta_despesas', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0', 'Oferta para despesas da ES local (sempre separada da missionária)'),
   ('tra_id', 'fk:transacao', '', 'Lançamento das ofertas na tesouraria'),
   ('observacoes', 'VARCHAR(500)')],
   uniq=[['ect_id', 'esa_id']],
   checks=[('chk_ers_numeros', '@membros_presentes BETWEEN 0 AND @membros_matriculados AND @estudo_diario BETWEEN 0 AND @membros_presentes AND @visitantes >= 0 AND @filiais >= 0'),
           ('chk_ers_ofertas', '@oferta >= 0 AND @oferta_13_sabado >= 0 AND @oferta_despesas >= 0')],
   estado=('estado_relatorio_t', "'ABERTO'")),
 T('presenca', 'epr', 'Chamada nominal (opcional); actualiza M.P. e E.D. do relatório', [
   ('ers_id', 'fk:relatorio_sabado', NN), ('mem_id', 'fk:membro', NN),
   ('igr_id', 'fk:igreja', NN, 'Copiado do relatório (segurança e desempenho)'),
   ('presente', 'BOOLEAN', NN), ('estudou_licao', 'BOOLEAN', 'NOT NULL DEFAULT FALSE')],
   uniq=[['ers_id', 'mem_id']], big=True,
   checks=[('chk_epr_estudo', '@presente OR NOT @estudou_licao')],
   extra=['CREATE INDEX idx_epr_mem ON {t} (@mem_id) WHERE @presente']),
 T('visitante', 'evi', 'Visitantes com contacto para seguimento', [
   ('ers_id', 'fk:relatorio_sabado', NN), ('nome', 'VARCHAR(150)', NN), ('telefone', 'VARCHAR(20)'),
   ('convidado_por_mem_id', 'fk:membro'), ('tornou_se_mem_id', 'fk:membro'),
   ('anonimizado_em', 'TIMESTAMPTZ', '', 'Dados apagados por fim do prazo de retenção')]),
 T('pontuacao_config', 'epc', 'Pesos da pontuação (sem trimestre = pesos por defeito)', [
   ('etr_id', 'fk:trimestre'),
   ('peso_presenca', 'DECIMAL(4,3)', 'NOT NULL DEFAULT 0.30'),
   ('peso_estudo', 'DECIMAL(4,3)', 'NOT NULL DEFAULT 0.30'),
   ('peso_ofertas', 'DECIMAL(4,3)', 'NOT NULL DEFAULT 0.25'),
   ('peso_visitantes', 'DECIMAL(4,3)', 'NOT NULL DEFAULT 0.15'),
   ('limite_ofertas', 'DECIMAL(4,2)', 'NOT NULL DEFAULT 1.20')],
   checks=[('chk_epc_soma', '@peso_presenca + @peso_estudo + @peso_ofertas + @peso_visitantes = 1'),
           ('chk_epc_limite', '@limite_ofertas >= 1')],
   extra=['CREATE UNIQUE INDEX uq_epc_trimestre ON {t} (@etr_id) WHERE @etr_id IS NOT NULL AND @end_date IS NULL',
          'CREATE UNIQUE INDEX uq_epc_defeito ON {t} ((TRUE)) WHERE @etr_id IS NULL AND @end_date IS NULL']),
])

# ======================================================================= tesouraria
M('V7__tesouraria', 'tesouraria', 'Tesouraria',
  'Contas, fundos (da Associação e locais), movimentos divididos por fundo, despesas, contagens, recibos, remessas, orçamento, fecho mensal e saldos pré-calculados.', [
 T('conta_financeira', 'cfi', 'Contas onde o dinheiro está (M-Pesa, banco, caixa)', [
   ('igr_id', 'fk:igreja', NN), ('tipo', 'tipo_conta_t', NN), ('nome', 'VARCHAR(100)', NN),
   ('numero', 'VARCHAR(50)'), ('titular', 'VARCHAR(150)'), ('banco', 'VARCHAR(100)'),
   ('moeda', 'CHAR(3)', "NOT NULL DEFAULT 'MZN'"),
   ('saldo_inicial', 'DECIMAL(14,2)', 'NOT NULL DEFAULT 0'),
   ('data_saldo_inicial', 'DATE', NN, 'Movimentos anteriores a esta data não entram no saldo')],
   uniq=[['igr_id', 'nome']]),
 T('fundo', 'fun', 'Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais', [
   ('igr_id', 'fk:igreja', '', 'NULL = fundo geral'),
   ('codigo', 'VARCHAR(20)', NN), ('nome', 'VARCHAR(100)', NN), ('tipo', 'tipo_fundo_t', NN),
   ('restrito', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'Fundo local que só pode ser gasto no seu fim'),
   ('percentagem_remessa', 'DECIMAL(5,2)', 'NOT NULL DEFAULT 0', '100 = fundo da Associação, a igreja não o pode usar'),
   ('destino_ent_id', 'fk:entidade')],
   uniq=[['codigo']],
   checks=[('chk_fun_remessa', '@percentagem_remessa BETWEEN 0 AND 100 AND (@percentagem_remessa = 0 OR @destino_ent_id IS NOT NULL)'),
           ('chk_fun_associacao', "@tipo NOT IN ('DIZIMO', 'ES_MISSOES', 'ES_13_SABADO', 'OFERTA_MISSIONARIA') OR @percentagem_remessa = 100"),
           ('chk_fun_local', "@tipo NOT IN ('ES_DESPESAS', 'ORCAMENTO_LOCAL') OR @percentagem_remessa = 0")]),
 T('calendario_oferta', 'cof', 'Calendário de ofertas especiais definido pela Divisão/União/Associação', [
   ('ent_id', 'fk:entidade', NN), ('data', 'DATE', NN), ('fun_id', 'fk:fundo', NN),
   ('descricao', 'VARCHAR(150)', NN)], uniq=[['ent_id', 'data', 'fun_id']]),
 T('categoria', 'cat', 'Plano de contas: categorias de receita e despesa', [
   ('pai_cat_id', 'fk:categoria'), ('codigo', 'VARCHAR(20)', NN), ('nome', 'VARCHAR(100)', NN),
   ('tipo', 'tipo_categoria_t', NN),
   ('e_remessa', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'Categoria usada para enviar fundos à Associação')], uniq=[['codigo']]),
 T('alvo', 'alv', 'Alvos de arrecadação por fundo', [
   ('igr_id', 'fk:igreja', NN), ('fun_id', 'fk:fundo', NN), ('descricao', 'VARCHAR(255)'),
   ('valor_alvo', 'DECIMAL(14,2)', NN), ('data_inicio', 'DATE', NN), ('data_fim', 'DATE', NN)],
   checks=[('chk_alv', '@valor_alvo > 0 AND @data_fim >= @data_inicio')]),
 T('orcamento', 'orc', 'Orçamento anual da igreja local (aprovado pela igreja)', [
   ('igr_id', 'fk:igreja', NN), ('ide_id', 'fk:igreja_departamento'), ('ano', 'SMALLINT', NN),
   ('vot_id', 'fk:voto', '', 'Voto da igreja que aprovou o orçamento'),
   ('observacoes', 'VARCHAR(500)')],
   estado=('estado_orcamento_t', "'RASCUNHO'"),
   checks=[('chk_orc_aprovado', "@estado = 'RASCUNHO' OR @vot_id IS NOT NULL")],
   extra=['CREATE UNIQUE INDEX uq_orc ON {t} (@igr_id, COALESCE(@ide_id, 0), @ano) WHERE @end_date IS NULL']),
 T('orcamento_linha', 'orl', 'Valor previsto por categoria', [
   ('orc_id', 'fk:orcamento', NN), ('cat_id', 'fk:categoria', NN),
   ('valor_previsto', 'DECIMAL(14,2)', NN)], uniq=[['orc_id', 'cat_id']],
   checks=[('chk_orl_valor', '@valor_previsto >= 0')]),
 T('despesa', 'des', 'Requisições de despesa (quem pede não aprova)', [
   ('igr_id', 'fk:igreja', NN), ('ide_id', 'fk:igreja_departamento'), ('act_id', 'fk:actividade'),
   ('cat_id', 'fk:categoria', NN), ('fun_id', 'fk:fundo', NN),
   ('descricao', 'VARCHAR(255)', NN), ('fornecedor', 'VARCHAR(150)'),
   ('valor_solicitado', 'DECIMAL(14,2)', NN), ('valor_aprovado', 'DECIMAL(14,2)'),
   ('solicitado_por_usu_id', 'fk:usuario', NN), ('aprovado_por_usu_id', 'fk:usuario'),
   ('vot_id', 'fk:voto', '', 'Voto da junta, quando o valor o exige'),
   ('aprovado_em', 'TIMESTAMPTZ'), ('motivo_rejeicao', 'VARCHAR(255)')],
   checks=[('chk_des_valores', '@valor_solicitado > 0 AND (@valor_aprovado IS NULL OR @valor_aprovado > 0)'),
           ('chk_des_quem_pede_nao_aprova', '@aprovado_por_usu_id IS NULL OR @aprovado_por_usu_id <> @solicitado_por_usu_id'),
           ('chk_des_aprovacao', "@estado NOT IN ('APROVADA', 'PAGA') OR (@aprovado_por_usu_id IS NOT NULL AND @valor_aprovado IS NOT NULL)"),
           ('chk_des_rejeicao', "@estado <> 'REJEITADA' OR @motivo_rejeicao IS NOT NULL")],
   estado=('estado_despesa_t', "'SUBMETIDA'")),
 T('contagem_numerario', 'cnu', 'Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)', [
   ('igr_id', 'fk:igreja', NN), ('cfi_id', 'fk:conta_financeira', NN), ('data', 'DATE', NN),
   ('ocasiao', 'VARCHAR(100)', "NOT NULL DEFAULT 'Culto de sábado'"),
   ('contador1_mem_id', 'fk:membro', NN), ('contador2_mem_id', 'fk:membro', NN),
   ('total_contado', 'DECIMAL(14,2)', NN), ('conferido_por_usu_id', 'fk:usuario')],
   checks=[('chk_cnu_contadores_diferentes', '@contador1_mem_id <> @contador2_mem_id'),
           ('chk_cnu_total', '@total_contado >= 0')],
   estado=('estado_contagem_t', "'ABERTA'")),
 T('transacao', 'tra', 'Movimentos: entradas, saídas e transferências (cabeçalho)', [
   ('igr_id', 'fk:igreja', NN, 'Preenchido automaticamente a partir da conta'),
   ('tipo', 'tipo_transacao_t', NN), ('metodo', 'metodo_pagamento_t', NN),
   ('valor_total', 'DECIMAL(14,2)', NN),
   ('cfi_id', 'fk:conta_financeira', NN),
   ('destino_cfi_id', 'fk:conta_financeira', '', 'Só transferências'),
   ('mem_id', 'fk:membro', '', 'Quem entregou'), ('fam_id', 'fk:familia', '', 'Entrega em nome da família'),
   ('anonimo', 'BOOLEAN', 'NOT NULL DEFAULT FALSE'),
   ('cnu_id', 'fk:contagem_numerario'), ('des_id', 'fk:despesa'),
   ('estorno_tra_id', 'fk:transacao'),
   ('beneficiario', 'VARCHAR(150)'), ('descricao', 'VARCHAR(255)'), ('referencia', 'VARCHAR(100)'),
   ('data_hora', 'TIMESTAMPTZ', 'NOT NULL DEFAULT now()'),
   ('aprovado_por_usu_id', 'fk:usuario')],
   checks=[('chk_tra_valor', '@valor_total > 0'),
           ('chk_tra_anonimo', 'NOT (@anonimo AND (@mem_id IS NOT NULL OR @fam_id IS NOT NULL))'),
           ('chk_tra_transferencia', "(@tipo = 'TRANSFERENCIA') = (@destino_cfi_id IS NOT NULL) AND (@destino_cfi_id IS NULL OR @destino_cfi_id <> @cfi_id)"),
           ('chk_tra_quem_regista_nao_aprova', '@aprovado_por_usu_id IS NULL OR @criado_por IS NULL OR @aprovado_por_usu_id <> @criado_por'),
           ('chk_tra_despesa', "@des_id IS NULL OR @tipo = 'SAIDA'"),
           ('chk_tra_contagem', "@cnu_id IS NULL OR (@tipo = 'ENTRADA' AND @metodo = 'NUMERARIO')")],
   estado=('estado_transacao_t', "'PENDENTE'"), big=True,
   extra=['CREATE INDEX idx_tra_igr_data ON {t} (@igr_id, @data_hora DESC)',
          'CREATE INDEX idx_tra_pendentes ON {t} (@igr_id) WHERE @estado = \'PENDENTE\' AND @end_date IS NULL']),
 T('transacao_linha', 'tli', 'Divisão do valor por fundo e categoria (soma = valor_total)', [
   ('tra_id', 'fk:transacao', NN),
   ('igr_id', 'fk:igreja', NN, 'Copiado da transacção (segurança e desempenho)'),
   ('fun_id', 'fk:fundo', NN), ('cat_id', 'fk:categoria', NN),
   ('ide_id', 'fk:igreja_departamento'), ('act_id', 'fk:actividade'),
   ('valor', 'DECIMAL(14,2)', NN), ('descricao', 'VARCHAR(255)')],
   checks=[('chk_tli_valor', '@valor > 0')], big=True,
   extra=['CREATE INDEX idx_tli_igr_fun ON {t} (@igr_id, @fun_id)']),
 T('saldo_diario_conta', 'sdc', 'Saldo pré-calculado por conta e dia (mantido por triggers; não editar)', [
   ('cfi_id', 'fk:conta_financeira', NN), ('igr_id', 'fk:igreja', NN), ('data', 'DATE', NN),
   ('entradas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0'), ('saidas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0')],
   uniq=[['cfi_id', 'data']], big=True, cache=True),
 T('saldo_diario_fundo', 'sdf', 'Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar)', [
   ('igr_id', 'fk:igreja', NN), ('fun_id', 'fk:fundo', NN), ('moeda', 'CHAR(3)', NN), ('data', 'DATE', NN),
   ('entradas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0', 'Entradas que não são estornos'),
   ('saidas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0', 'Saídas que não são estornos'),
   ('estornos_entradas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0', 'Saídas que estornam entradas'),
   ('estornos_saidas', 'DECIMAL(16,2)', 'NOT NULL DEFAULT 0', 'Entradas que estornam saídas')],
   uniq=[['igr_id', 'fun_id', 'moeda', 'data']], big=True, cache=True),
 T('recibo', 'rec', 'Recibos numerados por igreja e ano', [
   ('tra_id', 'fk:transacao', NN), ('igr_id', 'fk:igreja', NN),
   ('ano', 'SMALLINT', NN), ('numero', 'INT', NN)],
   uniq=[['tra_id'], ['igr_id', 'ano', 'numero']], big=True),
 T('documento', 'doc', 'Comprovativos (facturas, talões, prints M-Pesa)', [
   ('tra_id', 'fk:transacao'), ('des_id', 'fk:despesa'), ('tipo', 'tipo_documento_t', NN),
   ('nome_ficheiro', 'VARCHAR(255)', NN), ('url', 'VARCHAR(500)', NN)],
   checks=[('chk_doc_dono', '@tra_id IS NOT NULL OR @des_id IS NOT NULL')]),
 T('remessa', 'rem', 'Remessas mensais à Associação/Missão', [
   ('igr_id', 'fk:igreja', NN), ('ent_id', 'fk:entidade', NN), ('ano', 'SMALLINT', NN),
   ('mes', 'SMALLINT', NN), ('tra_id', 'fk:transacao'), ('enviada_em', 'DATE')],
   uniq=[['igr_id', 'ent_id', 'ano', 'mes']], checks=[('chk_rem_mes', '@mes BETWEEN 1 AND 12')],
   estado=('estado_remessa_t', "'PREPARADA'")),
 T('remessa_linha', 'rml', 'Valor remetido por fundo', [
   ('rem_id', 'fk:remessa', NN), ('fun_id', 'fk:fundo', NN), ('valor', 'DECIMAL(14,2)', NN)],
   uniq=[['rem_id', 'fun_id']], checks=[('chk_rml_valor', '@valor >= 0')]),
 T('fecho_periodo', 'fpe', 'Meses fechados: movimentos bloqueados (reabrir = preencher end_date)', [
   ('igr_id', 'fk:igreja', NN), ('ano', 'SMALLINT', NN), ('mes', 'SMALLINT', NN)],
   uniq=[['igr_id', 'ano', 'mes']], checks=[('chk_fpe_mes', '@mes BETWEEN 1 AND 12')]),
 T('extrato_linha', 'ext', 'Linhas do extracto bancário/M-Pesa para reconciliação', [
   ('cfi_id', 'fk:conta_financeira', NN), ('data', 'DATE', NN), ('descricao', 'VARCHAR(255)'),
   ('referencia', 'VARCHAR(100)'), ('valor', 'DECIMAL(14,2)', NN),
   ('tra_id', 'fk:transacao')],
   uniq=[['cfi_id', 'data', 'referencia', 'valor']], big=True),
])

# ======================================================================= pagamentos
M('V8__pagamentos', 'pagamentos', 'Pagamentos electrónicos', 'Integração com M-Pesa e bancos.', [
 T('pagamento_mpesa', 'pmp', 'Pedido e resposta da API M-Pesa', [
   ('tra_id', 'fk:transacao', NN), ('direccao', 'VARCHAR(3)', "NOT NULL DEFAULT 'C2B'"),
   ('msisdn', 'VARCHAR(15)', NN), ('valor', 'DECIMAL(14,2)', NN),
   ('taxa', 'DECIMAL(12,2)', 'NOT NULL DEFAULT 0'),
   ('transaction_reference', 'VARCHAR(50)', NN), ('third_party_reference', 'VARCHAR(50)', NN),
   ('service_provider_code', 'VARCHAR(20)', NN), ('response_code', 'VARCHAR(20)'),
   ('response_desc', 'VARCHAR(255)'), ('mpesa_transaction_id', 'VARCHAR(50)'),
   ('conversation_id', 'VARCHAR(100)'), ('pedido_em', 'TIMESTAMPTZ', 'NOT NULL DEFAULT now()'),
   ('respondido_em', 'TIMESTAMPTZ'), ('ultima_consulta_em', 'TIMESTAMPTZ'),
   ('tentativas_consulta', 'SMALLINT', 'NOT NULL DEFAULT 0')],
   uniq=[['tra_id'], ['third_party_reference'], ['mpesa_transaction_id']],
   checks=[('chk_pmp_direccao', "@direccao IN ('C2B', 'B2C')")], big=True,
   extra=['CREATE INDEX idx_pmp_pendentes ON {t} (@pedido_em) WHERE @respondido_em IS NULL AND @end_date IS NULL']),
 T('mpesa_callback_log', 'mcl', 'Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)', [
   ('pmp_id', 'fk:pagamento_mpesa'), ('tipo', 'VARCHAR(30)', NN),
   ('chave_idempotencia', 'VARCHAR(100)', NN), ('payload', 'JSONB', NN),
   ('processado', 'BOOLEAN', 'NOT NULL DEFAULT FALSE'), ('erro', 'VARCHAR(500)'),
   ('recebido_em', 'TIMESTAMPTZ', 'NOT NULL DEFAULT now()')],
   uniq=[['chave_idempotencia']], big=True,
   extra=['CREATE INDEX idx_mcl_por_processar ON {t} (@recebido_em) WHERE NOT @processado']),
 T('pagamento_bancario', 'pba', 'Detalhe de pagamentos por banco', [
   ('tra_id', 'fk:transacao', NN), ('banco', 'VARCHAR(100)'), ('nib', 'VARCHAR(25)', NN),
   ('titular', 'VARCHAR(150)', NN), ('referencia_bancaria', 'VARCHAR(100)')],
   uniq=[['tra_id']], big=True),
])

# ======================================================================= comunicacao
M('V9__comunicacao', 'comunicacao', 'Comunicação', 'Fila de SMS, WhatsApp e e-mail.', [
 T('notificacao', 'ntf', 'Fila de SMS, WhatsApp e e-mail a enviar', [
   ('igr_id', 'fk:igreja', NN), ('mem_id', 'fk:membro'), ('canal', 'canal_notificacao_t', NN),
   ('destino', 'VARCHAR(150)', NN), ('assunto', 'VARCHAR(150)'), ('mensagem', 'TEXT', NN),
   ('agendada_para', 'TIMESTAMPTZ', 'NOT NULL DEFAULT now()'), ('enviada_em', 'TIMESTAMPTZ'),
   ('tentativas', 'SMALLINT', 'NOT NULL DEFAULT 0'), ('erro', 'VARCHAR(500)'),
   ('origem_tabela', 'VARCHAR(80)'), ('origem_id', 'BIGINT')],
   estado=('estado_notificacao_t', "'PENDENTE'"), big=True,
   extra=["CREATE INDEX idx_ntf_fila ON {t} (@agendada_para) WHERE @estado = 'PENDENTE' AND @end_date IS NULL"]),
])

SCHEMAS = [m[1] for m in MODULES]

# Segurança: em que igreja está cada registo --------------------------------
# ('direct', coluna)            a tabela tem a coluna de igreja
# ('parent', fk, tabela_mae)    a igreja vem da tabela-mãe (que tem coluna de igreja)
# ('custom', expressão com {A}) regra própria; {A} = array das igrejas onde o utilizador tem a permissão
# Tabelas que não estão aqui são comuns a todas as igrejas (ver GLOBAL_READ).
SCOPE = {
 'igreja': ('direct', 'id'), 'usuario_igreja': ('direct', 'igr_id'), 'familia': ('direct', 'igr_id'),
 'membro': ('direct', 'igr_id'), 'reuniao': ('direct', 'igr_id'), 'movimento_membro': ('direct', 'igr_id'),
 'oficial': ('direct', 'igr_id'), 'igreja_departamento': ('direct', 'igr_id'), 'escala': ('direct', 'igr_id'),
 'classe': ('direct', 'igr_id'), 'classe_trimestre': ('direct', 'igr_id'), 'relatorio_sabado': ('direct', 'igr_id'),
 'presenca': ('direct', 'igr_id'), 'conta_financeira': ('direct', 'igr_id'), 'alvo': ('direct', 'igr_id'),
 'orcamento': ('direct', 'igr_id'), 'despesa': ('direct', 'igr_id'), 'contagem_numerario': ('direct', 'igr_id'),
 'transacao': ('direct', 'igr_id'), 'transacao_linha': ('direct', 'igr_id'),
 'saldo_diario_conta': ('direct', 'igr_id'), 'saldo_diario_fundo': ('direct', 'igr_id'),
 'recibo': ('direct', 'igr_id'), 'remessa': ('direct', 'igr_id'), 'fecho_periodo': ('direct', 'igr_id'),
 'notificacao': ('direct', 'igr_id'),
 'consentimento': ('parent', 'mem_id', 'membro'), 'baptismo': ('parent', 'mem_id', 'membro'),
 'disciplina': ('parent', 'mem_id', 'membro'), 'voto': ('parent', 'reu_id', 'reuniao'),
 'actividade': ('parent', 'ide_id', 'igreja_departamento'), 'matricula': ('parent', 'ecl_id', 'classe'),
 'visitante': ('parent', 'ers_id', 'relatorio_sabado'), 'orcamento_linha': ('parent', 'orc_id', 'orcamento'),
 'remessa_linha': ('parent', 'rem_id', 'remessa'), 'extrato_linha': ('parent', 'cfi_id', 'conta_financeira'),
 'pagamento_mpesa': ('parent', 'tra_id', 'transacao'), 'pagamento_bancario': ('parent', 'tra_id', 'transacao'),
 'material': ('custom', 'EXISTS (SELECT 1 FROM actividades.actividade a JOIN organizacao.igreja_departamento d ON d.ide_id = a.act_ide_id WHERE a.act_id = @act_id AND d.ide_igr_id = ANY ({A}))'),
 'fundo': ('custom', '@igr_id = ANY ({A}) OR (@igr_id IS NULL AND {G})'),
 'contacto': ('custom', '@igr_id = ANY ({A}) OR EXISTS (SELECT 1 FROM secretaria.membro m WHERE m.mem_id = @mem_id AND m.mem_igr_id = ANY ({A}))'),
 'transferencia_membro': ('custom', '@origem_igr_id = ANY ({A}) OR @destino_igr_id = ANY ({A})'),
 'documento': ('custom', 'EXISTS (SELECT 1 FROM tesouraria.transacao x WHERE x.tra_id = @tra_id AND x.tra_igr_id = ANY ({A})) OR EXISTS (SELECT 1 FROM tesouraria.despesa x WHERE x.des_id = @des_id AND x.des_igr_id = ANY ({A}))'),
}
# Tabelas comuns que qualquer utilizador autenticado pode ler (escrever exige permissão)
GLOBAL_READ = {'perfil', 'permissao', 'perfil_permissao', 'entidade', 'distrito', 'departamento', 'cargo',
               'trimestre', 'sabado', 'pontuacao_config', 'calendario_oferta', 'categoria'}
# Tabelas que só os triggers do sistema escrevem (os utilizadores só lêem)
SYSTEM_WRITE = {'saldo_diario_conta', 'saldo_diario_fundo', 'log_auditoria'}

# O próprio membro vê sempre os seus dados (direito de acesso), mesmo sem perfil
OWNER_READ = {   # (SELECT ...) = calculado uma vez por consulta
 'membro': '@id = (SELECT nucleo.fn_membro_sessao())',
 'contacto': '@mem_id = (SELECT nucleo.fn_membro_sessao())',
 'consentimento': '@mem_id = (SELECT nucleo.fn_membro_sessao())',
 'transacao': "@mem_id = (SELECT nucleo.fn_membro_sessao()) OR @fam_id = (SELECT nucleo.fn_familia_sessao())",
 'transacao_linha': '@tra_id IN (SELECT x.tra_id FROM tesouraria.transacao x WHERE x.tra_mem_id = (SELECT nucleo.fn_membro_sessao()) OR x.tra_fam_id = (SELECT nucleo.fn_familia_sessao()))',
 'recibo': '@tra_id IN (SELECT x.tra_id FROM tesouraria.transacao x WHERE x.tra_mem_id = (SELECT nucleo.fn_membro_sessao()) OR x.tra_fam_id = (SELECT nucleo.fn_familia_sessao()))',
 'fundo': 'TRUE',
 'matricula': '@mem_id = (SELECT nucleo.fn_membro_sessao())',
 'presenca': '@mem_id = (SELECT nucleo.fn_membro_sessao())',
 'escala': '(SELECT nucleo.fn_membro_sessao()) IN (@mem_id, @substituto_mem_id)',
 'usuario': '@id = (SELECT nucleo.fn_usuario_sessao())',
}

# Permissões de negócio (além de ler / criar / alterar / terminar em cada tabela)
ACCOES = ['ler', 'criar', 'alterar', 'terminar']
NEGOCIO = [
 ('secretaria.membro.validar', 'Aprovar o registo de um membro'),
 ('secretaria.transferencia_membro.emitir_carta', 'Emitir a carta de transferência (igreja de origem)'),
 ('secretaria.transferencia_membro.aceitar', 'Concluir a transferência (igreja de destino)'),
 ('tesouraria.transacao.aprovar', 'Aprovar uma saída de dinheiro'),
 ('tesouraria.despesa.aprovar', 'Aprovar ou rejeitar requisições de despesa'),
 ('tesouraria.orcamento.aprovar', 'Marcar o orçamento como aprovado'),
 ('tesouraria.remessa.confirmar', 'Confirmar a recepção de uma remessa (Associação)'),
 ('escola_sabatina.relatorio_sabado.fechar', 'Fechar o relatório do sábado'),
 ('escola_sabatina.relatorio_sabado.reabrir', 'Reabrir um relatório fechado'),
]

# Perfis: regras aplicadas por ordem ('+' acrescenta, '-' retira); padrões do tipo fnmatch
PERFIS = [
 ('ADMIN', 'IGREJA', 'Administrador do sistema na igreja (não vê a disciplina)', [
   ('+', '*'), ('-', 'secretaria.disciplina.*'), ('-', 'nucleo.*'), ('+', 'nucleo.usuario.*'), ('+', 'nucleo.usuario_igreja.*'),
   ('-', 'nucleo.usuario.super_admin'), ('-', '*.aprovar'), ('-', 'tesouraria.remessa.confirmar'), ('-', 'organizacao.*'),
   ('+', 'organizacao.igreja.ler'), ('+', 'organizacao.igreja.alterar'), ('+', 'organizacao.igreja_departamento.*'),
   # actos que o Manual reserva ao secretário, tesoureiro e anciãos não são do administrador técnico
   ('-', 'secretaria.membro.validar'), ('-', 'secretaria.transferencia_membro.emitir_carta'),
   ('-', 'secretaria.transferencia_membro.aceitar'), ('-', 'escola_sabatina.relatorio_sabado.fechar'),
   ('-', 'escola_sabatina.relatorio_sabado.reabrir')]),
 ('PASTOR', 'IGREJA', 'Pastor: lê tudo da igreja, gere a secretaria e a disciplina, aprova despesas', [
   ('+', '*.ler'), ('-', 'nucleo.log_auditoria.ler'), ('+', 'secretaria.*'), ('+', 'actividades.*'),
   ('+', 'tesouraria.despesa.aprovar'), ('+', 'tesouraria.transacao.aprovar'), ('+', 'tesouraria.orcamento.aprovar')]),
 ('ANCIAO', 'IGREJA', 'Ancião: aprova saídas e despesas, fecha e reabre meses, reuniões e votos', [
   ('+', 'secretaria.*.ler'), ('+', 'secretaria.reuniao.*'), ('+', 'secretaria.voto.*'),
   ('+', 'escola_sabatina.*.ler'), ('+', 'actividades.*'), ('+', 'tesouraria.*.ler'),
   ('+', 'tesouraria.transacao.aprovar'), ('+', 'tesouraria.despesa.aprovar'), ('+', 'tesouraria.despesa.alterar'),
   ('+', 'tesouraria.orcamento.aprovar'), ('+', 'tesouraria.orcamento.alterar'), ('+', 'tesouraria.fecho_periodo.*'),
   ('+', 'organizacao.igreja.ler'), ('+', 'organizacao.igreja_departamento.ler'), ('+', 'nucleo.usuario_igreja.ler')]),
 ('SECRETARIO', 'IGREJA', 'Secretário(a) da igreja: livro de membros, reuniões, votos, transferências, disciplina', [
   ('+', 'secretaria.*'), ('+', 'actividades.escala.*'), ('+', 'escola_sabatina.*.ler'),
   ('+', 'organizacao.igreja.ler'), ('+', 'organizacao.igreja_departamento.ler')]),
 ('TESOUREIRO', 'IGREJA', 'Tesoureiro(a): movimentos, recibos, contagens, despesas, remessas (não aprova o que regista)', [
   ('+', 'tesouraria.*'), ('-', '*.aprovar'), ('-', 'tesouraria.remessa.confirmar'), ('-', 'tesouraria.fecho_periodo.terminar'),
   ('+', 'pagamentos.*'), ('+', 'comunicacao.notificacao.*'),
   ('+', 'secretaria.membro.ler'), ('+', 'secretaria.familia.ler'), ('+', 'secretaria.contacto.ler'),
   ('+', 'escola_sabatina.relatorio_sabado.ler'), ('+', 'escola_sabatina.classe*.ler'),
   ('+', 'organizacao.igreja.ler'), ('+', 'organizacao.igreja_departamento.ler'), ('+', 'actividades.actividade.ler')]),
 ('DIRECTOR_ES', 'IGREJA', 'Director(a) da Escola Sabatina: classes, alvos, relatórios', [
   ('+', 'escola_sabatina.*'), ('+', 'secretaria.membro.ler'), ('+', 'secretaria.baptismo.ler'),
   ('+', 'actividades.escala.*'), ('+', 'organizacao.igreja.ler')]),
 ('SECRETARIO_ES', 'IGREJA', 'Secretário(a) da Escola Sabatina: relatórios do sábado e chamada', [
   ('+', 'escola_sabatina.*.ler'), ('+', 'escola_sabatina.relatorio_sabado.*'), ('-', 'escola_sabatina.relatorio_sabado.reabrir'),
   ('-', 'escola_sabatina.relatorio_sabado.terminar'),
   ('+', 'escola_sabatina.presenca.*'), ('+', 'escola_sabatina.visitante.*'), ('+', 'escola_sabatina.matricula.*'),
   ('+', 'secretaria.membro.ler'), ('+', 'organizacao.igreja.ler')]),
 ('DIRECTOR_DEPARTAMENTO', 'IGREJA', 'Director(a) de departamento: actividades, material, escalas, pedir despesas', [
   ('+', 'actividades.*'), ('-', 'actividades.*.terminar'), ('+', 'tesouraria.despesa.ler'), ('+', 'tesouraria.despesa.criar'),
   ('+', 'tesouraria.documento.criar'), ('+', 'tesouraria.documento.ler'),
   ('+', 'secretaria.membro.ler'), ('+', 'organizacao.igreja.ler'), ('+', 'organizacao.igreja_departamento.ler')]),
 ('MEMBRO', 'IGREJA', 'Membro: vê os seus dados, contribuições e escalas (garantido sem perfil)', []),
 ('ADMIN_ASSOCIACAO', 'ENTIDADE', 'Administração da Associação/Missão: igrejas, distritos, tabelas comuns, utilizadores', [
   ('+', 'organizacao.*'), ('+', 'nucleo.usuario.*'), ('+', 'nucleo.usuario_igreja.*'), ('+', 'nucleo.usuario_entidade.*'),
   ('+', 'escola_sabatina.trimestre.*'), ('+', 'escola_sabatina.sabado.*'), ('+', 'escola_sabatina.pontuacao_config.*'),
   ('+', 'tesouraria.categoria.*'), ('+', 'tesouraria.fundo.*'), ('+', 'tesouraria.calendario_oferta.*'),
   ('+', 'nucleo.log_auditoria.ler'), ('+', '*.ler'), ('-', 'secretaria.disciplina.ler')]),
 ('TESOUREIRO_ASSOCIACAO', 'ENTIDADE', 'Tesoureiro(a) da Associação/Missão: lê as tesourarias e confirma remessas', [
   ('+', 'tesouraria.*.ler'), ('+', 'pagamentos.*.ler'), ('+', 'tesouraria.remessa.confirmar'), ('+', 'tesouraria.remessa.alterar'),
   ('+', 'organizacao.*.ler')]),
 ('SECRETARIO_ASSOCIACAO', 'ENTIDADE', 'Secretário(a) da Associação/Missão: lê os livros de membros e as estatísticas', [
   ('+', 'secretaria.*.ler'), ('-', 'secretaria.disciplina.ler'), ('+', 'escola_sabatina.*.ler'), ('+', 'organizacao.*.ler')]),
 ('INTEGRACAO', 'ENTIDADE', 'Conta de serviço da API (callbacks M-Pesa, envio de notificações)', [
   ('+', 'pagamentos.*'), ('-', 'pagamentos.*.terminar'), ('+', 'tesouraria.transacao.ler'), ('+', 'tesouraria.transacao.alterar'),
   ('+', 'comunicacao.notificacao.ler'), ('+', 'comunicacao.notificacao.alterar')]),
]

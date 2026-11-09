SET search_path TO nucleo, organizacao, secretaria, actividades, escola_sabatina, tesouraria, pagamentos, comunicacao, public;

-- =====================================================================
-- Dados de referência
-- =====================================================================
-- Perfis e permissões: gerados no fim deste ficheiro a partir de defs.py

-- Departamentos e ministérios da igreja local (Manual da Igreja)
INSERT INTO organizacao.departamento (dep_nome) VALUES
  ('Escola Sabatina e Ministério Pessoal'), ('Ministério Jovem'), ('Desbravadores'), ('Aventureiros'),
  ('Ministério da Mulher'), ('Ministério da Criança'), ('Ministério da Família'), ('Ministério de Saúde'),
  ('Mordomia Cristã'), ('Comunicação'), ('Educação'), ('Liberdade Religiosa'), ('Publicações'),
  ('Música'), ('Diaconato'), ('ADRA / Acção Solidária'), ('Ministério dos Homens'), ('Ministério das Possibilidades');

INSERT INTO organizacao.cargo (car_nome, car_mandato_anos) VALUES
  ('Ancião', 1), ('Diácono', 1), ('Diaconisa', 1), ('Secretário(a) da igreja', 1), ('Tesoureiro(a)', 1),
  ('Tesoureiro(a) adjunto(a)', 1), ('Secretário(a) da junta', 1);
INSERT INTO organizacao.cargo (car_nome, car_mandato_anos, car_dep_id)
SELECT x.nome, 1, d.dep_id FROM (VALUES
  ('Director(a) da Escola Sabatina', 'Escola Sabatina e Ministério Pessoal'),
  ('Secretário(a) da Escola Sabatina', 'Escola Sabatina e Ministério Pessoal'),
  ('Director(a) do Ministério Pessoal', 'Escola Sabatina e Ministério Pessoal'),
  ('Director(a) de Jovens', 'Ministério Jovem'),
  ('Director(a) de Desbravadores', 'Desbravadores'),
  ('Director(a) de Aventureiros', 'Aventureiros'),
  ('Director(a) do Ministério da Mulher', 'Ministério da Mulher'),
  ('Director(a) do Ministério da Criança', 'Ministério da Criança'),
  ('Director(a) de Mordomia', 'Mordomia Cristã'),
  ('Director(a) de Comunicação', 'Comunicação'),
  ('Director(a) de Música', 'Música')) x(nome, dep)
JOIN organizacao.departamento d ON d.dep_nome = x.dep;

INSERT INTO escola_sabatina.pontuacao_config (epc_etr_id) VALUES (NULL);

INSERT INTO tesouraria.categoria (cat_codigo, cat_nome, cat_tipo, cat_e_remessa) VALUES
  ('R1', 'Dízimos',                         'RECEITA', FALSE),
  ('R2', 'Ofertas',                         'RECEITA', FALSE),
  ('R3', 'Ofertas da Escola Sabatina',      'RECEITA', FALSE),
  ('R4', 'Doações para projectos',          'RECEITA', FALSE),
  ('R9', 'Outras receitas',                 'RECEITA', FALSE),
  ('D1', 'Remessas à Associação/Missão',    'DESPESA', TRUE),
  ('D2', 'Água, luz e comunicações',        'DESPESA', FALSE),
  ('D3', 'Manutenção e obras',              'DESPESA', FALSE),
  ('D4', 'Actividades de departamentos',    'DESPESA', FALSE),
  ('D5', 'Assistência social',              'DESPESA', FALSE),
  ('D6', 'Material e literatura',           'DESPESA', FALSE),
  ('D7', 'Taxas bancárias e M-Pesa',        'DESPESA', FALSE),
  ('D8', 'Despesas da Escola Sabatina',     'DESPESA', FALSE),
  ('D9', 'Outras despesas',                 'DESPESA', FALSE);

-- ---------------------------------------------------------------- permissões (geradas)
INSERT INTO nucleo.permissao (prm_codigo, prm_descricao) VALUES
  ('nucleo.perfil.criar', 'Criar: Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.perfil.alterar', 'Alterar: Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.perfil.terminar', 'Terminar (end_date): Perfis de acesso (Admin, Secretário, Tesoureiro, ...)'),
  ('nucleo.permissao.criar', 'Criar: Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.permissao.alterar', 'Alterar: Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.permissao.terminar', 'Terminar (end_date): Permissões elementares (ex.: transacao.aprovar)'),
  ('nucleo.perfil_permissao.criar', 'Criar: Que permissões cada perfil tem'),
  ('nucleo.perfil_permissao.alterar', 'Alterar: Que permissões cada perfil tem'),
  ('nucleo.perfil_permissao.terminar', 'Terminar (end_date): Que permissões cada perfil tem'),
  ('nucleo.usuario.ler', 'Ler: Contas de acesso ao sistema'),
  ('nucleo.usuario.criar', 'Criar: Contas de acesso ao sistema'),
  ('nucleo.usuario.alterar', 'Alterar: Contas de acesso ao sistema'),
  ('nucleo.usuario.terminar', 'Terminar (end_date): Contas de acesso ao sistema'),
  ('nucleo.usuario_igreja.ler', 'Ler: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.criar', 'Criar: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.alterar', 'Alterar: Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_igreja.terminar', 'Terminar (end_date): Perfil de cada utilizador em cada igreja (base da segurança por igreja)'),
  ('nucleo.usuario_entidade.ler', 'Ler: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.criar', 'Criar: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.alterar', 'Alterar: Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.usuario_entidade.terminar', 'Terminar (end_date): Perfil de um utilizador numa Associação/Missão inteira (vale para todas as igrejas abaixo dela)'),
  ('nucleo.log_auditoria.ler', 'Ler: Histórico de alterações (só os campos que mudaram); particionado por mês'),
  ('organizacao.entidade.criar', 'Criar: Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.entidade.alterar', 'Alterar: Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.entidade.terminar', 'Terminar (end_date): Níveis da organização: Conferência Geral, Divisão, União, Associação, Missão'),
  ('organizacao.distrito.criar', 'Criar: Distritos pastorais de uma Associação/Missão'),
  ('organizacao.distrito.alterar', 'Alterar: Distritos pastorais de uma Associação/Missão'),
  ('organizacao.distrito.terminar', 'Terminar (end_date): Distritos pastorais de uma Associação/Missão'),
  ('organizacao.igreja.ler', 'Ler: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.criar', 'Criar: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.alterar', 'Alterar: Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.igreja.terminar', 'Terminar (end_date): Igrejas organizadas, grupos organizados e grupos/filiais'),
  ('organizacao.departamento.criar', 'Criar: Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.departamento.alterar', 'Alterar: Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.departamento.terminar', 'Terminar (end_date): Departamentos e ministérios (Manual da Igreja)'),
  ('organizacao.igreja_departamento.ler', 'Ler: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.criar', 'Criar: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.alterar', 'Alterar: Departamento a funcionar numa igreja'),
  ('organizacao.igreja_departamento.terminar', 'Terminar (end_date): Departamento a funcionar numa igreja'),
  ('organizacao.cargo.criar', 'Criar: Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('organizacao.cargo.alterar', 'Alterar: Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('organizacao.cargo.terminar', 'Terminar (end_date): Cargos da igreja (Ancião, Secretário, Tesoureiro, Director da ES, ...)'),
  ('secretaria.familia.ler', 'Ler: Agregados familiares'),
  ('secretaria.familia.criar', 'Criar: Agregados familiares'),
  ('secretaria.familia.alterar', 'Alterar: Agregados familiares'),
  ('secretaria.familia.terminar', 'Terminar (end_date): Agregados familiares'),
  ('secretaria.membro.ler', 'Ler: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.criar', 'Criar: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.alterar', 'Alterar: Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.membro.terminar', 'Terminar (end_date): Membros, interessados e visitantes regulares (estado muda só por movimento)'),
  ('secretaria.contacto.ler', 'Ler: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.criar', 'Criar: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.alterar', 'Alterar: Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.contacto.terminar', 'Terminar (end_date): Telefones, e-mails e WhatsApp de membros ou igrejas'),
  ('secretaria.consentimento.ler', 'Ler: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.criar', 'Criar: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.alterar', 'Alterar: Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.consentimento.terminar', 'Terminar (end_date): Consentimentos para tratamento de dados (menores: dado pelo encarregado)'),
  ('secretaria.reuniao.ler', 'Ler: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.criar', 'Criar: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.alterar', 'Alterar: Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.reuniao.terminar', 'Terminar (end_date): Reuniões: junta directiva, reunião regular, assembleia administrativa, comissão de nomeações, conselho da ES'),
  ('secretaria.voto.ler', 'Ler: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.criar', 'Criar: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.alterar', 'Alterar: Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.voto.terminar', 'Terminar (end_date): Votos registados em acta (admissões, transferências, remoções, eleições, finanças)'),
  ('secretaria.movimento_membro.ler', 'Ler: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.criar', 'Criar: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.alterar', 'Alterar: Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.movimento_membro.terminar', 'Terminar (end_date): Livro de membros: cada entrada e saída, com o voto que a autoriza'),
  ('secretaria.transferencia_membro.ler', 'Ler: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.criar', 'Criar: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.alterar', 'Alterar: Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.transferencia_membro.terminar', 'Terminar (end_date): Cartas de transferência (válidas 6 meses; o membro só sai quando o destino aceita)'),
  ('secretaria.disciplina.ler', 'Ler: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.criar', 'Criar: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.alterar', 'Alterar: Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.disciplina.terminar', 'Terminar (end_date): Censuras (1 a 12 meses): sem cargos nem carta de transferência durante a censura'),
  ('secretaria.oficial.ler', 'Ler: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.criar', 'Criar: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.alterar', 'Alterar: Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.oficial.terminar', 'Terminar (end_date): Eleições e mandatos: quem ocupou que cargo e quando'),
  ('secretaria.baptismo.ler', 'Ler: Baptismos e rebaptismos'),
  ('secretaria.baptismo.criar', 'Criar: Baptismos e rebaptismos'),
  ('secretaria.baptismo.alterar', 'Alterar: Baptismos e rebaptismos'),
  ('secretaria.baptismo.terminar', 'Terminar (end_date): Baptismos e rebaptismos'),
  ('actividades.actividade.ler', 'Ler: Actividades e eventos dos departamentos'),
  ('actividades.actividade.criar', 'Criar: Actividades e eventos dos departamentos'),
  ('actividades.actividade.alterar', 'Alterar: Actividades e eventos dos departamentos'),
  ('actividades.actividade.terminar', 'Terminar (end_date): Actividades e eventos dos departamentos'),
  ('actividades.material.ler', 'Ler: Material necessário para uma actividade'),
  ('actividades.material.criar', 'Criar: Material necessário para uma actividade'),
  ('actividades.material.alterar', 'Alterar: Material necessário para uma actividade'),
  ('actividades.material.terminar', 'Terminar (end_date): Material necessário para uma actividade'),
  ('actividades.escala.ler', 'Ler: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.criar', 'Criar: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.alterar', 'Alterar: Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('actividades.escala.terminar', 'Terminar (end_date): Escalas de serviço (pregador, diáconos, recepção, ...)'),
  ('escola_sabatina.trimestre.criar', 'Criar: Trimestres da lição'),
  ('escola_sabatina.trimestre.alterar', 'Alterar: Trimestres da lição'),
  ('escola_sabatina.trimestre.terminar', 'Terminar (end_date): Trimestres da lição'),
  ('escola_sabatina.sabado.criar', 'Criar: Sábados de cada trimestre'),
  ('escola_sabatina.sabado.alterar', 'Alterar: Sábados de cada trimestre'),
  ('escola_sabatina.sabado.terminar', 'Terminar (end_date): Sábados de cada trimestre'),
  ('escola_sabatina.classe.ler', 'Ler: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.criar', 'Criar: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.alterar', 'Alterar: Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe.terminar', 'Terminar (end_date): Classes / unidades de acção, por divisão da Escola Sabatina'),
  ('escola_sabatina.classe_trimestre.ler', 'Ler: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.criar', 'Criar: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.alterar', 'Alterar: Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.classe_trimestre.terminar', 'Terminar (end_date): Classe num trimestre: professor e alvos (ACTIVO/INACTIVO = Activo/Desactivado da planilha)'),
  ('escola_sabatina.matricula.ler', 'Ler: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.criar', 'Criar: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.alterar', 'Alterar: Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.matricula.terminar', 'Terminar (end_date): Inscrição nas classes (histórico); membros e não membros'),
  ('escola_sabatina.relatorio_sabado.ler', 'Ler: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.criar', 'Criar: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.alterar', 'Alterar: Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.relatorio_sabado.terminar', 'Terminar (end_date): Relatório de cada classe em cada sábado (linha da folha "Grupo N")'),
  ('escola_sabatina.presenca.ler', 'Ler: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.criar', 'Criar: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.alterar', 'Alterar: Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.presenca.terminar', 'Terminar (end_date): Chamada nominal (opcional); actualiza M.P. e E.D. do relatório'),
  ('escola_sabatina.visitante.ler', 'Ler: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.criar', 'Criar: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.alterar', 'Alterar: Visitantes com contacto para seguimento'),
  ('escola_sabatina.visitante.terminar', 'Terminar (end_date): Visitantes com contacto para seguimento'),
  ('escola_sabatina.pontuacao_config.criar', 'Criar: Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('escola_sabatina.pontuacao_config.alterar', 'Alterar: Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('escola_sabatina.pontuacao_config.terminar', 'Terminar (end_date): Pesos da pontuação (sem trimestre = pesos por defeito)'),
  ('tesouraria.conta_financeira.ler', 'Ler: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.criar', 'Criar: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.alterar', 'Alterar: Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.conta_financeira.terminar', 'Terminar (end_date): Contas onde o dinheiro está (M-Pesa, banco, caixa)'),
  ('tesouraria.fundo.ler', 'Ler: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.criar', 'Criar: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.alterar', 'Alterar: Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.fundo.terminar', 'Terminar (end_date): Fundos: da Associação (dízimo, ofertas missionárias, 13º sábado) ou locais'),
  ('tesouraria.calendario_oferta.criar', 'Criar: Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.calendario_oferta.alterar', 'Alterar: Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.calendario_oferta.terminar', 'Terminar (end_date): Calendário de ofertas especiais definido pela Divisão/União/Associação'),
  ('tesouraria.categoria.criar', 'Criar: Plano de contas: categorias de receita e despesa'),
  ('tesouraria.categoria.alterar', 'Alterar: Plano de contas: categorias de receita e despesa'),
  ('tesouraria.categoria.terminar', 'Terminar (end_date): Plano de contas: categorias de receita e despesa'),
  ('tesouraria.alvo.ler', 'Ler: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.criar', 'Criar: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.alterar', 'Alterar: Alvos de arrecadação por fundo'),
  ('tesouraria.alvo.terminar', 'Terminar (end_date): Alvos de arrecadação por fundo'),
  ('tesouraria.orcamento.ler', 'Ler: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.criar', 'Criar: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.alterar', 'Alterar: Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento.terminar', 'Terminar (end_date): Orçamento anual da igreja local (aprovado pela igreja)'),
  ('tesouraria.orcamento_linha.ler', 'Ler: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.criar', 'Criar: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.alterar', 'Alterar: Valor previsto por categoria'),
  ('tesouraria.orcamento_linha.terminar', 'Terminar (end_date): Valor previsto por categoria'),
  ('tesouraria.despesa.ler', 'Ler: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.criar', 'Criar: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.alterar', 'Alterar: Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.despesa.terminar', 'Terminar (end_date): Requisições de despesa (quem pede não aprova)'),
  ('tesouraria.contagem_numerario.ler', 'Ler: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.criar', 'Criar: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.alterar', 'Alterar: Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.contagem_numerario.terminar', 'Terminar (end_date): Contagem do dinheiro de um culto (tesoureiro e diácono: dois contadores)'),
  ('tesouraria.transacao.ler', 'Ler: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.criar', 'Criar: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.alterar', 'Alterar: Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao.terminar', 'Terminar (end_date): Movimentos: entradas, saídas e transferências (cabeçalho)'),
  ('tesouraria.transacao_linha.ler', 'Ler: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.criar', 'Criar: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.alterar', 'Alterar: Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.transacao_linha.terminar', 'Terminar (end_date): Divisão do valor por fundo e categoria (soma = valor_total)'),
  ('tesouraria.saldo_diario_conta.ler', 'Ler: Saldo pré-calculado por conta e dia (mantido por triggers; não editar)'),
  ('tesouraria.saldo_diario_fundo.ler', 'Ler: Totais pré-calculados por igreja, fundo, moeda e dia (mantido por triggers; não editar)'),
  ('tesouraria.recibo.ler', 'Ler: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.criar', 'Criar: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.alterar', 'Alterar: Recibos numerados por igreja e ano'),
  ('tesouraria.recibo.terminar', 'Terminar (end_date): Recibos numerados por igreja e ano'),
  ('tesouraria.documento.ler', 'Ler: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.criar', 'Criar: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.alterar', 'Alterar: Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.documento.terminar', 'Terminar (end_date): Comprovativos (facturas, talões, prints M-Pesa)'),
  ('tesouraria.remessa.ler', 'Ler: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.criar', 'Criar: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.alterar', 'Alterar: Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa.terminar', 'Terminar (end_date): Remessas mensais à Associação/Missão'),
  ('tesouraria.remessa_linha.ler', 'Ler: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.criar', 'Criar: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.alterar', 'Alterar: Valor remetido por fundo'),
  ('tesouraria.remessa_linha.terminar', 'Terminar (end_date): Valor remetido por fundo'),
  ('tesouraria.fecho_periodo.ler', 'Ler: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.criar', 'Criar: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.alterar', 'Alterar: Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.fecho_periodo.terminar', 'Terminar (end_date): Meses fechados: movimentos bloqueados (reabrir = preencher end_date)'),
  ('tesouraria.extrato_linha.ler', 'Ler: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.criar', 'Criar: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.alterar', 'Alterar: Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('tesouraria.extrato_linha.terminar', 'Terminar (end_date): Linhas do extracto bancário/M-Pesa para reconciliação'),
  ('pagamentos.pagamento_mpesa.ler', 'Ler: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.criar', 'Criar: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.alterar', 'Alterar: Pedido e resposta da API M-Pesa'),
  ('pagamentos.pagamento_mpesa.terminar', 'Terminar (end_date): Pedido e resposta da API M-Pesa'),
  ('pagamentos.mpesa_callback_log.ler', 'Ler: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.criar', 'Criar: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.alterar', 'Alterar: Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.mpesa_callback_log.terminar', 'Terminar (end_date): Tudo o que a API M-Pesa envia, em bruto (callbacks repetidos são ignorados)'),
  ('pagamentos.pagamento_bancario.ler', 'Ler: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.criar', 'Criar: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.alterar', 'Alterar: Detalhe de pagamentos por banco'),
  ('pagamentos.pagamento_bancario.terminar', 'Terminar (end_date): Detalhe de pagamentos por banco'),
  ('comunicacao.notificacao.ler', 'Ler: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.criar', 'Criar: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.alterar', 'Alterar: Fila de SMS, WhatsApp e e-mail a enviar'),
  ('comunicacao.notificacao.terminar', 'Terminar (end_date): Fila de SMS, WhatsApp e e-mail a enviar'),
  ('secretaria.membro.validar', 'Aprovar o registo de um membro'),
  ('secretaria.transferencia_membro.emitir_carta', 'Emitir a carta de transferência (igreja de origem)'),
  ('secretaria.transferencia_membro.aceitar', 'Concluir a transferência (igreja de destino)'),
  ('tesouraria.transacao.aprovar', 'Aprovar uma saída de dinheiro'),
  ('tesouraria.despesa.aprovar', 'Aprovar ou rejeitar requisições de despesa'),
  ('tesouraria.orcamento.aprovar', 'Marcar o orçamento como aprovado'),
  ('tesouraria.remessa.confirmar', 'Confirmar a recepção de uma remessa (Associação)'),
  ('escola_sabatina.relatorio_sabado.fechar', 'Fechar o relatório do sábado'),
  ('escola_sabatina.relatorio_sabado.reabrir', 'Reabrir um relatório fechado');

-- ---------------------------------------------------------------- perfis (gerados)
INSERT INTO nucleo.perfil (per_nome, per_ambito, per_descricao) VALUES
  ('ADMIN', 'IGREJA', 'Administrador do sistema na igreja (não vê a disciplina)'),
  ('PASTOR', 'IGREJA', 'Pastor: lê tudo da igreja, gere a secretaria e a disciplina, aprova despesas'),
  ('ANCIAO', 'IGREJA', 'Ancião: aprova saídas e despesas, fecha e reabre meses, reuniões e votos'),
  ('SECRETARIO', 'IGREJA', 'Secretário(a) da igreja: livro de membros, reuniões, votos, transferências, disciplina'),
  ('TESOUREIRO', 'IGREJA', 'Tesoureiro(a): movimentos, recibos, contagens, despesas, remessas (não aprova o que regista)'),
  ('DIRECTOR_ES', 'IGREJA', 'Director(a) da Escola Sabatina: classes, alvos, relatórios'),
  ('SECRETARIO_ES', 'IGREJA', 'Secretário(a) da Escola Sabatina: relatórios do sábado e chamada'),
  ('DIRECTOR_DEPARTAMENTO', 'IGREJA', 'Director(a) de departamento: actividades, material, escalas, pedir despesas'),
  ('MEMBRO', 'IGREJA', 'Membro: vê os seus dados, contribuições e escalas (garantido sem perfil)'),
  ('ADMIN_ASSOCIACAO', 'ENTIDADE', 'Administração da Associação/Missão: igrejas, distritos, tabelas comuns, utilizadores'),
  ('TESOUREIRO_ASSOCIACAO', 'ENTIDADE', 'Tesoureiro(a) da Associação/Missão: lê as tesourarias e confirma remessas'),
  ('SECRETARIO_ASSOCIACAO', 'ENTIDADE', 'Secretário(a) da Associação/Missão: lê os livros de membros e as estatísticas'),
  ('INTEGRACAO', 'ENTIDADE', 'Conta de serviço da API (callbacks M-Pesa, envio de notificações)');

-- ADMIN: 183 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'comunicacao.notificacao.alterar', 'comunicacao.notificacao.criar', 'comunicacao.notificacao.ler', 'comunicacao.notificacao.terminar', 'escola_sabatina.classe.alterar', 'escola_sabatina.classe.criar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe.terminar', 'escola_sabatina.classe_trimestre.alterar', 'escola_sabatina.classe_trimestre.criar', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.classe_trimestre.terminar', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.relatorio_sabado.terminar', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'nucleo.usuario.alterar', 'nucleo.usuario.criar', 'nucleo.usuario.ler', 'nucleo.usuario.terminar', 'nucleo.usuario_igreja.alterar', 'nucleo.usuario_igreja.criar', 'nucleo.usuario_igreja.ler', 'nucleo.usuario_igreja.terminar', 'organizacao.igreja.alterar', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.alterar', 'organizacao.igreja_departamento.criar', 'organizacao.igreja_departamento.ler', 'organizacao.igreja_departamento.terminar', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.mpesa_callback_log.terminar', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_bancario.terminar', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'pagamentos.pagamento_mpesa.terminar', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.alterar', 'tesouraria.alvo.criar', 'tesouraria.alvo.ler', 'tesouraria.alvo.terminar', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.alterar', 'tesouraria.conta_financeira.criar', 'tesouraria.conta_financeira.ler', 'tesouraria.conta_financeira.terminar', 'tesouraria.contagem_numerario.alterar', 'tesouraria.contagem_numerario.criar', 'tesouraria.contagem_numerario.ler', 'tesouraria.contagem_numerario.terminar', 'tesouraria.despesa.alterar', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.despesa.terminar', 'tesouraria.documento.alterar', 'tesouraria.documento.criar', 'tesouraria.documento.ler', 'tesouraria.documento.terminar', 'tesouraria.extrato_linha.alterar', 'tesouraria.extrato_linha.criar', 'tesouraria.extrato_linha.ler', 'tesouraria.extrato_linha.terminar', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fecho_periodo.terminar', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.criar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento.terminar', 'tesouraria.orcamento_linha.alterar', 'tesouraria.orcamento_linha.criar', 'tesouraria.orcamento_linha.ler', 'tesouraria.orcamento_linha.terminar', 'tesouraria.recibo.alterar', 'tesouraria.recibo.criar', 'tesouraria.recibo.ler', 'tesouraria.recibo.terminar', 'tesouraria.remessa.alterar', 'tesouraria.remessa.criar', 'tesouraria.remessa.ler', 'tesouraria.remessa.terminar', 'tesouraria.remessa_linha.alterar', 'tesouraria.remessa_linha.criar', 'tesouraria.remessa_linha.ler', 'tesouraria.remessa_linha.terminar', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.criar', 'tesouraria.transacao.ler', 'tesouraria.transacao.terminar', 'tesouraria.transacao_linha.alterar', 'tesouraria.transacao_linha.criar', 'tesouraria.transacao_linha.ler', 'tesouraria.transacao_linha.terminar');

-- PASTOR: 94 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'PASTOR'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'comunicacao.notificacao.ler', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'nucleo.usuario.ler', 'nucleo.usuario_entidade.ler', 'nucleo.usuario_igreja.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.disciplina.alterar', 'secretaria.disciplina.criar', 'secretaria.disciplina.ler', 'secretaria.disciplina.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.membro.validar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.aceitar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.emitir_carta', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.aprovar', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.ler', 'tesouraria.orcamento.aprovar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.aprovar', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- ANCIAO: 63 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ANCIAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.actividade.terminar', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'actividades.material.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'nucleo.usuario_igreja.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.disciplina.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.ler', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.alterar', 'tesouraria.despesa.aprovar', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fecho_periodo.terminar', 'tesouraria.fundo.ler', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.aprovar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.aprovar', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- SECRETARIO: 59 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.alterar', 'secretaria.baptismo.criar', 'secretaria.baptismo.ler', 'secretaria.baptismo.terminar', 'secretaria.consentimento.alterar', 'secretaria.consentimento.criar', 'secretaria.consentimento.ler', 'secretaria.consentimento.terminar', 'secretaria.contacto.alterar', 'secretaria.contacto.criar', 'secretaria.contacto.ler', 'secretaria.contacto.terminar', 'secretaria.disciplina.alterar', 'secretaria.disciplina.criar', 'secretaria.disciplina.ler', 'secretaria.disciplina.terminar', 'secretaria.familia.alterar', 'secretaria.familia.criar', 'secretaria.familia.ler', 'secretaria.familia.terminar', 'secretaria.membro.alterar', 'secretaria.membro.criar', 'secretaria.membro.ler', 'secretaria.membro.terminar', 'secretaria.membro.validar', 'secretaria.movimento_membro.alterar', 'secretaria.movimento_membro.criar', 'secretaria.movimento_membro.ler', 'secretaria.movimento_membro.terminar', 'secretaria.oficial.alterar', 'secretaria.oficial.criar', 'secretaria.oficial.ler', 'secretaria.oficial.terminar', 'secretaria.reuniao.alterar', 'secretaria.reuniao.criar', 'secretaria.reuniao.ler', 'secretaria.reuniao.terminar', 'secretaria.transferencia_membro.aceitar', 'secretaria.transferencia_membro.alterar', 'secretaria.transferencia_membro.criar', 'secretaria.transferencia_membro.emitir_carta', 'secretaria.transferencia_membro.ler', 'secretaria.transferencia_membro.terminar', 'secretaria.voto.alterar', 'secretaria.voto.criar', 'secretaria.voto.ler', 'secretaria.voto.terminar');

-- TESOUREIRO: 92 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'TESOUREIRO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.ler', 'comunicacao.notificacao.alterar', 'comunicacao.notificacao.criar', 'comunicacao.notificacao.ler', 'comunicacao.notificacao.terminar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.relatorio_sabado.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.mpesa_callback_log.terminar', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_bancario.terminar', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'pagamentos.pagamento_mpesa.terminar', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'tesouraria.alvo.alterar', 'tesouraria.alvo.criar', 'tesouraria.alvo.ler', 'tesouraria.alvo.terminar', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.alterar', 'tesouraria.conta_financeira.criar', 'tesouraria.conta_financeira.ler', 'tesouraria.conta_financeira.terminar', 'tesouraria.contagem_numerario.alterar', 'tesouraria.contagem_numerario.criar', 'tesouraria.contagem_numerario.ler', 'tesouraria.contagem_numerario.terminar', 'tesouraria.despesa.alterar', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.despesa.terminar', 'tesouraria.documento.alterar', 'tesouraria.documento.criar', 'tesouraria.documento.ler', 'tesouraria.documento.terminar', 'tesouraria.extrato_linha.alterar', 'tesouraria.extrato_linha.criar', 'tesouraria.extrato_linha.ler', 'tesouraria.extrato_linha.terminar', 'tesouraria.fecho_periodo.alterar', 'tesouraria.fecho_periodo.criar', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.alterar', 'tesouraria.orcamento.criar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento.terminar', 'tesouraria.orcamento_linha.alterar', 'tesouraria.orcamento_linha.criar', 'tesouraria.orcamento_linha.ler', 'tesouraria.orcamento_linha.terminar', 'tesouraria.recibo.alterar', 'tesouraria.recibo.criar', 'tesouraria.recibo.ler', 'tesouraria.recibo.terminar', 'tesouraria.remessa.alterar', 'tesouraria.remessa.criar', 'tesouraria.remessa.ler', 'tesouraria.remessa.terminar', 'tesouraria.remessa_linha.alterar', 'tesouraria.remessa_linha.criar', 'tesouraria.remessa_linha.ler', 'tesouraria.remessa_linha.terminar', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.criar', 'tesouraria.transacao.ler', 'tesouraria.transacao.terminar', 'tesouraria.transacao_linha.alterar', 'tesouraria.transacao_linha.criar', 'tesouraria.transacao_linha.ler', 'tesouraria.transacao_linha.terminar');

-- DIRECTOR_ES: 42 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_ES'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.escala.terminar', 'escola_sabatina.classe.alterar', 'escola_sabatina.classe.criar', 'escola_sabatina.classe.ler', 'escola_sabatina.classe.terminar', 'escola_sabatina.classe_trimestre.alterar', 'escola_sabatina.classe_trimestre.criar', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.classe_trimestre.terminar', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.fechar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.relatorio_sabado.reabrir', 'escola_sabatina.relatorio_sabado.terminar', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'organizacao.igreja.ler', 'secretaria.baptismo.ler', 'secretaria.membro.ler');

-- SECRETARIO_ES: 20 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO_ES'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.alterar', 'escola_sabatina.matricula.criar', 'escola_sabatina.matricula.ler', 'escola_sabatina.matricula.terminar', 'escola_sabatina.presenca.alterar', 'escola_sabatina.presenca.criar', 'escola_sabatina.presenca.ler', 'escola_sabatina.presenca.terminar', 'escola_sabatina.relatorio_sabado.alterar', 'escola_sabatina.relatorio_sabado.criar', 'escola_sabatina.relatorio_sabado.fechar', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.alterar', 'escola_sabatina.visitante.criar', 'escola_sabatina.visitante.ler', 'escola_sabatina.visitante.terminar', 'organizacao.igreja.ler', 'secretaria.membro.ler');

-- DIRECTOR_DEPARTAMENTO: 16 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'DIRECTOR_DEPARTAMENTO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.alterar', 'actividades.actividade.criar', 'actividades.actividade.ler', 'actividades.escala.alterar', 'actividades.escala.criar', 'actividades.escala.ler', 'actividades.material.alterar', 'actividades.material.criar', 'actividades.material.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.membro.ler', 'tesouraria.despesa.criar', 'tesouraria.despesa.ler', 'tesouraria.documento.criar', 'tesouraria.documento.ler');

-- ADMIN_ASSOCIACAO: 91 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'ADMIN_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('actividades.actividade.ler', 'actividades.escala.ler', 'actividades.material.ler', 'comunicacao.notificacao.ler', 'escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.pontuacao_config.alterar', 'escola_sabatina.pontuacao_config.criar', 'escola_sabatina.pontuacao_config.terminar', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.sabado.alterar', 'escola_sabatina.sabado.criar', 'escola_sabatina.sabado.terminar', 'escola_sabatina.trimestre.alterar', 'escola_sabatina.trimestre.criar', 'escola_sabatina.trimestre.terminar', 'escola_sabatina.visitante.ler', 'nucleo.log_auditoria.ler', 'nucleo.usuario.alterar', 'nucleo.usuario.criar', 'nucleo.usuario.ler', 'nucleo.usuario.terminar', 'nucleo.usuario_entidade.alterar', 'nucleo.usuario_entidade.criar', 'nucleo.usuario_entidade.ler', 'nucleo.usuario_entidade.terminar', 'nucleo.usuario_igreja.alterar', 'nucleo.usuario_igreja.criar', 'nucleo.usuario_igreja.ler', 'nucleo.usuario_igreja.terminar', 'organizacao.cargo.alterar', 'organizacao.cargo.criar', 'organizacao.cargo.terminar', 'organizacao.departamento.alterar', 'organizacao.departamento.criar', 'organizacao.departamento.terminar', 'organizacao.distrito.alterar', 'organizacao.distrito.criar', 'organizacao.distrito.terminar', 'organizacao.entidade.alterar', 'organizacao.entidade.criar', 'organizacao.entidade.terminar', 'organizacao.igreja.alterar', 'organizacao.igreja.criar', 'organizacao.igreja.ler', 'organizacao.igreja.terminar', 'organizacao.igreja_departamento.alterar', 'organizacao.igreja_departamento.criar', 'organizacao.igreja_departamento.ler', 'organizacao.igreja_departamento.terminar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.ler', 'secretaria.transferencia_membro.ler', 'secretaria.voto.ler', 'tesouraria.alvo.ler', 'tesouraria.calendario_oferta.alterar', 'tesouraria.calendario_oferta.criar', 'tesouraria.calendario_oferta.terminar', 'tesouraria.categoria.alterar', 'tesouraria.categoria.criar', 'tesouraria.categoria.terminar', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.alterar', 'tesouraria.fundo.criar', 'tesouraria.fundo.ler', 'tesouraria.fundo.terminar', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- TESOUREIRO_ASSOCIACAO: 24 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'TESOUREIRO_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.ler', 'tesouraria.alvo.ler', 'tesouraria.conta_financeira.ler', 'tesouraria.contagem_numerario.ler', 'tesouraria.despesa.ler', 'tesouraria.documento.ler', 'tesouraria.extrato_linha.ler', 'tesouraria.fecho_periodo.ler', 'tesouraria.fundo.ler', 'tesouraria.orcamento.ler', 'tesouraria.orcamento_linha.ler', 'tesouraria.recibo.ler', 'tesouraria.remessa.alterar', 'tesouraria.remessa.confirmar', 'tesouraria.remessa.ler', 'tesouraria.remessa_linha.ler', 'tesouraria.saldo_diario_conta.ler', 'tesouraria.saldo_diario_fundo.ler', 'tesouraria.transacao.ler', 'tesouraria.transacao_linha.ler');

-- SECRETARIO_ASSOCIACAO: 18 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'SECRETARIO_ASSOCIACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('escola_sabatina.classe.ler', 'escola_sabatina.classe_trimestre.ler', 'escola_sabatina.matricula.ler', 'escola_sabatina.presenca.ler', 'escola_sabatina.relatorio_sabado.ler', 'escola_sabatina.visitante.ler', 'organizacao.igreja.ler', 'organizacao.igreja_departamento.ler', 'secretaria.baptismo.ler', 'secretaria.consentimento.ler', 'secretaria.contacto.ler', 'secretaria.familia.ler', 'secretaria.membro.ler', 'secretaria.movimento_membro.ler', 'secretaria.oficial.ler', 'secretaria.reuniao.ler', 'secretaria.transferencia_membro.ler', 'secretaria.voto.ler');

-- INTEGRACAO: 13 permissões
INSERT INTO nucleo.perfil_permissao (ppe_per_id, ppe_prm_id)
SELECT (SELECT per_id FROM nucleo.perfil WHERE per_nome = 'INTEGRACAO'), prm_id FROM nucleo.permissao
WHERE prm_codigo IN ('comunicacao.notificacao.alterar', 'comunicacao.notificacao.ler', 'pagamentos.mpesa_callback_log.alterar', 'pagamentos.mpesa_callback_log.criar', 'pagamentos.mpesa_callback_log.ler', 'pagamentos.pagamento_bancario.alterar', 'pagamentos.pagamento_bancario.criar', 'pagamentos.pagamento_bancario.ler', 'pagamentos.pagamento_mpesa.alterar', 'pagamentos.pagamento_mpesa.criar', 'pagamentos.pagamento_mpesa.ler', 'tesouraria.transacao.alterar', 'tesouraria.transacao.ler');

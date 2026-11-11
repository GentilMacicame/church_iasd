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

INSERT INTO organizacao.cargo (car_nome, car_mandato_anos, car_conselho) VALUES
  ('Ancião', 1, TRUE), ('Diácono', 1, TRUE), ('Diaconisa', 1, TRUE), ('Secretário(a) da igreja', 1, TRUE), ('Tesoureiro(a)', 1, TRUE),
  ('Tesoureiro(a) adjunto(a)', 1, FALSE), ('Secretário(a) da junta', 1, TRUE), ('Vogal do conselho', 1, TRUE);
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
-- os directores de departamento fazem parte do conselho (menos o secretário da ES e a música)
UPDATE organizacao.cargo SET car_conselho = TRUE
 WHERE car_dep_id IS NOT NULL AND car_nome NOT IN ('Secretário(a) da Escola Sabatina', 'Director(a) de Música');

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

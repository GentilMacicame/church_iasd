-- Divisão administrativa de Moçambique (V26): as 11 províncias (com a Cidade de Maputo) e os seus distritos
-- (na Cidade de Maputo, os distritos municipais). Lista de referência: a Associação/Missão pode acrescentar ou
-- corrigir em Administração (permissões organizacao.provincia.* / organizacao.distrito_administrativo.*).
INSERT INTO organizacao.provincia (prv_nome, prv_codigo) VALUES
  ('Niassa', 'NSA'), ('Cabo Delgado', 'CDG'), ('Nampula', 'NPL'), ('Zambézia', 'ZBZ'), ('Tete', 'TTE'),
  ('Manica', 'MNC'), ('Sofala', 'SFL'), ('Inhambane', 'IBN'), ('Gaza', 'GZA'), ('Maputo Província', 'MPP'),
  ('Cidade de Maputo', 'MPC');

INSERT INTO organizacao.distrito_administrativo (dad_prv_id, dad_nome)
SELECT p.prv_id, d.nome
FROM (VALUES
  ('Niassa', 'Chimbunila'), ('Niassa', 'Cidade de Lichinga'), ('Niassa', 'Cuamba'), ('Niassa', 'Lago'),
  ('Niassa', 'Majune'), ('Niassa', 'Mandimba'), ('Niassa', 'Marrupa'), ('Niassa', 'Maúa'), ('Niassa', 'Mavago'),
  ('Niassa', 'Mecanhelas'), ('Niassa', 'Mecula'), ('Niassa', 'Metarica'), ('Niassa', 'Muembe'),
  ('Niassa', 'N''gauma'), ('Niassa', 'Nipepe'), ('Niassa', 'Sanga'),
  ('Cabo Delgado', 'Ancuabe'), ('Cabo Delgado', 'Balama'), ('Cabo Delgado', 'Chiúre'), ('Cabo Delgado', 'Cidade de Pemba'),
  ('Cabo Delgado', 'Ibo'), ('Cabo Delgado', 'Macomia'), ('Cabo Delgado', 'Mecúfi'), ('Cabo Delgado', 'Meluco'),
  ('Cabo Delgado', 'Metuge'), ('Cabo Delgado', 'Mocímboa da Praia'), ('Cabo Delgado', 'Montepuez'), ('Cabo Delgado', 'Mueda'),
  ('Cabo Delgado', 'Muidumbe'), ('Cabo Delgado', 'Namuno'), ('Cabo Delgado', 'Nangade'), ('Cabo Delgado', 'Palma'),
  ('Cabo Delgado', 'Quissanga'),
  ('Nampula', 'Angoche'), ('Nampula', 'Cidade de Nampula'), ('Nampula', 'Eráti'), ('Nampula', 'Ilha de Moçambique'),
  ('Nampula', 'Lalaua'), ('Nampula', 'Larde'), ('Nampula', 'Liúpo'), ('Nampula', 'Malema'), ('Nampula', 'Meconta'),
  ('Nampula', 'Mecubúri'), ('Nampula', 'Memba'), ('Nampula', 'Mogincual'), ('Nampula', 'Mogovolas'), ('Nampula', 'Moma'),
  ('Nampula', 'Monapo'), ('Nampula', 'Mossuril'), ('Nampula', 'Muecate'), ('Nampula', 'Murrupula'),
  ('Nampula', 'Nacala-a-Velha'), ('Nampula', 'Nacala Porto'), ('Nampula', 'Nacarôa'), ('Nampula', 'Rapale'), ('Nampula', 'Ribaué'),
  ('Zambézia', 'Alto Molócuè'), ('Zambézia', 'Chinde'), ('Zambézia', 'Cidade de Quelimane'), ('Zambézia', 'Derre'),
  ('Zambézia', 'Gilé'), ('Zambézia', 'Gurué'), ('Zambézia', 'Ile'), ('Zambézia', 'Inhassunge'), ('Zambézia', 'Luabo'),
  ('Zambézia', 'Lugela'), ('Zambézia', 'Maganja da Costa'), ('Zambézia', 'Milange'), ('Zambézia', 'Mocuba'),
  ('Zambézia', 'Mocubela'), ('Zambézia', 'Molumbo'), ('Zambézia', 'Mopeia'), ('Zambézia', 'Morrumbala'),
  ('Zambézia', 'Mulevala'), ('Zambézia', 'Namacurra'), ('Zambézia', 'Namarrói'), ('Zambézia', 'Nicoadala'), ('Zambézia', 'Pebane'),
  ('Tete', 'Angónia'), ('Tete', 'Cahora-Bassa'), ('Tete', 'Changara'), ('Tete', 'Chifunde'), ('Tete', 'Chiuta'),
  ('Tete', 'Cidade de Tete'), ('Tete', 'Dôa'), ('Tete', 'Macanga'), ('Tete', 'Magoé'), ('Tete', 'Marara'),
  ('Tete', 'Marávia'), ('Tete', 'Moatize'), ('Tete', 'Mutarara'), ('Tete', 'Tsangano'), ('Tete', 'Zumbo'),
  ('Manica', 'Bárue'), ('Manica', 'Cidade de Chimoio'), ('Manica', 'Gondola'), ('Manica', 'Guro'), ('Manica', 'Macate'),
  ('Manica', 'Machaze'), ('Manica', 'Macossa'), ('Manica', 'Manica'), ('Manica', 'Mossurize'), ('Manica', 'Sussundenga'),
  ('Manica', 'Tambara'), ('Manica', 'Vanduzi'),
  ('Sofala', 'Búzi'), ('Sofala', 'Caia'), ('Sofala', 'Chemba'), ('Sofala', 'Cheringoma'), ('Sofala', 'Chibabava'),
  ('Sofala', 'Cidade da Beira'), ('Sofala', 'Dondo'), ('Sofala', 'Gorongosa'), ('Sofala', 'Machanga'),
  ('Sofala', 'Maringué'), ('Sofala', 'Marromeu'), ('Sofala', 'Muanza'), ('Sofala', 'Nhamatanda'),
  ('Inhambane', 'Cidade de Inhambane'), ('Inhambane', 'Funhalouro'), ('Inhambane', 'Govuro'), ('Inhambane', 'Homoíne'),
  ('Inhambane', 'Inharrime'), ('Inhambane', 'Inhassoro'), ('Inhambane', 'Jangamo'), ('Inhambane', 'Mabote'),
  ('Inhambane', 'Massinga'), ('Inhambane', 'Maxixe'), ('Inhambane', 'Morrumbene'), ('Inhambane', 'Panda'),
  ('Inhambane', 'Vilankulo'), ('Inhambane', 'Zavala'),
  ('Gaza', 'Bilene'), ('Gaza', 'Chibuto'), ('Gaza', 'Chicualacuala'), ('Gaza', 'Chigubo'), ('Gaza', 'Chókwè'),
  ('Gaza', 'Chongoene'), ('Gaza', 'Cidade de Xai-Xai'), ('Gaza', 'Guijá'), ('Gaza', 'Limpopo'), ('Gaza', 'Mabalane'),
  ('Gaza', 'Manjacaze'), ('Gaza', 'Mapai'), ('Gaza', 'Massangena'), ('Gaza', 'Massingir'),
  ('Maputo Província', 'Boane'), ('Maputo Província', 'Cidade da Matola'), ('Maputo Província', 'Magude'),
  ('Maputo Província', 'Manhiça'), ('Maputo Província', 'Marracuene'), ('Maputo Província', 'Matutuíne'),
  ('Maputo Província', 'Moamba'), ('Maputo Província', 'Namaacha'),
  ('Cidade de Maputo', 'KaMpfumo'), ('Cidade de Maputo', 'Nlhamankulu'), ('Cidade de Maputo', 'KaMaxakeni'),
  ('Cidade de Maputo', 'KaMavota'), ('Cidade de Maputo', 'KaMubukwana'), ('Cidade de Maputo', 'KaTembe'),
  ('Cidade de Maputo', 'KaNyaka')
) AS d(provincia, nome)
JOIN organizacao.provincia p ON p.prv_nome = d.provincia;

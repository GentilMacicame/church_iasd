-- =====================================================================
-- V24 · Nome da categoria: "Depósitos à Associação/Missão" em vez de "Remessas"
--
-- Na interface, "remessa" passou a chamar-se "depósito à Missão" (é o depósito do fim do mês na conta da
-- Missão, com o talão). A categoria do plano de contas acompanha o nome; o código (D1) e a marca de remessa
-- (cat_e_remessa) não mudam, nem os nomes técnicos (tabela remessa, rotas /remessas).
-- =====================================================================
UPDATE tesouraria.categoria SET cat_nome = 'Depósitos à Associação/Missão (remessas)'
 WHERE cat_codigo = 'D1' AND cat_nome = 'Remessas à Associação/Missão';

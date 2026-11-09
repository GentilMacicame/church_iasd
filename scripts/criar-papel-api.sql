-- Cria o utilizador com que a API se liga à base de dados (CLAUDE.md, regra 3).
-- Correr UMA vez por servidor, como administrador, depois das migrações (V11 cria app_igreja).
-- Normalmente através de scripts/criar-papel-api.sh, que lê o nome e a senha do .env
-- (BD_UTILIZADOR e BD_SENHA). Directamente:
--   psql -d "$BD_NOME" -v utilizador="$BD_UTILIZADOR" -v senha="$BD_SENHA" -f scripts/criar-papel-api.sql
CREATE ROLE :"utilizador" LOGIN PASSWORD :'senha' IN ROLE app_igreja;
ALTER ROLE :"utilizador" SET search_path = nucleo, organizacao, secretaria, actividades,
    escola_sabatina, tesouraria;

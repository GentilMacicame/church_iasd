-- Cria o utilizador com que a API se liga à base de dados (CLAUDE.md, regra 3).
-- Correr UMA vez por servidor, como super-utilizador, depois das migrações (V11 cria app_igreja):
--   psql -v senha="'a-senha-real'" -d igreja -f scripts/criar-papel-api.sql
-- A senha real vai para BD_SENHA no .env da API; nunca para o repositório.
CREATE ROLE api_igreja LOGIN PASSWORD :senha IN ROLE app_igreja;
ALTER ROLE api_igreja SET search_path = nucleo, organizacao, secretaria, actividades,
    escola_sabatina, tesouraria, pagamentos, comunicacao;

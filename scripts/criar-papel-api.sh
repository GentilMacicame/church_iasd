#!/usr/bin/env bash
# Cria o utilizador da API (BD_UTILIZADOR, com a senha BD_SENHA do .env) na base BD_NOME.
# Uma vez por servidor, depois das migrações. Se já existir, só actualiza a senha.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/carregar-env.sh
: "${BD_SENHA:?defina BD_SENHA no .env}"
utilizador="${BD_UTILIZADOR:?defina BD_UTILIZADOR no .env}"
base="${BD_NOME:?defina BD_NOME no .env}"
if echo "SELECT 1 FROM pg_roles WHERE rolname = :'utilizador';" \
     | psql -d "$base" -tA -v utilizador="$utilizador" | grep -q 1; then
  # pelo stdin: o psql só substitui :"utilizador" e :'senha' em comandos lidos de ficheiro ou do stdin
  echo "ALTER ROLE :\"utilizador\" PASSWORD :'senha';" \
    | psql -d "$base" -q -v ON_ERROR_STOP=1 -v utilizador="$utilizador" -v senha="$BD_SENHA"
  echo "Utilizador \"$utilizador\" já existia: senha actualizada."
else
  psql -d "$base" -q -v ON_ERROR_STOP=1 -v utilizador="$utilizador" -v senha="$BD_SENHA" -f scripts/criar-papel-api.sql
  echo "Utilizador \"$utilizador\" criado em $base ($PGHOST:$PGPORT)."
fi

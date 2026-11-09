#!/usr/bin/env bash
# Junta todas as migrações (por ordem de versão) num só script: database/schema_completo.sql.
# Serve para instalar de raiz com um só ficheiro (psql -d <base> -f database/schema_completo.sql) ou para ler o
# esquema inteiro. A fonte continua a ser database/migrations: correr de novo depois de cada migração nova.
set -euo pipefail
cd "$(dirname "$0")/.."
destino=database/schema_completo.sql
{
  echo "-- ====================================================================="
  echo "-- Sistema de Gestão da Igreja Adventista · esquema completo (script único)"
  echo "-- GERADO por scripts/gerar-schema-completo.sh a partir de database/migrations"
  echo "-- ($(ls database/migrations/V*__*.sql | sort -V | head -1 | xargs basename) … $(ls database/migrations/V*__*.sql | sort -V | tail -1 | xargs basename)). NÃO EDITAR À MÃO."
  echo "-- PostgreSQL 16+, como administrador; depois: scripts/criar-papel-api.sh"
  echo "-- ====================================================================="
  for f in $(ls database/migrations/V*__*.sql | sort -V); do
    echo
    echo "-- >>>>> $(basename "$f")"
    tr -d '\r' < "$f"
  done
} > "$destino"
echo "$destino: $(ls database/migrations/V*__*.sql | wc -l) migrações, $(wc -l < "$destino") linhas"

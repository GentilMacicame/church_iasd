#!/usr/bin/env bash
# Recria a base de dados local a partir das migrações (por ordem de versão).
# Uso: scripts/db-reset.sh            (usa as variáveis PG* do ambiente)
#      PGDATABASE=igreja_teste scripts/db-reset.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${PGDATABASE:-igreja}"
export PGDATABASE=postgres
psql -v ON_ERROR_STOP=1 -qc "DROP DATABASE IF EXISTS \"$DB\" WITH (FORCE)" -c "CREATE DATABASE \"$DB\""
export PGDATABASE="$DB"
for f in $(ls database/migrations/V*__*.sql | sort -V); do
  echo "→ $(basename "$f")"
  psql -v ON_ERROR_STOP=1 -q -f "$f" >/dev/null
done
echo "Base \"$DB\" criada com $(ls database/migrations/V*__*.sql | wc -l) migrações."

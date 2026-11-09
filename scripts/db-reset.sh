#!/usr/bin/env bash
# Recria uma base de dados a partir das migrações (por ordem de versão). APAGA a base se já existir:
# só para o PC, testes ou a primeira instalação; numa base com dados aplicam-se só as migrações novas.
# Uso: scripts/db-reset.sh                 (base BD_NOME do .env)
#      scripts/db-reset.sh "$BD_NOME_TESTE"   (outra base)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/carregar-env.sh
DB="${1:-${PGDATABASE:-${BD_NOME:?defina BD_NOME no .env}}}"
# protecção: fora do PC (localhost) só com a confirmação explícita do nome da base a apagar
case "$PGHOST" in
  localhost|127.0.0.1|::1) ;;
  *) if [[ "${CONFIRMAR_APAGAR:-}" != "$DB" ]]; then
       echo "RECUSADO: isto APAGA a base \"$DB\" em $PGHOST:$PGPORT, que não é o PC." >&2
       echo "Num servidor use scripts/db-migrar.sh (aplica só o que falta, sem apagar)." >&2
       echo "Se quer mesmo apagá-la: CONFIRMAR_APAGAR=$DB scripts/db-reset.sh" >&2
       exit 1
     fi ;;
esac
export PGDATABASE=postgres
psql -v ON_ERROR_STOP=1 -qc "DROP DATABASE IF EXISTS \"$DB\" WITH (FORCE)" -c "CREATE DATABASE \"$DB\""
export PGDATABASE="$DB"
for f in $(ls database/migrations/V*__*.sql | sort -V); do
  echo "→ $(basename "$f")"
  psql -v ON_ERROR_STOP=1 -q -f "$f" >/dev/null
done
echo "Base \"$DB\" criada em $PGHOST:$PGPORT com $(ls database/migrations/V*__*.sql | wc -l) migrações."

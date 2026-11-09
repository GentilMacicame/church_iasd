#!/usr/bin/env bash
# Cópia de segurança diária da base (formato custom do pg_dump, comprimido), com retenção.
# Uso (cron):  scripts/backup-bd.sh /var/backups/bd 30     (servidor, base e administrador do .env)
# Restaurar numa base NOVA (nunca por cima da de produção):
#   createdb "${BD_NOME}_restauro" && pg_restore -d "${BD_NOME}_restauro" --no-owner /var/backups/bd/<ficheiro>.dump
# Isto não substitui o PITR (arquivo contínuo de WAL, ex.: pgBackRest) recomendado em docs/producao/README.md.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/carregar-env.sh
export PGDATABASE="${PGDATABASE:-${BD_NOME:?defina BD_NOME no .env}}"
destino="${1:?indique a pasta de destino}"
dias="${2:-30}"
mkdir -p "$destino"
ficheiro="$destino/${PGDATABASE:-igreja}-$(date +%Y%m%d-%H%M).dump"
pg_dump --format=custom --compress=9 --file="$ficheiro.parcial"
pg_restore --list "$ficheiro.parcial" > /dev/null          # o ficheiro é legível
mv "$ficheiro.parcial" "$ficheiro"
find "$destino" -name '*.dump' -mtime +"$dias" -delete
echo "backup: $ficheiro ($(du -h "$ficheiro" | cut -f1))"

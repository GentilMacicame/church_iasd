#!/usr/bin/env bash
# Recria a base de testes e corre os testes SQL por ordem (00 → 04).
# Os testes 01–03 provocam erros DE PROPÓSITO (regras e permissões a recusar).
# O resultado é comparado com database/tests/esperado/*.out: qualquer diferença falha.
set -euo pipefail
cd "$(dirname "$0")/.."
export PGDATABASE="${PGDATABASE:-igreja_teste}"
scripts/db-reset.sh >/dev/null
mkdir -p database/tests/resultado
falhou=0
for t in 00_dados_exemplo_escola_sabatina 01_regras_manual_e_tesouraria 02_permissoes_por_perfil 03_sessoes_e_api 04_perfis_proprios_e_manutencao; do
  psql -X -q -f "database/tests/$t.sql" 2>&1 \
    | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9:.+]+//g; s/"pedido_[0-9a-f-]+"//g' > "database/tests/resultado/$t.out" || true
  if [[ "${ACTUALIZAR:-0}" == "1" ]]; then
    mkdir -p database/tests/esperado; cp "database/tests/resultado/$t.out" "database/tests/esperado/$t.out"; echo "actualizado  $t"
  elif diff -u "database/tests/esperado/$t.out" "database/tests/resultado/$t.out" > "database/tests/resultado/$t.diff"; then
    echo "ok     $t"
  else
    echo "FALHOU $t  (ver database/tests/resultado/$t.diff)"; falhou=1
  fi
done
exit $falhou

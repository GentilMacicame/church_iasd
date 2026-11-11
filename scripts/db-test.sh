#!/usr/bin/env bash
# Recria a base de testes e corre os testes SQL por ordem (00 → 09).
# Os testes 01–04 provocam erros DE PROPÓSITO (regras e permissões a recusar).
# O resultado é comparado com database/tests/esperado/*.out: qualquer diferença falha.
# Servidor e administrador: .env (BD_SERVIDOR, BD_PORTA, BD_ADMIN_*); base: BD_NOME_TESTE.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/carregar-env.sh
export PGDATABASE="${BD_NOME_TESTE:?defina BD_NOME_TESTE no .env}"
scripts/db-reset.sh "$PGDATABASE" >/dev/null
mkdir -p database/tests/resultado
# no Windows (Git Bash) o psql não conhece /dev/null: corre-se uma cópia do teste com NUL
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) windows=1 ;; *) windows=0 ;; esac
falhou=0
for t in 00_dados_exemplo_escola_sabatina 01_regras_manual_e_tesouraria 02_permissoes_por_perfil 03_sessoes_e_api 04_perfis_proprios_e_manutencao 05_escalas_e_lembretes 06_juntar_schemas_e_indices 07_ficha_do_membro 08_conta_da_missao 09_conselho_e_actas 10_tabelas_comuns_e_ofertas 11_registar_igrejas 12_provincias_e_distritos 13_directorio_de_igrejas; do
  fonte="database/tests/$t.sql"
  if [[ $windows == 1 ]]; then
    sed 's#\g /dev/null#\g NUL#' "$fonte" > "database/tests/resultado/$t.sql"
    fonte="database/tests/resultado/$t.sql"
  fi
  psql -X -q -f "$fonte" 2>&1 \
    | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9:.+]+//g; s/"pedido_[0-9a-f-]+"//g; s#database/tests/resultado/#database/tests/#g' \
    > "database/tests/resultado/$t.out" || true
  if [[ "${ACTUALIZAR:-0}" == "1" ]]; then
    mkdir -p database/tests/esperado; cp "database/tests/resultado/$t.out" "database/tests/esperado/$t.out"; echo "actualizado  $t"
  elif [[ ! -f "database/tests/esperado/$t.out" ]]; then
    echo "FALHOU $t  (sem resultado esperado: rever database/tests/resultado/$t.out e aceitar com ACTUALIZAR=1)"; falhou=1
  elif diff -u "database/tests/esperado/$t.out" "database/tests/resultado/$t.out" > "database/tests/resultado/$t.diff"; then
    echo "ok     $t"
  else
    echo "FALHOU $t  (ver database/tests/resultado/$t.diff)"; falhou=1
  fi
done
exit $falhou

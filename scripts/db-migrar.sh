#!/usr/bin/env bash
# Aplica as migrações que faltam na base BD_NOME (servidor e administrador do .env). NÃO apaga nada:
# é o script para servidores (o db-reset.sh, que apaga a base, é só para o PC).
#
# Cada migração corre numa transacção (ou entra inteira, ou nada) e fica registada em
# public.historico_migracoes com o SHA-256 do ficheiro. Se um ficheiro já aplicado tiver sido alterado,
# pára (regra 5 do CLAUDE.md: migrações aplicadas não se editam; a correcção é uma migração nova).
#
# Uso: scripts/db-migrar.sh            (aplica as que faltam)
#      scripts/db-migrar.sh --ver      (só mostra o estado)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/carregar-env.sh
export PGDATABASE="${BD_NOME:?defina BD_NOME no .env}"

psql -X -q -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS public.historico_migracoes (
    versao      INT PRIMARY KEY,
    ficheiro    TEXT NOT NULL,
    sha256      CHAR(64) NOT NULL,
    aplicada_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    aplicada_por TEXT NOT NULL DEFAULT current_user)" >/dev/null

aplicadas=0
for f in $(ls database/migrations/V*__*.sql | sort -V); do
  nome="$(basename "$f")"
  versao="${nome#V}"; versao="${versao%%__*}"
  hash="$(tr -d '\r' < "$f" | sha256sum | cut -d' ' -f1)"
  registado="$(psql -X -tA -c "SELECT sha256 FROM public.historico_migracoes WHERE versao = $versao")"
  if [[ -n "$registado" ]]; then
    if [[ "$registado" != "$hash" ]]; then
      echo "ERRO: $nome já foi aplicada e o ficheiro mudou desde então. Desfaça a alteração e crie uma migração nova." >&2
      exit 1
    fi
    [[ "${1:-}" == "--ver" ]] && echo "aplicada  $nome"
    continue
  fi
  if [[ "${1:-}" == "--ver" ]]; then
    echo "POR APLICAR  $nome"
    continue
  fi
  echo "→ $nome"
  tr -d '\r' < "$f" > "${TMPDIR:-/tmp}/migracao.sql"
  psql -X -q -1 -v ON_ERROR_STOP=1 -f "${TMPDIR:-/tmp}/migracao.sql" \
       -c "INSERT INTO public.historico_migracoes (versao, ficheiro, sha256) VALUES ($versao, '$nome', '$hash')" >/dev/null
  aplicadas=$((aplicadas + 1))
done
rm -f "${TMPDIR:-/tmp}/migracao.sql"
[[ "${1:-}" == "--ver" ]] || echo "Base \"$PGDATABASE\" em $PGHOST:$PGPORT: $aplicadas migração(ões) aplicada(s); está em dia."

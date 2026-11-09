# Carrega o .env da raiz do projecto (se existir) e prepara as variáveis do psql.
# Usado pelos outros scripts: . scripts/carregar-env.sh
# O que já estiver definido no ambiente tem prioridade sobre o .env (ex.: na CI).
_raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$_raiz/.env" ]]; then
  while IFS= read -r _linha || [[ -n "$_linha" ]]; do
    _linha="${_linha%$'\r'}"
    [[ -z "$_linha" || "$_linha" == \#* || "$_linha" != *=* ]] && continue
    _nome="${_linha%%=*}"; _valor="${_linha#*=}"
    [[ "$_nome" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    [[ -z "${!_nome+x}" ]] && export "$_nome=$_valor"
  done < "$_raiz/.env"
fi
# Windows sem o psql no PATH: usa a versão mais recente instalada em "Program Files\PostgreSQL"
if ! command -v psql >/dev/null 2>&1; then
  _escolhido=""
  for _bin in "/c/Program Files/PostgreSQL/"*/bin; do      # por ordem: fica a versão mais recente
    [[ -x "$_bin/psql.exe" ]] && _escolhido="$_bin"
  done
  [[ -n "$_escolhido" ]] && export PATH="$_escolhido:$PATH"
  unset _bin _escolhido
fi
# psql, pg_dump, ...: como administrador (dono), no servidor do .env
export PGHOST="${PGHOST:-${BD_SERVIDOR:-localhost}}"
export PGPORT="${PGPORT:-${BD_PORTA:-5432}}"
export PGUSER="${PGUSER:-${BD_ADMIN_UTILIZADOR:-postgres}}"
[[ -n "${BD_ADMIN_SENHA:-}" && -z "${PGPASSWORD:-}" ]] && export PGPASSWORD="$BD_ADMIN_SENHA"
export PGCLIENTENCODING=UTF8
unset _raiz _linha _nome _valor

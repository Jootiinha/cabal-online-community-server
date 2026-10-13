#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
action=${1:-up}

ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
      echo 'Docker CLI não encontrado no WSL. Ative a integração desta distribuição em Docker Desktop > Settings > Resources > WSL Integration.' >&2
    else
      echo 'Docker CLI não encontrado no PATH.' >&2
    fi
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
      echo 'Não foi possível acessar o Docker a partir do WSL. Inicie o Docker Desktop e ative a integração desta distribuição.' >&2
    else
      echo 'Não foi possível acessar o daemon Docker. Inicie o Docker e confira as permissões do usuário.' >&2
    fi
    exit 1
  fi
  docker compose version >/dev/null
}

init_env() {
  python3 - <<'PY'
import pathlib, re, secrets
path = pathlib.Path('.env')
text = path.read_text() if path.exists() else ''
values = dict(line.split('=', 1) for line in text.splitlines() if '=' in line and not line.startswith('#'))
for key in ('DB_PASSWORD', 'DB_ROOT_PASSWORD'):
    if not values.get(key):
        value = secrets.token_hex(24)
        if key in values:
            text = re.sub(r'^' + key + r'=.*$', key + '=' + value, text, flags=re.M)
        else:
            text = text.rstrip('\n') + '\n' + key + '=' + value + '\n'
    elif not re.fullmatch(r'[A-Za-z0-9@#]{12,128}', values[key]):
        raise SystemExit(key + ': use 12..128 characters: letters, digits, @ or #')
path.write_text(text.lstrip('\n'))
path.chmod(0o600)
pathlib.Path('.runtime').mkdir(exist_ok=True)
print('Docker environment ready; existing passwords preserved.')
PY
}
compose() { docker compose "$@"; }
db() {
  compose exec -T database sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb --skip-ssl -uroot "$@"' -- "$@"
}
if [ "$action" != init ]; then
  ensure_docker
fi
case "$action" in
  init) init_env ;;
  build) init_env; compose build ;;
  up) init_env; compose up -d --build --wait --wait-timeout 180 ;;
  down) compose down ;;
  status) compose ps ;;
  logs) compose logs --tail=100 ;;
  logs-follow) compose logs --follow --tail=100 ;;
  smoke-test)
    compose ps
    for service in database masterserver loginserver gameserver; do
      id=$(compose ps -q "$service")
      test -n "$id"
      test "$(docker inspect -f '{{.State.Health.Status}}' "$id")" = healthy
    done
    db -e 'SELECT COUNT(*) FROM cabal_login.accounts; SELECT COUNT(*) FROM cabal_world.characters;'
    python3 - <<'PY'
import socket
for port in (38101, 38111):
    with socket.create_connection(('127.0.0.1', port), timeout=3): pass
    print('Published TCP port OK:', port)
PY
    ;;
  create-local-account) compose run --rm localaccount ;;
  backup)
    umask 077
    mkdir -p .runtime/backups
    target=".runtime/backups/docker-$(date +%Y%m%d-%H%M%S).sql"
    compose exec -T database sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump --skip-ssl -uroot --single-transaction --databases cabal_login cabal_world' > "$target.tmp"
    mv "$target.tmp" "$target"
    echo "Backup: $target"
    ;;
  migrate)
    init_env
    # Build and verify the target before stopping the old server.
    compose build
    compose up -d database --wait --wait-timeout 180
    if [ -f .runtime/docker-migrated ]; then
      echo 'Migration already completed; starting Docker services.'
      compose up -d --wait --wait-timeout 180
      exit 0
    fi
    test -f .runtime/client.cnf || { echo 'Legacy database configuration missing.' >&2; exit 1; }
    count=$(db -N -e 'SELECT (SELECT COUNT(*) FROM cabal_login.accounts)+(SELECT COUNT(*) FROM cabal_world.characters);')
    test "$count" = 0 || { echo 'Target database contains players; refusing to overwrite.' >&2; exit 1; }
    bash scripts/stop-local.sh
    bash scripts/backup.sh
    python3 scripts/migrate-docker.py
    compose up -d --wait --wait-timeout 180
    bash scripts/docker-local.sh smoke-test
    ;;
  test)
    compose build
    docker build --target build -t cabal-builder:local .
    docker run --rm -v "$PWD/backend:/src" -w /src cabal-builder:local go test ./...
    ;;
  *) echo "Unknown action: $action" >&2; exit 1 ;;
esac

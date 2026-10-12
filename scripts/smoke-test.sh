#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cfg=$(mktemp)
trap 'rm -f "$cfg"' EXIT
cp .runtime/client.cnf "$cfg"
chmod 600 "$cfg"
mariadb --defaults-extra-file="$cfg" -e 'SELECT COUNT(*) FROM cabal_login.accounts; SELECT COUNT(*) FROM cabal_world.characters;'
python3 - <<'PY'
import socket,pathlib
for port in (9001,38101,38111):
    with socket.create_connection(('127.0.0.1',port),timeout=3): pass
    print('TCP localhost OK:',port)
for path in pathlib.Path('.runtime/logs').glob('*.log'):
    text=path.read_text(errors='replace')
    if 'panic:' in text or 'FATAL' in text: raise SystemExit('Falha em '+str(path))
PY
ss -lntp

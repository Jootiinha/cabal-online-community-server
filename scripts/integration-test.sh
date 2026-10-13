#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$EUID" -ne 0 ]; then echo 'Execute como root no WSL (banco descartavel).'; exit 1; fi
python3 - <<'PY'
import os,pathlib,secrets,subprocess
name='cabal_test_'+secrets.token_hex(8)
password=secrets.token_hex(24)
def sql(text): subprocess.run(['mariadb'],input=text.encode(),check=True)
sql(f'CREATE DATABASE {name};')
try:
    sql(f'USE {name};'+pathlib.Path('backend/sql/world.sql').read_text())
    sql(f"CREATE USER '{name}'@'127.0.0.1' IDENTIFIED BY '{password}'; GRANT ALL ON {name}.* TO '{name}'@'127.0.0.1';")
    env=os.environ.copy();env['CABAL_TEST_DSN']=f'{name}:{password}@tcp(127.0.0.1:3306)/{name}?parseTime=true'
    subprocess.run(['go','test','-tags=integration','-v','./cmd/masterserver/rpc'],cwd='backend',env=env,check=True)
finally:
    sql(f"DROP DATABASE {name}; DROP USER IF EXISTS '{name}'@'127.0.0.1';")
PY

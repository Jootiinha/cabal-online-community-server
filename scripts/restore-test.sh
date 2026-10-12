#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$EUID" -ne 0 ]; then echo 'Execute como root no WSL.'; exit 1; fi
python3 - <<'PY'
import pathlib,secrets,subprocess
backups=sorted(pathlib.Path('.runtime/backups').glob('*.sql'))
if not backups: raise SystemExit('Execute backup primeiro')
prefix='cabal_restore_'+secrets.token_hex(8)
names=[prefix+'_login',prefix+'_world']
def sql(text): return subprocess.check_output(['mariadb','-N'],input=text.encode()).decode().strip()
try:
    text=backups[-1].read_text().replace('`cabal_login`',f'`{names[0]}`').replace('`cabal_world`',f'`{names[1]}`')
    sql(text)
    for source,target in zip(['cabal_login','cabal_world'],names):
        tables=sql(f"SELECT table_name FROM information_schema.tables WHERE table_schema='{source}' ORDER BY table_name;").splitlines()
        restored=sql(f"SELECT table_name FROM information_schema.tables WHERE table_schema='{target}' ORDER BY table_name;").splitlines()
        if tables!=restored: raise SystemExit('Diferenca de tabelas')
        for table in tables:
            if sql(f'SELECT COUNT(*) FROM {source}.`{table}`;')!=sql(f'SELECT COUNT(*) FROM {target}.`{table}`;'): raise SystemExit('Diferenca de registros')
    print('Restore em bancos descartaveis OK: tabelas e contagens conferidas.')
finally:
    for name in names: sql(f'DROP DATABASE IF EXISTS {name};')
PY

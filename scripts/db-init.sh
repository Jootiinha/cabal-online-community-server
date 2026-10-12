#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$EUID" -ne 0 ]; then echo 'Execute com sudo no WSL.' >&2; exit 1; fi
umask 077
mkdir -p .runtime
python3 - <<'PY'
import pathlib, re, secrets, subprocess
root=pathlib.Path.cwd()
env=root/'.env'
if not env.exists(): env.write_text('DB_PASSWORD='+secrets.token_hex(24)+'\nCABAL_INITIAL_HP_PERCENT=100\n')
values=dict(line.split('=',1) for line in env.read_text().splitlines() if '=' in line and not line.startswith('#'))
password=values.get('DB_PASSWORD','')
if not re.fullmatch(r'[A-Za-z0-9]{24,128}',password): raise SystemExit('DB_PASSWORD deve ter 24..128 caracteres alfanumericos.')
def sql(s): return subprocess.check_output(['mariadb','-N'],input=s.encode()).decode().strip()
for name in ['cabal_login','cabal_world']:
    sql(f'CREATE DATABASE IF NOT EXISTS {name} CHARACTER SET utf8mb4;')
    if sql(f"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='{name}';") != '0':
        expected='accounts' if name.endswith('login') else 'characters'
        if sql(f"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='{name}' AND table_name='{expected}';") != '1':
            raise SystemExit('Schema parcial: restaurar backup ou usar banco vazio; nenhuma sobrescrita executada.')
        continue
    source='login' if name.endswith('login') else 'world'
    text=(root/f'emulator/sql/{source}.sql').read_text()
    # Remove upstream sample player account; no default account is provisioned.
    text=re.sub(r'INSERT INTO `accounts`.*?;', '', text, flags=re.S)
    sql(f'USE {name};\n'+text)
sql(f"CREATE USER IF NOT EXISTS 'cabal_local'@'127.0.0.1' IDENTIFIED BY '{password}'; ALTER USER 'cabal_local'@'127.0.0.1' IDENTIFIED BY '{password}'; GRANT SELECT,INSERT,UPDATE,DELETE ON cabal_login.* TO 'cabal_local'@'127.0.0.1'; GRANT SELECT,INSERT,UPDATE,DELETE ON cabal_world.* TO 'cabal_local'@'127.0.0.1';")
runtime=root/'.runtime'
(runtime/'client.cnf').write_text(f'[client]\nhost=127.0.0.1\nuser=cabal_local\npassword={password}\n')
cfg=(root/'emulator/cfg/masterserver.ini').read_text().replace('database=login','database=cabal_login').replace('database=world','database=cabal_world').replace('username=root','username=cabal_local').replace('password=','password='+password)
(runtime/'masterserver.ini').write_text(cfg)
print('Schemas preparados; conta upstream removida; credenciais locais geradas.')
PY

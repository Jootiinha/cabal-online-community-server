"""Transfer the WSL Docker database to Desktop in memory, without a backup."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
subprocess.run(['docker', 'compose', 'stop', 'loginserver', 'gameserver', 'masterserver'], cwd=root, check=True)
windows_root = subprocess.check_output(['wslpath', '-w', str(root)]).decode().strip()
desktop_cli = sys.argv[1]
desktop = [desktop_cli, '--context', 'desktop-linux', 'compose', '--project-directory', windows_root,
           '--file', windows_root + '\\compose.yaml']
source = ['docker', 'compose']

def sql(compose, query):
    command = compose + ['exec', '-T', 'database', 'sh', '-c',
                         'MYSQL_PWD=$MARIADB_ROOT_PASSWORD exec mariadb --skip-ssl -uroot -N']
    return subprocess.check_output(command, input=query.encode(), cwd=root).decode().strip()

marker = root / '.runtime/desktop-migrated'
if marker.exists():
    print('Desktop migration already completed.')
    raise SystemExit(0)
# The original volume survives even when WSL's containers/images were removed.
if subprocess.run(['docker', 'image', 'inspect', 'cabal-database:local'],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
    sender = subprocess.Popen([desktop_cli, '--context', 'desktop-linux', 'image', 'save', 'cabal-database:local'], stdout=subprocess.PIPE)
    receiver = subprocess.run(['docker', 'image', 'load'], stdin=sender.stdout, check=True)
    sender.stdout.close()
    if sender.wait() != 0:
        raise SystemExit('Failed to transfer database image to source engine.')
subprocess.run(source + ['up', '-d', '--no-build', '--no-recreate', 'database', '--wait', '--wait-timeout', '180'], cwd=root, check=True)
count = sql(desktop, 'SELECT (SELECT COUNT(*) FROM cabal_login.accounts)+(SELECT COUNT(*) FROM cabal_world.characters)')
if count != '0':
    raise SystemExit('Desktop database contains players; refusing to overwrite.')
expected = {}
for db in ('cabal_login', 'cabal_world'):
    tables = sql(source, f"SELECT table_name FROM information_schema.tables WHERE table_schema='{db}' ORDER BY table_name").splitlines()
    for table in tables:
        expected[(db, table)] = sql(source, f'SELECT COUNT(*) FROM `{db}`.`{table}`')
dump = subprocess.check_output(source + ['exec', '-T', 'database', 'sh', '-c',
    'MYSQL_PWD=$MARIADB_ROOT_PASSWORD exec mariadb-dump --skip-ssl -uroot --single-transaction --databases cabal_login cabal_world'], cwd=root)
subprocess.run(desktop + ['exec', '-T', 'database', 'sh', '-c',
    'MYSQL_PWD=$MARIADB_ROOT_PASSWORD exec mariadb --skip-ssl -uroot'], input=dump, cwd=root, check=True)
for (db, table), count in expected.items():
    if sql(desktop, f'SELECT COUNT(*) FROM `{db}`.`{table}`') != count:
        raise SystemExit(f'Row count mismatch: {db}.{table}; original volume preserved.')
marker.write_text('Transferred from WSL Docker; table counts verified. No backup created.\n')
subprocess.run(source + ['down'], cwd=root, check=True)
print('Database transferred to Docker Desktop; row counts verified. Original WSL volume preserved.')

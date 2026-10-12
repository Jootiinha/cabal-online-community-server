"""Import a legacy snapshot and compare every table count before cutover."""
from pathlib import Path
import atexit
import os
import subprocess
import tempfile

# DrvFS permissions can make MariaDB ignore the original config as world-writable.
fd, config = tempfile.mkstemp(prefix='cabal-migrate-', suffix='.cnf')
with os.fdopen(fd, 'wb') as output:
    output.write(Path('.runtime/client.cnf').read_bytes())
atexit.register(lambda: os.unlink(config))
legacy = ['mariadb', '--defaults-extra-file=' + config, '-N']
target = ['docker', 'compose', 'exec', '-T', 'database', 'sh', '-c',
          'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot "$@"', '--', '-N']

def query(command, sql):
    return subprocess.check_output(command, input=sql.encode()).decode().strip()

snapshot = sorted(p for p in Path('.runtime/backups').glob('*.sql') if not p.name.startswith('docker-'))[-1]
query(legacy, 'SELECT 1')
with snapshot.open('rb') as source:
    subprocess.run(target, stdin=source, check=True)
for database in ('cabal_login', 'cabal_world'):
    sql = f"SELECT table_name FROM information_schema.tables WHERE table_schema='{database}' ORDER BY table_name"
    tables = query(legacy, sql).splitlines()
    if tables != query(target, sql).splitlines():
        raise SystemExit(f'Table mismatch: {database}; legacy snapshot preserved at {snapshot}')
    for table in tables:
        sql = f'SELECT COUNT(*) FROM `{database}`.`{table}`'
        if query(legacy, sql) != query(target, sql):
            raise SystemExit(f'Row count mismatch: {database}.{table}')
Path('.runtime/docker-migrated').write_text(str(snapshot) + '\n')
print('Legacy data imported; all table row counts match. Backup:', snapshot)

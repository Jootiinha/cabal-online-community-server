import configparser
import ipaddress
import os
from pathlib import Path
import re
import sys

service = sys.argv[1]
if service not in ('masterserver', 'loginserver', 'gameserver', 'localaccount'):
    raise SystemExit('Unknown service')
if service == 'masterserver':
    password = os.environ['DB_PASSWORD']
    if not re.fullmatch(r'[A-Za-z0-9]{24,128}', password):
        raise SystemExit('DB_PASSWORD must contain 24..128 alphanumeric characters')
    cfg = configparser.ConfigParser()
    cfg.read('/app/templates/masterserver.ini')
    for section, database in [('login', 'cabal_login'), ('game_1', 'cabal_world')]:
        cfg[section].update(ip='database', database=database, username='cabal_local', password=password)
    with open('/app/cfg/masterserver.ini', 'w') as output:
        cfg.write(output)
elif service in ('loginserver', 'gameserver'):
    name = 'loginserver' if service == 'loginserver' else 'gameserver_1_1'
    cfg = configparser.ConfigParser()
    cfg.read(f'/app/templates/{name}.ini')
    cfg['master']['ip'] = 'masterserver'
    if service == 'gameserver':
        address = os.getenv('CABAL_PUBLIC_IP', '127.0.0.1')
        ipaddress.IPv4Address(address)
        cfg['network']['ip'] = address
        cfg['network']['use_local_ip'] = '0'
    target = 'loginserver' if service == 'loginserver' else 'GameServer_1_1'
    with open(f'/app/cfg/{target}.ini', 'w') as output:
        cfg.write(output)
os.execv(f'/app/bin/{service}', [f'/app/bin/{service}', *sys.argv[2:]])

from pathlib import Path
import sys

# Probe listeners without creating incomplete game sessions every few seconds.
port = int(sys.argv[1])
for filename in ('/proc/net/tcp', '/proc/net/tcp6'):
    for line in Path(filename).read_text().splitlines()[1:]:
        fields = line.split()
        if fields[3] == '0A' and int(fields[1].split(':')[1], 16) == port:
            raise SystemExit(0)
raise SystemExit(1)

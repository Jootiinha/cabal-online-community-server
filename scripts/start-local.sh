#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
test -f .runtime/masterserver.ini || { echo 'Execute db-init.sh primeiro'; exit 1; }
mkdir -p .runtime/bin .runtime/cfg .runtime/logs
cp emulator/cfg/loginserver.ini emulator/cfg/gameserver_1_1.ini .runtime/cfg/
cp emulator/cfg/gameserver_1_1.ini .runtime/cfg/GameServer_1_1.ini
cp .runtime/masterserver.ini .runtime/cfg/
ln -sfn "$root/emulator/data" .runtime/data
ln -sfn "$root/emulator/script" .runtime/script
set -a
source .env
set +a
cd .runtime
for service in masterserver loginserver gameserver; do
  if [ -f "$service.pid" ] && kill -0 "$(cat "$service.pid")" 2>/dev/null; then
    pid=$(cat "$service.pid")
    [ "$(readlink -f "/proc/$pid/exe")" = "$PWD/bin/$service" ] || { echo 'PID pertence a outro processo; examine o arquivo PID.'; exit 1; }
    continue
  fi
  cp "$root/emulator/bin/$service" "bin/$service"
  nohup "./bin/$service" >"logs/$service.log" 2>&1 &
  echo $! >"$service.pid"
  sleep 2
  kill -0 "$(cat "$service.pid")" || { tail -30 "logs/$service.log"; exit 1; }
done

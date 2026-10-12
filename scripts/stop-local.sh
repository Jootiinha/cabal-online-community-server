#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.runtime"
for service in gameserver loginserver masterserver; do
  if [ -f "$service.pid" ]; then
    pid=$(cat "$service.pid")
    if [ -e "/proc/$pid/exe" ] && [ "$(readlink -f "/proc/$pid/exe")" = "$PWD/bin/$service" ]; then kill "$pid"; fi
    rm -f "$service.pid"
  fi
done

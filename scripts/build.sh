#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../backend"
mkdir -p bin
for service in masterserver loginserver gameserver; do
  go build -o "bin/$service" "./cmd/$service"
done

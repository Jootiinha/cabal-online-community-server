#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p .runtime/backups
cfg=$(mktemp)
trap 'rm -f "$cfg"' EXIT
cp .runtime/client.cnf "$cfg"
chmod 600 "$cfg"
mariadb-dump --defaults-extra-file="$cfg" --single-transaction --skip-lock-tables --databases cabal_login cabal_world > ".runtime/backups/$(date +%Y%m%d-%H%M%S).sql"

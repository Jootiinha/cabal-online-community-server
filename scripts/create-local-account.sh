#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
set -a
source .env
set +a
cd emulator
go run ./cmd/localaccount "$root/.runtime/player-credentials.json"

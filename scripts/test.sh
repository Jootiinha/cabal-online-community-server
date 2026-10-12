#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../emulator"
go test ./...

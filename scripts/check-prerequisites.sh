#!/usr/bin/env bash
set -euo pipefail
for tool in go mariadb mariadb-dump python3 ss; do
  command -v "$tool" || { echo "Falta: $tool" >&2; exit 1; }
done
go version
mariadb --version

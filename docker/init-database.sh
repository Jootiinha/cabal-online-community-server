#!/usr/bin/env bash
# Sourced by the official MariaDB entrypoint, only for a new data volume.
# Do not enable nounset in the sourcing entrypoint: it uses optional arguments.
set -eo pipefail
if [[ ! "$DB_PASSWORD" =~ ^[A-Za-z0-9]{24,128}$ ]]; then
    echo 'DB_PASSWORD must contain 24..128 alphanumeric characters' >&2
    exit 1
fi
docker_process_sql <<SQL
CREATE DATABASE cabal_login CHARACTER SET utf8mb4;
CREATE DATABASE cabal_world CHARACTER SET utf8mb4;
CREATE USER 'cabal_local'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE ON cabal_login.* TO 'cabal_local'@'%';
GRANT SELECT,INSERT,UPDATE,DELETE ON cabal_world.* TO 'cabal_local'@'%';
SQL
docker_process_sql --database=cabal_login < /schemas/login.sql
docker_process_sql --database=cabal_world < /schemas/world.sql

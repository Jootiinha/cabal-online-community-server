FROM mariadb:11.4
COPY backend/sql/ /schemas/
COPY --chmod=0644 infra/docker/init-database.sh /docker-entrypoint-initdb.d/10-cabal.sh

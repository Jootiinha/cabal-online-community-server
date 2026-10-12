FROM mariadb:11.4
COPY emulator/sql/ /schemas/
COPY --chmod=0644 docker/init-database.sh /docker-entrypoint-initdb.d/10-cabal.sh

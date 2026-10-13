# Ambiente local com WSL2 ou Linux

O Ubuntu-24.04 já estava instalado nesta máquina. Go e MariaDB foram instalados no WSL. Em outra máquina, execute manualmente `wsl --install -d Ubuntu-24.04`; no Ubuntu: `sudo apt update && sudo apt install make golang-go mariadb-server mariadb-client python3 iproute2`. Para os alvos Docker, inicie o Docker Desktop e habilite a integração com Ubuntu-24.04 em **Settings > Resources > WSL Integration**.

Na raiz do projeto:

```bash
sudo service mariadb start
make check-prerequisites
sudo make db-init
make build-local
make test
sudo make integration-test
make start-local
make smoke-test
```

`db-init` gera .env com senha aleatória, bancos cabal_login/cabal_world e usuário cabal_local limitado a SELECT/INSERT/UPDATE/DELETE. Não importa a conta de exemplo de referência. Importa somente bancos vazios; tabelas existentes não são sobrescritas. Se uma importação falhar, investigar schema parcial antes de repetir. Não é um mecanismo de migrations.

Para parar: `make stop-local`. MariaDB permanece disponível; pare com `sudo service mariadb stop` se necessário.

Para backup: ação `backup`, arquivos em .runtime/backups. Não edite credenciais em backend/cfg; configuração efetiva em .runtime. Proteja .env e .runtime com ACL da sua conta Windows: permissões Linux não restringem automaticamente arquivos no NTFS montado. Nenhuma conta de jogador é criada automaticamente.

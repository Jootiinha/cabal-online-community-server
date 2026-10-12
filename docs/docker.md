# Backend em Docker

O backend usa quatro containers: `database` (MariaDB 11.4), `masterserver`, `loginserver` e `gameserver`. O utilitário `localaccount` é um container temporário. A imagem Go usa compilação em múltiplos estágios; os servidores executam como usuário sem privilégios. Dados e Lua acompanham a imagem. As configurações são geradas em cada inicialização.

## Pré-requisitos e início

No Windows, os wrappers usam Ubuntu-24.04 no WSL2, com Docker Engine e plugin Compose instalados e daemon ativo. Também podem ser usados Docker Desktop com integração nessa distribuição. Não é necessário Go nem MariaDB instalado no host para uma instalação nova. Python3 no WSL é usado para gerar `.env` e verificar portas.

```powershell
.\scripts\docker.ps1 init
.\scripts\docker.ps1 up
.\scripts\docker.ps1 smoke-test
.\scripts\Start-CabalLocal.ps1 -NoClient
```

`init` gera senhas alfanuméricas aleatórias e preserva valores existentes. Não publique `.env`. `DB_PASSWORD` é a senha de aplicação; `DB_ROOT_PASSWORD` é reservada às operações administrativas. As senhas são aplicadas na primeira inicialização do volume; alterar `.env` depois requer atualizar os usuários SQL correspondentes.

No Linux/WSL, execute `bash scripts/docker-local.sh <ação>`. Docker Compose direto também funciona depois de gerar `.env`: `docker compose up -d --build --wait`.

Login e jogo são publicados somente em `127.0.0.1:38101` e `127.0.0.1:38111`. Banco e RPC ficam na rede interna do Compose. `CABAL_PUBLIC_IP=127.0.0.1` é o endereço anunciado ao cliente local. A configuração fornecida é para desenvolvimento na mesma máquina.

## Migrar o banco nativo existente

```powershell
.\scripts\docker.ps1 migrate
```

A migração constrói as imagens e prepara o banco Docker antes de parar os processos nativos. Exige `.runtime/client.cnf`, MariaDB nativo acessível e cliente `mariadb`/`mariadb-dump` no WSL. Recusa sobrescrever um destino com contas ou personagens. Faz backup em `.runtime/backups`, importa login e world e compara todas as tabelas e contagens. O banco nativo é preservado. Uma marca em `.runtime/docker-migrated` evita repetir a importação.

Se a importação ou conferência falhar, os servidores nativos permanecem parados para evitar escrita concorrente; o backup e o banco original continuam disponíveis. Examine os erros antes de retomar. Para voltar temporariamente ao backend original: execute `docker.ps1 down` e depois `local.ps1 start-local`. Novas alterações feitas no Docker não são copiadas automaticamente de volta ao banco nativo.

## Operação

```powershell
.\scripts\docker.ps1 status
.\scripts\docker.ps1 logs
.\scripts\docker.ps1 backup
.\scripts\docker.ps1 create-local-account
.\scripts\docker.ps1 down
```

`Start-CabalLocal.ps1` usa Docker e abre o cliente Windows, criando a conta local apenas quando falta o arquivo de credenciais. O cliente permanece no Windows. `down` preserva o volume `cabal-local_database`; `up` reaproveita os dados. Não use `docker compose down -v` se quiser preservar contas e personagens.

Backups Docker têm prefixo `docker-` e contêm os dois bancos. Para restaurar um backup, pare login, jogo e master e importe pelo usuário root do container (a senha é lida do ambiente do próprio container):

```bash
docker compose stop loginserver gameserver masterserver
docker compose exec -T database sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot' < .runtime/backups/docker-AAAAMMDD-HHMMSS.sql
docker compose up -d --wait
bash scripts/docker-local.sh smoke-test
```

Os dumps substituem tabelas; escolha o backup correto antes de restaurar. Logs ficam disponíveis por `docker compose logs` e têm rotação nos containers Go. Healthchecks verificam prontidão do MariaDB e conexão TCP nos servidores; não validam um login completo no cliente.

`docker.ps1 test` executa a suíte Go em container. Os scripts nativos antigos continuam disponíveis para rollback e consulta histórica. A inicialização ordenada usa [dependências saudáveis do Compose](https://docs.docker.com/compose/how-tos/startup-order) e o [healthcheck oficial MariaDB](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/using-healthcheck-sh).

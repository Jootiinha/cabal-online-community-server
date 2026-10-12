# Windows + WSL2

O Ubuntu-24.04 já estava instalado nesta máquina. Go e MariaDB foram instalados no WSL. Em outra máquina, execute manualmente `wsl --install -d Ubuntu-24.04`; no Ubuntu: `sudo apt update && sudo apt install golang-go mariadb-server mariadb-client python3 iproute2`.

Na raiz do projeto, PowerShell:

```powershell
wsl -d Ubuntu-24.04 -u root -- service mariadb start
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 check-prerequisites
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 db-init
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 build
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 test
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 integration-test
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 start-local
powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 smoke-test
```

`db-init` gera .env com senha aleatória, bancos cabal_login/cabal_world e usuário cabal_local limitado a SELECT/INSERT/UPDATE/DELETE. Não importa a conta de exemplo upstream. Importa somente bancos vazios; tabelas existentes não são sobrescritas. Se uma importação falhar, investigar schema parcial antes de repetir. Não é um mecanismo de migrations.

Para parar: `powershell -ExecutionPolicy Bypass -File .\scripts\local.ps1 stop-local`. MariaDB permanece disponível; pare com `wsl -d Ubuntu-24.04 -u root -- service mariadb stop` se necessário.

Para backup: ação `backup`, arquivos em .runtime/backups. Não edite credenciais em emulator/cfg; configuração efetiva em .runtime. Proteja .env e .runtime com ACL da sua conta Windows: permissões Linux não restringem automaticamente arquivos no NTFS montado. Nenhuma conta de jogador é criada automaticamente.

# Cabal Online local no Windows

Workspace Freya EP8 (MIT), Go + MariaDB, executado no Ubuntu 24.04 WSL2. Servidor experimental: processos ativos não significam jogo completo/jogável.

Para iniciar MariaDB, serviços, verificações e o cliente em um comando: `powershell -ExecutionPolicy Bypass -File .\scripts\Start-CabalLocal.ps1`. Use `-NoClient` para subir somente os serviços.

Leia [setup local](docs/setup-local.md) para comandos PowerShell, [relatório](docs/validation.md) para evidências e [compatibilidade](docs/client-compatibility.md) para o cliente externo necessário.

Código em emulator/; scripts idempotentes em scripts/; logs, bancos de teste e credenciais ficam fora do Git. Primeira alteração: [HP inicial de novos personagens](docs/first-customization.md). Licença e versão upstream em [versions](docs/versions.md); arquitetura e pendências em docs/architecture.md e docs/roadmap.md.

# Cabal Online local no Windows

Workspace Freya EP8 (MIT), Go + MariaDB, executado em Docker Compose no Docker Desktop do Windows (contexto `desktop-linux`). MariaDB, MasterServer, LoginServer e GameServer têm containers separados. Servidor experimental: processos ativos não significam jogo completo/jogável.

Para iniciar MariaDB, serviços, verificações e o cliente em um comando: `powershell -ExecutionPolicy Bypass -File .\scripts\Start-CabalLocal.ps1`. Use `-NoClient` para subir somente os serviços.

Para iniciar todo o backend com Docker Compose: `powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Backend.ps1`. Acrescente `-FollowLogs` para acompanhar os logs em tempo real.

Leia [setup Docker](docs/docker.md) para instalação, migração, backup e comandos PowerShell, [relatório](docs/validation.md) para evidências anteriores e [compatibilidade](docs/client-compatibility.md) para o cliente externo necessário. O [setup local](docs/setup-local.md) descreve a execução nativa anterior.

Código em emulator/; scripts idempotentes em scripts/; logs, bancos de teste e credenciais ficam fora do Git. Primeira alteração: [HP inicial de novos personagens](docs/first-customization.md). Licença e versão upstream em [versions](docs/versions.md); arquitetura e pendências em docs/architecture.md e docs/roadmap.md.

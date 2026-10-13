# Cabal Online Community Server

Backend experimental EP8 em Go e MariaDB, executado com Docker Compose no Docker Desktop do Windows.

Para iniciar todos os serviços:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Backend.ps1
```

Acrescente `-FollowLogs` para acompanhar os logs. Para iniciar também o cliente local, use `powershell -ExecutionPolicy Bypass -File .\scripts\Start-CabalLocal.ps1`.

| Pasta | Responsabilidade |
| --- | --- |
| `backend/` | Código Go, configurações, schemas, dados e scripts Lua |
| `infra/docker/` | Imagem do banco, inicialização, entrypoint e healthchecks |
| `scripts/` | Operação, build, testes e configuração do cliente |
| `docs/` | Guias de manutenção e execução |
| `docs/archive/` | Plano inicial e relatórios históricos |
| `.runtime/` | Credenciais, logs e arquivos locais ignorados pelo Git |
| `.client/` | Cliente local externo, ignorado pelo Git |

O `Dockerfile` e o `compose.yaml` ficam na raiz para permitir os comandos padrão do Docker Compose. O volume `cabal-local_database` persiste contas e personagens.

Consulte [Docker e logs](docs/docker.md), [arquitetura](docs/architecture.md), [cliente](docs/client-compatibility.md), [personalização de HP](docs/first-customization.md) e [pendências](docs/roadmap.md). A origem e as licenças dos componentes estão em [atribuições](docs/THIRD_PARTY_NOTICES.md).

# Backend Cabal Community Server

Módulo Go `cabal-online-community-server`. Execute os comandos de operação a partir da raiz do repositório.

- `cmd/`: MasterServer, LoginServer, GameServer e ferramenta de conta local.
- `share/`: rede, criptografia, RPC, modelos e políticas compartilhadas.
- `cfg/`: configurações de referência; Docker gera a configuração de execução.
- `data/`: dados iniciais, mapas e definições do jogo.
- `script/`: eventos e comandos Lua.
- `sql/`: schemas de inicialização dos bancos.

Veja [arquitetura](../docs/architecture.md), [Docker](../docs/docker.md) e [atribuições](../docs/THIRD_PARTY_NOTICES.md). A licença do código está em [LICENSE](LICENSE).

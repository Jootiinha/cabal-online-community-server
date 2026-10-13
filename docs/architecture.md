# Arquitetura e manutenção

O módulo Go em `backend/` contém quatro executáveis em `cmd/`: `masterserver` acessa os bancos e atende RPC; `loginserver` autentica e apresenta os servidores; `gameserver` gerencia personagens e mapas; `localaccount` provisiona a conta de desenvolvimento. `share/` reúne os componentes compartilhados. Imports internos usam `cabal-online-community-server`.

Docker Desktop executa os serviços no contexto `desktop-linux`. MasterServer conecta `database:3306` e atende RPC interno em 9001. LoginServer e GameServer conectam `masterserver:9001`. As portas publicadas em localhost são 3306, 38101 e 38111. O volume `cabal-local_database` guarda os dados dos jogadores.

`backend/cfg/` contém os modelos de configuração. `infra/docker/entrypoint.py` gera os arquivos em `/app/cfg` a partir do ambiente. Os dados do jogo ficam em `backend/data/`, eventos Lua em `backend/script/` e schemas em `backend/sql/`. No container, esses caminhos são copiados para `/app`, mantendo a resolução de arquivos relativa a `bin/`.

Execute os wrappers em `scripts/` a partir da raiz. `Start-Backend.ps1` inicia o Compose e verifica a saúde dos serviços. `scripts/docker.ps1 test` executa os testes Go no builder. Os testes SQL de criação de personagem usam `scripts/integration-test.sh` com banco descartável no WSL; o script exige MariaDB nativo ativo e Go instalado. Os scripts nativos são mantidos para desenvolvimento e migração, conforme [setup nativo](setup-local.md).

Ao alterar caminhos, revise `Dockerfile`, `compose.yaml`, `.dockerignore`, scripts e CI. Ao alterar dados iniciais de personagens, mantenha os valores retornados pelo RPC consistentes com os defaults SQL: a primeira entrada no mapa usa o personagem em memória. Os testes de integração verificam essa consistência.

Documentos históricos ficam em `archive/`; instruções atuais ficam diretamente em `docs/`. A licença e a origem dos componentes estão em [atribuições](THIRD_PARTY_NOTICES.md).

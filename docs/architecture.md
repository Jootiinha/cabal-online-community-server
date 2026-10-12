# Arquitetura local

Integração por cópia versionada em `emulator/`, licença MIT preservada. A raiz estava vazia, exceto o guia não rastreado; branch main e origin existentes foram preservados. Não há fork remoto próprio para manter patches em um submódulo; a cópia permite revisar e modificar o código no mesmo repositório. Nenhum commit ou push realizado.

Windows executa os comandos PowerShell e o cliente; Ubuntu 24.04 WSL2 executa Docker Compose. MariaDB, MasterServer, LoginServer e GameServer têm containers separados. MasterServer conecta `database:3306` e atende RPC na rede interna em 9001. LoginServer atende 38101; GameServer 1/1 atende 38111. Ambos conectam `masterserver:9001`. Somente portas do cliente são publicadas no localhost do host. Os listeners usam `CABAL_BIND_IP=0.0.0.0` nos containers e localhost por padrão na execução nativa. Configurações, dados e scripts ficam relativos à pasta pai de bin. O volume Docker persiste o banco; `.runtime` mantém backups, credenciais do jogador e artefatos nativos preservados para rollback. Veja [Docker](docker.md).

Patches: listeners localhost, resolução de diretório portátil, política de HP inicial e criação transacional de personagem. Os demais fluxos upstream ainda precisam de revisão antes de qualquer uso fora do desenvolvimento local.

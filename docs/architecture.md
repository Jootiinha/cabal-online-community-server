# Arquitetura local

Integração por cópia versionada em `emulator/`, licença MIT preservada. A raiz estava vazia, exceto o guia não rastreado; branch main e origin existentes foram preservados. Não há fork remoto próprio para manter patches em um submódulo; a cópia permite revisar e modificar o código no mesmo repositório. Nenhum commit ou push realizado.

Windows executa os comandos PowerShell; Ubuntu 24.04 WSL2 executa MariaDB e os binários Go. MasterServer conecta login/world e atende RPC em 127.0.0.1:9001. LoginServer atende 38101; GameServer 1/1 atende 38111. Ambos conectam MasterServer. Configurações, dados e scripts ficam relativos à pasta pai de bin. O runtime ignorado contém configuração com credenciais, logs e PIDs.

Patches: listeners localhost, resolução de diretório portátil, política de HP inicial e criação transacional de personagem. Os demais fluxos upstream ainda precisam de revisão antes de qualquer uso fora do desenvolvimento local.

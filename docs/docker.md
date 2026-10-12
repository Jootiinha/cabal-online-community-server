# Backend no Docker Desktop

MariaDB, MasterServer, LoginServer e GameServer executam em containers separados no Docker Desktop do Windows. Os scripts PowerShell selecionam explicitamente o contexto `desktop-linux`. O cliente do jogo continua no Windows.

Inicie Docker Desktop com containers Linux e, na raiz do projeto, execute:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Backend.ps1
```

Para iniciar e acompanhar os logs, acrescente `-FollowLogs`. Ctrl+C encerra o acompanhamento e mantém os containers ativos.

```powershell
.\scripts\docker.ps1 status
.\scripts\docker.ps1 logs
.\scripts\docker.ps1 logs-follow
.\scripts\docker.ps1 smoke-test
.\scripts\docker.ps1 down
```

Os wrappers localizam o cliente Docker nas instalações por usuário e em Program Files. Não é necessário Go, MariaDB ou um Engine independente no Ubuntu para uma instalação nova. `up` gera as credenciais ausentes em `.env`, constrói as imagens e aguarda todos os serviços saudáveis. Credenciais existentes são preservadas.

Os comandos Docker diretos devem usar o mesmo contexto:

```powershell
docker --context desktop-linux ps
docker --context desktop-linux compose logs -f --tail=100
docker --context desktop-linux compose logs -f gameserver
```

MariaDB e RPC ficam na rede interna. As portas do cliente são publicadas em localhost: 38101 e 38111. O volume `cabal-local_database` persiste os dados; `down` preserva o volume. `down -v` apaga os dados.

O banco local usa `--skip-ssl` na rede privada do Compose para evitar falhas de certificados automáticos causadas por diferenças de relógio na VM do Desktop; a porta do banco não é publicada.

## Transferência do Engine WSL para Desktop

```powershell
.\scripts\docker.ps1 migrate
```

Esta ação prepara o destino no Desktop, para os servidores no Engine Ubuntu-24.04, transfere os dois bancos em memória sem criar backup e compara as contagens de todas as tabelas. Recusa sobrescrever um destino com jogadores. Após concluir, remove os containers de origem e preserva seu volume. `.runtime/desktop-migrated` registra a conclusão para evitar uma nova importação.

A transferência exige WSL e Python3 apenas para acessar o Engine de origem. Se falhar, a origem permanece preservada e seus servidores ficam parados para evitar escrita concorrente. Não reinicie duas cópias do backend ao mesmo tempo. Alterações posteriores no Desktop não voltam automaticamente à origem.

O script `docker-local.sh` continua disponível para Linux/CI e usa o daemon desse ambiente. Um Engine independente no WSL possui containers e volumes separados; seus serviços não aparecem no Desktop. A antiga migração do MariaDB nativo permanece em `bash scripts/docker-local.sh migrate`.

## Dados e validação

`DB_PASSWORD` e `DB_ROOT_PASSWORD` são aplicados na primeira inicialização do volume. Alterar `.env` posteriormente exige alterar também os usuários SQL. Não publique `.env` nem credenciais em `.runtime`.

Backups são opcionais, criados somente pela ação `backup`; o wrapper Windows usa prefixo `desktop-`. A transferência para Desktop não cria backup. Para criar/verificar a conta local: `docker.ps1 create-local-account`. Para testar Go dentro do builder Docker: `docker.ps1 test`.

Healthchecks verificam prontidão do banco e portas em escuta; `smoke-test` verifica também acesso TCP pelo Windows. Login completo e jogabilidade precisam de validação no cliente.

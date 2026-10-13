# Backend no Docker

MariaDB, MasterServer, LoginServer e GameServer executam em containers separados no Docker. Execute os comandos abaixo no terminal da distribuição WSL; o cliente do jogo pode continuar no Windows.

Inicie o Docker Desktop com containers Linux e ative a integração com sua distribuição WSL em **Settings > Resources > WSL Integration**. Na raiz do projeto dentro do WSL, execute:

```bash
make start
```

Para iniciar e acompanhar os logs, execute `make start-logs`. Ctrl+C encerra o acompanhamento e mantém os containers ativos.

```bash
make status
make logs
make logs-follow
make smoke-test
make down
```

Não é necessário Go, MariaDB ou um Engine independente para uma instalação nova. `make up` gera as credenciais ausentes em `.env`, constrói as imagens e aguarda todos os serviços saudáveis. Credenciais existentes são preservadas.

Os comandos Docker diretos devem usar o mesmo contexto:

```bash
docker compose ps
docker compose logs -f --tail=100
docker compose logs -f gameserver
```

MariaDB é publicado apenas em localhost: 3306; RPC fica na rede interna. As portas do cliente são publicadas em localhost: 38101 e 38111. O volume `cabal-local_database` persiste os dados; `make down` preserva o volume. `docker compose down -v` apaga os dados.

O banco local usa `--skip-ssl` para evitar falhas de certificados automáticos causadas por diferenças de relógio na VM do Docker Desktop. No DataGrip, crie uma fonte MariaDB com host `127.0.0.1`, porta `3306`, usuário `cabal_local` e a senha `DB_PASSWORD` do `.env`. Deixe SSL desativado e selecione os schemas `cabal_login` e `cabal_world`. Após alterar a publicação da porta, aplique com `docker compose up -d --no-deps database`.

## Migração do banco nativo

```bash
make migrate
```

Esta ação prepara o destino Docker, transfere os dois bancos em memória sem criar backup e compara as contagens de todas as tabelas. Recusa sobrescrever um destino com jogadores. Após concluir, remove os processos de origem e preserva seu backup. `.runtime/docker-migrated` registra a conclusão para evitar uma nova importação.

A transferência exige Python3 para acessar a origem. Se falhar, a origem permanece preservada e seus servidores ficam parados para evitar escrita concorrente. Não reinicie duas cópias do backend ao mesmo tempo. Alterações posteriores no Docker não voltam automaticamente à origem.

O Makefile usa o Docker disponibilizado à distribuição WSL. Um Engine independente no WSL possui containers e volumes separados; seus serviços não aparecem no Docker Desktop.

## Dados e validação

`DB_PASSWORD` e `DB_ROOT_PASSWORD` são aplicados na primeira inicialização do volume. Alterar `.env` posteriormente exige alterar também os usuários SQL. Não publique `.env` nem credenciais em `.runtime`.

Backups são opcionais, criados somente pela ação `backup`, com prefixo `docker-`. A transferência não cria backup. Para criar/verificar a conta local: `make create-local-account`. Para testar Go dentro do builder Docker: `make test`.

Healthchecks verificam prontidão do banco e portas em escuta; `smoke-test` verifica também acesso TCP pelo Windows. Login completo e jogabilidade precisam de validação no cliente.

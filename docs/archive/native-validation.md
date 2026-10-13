# Relatório de execução — 12/10/2026

## Base

Freya development, fb5bbcce67a448075f1b139ee5d269d26f910043, MIT. Cópia versionada em backend/ para permitir patches no repositório existente sem criar remoto/fork. Documento original preservado. Nenhum commit/push realizado.

## Arquivos

- backend/: código, módulos, schema, scripts, dados e licença upstream. Patches em share/network/network.go, share/rpc/server.go, share/directory/directory.go, cmd/masterserver/rpc/character.go e sql/login.sql (remoção do seed).
- backend/share/policy/: política e teste do HP inicial.
- backend/cmd/masterserver/rpc/character_integration_test.go: persistência e rollback em banco descartável.
- scripts/: pré-requisitos, build, testes, banco, start/stop, smoke, backup, restore-test e wrapper local.ps1.
- .env.example, .gitignore, .gitattributes: configuração sem segredos e exclusão dos artefatos.
- docs/: arquitetura, versões, setup, cliente, alteração, troubleshooting, roadmap e este relatório.
- .github/workflows/build.yml: build/test e integração MariaDB; não executado no GitHub.

## Comandos e resultados

- git status/remote/branch e inspeção de fontes: executados, branch main e origin preservados.
- wsl --list --verbose: Ubuntu-24.04 WSL2 instalado; sandbox inicialmente negou acesso, consulta autorizada funcionou.
- apt update/install: Go 1.22.2 e MariaDB 10.11.14 instalados; lock temporário aguardado.
- bash scripts/build.sh: três executáveis compilados. GOPROXY=direct resolveu falha de DNS em downloads.
- bash scripts/test.sh: go test ./... passou; maioria dos pacotes upstream não contém testes.
- bash scripts/integration-test.sh: PASS TestCreateCharacterPersistence em banco isolado; banco/usuário temporários removidos.
- bash scripts/db-init.sh: schema importado sem conta padrão; segunda execução passou sem sobrescrever tabelas.
- bash scripts/start-local.sh / stop-local.sh: iniciados, parados e reiniciados os processos próprios.
- bash scripts/smoke-test.sh: SELECT nos dois bancos e TCP nas três portas passaram; listeners dos serviços e MariaDB em 127.0.0.1.
- bash scripts/backup.sh / restore-test.sh: dump gerado e restaurado em bancos isolados, tabelas/contagens iguais; bancos reais vazios nesta validação.
- scripts/local.ps1 check-prerequisites/smoke-test: executados no PowerShell, passaram.
- git diff --check: passou (arquivos novos ainda não estão no índice; revisão adicional de whitespace executada separadamente).

## Marcos

| Marco | Status | Evidência/limite |
|---|---|---|
| Ambiente/build | VALIDADO | Go, MariaDB e três binários no WSL |
| Banco | VALIDADO | Schema, conexão, setup repetido, backup/restore vazio |
| Serviços | VALIDADO | Processos ativos e listeners localhost; não comprova protocolo |
| Regra inicial | VALIDADO | HP 50/100, itens persistidos, erro inválido e rollback |
| Cliente/jogabilidade | BLOQUEADO | Cliente EP8 autorizado ausente |
| E2E do protocolo | BLOQUEADO | Login/mundo/logout/reconexão dependem do cliente |
| CI remoto | PARCIAL | Workflow preparado; execução GitHub não realizada |

## Limites e rollback

Sem conta de jogador criada automaticamente. Provisionamento com bcrypt e senha escolhida fica para a próxima etapa. Combate, experiência, economia geral, persistência após logout e suporte a uma build específica de cliente não foram demonstrados. Upstream experimental ainda contém erros/panics em outros fluxos. Não foi feito scan de segurança abrangente.

Para reverter a regra, use CABAL_INITIAL_HP_PERCENT=100 em .env e reinicie; personagens já criados mantêm seus dados. Para interromper serviços próprios, use stop-local. Não remova bancos ou restaure dados reais sem backup e autorização. Credenciais e logs estão ignorados no Git; proteger também com ACL do Windows.

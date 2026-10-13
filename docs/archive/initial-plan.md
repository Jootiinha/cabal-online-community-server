# Implementação orientada ao Codex — Cabal Online local e extensível

> **Documento de execução para o Codex**  
> Projeto: servidor Cabal Online para desenvolvimento local  
> Decisão inicial: avaliar e integrar **ubis/Freya (Go, EP8)** como núcleo de emulador modificável  
> Destino: **o repositório Git já existente**, local e hospedado no GitHub  
> Prioridade: ambiente reproduzível, alterações básicas de gameplay/economia, arquitetura que permita novas funcionalidades  
> Estado: plano de execução; **não presume que o cliente Cabal EP8 esteja disponível**

## Instrução principal ao Codex

Você está trabalhando **dentro do meu repositório existente**. Sua missão é transformar este repositório em um workspace de desenvolvimento para um servidor Cabal Online local, com um emulador de código aberto modificável, persistência, scripts de inicialização, documentação, testes e um pequeno exemplo real de regra de gameplay configurável.

**Trabalhe de forma incremental, implementando o que for possível com os arquivos e dependências disponíveis.** Não apenas descreva o que faria: crie arquivos, configure os projetos, execute os comandos e registre os resultados. Não afirme que o jogo está jogável sem validar com um cliente compatível.

### Regras obrigatórias

1. **Inspecione primeiro** o repositório: `pwd`, `git status --short`, `git remote -v`, `ls -la`, arquivos de configuração, instruções e eventual `AGENTS.md`. Respeite as convenções e instruções existentes.
2. **Não sobrescreva nem remova** arquivos, mudanças locais ou histórico existentes. Se houver conflito, preserve os dados e relate o bloqueio.
3. Verifique os `remotes` e branches antes de operar. **Não crie outro repositório Git na raiz**, não faça `git init`, `git push`, alterações de remoto ou force-push sem minha autorização explícita.
4. Priorize **código-fonte verificável e licitamente utilizável**. O repositório [ubis/Freya](https://github.com/ubis/Freya) é o primeiro candidato. Verifique diretamente licença, README, branch, árvore, scripts SQL e compatibilidade de compilação antes de integrar.
5. Registre o **hash exato do commit upstream**. Não presuma que a branch `development`, o Makefile, os scripts SQL ou os comandos deste documento continuam iguais: valide cada um.
6. **Não baixe clientes de Cabal, assets proprietários, servidores vazados, cracks ou executáveis de procedência duvidosa.** Não contorne anticheat, DRM ou proteções do cliente. O cliente autorizado e compatível é dependência externa a ser fornecida separadamente.
7. Não coloque senhas, chaves, dumps contendo dados de jogadores, arquivos de cliente ou binários proprietários no Git. Use `.env.example` sem segredos e ignore `.env` real.
8. Mantenha os serviços e o banco restritos a **localhost/rede privada** por padrão. Não abra portas públicas, não implante em produção e não crie contas administrativas com senhas padrão.
9. Faça alterações de gameplay/economia **no lado servidor**, com validação de entradas, consistência transacional e testes. Não implemente edição direta de saldo Alz ou inventário como regra de negócio.
10. **Não invente** nomes de arquivos, funções, APIs, tabelas, portas, pacotes de rede ou suporte funcional. Sempre aponte o código ou configuração encontrados.
11. Use testes de integração e E2E para os fluxos críticos, especialmente persistência e economia. Adicione testes unitários apenas quando isolarem regras puras relevantes; não produza testes de baixo valor por obrigação.
12. Se a execução do cliente for inviável, **conclua o restante** (build, banco, serviços, testes, documentação) e reporte o bloqueio com evidências e ações precisas necessárias.

## Critérios gerais de conclusão

O trabalho inicial está concluído quando o repositório contém:

- Código do emulador integrado de forma reproduzível (preferencialmente fork referenciado ou submódulo; escolha após inspecionar o repositório existente).
- `docs/architecture.md`, `docs/setup-local.md`, `docs/versions.md`, `docs/troubleshooting.md`, `docs/roadmap.md`.
- Scripts idempotentes para preparar, validar, compilar e iniciar serviços, sem depender de diretórios absolutos da máquina do desenvolvedor.
- Configuração do banco local com credenciais externas ao Git, provisionamento e importação revisada do schema upstream.
- Testes de smoke e integração executáveis, com logs e resultados documentados.
- **Uma alteração básica e reversível de regra implementada de fato no emulador**, com teste demonstrando o comportamento anterior e o novo.
- Um resumo final com itens **implementados**, **validados**, **não validados** e **bloqueados** — distinguindo execução dos processos de jogabilidade real.

---

## Fase 0 — Reconhecimento e decisão de integração

**Objetivo:** adaptar o plano à estrutura real do repositório, sem destruir trabalho existente.

**Execute:**

```bash
pwd
git status --short
git remote -v
git branch --show-current
find . -maxdepth 2 -type f | head -100
```

1. Leia o `README`, `AGENTS.md`, `.gitignore`, manifests e automações existentes.
2. Identifique SO de execução: Windows + WSL2 Ubuntu 24.04, Ubuntu nativo, ou outro ambiente.
3. Faça um diagnóstico de dependências (`git`, `go`, `make`, MariaDB, compiladores), sem instalar pacotes silenciosamente caso exijam `sudo` ou acesso externo.
4. Examine o Freya upstream: licença, status de manutenção, layout, branches, dependências, comandos de build, arquivos `cfg`, `sql` e processos reais.
5. Escolha a estratégia de integração:
   - **Submódulo Git** quando quisermos preservar upstream claramente e manter alterações em um fork próprio.
   - **Fork como repositório principal** quando o repositório atual já for destinado exclusivamente ao emulador.
   - **Cópia versionada com atribuição e licença** apenas quando submódulo/fork não forem apropriados e a licença permitir.
6. Justifique a escolha em `docs/architecture.md`. Não crie submódulo aninhado inadvertidamente.
7. Adicione `docs/versions.md` com URLs, commit SHA, licença e versões de ferramentas testadas.

**Aceite:** estrutura escolhida documentada e `git status` conhecido; nenhuma mudança de usuário perdida.

## Fase 1 — Preparação do ambiente local

**Objetivo:** permitir que outra pessoa reproduza a configuração.

Ambiente de referência: **Windows 11 + WSL2 Ubuntu 24.04** ou Ubuntu 24.04 nativo; Go e MariaDB na versão compatível identificada pela auditoria.

No WSL, o usuário poderá executar, se necessário:

```powershell
wsl --install -d Ubuntu-24.04
```

No Ubuntu, exemplos iniciais **sujeitos às dependências verificadas**:

```bash
sudo apt update
sudo apt install -y git make build-essential golang-go mariadb-server mariadb-client
```

**Codex:** automatize checagens de pré-requisitos, não assuma `sudo` disponível, não instale componentes de modo irreversível. Crie scripts como `scripts/check-prerequisites.sh` e documente comandos manuais caso falte acesso.

**Aceite:** relatório de ferramentas instaladas, versões e eventuais incompatibilidades.

## Fase 2 — Integrar e compilar Freya

**Objetivo:** compilar os serviços reais do emulador e produzir artefatos locais.

1. Confirme se existem `cmd/loginserver`, `cmd/gameserver`, `cmd/masterserver` e o Makefile na revisão escolhida.
2. Identifique se o projeto usa módulos Go, GOPATH ou outro mecanismo legado e corrija o ambiente da forma **menos invasiva**, documentando qualquer patch necessário.
3. Crie `scripts/build.sh` com mensagens de erro claras, rodando os comandos da revisão verificada (e não comandos assumidos).
4. Se confirmado pelo código, o procedimento pode ser semelhante a:

```bash
make
# ou, se a estrutura real suportar:
go build -o ./bin/loginserver ./cmd/loginserver
go build -o ./bin/gameserver ./cmd/gameserver
go build -o ./bin/masterserver ./cmd/masterserver
```

5. Não inclua builds compilados no repositório sem justificativa. Documente `go version`, comando, SHA e resultado.

**Aceite:** serviços compilados sem erros, ou erros diagnosticados com linhas e dependências exatas. A compilação **não é** validação de gameplay.

## Fase 3 — Banco de dados e configuração local

**Objetivo:** inicializar as dependências de persistência com segurança.

1. Inspecione os scripts SQL upstream antes de qualquer importação; identifique bancos, tabelas, seeds, defaults e alterações destrutivas.
2. Verifique se a revisão usa `login`/`world`, MariaDB e quais credenciais/configurações são esperadas.
3. Implemente `scripts/db-init.sh` de maneira segura para ambiente de testes, preferencialmente não destrutiva e com confirmação antes de sobrescrever dados.
4. Forneça `.env.example` com variáveis **baseadas nos campos realmente presentes** e documente como criar `.env` local.
5. Não exponha o banco publicamente. Configure usuário com escopo limitado às bases do projeto.
6. Implemente backup e restauração documentados, validando em banco descartável antes de adotar migrations modificadas.

Exemplo **ilustrativo**, somente se confirmado o schema `login`/`world`:

```sql
CREATE DATABASE IF NOT EXISTS login CHARACTER SET utf8mb4;
CREATE DATABASE IF NOT EXISTS world CHARACTER SET utf8mb4;
```

**Aceite:** conexão validada, schemas importados, tabelas verificadas, sem segredos no Git.

## Fase 4 — Inicialização e teste dos serviços

**Objetivo:** executar os componentes necessários dentro da máquina local.

1. Identifique a ordem de inicialização e diretório de execução necessários.
2. Crie `scripts/start-local.sh`, `scripts/stop-local.sh`, `scripts/smoke-test.sh` se compatíveis com a plataforma e comportamento dos processos.
3. Capture logs por serviço com caminhos locais ignorados pelo Git.
4. Verifique listeners via `ss -lntp`, conectividade com MariaDB, ausência de `panic` e falhas repetidas.
5. Documente todas as portas **descobertas na configuração real**. Não invente valores.
6. Não anuncie serviços expostos para a internet nem configure roteador/firewall público.

**Aceite:** serviços permanecem ativos e suas dependências passam no smoke test. Registre quais processos foram iniciados e as evidências.

## Fase 5 — Cliente e primeira sessão jogável (gate externo)

O Freya declara cliente **EP8**; ele **não inclui** necessariamente um cliente Cabal utilizável, nem o código-fonte dele. **Não presuma compatibilidade com EP33.**

1. Identifique na documentação upstream os requisitos precisos da build cliente e os parâmetros de conexão conhecidos.
2. Escreva `docs/client-compatibility.md` com informações confirmadas; não distribua cliente ou assets.
3. **Se eu fornecer um cliente legalmente obtido e compatível**, configure apenas as opções documentadas/autorizadas de endereço local.
4. Teste na sequência: conexão → autenticação → lista/criação de personagens → entrada no mundo → logout → reconexão → persistência.
5. Se o cliente não estiver disponível, classifique esta etapa como **BLOQUEADA — CLIENTE EXTERNO**, sem criar um cliente fictício nem alegar sucesso.

**Aceite:** fluxo completo demonstrado por logs e testes, ou bloqueio explícito bem documentado.

## Fase 6 — Primeira modificação real de gameplay/economia

**Objetivo:** demonstrar que nossa base é modificável e segura.

1. Busque as regras existentes no código (`exp`, `experience`, `loot`, `drop`, `reward`, `alz`, `price`, `inventory`) e liste os arquivos/funções encontrados.
2. Escolha **uma regra que realmente exista** e possa ser validada sem depender de interface nova: preferencialmente **multiplicador de experiência/recompensa**, se o fluxo estiver implementado; alternativa: uma regra simples de taxa/custo já suportada. Se não existir, implemente uma regra pequena em um fluxo comprovadamente disponível.
3. Introduza configuração explícita e valor padrão que **preserve o comportamento original**.
4. Separe lógica de regra da persistência, valide limites, arredondamentos e condições de overflow.
5. Teste valor padrão e novo valor. Use testes de integração para verificar persistência e repetição do fluxo; testes unitários apenas para cálculo puro relevante.
6. Documente em `docs/first-customization.md`: localização do código, configuração, comando de build, teste, efeito observado e rollback.
7. Não altere saldo diretamente por SQL como solução definitiva e não implemente injeção de código em cliente ou binário proprietário.

**Aceite:** diff pequeno e reversível, build passando, testes comprovando comportamento e configuração documentada. Se o emulador não implementar o fluxo, informe claramente a limitação e crie um plano objetivo para habilitá-lo.

## Fase 7 — Preparação para extensibilidade futura

**Objetivo:** não deixar a primeira mudança se tornar dívida arquitetural.

Proponha e, quando houver sustentação no código real, implemente interfaces mínimas para:

- Políticas econômicas (recompensas, custos e regras de emissão/consumo de Alz).
- Trilhas de auditoria de operações relevantes para economia e inventário.
- Eventos de domínio para ações realmente executadas pelo servidor.
- Configuração por ambiente, validação e telemetria básica.

**Não crie arquitetura especulativa grande ou serviços externos sem necessidade atual.** Registre a proposta de módulos em `docs/roadmap.md`; implemente primeiro apenas o que sustenta a Fase 6.

## Fase 8 — CI e documentação para continuidade

1. Se o repositório utilizar GitHub Actions, adicione workflow seguro de build/testes, sem dependência de cliente proprietário.
2. Mantenha lint e `git diff --check`; execute `go test ./...` somente onde fizer sentido na revisão e registre limitações.
3. Atualize o `README.md` com pré-requisitos, execução local, testes, como fazer a primeira modificação e limitações.
4. Não efetue `push` sem aprovação. Prepare mudanças revisáveis em commits pequenos **somente se a política do ambiente permitir**.

---

## Organização sugerida (adaptar ao repositório existente)

```text
<repo-existente>/
├── README.md
├── AGENTS.md                        # somente se não conflitar com instruções existentes
├── .gitignore
├── .env.example
├── docs/
│   ├── architecture.md
│   ├── setup-local.md
│   ├── versions.md
│   ├── client-compatibility.md
│   ├── first-customization.md
│   ├── troubleshooting.md
│   └── roadmap.md
├── scripts/
│   ├── check-prerequisites.sh
│   ├── build.sh
│   ├── db-init.sh
│   ├── start-local.sh
│   ├── stop-local.sh
│   └── smoke-test.sh
└── <caminho-do-freya-selecionado>/   # fork, submódulo ou outra estratégia justificada
```

## Formato do relatório final obrigatório

Ao concluir a execução, responda com:

1. **Resumo executivo:** qual base e revisão foram integradas e por quê.
2. **Arquivos criados/modificados:** caminhos e propósito.
3. **Comandos executados:** build, setup e testes, com sucesso/erro.
4. **Status dos marcos:** ambiente, banco, serviços, cliente, gameplay; use `VALIDADO`, `PARCIAL` ou `BLOQUEADO`.
5. **Primeira funcionalidade alterada:** arquivo/função, diferença de comportamento e prova do teste.
6. **Próximos bloqueios externos:** em especial cliente EP8 compatível, credenciais ou dependências indisponíveis.
7. **Como rodar agora:** comandos exatos adequados ao ambiente e aos caminhos reais.
8. **Pendências e riscos:** o que não foi testado, pontos frágeis e passos para rollback.

**Comece agora pela Fase 0 e prossiga pelas demais fases sem pedir confirmação para tarefas locais, seguras e reversíveis. Solicite autorização apenas para ações destrutivas, uso de privilégios, alterações em recursos externos, publicação de código ou escolhas que exijam arquivos/direitos ausentes.**

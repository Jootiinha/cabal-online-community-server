# Validação Docker — 12/10/2026

Executado nesta máquina Windows com Ubuntu-24.04 WSL2 e Docker Engine 29.6.1 / Compose 5.3.1.

- Construção das imagens Go 1.26 e MariaDB 11.4 concluída.
- Configuração Compose validada; scripts Bash, Python e PowerShell conferidos.
- Suíte `go test ./...` passou no WSL (Go 1.22.2) e dentro do builder Docker (Go 1.26).
- Banco nativo exportado para `.runtime/backups/20261012-202443.sql` e importado no volume Docker. Todas as tabelas e contagens conferidas. Uma conta e zero personagens no momento da migração.
- Quatro containers saudáveis: database, masterserver, loginserver e gameserver.
- Logs confirmaram conexões aos dois bancos e registro RPC de LoginServer e GameServer 1/1 no MasterServer.
- Portas 38101 e 38111 verificadas por TCP no WSL e pelo Windows.
- Backup Docker gerado em `.runtime/backups/docker-20261012-202551.sql`.
- Banco nativo e backup preservados para recuperação. Credenciais do jogador preservadas.

Healthchecks dos servidores verificam portas em escuta. O smoke test acrescenta consulta SQL e conexão às portas publicadas. Login completo e jogabilidade no cliente não foram testados nesta migração.

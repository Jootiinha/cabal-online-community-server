# Diagnóstico

- WSL/E_ACCESSDENIED dentro do sandbox: consultas/execução precisam de autorização fora do sandbox.
- sudo exige senha: comandos administrativos usam wsl -u root explicitamente; não há senha padrão criada.
- apt bloqueado por unattended-upgrades: aguarde o lock; não remova arquivos de lock.
- proxy.golang.org falha DNS: no Ubuntu, `GOPROXY=direct bash scripts/build.sh`. Não desabilite checksums.
- MariaDB ignora client.cnf no NTFS: smoke/backup copiam a configuração para arquivo temporário Linux modo 600 e removem ao finalizar.
- Porta ocupada: examine `ss -lntp` e logs em .runtime/logs; não finalize processos desconhecidos.
- GameServer_1_1.ini: Linux distingue maiúsculas; start-local cria o nome esperado por def.GetName.
- Smoke TCP gera mensagem de contexto inválido no GameServer porque não envia protocolo Cabal; isso é esperado para essa sonda, sem comprovar handshake válido.

Backup usa dump transacional. A ação restore-test restaura em bancos descartáveis e compara tabelas e contagens com os bancos locais; foi validada com bancos locais vazios. Para restaurar nos bancos reais, primeiro pare os serviços e escolha explicitamente o backup: essa restauração é destrutiva e manual. Não importe cegamente em banco com dados.

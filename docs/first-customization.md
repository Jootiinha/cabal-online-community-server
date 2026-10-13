# HP inicial configurável

Fluxo real: backend/cmd/masterserver/rpc/character.go, CreateCharacter, lê hp em data/initial_data.yml. Warrior inicia com 50 HP. CABAL_INITIAL_HP_PERCENT=100 preserva isso; 200 gera 100 HP para personagens novos. Atual e máximo usam o mesmo valor; personagens existentes não mudam.

Política pura em share/policy/initial_hp.go: porcentagem 1..1000; base 1..65535; cálculo int64 com arredondamento para baixo; resultado 1..65535; valores inválidos retornam erro antes de persistir. BattleStyle zero também é rejeitado antes de indexar a lista. Não houve mudança direta de Alz/inventário por SQL.

CreateCharacter usa uma transação para personagem, equipamento, inventário, habilidades, atalhos e metadata; falhas retornam erro com rollback. Teste de integração chama o handler real em banco descartável, verifica HP 50/100 e itens persistidos, configuração inválida e falha forçada no inventário após inserir personagem. Não usa cliente nem valida protocolo de rede.

Edite .env e execute `powershell -ExecutionPolicy Bypass -File scripts/docker.ps1 up` para reconstruir e atualizar os serviços. Para rollback da regra: CABAL_INITIAL_HP_PERCENT=100 e reinicie. Isso preserva dados existentes; não desfaz HP de personagens já criados. Testes: ações test e integration-test.

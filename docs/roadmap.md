# Próximas etapas

1. Fornecer cliente EP8 autorizado e método documentado de conexão; criar conta local com senha escolhida e bcrypt, conforme AuthCheck, sem conta padrão.
2. E2E real: autenticação, criação, mundo, logout/reconexão e persistência. Combate/recompensa de experiência não foram demonstrados: evitar multiplicador fictício.
3. Ampliar testes dos handlers de inventário, auditoria e transações. Diversos fluxos upstream ainda usam MustExec e não têm tratamento robusto de erros.
4. Políticas econômicas e eventos somente quando fluxo real exigir. A política de HP atual é pequena e não cria serviços ou framework especulativos.
5. Evoluir db-init para migrations verificadas com marcador de versão, checksums e recuperação de importação parcial.
6. Revisar limites de pacotes, autorização RPC e vínculo conta/personagem antes de ampliar o escopo de rede. Ambiente atual fica em localhost.

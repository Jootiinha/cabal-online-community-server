# Cliente local EP8

O launcher abre `.client/CabalMain.exe` por padrão; `scripts/Start-CabalLocal.ps1 -ClientExecutable caminho` seleciona outra cópia. O cliente atual tem FileVersion 1.0.0.374. A pasta `.client/` não é versionada.

O endereço de login deve ser `127.0.0.1:38101`. Nesta cópia, a configuração fica em `Data/language/portuguese/language.enc` e usa a chave XOR `92681515`.

Para verificar a configuração pelo WSL, a partir da raiz:

```bash
python3 scripts/client-config.py .client --config Data/language/portuguese/language.enc --xor-hex 92681515
```

Acrescente `--apply` para corrigir os endereços locais; o script verifica o formato e preserva a configuração anterior. Não altera os executáveis do cliente.

Login, seleção de servidor e criação de personagem foram confirmados no cliente. A falha na primeira entrada no mapa foi identificada como nível zero no personagem em memória; o RPC foi corrigido para retornar os defaults persistidos. A jogabilidade posterior depende de validação no cliente.

Os serviços CHS nas portas 38121/38125/38122/38123 não estão implementados. EP33 não foi validado. Veja [atribuições](THIRD_PARTY_NOTICES.md) e [investigação histórica](archive/client-investigation.md).

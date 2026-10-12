# Gate do cliente

README upstream declara suporte EP8. cfg/loginserver.ini contém client_version=1422, magic_key=709182467 e ignore_client_version=1. Isso não comprova compatibilidade de qualquer distribuição EP8; EP33 não foi validado. Esses campos foram preservados, sem implementação de contorno de proteção.

Cliente local informado posteriormente pelo usuário em C:\Users\joaoc\Downloads\TGCabalEP8\TGCabalEP8, com autorização declarada para configuração local. cabalmain.exe tem FileVersion 1.0.0.369, ProductVersion 1.0.0.9000, assinatura Authenticode válida ESTsoft, SHA256 12D56A37C78424B6202D04FAF3B9BB82B2B25FD680D238F4418FE773F4A60558. Isso não confirma sua build de protocolo.

Data/language.enc contém configurações [Svr] com campos 1_Login_Addr, 2_Login_Addr, 1_LoginEX_Addr, 1_LoginTest_Addr e chsAddr. Os endereços foram alterados para 127.0.0.1; portas preservadas (login 38101, chs 38121/38125/38122/38123). Esses serviços adicionais chs não existem no Freya integrado e não foram habilitados. Configuração anterior preservada em Data/language.enc.local-backup. Executáveis, XTrap e opções de integridade não alterados.

Formato ENC verificado no projeto MIT https://github.com/Michael-K-GH/libcozip, commit eff32a6bc2964703da06b03e094acbf6a4e5ef0e: tamanho uint32, DEFLATE raw e XOR nos primeiros quatro bytes compactados. Script scripts/client-config.py verifica tamanho, stream e roundtrip antes de editar somente os endereços. Licença em scripts/LICENSE-libcozip.txt. Wiki Freya confirma language.enc como configuração: https://github.com/ubis/Freya/wiki/Configuration.

Portas 9001/38101/38111 verificadas também por TCP a partir do Windows (localhost forwarding funcional). Cliente iniciado para teste, mas nenhuma tela/login/handshake válido foi observado até este registro. Launcher.exe não tem assinatura e contém URLs cabal.gamestheft.com; execução do launcher não foi testada. Compatibilidade e jogabilidade permanecem NÃO VALIDADAS.

Conta localplayer provisionada com senha aleatória, bcrypt e status Normal (32). Credenciais somente em .runtime/player-credentials.json, ignorado no Git. A ação create-local-account não redefine senha de uma conta existente. Leia o arquivo local para login; não envie senha no chat. Para rollback do endereço, feche o cliente e restaure language.enc.local-backup sobre language.enc. Nenhum arquivo do cliente foi copiado para Git.

Com cliente autorizado e opções documentadas de conexão local: validar conexão, autenticação, listagem/criação, entrada no mundo, logout, reconexão e persistência. WSL localhost forwarding para o cliente Windows ainda precisa de teste. Nunca equiparar os testes TCP à jogabilidade.

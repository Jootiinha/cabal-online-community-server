# Licenças e atribuições

## Código do backend

O backend deriva de [ubis/Freya](https://github.com/ubis/Freya), branch development, commit `fb5bbcce67a448075f1b139ee5d269d26f910043` de 22/12/2023. A licença MIT e o copyright de Jokubas Maciulaitis estão preservados integralmente em [backend/LICENSE](../backend/LICENSE).

O código passou a usar o módulo local `cabal-online-community-server`. Essa mudança de nome não modifica a atribuição do código original. As dependências Go e seus checksums estão em `backend/go.mod` e `backend/go.sum`.

## Formato da configuração do cliente

O formato ENC foi verificado com [libcozip](https://github.com/Michael-K-GH/libcozip), commit `eff32a6bc2964703da06b03e094acbf6a4e5ef0e`. A licença MIT correspondente está em [scripts/LICENSE-libcozip.txt](../scripts/LICENSE-libcozip.txt).

## Arquivos externos

O cliente local não é distribuído por este repositório. Os mapas binários foram recebidos com o código original; sua origem individual não foi auditada. Relatórios da integração inicial estão em `docs/archive/`.

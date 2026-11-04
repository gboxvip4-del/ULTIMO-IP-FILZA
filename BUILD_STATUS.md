# Build status — GBOXIOSVIP 2.1 build 2

Esta Source foi adaptada para a IPA de referência `3105-2.1-beta2-no-key-ui-unsigned.ipa`.

## Identidade aplicada

- Nome exibido: `GBOXIOSVIP`
- Executável: `3105`
- Bundle ID: `com.apple.mobile.MobileHouseArrest`
- Marketing version: `2.1`
- Build: `2`
- Deployment target: iOS 16.0
- Arquiteturas: arm64

## Autenticação por IP

- A tela de login e a consulta à API estão temporariamente desativadas; o app abre diretamente na tela principal.
- O código de validação por IP permanece no projeto, mas não é acionado enquanto a tela de login estiver desativada.
- O fluxo não solicita nem transmite key de licença ou HWID.

## Patches incluídos

A pasta `ThreeOneOSFive/Resources/OfficialPatches` contém cinco pacotes protegidos: `RESET GUEST` e os quatro patches do ZIP do MediaFire (`HS PEITO COM ANTENA`, `HS BARRIGA COM ANTENA`, `HS PESCOÇO - ALTO COM ANTENA` e `BALA MÁGICA COM ANTENA`). Os outros pacotes antigos foram removidos do bundle e da lista principal.

## CodeMagic

O workflow `ios-unsigned` gera `build/ipa/GBOXIOSVIP.ipa` sem assinatura, confere a presença dos cinco pacotes `.mfp` e rejeita arquivos `.3105` desprotegidos. Para instalar em dispositivo, use os certificados/provisioning profiles da sua conta Apple em uma etapa de assinatura compatível. Nenhuma chave ou segredo foi incluído.

## Layout dos patches

As linhas de patch não renderizam ícone, checkbox ou quadrado lateral. O único controle visual à direita é o switch; o status permanece abaixo do nome.

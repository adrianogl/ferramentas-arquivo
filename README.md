# Ferramentas de Arquivo

App de barra de menus para macOS que resolve tarefas de PDF e imagem direto no Finder, sem subir arquivo para nenhum site. ⌥ + clique direito num arquivo abre um menu circular com as ações:

- Otimizar PDF (até o limite configurado, 1 MB por padrão)
- Juntar PDFs
- Dividir PDF
- Organizar PDF
- Imagens para PDF
- PDF para JPG
- PDF para Markdown

As mesmas ações também aparecem no clique direito normal do Finder, em Serviços. Tudo roda na sua máquina, sem rede, e o arquivo original nunca é sobrescrito: a saída vai para a pasta do original.

## Instalação

Requer macOS 26 ou mais novo. Roda em Mac com Apple Silicon e em Mac com Intel.

1. Baixe o `.zip` da última release e abra.
2. Arraste "Ferramentas de Arquivo" para a pasta Aplicativos.
3. Na primeira abertura, o macOS avisa que não consegue verificar o app, porque ele não é notarizado. Feche o aviso, abra Ajustes do Sistema → Privacidade e Segurança e clique em "Abrir assim mesmo".

## Permissões

O assistente de primeira abertura pede e explica cada uma:

- Acessibilidade: para capturar o ⌥ + clique direito sem atrapalhar o Finder.
- Automação do Finder: para saber quais arquivos estão selecionados.

## Depois de atualizar

O macOS pode pedir a Acessibilidade de novo, porque a assinatura ad hoc muda a cada versão. O assistente abre sozinho nesse caso. Se o app já aparecer ligado na lista, desligue e ligue de novo (ou remova com − e adicione outra vez).

## Build a partir do código

Requer Xcode 27 ou mais novo.

```bash
swift test
scripts/build-app.sh --install
```

O script assina com a variável `SIGN_IDENTITY`, se estiver definida. Sem ela, usa o primeiro certificado "Apple Development" do keychain e, na falta dele, assina ad hoc. Com um certificado estável, as permissões sobrevivem a rebuilds. `--adhoc` força a assinatura ad hoc.

Para gerar o zip de uma release: `scripts/release.sh <versão>`.

## Licença

[MIT](LICENSE)

## Apoie

[![Buy me a coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=adrianogl&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff)](https://www.buymeacoffee.com/adrianogl)

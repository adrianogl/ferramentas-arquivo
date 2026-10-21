# Ferramentas de Arquivo

App de barra de menus para macOS que resolve tarefas de PDF e imagem direto no Finder, sem subir arquivo para nenhum site. ⌥ + clique direito num arquivo abre um menu circular com as ações:

- Otimizar PDF (até o limite configurado, 1 MB por padrão)
- Juntar PDFs
- Dividir PDF
- Organizar PDF
- Imagens para PDF
- PDF para JPG
- PDF para Markdown

As mesmas ações também aparecem no clique direito normal do Finder, em Ações Rápidas.

## Build e instalação

```bash
scripts/build-app.sh --install
```

Na primeira execução, o macOS pede permissão de Acessibilidade (para capturar o ⌥ + clique direito) e de Automação do Finder (para saber quais arquivos estão selecionados).

## Testes

```bash
swift test
```

## Apoie

[![Buy me a coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=adrianogl&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff)](https://www.buymeacoffee.com/adrianogl)

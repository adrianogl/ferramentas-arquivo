# Contribuindo

## Testes

```bash
swift test
```

O build precisa passar sem warnings e os testes sem falhas antes de abrir a PR. Lógica nova vai com teste.

## Convenções

- Identificadores em inglês. Texto visível ao usuário em pt-BR.
- Sem comentários no código, salvo workaround não óbvio.
- Constantes em `Constants.swift`. Um tipo público por arquivo.
- `FileToolsCore` não tem interface: nada de SwiftUI nem de janelas. A lógica testável fica lá e a interface em `FileToolsApp`.
- Nunca sobrescrever nem apagar o arquivo original.

## Commits e PRs

Conventional Commits em pt-BR, no imperativo, em minúsculas e sem ponto final: `fix(merge): respeita o limite de 1 MB`. Branches seguem o tipo do commit: `feat/...`, `fix/...`, `chore/...`.

A descrição da PR diz qual era o problema, o que muda e como validar.

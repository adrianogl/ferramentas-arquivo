# Ferramentas de Arquivo: design

Data: 2026-10-21
Uso: open source (licença MIT), distribuído pelo GitHub para quem quiser usar. Desenvolvido no Mac do autor (macOS 27, Xcode 27.1, Swift 6.4).

## Por que existe

Para pedir reembolso, o autor precisa anexar PDFs de no máximo 1 MB. Os PDFs costumam vir maiores, e as imagens às vezes chegam num formato que o sistema não aceita. Hoje ele abre o iLovePDF no navegador, sobe o arquivo, comprime ou converte, baixa o resultado e anexa. O app troca esse caminho por um clique direito no arquivo no Finder, com processamento local. Documento de reembolso não sai da máquina.

## Escopo da primeira versão

Sete ações, acessadas por um menu circular flutuante (⌥ + clique direito no arquivo) e, como alternativa, pelo menu de contexto do Finder:

1. **Otimizar PDF**: reduz o PDF até ficar abaixo do limite configurado (padrão 1 MB).
2. **Imagens para PDF**: uma ou várias imagens viram um PDF só, uma página por imagem, já abaixo do limite.
3. **Juntar PDFs**: vários PDFs viram um só, abaixo do limite.
4. **Dividir PDF**: janelinha para separar todas as páginas ou extrair um intervalo.
5. **Organizar PDF**: janela com miniaturas para reordenar, apagar, girar e adicionar páginas.
6. **PDF para JPG**: cada página vira um JPG.
7. **PDF para Markdown**: o texto do PDF vira um arquivo `.md`, preservando títulos, listas e links.

O app nasce para receber ações novas depois. Candidatas: OCR para deixar PDF escaneado pesquisável, senha e marca d'água.

*Decisão minha:* o limite de tamanho vale só para Otimizar, Imagens para PDF e Juntar, que são as ações de "preparar para enviar". Dividir, Organizar, PDF para JPG e PDF para Markdown não comprimem.

## Comportamento

### Menu circular

Este é o jeito principal de usar o app, pedido pelo autor.

- **Gatilho:** ⌥ Option + clique direito sobre um arquivo (ou uma seleção) no Finder, inclusive na Mesa. O menu de contexto do Finder **não** aparece nesse caso. Sem a tecla, o clique direito continua normal. A tecla pode ser trocada nas configurações *(padrão ⌥: decisão minha)*.
- **Alvo:** se o arquivo clicado já fizer parte da seleção, vale a seleção inteira. Se não fizer, vale só o arquivo clicado, como acontece no Finder.
- **Forma:** círculo centralizado no cursor, com 8 fatias de 45° e um miolo central. Posições em sentido horário a partir do topo *(decisão minha)*: Otimizar (topo), Juntar, Dividir, Organizar, Imagens para PDF (base), PDF para JPG, PDF para Markdown, e uma vaga tracejada para a próxima ação.
- **Visual aprovado ("C + D"):** vidro translúcido no estilo do macOS atual (desfoque e brilho na borda), que segue o modo claro e o escuro do sistema. Cada ação tem uma cor própria: Otimizar em vermelho (#ff5a5f), Juntar em azul (#2f8cff) e Imagens para PDF em verde (#2fbf71). *Decisão minha* para as novas: Dividir em laranja (#ff9f0a), Organizar em roxo (#a970ff), PDF para JPG em âmbar (#e0a800) e PDF para Markdown em verde-água (#22b8b0). O mockup com 8 fatias é `docs/mockups/menu-circular-8.html`. A fatia ativa ganha um anel fino brilhando na cor da ação e um fundo suave da mesma cor, e o ícone fica preenchido. O mockup de referência é `docs/mockups/menu-circular.html`. Ele usa classes do frame do brainstorm, então abra como referência visual, não como código.
- **Miolo:** mostra o que vai acontecer com a fatia sob o cursor: nome da ação, arquivo ou quantidade de arquivos, tamanho atual e limite ("3,4 MB → até 1 MB").
- **Ações que não servem para a seleção** aparecem apagadas e não respondem. Ao passar o mouse, o miolo mostra o motivo:
  - Otimizar sem PDF na seleção: "só para PDF".
  - Juntar com menos de 2 arquivos: "selecione 2 ou mais".
  - Imagens para PDF quando algum arquivo não é imagem: "só para imagens".
  - Dividir e Organizar com mais de um arquivo ou sem PDF: "selecione 1 PDF".
  - Dividir com PDF de 1 página: "o PDF tem só 1 página".
  - PDF para JPG e PDF para Markdown sem PDF: "só para PDF". Com vários PDFs, processam cada um separadamente.
- **Interação:** mover o mouse na direção acende a fatia, e clicar executa. Esc, clique fora ou clique no miolo fecha sem fazer nada. O círculo abre e fecha com uma animação curta de escala e desfoque.
- **Depois do clique:** o miolo mostra o progresso por um instante, o círculo some, e o resultado segue a seção "Saída".

### Otimizar PDF

- Se o arquivo já estiver abaixo do limite, não gera nada e avisa ("já tem 640 KB, abaixo de 1 MB").
- Senão, comprime em etapas de qualidade decrescente e para na primeira que fica abaixo do limite. O resultado é o arquivo mais legível que cabe no limite, e não o menor possível.
- O caso típico é nota ou comprovante escaneado ou fotografado, ou seja, PDF com imagem. A compressão atua sobre as imagens (resolução e qualidade JPEG). Páginas só com texto e vetor devem continuar com texto selecionável sempre que isso couber no limite.
- Existe um piso de legibilidade. Se nem no piso o arquivo ficar abaixo do limite, o app **não entrega um arquivo ilegível**: avisa que não conseguiu e informa o menor tamanho alcançado. O builder define o piso, mas o texto de um comprovante comum escaneado em A4 precisa continuar legível.
- Selecionar vários PDFs e escolher "Otimizar" processa cada um separadamente. *Decisão minha:* se um falhar, os outros seguem, e o aviso final lista os que falharam.
- *Decisão minha:* 1 MB = 1.000.000 bytes, e o arquivo tem que ficar estritamente abaixo. Assim ele passa nas duas interpretações (1.000.000 ou 1.048.576) que o sistema de reembolso possa usar.

### Imagens para PDF

- Aceita qualquer formato que o ImageIO do macOS leia (HEIC, JPEG, PNG, WebP, TIFF, GIF, BMP...).
- Várias imagens selecionadas geram **um PDF só**, uma página por imagem, na ordem do nome do arquivo (ordenação natural: `IMG_2` antes de `IMG_10`). O Finder não informa a ordem de clique.
- Respeita a orientação EXIF (foto de celular não pode sair deitada).
- Página com a proporção da imagem, sem margem. O tamanho em pontos sai das dimensões da imagem com um DPI razoável, para foto de 12 MP não virar uma página de 1 metro. *(Decisão do builder: se A4 ficar melhor para o sistema de reembolso, pode trocar. O autor não pediu nenhum dos dois.)*
- *Decisão minha:* se uma das imagens falhar, a ação inteira para sem gerar arquivo. Um PDF com página faltando seria um resultado errado sem aviso. O mesmo vale para "Juntar PDFs".
- O PDF final passa pela mesma regra de limite e piso do "Otimizar PDF".

### Juntar PDFs

- Precisa de dois ou mais arquivos. Ordem pelo nome do arquivo, como nas imagens.
- *Decisão minha:* aceita PDFs e imagens misturados na mesma seleção. A imagem vira página.
- *Decisão minha:* o resultado passa pela regra de limite. O motivo de juntar é anexar no reembolso.

### Dividir PDF

Escolha do autor: abre uma janelinha em vez de agir direto.

- Título "Dividir nota.pdf (8 páginas)". Duas opções:
  - **Separar todas as páginas** (marcada por padrão): gera uma pasta `nota-paginas/` ao lado do original, com `nota-01.pdf`, `nota-02.pdf` e assim por diante. O número tem zeros à esquerda conforme o total de páginas.
  - **Extrair páginas:** campo de texto que aceita intervalos como `1-3, 5`. Gera um PDF só, `nota-extraido.pdf`, com as páginas na ordem digitada.
- Enter confirma e Esc cancela. Intervalo inválido mostra o erro embaixo do campo e não fecha a janela: "Página 9 não existe (o PDF tem 8)" ou "Use números e intervalos, como 1-3, 5".
- A janela aparece na frente de tudo, perto do cursor, sem trazer o Finder para trás.

### Organizar PDF

*Decisões minhas*, a partir da descrição do iLovePDF que o autor mandou:

- Janela com as miniaturas das páginas em grade, cada uma com o número embaixo.
- Arrastar reordena. Clique seleciona, e ⌘/⇧ + clique seleciona várias.
- ⌫ apaga as selecionadas. Botões de girar à esquerda e à direita na barra da janela (também ⌘← e ⌘→).
- Botão "Adicionar…" (e arrastar arquivos para dentro da janela) acrescenta páginas de outro PDF ou imagem no fim.
- ⌘Z desfaz.
- "Salvar" grava `nota-organizado.pdf` ao lado do original e revela no Finder. Fechar com alterações não salvas pergunta se quer descartar.
- Apagar todas as páginas desabilita o "Salvar".

### PDF para JPG

- *Decisão minha:* só converte páginas em imagem. "Extrair imagens contidas no PDF", que o iLovePDF também oferece, fica de fora.
- PDF com uma página gera `nota.jpg` ao lado. Com várias páginas, gera a pasta `nota-paginas/` com `nota-01.jpg`, `nota-02.jpg` e assim por diante, e revela a pasta.
- *Decisão minha:* 150 DPI, qualidade JPEG 0,85, fundo branco nas áreas transparentes.

### PDF para Markdown

- Gera `nota.md` ao lado do original.
- Títulos: linhas com fonte bem maior que o corpo do texto viram `#` ou `##`, e linhas curtas em negrito viram `###`. O builder define os limiares.
- Listas: linhas que começam com marcador (•, –, -, *) ou numeração (`1.`, `1)`) viram itens de lista.
- Links do PDF viram `[texto](url)`.
- Tabelas viram texto corrido, uma linha por linha da tabela. O autor foi avisado.
- *Decisão minha:* página sem texto (escaneada) passa por OCR local (Vision, português e inglês), e o texto reconhecido entra como parágrafos.
- Se o PDF inteiro não tiver texto nenhum, nem com OCR, a ação avisa e não gera arquivo.

### Saída (vale para todas as ações)

- Nunca sobrescreve o original.
- Salva na mesma pasta do arquivo de origem, com sufixo:
  - `nota.pdf` → `nota-otimizado.pdf`
  - `foto.heic` → `foto.pdf`; várias imagens → nome da primeira na ordem + `.pdf`
  - juntar → nome do primeiro na ordem + `-juntado.pdf`
  - dividir, organizar, PDF para JPG e PDF para Markdown → nomes definidos nas seções acima. A pasta `-paginas` também ganha número se já existir.
- Se o nome já existir, acrescenta um número (`nota-otimizado 2.pdf`), no padrão do Finder.
- No fim, revela o arquivo novo no Finder já selecionado, pronto para arrastar no formulário, e mostra uma notificação com o tamanho final ("nota-otimizado.pdf: 3,4 MB → 870 KB").
- Erros (arquivo corrompido, PDF com senha, limite inalcançável) aparecem como notificação ou alerta, com uma frase que diga o que fazer.

### Assistente de configuração

Pedido do autor, para quem instala não precisar do terminal nem de instruções avulsas. É uma janela de cinco passos que abre na primeira vez que o app roda e de novo sempre que faltar uma permissão (por exemplo, depois de uma atualização, quando o macOS revoga a Acessibilidade de um app sem assinatura estável). Também abre pelo item "Configurar permissões…" do menu da barra.

1. **Boas-vindas:** o que o app faz e que vai pedir duas permissões. Botão "Começar".
2. **Acessibilidade:** por que precisa ("perceber o ⌥ + clique direito antes do Finder abrir o menu dele; não lê o que você digita nem o conteúdo das janelas") e o caminho nos Ajustes. Botão "Abrir Ajustes do Sistema". A tela verifica a permissão a cada segundo e avança sozinha quando ela é concedida.
3. **Finder:** pede a permissão de Automação do Finder ("só pergunta quais arquivos estão selecionados; nunca move, apaga ou renomeia nada"). Botão "Pedir permissão", que dispara o aviso do macOS. Mostra as duas permissões com check verde quando ok, e explica onde religar se a pessoa recusar.
4. **Experimente:** o app cria um `exemplo.pdf` numa pasta temporária, abre essa pasta no Finder e espera o primeiro ⌥ + clique direito nele. Quando o alvo é reconhecido, o passo fica verde e libera "Continuar". Tem "Pular este passo".
5. **Pronto:** lembra que o app fica na barra de menus e mostra dois ajustes: limite de tamanho (MB) e "Abrir ao iniciar sessão". Botão "Concluir".

Barra inferior com indicador de passos (5 pontos) e botões "Voltar" e a ação principal.

### Marca

Escolha do autor: **A3 + C marinho**. A marca é um quadrado de cantos arredondados em marinho (#0B1B33) com o canto superior direito dobrado em azul (#2F8CFF), como uma folha. Dentro dele há o anel de oito fatias em branco, com a fatia de cima em azul e a vaga em #34507A. O fundo de apoio é o azul-claro #E8F1FF, e a fonte da marca é DM Sans. A marca é o ícone do app, e o ícone da barra de menus é a versão monocromática (quadrado com o anel vazado), como template image do macOS. As cores das ações no menu circular não mudam.

### Configurações

O app fica rodando em segundo plano, com um ícone na barra de menus. Pelo ícone, ou abrindo o app pelo Launchpad, aparece uma janela pequena de configurações:

- Limite de tamanho em MB (padrão 1). Vale para as três ações.
- Tecla do menu circular (padrão ⌥).
- Abrir ao iniciar sessão (padrão ligado).
- Estado das permissões (Acessibilidade e Automação do Finder), com botão para abrir o painel certo dos Ajustes do Sistema quando faltar alguma.
- Lista das ações disponíveis, só para consulta.

## Decisões de como construir

Todas abaixo são decisões minhas. O autor delegou a escolha técnica e aprovou o resumo ("app nativo em Swift, Quick Actions no Finder, tudo local").

- **Swift + SwiftUI**, app nativo. Só as bibliotecas do sistema: PDFKit, Core Graphics/Quartz e ImageIO. Sem dependência externa e sem rede.
- **App de barra de menus** (sem ícone no Dock), que abre no login e roda **fora do sandbox**. Isso é necessário para capturar o clique e gravar ao lado do original. O autor aceitou dar as permissões de Acessibilidade e Automação do Finder.
- **Captura do ⌥ + clique direito:** um event tap global que consome o evento quando a tecla está pressionada, para o menu do Finder não abrir, e deixa passar os outros cliques. Ele só age quando o Finder é o app sob o cursor.
- **Descobrir o arquivo sob o cursor:** pelo Finder, via Apple Events ou Scripting Bridge, a seleção e o item clicado. Um caminho possível é deixar o Finder processar um clique de seleção antes de ler a seleção. O builder escolhe o mecanismo, desde que respeite a regra de alvo da seção "Menu circular".
- **O menu circular** é uma janela sem borda, flutuante e transparente (`NSPanel` não ativador), desenhada em SwiftUI com materiais do sistema.
- **Alternativa pelo Finder:** as mesmas três ações também ficam no clique direito normal (Ações Rápidas ou Serviços). Elas funcionam sem as permissões e continuam funcionando se uma atualização do macOS quebrar a captura do clique. Minha aposta é Services (`NSServices`), e o builder valida.
- **Risco conhecido:** a captura de clique em outro app é a parte frágil. Se não der para impedir o menu do Finder de forma confiável no macOS 27, o builder para e volta ao autor antes de buscar outro gatilho.
- **Estrutura para crescer.** A lógica de cada ação fica separada da integração com o Finder, num módulo testável (por exemplo, um Swift package local). Cada ação declara os tipos de arquivo que aceita e se exige uma ou várias seleções. Adicionar ação nova deve se resumir a escrever a ação e registrá-la, sem mexer nas outras.
- **Distribuição (escolha do autor).** Release no GitHub com um `.zip` do `.app`, assinado ad hoc e **sem notarização**. O README e a landing page explicam a primeira abertura: Ajustes do Sistema → Privacidade e Segurança → "Abrir assim mesmo". Sem conta paga da Apple, sem App Store e sem atualização automática.
- **Assinatura em desenvolvimento.** O script de build usa a identidade de `SIGN_IDENTITY`. Sem ela, procura uma "Apple Development" no keychain e, se não houver, faz fallback para ad hoc. Nenhum nome de certificado ou e-mail fica no repositório.
- **Repositório.** `~/Code/ferramentas-arquivo`, git próprio, licença MIT ("Copyright (c) 2026 Adriano Gonçalves"). README em pt-BR com o que o app faz, a instalação pela release, a primeira abertura, as permissões, o build a partir do código e o botão do Buy me a coffee. Nada de dado pessoal além do nome do autor na licença.

## Fora do escopo

- Upload ou qualquer serviço externo.
- Conversão de e para Word, Excel e PowerPoint.
- Edição de conteúdo, assinatura, tarja e comparação de PDFs (o Preview já cobre parte disso).
- Estrutura de tabela no Markdown.
- Notarização, App Store, Homebrew e atualização automática.
- Tradução para outros idiomas (o app sai em pt-BR).
- Tela própria para processar arquivos arrastados para dentro do app. O caminho principal é o Finder.
- Menu circular fora do Finder (em outros apps ou em diálogos de abrir arquivo).

## Seria um fracasso se

- Entregasse um PDF ilegível sem avisar.
- Sobrescrevesse ou apagasse o original.
- Exigisse abrir o app ou passar por mais de um passo para a tarefa comum (um PDF de reembolso).
- Atrapalhasse o clique direito normal do Finder quando a tecla não está pressionada.
- Demorasse muito num comprovante comum. Como referência, um PDF escaneado de poucas páginas deve sair em poucos segundos.

## Como validar

- Testes do módulo de ações com arquivos gerados no próprio teste: PDF escaneado grande que cai abaixo de 1 MB; PDF já pequeno, que não gera arquivo; PDF que não chega ao limite no piso, que dá erro e não gera arquivo; HEIC com orientação EXIF; várias imagens em ordem natural; juntar PDF com imagem.
- Teste manual no Finder com um PDF de reembolso real: ⌥ + clique direito → Otimizar → arquivo novo selecionado, abaixo de 1 MB, legível. Repetir pelo menu normal do Finder.
- Testes do módulo para as novas ações: dividir todas as páginas (nomes e zeros à esquerda), extrair `1-3, 5` e intervalos inválidos; PDF para JPG com 1 e com várias páginas; Markdown com título, lista, link e página escaneada (OCR); operações do Organizar (mover, apagar, girar, adicionar) no modelo sem interface.
- Teste manual do menu circular: o menu do Finder não aparece com ⌥, aparece normalmente sem ⌥, a regra de alvo funciona com o arquivo dentro e fora da seleção, as fatias ficam apagadas nos casos certos, Esc fecha, e o visual acompanha o modo claro e o escuro.

## Fica para o builder

- Algoritmo exato de compressão: etapas de DPI e qualidade, como detectar página só com imagem e como manter o texto das outras.
- Valor do piso de legibilidade, dentro da regra acima.
- Services ou Action Extension, depois de validar no macOS 27.
- Notificação ou alerta para cada tipo de mensagem.
- Visual da janela de configurações.
- Ícones das ações no menu circular (SF Symbols), mantendo as cores definidas.
- Mecanismo exato para capturar o clique e identificar o arquivo sob o cursor.

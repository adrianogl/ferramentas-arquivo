# Ferramentas de Arquivo: plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** app de barra de menus para macOS que abre um menu circular com ⌥ + clique direito num arquivo do Finder e executa sete ações locais de PDF e imagem (otimizar, juntar, dividir, organizar, imagens para PDF, PDF para JPG, PDF para Markdown).

**Architecture:** um Swift package com dois targets. `FileToolsCore` é uma biblioteca sem UI com toda a lógica (compressão, montagem de PDF, conversões, nomes de saída, regras de disponibilidade, textos para o usuário) e é coberta por testes. `FileToolsApp` é o executável AppKit/SwiftUI: captura do clique, leitura do Finder, menu circular, janelas de Dividir e Organizar, configurações, notificações e Services como alternativa. Um script monta o `.app`, assina e instala em `/Applications`.

**Tech Stack:** Swift 6.4 (modo de linguagem Swift 6), SwiftPM, Swift Testing, PDFKit, Core Graphics, ImageIO, Vision, SwiftUI, AppKit, ServiceManagement, UserNotifications, ApplicationServices (Accessibility, Apple Events).

**Spec:** `docs/superpowers/specs/2026-10-21-ferramentas-arquivo-design.md`. Mockups: `docs/superpowers/specs/assets/menu-circular-8.html` (menu com 8 fatias, janela do Dividir, janela do Organizar) e `docs/superpowers/specs/assets/menu-circular.html` (estilo de vidro e cores).

## Global Constraints

- Deployment target `.macOS(.v26)`. O app roda no macOS 27 do autor. Sem dependências de terceiros e sem rede.
- Nome do app "Ferramentas de Arquivo", bundle id `dev.aglv.FerramentasArquivo`, `LSUIElement = true`, sem sandbox e sem hardened runtime.
- Assinatura com a identidade "Apple Development: adgoleva@gmail.com (4W97KN5362)", para as permissões de Acessibilidade e Automação sobreviverem a rebuilds. Ad hoc (`-`) só como fallback, com aviso.
- 1 MB = 1.000.000 bytes. O arquivo precisa ficar **estritamente abaixo** do limite. O limite padrão é 1 MB e vale só para Otimizar, Imagens para PDF e Juntar.
- Nunca sobrescrever nem apagar o original. A saída vai na pasta do arquivo de origem e, quando o nome já existe, ganha número no padrão do Finder (`nota-otimizado 2.pdf`, pasta `nota-paginas 2`).
- Identificadores em inglês. Todo texto visível ao usuário em pt-BR, exatamente como está neste plano.
- Sem comentários no código, salvo workaround não óbvio. Constantes em `Constants.swift` e cada tipo público no próprio arquivo.
- Cores: Otimizar `#ff5a5f`, Juntar `#2f8cff`, Dividir `#ff9f0a`, Organizar `#a970ff`, Imagens para PDF `#2fbf71`, PDF para JPG `#e0a800`, PDF para Markdown `#22b8b0`, vaga `#8e8e93`.
- Git: trabalhar na branch `feat/app-inicial`, criada a partir da `main`. Mensagens em Conventional Commits, em pt-BR, no imperativo, minúsculas, **sem trailer de co-autoria**. Cada commit e cada push **só depois da confirmação explícita do autor**: mostre `git status`, `git diff --staged` e a mensagem proposta, e espere.

## Review Focus

- PNG com transparência (print de tela) vira página ou JPG com fundo **branco**, nunca preto. Teste na Task 4.
- Se o macOS desligar o event tap por timeout ou por input do usuário (`tapDisabledByTimeout` / `tapDisabledByUserInput`), o tap religa sozinho. Sem isso, o ⌥ + clique para de funcionar sem aviso. Verificação na Task 3.
- ⌥ + clique direito em área vazia, numa pasta ou num arquivo que não é PDF nem imagem abre o menu normal do Finder, e o clique não some. Teste de `TargetRule` na Task 1 e verificação manual na Task 3.
- Nomes com acento, espaço e emoji, inclusive na forma NFD que o Finder devolve, e arquivos no iCloud Drive funcionam igual aos outros. Teste na Task 1.
- PDF grande (dezenas de páginas escaneadas) não trava a UI nem estoura a memória. O trabalho roda fora da main thread, as páginas são rasterizadas uma a uma dentro de `autoreleasepool`, e a etapa da escada é abortada assim que os bytes acumulados passam do limite. Teste na Task 5.

---

## Estrutura de arquivos

```
Package.swift
Resources/Info.plist
scripts/build-app.sh
Sources/FileToolsCore/
  Constants.swift              ladder, dimensões, descritores de ação, DPI
  SizeLimit.swift  FileKind.swift  NaturalOrder.swift  OutputNaming.swift
  TargetRule.swift  TriggerModifier.swift  SettingsStore.swift
  Raster/  RasterQuality.swift  ImageLoader.swift  JPEGEncoder.swift  PageRasterizer.swift
  PDF/     PDFReader.swift  PDFPageSource.swift  PDFAssembler.swift
  Compression/  PDFCompressor.swift  CompressionResult.swift  ScannedPageDetector.swift
  Actions/ ActionID.swift  ActionDescriptor.swift  Availability.swift  ActionAvailability.swift
           ActionReport.swift  ActionFailure.swift  OutputWriter.swift  ImmediateAction.swift
           OptimizePDFAction.swift  ImagesToPDFAction.swift  MergePDFsAction.swift
           PDFToJPGAction.swift  PDFToMarkdownAction.swift
  Markdown/ MarkdownConverter.swift  OCRRecognizer.swift
  Split/    PageRangeParser.swift  PageRangeError.swift  SplitMode.swift  PDFSplitter.swift
  Organize/ OrganizePage.swift  OrganizeModel.swift  OrganizeExporter.swift
  Messages/ UserMessage.swift  ReportFormatter.swift
  Radial/   RadialGeometry.swift  RadialCoreText.swift  TargetInfo.swift
Sources/FileToolsApp/
  FileToolsApp.swift  AppDelegate.swift  Log.swift
  Trigger/  RightClickTap.swift  FinderWindowLocator.swift  FinderTargetResolver.swift  FinderScripting.swift
  Run/      ActionCoordinator.swift  Notifier.swift  ServiceProvider.swift
  Radial/   RadialPanelController.swift  RadialMenuModel.swift  RadialMenuView.swift  RadialSliceShape.swift
  Split/    SplitDialogController.swift  SplitDialogView.swift
  Organize/ OrganizeWindowController.swift  OrganizeView.swift  ThumbnailCache.swift
  Settings/ SettingsView.swift  Permissions.swift  LaunchAtLogin.swift
Tests/FileToolsCoreTests/
  Fixtures.swift  + um arquivo de teste por unidade (nomes em cada task)
```

Rodar testes: `swift test` (tudo) ou `swift test --filter <Suite>`. Os testes usam Swift Testing (`import Testing`) e `@testable import FileToolsCore`.

---

### Task 1: Base do core

**Files:**
- Create: `Package.swift`, `.gitignore` (já existe, acrescentar `.build/`), `Sources/FileToolsCore/{Constants,SizeLimit,FileKind,NaturalOrder,OutputNaming,TargetRule,TriggerModifier,SettingsStore}.swift`
- Create: `Sources/FileToolsApp/FileToolsApp.swift` (só `@main` vazio para o package compilar, completado na Task 2)
- Test: `Tests/FileToolsCoreTests/{SizeLimitTests,FileKindTests,NaturalOrderTests,OutputNamingTests,TargetRuleTests,SettingsStoreTests}.swift`

**Interfaces:**
- Produces:
  - `public struct SizeLimit: Sendable, Equatable { public let bytes: Int; public init(bytes: Int); public static func megabytes(_ value: Double) -> SizeLimit; public func accepts(byteCount: Int) -> Bool }`
  - `public enum FileKind: Sendable, Equatable { case pdf, image, unsupported; public static func of(_ url: URL) -> FileKind }`
  - `public func naturalOrder(_ urls: [URL]) -> [URL]`
  - `public enum OutputNaming` com `static func optimized(for source: URL) -> URL`, `static func imagesPDF(firstImage: URL) -> URL`, `static func merged(first: URL) -> URL`, `static func extracted(for source: URL) -> URL`, `static func organized(for source: URL) -> URL`, `static func markdown(for source: URL) -> URL`, `static func singleJPG(for source: URL) -> URL`, `static func pagesFolder(for source: URL) -> URL`, `static func pageFileName(base: String, index: Int, pageCount: Int, ext: String) -> String`, `static func unique(_ candidate: URL, fileManager: FileManager = .default) -> URL`. Todas as funções de nome já devolvem a URL única.
  - `public enum TargetRule { public static func resolve(selection: [URL], clicked: URL?) -> [URL]?; public static func shouldShowRadial(for targets: [URL]) -> Bool }`
  - `public enum TriggerModifier: String, CaseIterable, Sendable { case option, command, shift; public var title: String; public var cgFlag: CGEventFlags }`
  - `@MainActor public final class SettingsStore { public init(defaults: UserDefaults = .standard); public var limitMegabytes: Double; public var triggerModifier: TriggerModifier; public var launchAtLogin: Bool; public var sizeLimit: SizeLimit }`

- [ ] **Step 1: Criar a branch**

```bash
cd ~/Code/ferramentas-arquivo && git checkout main && git checkout -b feat/app-inicial
```

- [ ] **Step 2: Criar `Package.swift`**

Targets: `FileToolsCore` (library), `FileToolsApp` (executableTarget, depende de `FileToolsCore`) e `FileToolsCoreTests` (testTarget). Platforms `[.macOS(.v26)]`, `swiftLanguageModes: [.v6]`. Rode `swift build` e espere "Build complete!".

- [ ] **Step 3: Escrever os testes que falham**

```swift
@Suite struct SizeLimitTests {
  @Test func megabyteIsDecimal() { #expect(SizeLimit.megabytes(1).bytes == 1_000_000) }
  @Test func strictlyBelow() {
    let l = SizeLimit.megabytes(1)
    #expect(l.accepts(byteCount: 999_999)); #expect(!l.accepts(byteCount: 1_000_000))
  }
  @Test func fractional() { #expect(SizeLimit.megabytes(1.5).bytes == 1_500_000) }
}
@Suite struct NaturalOrderTests {
  @Test func numbersCompareNumerically() {
    let urls = ["IMG_10.png", "IMG_2.png", "IMG_1.png"].map { URL(fileURLWithPath: "/t/\($0)") }
    #expect(naturalOrder(urls).map(\.lastPathComponent) == ["IMG_1.png", "IMG_2.png", "IMG_10.png"])
  }
}
@Suite struct OutputNamingTests {
  @Test func suffixes() throws {
    let d = try Fixtures.tempDirectory()
    #expect(OutputNaming.optimized(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-otimizado.pdf")
    #expect(OutputNaming.imagesPDF(firstImage: d.appending(path: "foto.heic")).lastPathComponent == "foto.pdf")
    #expect(OutputNaming.merged(first: d.appending(path: "a.pdf")).lastPathComponent == "a-juntado.pdf")
    #expect(OutputNaming.extracted(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-extraido.pdf")
    #expect(OutputNaming.organized(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-organizado.pdf")
    #expect(OutputNaming.markdown(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota.md")
    #expect(OutputNaming.singleJPG(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota.jpg")
    #expect(OutputNaming.pagesFolder(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-paginas")
  }
  @Test func collisionAddsNumber() throws {
    let d = try Fixtures.tempDirectory()
    try Data().write(to: d.appending(path: "nota-otimizado.pdf"))
    try Data().write(to: d.appending(path: "nota-otimizado 2.pdf"))
    #expect(OutputNaming.optimized(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-otimizado 3.pdf")
    try FileManager.default.createDirectory(at: d.appending(path: "nota-paginas"), withIntermediateDirectories: false)
    #expect(OutputNaming.pagesFolder(for: d.appending(path: "nota.pdf")).lastPathComponent == "nota-paginas 2")
  }
  @Test func pageNumbersArePadded() {
    #expect(OutputNaming.pageFileName(base: "nota", index: 1, pageCount: 8, ext: "pdf") == "nota-01.pdf")
    #expect(OutputNaming.pageFileName(base: "nota", index: 7, pageCount: 120, ext: "jpg") == "nota-007.jpg")
  }
  @Test func unicodeNames() throws {
    let d = try Fixtures.tempDirectory()
    let nfd = "Recibo Sa\u{0303}o Paulo 🚕.pdf"
    #expect(OutputNaming.optimized(for: d.appending(path: nfd)).lastPathComponent.precomposedStringWithCanonicalMapping == "Recibo São Paulo 🚕-otimizado.pdf")
  }
}
@Suite struct TargetRuleTests {
  let a = URL(fileURLWithPath: "/t/a.pdf"), b = URL(fileURLWithPath: "/t/b.pdf"), c = URL(fileURLWithPath: "/t/c.pdf")
  @Test func clickedInsideSelectionUsesSelection() { #expect(TargetRule.resolve(selection: [a, b], clicked: b) == [a, b]) }
  @Test func clickedOutsideUsesClicked() { #expect(TargetRule.resolve(selection: [a, b], clicked: c) == [c]) }
  @Test func nothingClicked() { #expect(TargetRule.resolve(selection: [a], clicked: nil) == nil) }
  @Test func radialOnlyForPDFOrImage() throws {
    let d = try Fixtures.tempDirectory()
    let txt = d.appending(path: "x.txt"); try Data("x".utf8).write(to: txt)
    #expect(!TargetRule.shouldShowRadial(for: [d]))
    #expect(!TargetRule.shouldShowRadial(for: [txt]))
    #expect(!TargetRule.shouldShowRadial(for: []))
  }
}
@Suite @MainActor struct SettingsStoreTests {
  @Test func defaults() {
    let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    #expect(s.limitMegabytes == 1.0); #expect(s.triggerModifier == .option); #expect(s.launchAtLogin)
    #expect(s.sizeLimit == SizeLimit(bytes: 1_000_000))
  }
  @Test func persists() {
    let suite = UUID().uuidString
    SettingsStore(defaults: UserDefaults(suiteName: suite)!).limitMegabytes = 2.5
    #expect(SettingsStore(defaults: UserDefaults(suiteName: suite)!).sizeLimit.bytes == 2_500_000)
  }
  @Test func clampsLimit() {
    let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    s.limitMegabytes = 0; #expect(s.limitMegabytes == 0.1)
    s.limitMegabytes = 500; #expect(s.limitMegabytes == 100)
  }
}
```

`FileKindTests`: `.pdf` para um PDF real (de `Fixtures.textPDF`), `.image` para PNG e para HEIC, `.unsupported` para `.txt` e para pasta. Nesta task, `Fixtures.swift` só precisa de `tempDirectory()`, que cria uma pasta única em `FileManager.default.temporaryDirectory`. O resto dos fixtures entra na Task 4, então os casos de PDF e imagem do `FileKindTests` entram lá.

- [ ] **Step 4: Rodar e ver falhar.** `swift test` → erro de compilação (tipos não existem).

- [ ] **Step 5: Implementar**

- `FileKind.of`: lê `.contentTypeKey` via `resourceValues`. Pasta → `.unsupported`. `conforms(to: .pdf)` → `.pdf`, `conforms(to: .image)` → `.image`, senão `.unsupported`.
- `naturalOrder`: ordena por `lastPathComponent` com `localizedStandardCompare`.
- `OutputNaming.unique`: se o candidato existe, tenta `"<stem> 2.<ext>"`, `" 3"` e assim por diante. Pasta sem extensão segue a mesma regra. `pageFileName`: largura do número = `max(2, String(pageCount).count)`.
- `TargetRule.resolve`: compara por `standardizedFileURL.path` normalizado com `precomposedStringWithCanonicalMapping`. `shouldShowRadial`: verdadeiro se algum alvo for `.pdf` ou `.image`.
- `TriggerModifier.title`: `"⌥ Option"`, `"⌘ Command"`, `"⇧ Shift"`. `cgFlag`: `.maskAlternate`, `.maskCommand`, `.maskShift`.
- `SettingsStore`: chaves `limitMegabytes`, `triggerModifier`, `launchAtLogin`. Faz clamp de `limitMegabytes` para `0.1...100`.

- [ ] **Step 6: Rodar.** `swift test` → todos passam.

- [ ] **Step 7: Commit (depois da confirmação do autor)** — `feat(core): adiciona limite, nomes de saída e configurações`

---

### Task 2: App de barra de menus, build e instalação

**Files:**
- Create: `Resources/Info.plist`, `scripts/build-app.sh`, `Sources/FileToolsApp/{FileToolsApp,AppDelegate,Log}.swift`
- Modify: `.gitignore` (acrescentar `build/`)

**Interfaces:**
- Consumes: `SettingsStore` (Task 1).
- Produces: `@MainActor final class AppDelegate: NSObject, NSApplicationDelegate` com `let settings: SettingsStore` e o ponto onde as tasks seguintes registram tap, services e coordinator (`applicationDidFinishLaunching`). `enum Log { static let app = Logger(subsystem: "dev.aglv.FerramentasArquivo", category: "app"); static let trigger = Logger(subsystem: "dev.aglv.FerramentasArquivo", category: "trigger") }`.

- [ ] **Step 1: `Info.plist`**

`CFBundleIdentifier` `dev.aglv.FerramentasArquivo`, `CFBundleName`/`CFBundleDisplayName` "Ferramentas de Arquivo", `CFBundleExecutable` `FileTools`, `CFBundlePackageType` `APPL`, `CFBundleShortVersionString` `0.1.0`, `CFBundleVersion` `1`, `LSMinimumSystemVersion` `26.0`, `LSUIElement` true, `NSAppleEventsUsageDescription` "Para saber quais arquivos estão selecionados no Finder." Os `NSServices` entram na Task 14.

- [ ] **Step 2: `scripts/build-app.sh`**

`set -euo pipefail`; `swift build -c release --product FileToolsApp`; monta `build/Ferramentas de Arquivo.app/Contents/{MacOS/FileTools,Info.plist,Resources/}`; identidade = `${SIGN_IDENTITY:-}` ou a primeira linha "Apple Development" de `security find-identity -v -p codesigning`, com fallback `-` e aviso "assinatura ad hoc: as permissões serão pedidas de novo a cada build"; `codesign --force --sign "$IDENTITY" "$APP"`. Com `--install`: `osascript -e 'quit app id "dev.aglv.FerramentasArquivo"' || true`, substitui `/Applications/Ferramentas de Arquivo.app`, roda `/System/Library/CoreServices/pbs -update` e `open` o app.

- [ ] **Step 3: App**

`@main struct FileToolsApp: App` com `@NSApplicationDelegateAdaptor(AppDelegate.self)`, `MenuBarExtra("Ferramentas de Arquivo", systemImage: "doc.badge.gearshape")` com itens "Configurações…" (abre a cena `Window("Ferramentas de Arquivo", id: "settings")`, por enquanto com um `Text("Configurações")`, completada na Task 18) e "Sair" (⌘Q).

- [ ] **Step 4: Verificar**

Run: `scripts/build-app.sh --install && codesign -dv "/Applications/Ferramentas de Arquivo.app" 2>&1 | grep Authority`
Expected: `Authority=Apple Development: adgoleva@gmail.com (4W97KN5362)`. O ícone aparece na barra de menus, não aparece no Dock, e "Configurações…" abre a janela.

- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(app): adiciona app de barra de menus e script de build`

---

### Task 3: Captura do ⌥ + clique direito e alvo no Finder (portão de risco)

Esta é a parte frágil do design. **Condição de parada:** se, depois desta task, o menu do Finder ainda abrir com ⌥ pressionado, ou se o alvo sair errado em algum dos casos do Step 6, pare e volte ao autor antes de seguir para a Task 4. Não procure outro gatilho por conta própria.

**Files:**
- Create: `Sources/FileToolsApp/Trigger/{RightClickTap,FinderWindowLocator,FinderTargetResolver,FinderScripting}.swift`
- Modify: `Sources/FileToolsApp/AppDelegate.swift`

**Interfaces:**
- Consumes: `TargetRule`, `TriggerModifier`, `SettingsStore`, `Log`.
- Produces:
  - `@MainActor final class RightClickTap { init(modifier: @escaping () -> TriggerModifier, onTrigger: @escaping (CGPoint) -> Void); func start() -> Bool; func passThrough(at point: CGPoint, flags: CGEventFlags) }`. `CGPoint` em coordenadas globais com origem no canto superior esquerdo (as do `CGEvent`).
  - `@MainActor enum FinderWindowLocator { static func isFinderUnder(_ point: CGPoint) -> Bool }`
  - `@MainActor enum FinderScripting { static func selection() -> [URL]; static func select(_ urls: [URL]) }`
  - `@MainActor enum FinderTargetResolver { static func resolve(at point: CGPoint) async -> [URL]? }`

- [ ] **Step 1: `RightClickTap`**

`CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: rightMouseDown | rightMouseUp, ...)`, adicionado ao main run loop. No callback:
- `tapDisabledByTimeout` ou `tapDisabledByUserInput` → `CGEvent.tapEnable(tap:, enable: true)` e `Log.trigger.info("religando tap")`.
- Evento com `eventSourceUserData == 0x4654_4150` (eventos que o próprio app reposta) → deixa passar.
- `rightMouseDown` com o flag do modificador configurado, e `FinderWindowLocator.isFinderUnder(location)` verdadeiro → marca `swallowingUp = true`, agenda `onTrigger(location)` no main queue e retorna `nil`.
- `rightMouseUp` com `swallowingUp` ligado → desliga e retorna `nil`.
- Em qualquer outro caso, devolve o evento intacto.

`passThrough` reposta down e up com os mesmos flags, marcados com `eventSourceUserData`, para o Finder abrir o menu normal.

`start()` retorna `false` se `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` for falso ou se o tap não for criado. O `AppDelegate` tenta de novo a cada 2 s até conseguir, porque o usuário pode estar dando a permissão naquele momento.

- [ ] **Step 2: `FinderWindowLocator`**

`CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements]...)` não serve, porque os ícones da Mesa precisam entrar. Use `[.optionOnScreenOnly]` e percorra a lista de frente para trás. A primeira janela cujo `kCGWindowBounds` contém o ponto decide: verdadeiro se `kCGWindowOwnerPID` for o PID do Finder (`NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder")`). Janelas com `kCGWindowAlpha == 0` ficam de fora.

- [ ] **Step 3: `FinderScripting`**

`selection()` roda via `NSAppleScript` este script e lê a lista de strings do descriptor:

```applescript
tell application "Finder"
  set out to {}
  repeat with i in (get selection)
    set end of out to POSIX path of (i as alias)
  end repeat
  return out
end tell
```

`select(_:)` roda `tell application "Finder" to select {POSIX file "<p1>" as alias, ...}`, escapando `"` e `\` nos caminhos.

- [ ] **Step 4: `FinderTargetResolver.resolve(at:)`**

1. `s0 = FinderScripting.selection()`.
2. Tenta achar o item sob o cursor pelo Accessibility: `AXUIElementCopyElementAtPosition(AXUIElementCreateApplication(finderPID), x, y)`, subindo até 8 pais e lendo `kAXURLAttribute`. Se achar, `return TargetRule.resolve(selection: s0, clicked: url)`.
3. Se não achar, posta um clique esquerdo sintético (down+up, sem flags, marcado com `eventSourceUserData`) no ponto, espera 150 ms e lê `s1 = selection()`. Se `s1` estiver vazio → `nil`. Se `s1.count == 1` e `s1[0]` estiver em `s0` → `FinderScripting.select(s0)` para restaurar a seleção e retorna `s0`. Senão → `s1`.
4. Se o resultado não passar em `TargetRule.shouldShowRadial`, retorna `nil`.

No `AppDelegate`, `onTrigger` chama `resolve`. Com alvo, loga os caminhos (`Log.trigger.info("alvo: \(paths, privacy: .public)")`), e a Task 15 troca esse log pelo menu circular. Sem alvo, chama `tap.passThrough`.

- [ ] **Step 5: Instalar e conceder permissões**

Run: `scripts/build-app.sh --install`. Conceda Acessibilidade em Ajustes do Sistema e aceite o pedido de Automação do Finder no primeiro uso.

- [ ] **Step 6: Verificação manual**

Rode em outro terminal: `log stream --predicate 'subsystem == "dev.aglv.FerramentasArquivo"' --level info`.

| Caso | Esperado |
| --- | --- |
| ⌥ + clique direito num PDF não selecionado (visualização em ícones) | menu do Finder não abre; log com só esse PDF |
| mesmo caso nas visualizações em lista, colunas e galeria, e num arquivo da Mesa | igual |
| 3 arquivos selecionados, ⌥ + clique direito num deles | log com os 3; seleção continua com os 3 |
| 3 selecionados, ⌥ + clique direito num quarto, fora da seleção | log só com o quarto |
| ⌥ + clique direito em área vazia, numa pasta ou num `.txt` | menu normal do Finder abre |
| clique direito sem ⌥ | menu normal do Finder, sem log |
| ⌥ + clique direito no Safari | comportamento normal do Safari |
| `kill -STOP $(pgrep -x FileTools)`, alguns cliques direitos, espere 10 s, `kill -CONT $(pgrep -x FileTools)`, depois ⌥ + clique | log "religando tap" e o ⌥ + clique volta a funcionar |

- [ ] **Step 7: Commit (depois da confirmação do autor)** — `feat(app): captura opção + clique direito e identifica o alvo no finder`

---

### Task 4: Primitivas de imagem e PDF

**Files:**
- Create: `Sources/FileToolsCore/Raster/{RasterQuality,ImageLoader,JPEGEncoder,PageRasterizer}.swift`, `Sources/FileToolsCore/PDF/{PDFReader,PDFPageSource,PDFAssembler}.swift`, `Sources/FileToolsCore/Actions/ActionFailure.swift`
- Modify: `Sources/FileToolsCore/Constants.swift`, `Tests/FileToolsCoreTests/Fixtures.swift`
- Test: `Tests/FileToolsCoreTests/{ImageLoaderTests,JPEGEncoderTests,PDFAssemblerTests,PDFReaderTests}.swift`, completar `FileKindTests`

**Interfaces:**
- Produces:
  - `public struct RasterQuality: Sendable, Equatable { public let dpi: Double; public let jpegQuality: Double }`
  - Em `Constants`: `public static let rasterLadder: [RasterQuality] = [(200, 0.80), (150, 0.70), (150, 0.55), (120, 0.50), (100, 0.45)]` (o último item é o piso de legibilidade), `public static let imagePageLongSide: CGFloat = 842`, `public static let jpgExportQuality = RasterQuality(dpi: 150, jpegQuality: 0.85)`.
  - `public enum ActionFailure: Error, Sendable, Equatable { case unreadable, encrypted, writeFailed, unreachable(smallestBytes: Int), noText }`
  - `public enum ImageLoader { public static func load(_ url: URL, maxPixelSize: Int? = nil) throws(ActionFailure) -> CGImage }`
  - `public enum JPEGEncoder { public static func encode(_ image: CGImage, quality: Double) throws(ActionFailure) -> Data; public static func jpegBackedImage(_ image: CGImage, quality: Double) throws(ActionFailure) -> CGImage }`
  - `public enum PageRasterizer { public static func render(_ page: PDFPage, dpi: Double) -> CGImage? }`
  - `public enum PDFReader { public static func open(_ data: Data) throws(ActionFailure) -> PDFDocument; public static func open(_ url: URL) throws(ActionFailure) -> PDFDocument }`
  - `public enum PDFPageSource { case vector(PDFPage, extraRotation: Int = 0); case image(CGImage, pageSize: CGSize, rotation: Int = 0) }`
  - `public enum PDFAssembler { public static func assemble(_ pages: [PDFPageSource]) throws(ActionFailure) -> Data; public static func imagePageSize(for image: CGImage) -> CGSize }`
  - `Fixtures`: `noiseImage(width:height:alpha:seed:) -> CGImage` (determinístico, SplitMix64), `transparentImage(width:height:) -> CGImage`, `textImage(_:width:height:pointSize:) -> CGImage`, `scannedPDF(pages:pixelWidth:pixelHeight:) -> Data` (página A4 595×842 com bitmap de página inteira, padrão 1240×1754, desenhado sem compressão JPEG), `textPDF(_ pages: [String]) -> Data` (CoreText 12 pt), `logoPDF() -> Data` (texto + imagem 300×100), `encryptedPDF() -> Data`, `writeImage(_:to:type:orientation:) throws`, `write(_:named:in:) throws -> URL`.

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func transparentBecomesWhite() throws {
  let jpeg = try JPEGEncoder.jpegBackedImage(Fixtures.transparentImage(width: 100, height: 100), quality: 0.8)
  let px = try #require(pixel(jpeg, x: 50, y: 50))
  #expect(px.r >= 250 && px.g >= 250 && px.b >= 250)
}
@Test func jpegPassesThroughIntoPDF() throws {
  let img = Fixtures.noiseImage(width: 1000, height: 1000)
  let jpegData = try JPEGEncoder.encode(img, quality: 0.6)
  let pdf = try PDFAssembler.assemble([.image(try JPEGEncoder.jpegBackedImage(img, quality: 0.6), pageSize: CGSize(width: 595, height: 595))])
  #expect(pdf.count < jpegData.count + 20_000)
}
@Test func appliesExifOrientation() throws {
  let d = try Fixtures.tempDirectory(); let u = d.appending(path: "foto.jpg")
  try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: u, type: .jpeg, orientation: 6)
  let img = try ImageLoader.load(u)
  #expect(img.height > img.width)
}
@Test func doesNotUpscale() throws { /* 400x200 com maxPixelSize 2000 → width == 400 */ }
@Test func imagePageLongSideIs842() {
  let s = PDFAssembler.imagePageSize(for: Fixtures.noiseImage(width: 4032, height: 3024))
  #expect(abs(s.width - 842) < 0.5); #expect(abs(s.height - 631.5) < 0.5)
}
@Test func extraRotationSwapsPageSize() throws {
  let doc = try PDFReader.open(Fixtures.textPDF(["a"]))
  let out = try PDFReader.open(PDFAssembler.assemble([.vector(doc.page(at: 0)!, extraRotation: 90)]))
  let b = out.page(at: 0)!.bounds(for: .cropBox)
  let rotated = out.page(at: 0)!.rotation % 180 != 0
  #expect((rotated ? b.height : b.width) > (rotated ? b.width : b.height))
  #expect(out.page(at: 0)!.string?.contains("a") == true)
}
@Test func encryptedIsReported() { #expect(throws: ActionFailure.encrypted) { try PDFReader.open(Fixtures.encryptedPDF()) } }
@Test func garbageIsUnreadable() { #expect(throws: ActionFailure.unreadable) { try PDFReader.open(Data("x".utf8)) } }
@Test func brokenImageIsUnreadable() throws { /* arquivo .png com bytes aleatórios → throws .unreadable */ }
```

`pixel(_:x:y:)` é um helper local que desenha a imagem num `CGContext` RGBA e lê o pixel. Complete o `FileKindTests` com PDF, PNG e HEIC (se `CGImageDestinationCopyTypeIdentifiers()` incluir `public.heic`; senão use `#require` e pule com mensagem).

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "ImageLoaderTests|JPEGEncoderTests|PDFAssemblerTests|PDFReaderTests"`

- [ ] **Step 3: Implementar**

- `ImageLoader.load`: `CGImageSourceCreateWithURL` + `CGImageSourceCreateThumbnailAtIndex(…, 0, [CreateThumbnailFromImageAlways: true, CreateThumbnailWithTransform: true, ThumbnailMaxPixelSize: min(maxPixelSize ?? longSide, longSide)])`. `longSide` vem das propriedades da imagem, considerando a orientação. Falha → `.unreadable`.
- `JPEGEncoder.jpegBackedImage`: desenha a imagem sobre branco num `CGContext` RGB `noneSkipLast`, codifica com `CGImageDestination` (`UTType.jpeg`, `kCGImageDestinationLossyCompressionQuality`) e devolve `CGImage(jpegDataProviderSource:decode:shouldInterpolate:intent:)`. Esse caminho é o que faz o contexto PDF embutir o JPEG sem recodificar (DCT passthrough). Sem ele, o Quartz grava o bitmap em Flate e o PDF fica enorme. Isto justifica uma linha de comentário no código.
- `PageRasterizer.render`: tamanho em pixels = tamanho da página (cropBox já rotacionado) × dpi / 72, fundo branco, `page.transform(ctx, for: .cropBox)` e depois `page.draw(with: .cropBox, to: ctx)`.
- `PDFReader.open`: `PDFDocument(data:)` nulo → `.unreadable`. `isLocked` ou `isEncrypted` sem conseguir desbloquear com senha vazia → `.encrypted`.
- `PDFAssembler.assemble`: `CGContext(consumer:mediaBox:nil)` sobre um `CGDataConsumer(data:)`. Para cada página, `beginPDFPage([kCGPDFContextMediaBox: rect])`. `.vector`: copia a página (`copy() as! PDFPage`), soma `extraRotation` à `rotation`, usa o tamanho rotacionado e desenha com `transform` + `draw`. `.image`: tamanho da página trocado se `rotation % 180 != 0`, transforma e desenha a imagem preenchendo a página. `imagePageSize`: lado maior = `Constants.imagePageLongSide`, mantendo a proporção.

- [ ] **Step 4: Rodar.** Mesmo comando → PASS.

- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona primitivas de imagem jpeg e montagem de pdf`

---

### Task 5: Compressor de PDF

**Files:**
- Create: `Sources/FileToolsCore/Compression/{PDFCompressor,CompressionResult,ScannedPageDetector}.swift`
- Test: `Tests/FileToolsCoreTests/{PDFCompressorTests,ScannedPageDetectorTests}.swift`

**Interfaces:**
- Consumes: Task 4 inteira, `SizeLimit`.
- Produces:
  - `public enum CompressionMode: Sendable, Equatable { case scannedPagesOnly, allPages }`
  - `public struct CompressionStep: Sendable, Equatable { public let mode: CompressionMode; public let quality: RasterQuality }`
  - `public enum CompressionOutcome: Sendable, Equatable { case alreadyUnderLimit(bytes: Int); case compressed(data: Data, originalBytes: Int, step: CompressionStep); case unreachable(smallestBytes: Int) }`
  - `public struct PDFCompressor: Sendable { public init(ladder: [RasterQuality] = Constants.rasterLadder); public func compress(_ data: Data, limit: SizeLimit) throws(ActionFailure) -> CompressionOutcome }`
  - `public enum ScannedPageDetector { public static func isScanned(_ page: PDFPage) -> Bool }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func smallFileIsUntouched() throws {
  let d = Fixtures.textPDF(["Reembolso"])
  #expect(try PDFCompressor().compress(d, limit: .megabytes(1)) == .alreadyUnderLimit(bytes: d.count))
}
@Test func scannedFallsUnderOneMegabyte() throws {
  let d = Fixtures.scannedPDF(pages: 2); try #require(d.count > 1_000_000)
  guard case let .compressed(out, original, _) = try PDFCompressor().compress(d, limit: .megabytes(1)) else { Issue.record(); return }
  #expect(out.count < 1_000_000); #expect(original == d.count)
  #expect(try PDFReader.open(out).pageCount == 2)
}
@Test func stopsAtMostLegibleFittingStep() throws {
  let d = Fixtures.scannedPDF(pages: 1)
  guard case let .compressed(_, _, step) = try PDFCompressor().compress(d, limit: SizeLimit(bytes: d.count - 1)) else { Issue.record(); return }
  #expect(step == CompressionStep(mode: .scannedPagesOnly, quality: Constants.rasterLadder[0]))
}
@Test func keepsTextPagesSelectable() throws {
  let d = merge(Fixtures.textPDF(["Reembolso de despesas"]), Fixtures.scannedPDF(pages: 1))
  guard case let .compressed(out, _, step) = try PDFCompressor().compress(d, limit: .megabytes(1)) else { Issue.record(); return }
  #expect(step.mode == .scannedPagesOnly)
  #expect(try PDFReader.open(out).page(at: 0)?.string?.contains("Reembolso") == true)
}
@Test func reportsUnreachableWithSmallestSize() throws {
  let d = Fixtures.scannedPDF(pages: 1)
  guard case let .unreachable(smallest) = try PDFCompressor().compress(d, limit: SizeLimit(bytes: 5_000)) else { Issue.record(); return }
  #expect(smallest > 5_000); #expect(smallest < d.count)
}
@Test func largeDocumentCompletes() throws {
  let d = Fixtures.scannedPDF(pages: 30, pixelWidth: 827, pixelHeight: 1169)
  guard case let .compressed(out, _, _) = try PDFCompressor().compress(d, limit: .megabytes(5)) else { Issue.record(); return }
  #expect(try PDFReader.open(out).pageCount == 30)
}
@Test func encryptedThrows() { #expect(throws: ActionFailure.encrypted) { try PDFCompressor().compress(Fixtures.encryptedPDF(), limit: .megabytes(1)) } }

@Test func detector() throws {
  #expect(!ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.textPDF(["x"])).page(at: 0)!))
  #expect(ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.scannedPDF(pages: 1)).page(at: 0)!))
  #expect(!ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.logoPDF()).page(at: 0)!))
}
```

`merge` é um helper local que usa `PDFAssembler` com as páginas `.vector` dos dois documentos.

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "PDFCompressorTests|ScannedPageDetectorTests"`

- [ ] **Step 3: Implementar**

`ScannedPageDetector.isScanned`: percorre `page.pageRef` → `Resources` → `XObject` com `CGPDFDictionaryApplyBlock` e pega a maior imagem (`/Subtype /Image`, `Width × Height` do dicionário do stream). A página é escaneada se essa área em pixels for `>=` largura × altura da página em pontos (equivale a ≥ 72 DPI na página inteira). Assim, logo pequeno não conta, e escaneado com camada de OCR conta. XObjects do tipo Form ficam de fora.

`PDFCompressor.compress`:

```
doc = PDFReader.open(data)
se limit.accepts(data.count) → .alreadyUnderLimit(data.count)
scanned = índices das páginas escaneadas
estágios = []
se 0 < scanned.count < pageCount → estágios += ladder.map { (.scannedPagesOnly, $0) }
estágios += ladder.map { (.allPages, $0) }
se scanned.count == pageCount → (.allPages) já cobre; (.scannedPagesOnly) não entra
menor = Int.max
para cada estágio:
  fontes = páginas em ordem; rasteriza (render na dpi → jpegBackedImage na qualidade) as páginas do modo, mantém as outras .vector
  cada página dentro de autoreleasepool; soma os bytes JPEG; se a soma passar de limit.bytes, aborta o estágio (menor = min(menor, soma))
  out = PDFAssembler.assemble(fontes); menor = min(menor, out.count)
  se limit.accepts(out.count) → .compressed(out, data.count, estágio)
→ .unreachable(menor)
```

- [ ] **Step 4: Rodar.** Mesmo comando → PASS.

- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona compressor de pdf com escada de qualidade`

---

### Task 6: Modelo de ações e textos para o usuário

**Files:**
- Create: `Sources/FileToolsCore/Actions/{ActionID,ActionDescriptor,Availability,ActionAvailability,ActionReport,OutputWriter,ImmediateAction}.swift`, `Sources/FileToolsCore/Messages/{UserMessage,ReportFormatter}.swift`
- Modify: `Sources/FileToolsCore/Constants.swift`
- Test: `Tests/FileToolsCoreTests/{ActionAvailabilityTests,ReportFormatterTests,OutputWriterTests}.swift`

**Interfaces:**
- Produces:
  - `public enum ActionID: String, Sendable, CaseIterable { case optimizePDF, mergePDFs, splitPDF, organizePDF, imagesToPDF, pdfToJPG, pdfToMarkdown }`
  - `public enum ActionInteraction: Sendable { case immediate, splitDialog, organizeWindow }`
  - `public struct ActionDescriptor: Sendable { public let id: ActionID; public let title: String; public let shortLabel: String; public let symbol: String; public let colorHex: String; public let slot: Int; public let interaction: ActionInteraction; public let progressTitle: String }` e `Constants.actions: [ActionDescriptor]` (em ordem de slot) e `Constants.descriptor(_ id: ActionID) -> ActionDescriptor`
  - `public enum Availability: Sendable, Equatable { case available; case unavailable(reason: String) }`
  - `public enum ActionAvailability { public static func availability(of id: ActionID, for urls: [URL], pageCount: (URL) -> Int? = { (try? PDFReader.open($0))?.pageCount }) -> Availability }`
  - `public struct ActionReport: Sendable, Equatable { public var outputs: [Output]; public var untouched: [Untouched]; public var failures: [Failure] }` com `Output { url: URL; isFolder: Bool; sourceCount: Int; originalBytes: Int; finalBytes: Int; pageCount: Int; ocrPageCount: Int }`, `Untouched { url: URL; bytes: Int }`, `Failure { url: URL; reason: ActionFailure }`. Inits com valores padrão (0, false, []).
  - `public protocol ImmediateAction: Sendable { var id: ActionID { get }; func run(_ urls: [URL], limit: SizeLimit) -> ActionReport }`
  - `public enum OutputWriter { public static func write(_ data: Data, to url: URL) throws(ActionFailure); public static func makeFolder(_ url: URL) throws(ActionFailure) }`
  - `public struct UserMessage: Sendable, Equatable { public let title: String; public let body: String; public let isError: Bool }`
  - `public enum ReportFormatter { public static func messages(for report: ActionReport, action: ActionID, limit: SizeLimit) -> [UserMessage]; public static func format(bytes: Int) -> String }`

Descritores, nesta ordem de slot (0 = topo, sentido horário):

| slot | id | title | shortLabel | symbol | progressTitle | interaction |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | optimizePDF | Otimizar PDF | Otimizar | arrow.down.doc | Otimizando… | immediate |
| 1 | mergePDFs | Juntar PDFs | Juntar | doc.on.doc | Juntando… | immediate |
| 2 | splitPDF | Dividir PDF | Dividir | scissors | Dividindo… | splitDialog |
| 3 | organizePDF | Organizar PDF | Organizar | square.grid.2x2 | Abrindo… | organizeWindow |
| 4 | imagesToPDF | Imagens para PDF | Imagens→PDF | photo.on.rectangle | Gerando PDF… | immediate |
| 5 | pdfToJPG | PDF para JPG | PDF→JPG | photo | Convertendo… | immediate |
| 6 | pdfToMarkdown | PDF para Markdown | Markdown | doc.plaintext | Extraindo texto… | immediate |

Slot 7 é a vaga (símbolo `plus`).

Regras de disponibilidade (motivos com o texto exato):

| id | disponível quando | motivo quando não |
| --- | --- | --- |
| optimizePDF, pdfToJPG, pdfToMarkdown | algum PDF na seleção | `só para PDF` |
| mergePDFs | ≥ 2 arquivos, todos PDF ou imagem | `selecione 2 ou mais`; com algum outro tipo: `só PDFs e imagens` |
| splitPDF | exatamente 1 PDF e `pageCount > 1` | `selecione 1 PDF`; com 1 página: `o PDF tem só 1 página` |
| organizePDF | exatamente 1 PDF | `selecione 1 PDF` |
| imagesToPDF | ≥ 1 arquivo, todos imagem | `só para imagens` |

Textos (`{lim}` = `format(bytes: limit.bytes)`, `{nome}` = `lastPathComponent` do arquivo, `{saida}` = `lastPathComponent` da saída):

| caso | title | body |
| --- | --- | --- |
| optimize output | `{saida}` | `{orig} → {final} · abaixo do limite de {lim}` |
| images output | `{saida}` | `{n} imagens · {orig} → {final} · abaixo do limite de {lim}` (n = 1: `1 imagem`) |
| merge output | `{saida}` | `{n} arquivos · {orig} → {final} · abaixo do limite de {lim}` |
| pdfToJPG output | `{saida}` | `{p} páginas convertidas em JPG` / `1 página convertida em JPG` |
| pdfToMarkdown output | `{saida}` | `Texto de {p} páginas` / `Texto de 1 página`, + ` ({k} com OCR)` se k > 0 |
| split, pasta | `{saida}` | `{p} PDFs, um por página` |
| split, arquivo | `{saida}` | `{p} páginas extraídas` / `1 página extraída` |
| organize output | `{saida}` | `{p} páginas salvas` / `1 página salva` |
| untouched | `{nome} já está ok` | `{bytes}, abaixo de {lim}. Nenhum arquivo novo foi criado.` |
| unreachable | `Não deu para chegar a {lim}` | `{nome} ficou com {menor} na menor qualidade legível. O original não foi alterado.` |
| encrypted | `PDF protegido por senha` | `{nome} tem senha. Remova a senha no Preview e tente de novo.` |
| unreadable | `Não deu para abrir o arquivo` | `{nome} está corrompido ou num formato que o app não lê.` |
| writeFailed | `Não deu para salvar` | `Sem permissão para gravar na pasta de {nome}. Copie o arquivo para outra pasta e tente de novo.` |
| noText | `Nenhum texto encontrado` | `{nome} não tem texto, nem com OCR. Nenhum arquivo foi criado.` |

Falhas e unreachable têm `isError = true`. Ordem das mensagens: outputs, untouched, failures.

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func bytes() {
  #expect(ReportFormatter.format(bytes: 870_000) == "870 KB")
  #expect(ReportFormatter.format(bytes: 640_400) == "640 KB")
  #expect(ReportFormatter.format(bytes: 1_000_000) == "1 MB")
  #expect(ReportFormatter.format(bytes: 3_400_000) == "3,4 MB")
  #expect(ReportFormatter.format(bytes: 1_640_000) == "1,6 MB")
}
@Test func optimizeSuccess() {
  let r = ActionReport(outputs: [.init(url: URL(fileURLWithPath: "/t/nota-otimizado.pdf"), sourceCount: 1, originalBytes: 3_400_000, finalBytes: 870_000, pageCount: 2)])
  #expect(ReportFormatter.messages(for: r, action: .optimizePDF, limit: .megabytes(1)) ==
    [UserMessage(title: "nota-otimizado.pdf", body: "3,4 MB → 870 KB · abaixo do limite de 1 MB", isError: false)])
}
@Test func untouched() { /* Untouched(nota.pdf, 640_000) → "nota.pdf já está ok" / "640 KB, abaixo de 1 MB. Nenhum arquivo novo foi criado." */ }
@Test func unreachable() { /* Failure(fatura.pdf, .unreachable(1_600_000)) → "Não deu para chegar a 1 MB" / "fatura.pdf ficou com 1,6 MB na menor qualidade legível. O original não foi alterado." */ }
```

Escreva um `@Test` para cada linha restante da tabela de textos, com a string exata. Em `ActionAvailabilityTests`, um `@Test` por célula da tabela de disponibilidade, com `pageCount` injetado (`{ _ in 8 }` e `{ _ in 1 }`). `OutputWriterTests`: escreve e lê de volta; pasta com `chmod 0555` → `throws: ActionFailure.writeFailed`.

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "ActionAvailabilityTests|ReportFormatterTests|OutputWriterTests"`

- [ ] **Step 3: Implementar** conforme as tabelas. `format(bytes:)`: abaixo de 1.000.000 → `"\(Int((Double(n)/1000).rounded())) KB"`. Senão, MB com uma casa decimal e vírgula, e sem `,0` quando o valor é inteiro. `OutputWriter.write` usa `data.write(to:options: .atomic)` e converte qualquer erro em `.writeFailed`.

- [ ] **Step 4: Rodar.** PASS.

- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona modelo de ações, disponibilidade e textos`

---

### Task 7: Otimizar PDF

**Files:**
- Create: `Sources/FileToolsCore/Actions/OptimizePDFAction.swift`
- Test: `Tests/FileToolsCoreTests/OptimizePDFActionTests.swift`

**Interfaces:**
- Consumes: `PDFCompressor`, `OutputNaming.optimized`, `OutputWriter`, `ActionReport`, `FileKind`.
- Produces: `public struct OptimizePDFAction: ImmediateAction { public init() }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func writesSiblingWithSuffix() throws {
  let d = try Fixtures.tempDirectory(); let src = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
  let before = try Data(contentsOf: src)
  let r = OptimizePDFAction().run([src], limit: .megabytes(1))
  #expect(r.outputs.map(\.url.lastPathComponent) == ["nota-otimizado.pdf"])
  #expect(r.outputs[0].finalBytes < 1_000_000)
  #expect(try Data(contentsOf: src) == before)
}
@Test func smallFileCreatesNothing() { /* textPDF → r.untouched.count == 1; pasta continua com 1 arquivo */ }
@Test func continuesAfterFailure() { /* [quebrado.pdf (bytes "x"), nota.pdf escaneado] → failures == [Failure(quebrado, .unreadable)], outputs.count == 1 */ }
@Test func unreachableWritesNothing() { /* limite 5_000 → failures[0].reason é .unreachable; pasta com 1 arquivo */ }
@Test func ignoresNonPDFs() { /* [foto.png, nota.pdf] → só nota é processada; foto não aparece no report */ }
@Test func readOnlyFolder() { /* pasta 0555 → failures[0].reason == .writeFailed */ }
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter OptimizePDFActionTests`
- [ ] **Step 3: Implementar.** Para cada PDF em `naturalOrder(urls)`: lê o `Data`, chama `compress` e mapeia `.alreadyUnderLimit` → `untouched`, `.compressed` → grava em `OutputNaming.optimized` e entra em `outputs`, `.unreachable` e erros → `failures`.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona ação de otimizar pdf`

---

### Task 8: Imagens para PDF

**Files:**
- Create: `Sources/FileToolsCore/Actions/ImagesToPDFAction.swift`
- Test: `Tests/FileToolsCoreTests/ImagesToPDFActionTests.swift`

**Interfaces:**
- Consumes: `ImageLoader`, `JPEGEncoder`, `PDFAssembler`, `Constants.rasterLadder`, `OutputNaming.imagesPDF`.
- Produces: `public struct ImagesToPDFAction: ImmediateAction { public init(ladder: [RasterQuality] = Constants.rasterLadder) }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func onePDFInNaturalOrder() throws {
  let d = try Fixtures.tempDirectory()
  let p2 = d.appending(path: "IMG_2.png"), p10 = d.appending(path: "IMG_10.png")
  try Fixtures.writeImage(Fixtures.noiseImage(width: 200, height: 400), to: p2, type: .png)
  try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: p10, type: .png)
  let r = ImagesToPDFAction().run([p10, p2], limit: .megabytes(1))
  #expect(r.outputs.map(\.url.lastPathComponent) == ["IMG_2.pdf"])
  let doc = try PDFReader.open(r.outputs[0].url)
  #expect(doc.pageCount == 2)
  let b0 = doc.page(at: 0)!.bounds(for: .cropBox), b1 = doc.page(at: 1)!.bounds(for: .cropBox)
  #expect(b0.height > b0.width); #expect(b1.width > b1.height)
  #expect(abs(max(b0.width, b0.height) - 842) < 0.5)
}
@Test func respectsExif() { /* jpg 400x200 com orientation 6 → página em retrato */ }
@Test func bigPhotosFitLimit() { /* 3 noise 4032x3024 → outputs[0].finalBytes < 1_000_000, sourceCount == 3 */ }
@Test func abortsWhenOneFails() { /* [boa.png, quebrada.png] → outputs vazio, failures == [Failure(quebrada, .unreadable)], nenhum .pdf na pasta */ }
@Test func unreachableWritesNothing() { /* limite 5_000 → .unreachable; nenhum .pdf na pasta */ }
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter ImagesToPDFActionTests`
- [ ] **Step 3: Implementar.** Carrega todas as imagens primeiro, com a orientação já aplicada (a primeira falha aborta tudo). Para cada degrau da escada: `maxPixelSize = Int(842 * dpi / 72)`, recarrega com esse limite (sem ampliar), gera `jpegBackedImage`, `pageSize = imagePageSize` e monta. Grava no primeiro degrau que passa no limite. Se nenhum passar, a falha é `.unreachable(menor)` com a URL da primeira imagem. `originalBytes` = soma dos tamanhos dos arquivos de origem.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona ação de imagens para pdf`

---

### Task 9: Juntar PDFs

**Files:**
- Create: `Sources/FileToolsCore/Actions/MergePDFsAction.swift`
- Test: `Tests/FileToolsCoreTests/MergePDFsActionTests.swift`

**Interfaces:**
- Consumes: `PDFReader`, `ImageLoader`, `JPEGEncoder`, `PDFAssembler`, `PDFCompressor`, `OutputNaming.merged`.
- Produces: `public struct MergePDFsAction: ImmediateAction { public init() }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func naturalOrderWithImages() throws {
  // a_10.pdf ("dez"), a_2.pdf ("dois"), b.png
  let r = MergePDFsAction().run([a10, b, a2], limit: .megabytes(1))
  #expect(r.outputs.map(\.url.lastPathComponent) == ["a_2-juntado.pdf"])
  let doc = try PDFReader.open(r.outputs[0].url)
  #expect(doc.pageCount == 3)
  #expect(doc.page(at: 0)!.string!.contains("dois")); #expect(doc.page(at: 1)!.string!.contains("dez"))
  #expect(r.outputs[0].sourceCount == 3)
}
@Test func compressesWhenOverLimit() { /* 2 scannedPDF(pages: 1) → finalBytes < 1_000_000 */ }
@Test func abortsOnEncrypted() { /* [boa.pdf, senha.pdf] → outputs vazio, failures == [Failure(senha, .encrypted)], só os 2 arquivos na pasta */ }
@Test func unreachableWritesNothing() { /* limite 5_000 */ }
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter MergePDFsActionTests`
- [ ] **Step 3: Implementar.** Em `naturalOrder`: PDF → páginas `.vector`, imagem → `.image` com `rasterLadder[0]` e lado maior 842. A primeira falha aborta tudo. Monta o PDF. Se ele já passa no limite, grava. Senão, chama `PDFCompressor.compress`: `.compressed` → grava, `.unreachable` → falha com a URL do primeiro arquivo. `originalBytes` = soma das origens.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona ação de juntar pdfs`

---

### Task 10: PDF para JPG

**Files:**
- Create: `Sources/FileToolsCore/Actions/PDFToJPGAction.swift`
- Test: `Tests/FileToolsCoreTests/PDFToJPGActionTests.swift`

**Interfaces:**
- Consumes: `PageRasterizer`, `JPEGEncoder`, `Constants.jpgExportQuality`, `OutputNaming.singleJPG/pagesFolder/pageFileName`, `OutputWriter`.
- Produces: `public struct PDFToJPGAction: ImmediateAction { public init() }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func singlePage() { /* textPDF(["a"]) "nota.pdf" → outputs[0].url.lastPathComponent == "nota.jpg", isFolder false, pageCount 1; imagem 1240x1754 ±1 (A4 a 150 DPI) */ }
@Test func manyPages() { /* textPDF 3 páginas → pasta "nota-paginas" com ["nota-01.jpg","nota-02.jpg","nota-03.jpg"], isFolder true, pageCount 3 */ }
@Test func eachPDFSeparately() { /* [a.pdf, b.pdf] → 2 outputs */ }
@Test func encryptedFails() { /* failures == [Failure(senha.pdf, .encrypted)] */ }
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter PDFToJPGActionTests`
- [ ] **Step 3: Implementar.** Cada página → `PageRasterizer.render(dpi: 150)` → `JPEGEncoder.encode(quality: 0.85)`, em `autoreleasepool`. Com várias páginas, cria a pasta antes. Se uma página falhar no meio, apaga a pasta criada e registra a falha.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona ação de pdf para jpg`

---

### Task 11: PDF para Markdown

**Files:**
- Create: `Sources/FileToolsCore/Markdown/{MarkdownConverter,OCRRecognizer}.swift`, `Sources/FileToolsCore/Actions/PDFToMarkdownAction.swift`
- Modify: `Tests/FileToolsCoreTests/Fixtures.swift` (acrescentar `richPDF() -> Data`)
- Test: `Tests/FileToolsCoreTests/{MarkdownConverterTests,PDFToMarkdownActionTests}.swift`

**Interfaces:**
- Consumes: `PDFReader`, `PageRasterizer`, `OutputNaming.markdown`, `OutputWriter`.
- Produces:
  - `public struct MarkdownResult: Sendable, Equatable { public let markdown: String; public let ocrPageCount: Int }`
  - `public enum MarkdownConverter { public static func convert(_ document: PDFDocument, ocr: (PDFPage) -> [String] = OCRRecognizer.lines) -> MarkdownResult }`
  - `public enum OCRRecognizer { public static func lines(in page: PDFPage) -> [String] }`
  - `public struct PDFToMarkdownAction: ImmediateAction { public init() }`

`Fixtures.richPDF()`: uma página desenhada com CoreText contendo `Relatório de Despesas` (24 pt negrito), `Resumo` (15 pt), `Itens pagos` (12 pt negrito), dois parágrafos de 12 pt, as linhas `• Táxi`, `• Hotel`, `1. Primeiro`, `2) Segundo`, e a linha `Mais em site`, com uma `PDFAnnotation` do tipo link sobre "site" apontando para `https://example.com`. Uma segunda página só com `Fixtures.textImage("TOTAL 123", …, pointSize: 48)` como bitmap (escaneada, sem texto).

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func structure() throws {
  let r = MarkdownConverter.convert(try PDFReader.open(Fixtures.richPDF()), ocr: { _ in ["TOTAL 123"] })
  #expect(r.markdown.contains("# Relatório de Despesas\n"))
  #expect(r.markdown.contains("## Resumo\n"))
  #expect(r.markdown.contains("### Itens pagos\n"))
  #expect(r.markdown.contains("- Táxi\n- Hotel\n"))
  #expect(r.markdown.contains("1. Primeiro\n2. Segundo\n"))
  #expect(r.markdown.contains("[site](https://example.com)"))
  #expect(r.markdown.contains("TOTAL 123")); #expect(r.ocrPageCount == 1)
}
@Test func realOCR() throws {
  let doc = try PDFReader.open(Fixtures.scannedTextPDF("TOTAL 123"))
  #expect(OCRRecognizer.lines(in: doc.page(at: 0)!).joined(separator: " ").contains("TOTAL"))
}
@Test func actionWritesFile() { /* richPDF "nota.pdf" → outputs[0].url.lastPathComponent == "nota.md", pageCount 2, ocrPageCount 1 */ }
@Test func noTextAnywhere() { /* PDF só com ruído e OCR que retorna [] → failures == [Failure(url, .noText)], sem .md na pasta */ }
```

`Fixtures.scannedTextPDF(_:)` é uma página A4 só com `textImage` em bitmap.

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "MarkdownConverterTests|PDFToMarkdownActionTests"`
- [ ] **Step 3: Implementar `MarkdownConverter.convert`**

```
corpo = mediana do tamanho de fonte ponderada pelo número de caracteres no documento todo (page.attributedString, NSFont em .font)
para cada página:
  texto vazio depois de trim → linhas = ocr(page), ocrPageCount += 1, cada linha vira parágrafo
  senão, para cada linha de attributedString separada por "\n":
    tamanho = maior pointSize da linha; negrito = fonte com traço .bold em todos os runs
    tamanho >= corpo*1.6 → "# "; >= corpo*1.2 → "## "; negrito && count <= 80 && !hasSuffix(".") → "### "
    regex ^\s*[•\-–*]\s+ → "- " + resto;  ^\s*(\d+)[.)]\s+ → "\(n). " + resto
    links: para cada PDFAnnotation .link com url na página, texto = page.selection(for: bounds)?.string trim; troca a primeira ocorrência na linha por "[texto](url)"
  linhas comuns seguidas viram um parágrafo, unidas por espaço; blocos separados por linha em branco; páginas separadas por linha em branco
```

`OCRRecognizer.lines`: renderiza a página a 200 DPI, `VNRecognizeTextRequest` com `.accurate`, `recognitionLanguages = ["pt-BR", "en-US"]` e `usesLanguageCorrection = true`. Ordena as observações de cima para baixo e devolve `topCandidates(1).first?.string`. A ação grava o `.md` em UTF-8. Markdown vazio depois de trim → `.noText`.

- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona ação de pdf para markdown com ocr`

---

### Task 12: Dividir PDF (núcleo)

**Files:**
- Create: `Sources/FileToolsCore/Split/{PageRangeParser,PageRangeError,SplitMode,PDFSplitter}.swift`
- Test: `Tests/FileToolsCoreTests/{PageRangeParserTests,PDFSplitterTests}.swift`

**Interfaces:**
- Produces:
  - `public enum PageRangeError: Error, Sendable, Equatable { case invalidSyntax; case pageOutOfRange(page: Int, pageCount: Int); public var message: String }`
  - `public enum PageRangeParser { public static func parse(_ text: String, pageCount: Int) -> Result<[Int], PageRangeError> }` (números de página a partir de 1, na ordem digitada)
  - `public enum SplitMode: Sendable, Equatable { case allPages; case extract([Int]) }`
  - `public enum PDFSplitter { public static func split(_ url: URL, mode: SplitMode) -> ActionReport }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func parses() {
  #expect(PageRangeParser.parse("1-3, 5", pageCount: 8) == .success([1, 2, 3, 5]))
  #expect(PageRangeParser.parse(" 2 ,4-4", pageCount: 8) == .success([2, 4]))
  #expect(PageRangeParser.parse("5-3", pageCount: 8) == .success([5, 4, 3]))
}
@Test func errors() {
  #expect(PageRangeParser.parse("1-3, 9", pageCount: 8) == .failure(.pageOutOfRange(page: 9, pageCount: 8)))
  #expect(PageRangeParser.parse("0", pageCount: 8) == .failure(.pageOutOfRange(page: 0, pageCount: 8)))
  #expect(PageRangeParser.parse("", pageCount: 8) == .failure(.invalidSyntax))
  #expect(PageRangeParser.parse("a-b", pageCount: 8) == .failure(.invalidSyntax))
  #expect(PageRangeError.pageOutOfRange(page: 9, pageCount: 8).message == "Página 9 não existe (o PDF tem 8)")
  #expect(PageRangeError.invalidSyntax.message == "Use números e intervalos, como 1-3, 5")
}
@Test func splitsAll() { /* textPDF de 3 páginas "nota.pdf" → pasta "nota-paginas" com nota-01..03.pdf, cada um com 1 página e o texto certo; output isFolder true, pageCount 3 */ }
@Test func extractsInTypedOrder() { /* extract([3, 1]) → "nota-extraido.pdf" com páginas na ordem 3, 1; pageCount 2 */ }
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "PageRangeParserTests|PDFSplitterTests"`
- [ ] **Step 3: Implementar.** Parser: separa por vírgula, faz trim, aceita `n` ou `a-b`, e o primeiro número fora de `1...pageCount` vira erro. Splitter: `PDFAssembler` com `.vector` (sem rasterizar), `OutputNaming.pagesFolder` / `pageFileName` / `extracted`. Erros de leitura e escrita vão para `failures`, e a pasta criada é apagada se falhar no meio.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona divisão de pdf por página e por intervalo`

---

### Task 13: Organizar PDF (modelo e exportação)

**Files:**
- Create: `Sources/FileToolsCore/Organize/{OrganizePage,OrganizeModel,OrganizeExporter}.swift`
- Test: `Tests/FileToolsCoreTests/{OrganizeModelTests,OrganizeExporterTests}.swift`

**Interfaces:**
- Produces:
  - `public struct OrganizePage: Identifiable, Sendable, Equatable { public let id: UUID; public let source: Source; public var rotation: Int; public enum Source: Sendable, Equatable { case pdf(URL, index: Int); case image(URL) } }`
  - `public struct OrganizeModel: Sendable, Equatable { public private(set) var pages: [OrganizePage]; public init(pdf: URL) throws(ActionFailure); public mutating func move(_ ids: Set<UUID>, to index: Int); public mutating func delete(_ ids: Set<UUID>); public mutating func rotate(_ ids: Set<UUID>, by degrees: Int); public mutating func append(_ url: URL) throws(ActionFailure); public var canSave: Bool }`
  - `public enum OrganizeExporter { public static func export(_ model: OrganizeModel, original: URL) -> ActionReport }`

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func loadsPages() { /* textPDF 4 páginas → pages.count 4, sources .pdf(url, 0...3), rotation 0 */ }
@Test func moveKeepsRelativeOrder() { /* [p0,p1,p2,p3], move({p0,p2}, to: 4) → [p1,p3,p0,p2]; move({p3}, to: 0) → [p3,p0,p1,p2] */ }
@Test func deleteAndCanSave() { /* delete todos → pages vazio, canSave false */ }
@Test func rotateNormalizes() { /* rotate(+90) 5x → 90; rotate(-90) a partir de 0 → 270 */ }
@Test func appendsPDFAndImage() { /* append(outro.pdf de 2 páginas) → +2 no fim; append(foto.png) → +1 .image; append(arquivo.txt) throws .unreadable */ }
@Test func exportApplies() {
  // 3 páginas "um","dois","três"; delete p1; rotate p2 +90; move p2 para 0 → export
  // "nota-organizado.pdf"; páginas: "três" (rotação efetiva 90), "um"; pageCount 2
}
```

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "OrganizeModelTests|OrganizeExporterTests"`
- [ ] **Step 3: Implementar.** `move` remove os ids selecionados (mantendo a ordem relativa entre eles) e os insere no índice ajustado pelos removidos antes dele. O exporter abre cada PDF de origem uma vez (cache por URL), mapeia `.pdf` → `.vector(page, extraRotation: rotation)` e `.image` → `.image(jpegBackedImage(rasterLadder[0]), imagePageSize, rotation)`, e grava em `OutputNaming.organized`.
- [ ] **Step 4: Rodar.** PASS.
- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(core): adiciona modelo e exportação do organizar pdf`

---

### Task 14: Execução, notificações e Services

**Files:**
- Create: `Sources/FileToolsApp/Run/{ActionCoordinator,Notifier,ServiceProvider}.swift`
- Modify: `Resources/Info.plist`, `Sources/FileToolsApp/AppDelegate.swift`

**Interfaces:**
- Consumes: `ImmediateAction` e as cinco ações imediatas, `ReportFormatter`, `SettingsStore`, `ActionAvailability`, `Constants.descriptor`.
- Produces:
  - `@MainActor final class ActionCoordinator { init(settings: SettingsStore, notifier: Notifier); func run(_ id: ActionID, urls: [URL], near point: CGPoint?) async; var presentSplit: ((URL, Int, CGPoint?) -> Void)?; var presentOrganize: ((URL) -> Void)?; func deliver(_ report: ActionReport, action: ActionID) }`
  - `@MainActor final class Notifier { func requestAuthorization(); func post(_ messages: [UserMessage]) }`
  - `enum ActionCatalog { static func immediate(_ id: ActionID) -> (any ImmediateAction)? }` em `ActionCoordinator.swift`: `switch` das cinco ações imediatas, e `nil` para dividir e organizar.
  - `final class ServiceProvider: NSObject` com `@objc func optimizePDF(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>)` e os equivalentes `mergePDFs`, `splitPDF`, `organizePDF`, `imagesToPDF`, `pdfToJPG`, `pdfToMarkdown`.

- [ ] **Step 1: `ActionCoordinator.run`**

Se a ação não estiver disponível para as URLs, não faz nada. `.immediate` → `let limit = settings.sizeLimit`, depois `await Task.detached(priority: .userInitiated) { action.run(urls, limit: limit) }.value` e `deliver`. `.splitDialog` → `presentSplit?(url, pageCount, point)`. `.organizeWindow` → `presentOrganize?(url)`. `deliver`: `notifier.post(ReportFormatter.messages(...))` e, se houver outputs, `NSWorkspace.shared.activateFileViewerSelecting(outputs.map(\.url))`.

- [ ] **Step 2: `Notifier`**

`UNUserNotificationCenter` pede autorização (`.alert`) no launch. Se estiver autorizado, cada mensagem vira uma notificação. Sem autorização, só mensagens com `isError` aparecem num `NSAlert` (estilo `.warning`, título e corpo da mensagem).

- [ ] **Step 3: Services**

No `Info.plist`, `NSServices` com 7 entradas: `NSMenuItem.default` = `title` do descritor, `NSMessage` = nome do método, `NSRequiredContext` = `{}`, `NSSendFileTypes` = `["com.adobe.pdf"]` (otimizar, dividir, organizar, JPG, Markdown), `["public.image"]` (imagens) ou `["com.adobe.pdf", "public.image"]` (juntar). Cada método lê `pboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])` e chama `coordinator.run(id, urls:, near: nil)`. No launch, `NSApp.servicesProvider = ServiceProvider(...)` e `NSUpdateDynamicServices()`.

- [ ] **Step 4: Verificação manual**

`scripts/build-app.sh --install`. No Finder, clique direito num PDF de reembolso real → Ações Rápidas ou Serviços → "Otimizar PDF". Esperado: `-otimizado.pdf` ao lado, abaixo de 1 MB, legível, selecionado no Finder, com notificação "… → … · abaixo do limite de 1 MB". Repita "Imagens para PDF" com 2 HEIC, "Juntar PDFs" com 2 PDFs, "PDF para JPG" e "PDF para Markdown". Dividir e Organizar ainda não fazem nada (Tasks 16 e 17).

- [ ] **Step 5: Commit (depois da confirmação do autor)** — `feat(app): executa ações com notificação e services do finder`

---

### Task 15: Menu circular

**Files:**
- Create: `Sources/FileToolsCore/Radial/{RadialGeometry,RadialCoreText,TargetInfo}.swift`, `Sources/FileToolsApp/Radial/{RadialPanelController,RadialMenuModel,RadialMenuView,RadialSliceShape}.swift`
- Modify: `Sources/FileToolsCore/Constants.swift`, `Sources/FileToolsApp/AppDelegate.swift`
- Test: `Tests/FileToolsCoreTests/{RadialGeometryTests,RadialCoreTextTests}.swift`

**Interfaces:**
- Consumes: `RightClickTap.onTrigger`, `FinderTargetResolver`, `ActionCoordinator.run`, `ActionAvailability`, `Constants.actions`.
- Produces:
  - Em `Constants`: `radialDiameter: CGFloat = 260`, `radialCoreRadius = 62`, `radialRingInner = 122`, `radialRingOuter = 128`, `radialIconRadius = 96`, `radialSlotCount = 8`.
  - `public enum RadialGeometry { public static func slot(at offset: CGVector) -> Int? }` (offset com y para cima)
  - `public struct TargetInfo: Sendable, Equatable { public let name: String; public let bytes: Int; public let pageCount: Int?; public let kind: FileKind }`
  - `public struct RadialCoreText: Sendable, Equatable { public let title: String; public let line: String; public let hint: String; public let isReason: Bool; public static func make(hovered: ActionID?, availability: Availability, targets: [TargetInfo], limit: SizeLimit, running: ActionID?) -> RadialCoreText }`
  - `@MainActor final class RadialPanelController { init(coordinator: ActionCoordinator, settings: SettingsStore); func show(targets: [URL], at cgPoint: CGPoint) }`

Textos do miolo (`{lim}` = limite formatado; `{n}` = número de alvos; `{tot}` = soma dos bytes):

| estado | title | line | hint |
| --- | --- | --- | --- |
| sem hover, 1 alvo | `{nome}` | `{bytes}` + ` · {p} páginas` se PDF com p > 1 | `escolha uma ação` |
| sem hover, n alvos | `{n} arquivos` | `{tot}` | `escolha uma ação` |
| hover em ação disponível | `title` do descritor | 1 alvo: `{nome} · {bytes}` (dividir e organizar: `{nome} · {p} páginas`); n: `{n} arquivos · {tot}` | otimizar: `até {lim}`; juntar e imagens: `1 PDF até {lim}`; dividir: `abre as opções`; organizar: `abre o editor`; JPG com 1 PDF: `gera {base}.jpg` se p = 1, senão `gera {p} JPGs`; JPG com n PDFs: `um JPG por página`; Markdown: `gera {base}.md` / `um .md por PDF` |
| hover em ação indisponível | `title` do descritor | o motivo, com `isReason = true` | o mesmo `line` do caso disponível |
| executando | `progressTitle` | `{nome}` ou `{n} arquivos` | `""` |

- [ ] **Step 1: Escrever os testes que falham**

```swift
@Test func slots() {
  #expect(RadialGeometry.slot(at: CGVector(dx: 0, dy: 90)) == 0)
  #expect(RadialGeometry.slot(at: CGVector(dx: 90, dy: 0)) == 2)
  #expect(RadialGeometry.slot(at: CGVector(dx: 0, dy: -90)) == 4)
  #expect(RadialGeometry.slot(at: CGVector(dx: -90, dy: 0)) == 6)
  #expect(RadialGeometry.slot(at: CGVector(dx: 64, dy: 64)) == 1)
  #expect(RadialGeometry.slot(at: CGVector(dx: 90 * sin(.pi * 20 / 180), dy: 90 * cos(.pi * 20 / 180))) == 0)
  #expect(RadialGeometry.slot(at: CGVector(dx: 90 * sin(.pi * 25 / 180), dy: 90 * cos(.pi * 25 / 180))) == 1)
  #expect(RadialGeometry.slot(at: CGVector(dx: 40, dy: 10)) == nil)
  #expect(RadialGeometry.slot(at: CGVector(dx: 200, dy: 0)) == nil)
}
@Test func coreTextOptimize() {
  let t = RadialCoreText.make(hovered: .optimizePDF, availability: .available,
    targets: [TargetInfo(name: "nota-uber.pdf", bytes: 3_400_000, pageCount: 2, kind: .pdf)], limit: .megabytes(1), running: nil)
  #expect(t == RadialCoreText(title: "Otimizar PDF", line: "nota-uber.pdf · 3,4 MB", hint: "até 1 MB", isReason: false))
}
@Test func coreTextSplit() { /* 1 PDF de 8 páginas, hover split → line "nota.pdf · 8 páginas", hint "abre as opções" */ }
@Test func coreTextUnavailable() { /* 2 PDFs, hover organize, .unavailable("selecione 1 PDF") → line "selecione 1 PDF", isReason true, hint "2 arquivos · …" */ }
@Test func coreTextRunning() { /* running .mergePDFs com 2 alvos → title "Juntando…", line "2 arquivos" */ }
```

`slot`: `r = hypot`; `r < 62 || r > 130` → `nil`; `θ = atan2(dx, dy)` normalizado em `[0, 2π)`; índice = `Int(((θ + π/8).truncatingRemainder(dividingBy: 2π)) / (π/4))`. A vaga (slot 7) é devolvida e a UI a ignora.

- [ ] **Step 2: Rodar e ver falhar.** `swift test --filter "RadialGeometryTests|RadialCoreTextTests"`
- [ ] **Step 3: Implementar o core** e rodar → PASS.

- [ ] **Step 4: Implementar o painel**

- `RadialPanelController.show`: monta `TargetInfo` (tamanho via `.fileSizeKey`, `pageCount` via `PDFReader`), calcula a disponibilidade das 7 ações e converte o ponto do CG para AppKit (`y = NSScreen.screens[0].frame.maxY - y`). Cria um `NSPanel` de 300×300 centrado no ponto e limitado ao `visibleFrame` da tela, com `styleMask [.borderless, .nonactivatingPanel]`, `backgroundColor .clear`, `isOpaque false`, `hasShadow false`, `level .popUpMenu`, `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]` e `NSHostingView(RadialMenuView)`.
- Monitores, global e local, enquanto o painel estiver aberto: `.mouseMoved` → `model.hoveredSlot = RadialGeometry.slot(at: mouse - centro)`. `.leftMouseDown` → slot com ação disponível: `model.phase = .running(id)` e `await coordinator.run(id, urls:, near:)`, com o progresso visível por pelo menos 0,4 s; depois fecha. Slot indisponível ou vaga: não faz nada. Miolo (nil com r < 62) ou fora do círculo: fecha. `.rightMouseDown`: fecha. `.keyDown` com keyCode 53 (Esc): fecha. Os monitores são removidos ao fechar.
- `RadialMenuView` (layout do mockup `menu-circular-8.html`): disco `Circle()` com `.glassEffect(.regular, in: Circle())` em 260 pt; 8 separadores finos (`primary.opacity(0.12)`) em 22,5° + 45°·k, de r 62 a 128. Na fatia sob o cursor, se disponível: `RadialSliceShape` (setor anular de 62 a 128, ±22,5°) com a cor a 16% e um arco de r 125 com `lineWidth 6`, ponta arredondada, na cor da ação, com `.shadow(color: cor, radius: 6)`. Miolo em círculo de 124 pt com `.regularMaterial` mais claro, e os textos de `RadialCoreText` (title 12 semibold, line e hint 10 com opacidade 0,62; `isReason` em `#ff5a5f`). Ícones a r 96: quadrado de 30 pt com canto 9, SF Symbol e `shortLabel` 9,5 pt embaixo. Normal: cor a 13% de fundo e 30% de borda. Ativo: preenchido na cor, símbolo branco e glow. Indisponível: opacidade 0,3. Vaga: borda tracejada cinza e opacidade 0,5. Ao abrir, anima de `scale 0.85` + `blur 6` + `opacity 0` até o estado final com spring de 0,16 s. Ao fechar, faz o inverso em 0,12 s.
- `AppDelegate`: `onTrigger` → `resolve` → `radial.show(targets:at:)` ou `tap.passThrough`. Isso substitui o log da Task 3.

- [ ] **Step 5: Verificação manual**

`scripts/build-app.sh --install` e repita a tabela da Task 3, agora com o círculo. Confira também: fatias apagadas com 1 PDF (Juntar, Imagens) e com 2 PDFs (Dividir, Organizar, Imagens); o motivo no miolo; Esc, clique fora e clique no miolo fecham; Otimizar num PDF real gera o arquivo e a notificação; o visual nos modos claro e escuro (Ajustes do Sistema → Aparência); o círculo perto da borda da tela não sai dela.

- [ ] **Step 6: Commit (depois da confirmação do autor)** — `feat(app): adiciona menu circular com as sete ações`

---

### Task 16: Janelinha do Dividir

**Files:**
- Create: `Sources/FileToolsApp/Split/{SplitDialogController,SplitDialogView}.swift`
- Modify: `Sources/FileToolsApp/AppDelegate.swift` (liga `coordinator.presentSplit`)

**Interfaces:**
- Consumes: `PageRangeParser`, `PageRangeError.message`, `PDFSplitter.split`, `ActionCoordinator.deliver`.
- Produces: `@MainActor final class SplitDialogController { func present(for url: URL, pageCount: Int, near cgPoint: CGPoint?) }`

- [ ] **Step 1: Implementar** conforme o mockup. `NSPanel` titulado, `level .floating`, que vira key (`NSApp.activate()`), posicionado perto do ponto (ou centralizado). Título `Dividir {nome} ({p} páginas)`. Rádio "Separar todas as páginas", com legenda `{p} PDFs na pasta {base}-paginas`, marcado por padrão. Rádio "Extrair páginas:", com campo de placeholder `ex.: 1-3, 5` e legenda `1 PDF com essas páginas: {base}-extraido.pdf`. Digitar no campo seleciona esse rádio. Validação a cada tecla com `PageRangeParser`: o erro aparece em vermelho embaixo do campo e desabilita o botão. Botões "Cancelar" (Esc) e "Dividir" (default, Enter). Confirmar fecha a janela, roda `PDFSplitter.split` em `Task.detached` e chama `coordinator.deliver(report, action: .splitPDF)`.
- [ ] **Step 2: Verificação manual.** Com um PDF de 8 páginas: Dividir → Enter gera `nota-paginas/` com 8 arquivos e a notificação "8 PDFs, um por página". Digitar `1-3, 9` mostra "Página 9 não existe (o PDF tem 8)" e o botão fica desabilitado. `1-3, 5` + Enter gera `nota-extraido.pdf` com 4 páginas. Esc fecha sem gerar nada.
- [ ] **Step 3: Commit (depois da confirmação do autor)** — `feat(app): adiciona janela do dividir pdf`

---

### Task 17: Janela do Organizar

**Files:**
- Create: `Sources/FileToolsApp/Organize/{OrganizeWindowController,OrganizeView,ThumbnailCache}.swift`
- Modify: `Sources/FileToolsApp/AppDelegate.swift` (liga `coordinator.presentOrganize`)

**Interfaces:**
- Consumes: `OrganizeModel`, `OrganizeExporter.export`, `ActionCoordinator.deliver`.
- Produces: `@MainActor final class OrganizeWindowController: NSObject, NSWindowDelegate { init(url: URL, coordinator: ActionCoordinator) throws; func show() }`

- [ ] **Step 1: Implementar** conforme o mockup.
  - `NSWindow` de 900×620, redimensionável, título `Organizar {nome}`, com `NSApp.activate()`.
  - Toolbar com girar à esquerda (`rotate.left`, ⌘←), girar à direita (`rotate.right`, ⌘→), apagar (`trash`, ⌫), "Adicionar…" (`NSOpenPanel` aceitando PDF e imagem, várias seleções) e "Salvar" (botão primário, ⌘S, desabilitado quando `!canSave`).
  - `LazyVGrid` adaptativo com mínimo de 120 pt. Cada miniatura vem de `ThumbnailCache` (`PDFPage.thumbnail(of: 184×252, for: .cropBox)` ou `ImageLoader` com `maxPixelSize` 252, cache por `OrganizePage.id`), com `.rotationEffect(rotation)` e o número embaixo. A selecionada tem borda azul de 3 pt e número em pílula azul.
  - Clique seleciona; ⌘-clique e ⇧-clique estendem a seleção. Arrastar reordena via `.draggable(id.uuidString)` + `.dropDestination`, chamando `model.move`. Soltar arquivos do Finder na janela chama `append`.
  - Barra de status: `{p} páginas · {s} selecionadas` à esquerda e `Salvar gera {base}-organizado.pdf` à direita.
  - Cada mutação registra o snapshot anterior do `OrganizeModel` no `undoManager` da janela, para o ⌘Z funcionar.
  - "Salvar" exporta, chama `deliver(report, action: .organizePDF)`, marca como salvo e fecha.
  - `windowShouldClose` com alterações não salvas abre um `NSAlert` "Descartar alterações?" com os botões "Descartar" e "Cancelar".
  - Arquivo inválido em "Adicionar…" → `NSAlert` com o texto de `unreadable` do `ReportFormatter`.
- [ ] **Step 2: Verificação manual.** Com um PDF de 8 páginas: arrastar a 5 para a posição 3, apagar a 2, girar a 4, adicionar uma imagem e salvar. Esperado: `nota-organizado.pdf` com 8 páginas na nova ordem, a página girada e a imagem no fim. ⌘Z desfaz um passo de cada vez. Fechar com alterações pergunta antes. Apagar todas as páginas desabilita o "Salvar".
- [ ] **Step 3: Commit (depois da confirmação do autor)** — `feat(app): adiciona janela do organizar pdf`

---

### Task 18: Janela de configurações

**Files:**
- Create: `Sources/FileToolsApp/Settings/{SettingsView,Permissions,LaunchAtLogin}.swift`
- Modify: `Sources/FileToolsApp/FileToolsApp.swift`, `Sources/FileToolsApp/AppDelegate.swift`

**Interfaces:**
- Consumes: `SettingsStore`, `Constants.actions`, `TriggerModifier`.
- Produces: `@MainActor enum Permissions { static var accessibility: Bool; static var finderAutomation: Bool; static func openAccessibilitySettings(); static func openAutomationSettings() }`, `@MainActor enum LaunchAtLogin { static func apply(_ enabled: Bool) }`

- [ ] **Step 1: Implementar**
  - `Form` com estilo `.grouped`, largura 460.
  - "Limite de tamanho": `TextField` numérico em pt-BR (vírgula) + `Stepper` de 0,1 com sufixo "MB", e a legenda "Vale para Otimizar PDF, Imagens para PDF e Juntar PDFs."
  - "Tecla do menu circular": `Picker` com `TriggerModifier.allCases`, que exibe `title`.
  - "Abrir ao iniciar sessão": `Toggle` → `LaunchAtLogin.apply` (`SMAppService.mainApp.register()` / `unregister()`), também aplicado no launch.
  - Seção "Permissões": linhas "Acessibilidade" e "Automação do Finder" com `checkmark.circle.fill` verde ou `exclamationmark.triangle.fill` laranja, e o botão "Abrir Ajustes" quando falta a permissão. Acessibilidade: `AXIsProcessTrusted()`, URL `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`. Automação: `AEDeterminePermissionToAutomateTarget` com o descriptor do bundle `com.apple.finder` e `askUserIfNeeded: false` (`noErr` = ok), URL `...?Privacy_Automation`. O estado é reavaliado a cada 2 s enquanto a janela está aberta.
  - Seção "Ações": lista com o símbolo na cor de cada descritor e o `title`, e a legenda "⌥ + clique direito no arquivo, ou clique direito → Ações Rápidas." (a tecla segue a configurada).
  - Trocar a tecla vale no próximo clique, porque o tap lê `settings.triggerModifier` a cada evento.
- [ ] **Step 2: Verificação manual.** Mudar o limite para 0,5 e otimizar um PDF: o resultado fica abaixo de 500 KB, e a notificação diz "abaixo do limite de 500 KB". Trocar a tecla para ⌘: ⌘ + clique direito abre o círculo e ⌥ + clique direito não abre mais. Desligar "Abrir ao iniciar sessão" remove o app de Ajustes → Geral → Itens de Início de Sessão. Revogar a Acessibilidade mostra o aviso laranja.
- [ ] **Step 3: Commit (depois da confirmação do autor)** — `feat(app): completa janela de configurações`

---

### Task 19: Verificação final

- [ ] **Step 1:** `swift test` → todos passam. `swift build -c release` sem warnings novos de concorrência.
- [ ] **Step 2:** `grep -rn "TODO\|FIXME\|\.skip\|fatalError(\"unimplemented" Sources Tests` → vazio.
- [ ] **Step 3:** `scripts/build-app.sh --install`. Com um PDF de reembolso real e uma foto HEIC do iPhone: ⌥ + clique direito → cada uma das 7 ações, e depois as mesmas pelo menu normal do Finder (Services). Confira cada item da seção "Como validar" do spec e da Review Focus deste plano (PNG transparente com fundo branco; tap religa; ⌥ em área vazia abre o menu do Finder; nome com acento e emoji; PDF de 30+ páginas sem travar).
- [ ] **Step 4:** Revisão final da branch por um revisor novo (`superpowers:requesting-code-review`).
- [ ] **Step 5:** Mostrar o resumo ao autor e perguntar sobre o merge em `main`. Merge e push só com confirmação explícita.

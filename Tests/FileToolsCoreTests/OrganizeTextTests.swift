import Foundation
import Testing
@testable import FileToolsCore

@Suite struct OrganizeTextTests {
    @Test func status() {
        #expect(OrganizeText.status(pageCount: 8, selectedCount: 2) == "8 páginas · 2 selecionadas")
        #expect(OrganizeText.status(pageCount: 8, selectedCount: 1) == "8 páginas · 1 selecionada")
        #expect(OrganizeText.status(pageCount: 1, selectedCount: 0) == "1 página · 0 selecionadas")
        #expect(OrganizeText.status(pageCount: 0, selectedCount: 0) == "0 páginas · 0 selecionadas")
    }

    @Test func titleAndSaveHint() {
        let url = URL(fileURLWithPath: "/tmp/relatório v2.pdf")
        #expect(OrganizeText.title(for: url) == "Organizar relatório v2.pdf")
        #expect(OrganizeText.saveHint(for: url) == "Salvar gera relatório v2-organizado.pdf")
    }
}

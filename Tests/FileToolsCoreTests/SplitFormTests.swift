import Testing
@testable import FileToolsCore

@Suite struct SplitFormTests {
    @Test func defaultsToAllPages() {
        let form = SplitForm(fileName: "nota.pdf", pageCount: 8)
        #expect(form.choice == .allPages)
        #expect(form.title == "Dividir nota.pdf (8 páginas)")
        #expect(form.allPagesCaption == "8 PDFs na pasta nota-paginas")
        #expect(form.extractCaption == "1 PDF com essas páginas: nota-extraido.pdf")
        #expect(form.mode == .allPages)
        #expect(form.rangeError == nil)
        #expect(form.canConfirm)
    }

    @Test func editingRangeSelectsExtract() {
        var form = SplitForm(fileName: "nota.pdf", pageCount: 8)
        form.editRange("1-3, 5")
        #expect(form.choice == .extract)
        #expect(form.mode == .extract([1, 2, 3, 5]))
        #expect(form.rangeError == nil)
        #expect(form.canConfirm)
    }

    @Test func invalidRangeBlocksConfirmOnlyForExtract() {
        var form = SplitForm(fileName: "nota.pdf", pageCount: 8)
        form.editRange("1-3, 9")
        #expect(form.rangeError == "Página 9 não existe (o PDF tem 8)")
        #expect(form.mode == nil)
        #expect(form.canConfirm == false)
        form.editRange("1-3, a")
        #expect(form.rangeError == "Use números e intervalos, como 1-3, 5")
        form.choice = .allPages
        #expect(form.rangeError == nil)
        #expect(form.mode == .allPages)
        #expect(form.canConfirm)
    }

    @Test func emptyRangeHasNoErrorButCannotConfirm() {
        var form = SplitForm(fileName: "nota.pdf", pageCount: 8)
        form.choice = .extract
        #expect(form.rangeError == nil)
        #expect(form.mode == nil)
        #expect(form.canConfirm == false)
        form.editRange("   ")
        #expect(form.rangeError == nil)
        #expect(form.canConfirm == false)
    }

    @Test func keepsAccentsAndDotsInBaseName() {
        let form = SplitForm(fileName: "relatório v2.final.pdf", pageCount: 1)
        #expect(form.title == "Dividir relatório v2.final.pdf (1 página)")
        #expect(form.allPagesCaption == "1 PDF na pasta relatório v2.final-paginas")
        #expect(form.extractCaption == "1 PDF com essas páginas: relatório v2.final-extraido.pdf")
    }
}

import Foundation
import Testing
@testable import FileToolsCore

struct RadialCoreTextTests {
    private let limit = SizeLimit.megabytes(1)

    private func pdf(_ name: String, bytes: Int = 3_400_000, pages: Int? = 2) -> TargetInfo {
        TargetInfo(name: name, bytes: bytes, pageCount: pages, kind: .pdf)
    }

    private func text(
        _ hovered: ActionID?, _ targets: [TargetInfo], availability: Availability = .available, running: ActionID? = nil
    ) -> RadialCoreText {
        RadialCoreText.make(hovered: hovered, availability: availability, targets: targets, limit: limit, running: running)
    }

    @Test func coreTextOptimize() {
        let t = RadialCoreText.make(hovered: .optimizePDF, availability: .available,
            targets: [TargetInfo(name: "nota-uber.pdf", bytes: 3_400_000, pageCount: 2, kind: .pdf)], limit: .megabytes(1), running: nil)
        #expect(t == RadialCoreText(title: "Otimizar PDF", line: "nota-uber.pdf · 3,4 MB", hint: "até 1 MB", isReason: false))
    }

    @Test func coreTextSplit() {
        #expect(text(.splitPDF, [pdf("nota.pdf", pages: 8)])
            == RadialCoreText(title: "Dividir PDF", line: "nota.pdf · 8 páginas", hint: "abre as opções", isReason: false))
    }

    @Test func coreTextOrganize() {
        #expect(text(.organizePDF, [pdf("nota.pdf", pages: 8)])
            == RadialCoreText(title: "Organizar PDF", line: "nota.pdf · 8 páginas", hint: "abre o editor", isReason: false))
    }

    @Test func coreTextUnavailable() {
        let t = text(.organizePDF, [pdf("nota.pdf", bytes: 1_000_000), pdf("hotel.pdf", bytes: 600_000)],
            availability: .unavailable(reason: "selecione 1 PDF"))
        #expect(t == RadialCoreText(title: "Organizar PDF", line: "selecione 1 PDF", hint: "2 arquivos · 1,6 MB", isReason: true))
    }

    @Test func coreTextRunning() {
        #expect(text(nil, [pdf("a.pdf"), pdf("b.pdf")], running: .mergePDFs)
            == RadialCoreText(title: "Juntando…", line: "2 arquivos", hint: "", isReason: false))
        #expect(text(.optimizePDF, [pdf("nota.pdf")], running: .optimizePDF)
            == RadialCoreText(title: "Otimizando…", line: "nota.pdf", hint: "", isReason: false))
    }

    @Test func idle() {
        #expect(text(nil, [pdf("nota.pdf", pages: 8)])
            == RadialCoreText(title: "nota.pdf", line: "3,4 MB · 8 páginas", hint: "escolha uma ação", isReason: false))
        #expect(text(nil, [pdf("nota.pdf", pages: 1)]).line == "3,4 MB")
        #expect(text(nil, [TargetInfo(name: "foto.png", bytes: 870_000, pageCount: nil, kind: .image)]).line == "870 KB")
        #expect(text(nil, [pdf("a.pdf", bytes: 1_000_000), pdf("b.pdf", bytes: 600_000)])
            == RadialCoreText(title: "2 arquivos", line: "1,6 MB", hint: "escolha uma ação", isReason: false))
    }

    @Test func hints() {
        let one = [pdf("nota.pdf", pages: 3)]
        let two = [pdf("a.pdf", bytes: 1_000_000), pdf("b.pdf", bytes: 600_000)]
        #expect(text(.mergePDFs, two) == RadialCoreText(title: "Juntar PDFs", line: "2 arquivos · 1,6 MB", hint: "1 PDF até 1 MB", isReason: false))
        #expect(text(.imagesToPDF, two).hint == "1 PDF até 1 MB")
        #expect(text(.pdfToJPG, one).hint == "gera 3 JPGs")
        #expect(text(.pdfToJPG, [pdf("nota.pdf", pages: 1)]).hint == "gera nota.jpg")
        #expect(text(.pdfToJPG, two).hint == "um JPG por página")
        #expect(text(.pdfToMarkdown, one).hint == "gera nota.md")
        #expect(text(.pdfToMarkdown, two).hint == "um .md por PDF")
    }

    @Test func unavailableSingleTarget() {
        let image = TargetInfo(name: "foto.png", bytes: 870_000, pageCount: nil, kind: .image)
        #expect(text(.optimizePDF, [image], availability: .unavailable(reason: "só para PDF"))
            == RadialCoreText(title: "Otimizar PDF", line: "só para PDF", hint: "foto.png · 870 KB", isReason: true))
    }
}

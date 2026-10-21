import Foundation
import Testing
@testable import FileToolsCore

struct ReportFormatterTests {
    private let limit = SizeLimit.megabytes(1)

    private func url(_ name: String) -> URL {
        URL(fileURLWithPath: "/t/\(name)")
    }

    private func messages(_ report: ActionReport, _ action: ActionID) -> [UserMessage] {
        ReportFormatter.messages(for: report, action: action, limit: limit)
    }

    @Test func bytes() {
        #expect(ReportFormatter.format(bytes: 870_000) == "870 KB")
        #expect(ReportFormatter.format(bytes: 640_400) == "640 KB")
        #expect(ReportFormatter.format(bytes: 1_000_000) == "1 MB")
        #expect(ReportFormatter.format(bytes: 3_400_000) == "3,4 MB")
        #expect(ReportFormatter.format(bytes: 1_640_000) == "1,6 MB")
    }

    @Test func optimizeSuccess() {
        let report = ActionReport(outputs: [
            .init(url: url("nota-otimizado.pdf"), sourceCount: 1, originalBytes: 3_400_000, finalBytes: 870_000, pageCount: 2)
        ])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(title: "nota-otimizado.pdf", body: "3,4 MB → 870 KB · abaixo do limite de 1 MB", isError: false)
        ])
    }

    @Test func imagesOutput() {
        let many = ActionReport(outputs: [
            .init(url: url("fotos.pdf"), sourceCount: 3, originalBytes: 3_400_000, finalBytes: 870_000, pageCount: 3)
        ])
        #expect(messages(many, .imagesToPDF).first?.body == "3 imagens · 3,4 MB → 870 KB · abaixo do limite de 1 MB")
        let one = ActionReport(outputs: [
            .init(url: url("foto.pdf"), sourceCount: 1, originalBytes: 3_400_000, finalBytes: 870_000, pageCount: 1)
        ])
        #expect(messages(one, .imagesToPDF).first?.body == "1 imagem · 3,4 MB → 870 KB · abaixo do limite de 1 MB")
    }

    @Test func mergeOutput() {
        let report = ActionReport(outputs: [
            .init(url: url("a-juntado.pdf"), sourceCount: 4, originalBytes: 3_400_000, finalBytes: 870_000, pageCount: 9)
        ])
        #expect(messages(report, .mergePDFs) == [
            UserMessage(title: "a-juntado.pdf", body: "4 arquivos · 3,4 MB → 870 KB · abaixo do limite de 1 MB", isError: false)
        ])
    }

    @Test func pdfToJPGOutput() {
        let many = ActionReport(outputs: [.init(url: url("p-paginas"), isFolder: true, pageCount: 5)])
        #expect(messages(many, .pdfToJPG) == [
            UserMessage(title: "p-paginas", body: "5 páginas convertidas em JPG", isError: false)
        ])
        let one = ActionReport(outputs: [.init(url: url("p.jpg"), pageCount: 1)])
        #expect(messages(one, .pdfToJPG).first?.body == "1 página convertida em JPG")
    }

    @Test func pdfToMarkdownOutput() {
        func body(pages: Int, ocr: Int) -> String? {
            let report = ActionReport(outputs: [.init(url: url("p.md"), pageCount: pages, ocrPageCount: ocr)])
            return messages(report, .pdfToMarkdown).first?.body
        }
        #expect(body(pages: 4, ocr: 0) == "Texto de 4 páginas")
        #expect(body(pages: 1, ocr: 0) == "Texto de 1 página")
        #expect(body(pages: 4, ocr: 2) == "Texto de 4 páginas (2 com OCR)")
        #expect(body(pages: 1, ocr: 1) == "Texto de 1 página (1 com OCR)")
    }

    @Test func splitOutput() {
        let folder = ActionReport(outputs: [.init(url: url("p-paginas"), isFolder: true, pageCount: 6)])
        #expect(messages(folder, .splitPDF) == [
            UserMessage(title: "p-paginas", body: "6 PDFs, um por página", isError: false)
        ])
        let file = ActionReport(outputs: [.init(url: url("p-extraido.pdf"), pageCount: 3)])
        #expect(messages(file, .splitPDF).first?.body == "3 páginas extraídas")
        let single = ActionReport(outputs: [.init(url: url("p-extraido.pdf"), pageCount: 1)])
        #expect(messages(single, .splitPDF).first?.body == "1 página extraída")
    }

    @Test func organizeOutput() {
        let many = ActionReport(outputs: [.init(url: url("p-organizado.pdf"), pageCount: 7)])
        #expect(messages(many, .organizePDF) == [
            UserMessage(title: "p-organizado.pdf", body: "7 páginas salvas", isError: false)
        ])
        let one = ActionReport(outputs: [.init(url: url("p-organizado.pdf"), pageCount: 1)])
        #expect(messages(one, .organizePDF).first?.body == "1 página salva")
    }

    @Test func untouched() {
        let report = ActionReport(untouched: [.init(url: url("nota.pdf"), bytes: 640_000)])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(title: "nota.pdf já está ok", body: "640 KB, abaixo de 1 MB. Nenhum arquivo novo foi criado.", isError: false)
        ])
    }

    @Test func unreachable() {
        let report = ActionReport(failures: [.init(url: url("fatura.pdf"), reason: .unreachable(smallestBytes: 1_600_000))])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(
                title: "Não deu para chegar a 1 MB",
                body: "fatura.pdf ficou com 1,6 MB na menor qualidade legível. O original não foi alterado.",
                isError: true)
        ])
    }

    @Test func encrypted() {
        let report = ActionReport(failures: [.init(url: url("a.pdf"), reason: .encrypted)])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(title: "PDF protegido por senha", body: "a.pdf tem senha. Remova a senha no Preview e tente de novo.", isError: true)
        ])
    }

    @Test func unreadable() {
        let report = ActionReport(failures: [.init(url: url("a.pdf"), reason: .unreadable)])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(
                title: "Não deu para abrir o arquivo",
                body: "a.pdf está corrompido ou num formato que o app não lê.",
                isError: true)
        ])
    }

    @Test func writeFailed() {
        let report = ActionReport(failures: [.init(url: url("a.pdf"), reason: .writeFailed)])
        #expect(messages(report, .optimizePDF) == [
            UserMessage(
                title: "Não deu para salvar",
                body: "Sem permissão para gravar na pasta de a.pdf. Copie o arquivo para outra pasta e tente de novo.",
                isError: true)
        ])
    }

    @Test func noText() {
        let report = ActionReport(failures: [.init(url: url("a.pdf"), reason: .noText)])
        #expect(messages(report, .pdfToMarkdown) == [
            UserMessage(
                title: "Nenhum texto encontrado",
                body: "a.pdf não tem texto, nem com OCR. Nenhum arquivo foi criado.",
                isError: true)
        ])
    }

    @Test func orderIsOutputsUntouchedFailures() {
        let report = ActionReport(
            outputs: [.init(url: url("o.pdf"), originalBytes: 2_000_000, finalBytes: 500_000)],
            untouched: [.init(url: url("u.pdf"), bytes: 100_000)],
            failures: [.init(url: url("f.pdf"), reason: .encrypted)]
        )
        #expect(messages(report, .optimizePDF).map(\.title) == ["o.pdf", "u.pdf já está ok", "PDF protegido por senha"])
    }
}

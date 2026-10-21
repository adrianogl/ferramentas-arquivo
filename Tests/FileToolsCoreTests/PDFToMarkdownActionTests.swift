import Foundation
import Testing
@testable import FileToolsCore

@Suite struct PDFToMarkdownActionTests {
    @Test func actionWritesFile() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.richPDF(), named: "nota.pdf", in: d)
        let r = PDFToMarkdownAction(ocr: { _ in ["TOTAL 123"] }).run([pdf], limit: .megabytes(1))
        #expect(r.failures.isEmpty)
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota.md")
        #expect(output.pageCount == 2)
        #expect(output.ocrPageCount == 1)
        #expect(output.sourceCount == 1)
        #expect(output.originalBytes == (try Data(contentsOf: pdf)).count)
        let data = try Data(contentsOf: output.url)
        #expect(output.finalBytes == data.count)
        #expect(String(decoding: data, as: UTF8.self).contains("# Relatório de Despesas\n"))
    }

    @Test func noTextAnywhere() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "ruido.pdf", in: d)
        let r = PDFToMarkdownAction(ocr: { _ in [] }).run([pdf], limit: .megabytes(1))
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: pdf, reason: .noText)])
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["ruido.pdf"])
    }

    @Test func eachPDFSeparately() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let a = try Fixtures.write(Fixtures.textPDF(["a"]), named: "a.pdf", in: d)
        let b = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "b.pdf", in: d)
        let c = try Fixtures.write(Fixtures.textPDF(["c"]), named: "c.pdf", in: d)
        let r = PDFToMarkdownAction(ocr: { _ in [] }).run([c, b, a], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["a.md", "c.md"])
        #expect(r.failures == [ActionReport.Failure(url: b, reason: .noText)])
    }
}

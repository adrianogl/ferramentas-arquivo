import Foundation
import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct MarkdownConverterTests {
    @Test func structure() throws {
        let r = MarkdownConverter.convert(try PDFReader.open(Fixtures.richPDF()), ocr: { _ in ["TOTAL 123"] })
        #expect(r.markdown.contains("# Relatório de Despesas\n"))
        #expect(r.markdown.contains("## Resumo\n"))
        #expect(r.markdown.contains("### Itens pagos\n"))
        #expect(r.markdown.contains("- Táxi\n- Hotel\n"))
        #expect(r.markdown.contains("1. Primeiro\n2. Segundo\n"))
        #expect(r.markdown.contains("[site](https://example.com)"))
        #expect(r.markdown.contains("TOTAL 123"))
        #expect(r.ocrPageCount == 1)
    }

    @Test func realOCR() throws {
        let doc = try PDFReader.open(Fixtures.scannedTextPDF("TOTAL 123"))
        #expect(OCRRecognizer.lines(in: doc.page(at: 0)!).joined(separator: " ").contains("TOTAL"))
    }
}

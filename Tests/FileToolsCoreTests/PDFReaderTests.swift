import Foundation
import Testing
@testable import FileToolsCore

@Suite struct PDFReaderTests {
    @Test func encryptedIsReported() {
        #expect(throws: ActionFailure.encrypted) { try PDFReader.open(Fixtures.encryptedPDF()) }
    }

    @Test func garbageIsUnreadable() {
        #expect(throws: ActionFailure.unreadable) { try PDFReader.open(Data("x".utf8)) }
    }

    @Test func opensFromURL() throws {
        let d = try Fixtures.tempDirectory()
        let u = try Fixtures.write(Fixtures.textPDF(["a", "b"]), named: "a.pdf", in: d)
        #expect(try PDFReader.open(u).pageCount == 2)
    }

    @Test func missingFileIsUnreadable() throws {
        let u = try Fixtures.tempDirectory().appending(path: "nao-existe.pdf")
        #expect(throws: ActionFailure.unreadable) { try PDFReader.open(u) }
    }

    @Test func rasterizerRendersPageAtDpi() throws {
        let doc = try PDFReader.open(Fixtures.textPDF(["a"]))
        let img = try #require(PageRasterizer.render(doc.page(at: 0)!, dpi: 144))
        #expect(img.width == 1190 && img.height == 1684)
    }
}

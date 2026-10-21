import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct ScannedPageDetectorTests {
    @Test func detector() throws {
        #expect(!ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.textPDF(["x"])).page(at: 0)!))
        #expect(ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.scannedPDF(pages: 1)).page(at: 0)!))
        #expect(!ScannedPageDetector.isScanned(try PDFReader.open(Fixtures.logoPDF()).page(at: 0)!))
    }
}

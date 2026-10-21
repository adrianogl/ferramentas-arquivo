import Foundation
import Testing
@testable import FileToolsCore

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

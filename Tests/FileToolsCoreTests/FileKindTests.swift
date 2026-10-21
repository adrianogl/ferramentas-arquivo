import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import FileToolsCore

@Suite struct FileKindTests {
    @Test func textFileIsUnsupported() throws {
        let d = try Fixtures.tempDirectory()
        let txt = d.appending(path: "x.txt")
        try Data("x".utf8).write(to: txt)
        #expect(FileKind.of(txt) == .unsupported)
    }

    @Test func folderIsUnsupported() throws {
        #expect(FileKind.of(try Fixtures.tempDirectory()) == .unsupported)
    }

    @Test func pdfIsPDF() throws {
        let d = try Fixtures.tempDirectory()
        let u = try Fixtures.write(Fixtures.textPDF(["a"]), named: "a.pdf", in: d)
        #expect(FileKind.of(u) == .pdf)
    }

    @Test func pngIsImage() throws {
        let d = try Fixtures.tempDirectory()
        let u = d.appending(path: "a.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 10, height: 10), to: u, type: .png)
        #expect(FileKind.of(u) == .image)
    }

    @Test func heicIsImage() throws {
        let supported = (CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? []
        try #require(supported.contains("public.heic"), "este macOS não grava HEIC")
        let d = try Fixtures.tempDirectory()
        let u = d.appending(path: "a.heic")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 64, height: 64), to: u, type: .heic)
        #expect(FileKind.of(u) == .image)
    }
}

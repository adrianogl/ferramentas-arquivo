import Foundation
import PDFKit
import Testing
import UniformTypeIdentifiers
@testable import FileToolsCore

@Suite struct MergePDFsActionTests {
    private func fileCount(_ directory: URL) throws -> Int {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).count
    }

    @Test func naturalOrderWithImages() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let a10 = try Fixtures.write(Fixtures.textPDF(["dez"]), named: "a_10.pdf", in: d)
        let a2 = try Fixtures.write(Fixtures.textPDF(["dois"]), named: "a_2.pdf", in: d)
        let b = d.appending(path: "b.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 300, height: 200), to: b, type: .png)
        let r = MergePDFsAction().run([a10, b, a2], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["a_2-juntado.pdf"])
        let doc = try PDFReader.open(r.outputs[0].url)
        #expect(doc.pageCount == 3)
        #expect(doc.page(at: 0)!.string!.contains("dois"))
        #expect(doc.page(at: 1)!.string!.contains("dez"))
        #expect(r.outputs[0].sourceCount == 3)
        #expect(r.outputs[0].pageCount == 3)
        let sizes = try [a10, a2, b].map { try Data(contentsOf: $0).count }
        #expect(r.outputs[0].originalBytes == sizes.reduce(0, +))
        #expect(r.outputs[0].finalBytes == (try Data(contentsOf: r.outputs[0].url)).count)
    }

    @Test func compressesWhenOverLimit() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let first = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "um.pdf", in: d)
        let second = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "dois.pdf", in: d)
        let r = MergePDFsAction().run([first, second], limit: .megabytes(1))
        #expect(r.outputs.count == 1)
        #expect(r.outputs[0].finalBytes < 1_000_000)
        #expect(r.outputs[0].pageCount == 2)
    }

    @Test func abortsOnEncrypted() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let good = try Fixtures.write(Fixtures.textPDF(["ok"]), named: "boa.pdf", in: d)
        let locked = try Fixtures.write(Fixtures.encryptedPDF(), named: "senha.pdf", in: d)
        let r = MergePDFsAction().run([good, locked], limit: .megabytes(1))
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: locked, reason: .encrypted)])
        #expect(try fileCount(d) == 2)
    }

    @Test func unreachableWritesNothing() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let first = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "a.pdf", in: d)
        let second = try Fixtures.write(Fixtures.scannedPDF(pages: 1), named: "b.pdf", in: d)
        let r = MergePDFsAction().run([second, first], limit: SizeLimit(bytes: 5_000))
        guard case .unreachable = r.failures.first?.reason else {
            Issue.record("esperava .unreachable")
            return
        }
        #expect(r.failures[0].url == first)
        #expect(r.outputs.isEmpty)
        #expect(try fileCount(d) == 2)
    }
}

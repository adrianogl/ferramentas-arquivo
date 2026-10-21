import Foundation
import PDFKit
import Testing
import UniformTypeIdentifiers
@testable import FileToolsCore

@Suite struct ImagesToPDFActionTests {
    private func pdfCount(_ directory: URL) throws -> Int {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".pdf") }.count
    }

    @Test func onePDFInNaturalOrder() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let p2 = d.appending(path: "IMG_2.png"), p10 = d.appending(path: "IMG_10.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 200, height: 400), to: p2, type: .png)
        try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: p10, type: .png)
        let r = ImagesToPDFAction().run([p10, p2], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["IMG_2.pdf"])
        #expect(r.outputs[0].sourceCount == 2)
        #expect(r.outputs[0].pageCount == 2)
        let doc = try PDFReader.open(r.outputs[0].url)
        #expect(doc.pageCount == 2)
        let b0 = doc.page(at: 0)!.bounds(for: .cropBox), b1 = doc.page(at: 1)!.bounds(for: .cropBox)
        #expect(b0.height > b0.width)
        #expect(b1.width > b1.height)
        #expect(abs(max(b0.width, b0.height) - 842) < 0.5)
    }

    @Test func respectsExif() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let photo = d.appending(path: "foto.jpg")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: photo, type: .jpeg, orientation: 6)
        let r = ImagesToPDFAction().run([photo], limit: .megabytes(1))
        let doc = try PDFReader.open(r.outputs[0].url)
        let bounds = doc.page(at: 0)!.bounds(for: .cropBox)
        #expect(bounds.height > bounds.width)
    }

    @Test func bigPhotosFitLimit() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        var urls: [URL] = []
        for index in 1...3 {
            let url = d.appending(path: "foto\(index).png")
            try Fixtures.writeImage(
                Fixtures.noiseImage(width: 4032, height: 3024, seed: UInt64(index)), to: url, type: .png
            )
            urls.append(url)
        }
        let r = ImagesToPDFAction().run(urls, limit: .megabytes(1))
        #expect(r.outputs.count == 1)
        #expect(r.outputs[0].finalBytes < 1_000_000)
        #expect(r.outputs[0].sourceCount == 3)
        let sizes = try urls.map { try Data(contentsOf: $0).count }
        #expect(r.outputs[0].originalBytes == sizes.reduce(0, +))
    }

    @Test func abortsWhenOneFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let good = d.appending(path: "boa.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 50, height: 50), to: good, type: .png)
        let broken = try Fixtures.write(Data("x".utf8), named: "quebrada.png", in: d)
        let r = ImagesToPDFAction().run([good, broken], limit: .megabytes(1))
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: broken, reason: .unreadable)])
        #expect(try pdfCount(d) == 0)
    }

    @Test func unreachableWritesNothing() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let first = d.appending(path: "a.png"), second = d.appending(path: "b.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 800, height: 600), to: first, type: .png)
        try Fixtures.writeImage(Fixtures.noiseImage(width: 800, height: 600, seed: 2), to: second, type: .png)
        let r = ImagesToPDFAction().run([second, first], limit: SizeLimit(bytes: 5_000))
        guard case .unreachable = r.failures.first?.reason else {
            Issue.record("esperava .unreachable")
            return
        }
        #expect(r.failures[0].url == first)
        #expect(r.outputs.isEmpty)
        #expect(try pdfCount(d) == 0)
    }
}

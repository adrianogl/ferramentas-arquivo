import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import FileToolsCore

@Suite struct PDFToJPGActionTests {
    @Test func singlePage() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.textPDF(["a"]), named: "nota.pdf", in: d)
        let r = PDFToJPGAction().run([pdf], limit: .megabytes(1))
        #expect(r.failures.isEmpty)
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota.jpg")
        #expect(output.isFolder == false)
        #expect(output.pageCount == 1)
        #expect(output.sourceCount == 1)
        #expect(output.originalBytes == (try Data(contentsOf: pdf)).count)
        #expect(output.finalBytes == (try Data(contentsOf: output.url)).count)
        let image = try ImageLoader.load(output.url)
        #expect(abs(image.width - 1240) <= 1)
        #expect(abs(image.height - 1754) <= 1)
    }

    @Test func manyPages() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.textPDF(["a", "b", "c"]), named: "nota.pdf", in: d)
        let r = PDFToJPGAction().run([pdf], limit: .megabytes(1))
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota-paginas")
        #expect(output.isFolder)
        #expect(output.pageCount == 3)
        let names = try FileManager.default.contentsOfDirectory(atPath: output.url.path).sorted()
        #expect(names == ["nota-01.jpg", "nota-02.jpg", "nota-03.jpg"])
        let total = try names.reduce(0) { $0 + (try Data(contentsOf: output.url.appending(path: $1))).count }
        #expect(output.finalBytes == total)
    }

    @Test func eachPDFSeparately() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let a = try Fixtures.write(Fixtures.textPDF(["a"]), named: "a.pdf", in: d)
        let b = try Fixtures.write(Fixtures.textPDF(["b"]), named: "b.pdf", in: d)
        let r = PDFToJPGAction().run([a, b], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["a.jpg", "b.jpg"])
    }

    @Test func encryptedFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let locked = try Fixtures.write(Fixtures.encryptedPDF(), named: "senha.pdf", in: d)
        let r = PDFToJPGAction().run([locked], limit: .megabytes(1))
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: locked, reason: .encrypted)])
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["senha.pdf"])
    }
}

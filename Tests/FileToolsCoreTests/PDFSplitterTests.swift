import Foundation
import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct PDFSplitterTests {
    @Test func splitsAll() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.textPDF(["um", "dois", "tres"]), named: "nota.pdf", in: d)
        let r = PDFSplitter.split(pdf, mode: .allPages)
        #expect(r.failures.isEmpty)
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota-paginas")
        #expect(output.isFolder)
        #expect(output.pageCount == 3)
        #expect(output.sourceCount == 1)
        #expect(output.originalBytes == (try Data(contentsOf: pdf)).count)
        let names = try FileManager.default.contentsOfDirectory(atPath: output.url.path).sorted()
        #expect(names == ["nota-01.pdf", "nota-02.pdf", "nota-03.pdf"])
        let total = try names.reduce(0) { $0 + (try Data(contentsOf: output.url.appending(path: $1))).count }
        #expect(output.finalBytes == total)
        for (name, text) in zip(names, ["um", "dois", "tres"]) {
            let doc = try PDFReader.open(output.url.appending(path: name))
            #expect(doc.pageCount == 1)
            #expect(doc.page(at: 0)!.string!.contains(text))
        }
    }

    @Test func extractsInTypedOrder() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.textPDF(["um", "dois", "tres"]), named: "nota.pdf", in: d)
        let r = PDFSplitter.split(pdf, mode: .extract([3, 1]))
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota-extraido.pdf")
        #expect(output.isFolder == false)
        #expect(output.pageCount == 2)
        #expect(output.finalBytes == (try Data(contentsOf: output.url)).count)
        let doc = try PDFReader.open(output.url)
        #expect(doc.pageCount == 2)
        #expect(doc.page(at: 0)!.string!.contains("tres"))
        #expect(doc.page(at: 1)!.string!.contains("um"))
    }

    @Test func encryptedFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let locked = try Fixtures.write(Fixtures.encryptedPDF(), named: "senha.pdf", in: d)
        let r = PDFSplitter.split(locked, mode: .allPages)
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: locked, reason: .encrypted)])
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["senha.pdf"])
    }

    @Test func extractWithPageOutsideDocumentFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.textPDF(["um"]), named: "nota.pdf", in: d)
        let r = PDFSplitter.split(pdf, mode: .extract([2]))
        #expect(r.outputs.isEmpty)
        #expect(r.failures == [ActionReport.Failure(url: pdf, reason: .unreadable)])
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["nota.pdf"])
    }

    @Test func zeroPagePDFFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let pdf = try Fixtures.write(Fixtures.zeroPagePDF(), named: "vazio.pdf", in: d)
        for mode in [SplitMode.extract([1]), .allPages] {
            let r = PDFSplitter.split(pdf, mode: mode)
            #expect(r.outputs.isEmpty)
            #expect(r.failures == [ActionReport.Failure(url: pdf, reason: .unreadable)])
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["vazio.pdf"])
    }
}

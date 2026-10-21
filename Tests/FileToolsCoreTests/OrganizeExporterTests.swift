import Foundation
import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct OrganizeExporterTests {
    @Test func exportApplies() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let url = try Fixtures.write(Fixtures.textPDF(["um", "dois", "três"]), named: "nota.pdf", in: d)
        var m = try OrganizeModel(pdf: url)
        let ids = m.pages.map(\.id)
        m.delete([ids[1]])
        m.rotate([ids[2]], by: 90)
        m.move([ids[2]], to: 0)
        let r = OrganizeExporter.export(m, original: url)
        #expect(r.failures.isEmpty)
        #expect(r.outputs.count == 1)
        let output = r.outputs[0]
        #expect(output.url.lastPathComponent == "nota-organizado.pdf")
        #expect(output.pageCount == 2)
        #expect(output.sourceCount == 1)
        #expect(output.originalBytes == (try Data(contentsOf: url)).count)
        #expect(output.finalBytes == (try Data(contentsOf: output.url)).count)
        let doc = try PDFReader.open(output.url)
        #expect(doc.pageCount == 2)
        #expect(doc.page(at: 0)!.string!.contains("três"))
        #expect(doc.page(at: 0)!.rotation == 90)
        #expect(doc.page(at: 1)!.string!.contains("um"))
        #expect(doc.page(at: 1)!.rotation == 0)
    }

    @Test func exportsAppendedPDFAndImage() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let url = try Fixtures.write(Fixtures.textPDF(["um"]), named: "nota.pdf", in: d)
        let other = try Fixtures.write(Fixtures.textPDF(["x", "y"]), named: "outro.pdf", in: d)
        let photo = d.appending(path: "foto.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 80, height: 40), to: photo, type: .png)
        var m = try OrganizeModel(pdf: url)
        try m.append(other)
        try m.append(photo)
        m.rotate([m.pages[3].id], by: 90)
        let r = OrganizeExporter.export(m, original: url)
        #expect(r.failures.isEmpty)
        let doc = try PDFReader.open(r.outputs[0].url)
        #expect(doc.pageCount == 4)
        #expect(doc.page(at: 1)!.string!.contains("x"))
        #expect(doc.page(at: 2)!.string!.contains("y"))
        #expect(doc.page(at: 3)!.rotation == 0)
        let size = doc.page(at: 3)!.bounds(for: .cropBox).size
        #expect(size.height > size.width)
    }

    @Test func emptyModelFails() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let url = try Fixtures.write(Fixtures.textPDF(["um"]), named: "nota.pdf", in: d)
        var m = try OrganizeModel(pdf: url)
        m.delete(Set(m.pages.map(\.id)))
        let r = OrganizeExporter.export(m, original: url)
        #expect(r.outputs.isEmpty)
        #expect(r.failures.count == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: d.path) == ["nota.pdf"])
    }
}

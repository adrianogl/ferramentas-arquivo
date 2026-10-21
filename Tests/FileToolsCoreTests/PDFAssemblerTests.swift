import CoreGraphics
import Foundation
import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct PDFAssemblerTests {
    @Test func jpegPassesThroughIntoPDF() throws {
        let img = Fixtures.noiseImage(width: 1000, height: 1000)
        let jpegData = try JPEGEncoder.encode(img, quality: 0.6)
        let pdf = try PDFAssembler.assemble([
            .image(try JPEGEncoder.jpegBackedImage(img, quality: 0.6), pageSize: CGSize(width: 595, height: 595))
        ])
        #expect(pdf.count < jpegData.count + 20_000)
    }

    @Test func imagePageLongSideIs842() {
        let s = PDFAssembler.imagePageSize(for: Fixtures.noiseImage(width: 4032, height: 3024))
        #expect(abs(s.width - 842) < 0.5)
        #expect(abs(s.height - 631.5) < 0.5)
    }

    @Test func extraRotationSwapsPageSize() throws {
        let doc = try PDFReader.open(Fixtures.textPDF(["a"]))
        let out = try PDFReader.open(PDFAssembler.assemble([.vector(doc.page(at: 0)!, extraRotation: 90)]))
        let b = out.page(at: 0)!.bounds(for: .cropBox)
        let rotated = out.page(at: 0)!.rotation % 180 != 0
        #expect((rotated ? b.height : b.width) > (rotated ? b.width : b.height))
        #expect(out.page(at: 0)!.string?.contains("a") == true)
    }

    @Test func vectorPagesKeepOrderAndText() throws {
        let doc = try PDFReader.open(Fixtures.textPDF(["primeira", "segunda"]))
        let out = try PDFReader.open(PDFAssembler.assemble([
            .vector(doc.page(at: 1)!, extraRotation: 0), .vector(doc.page(at: 0)!, extraRotation: 0),
        ]))
        #expect(out.pageCount == 2)
        #expect(out.page(at: 0)!.string?.contains("segunda") == true)
        #expect(out.page(at: 1)!.string?.contains("primeira") == true)
    }

    @Test func imageRotationSwapsPageSize() throws {
        let img = Fixtures.noiseImage(width: 40, height: 20)
        let out = try PDFReader.open(PDFAssembler.assemble([
            .image(img, pageSize: CGSize(width: 400, height: 200), rotation: 90)
        ]))
        let page = try #require(out.page(at: 0))
        let b = page.bounds(for: .cropBox)
        #expect(b.width == 200 && b.height == 400)
    }
}

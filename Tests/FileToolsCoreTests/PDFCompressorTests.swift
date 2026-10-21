import Foundation
import PDFKit
import Testing
@testable import FileToolsCore

@Suite struct PDFCompressorTests {
    @Test func smallFileIsUntouched() throws {
        let d = Fixtures.textPDF(["Reembolso"])
        #expect(try PDFCompressor().compress(d, limit: .megabytes(1)) == .alreadyUnderLimit(bytes: d.count))
    }

    @Test func scannedFallsUnderOneMegabyte() throws {
        let d = Fixtures.scannedPDF(pages: 2)
        try #require(d.count > 1_000_000)
        guard case let .compressed(out, original, _) = try PDFCompressor().compress(d, limit: .megabytes(1)) else {
            Issue.record()
            return
        }
        #expect(out.count < 1_000_000)
        #expect(original == d.count)
        #expect(try PDFReader.open(out).pageCount == 2)
    }

    @Test func stopsAtMostLegibleFittingStep() throws {
        let d = Fixtures.scannedPDF(pages: 1)
        guard case let .compressed(_, _, step) = try PDFCompressor().compress(d, limit: SizeLimit(bytes: d.count - 1))
        else {
            Issue.record()
            return
        }
        #expect(step == CompressionStep(mode: .scannedPagesOnly, quality: Constants.rasterLadder[0]))
    }

    @Test func keepsTextPagesSelectable() throws {
        let d = try merge(Fixtures.textPDF(["Reembolso de despesas"]), Fixtures.scannedPDF(pages: 1))
        guard case let .compressed(out, _, step) = try PDFCompressor().compress(d, limit: .megabytes(1)) else {
            Issue.record()
            return
        }
        #expect(step.mode == .scannedPagesOnly)
        #expect(try PDFReader.open(out).page(at: 0)?.string?.contains("Reembolso") == true)
    }

    @Test func reportsUnreachableWithSmallestSize() throws {
        let d = Fixtures.scannedPDF(pages: 1)
        guard case let .unreachable(smallest) = try PDFCompressor().compress(d, limit: SizeLimit(bytes: 5_000)) else {
            Issue.record()
            return
        }
        #expect(smallest > 5_000)
        #expect(smallest < d.count)
    }

    @Test func unreachableReportsAssembledFloorSize() throws {
        let d = Fixtures.scannedPDF(pages: 12)
        let floor = try #require(Constants.rasterLadder.last)
        let floorOnly = try PDFCompressor(ladder: [floor]).compress(d, limit: SizeLimit(bytes: 1))
        guard case let .unreachable(floorBytes) = floorOnly,
              case let .unreachable(smallest) = try PDFCompressor().compress(d, limit: .megabytes(1))
        else {
            Issue.record()
            return
        }
        #expect(smallest == floorBytes)
        #expect(smallest > 1_500_000)
    }

    @Test func largeDocumentCompletes() throws {
        let d = Fixtures.scannedPDF(pages: 30, pixelWidth: 827, pixelHeight: 1169)
        guard case let .compressed(out, _, _) = try PDFCompressor().compress(d, limit: .megabytes(5)) else {
            Issue.record()
            return
        }
        #expect(try PDFReader.open(out).pageCount == 30)
    }

    @Test func encryptedThrows() {
        #expect(throws: ActionFailure.encrypted) {
            try PDFCompressor().compress(Fixtures.encryptedPDF(), limit: .megabytes(1))
        }
    }

    private func merge(_ first: Data, _ second: Data) throws -> Data {
        let a = try PDFReader.open(first)
        let b = try PDFReader.open(second)
        let pages = [a, b].flatMap { doc in
            (0..<doc.pageCount).compactMap { doc.page(at: $0) }.map { PDFPageSource.vector($0) }
        }
        return try withExtendedLifetime((a, b)) { try PDFAssembler.assemble(pages) }
    }
}

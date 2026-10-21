import CoreGraphics
import Foundation
import PDFKit

public struct PDFCompressor: Sendable {
    private let ladder: [RasterQuality]

    public init(ladder: [RasterQuality] = Constants.rasterLadder) {
        self.ladder = ladder
    }

    public func compress(_ data: Data, limit: SizeLimit) throws(ActionFailure) -> CompressionOutcome {
        let document = try PDFReader.open(data)
        if limit.accepts(byteCount: data.count) { return .alreadyUnderLimit(bytes: data.count) }
        let pages = (0..<document.pageCount).compactMap { document.page(at: $0) }
        guard pages.count == document.pageCount else { throw .unreadable }
        let scanned = Set(pages.indices.filter { ScannedPageDetector.isScanned(pages[$0]) })
        var smallest = Int.max
        for step in steps(scannedCount: scanned.count, pageCount: pages.count) {
            let targets = step.mode == .allPages ? Set(pages.indices) : scanned
            let raster = try rasterize(pages, targets: targets, quality: step.quality, budget: limit.bytes)
            guard let sources = raster.sources else {
                smallest = min(smallest, raster.jpegBytes)
                continue
            }
            let output = try withExtendedLifetime(document) { () throws(ActionFailure) -> Data in
                try PDFAssembler.assemble(sources)
            }
            smallest = min(smallest, output.count)
            if limit.accepts(byteCount: output.count) {
                return .compressed(data: output, originalBytes: data.count, step: step)
            }
        }
        return .unreachable(smallestBytes: smallest)
    }

    private func steps(scannedCount: Int, pageCount: Int) -> [CompressionStep] {
        var steps: [CompressionStep] = []
        if scannedCount > 0 {
            steps += ladder.map { CompressionStep(mode: .scannedPagesOnly, quality: $0) }
        }
        if scannedCount < pageCount {
            steps += ladder.map { CompressionStep(mode: .allPages, quality: $0) }
        }
        return steps
    }

    private func rasterize(
        _ pages: [PDFPage], targets: Set<Int>, quality: RasterQuality, budget: Int
    ) throws(ActionFailure) -> (sources: [PDFPageSource]?, jpegBytes: Int) {
        var sources: [PDFPageSource] = []
        var jpegBytes = 0
        for (index, page) in pages.enumerated() {
            guard targets.contains(index) else {
                sources.append(.vector(page))
                continue
            }
            let result = autoreleasepool { () -> Result<(CGImage, Int), ActionFailure> in
                Result { () throws(ActionFailure) -> (CGImage, Int) in
                    guard let bitmap = PageRasterizer.render(page, dpi: quality.dpi) else { throw .unreadable }
                    let jpeg = try JPEGEncoder.encode(bitmap, quality: quality.jpegQuality)
                    return (try JPEGEncoder.image(fromJPEG: jpeg), jpeg.count)
                }
            }
            let (image, byteCount) = try result.get()
            jpegBytes += byteCount
            if jpegBytes > budget { return (nil, jpegBytes) }
            sources.append(.image(image, pageSize: PDFPageGeometry.displaySize(of: page)))
        }
        return (sources, jpegBytes)
    }
}

import CoreGraphics
import Foundation

enum ImagePageSource {
    static func make(_ url: URL, quality: RasterQuality) throws(ActionFailure) -> PDFPageSource {
        let maxPixelSize = Int(Constants.imagePageLongSide * quality.dpi / 72)
        let loaded = try ImageLoader.load(url, maxPixelSize: maxPixelSize)
        let backed = try JPEGEncoder.jpegBackedImage(loaded, quality: quality.jpegQuality)
        return .image(backed, pageSize: PDFAssembler.imagePageSize(for: backed))
    }

    static func fileSize(_ url: URL) throws(ActionFailure) -> Int {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { throw .unreadable }
        return size
    }
}

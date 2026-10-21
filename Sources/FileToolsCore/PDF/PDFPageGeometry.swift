import CoreGraphics
import PDFKit

enum PDFPageGeometry {
    static func displaySize(of page: PDFPage, extraRotation: Int = 0) -> CGSize {
        let bounds = page.bounds(for: .cropBox)
        let quarterTurn = (page.rotation + extraRotation) % 180 != 0
        return quarterTurn ? CGSize(width: bounds.height, height: bounds.width) : bounds.size
    }
}

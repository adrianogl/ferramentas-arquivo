import CoreGraphics
import PDFKit

public enum PDFPageSource {
    case vector(PDFPage, extraRotation: Int = 0)
    case image(CGImage, pageSize: CGSize, rotation: Int = 0)
}

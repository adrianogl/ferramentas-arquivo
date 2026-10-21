import CoreGraphics
import Foundation
import PDFKit

public enum PageRasterizer {
    public static func render(_ page: PDFPage, dpi: Double) -> CGImage? {
        let size = PDFPageGeometry.displaySize(of: page)
        let scale = dpi / 72
        let width = Int((size.width * scale).rounded())
        let height = Int((size.height * scale).rounded())
        guard width > 0, height > 0,
              let ctx = CGContext(
                  data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return nil }
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.scaleBy(x: scale, y: scale)
        page.transform(ctx, for: .cropBox)
        page.draw(with: .cropBox, to: ctx)
        return ctx.makeImage()
    }
}

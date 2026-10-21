import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum JPEGEncoder {
    public static func encode(_ image: CGImage, quality: Double) throws(ActionFailure) -> Data {
        guard let flattened = flattenOnWhite(image) else { throw .writeFailed }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw .writeFailed
        }
        let options = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, flattened, options)
        guard CGImageDestinationFinalize(destination) else { throw .writeFailed }
        return data as Data
    }

    public static func jpegBackedImage(_ image: CGImage, quality: Double) throws(ActionFailure) -> CGImage {
        let data = try encode(image, quality: quality)
        // Imagem lida direto do JPEG: o contexto PDF embute os bytes sem recodificar (DCT passthrough).
        guard let provider = CGDataProvider(data: data as CFData),
              let backed = CGImage(
                  jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
              )
        else { throw .writeFailed }
        return backed
    }

    private static func flattenOnWhite(_ image: CGImage) -> CGImage? {
        guard let ctx = CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(rect)
        ctx.draw(image, in: rect)
        return ctx.makeImage()
    }
}

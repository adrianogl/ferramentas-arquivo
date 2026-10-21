import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum Fixtures {
    static let a4 = CGRect(x: 0, y: 0, width: 595, height: 842)

    static func tempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func noiseImage(width: Int, height: Int, alpha: UInt8 = 255, seed: UInt64 = 1) -> CGImage {
        var rng = SplitMix64(state: seed)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<(width * height) {
            let r = rng.next()
            let a = Int(alpha)
            bytes[i * 4] = UInt8((Int(r & 0xFF) * a) / 255)
            bytes[i * 4 + 1] = UInt8((Int((r >> 8) & 0xFF) * a) / 255)
            bytes[i * 4 + 2] = UInt8((Int((r >> 16) & 0xFF) * a) / 255)
            bytes[i * 4 + 3] = alpha
        }
        return image(from: bytes, width: width, height: height)
    }

    static func transparentImage(width: Int, height: Int) -> CGImage {
        image(from: [UInt8](repeating: 0, count: width * height * 4), width: width, height: height)
    }

    static func textImage(_ text: String, width: Int, height: Int, pointSize: CGFloat) -> CGImage {
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        drawText(text, in: ctx, at: CGPoint(x: 10, y: CGFloat(height) / 2), pointSize: pointSize)
        return ctx.makeImage()!
    }

    static func scannedPDF(pages: Int, pixelWidth: Int = 1240, pixelHeight: Int = 1754) -> Data {
        pdf(pageCount: pages) { ctx, index in
            let bitmap = noiseImage(width: pixelWidth, height: pixelHeight, seed: UInt64(index + 1))
            ctx.draw(bitmap, in: a4)
        }
    }

    static func textPDF(_ pages: [String]) -> Data {
        pdf(pageCount: pages.count) { ctx, index in
            drawText(pages[index], in: ctx, at: CGPoint(x: 72, y: 700), pointSize: 12)
        }
    }

    static func logoPDF() -> Data {
        pdf(pageCount: 1) { ctx, _ in
            drawText("Documento com logo", in: ctx, at: CGPoint(x: 72, y: 700), pointSize: 12)
            ctx.draw(noiseImage(width: 300, height: 100, seed: 7), in: CGRect(x: 72, y: 560, width: 300, height: 100))
        }
    }

    static func encryptedPDF() -> Data {
        let options: [CFString: Any] = [
            kCGPDFContextUserPassword: "senha",
            kCGPDFContextOwnerPassword: "dono",
        ]
        return pdf(pageCount: 1, options: options) { ctx, _ in
            drawText("secreto", in: ctx, at: CGPoint(x: 72, y: 700), pointSize: 12)
        }
    }

    static func writeImage(_ image: CGImage, to url: URL, type: UTType, orientation: Int = 1) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }

    @discardableResult
    static func write(_ data: Data, named name: String, in directory: URL) throws -> URL {
        let url = directory.appending(path: name)
        try data.write(to: url)
        return url
    }

    private static func image(from bytes: [UInt8], width: Int, height: Int) -> CGImage {
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
    }

    private static func drawText(_ text: String, in ctx: CGContext, at point: CGPoint, pointSize: CGFloat) {
        let font = CTFontCreateWithName("Helvetica" as CFString, pointSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.textPosition = point
        CTLineDraw(line, ctx)
    }

    private static func pdf(
        pageCount: Int, options: [CFString: Any] = [:], draw: (CGContext, Int) -> Void
    ) -> Data {
        let data = NSMutableData()
        var box = a4
        let ctx = CGContext(consumer: CGDataConsumer(data: data)!, mediaBox: &box, options as CFDictionary)!
        for index in 0..<pageCount {
            ctx.beginPDFPage(nil)
            draw(ctx, index)
            ctx.endPDFPage()
        }
        ctx.closePDF()
        return data as Data
    }
}

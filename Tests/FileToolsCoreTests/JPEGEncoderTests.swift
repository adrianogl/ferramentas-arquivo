import CoreGraphics
import Foundation
import Testing
@testable import FileToolsCore

@Suite struct JPEGEncoderTests {
    struct Pixel { let r: UInt8, g: UInt8, b: UInt8 }

    func pixel(_ image: CGImage, x: Int, y: Int) -> Pixel? {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { return nil }
        let i = (y * image.width + x) * 4
        return Pixel(r: bytes[i], g: bytes[i + 1], b: bytes[i + 2])
    }

    @Test func transparentBecomesWhite() throws {
        let jpeg = try JPEGEncoder.jpegBackedImage(Fixtures.transparentImage(width: 100, height: 100), quality: 0.8)
        let px = try #require(pixel(jpeg, x: 50, y: 50))
        #expect(px.r >= 250 && px.g >= 250 && px.b >= 250)
    }

    @Test func encodeProducesJPEGData() throws {
        let data = try JPEGEncoder.encode(Fixtures.noiseImage(width: 64, height: 64), quality: 0.7)
        #expect(Array(data.prefix(3)) == [0xFF, 0xD8, 0xFF])
    }

    @Test func lowerQualityIsSmaller() throws {
        let img = Fixtures.noiseImage(width: 300, height: 300)
        let high = try JPEGEncoder.encode(img, quality: 0.9)
        let low = try JPEGEncoder.encode(img, quality: 0.3)
        #expect(low.count < high.count)
    }
}

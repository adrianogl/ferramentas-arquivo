import CoreGraphics
import Foundation

enum Constants {
    static let bytesPerMegabyte = 1_000_000.0
    static let defaultLimitMegabytes = 1.0
    static let limitMegabytesRange = 0.1...100.0
    static let minimumPageNumberWidth = 2
    static let imagePageLongSide: CGFloat = 842
    static let jpgExportQuality = RasterQuality(dpi: 150, jpegQuality: 0.85)
    static let rasterLadder = [
        RasterQuality(dpi: 200, jpegQuality: 0.80),
        RasterQuality(dpi: 150, jpegQuality: 0.70),
        RasterQuality(dpi: 150, jpegQuality: 0.55),
        RasterQuality(dpi: 120, jpegQuality: 0.50),
        RasterQuality(dpi: 100, jpegQuality: 0.45),
    ]

    enum Suffix {
        static let optimized = "-otimizado"
        static let merged = "-juntado"
        static let extracted = "-extraido"
        static let organized = "-organizado"
        static let pagesFolder = "-paginas"
    }

    enum SettingsKey {
        static let limitMegabytes = "limitMegabytes"
        static let triggerModifier = "triggerModifier"
        static let launchAtLogin = "launchAtLogin"
    }
}

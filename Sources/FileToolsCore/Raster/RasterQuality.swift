public struct RasterQuality: Sendable, Equatable {
    public let dpi: Double
    public let jpegQuality: Double

    public init(dpi: Double, jpegQuality: Double) {
        self.dpi = dpi
        self.jpegQuality = jpegQuality
    }
}

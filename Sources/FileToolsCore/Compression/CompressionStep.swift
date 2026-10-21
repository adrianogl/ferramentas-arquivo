public struct CompressionStep: Sendable, Equatable {
    public let mode: CompressionMode
    public let quality: RasterQuality

    public init(mode: CompressionMode, quality: RasterQuality) {
        self.mode = mode
        self.quality = quality
    }
}

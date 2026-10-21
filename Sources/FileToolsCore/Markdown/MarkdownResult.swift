public struct MarkdownResult: Sendable, Equatable {
    public let markdown: String
    public let ocrPageCount: Int

    public init(markdown: String, ocrPageCount: Int) {
        self.markdown = markdown
        self.ocrPageCount = ocrPageCount
    }
}

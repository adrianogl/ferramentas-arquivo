public struct TargetInfo: Sendable, Equatable {
    public let name: String
    public let bytes: Int
    public let pageCount: Int?
    public let kind: FileKind

    public init(name: String, bytes: Int, pageCount: Int?, kind: FileKind) {
        self.name = name
        self.bytes = bytes
        self.pageCount = pageCount
        self.kind = kind
    }
}

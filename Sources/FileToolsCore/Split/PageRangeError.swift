public enum PageRangeError: Error, Sendable, Equatable {
    case invalidSyntax
    case pageOutOfRange(page: Int, pageCount: Int)

    public var message: String {
        switch self {
        case .invalidSyntax:
            "Use números e intervalos, como 1-3, 5"
        case let .pageOutOfRange(page, pageCount):
            "Página \(page) não existe (o PDF tem \(pageCount))"
        }
    }
}

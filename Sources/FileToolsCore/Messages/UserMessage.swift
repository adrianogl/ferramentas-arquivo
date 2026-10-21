public struct UserMessage: Sendable, Equatable {
    public let title: String
    public let body: String
    public let isError: Bool

    public init(title: String, body: String, isError: Bool) {
        self.title = title
        self.body = body
        self.isError = isError
    }
}

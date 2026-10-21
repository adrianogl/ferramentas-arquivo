public enum ActionFailure: Error, Sendable, Equatable {
    case unreadable
    case encrypted
    case writeFailed
    case unreachable(smallestBytes: Int)
    case noText
}

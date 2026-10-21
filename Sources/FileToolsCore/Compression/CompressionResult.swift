import Foundation

public enum CompressionOutcome: Sendable, Equatable {
    case alreadyUnderLimit(bytes: Int)
    case compressed(data: Data, originalBytes: Int, step: CompressionStep)
    case unreachable(smallestBytes: Int)
}

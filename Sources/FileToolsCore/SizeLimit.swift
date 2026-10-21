import Foundation

public struct SizeLimit: Sendable, Equatable {
    public let bytes: Int

    public init(bytes: Int) {
        self.bytes = bytes
    }

    public static func megabytes(_ value: Double) -> SizeLimit {
        SizeLimit(bytes: Int((value * Constants.bytesPerMegabyte).rounded()))
    }

    public func accepts(byteCount: Int) -> Bool {
        byteCount < bytes
    }
}

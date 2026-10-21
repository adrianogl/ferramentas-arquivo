import Foundation

public struct SizeLimit: Sendable, Equatable {
    public let bytes: Int

    public init(bytes: Int) {
        self.bytes = bytes
    }

    public static func megabytes(_ value: Double) -> SizeLimit {
        let megabytes = value.isFinite ? value : Constants.defaultLimitMegabytes
        return SizeLimit(bytes: Int((megabytes * Constants.bytesPerMegabyte).rounded()))
    }

    public func accepts(byteCount: Int) -> Bool {
        byteCount < bytes
    }
}

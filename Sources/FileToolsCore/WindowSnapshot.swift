import CoreGraphics
import Foundation

public struct WindowSnapshot: Sendable, Equatable {
    public let ownerPID: Int32
    public let ownerName: String
    public let layer: Int
    public let alpha: Double
    public let bounds: CGRect

    public init(ownerPID: Int32, ownerName: String, layer: Int, alpha: Double, bounds: CGRect) {
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.layer = layer
        self.alpha = alpha
        self.bounds = bounds
    }

    public init?(info: [String: Any]) {
        guard let pid = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
              let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue,
              let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsDictionary)
        else { return nil }
        self.init(
            ownerPID: pid,
            ownerName: info[kCGWindowOwnerName as String] as? String ?? "",
            layer: layer,
            alpha: (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1,
            bounds: bounds
        )
    }
}

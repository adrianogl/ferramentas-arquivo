import Foundation

public struct OrganizePage: Identifiable, Sendable, Equatable {
    public enum Source: Sendable, Equatable {
        case pdf(URL, index: Int)
        case image(URL)
    }

    public let id: UUID
    public let source: Source
    public var rotation: Int

    public init(id: UUID = UUID(), source: Source, rotation: Int = 0) {
        self.id = id
        self.source = source
        self.rotation = rotation
    }
}

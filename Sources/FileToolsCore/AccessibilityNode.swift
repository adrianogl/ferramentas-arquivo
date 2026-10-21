public struct AccessibilityNode: Sendable, Equatable {
    public let role: String
    public let subrole: String
    public let identifier: String

    public init(role: String, subrole: String = "", identifier: String = "") {
        self.role = role
        self.subrole = subrole
        self.identifier = identifier
    }
}

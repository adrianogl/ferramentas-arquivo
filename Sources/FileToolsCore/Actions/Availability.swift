public enum Availability: Sendable, Equatable {
    case available
    case unavailable(reason: String)
}

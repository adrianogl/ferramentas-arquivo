public enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome, accessibility, finder, tryIt, done

    public static func first(accessibility: Bool, finder: Bool, completed: Bool) -> OnboardingStep? {
        if !completed { return .welcome }
        if !accessibility { return .accessibility }
        if !finder { return .finder }
        return nil
    }

    public func canContinue(accessibility: Bool, finder: Bool, triedIt: Bool) -> Bool {
        switch self {
        case .accessibility: accessibility
        case .finder: accessibility && finder
        case .tryIt: triedIt
        case .welcome, .done: true
        }
    }
}

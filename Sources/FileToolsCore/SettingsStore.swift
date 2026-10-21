import Foundation

@MainActor
public final class SettingsStore {
    public static let limitMegabytesRange = Constants.limitMegabytesRange

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var limitMegabytes: Double {
        get {
            guard let stored = defaults.object(forKey: Constants.SettingsKey.limitMegabytes) as? Double,
                  stored.isFinite
            else {
                return Constants.defaultLimitMegabytes
            }
            return Self.clamp(stored)
        }
        set {
            guard newValue.isFinite else { return }
            defaults.set(Self.clamp(newValue), forKey: Constants.SettingsKey.limitMegabytes)
        }
    }

    public var triggerModifier: TriggerModifier {
        get {
            defaults.string(forKey: Constants.SettingsKey.triggerModifier).flatMap(TriggerModifier.init(rawValue:)) ?? .option
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.SettingsKey.triggerModifier)
        }
    }

    public var launchAtLogin: Bool {
        get {
            defaults.object(forKey: Constants.SettingsKey.launchAtLogin) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: Constants.SettingsKey.launchAtLogin)
        }
    }

    public var onboardingCompleted: Bool {
        get {
            defaults.bool(forKey: Constants.SettingsKey.onboardingCompleted)
        }
        set {
            defaults.set(newValue, forKey: Constants.SettingsKey.onboardingCompleted)
        }
    }

    public var sizeLimit: SizeLimit {
        .megabytes(limitMegabytes)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, Constants.limitMegabytesRange.lowerBound), Constants.limitMegabytesRange.upperBound)
    }
}

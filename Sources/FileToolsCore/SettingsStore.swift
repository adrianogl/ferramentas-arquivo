import Foundation

@MainActor
public final class SettingsStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var limitMegabytes: Double {
        get {
            guard let stored = defaults.object(forKey: Constants.SettingsKey.limitMegabytes) as? Double else {
                return Constants.defaultLimitMegabytes
            }
            return Self.clamp(stored)
        }
        set {
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

    public var sizeLimit: SizeLimit {
        .megabytes(limitMegabytes)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, Constants.limitMegabytesRange.lowerBound), Constants.limitMegabytesRange.upperBound)
    }
}

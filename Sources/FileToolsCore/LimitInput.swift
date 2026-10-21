import Foundation

public enum LimitInput {
    public static let locale = Locale(identifier: Constants.limitInputLocaleIdentifier)

    public static func parse(_ text: String) -> Double? {
        try? Double(text.trimmingCharacters(in: .whitespaces), format: .number.locale(locale))
    }

    public static func liveValue(_ text: String) -> Double? {
        guard let value = parse(text), Constants.limitMegabytesRange.contains(value) else { return nil }
        return value
    }

    public static func normalize(_ text: String, previous: Double) -> Double {
        guard let value = parse(text) else { return previous }
        return min(max(value, Constants.limitMegabytesRange.lowerBound), Constants.limitMegabytesRange.upperBound)
    }

    public static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }
}

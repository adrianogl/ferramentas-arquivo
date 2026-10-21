import Foundation

enum AppConstants {
    static let accessibilityTrustPromptKey = "AXTrustedCheckOptionPrompt"
    static let finderBundleIdentifier = "com.apple.finder"
    static let syntheticEventMarker: Int64 = 0x4654_4150
    static let tapRetryInterval: TimeInterval = 2
    static let selectionSettleDelay: Duration = .milliseconds(150)
    static let maxAccessibilityAncestors = 8
}

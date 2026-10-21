import Foundation

enum AppConstants {
    static let accessibilityTrustPromptKey = "AXTrustedCheckOptionPrompt"
    static let finderBundleIdentifier = "com.apple.finder"
    static let syntheticEventMarker: Int64 = 0x4654_4150
    static let tapRetryInterval: TimeInterval = 2
    static let selectionSettleDelay: Duration = .milliseconds(150)
    static let maxAccessibilityAncestors = 8
    static let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    static let automationSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!

    enum Onboarding {
        static let windowSize = CGSize(width: 620, height: 440)
        static let permissionPollInterval: TimeInterval = 1
        static let sampleFolderName = "Ferramentas de Arquivo"
        static let sampleFileName = "exemplo.pdf"
        static let sampleText = "Faça ⌥ + clique direito neste arquivo"
        static let samplePageSize = CGSize(width: 595, height: 842)
        static let sampleFontSize: CGFloat = 28
        static let sampleTextInset: CGFloat = 60
    }

    enum Brand {
        static let navy: UInt32 = 0x0B1B33
        static let blue: UInt32 = 0x2F8CFF
        static let stepLabel: UInt32 = 0x1560C9
        static let secondaryText: UInt32 = 0x34507A
        static let lightGround: UInt32 = 0xF5F8FD
        static let border: UInt32 = 0xE1E8F3
        static let inactive: UInt32 = 0xC9D6EA
        static let keycap: UInt32 = 0xE8F1FF
        static let success: UInt32 = 0x15803D
        static let successText: UInt32 = 0x14532D
        static let successGround: UInt32 = 0xEAF7EF
        static let waiting: UInt32 = 0xB45309
        static let waitingText: UInt32 = 0x8A4A07
        static let pdfBadge: UInt32 = 0xE5484D
        static let optimize: UInt32 = 0xFF5A5F
    }
}

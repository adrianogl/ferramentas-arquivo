import Foundation

enum AppConstants {
    static let accessibilityTrustPromptKey = "AXTrustedCheckOptionPrompt"
    static let finderBundleIdentifier = "com.apple.finder"
    static let syntheticEventMarker: Int64 = 0x4654_4150
    static let tapRetryInterval: TimeInterval = 2
    static let selectionSettleDelay: Duration = .milliseconds(150)
    static let maxAccessibilityAncestors = 8
    static let hitTestMessagingTimeout: Float = 0.15
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

    enum Radial {
        static let panelSize: CGFloat = 300
        static let coreDiameter: CGFloat = 124
        static let iconSize: CGFloat = 30
        static let iconCornerRadius: CGFloat = 9
        static let iconSymbolSize: CGFloat = 14
        static let labelSize: CGFloat = 9.5
        static let titleSize: CGFloat = 12
        static let detailSize: CGFloat = 10
        static let detailOpacity = 0.62
        static let separatorOpacity = 0.12
        static let sliceFillOpacity = 0.16
        static let glowRadius: CGFloat = 6
        static let iconFillOpacity = 0.13
        static let iconBorderOpacity = 0.30
        static let iconRingOpacity = 0.20
        static let iconRingWidth: CGFloat = 4
        static let unavailableOpacity = 0.3
        static let vacancyOpacity = 0.5
        static let reasonColorHex = "#ff5a5f"
        static let coreTintLight = 0.55
        static let coreTintDark = 0.08
        static let coreBorderDark = 0.1
        static let coreShadowOpacity = 0.08
        static let coreShadowRadius: CGFloat = 7
        static let coreShadowOffset: CGFloat = 4
        static let coreLineSpacing: CGFloat = 2
        static let coreTextInset: CGFloat = 10
        static let iconLabelSpacing: CGFloat = 3
        static let iconGlowOpacity = 0.55
        static let iconGlowRadius: CGFloat = 8
        static let iconGlowOffset: CGFloat = 6
        static let vacancyDash: [CGFloat] = [3, 2]
        static let hiddenScale: CGFloat = 0.85
        static let hiddenBlur: CGFloat = 6
        static let openDuration: TimeInterval = 0.16
        static let closeDuration: TimeInterval = 0.12
        static let minimumProgress: Duration = .milliseconds(400)
        static let escapeKeyCode: UInt16 = 53
    }

    enum Split {
        static let width: CGFloat = 380
        static let textSize: CGFloat = 13
        static let captionSize: CGFloat = 12
        static let horizontalPadding: CGFloat = 22
        static let topPadding: CGFloat = 18
        static let footerTopPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 18
        static let rowSpacing: CGFloat = 14
        static let captionSpacing: CGFloat = 2
        static let fieldSpacing: CGFloat = 6
        static let fieldWidth: CGFloat = 140
        static let fieldCornerRadius: CGFloat = 5
        static let buttonSpacing: CGFloat = 8
        static let radioSize: CGFloat = 16
        static let radioSpacing: CGFloat = 10
        static let radioTopInset: CGFloat = 1
        static let radioOnBorder: CGFloat = 5
        static let accent: UInt32 = 0x0A63D6
        static let radioBorder: UInt32 = 0xA1A1A6
        static let errorBorder: UInt32 = 0xFF3B30
        static let errorText: UInt32 = 0xD70015
        static let errorGlowOpacity = 0.15
        static let errorGlowRadius: CGFloat = 3
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

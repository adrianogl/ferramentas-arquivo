import AppKit
import ApplicationServices
import CoreServices

@MainActor
enum Permissions {
    static var accessibility: Bool {
        AXIsProcessTrusted()
    }

    nonisolated static func finderAutomation(ask: Bool) -> Bool {
        var target = AEAddressDesc()
        let created = AppConstants.finderBundleIdentifier.withCString { bytes in
            AECreateDesc(DescType(typeApplicationBundleID), bytes, strlen(bytes), &target)
        }
        guard created == noErr else { return false }
        defer { AEDisposeDesc(&target) }
        let status = AEDeterminePermissionToAutomateTarget(&target, AEEventClass(typeWildCard), AEEventID(typeWildCard), ask)
        return status == noErr
    }

    static func openAccessibilitySettings() {
        NSWorkspace.shared.open(AppConstants.accessibilitySettingsURL)
    }

    static func openAutomationSettings() {
        NSWorkspace.shared.open(AppConstants.automationSettingsURL)
    }
}

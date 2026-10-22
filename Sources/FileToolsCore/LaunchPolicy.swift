import Foundation

public enum LaunchPolicy {
    public static func isLoginLaunch(
        hasLoginItemFlag: Bool,
        launchAtLoginEnabled: Bool,
        secondsSinceSessionStart: TimeInterval?
    ) -> Bool {
        if hasLoginItemFlag { return true }
        guard launchAtLoginEnabled, let secondsSinceSessionStart else { return false }
        return secondsSinceSessionStart >= 0 && secondsSinceSessionStart <= Constants.loginLaunchWindow
    }

    public static func shouldShowSettings(
        launchIsDefault: Bool?,
        isLoginLaunch: Bool,
        onboardingCompleted: Bool
    ) -> Bool {
        onboardingCompleted && launchIsDefault != false && !isLoginLaunch
    }
}

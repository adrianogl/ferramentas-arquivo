import Testing
@testable import FileToolsCore

@Suite struct LaunchPolicyTests {
    @Test func serviceColdLaunchDoesNotShowSettings() {
        #expect(!LaunchPolicy.shouldShowSettings(launchIsDefault: false, isLoginLaunch: false, onboardingCompleted: true))
    }

    @Test func userLaunchShowsSettings() {
        #expect(LaunchPolicy.shouldShowSettings(launchIsDefault: true, isLoginLaunch: false, onboardingCompleted: true))
    }

    @Test func missingLaunchIsDefaultCountsAsUserLaunch() {
        #expect(LaunchPolicy.shouldShowSettings(launchIsDefault: nil, isLoginLaunch: false, onboardingCompleted: true))
    }

    @Test func loginLaunchDoesNotShowSettings() {
        #expect(!LaunchPolicy.shouldShowSettings(launchIsDefault: true, isLoginLaunch: true, onboardingCompleted: true))
    }

    @Test func incompleteOnboardingNeverShowsSettings() {
        #expect(!LaunchPolicy.shouldShowSettings(launchIsDefault: true, isLoginLaunch: false, onboardingCompleted: false))
    }

    @Test func loginItemFlagIsLoginLaunch() {
        #expect(LaunchPolicy.isLoginLaunch(hasLoginItemFlag: true, launchAtLoginEnabled: false, secondsSinceSessionStart: nil))
    }

    @Test func enabledAndShortlyAfterSessionStartIsLoginLaunch() {
        #expect(LaunchPolicy.isLoginLaunch(hasLoginItemFlag: false, launchAtLoginEnabled: true, secondsSinceSessionStart: 20))
    }

    @Test func enabledLongAfterSessionStartIsUserLaunch() {
        #expect(!LaunchPolicy.isLoginLaunch(hasLoginItemFlag: false, launchAtLoginEnabled: true, secondsSinceSessionStart: 3600))
    }

    @Test func disabledShortlyAfterSessionStartIsUserLaunch() {
        #expect(!LaunchPolicy.isLoginLaunch(hasLoginItemFlag: false, launchAtLoginEnabled: false, secondsSinceSessionStart: 20))
    }

    @Test func unknownSessionStartIsUserLaunch() {
        #expect(!LaunchPolicy.isLoginLaunch(hasLoginItemFlag: false, launchAtLoginEnabled: true, secondsSinceSessionStart: nil))
    }
}

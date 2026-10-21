import FileToolsCore
import Observation

@MainActor
@Observable
final class SettingsModel {
    private(set) var limitMegabytes: Double
    private(set) var triggerModifier: TriggerModifier
    private(set) var launchAtLogin: Bool
    private(set) var accessibilityGranted = Permissions.accessibility
    private(set) var finderAutomationGranted = true

    @ObservationIgnored private let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
        limitMegabytes = settings.limitMegabytes
        triggerModifier = settings.triggerModifier
        launchAtLogin = settings.launchAtLogin
    }

    func reload() {
        limitMegabytes = settings.limitMegabytes
        triggerModifier = settings.triggerModifier
        launchAtLogin = settings.launchAtLogin
    }

    func setLimitMegabytes(_ value: Double) {
        settings.limitMegabytes = value
        limitMegabytes = settings.limitMegabytes
    }

    func setTriggerModifier(_ value: TriggerModifier) {
        settings.triggerModifier = value
        triggerModifier = value
    }

    func setLaunchAtLogin(_ value: Bool) {
        settings.launchAtLogin = value
        launchAtLogin = value
        LaunchAtLogin.apply(value)
    }

    func refreshPermissions() async {
        accessibilityGranted = Permissions.accessibility
        finderAutomationGranted = await Task.detached { Permissions.finderAutomation(ask: false) }.value
    }

    func pollPermissions() async {
        while !Task.isCancelled {
            await refreshPermissions()
            try? await Task.sleep(for: AppConstants.Settings.permissionPollInterval)
        }
    }
}

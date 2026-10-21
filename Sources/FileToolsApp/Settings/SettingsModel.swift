import FileToolsCore
import Observation

@MainActor
@Observable
final class SettingsModel {
    private(set) var limitMegabytes: Double
    private(set) var triggerModifier: TriggerModifier
    private(set) var launchAtLogin: Bool
    private(set) var accessibilityGranted: Bool? = nil
    private(set) var finderAutomationGranted: Bool? = nil

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(settings: SettingsStore) {
        self.settings = settings
        limitMegabytes = settings.limitMegabytes
        triggerModifier = settings.triggerModifier
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    func reload() {
        limitMegabytes = settings.limitMegabytes
        triggerModifier = settings.triggerModifier
        launchAtLogin = LaunchAtLogin.isEnabled
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
        let actual = LaunchAtLogin.apply(value)
        settings.launchAtLogin = actual
        launchAtLogin = actual
    }

    func refreshPermissions() async {
        accessibilityGranted = Permissions.accessibility
        finderAutomationGranted = await Task.detached { Permissions.finderAutomation(ask: false) }.value
    }

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshPermissions()
                try? await Task.sleep(for: AppConstants.Settings.permissionPollInterval)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}

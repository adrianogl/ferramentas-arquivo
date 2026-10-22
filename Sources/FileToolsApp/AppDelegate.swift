import AppKit
import FileToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    let notifier = Notifier()
    private(set) lazy var settingsModel = SettingsModel(settings: settings)
    private(set) lazy var coordinator = ActionCoordinator(settings: settings, notifier: notifier)
    private lazy var serviceProvider = ServiceProvider(coordinator: coordinator)
    private lazy var radial = RadialPanelController(coordinator: coordinator, settings: settings)
    private lazy var split = SplitDialogController(coordinator: coordinator)
    private var organizeWindows: [URL: OrganizeWindowController] = [:]
    private var tap: RightClickTap?
    private var tapRetryTimer: Timer?
    private var hasLoggedTapFailure = false
    private var hasPromptedForAccessibility = false
    private var isSettingsPending = false
    var openSettingsWindow: (() -> Void)? {
        didSet {
            guard isSettingsPending, openSettingsWindow != nil else { return }
            isSettingsPending = false
            showSettings()
        }
    }
    private lazy var onboarding: OnboardingWindowController = {
        let controller = OnboardingWindowController(settings: settings)
        controller.onAccessibilityGranted = { [weak self] in self?.startTap() }
        controller.onRequestAccessibility = { [weak self] in self?.requestAccessibility() }
        return controller
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchIsDefault = notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool
        let launchedAsLoginItem = LaunchPolicy.isLoginLaunch(
            hasLoginItemFlag: Self.hasLoginItemFlag(),
            launchAtLoginEnabled: LaunchAtLogin.isEnabled,
            secondsSinceSessionStart: SessionClock.secondsSinceSessionStart())
        let launchDescription = launchedAsLoginItem ? "login" : launchIsDefault == false ? "serviço ou arquivo" : "usuário"
        Log.app.info("app iniciado (\(launchDescription, privacy: .public))")
        notifier.requestAuthorization()
        NSApp.servicesProvider = serviceProvider
        coordinator.presentSplit = { [weak self] url, pageCount, point in
            self?.split.present(for: url, pageCount: pageCount, near: point)
        }
        coordinator.presentOrganize = { [weak self] url in
            self?.presentOrganize(url)
        }
        NSUpdateDynamicServices()
        tap = RightClickTap(
            modifier: { [settings] in settings.triggerModifier },
            onTrigger: { [weak self] point in self?.handleTrigger(at: point) }
        )
        Task {
            let finder = await Task.detached { Permissions.finderAutomation(ask: false) }.value
            let step = OnboardingStep.first(
                accessibility: Permissions.accessibility,
                finder: finder,
                completed: settings.onboardingCompleted)
            startTap()
            guard let step else {
                let shouldShow = LaunchPolicy.shouldShowSettings(
                    launchIsDefault: launchIsDefault,
                    isLoginLaunch: launchedAsLoginItem,
                    onboardingCompleted: settings.onboardingCompleted)
                if shouldShow { showSettings() }
                return
            }
            Log.app.info("abrindo assistente no passo \(String(describing: step), privacy: .public)")
            onboarding.show(at: step)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Log.app.info("app reaberto")
        showSettings()
        return false
    }

    func showSettings() {
        guard let openSettingsWindow else {
            isSettingsPending = true
            return
        }
        NSApp.activate()
        openSettingsWindow()
    }

    private static func hasLoginItemFlag() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication
        else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    private func presentOrganize(_ url: URL) {
        let key = url.standardizedFileURL.resolvingSymlinksInPath()
        if let existing = organizeWindows[key] {
            existing.show()
            return
        }
        do throws(ActionFailure) {
            let controller = try OrganizeWindowController(url: url, coordinator: coordinator)
            controller.onClose = { [weak self] in self?.organizeWindows[key] = nil }
            organizeWindows[key] = controller
            controller.show()
        } catch {
            coordinator.deliver(ActionReport(failures: [ActionReport.Failure(url: url, reason: error)]), action: .organizePDF)
        }
    }

    private func requestAccessibility() {
        if !hasPromptedForAccessibility, let tap {
            hasPromptedForAccessibility = true
            if tap.start(prompt: true) {
                startTap()
                return
            }
        }
        Permissions.openAccessibilitySettings()
    }

    func showOnboarding() {
        Task {
            let finder = await Task.detached { Permissions.finderAutomation(ask: false) }.value
            let step = OnboardingStep.first(accessibility: Permissions.accessibility, finder: finder, completed: true) ?? .welcome
            onboarding.show(at: step)
        }
    }

    private func startTap() {
        guard let tap else { return }
        if tap.start() {
            tapRetryTimer?.invalidate()
            tapRetryTimer = nil
            Log.trigger.info("tap ativo")
            return
        }
        if !hasLoggedTapFailure {
            hasLoggedTapFailure = true
            Log.trigger.error("tap não iniciou, aguardando permissão de Acessibilidade")
        }
        guard tapRetryTimer == nil else { return }
        tapRetryTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.tapRetryInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.startTap()
            }
        }
    }

    private func handleTrigger(at point: CGPoint) {
        Task {
            if let targets = await FinderTargetResolver.resolve(at: point) {
                let paths = targets.map(\.path).joined(separator: ", ")
                Log.trigger.info("alvo: \(paths, privacy: .public)")
                if onboarding.onTryItTarget?(targets) == true { return }
                radial.show(targets: targets, at: point)
            } else {
                tap?.passThrough(at: point, flags: settings.triggerModifier.cgFlag)
            }
        }
    }
}

import AppKit
import FileToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    private var tap: RightClickTap?
    private var tapRetryTimer: Timer?
    private var hasLoggedTapFailure = false
    private var hasPromptedForAccessibility = false
    private lazy var onboarding: OnboardingWindowController = {
        let controller = OnboardingWindowController(settings: settings)
        controller.onAccessibilityGranted = { [weak self] in self?.startTap() }
        controller.onRequestAccessibility = { [weak self] in self?.requestAccessibility() }
        return controller
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("app iniciado")
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
            guard let step else { return }
            Log.app.info("abrindo assistente no passo \(String(describing: step), privacy: .public)")
            onboarding.show(at: step)
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
                onboarding.onTryItTarget?(targets)
            } else {
                tap?.passThrough(at: point, flags: settings.triggerModifier.cgFlag)
            }
        }
    }
}

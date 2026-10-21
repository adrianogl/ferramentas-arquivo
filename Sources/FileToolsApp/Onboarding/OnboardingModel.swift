import AppKit
import FileToolsCore
import Observation

@MainActor
@Observable
final class OnboardingModel {
    private(set) var step: OnboardingStep = .welcome
    private(set) var accessibilityGranted = Permissions.accessibility
    private(set) var finderGranted = false
    private(set) var finderRequested = false
    private(set) var isRequestingFinder = false
    private(set) var triedIt = false

    private(set) var limitMegabytes: Double
    private(set) var launchAtLogin: Bool

    @ObservationIgnored var onAccessibilityGranted: (() -> Void)?
    @ObservationIgnored var onRequestAccessibility: (() -> Void)?
    @ObservationIgnored var commitEdits: (() -> Void)?
    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var pollTimer: Timer?

    init(settings: SettingsStore) {
        self.settings = settings
        limitMegabytes = settings.limitMegabytes
        launchAtLogin = settings.launchAtLogin
    }

    var canContinue: Bool {
        step.canContinue(accessibility: accessibilityGranted, finder: finderGranted, triedIt: triedIt)
    }

    func start(at step: OnboardingStep) {
        limitMegabytes = settings.limitMegabytes
        launchAtLogin = settings.launchAtLogin
        go(to: step)
        refreshPermissions()
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Onboarding.permissionPollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshPermissions()
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func advance() {
        guard canContinue else { return }
        if step == .done {
            commitEdits?()
            settings.onboardingCompleted = true
            onFinish?()
            return
        }
        if let next = OnboardingStep(rawValue: step.rawValue + 1) { go(to: next) }
    }

    func back() {
        if let previous = OnboardingStep(rawValue: step.rawValue - 1) { go(to: previous) }
    }

    func skipTryIt() {
        guard step == .tryIt else { return }
        go(to: .done)
    }

    func setLimitMegabytes(_ value: Double) {
        settings.limitMegabytes = value
        limitMegabytes = settings.limitMegabytes
    }

    func setLaunchAtLogin(_ value: Bool) {
        settings.launchAtLogin = value
        launchAtLogin = value
    }

    func openAccessibilitySettings() {
        if let onRequestAccessibility {
            onRequestAccessibility()
        } else {
            Permissions.openAccessibilitySettings()
        }
    }

    func openAutomationSettings() {
        Permissions.openAutomationSettings()
    }

    func requestFinder() {
        guard !isRequestingFinder else { return }
        isRequestingFinder = true
        Task {
            let granted = await Task.detached { Permissions.finderAutomation(ask: true) }.value
            finderGranted = granted
            finderRequested = true
            isRequestingFinder = false
            Log.app.info("permissão do Finder: \(granted ? "concedida" : "negada", privacy: .public)")
        }
    }

    func registerTryIt(_ targets: [URL]) -> Bool {
        guard step == .tryIt, SamplePDF.matches(targets) else { return false }
        if !triedIt {
            triedIt = true
            Log.app.info("passo Experimente concluído")
        }
        return true
    }

    private func go(to step: OnboardingStep) {
        self.step = step
        if step == .tryIt { prepareSample() }
    }

    private func prepareSample() {
        do {
            try SamplePDF.reveal()
        } catch {
            Log.app.error("não deu para criar o exemplo.pdf: \(error, privacy: .public)")
        }
    }

    private func refreshPermissions() {
        let accessibility = Permissions.accessibility
        if accessibility, !accessibilityGranted {
            accessibilityGranted = true
            onAccessibilityGranted?()
            if step == .accessibility { go(to: .finder) }
        } else {
            accessibilityGranted = accessibility
        }
        guard !isRequestingFinder else { return }
        Task {
            let granted = await Task.detached { Permissions.finderAutomation(ask: false) }.value
            if !isRequestingFinder { finderGranted = granted }
        }
    }
}

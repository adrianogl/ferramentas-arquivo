import AppKit
import FileToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()
    private var tap: RightClickTap?
    private var tapRetryTimer: Timer?
    private var hasLoggedTapFailure = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("app iniciado")
        tap = RightClickTap(
            modifier: { [settings] in settings.triggerModifier },
            onTrigger: { [weak self] point in self?.handleTrigger(at: point) }
        )
        startTap()
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
            } else {
                tap?.passThrough(at: point, flags: settings.triggerModifier.cgFlag)
            }
        }
    }
}

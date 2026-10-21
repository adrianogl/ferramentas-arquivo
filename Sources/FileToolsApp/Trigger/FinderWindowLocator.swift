import AppKit
import CoreGraphics
import FileToolsCore

@MainActor
enum FinderWindowLocator {
    static func isFinderUnder(_ point: CGPoint) -> Bool {
        guard let finderPID = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppConstants.finderBundleIdentifier)
            .first?.processIdentifier
        else {
            Log.trigger.info("⌥+clique ignorado: Finder não está rodando")
            return false
        }
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        let hit = WindowHitTest.frontmostWindow(
            at: point,
            in: info.compactMap(WindowSnapshot.init(info:)),
            excludingPID: ProcessInfo.processInfo.processIdentifier,
            desktopIconLayer: Int(CGWindowLevelForKey(.desktopIconWindow))
        )
        guard let hit else {
            Log.trigger.info("⌥+clique ignorado: nenhuma janela sob o cursor em \(point.debugDescription, privacy: .public)")
            return false
        }
        guard hit.ownerPID == finderPID else {
            Log.trigger.info("⌥+clique ignorado: janela sob o cursor é de \(hit.ownerName, privacy: .public) (layer \(hit.layer))")
            return false
        }
        return true
    }
}

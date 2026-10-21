import AppKit
import ApplicationServices
import CoreGraphics
import FileToolsCore

@MainActor
enum FinderWindowLocator {
    private static let systemWide: AXUIElement = {
        let element = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(element, AppConstants.hitTestMessagingTimeout)
        return element
    }()

    static func isFinderUnder(_ point: CGPoint) -> Bool {
        guard let finderPID = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppConstants.finderBundleIdentifier)
            .first?.processIdentifier
        else {
            Log.trigger.info("⌥+clique ignorado: Finder não está rodando")
            return false
        }

        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &element)
        var pid: pid_t = 0
        if result == .success, let element, AXUIElementGetPid(element, &pid) == .success {
            guard pid == finderPID else {
                Log.trigger.info("⌥+clique ignorado (AX): elemento sob o cursor é de \(appName(pid), privacy: .public)")
                return false
            }
            return true
        }
        return isFinderUnderByWindowList(point, finderPID: finderPID, axError: result)
    }

    private static func isFinderUnderByWindowList(_ point: CGPoint, finderPID: pid_t, axError: AXError) -> Bool {
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        let hit = WindowHitTest.frontmostWindow(
            at: point,
            in: info.compactMap(WindowSnapshot.init(info:)),
            excludingPID: ProcessInfo.processInfo.processIdentifier,
            desktopIconLayer: Int(CGWindowLevelForKey(.desktopIconWindow)),
            screens: activeDisplayBounds()
        )
        guard let hit else {
            Log.trigger.info("⌥+clique ignorado (fallback, AX \(axError.rawValue)): nenhuma janela sob o cursor em \(point.debugDescription, privacy: .public)")
            return false
        }
        guard hit.ownerPID == finderPID else {
            Log.trigger.info("⌥+clique ignorado (fallback, AX \(axError.rawValue)): janela sob o cursor é de \(hit.ownerName, privacy: .public) (layer \(hit.layer))")
            return false
        }
        return true
    }

    private static func activeDisplayBounds() -> [CGRect] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displays, &count) == .success else { return [] }
        return displays.prefix(Int(count)).map(CGDisplayBounds)
    }

    private static func appName(_ pid: pid_t) -> String {
        NSRunningApplication(processIdentifier: pid)?.localizedName ?? "pid \(pid)"
    }
}

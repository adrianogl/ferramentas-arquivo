import AppKit
import ApplicationServices
import FileToolsCore

@MainActor
enum FinderTargetResolver {
    private static let systemWide: AXUIElement = {
        let element = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(element, AppConstants.hitTestMessagingTimeout)
        return element
    }()

    static func resolve(at point: CGPoint) async -> [URL]? {
        let hit = hitTest(at: point)
        let targets: [URL]?
        if let clicked = hit?.url {
            targets = TargetRule.resolve(selection: FinderScripting.selection(), clicked: clicked)
        } else if let hit, ClickTargetRule.allowsSyntheticClick(path: hit.path) {
            targets = await selectByClicking(at: point, before: FinderScripting.selection())
        } else {
            let roles = hit?.path.map(\.role).joined(separator: " < ") ?? "nenhum elemento"
            Log.trigger.info("⌥+clique fora da área de arquivos: \(roles, privacy: .public)")
            targets = nil
        }
        guard let targets, TargetRule.shouldShowRadial(for: targets) else { return nil }
        return targets
    }

    private static func hitTest(at point: CGPoint) -> (url: URL?, path: [AccessibilityNode])? {
        guard let finderPID = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppConstants.finderBundleIdentifier)
            .first?.processIdentifier
        else { return nil }

        guard var element = topmostElement(at: point, finderPID: finderPID) else { return nil }

        var path: [AccessibilityNode] = []
        for _ in 0...AppConstants.maxAccessibilityAncestors {
            if let url = attribute(kAXURLAttribute, of: element) as? URL {
                return (url, path)
            }
            path.append(node(for: element))
            guard let parent = attribute(kAXParentAttribute, of: element),
                  CFGetTypeID(parent) == AXUIElementGetTypeID()
            else { return (nil, path) }
            element = parent as! AXUIElement
        }
        return (nil, path)
    }

    private static func topmostElement(at point: CGPoint, finderPID: pid_t) -> AXUIElement? {
        var hit: AXUIElement?
        if AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &hit) == .success, let hit {
            var pid: pid_t = 0
            guard AXUIElementGetPid(hit, &pid) == .success, pid == finderPID else { return nil }
            return hit
        }
        let application = AXUIElementCreateApplication(finderPID)
        guard AXUIElementCopyElementAtPosition(application, Float(point.x), Float(point.y), &hit) == .success else { return nil }
        return hit
    }

    private static func node(for element: AXUIElement) -> AccessibilityNode {
        AccessibilityNode(
            role: attribute(kAXRoleAttribute, of: element) as? String ?? "",
            subrole: attribute(kAXSubroleAttribute, of: element) as? String ?? "",
            identifier: attribute(kAXIdentifierAttribute, of: element) as? String ?? "")
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func selectByClicking(at point: CGPoint, before: [URL]) async -> [URL]? {
        guard FinderWindowLocator.isFinderUnder(point) else { return nil }
        postLeftClick(at: point)
        try? await Task.sleep(for: AppConstants.selectionSettleDelay)
        let after = FinderScripting.selection()
        if !before.isEmpty, selectionKeys(after) != selectionKeys(before) {
            FinderScripting.select(before)
        }
        if after.isEmpty { return nil }
        if after.count == 1, TargetRule.resolve(selection: before, clicked: after[0]) == before {
            return before
        }
        return after
    }

    private static func selectionKeys(_ urls: [URL]) -> Set<String> {
        Set(urls.map { $0.standardizedFileURL.path.precomposedStringWithCanonicalMapping })
    }

    private static func postLeftClick(at point: CGPoint) {
        for type in [CGEventType.leftMouseDown, .leftMouseUp] {
            guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { continue }
            event.flags = []
            event.setIntegerValueField(.eventSourceUserData, value: AppConstants.syntheticEventMarker)
            event.post(tap: .cghidEventTap)
        }
    }
}

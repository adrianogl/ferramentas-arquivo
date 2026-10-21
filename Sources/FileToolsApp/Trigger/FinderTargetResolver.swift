import AppKit
import ApplicationServices
import FileToolsCore

@MainActor
enum FinderTargetResolver {
    static func resolve(at point: CGPoint) async -> [URL]? {
        let before = FinderScripting.selection()
        let targets: [URL]?
        if let clicked = itemUnderCursor(at: point) {
            targets = TargetRule.resolve(selection: before, clicked: clicked)
        } else {
            targets = await selectByClicking(at: point, before: before)
        }
        guard let targets, TargetRule.shouldShowRadial(for: targets) else { return nil }
        return targets
    }

    private static func itemUnderCursor(at point: CGPoint) -> URL? {
        guard let finderPID = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppConstants.finderBundleIdentifier)
            .first?.processIdentifier
        else { return nil }

        var hit: AXUIElement?
        let application = AXUIElementCreateApplication(finderPID)
        guard AXUIElementCopyElementAtPosition(application, Float(point.x), Float(point.y), &hit) == .success,
              var element = hit
        else { return nil }

        for _ in 0...AppConstants.maxAccessibilityAncestors {
            if let url = attribute(kAXURLAttribute, of: element) as? URL { return url }
            guard let parent = attribute(kAXParentAttribute, of: element),
                  CFGetTypeID(parent) == AXUIElementGetTypeID()
            else { return nil }
            element = parent as! AXUIElement
        }
        return nil
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

import AppKit
import ApplicationServices
import FileToolsCore

@MainActor
final class RightClickTap {
    private let modifier: () -> TriggerModifier
    private let onTrigger: (CGPoint) -> Void
    private var machPort: CFMachPort?
    private var swallowingUp = false
    private var hasPromptedForTrust = false

    init(modifier: @escaping () -> TriggerModifier, onTrigger: @escaping (CGPoint) -> Void) {
        self.modifier = modifier
        self.onTrigger = onTrigger
    }

    func start() -> Bool {
        if machPort != nil { return true }
        let prompt = !hasPromptedForTrust
        hasPromptedForTrust = true
        let options = [AppConstants.accessibilityTrustPromptKey: prompt] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else { return false }

        let mask = (CGEventMask(1) << CGEventType.rightMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseUp.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: rightClickTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        machPort = port
        return true
    }

    func passThrough(at point: CGPoint, flags: CGEventFlags) {
        for type in [CGEventType.rightMouseDown, .rightMouseUp] {
            guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .right) else { continue }
            event.flags = flags
            event.setIntegerValueField(.eventSourceUserData, value: AppConstants.syntheticEventMarker)
            event.post(tap: .cghidEventTap)
        }
    }

    fileprivate func shouldSwallow(type: CGEventType, flags: CGEventFlags, location: CGPoint, isSynthetic: Bool) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            swallowingUp = false
            if let machPort { CGEvent.tapEnable(tap: machPort, enable: true) }
            Log.trigger.info("religando tap")
            return false
        case .rightMouseDown:
            swallowingUp = false
            guard !isSynthetic,
                  flags.contains(modifier().cgFlag),
                  FinderWindowLocator.isFinderUnder(location)
            else { return false }
            swallowingUp = true
            DispatchQueue.main.async { [weak self] in
                self?.onTrigger(location)
            }
            return true
        case .rightMouseUp:
            guard !isSynthetic, swallowingUp else { return false }
            swallowingUp = false
            return true
        default:
            return false
        }
    }
}

private func rightClickTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<RightClickTap>.fromOpaque(userInfo).takeUnretainedValue()
    let flags = event.flags
    let location = event.location
    let isSynthetic = event.getIntegerValueField(.eventSourceUserData) == AppConstants.syntheticEventMarker
    let swallow = MainActor.assumeIsolated {
        tap.shouldSwallow(type: type, flags: flags, location: location, isSynthetic: isSynthetic)
    }
    return swallow ? nil : Unmanaged.passUnretained(event)
}

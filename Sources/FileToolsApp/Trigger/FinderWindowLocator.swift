import AppKit
import CoreGraphics

@MainActor
enum FinderWindowLocator {
    static func isFinderUnder(_ point: CGPoint) -> Bool {
        guard let finderPID = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppConstants.finderBundleIdentifier)
            .first?.processIdentifier,
            let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]
        else { return false }

        for window in windows {
            if let alpha = window[kCGWindowAlpha as String] as? Double, alpha == 0 { continue }
            guard let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                  bounds.contains(point)
            else { continue }
            return (window[kCGWindowOwnerPID as String] as? pid_t) == finderPID
        }
        return false
    }
}

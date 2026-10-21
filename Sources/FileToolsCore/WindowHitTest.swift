import CoreGraphics

public enum WindowHitTest {
    public static func frontmostWindow(
        at point: CGPoint,
        in windows: [WindowSnapshot],
        excludingPID ownPID: Int32,
        desktopIconLayer: Int,
        screens: [CGRect]
    ) -> WindowSnapshot? {
        windows.first { window in
            guard window.alpha > 0, window.ownerPID != ownPID, window.bounds.contains(point) else { return false }
            if window.layer == Constants.normalWindowLayer || window.layer == desktopIconLayer { return true }
            return !screens.contains { window.bounds.contains($0) }
        }
    }
}

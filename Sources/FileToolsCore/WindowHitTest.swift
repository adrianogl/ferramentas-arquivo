import CoreGraphics

public enum WindowHitTest {
    public static func frontmostWindow(
        at point: CGPoint,
        in windows: [WindowSnapshot],
        excludingPID ownPID: Int32,
        desktopIconLayer: Int
    ) -> WindowSnapshot? {
        windows.first { window in
            (window.layer == Constants.normalWindowLayer || window.layer == desktopIconLayer)
                && window.alpha > 0
                && window.ownerPID != ownPID
                && window.bounds.contains(point)
        }
    }
}

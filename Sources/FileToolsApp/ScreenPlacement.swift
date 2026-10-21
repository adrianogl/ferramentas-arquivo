import AppKit

@MainActor
enum ScreenPlacement {
    static func frame(size: CGSize, centeredAt cgPoint: CGPoint) -> CGRect {
        let primaryMaxY = NSScreen.screens.first?.frame.maxY ?? 0
        let point = CGPoint(x: cgPoint.x, y: primaryMaxY - cgPoint.y)
        let screen = NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDisplayBounds(CGDirectDisplayID(number.uint32Value)).contains(cgPoint)
        } ?? NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        var origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        }
        return CGRect(origin: origin, size: size)
    }
}

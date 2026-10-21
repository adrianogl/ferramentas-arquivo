import CoreGraphics
import Testing
@testable import FileToolsCore

@Suite struct WindowHitTestTests {
    let finderPID: Int32 = 100
    let ownPID: Int32 = 200
    let desktopIconLayer = -2_147_483_603
    let screen = CGRect(x: 0, y: 0, width: 5120, height: 1440)

    func window(_ name: String, pid: Int32, layer: Int, alpha: Double = 1, bounds: CGRect) -> WindowSnapshot {
        WindowSnapshot(ownerPID: pid, ownerName: name, layer: layer, alpha: alpha, bounds: bounds)
    }

    var authorWindows: [WindowSnapshot] {
        [
            window("Window Server", pid: 1, layer: 2_147_483_630, bounds: CGRect(x: 4000, y: 0, width: 40, height: 30)),
            window("Wispr Flow", pid: 2, layer: 1000, bounds: CGRect(x: 2500, y: 1300, width: 120, height: 40)),
            window("Window Server", pid: 1, layer: 24, bounds: CGRect(x: 0, y: 0, width: 5120, height: 30)),
            window("Central de Notificações", pid: 3, layer: 21, bounds: screen),
            window("Safari", pid: 4, layer: 0, bounds: CGRect(x: 2000, y: 100, width: 1000, height: 800)),
            window("Finder", pid: finderPID, layer: 0, bounds: CGRect(x: 100, y: 100, width: 1200, height: 800)),
            window("Finder", pid: finderPID, layer: desktopIconLayer, bounds: screen),
        ]
    }

    func hit(_ point: CGPoint, in windows: [WindowSnapshot]) -> WindowSnapshot? {
        WindowHitTest.frontmostWindow(at: point, in: windows, excludingPID: ownPID, desktopIconLayer: desktopIconLayer, screens: [screen])
    }

    @Test func overlayInFrontOfFinderWindowIsIgnored() {
        #expect(hit(CGPoint(x: 500, y: 500), in: authorWindows)?.ownerPID == finderPID)
    }

    @Test func otherNormalAppAboveDesktopWins() {
        #expect(hit(CGPoint(x: 2500, y: 500), in: authorWindows)?.ownerName == "Safari")
    }

    @Test func desktopIconWindowCountsWhenNothingElseCovers() {
        #expect(hit(CGPoint(x: 4500, y: 1000), in: authorWindows)?.ownerPID == finderPID)
    }

    @Test func dockBlocksDesktopBehindIt() {
        let windows = authorWindows + [window("Dock", pid: 6, layer: 20, bounds: CGRect(x: 1500, y: 1340, width: 2100, height: 100))]
        let dockFirst = [windows.last!] + windows.dropLast()
        #expect(hit(CGPoint(x: 2000, y: 1400), in: dockFirst)?.ownerName == "Dock")
    }

    @Test func menuBarStripBlocksFinderWindowBelowIt() {
        let windows = [
            window("Window Server", pid: 1, layer: 24, bounds: CGRect(x: 0, y: 0, width: 5120, height: 30)),
            window("Finder", pid: finderPID, layer: 0, bounds: CGRect(x: 0, y: 0, width: 1200, height: 800)),
        ]
        #expect(hit(CGPoint(x: 500, y: 15), in: windows)?.ownerName == "Window Server")
    }

    @Test func desktopWidgetBlocksDesktopIcons() {
        let windows = [
            window("Central de Notificações", pid: 3, layer: -2_147_483_601, bounds: CGRect(x: 8, y: 38, width: 360, height: 180)),
            window("Finder", pid: finderPID, layer: desktopIconLayer, bounds: screen),
        ]
        #expect(hit(CGPoint(x: 100, y: 100), in: windows)?.ownerPID == 3)
        #expect(hit(CGPoint(x: 1000, y: 100), in: windows)?.ownerPID == finderPID)
    }

    @Test func transparentAndOwnWindowsAreSkipped() {
        let windows = [
            window("FileTools", pid: ownPID, layer: 0, bounds: screen),
            window("Invisível", pid: 5, layer: 0, alpha: 0, bounds: screen),
            window("Finder", pid: finderPID, layer: 0, bounds: screen),
        ]
        #expect(hit(CGPoint(x: 10, y: 50), in: windows)?.ownerPID == finderPID)
    }

    @Test func noWindowUnderPoint() {
        let windows = [window("Finder", pid: finderPID, layer: 0, bounds: CGRect(x: 0, y: 0, width: 10, height: 10))]
        #expect(hit(CGPoint(x: 50, y: 50), in: windows) == nil)
    }

    @Test func snapshotFromWindowInfo() {
        let info: [String: Any] = [
            kCGWindowOwnerPID as String: Int32(42),
            kCGWindowOwnerName as String: "Finder",
            kCGWindowLayer as String: 0,
            kCGWindowAlpha as String: 1.0,
            kCGWindowBounds as String: CGRect(x: 1, y: 2, width: 3, height: 4).dictionaryRepresentation,
        ]
        #expect(WindowSnapshot(info: info) == WindowSnapshot(ownerPID: 42, ownerName: "Finder", layer: 0, alpha: 1, bounds: CGRect(x: 1, y: 2, width: 3, height: 4)))
    }
}

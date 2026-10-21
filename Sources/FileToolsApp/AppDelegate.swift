import AppKit
import FileToolsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = SettingsStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("app iniciado")
    }
}

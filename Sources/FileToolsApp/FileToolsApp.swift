import AppKit
import SwiftUI

@main
struct FileToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(appDelegate: appDelegate)
        } label: {
            MenuBarLabel()
        }
        Window(AppConstants.Settings.windowTitle, id: "settings") {
            SettingsView(model: appDelegate.settingsModel)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct MenuBarContent: View {
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Configurações…") {
            NSApp.activate()
            openWindow(id: "settings")
        }
        Button("Configurar permissões…") {
            appDelegate.showOnboarding()
        }
        Divider()
        Button("Sair") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

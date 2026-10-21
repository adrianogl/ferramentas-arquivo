import AppKit
import SwiftUI

@main
struct FileToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(appDelegate: appDelegate)
        } label: {
            MenuBarLabel(appDelegate: appDelegate)
        }
        Window(AppConstants.Settings.windowTitle, id: AppConstants.Settings.windowID) {
            SettingsView(model: appDelegate.settingsModel)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct MenuBarContent: View {
    let appDelegate: AppDelegate

    var body: some View {
        Button("Configurações…") {
            appDelegate.showSettings()
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

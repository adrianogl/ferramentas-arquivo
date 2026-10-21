import AppKit
import SwiftUI

@main
struct FileToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Ferramentas de Arquivo", systemImage: "doc.badge.gearshape") {
            MenuBarContent()
        }
        Window("Ferramentas de Arquivo", id: "settings") {
            Text("Configurações")
                .padding()
        }
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Configurações…") {
            NSApp.activate()
            openWindow(id: "settings")
        }
        Divider()
        Button("Sair") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

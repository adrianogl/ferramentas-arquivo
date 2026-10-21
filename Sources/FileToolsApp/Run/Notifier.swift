import AppKit
import FileToolsCore
import UserNotifications

@MainActor
final class Notifier {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert])
                Log.app.info("autorização de notificações: \(granted, privacy: .public)")
            } catch {
                Log.app.error("falha ao pedir autorização de notificações: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func post(_ messages: [UserMessage]) {
        guard !messages.isEmpty else { return }
        Task {
            let status = await center.notificationSettings().authorizationStatus
            let canNotify = status == .authorized || status == .provisional
            for message in messages {
                if canNotify {
                    await send(message)
                } else if message.isError {
                    showAlert(message)
                }
            }
        }
    }

    private func send(_ message: UserMessage) async {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await center.add(request)
        } catch {
            Log.app.error("falha ao enviar notificação: \(error.localizedDescription, privacy: .public)")
            if message.isError { showAlert(message) }
        }
    }

    private func showAlert(_ message: UserMessage) {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message.title
        alert.informativeText = message.body
        alert.runModal()
    }
}

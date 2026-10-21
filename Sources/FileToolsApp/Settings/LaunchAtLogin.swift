import ServiceManagement

@MainActor
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func apply(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            }
        } catch {
            Log.app.error("falha ao ajustar abrir ao iniciar sessão: \(error.localizedDescription, privacy: .public)")
        }
        return isEnabled
    }
}

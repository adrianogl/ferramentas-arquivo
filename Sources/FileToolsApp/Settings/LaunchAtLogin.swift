import ServiceManagement

@MainActor
enum LaunchAtLogin {
    static func apply(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else if service.status == .enabled {
                try service.unregister()
            }
        } catch {
            Log.app.error("falha ao ajustar abrir ao iniciar sessão: \(error.localizedDescription, privacy: .public)")
        }
    }
}

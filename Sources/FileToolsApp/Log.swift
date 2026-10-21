import OSLog

enum Log {
    static let app = Logger(subsystem: "dev.aglv.FerramentasArquivo", category: "app")
    static let trigger = Logger(subsystem: "dev.aglv.FerramentasArquivo", category: "trigger")
}

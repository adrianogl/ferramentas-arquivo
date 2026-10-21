import Foundation

enum Constants {
    static let bytesPerMegabyte = 1_000_000.0
    static let defaultLimitMegabytes = 1.0
    static let limitMegabytesRange = 0.1...100.0
    static let minimumPageNumberWidth = 2

    enum Suffix {
        static let optimized = "-otimizado"
        static let merged = "-juntado"
        static let extracted = "-extraido"
        static let organized = "-organizado"
        static let pagesFolder = "-paginas"
    }

    enum SettingsKey {
        static let limitMegabytes = "limitMegabytes"
        static let triggerModifier = "triggerModifier"
        static let launchAtLogin = "launchAtLogin"
    }
}

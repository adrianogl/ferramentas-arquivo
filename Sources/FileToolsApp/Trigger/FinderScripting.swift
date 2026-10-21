import Foundation

@MainActor
enum FinderScripting {
    private static let selectionSource = """
    tell application "Finder"
      set out to {}
      repeat with i in (get selection)
        set end of out to POSIX path of (i as alias)
      end repeat
      return out
    end tell
    """

    static func selection() -> [URL] {
        guard let descriptor = run(selectionSource) else { return [] }
        guard descriptor.numberOfItems > 0 else { return [] }
        return (1...descriptor.numberOfItems).compactMap { index in
            descriptor.atIndex(index)?.stringValue.map { URL(fileURLWithPath: $0) }
        }
    }

    static func select(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let items = urls
            .map { "POSIX file \"\(escape($0.path))\" as alias" }
            .joined(separator: ", ")
        _ = run("tell application \"Finder\" to select {\(items)}")
    }

    private static func escape(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            Log.trigger.error("AppleScript do Finder falhou: \(error, privacy: .public)")
            return nil
        }
        return result
    }
}

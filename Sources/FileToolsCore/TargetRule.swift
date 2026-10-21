import Foundation

public enum TargetRule {
    public static func resolve(selection: [URL], clicked: URL?) -> [URL]? {
        guard let clicked else { return nil }
        let clickedKey = key(clicked)
        if selection.contains(where: { key($0) == clickedKey }) { return selection }
        return [clicked]
    }

    public static func shouldShowRadial(for targets: [URL]) -> Bool {
        targets.contains { FileKind.of($0) != .unsupported }
    }

    private static func key(_ url: URL) -> String {
        url.standardizedFileURL.path.precomposedStringWithCanonicalMapping
    }
}

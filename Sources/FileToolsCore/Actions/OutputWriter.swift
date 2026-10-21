import Foundation

public enum OutputWriter {
    public static func write(_ data: Data, to url: URL) throws(ActionFailure) {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw .writeFailed
        }
    }

    public static func makeFolder(_ url: URL) throws(ActionFailure) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        } catch {
            throw .writeFailed
        }
    }
}

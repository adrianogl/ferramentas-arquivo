import Foundation
import UniformTypeIdentifiers

public enum FileKind: Sendable, Equatable {
    case pdf, image, unsupported

    public static func of(_ url: URL) -> FileKind {
        guard let values = try? url.resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey]),
              values.isDirectory != true,
              let type = values.contentType
        else { return .unsupported }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        return .unsupported
    }
}

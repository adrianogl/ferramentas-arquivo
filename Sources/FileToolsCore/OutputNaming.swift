import Foundation

public enum OutputNaming {
    public static func optimized(for source: URL) -> URL {
        sibling(of: source, suffix: Constants.Suffix.optimized, ext: "pdf")
    }

    public static func imagesPDF(firstImage: URL) -> URL {
        sibling(of: firstImage, suffix: "", ext: "pdf")
    }

    public static func merged(first: URL) -> URL {
        sibling(of: first, suffix: Constants.Suffix.merged, ext: "pdf")
    }

    public static func extracted(for source: URL) -> URL {
        sibling(of: source, suffix: Constants.Suffix.extracted, ext: "pdf")
    }

    public static func organized(for source: URL) -> URL {
        sibling(of: source, suffix: Constants.Suffix.organized, ext: "pdf")
    }

    public static func markdown(for source: URL) -> URL {
        sibling(of: source, suffix: "", ext: "md")
    }

    public static func singleJPG(for source: URL) -> URL {
        sibling(of: source, suffix: "", ext: "jpg")
    }

    public static func pagesFolder(for source: URL) -> URL {
        sibling(of: source, suffix: Constants.Suffix.pagesFolder, ext: "")
    }

    public static func pageFileName(base: String, index: Int, pageCount: Int, ext: String) -> String {
        let width = max(Constants.minimumPageNumberWidth, String(pageCount).count)
        let number = String(index)
        let padded = String(repeating: "0", count: max(0, width - number.count)) + number
        return "\(base)-\(padded).\(ext)"
    }

    public static func unique(_ candidate: URL, fileManager: FileManager = .default) -> URL {
        guard fileManager.fileExists(atPath: candidate.path) else { return candidate }
        let directory = candidate.deletingLastPathComponent()
        let ext = candidate.pathExtension
        let stem = candidate.deletingPathExtension().lastPathComponent
        var n = 2
        while true {
            let name = ext.isEmpty ? "\(stem) \(n)" : "\(stem) \(n).\(ext)"
            let next = directory.appending(path: name)
            if !fileManager.fileExists(atPath: next.path) { return next }
            n += 1
        }
    }

    private static func sibling(of source: URL, suffix: String, ext: String) -> URL {
        let stem = source.deletingPathExtension().lastPathComponent
        let name = ext.isEmpty ? "\(stem)\(suffix)" : "\(stem)\(suffix).\(ext)"
        return unique(source.deletingLastPathComponent().appending(path: name))
    }
}

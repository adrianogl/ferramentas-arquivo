import Foundation

public struct SplitForm: Sendable, Equatable {
    public enum Choice: Sendable, Equatable {
        case allPages, extract
    }

    public let fileName: String
    public let pageCount: Int
    public var choice: Choice = .allPages
    public private(set) var rangeText = ""

    public init(fileName: String, pageCount: Int) {
        self.fileName = fileName
        self.pageCount = pageCount
    }

    public mutating func editRange(_ text: String) {
        rangeText = text
        choice = .extract
    }

    public var title: String {
        "Dividir \(fileName) (\(pageCount == 1 ? "1 página" : "\(pageCount) páginas"))"
    }

    public var allPagesCaption: String {
        let files = pageCount == 1 ? "1 PDF" : "\(pageCount) PDFs"
        return "\(files) na pasta \(baseName)\(Constants.Suffix.pagesFolder)"
    }

    public var extractCaption: String {
        "1 PDF com essas páginas: \(baseName)\(Constants.Suffix.extracted).pdf"
    }

    public var mode: SplitMode? {
        switch choice {
        case .allPages:
            return .allPages
        case .extract:
            guard case let .success(pages) = parsedRange else { return nil }
            return .extract(pages)
        }
    }

    public var rangeError: String? {
        guard choice == .extract, case let .failure(error) = parsedRange else { return nil }
        return error.message
    }

    public var canConfirm: Bool { mode != nil }

    private var parsedRange: Result<[Int], PageRangeError>? {
        guard !rangeText.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return PageRangeParser.parse(rangeText, pageCount: pageCount)
    }

    private var baseName: String {
        (fileName as NSString).deletingPathExtension
    }
}

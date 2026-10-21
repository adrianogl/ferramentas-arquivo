import Foundation

public struct RadialCoreText: Sendable, Equatable {
    public let title: String
    public let line: String
    public let hint: String
    public let isReason: Bool

    public init(title: String, line: String, hint: String, isReason: Bool) {
        self.title = title
        self.line = line
        self.hint = hint
        self.isReason = isReason
    }

    public static func make(
        hovered: ActionID?, availability: Availability, targets: [TargetInfo], limit: SizeLimit, running: ActionID?
    ) -> RadialCoreText {
        if let running {
            return RadialCoreText(
                title: Constants.descriptor(running).progressTitle, line: subject(targets), hint: "", isReason: false)
        }
        guard let hovered else { return idle(targets) }
        let title = Constants.descriptor(hovered).title
        let line = targetLine(for: hovered, targets: targets)
        if case .unavailable(let reason) = availability {
            return RadialCoreText(title: title, line: reason, hint: line, isReason: true)
        }
        return RadialCoreText(title: title, line: line, hint: hint(for: hovered, targets: targets, limit: limit), isReason: false)
    }

    private static func idle(_ targets: [TargetInfo]) -> RadialCoreText {
        guard targets.count == 1, let target = targets.first else {
            return RadialCoreText(
                title: files(targets.count), line: size(total(targets)), hint: Constants.CoreText.chooseAction, isReason: false)
        }
        var line = size(target.bytes)
        if target.kind == .pdf, let pages = target.pageCount, pages > 1 {
            line += " · \(pages) páginas"
        }
        return RadialCoreText(title: target.name, line: line, hint: Constants.CoreText.chooseAction, isReason: false)
    }

    private static func targetLine(for id: ActionID, targets: [TargetInfo]) -> String {
        guard targets.count == 1, let target = targets.first else {
            return "\(files(targets.count)) · \(size(total(targets)))"
        }
        if id == .splitPDF || id == .organizePDF, let pages = target.pageCount {
            return "\(target.name) · \(pages) \(pages == 1 ? "página" : "páginas")"
        }
        return "\(target.name) · \(size(target.bytes))"
    }

    private static func hint(for id: ActionID, targets: [TargetInfo], limit: SizeLimit) -> String {
        let limitText = size(limit.bytes)
        let pdfs = targets.filter { $0.kind == .pdf }
        let single = pdfs.count == 1 ? pdfs.first : nil
        switch id {
        case .optimizePDF:
            return "até \(limitText)"
        case .mergePDFs, .imagesToPDF:
            return "1 PDF até \(limitText)"
        case .splitPDF:
            return Constants.CoreText.opensOptions
        case .organizePDF:
            return Constants.CoreText.opensEditor
        case .pdfToJPG:
            guard let single, let pages = single.pageCount else { return Constants.CoreText.jpgPerPage }
            return pages == 1 ? "gera \(base(single.name)).jpg" : "gera \(pages) JPGs"
        case .pdfToMarkdown:
            guard let single else { return Constants.CoreText.markdownPerPDF }
            return "gera \(base(single.name)).md"
        }
    }

    private static func subject(_ targets: [TargetInfo]) -> String {
        targets.count == 1 ? targets[0].name : files(targets.count)
    }

    private static func files(_ count: Int) -> String {
        "\(count) arquivos"
    }

    private static func total(_ targets: [TargetInfo]) -> Int {
        targets.reduce(0) { $0 + $1.bytes }
    }

    private static func size(_ bytes: Int) -> String {
        ReportFormatter.format(bytes: bytes)
    }

    private static func base(_ name: String) -> String {
        (name as NSString).deletingPathExtension
    }
}

import AppKit
import Foundation
import PDFKit

public enum MarkdownConverter {
    private struct TextLine {
        var text: String
        var size: Double
        var isBold: Bool
    }

    private struct Link {
        var text: String
        var url: URL
    }

    private enum ListKind {
        case bullet, ordered
    }

    private enum Block {
        case heading(String)
        case list(ListKind, [String])
        case paragraph([String])

        var markdown: String {
            switch self {
            case .heading(let text): text
            case .list(_, let items): items.joined(separator: "\n")
            case .paragraph(let lines): lines.joined(separator: " ")
            }
        }
    }

    private nonisolated(unsafe) static let bulletPattern = /^\s*[•\-–*]\s+(.*)$/
    private nonisolated(unsafe) static let orderedPattern = /^\s*(\d+)[.)]\s+(.*)$/

    public static func convert(
        _ document: PDFDocument, ocr: (PDFPage) -> [String] = OCRRecognizer.lines
    ) -> MarkdownResult {
        let pages = (0..<document.pageCount).compactMap { document.page(at: $0) }
        let pageLines = pages.map { hasText($0) ? textLines($0) : nil }
        let body = bodySize(pageLines.compactMap { $0 }.flatMap { $0 })
        var blocks: [Block] = []
        var ocrPageCount = 0
        for (page, lines) in zip(pages, pageLines) {
            if let lines {
                blocks += pageBlocks(lines, body: body, links: links(on: page))
            } else {
                ocrPageCount += 1
                blocks += ocr(page)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .map { .paragraph([$0]) }
            }
        }
        let markdown = blocks.isEmpty ? "" : blocks.map(\.markdown).joined(separator: "\n\n") + "\n"
        return MarkdownResult(markdown: markdown, ocrPageCount: ocrPageCount)
    }

    private static func hasText(_ page: PDFPage) -> Bool {
        !(page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func pageBlocks(_ lines: [TextLine], body: Double, links: [Link]) -> [Block] {
        var blocks: [Block] = []
        var paragraph: [String] = []
        var list: (kind: ListKind, items: [String])?
        var pendingLinks = links

        func flush() {
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph)) }
            if let list { blocks.append(.list(list.kind, list.items)) }
            paragraph = []
            list = nil
        }

        func addItem(_ kind: ListKind, _ item: String) {
            if list?.kind != kind { flush() }
            if !paragraph.isEmpty { flush() }
            list = (kind, (list?.items ?? []) + [item])
        }

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else {
                flush()
                continue
            }
            let content = linked(text, &pendingLinks)
            if line.size >= body * Constants.Markdown.headingRatio {
                flush()
                blocks.append(.heading("# " + content))
            } else if line.size >= body * Constants.Markdown.subheadingRatio {
                flush()
                blocks.append(.heading("## " + content))
            } else if line.isBold, text.count <= Constants.Markdown.maxBoldHeadingLength, !text.hasSuffix(".") {
                flush()
                blocks.append(.heading("### " + content))
            } else if let match = content.wholeMatch(of: bulletPattern) {
                addItem(.bullet, "- " + match.1)
            } else if let match = content.wholeMatch(of: orderedPattern) {
                addItem(.ordered, "\(match.1). " + match.2)
            } else {
                if list != nil { flush() }
                paragraph.append(content)
            }
        }
        flush()
        return blocks
    }

    private static func linked(_ text: String, _ links: inout [Link]) -> String {
        guard let index = links.firstIndex(where: { text.contains($0.text) }) else { return text }
        let link = links.remove(at: index)
        guard let range = text.range(of: link.text) else { return text }
        return text.replacingCharacters(in: range, with: "[\(link.text)](\(link.url.absoluteString))")
    }

    private static func links(on page: PDFPage) -> [Link] {
        page.annotations.compactMap { annotation in
            guard annotation.type == PDFAnnotationSubtype.link.rawValue.trimmingCharacters(in: ["/"]),
                  let url = annotation.url,
                  let text = page.selection(for: annotation.bounds)?.string?
                      .trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty
            else { return nil }
            return Link(text: text, url: url)
        }
    }

    private static func textLines(_ page: PDFPage) -> [TextLine] {
        guard let attributed = page.attributedString else { return [] }
        let string = attributed.string as NSString
        var lines: [TextLine] = []
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length), options: .byLines
        ) { substring, range, _, _ in
            var size = 0.0
            var isBold = true
            var hasInk = false
            attributed.enumerateAttribute(.font, in: range) { value, runRange, _ in
                let run = string.substring(with: runRange)
                guard !run.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                hasInk = true
                guard let font = value as? NSFont else {
                    isBold = false
                    return
                }
                size = max(size, Double(font.pointSize))
                if !isBoldFont(font) { isBold = false }
            }
            lines.append(TextLine(text: substring ?? "", size: size, isBold: hasInk && isBold))
        }
        return lines
    }

    private static func isBoldFont(_ font: NSFont) -> Bool {
        font.fontDescriptor.symbolicTraits.contains(.bold) || font.fontName.contains("Bold")
    }

    private static func bodySize(_ lines: [TextLine]) -> Double {
        var weights: [Double: Int] = [:]
        for line in lines {
            let count = line.text.filter { !$0.isWhitespace }.count
            guard count > 0, line.size > 0 else { continue }
            weights[line.size, default: 0] += count
        }
        let total = weights.values.reduce(0, +)
        guard total > 0 else { return 0 }
        var cumulative = 0
        for (size, count) in weights.sorted(by: { $0.key < $1.key }) {
            cumulative += count
            if cumulative * 2 >= total { return size }
        }
        return 0
    }
}

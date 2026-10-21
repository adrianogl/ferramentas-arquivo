import Foundation
import PDFKit

public struct PDFToMarkdownAction: ImmediateAction {
    public let id = ActionID.pdfToMarkdown
    private let ocr: @Sendable (PDFPage) -> [String]

    public init() {
        self.init(ocr: { OCRRecognizer.lines(in: $0) })
    }

    init(ocr: @escaping @Sendable (PDFPage) -> [String]) {
        self.ocr = ocr
    }

    public func run(_ urls: [URL], limit: SizeLimit) -> ActionReport {
        var report = ActionReport()
        for url in naturalOrder(urls) where FileKind.of(url) == .pdf {
            do throws(ActionFailure) {
                report.outputs.append(try convert(url))
            } catch {
                report.failures.append(ActionReport.Failure(url: url, reason: error))
            }
        }
        return report
    }

    private func convert(_ url: URL) throws(ActionFailure) -> ActionReport.Output {
        let originalBytes = try ImagePageSource.fileSize(url)
        let document = try PDFReader.open(url)
        let result = MarkdownConverter.convert(document, ocr: ocr)
        guard !result.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw .noText }
        let data = Data(result.markdown.utf8)
        let destination = OutputNaming.markdown(for: url)
        try OutputWriter.write(data, to: destination)
        return ActionReport.Output(
            url: destination, sourceCount: 1, originalBytes: originalBytes, finalBytes: data.count,
            pageCount: document.pageCount, ocrPageCount: result.ocrPageCount
        )
    }
}

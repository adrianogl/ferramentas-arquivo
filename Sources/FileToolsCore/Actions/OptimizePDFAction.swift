import Foundation
import PDFKit

public struct OptimizePDFAction: ImmediateAction {
    public let id = ActionID.optimizePDF

    public init() {}

    public func run(_ urls: [URL], limit: SizeLimit) -> ActionReport {
        var report = ActionReport()
        for url in naturalOrder(urls) where FileKind.of(url) == .pdf {
            do {
                try optimize(url, limit: limit, into: &report)
            } catch {
                report.failures.append(ActionReport.Failure(url: url, reason: error))
            }
        }
        return report
    }

    private func optimize(_ url: URL, limit: SizeLimit, into report: inout ActionReport) throws(ActionFailure) {
        guard let data = try? Data(contentsOf: url) else { throw .unreadable }
        switch try PDFCompressor().compress(data, limit: limit) {
        case let .alreadyUnderLimit(bytes):
            report.untouched.append(ActionReport.Untouched(url: url, bytes: bytes))
        case let .compressed(output, originalBytes, _):
            let destination = OutputNaming.optimized(for: url)
            try OutputWriter.write(output, to: destination)
            report.outputs.append(ActionReport.Output(
                url: destination, sourceCount: 1, originalBytes: originalBytes, finalBytes: output.count,
                pageCount: PDFDocument(data: output)?.pageCount ?? 0
            ))
        case let .unreachable(smallestBytes):
            throw .unreachable(smallestBytes: smallestBytes)
        }
    }
}

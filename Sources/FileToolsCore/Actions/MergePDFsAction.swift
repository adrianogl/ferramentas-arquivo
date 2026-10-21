import Foundation
import PDFKit

public struct MergePDFsAction: ImmediateAction {
    public let id = ActionID.mergePDFs

    public init() {}

    public func run(_ urls: [URL], limit: SizeLimit) -> ActionReport {
        let files = naturalOrder(urls).filter { FileKind.of($0) != .unsupported }
        guard !files.isEmpty else { return ActionReport() }
        var documents: [PDFDocument] = []
        var sources: [PDFPageSource] = []
        var originalBytes = 0
        for url in files {
            do throws(ActionFailure) {
                originalBytes += try ImagePageSource.fileSize(url)
                if FileKind.of(url) == .pdf {
                    let document = try PDFReader.open(url)
                    documents.append(document)
                    for index in 0..<document.pageCount {
                        guard let page = document.page(at: index) else { throw .unreadable }
                        sources.append(.vector(page))
                    }
                } else {
                    sources.append(try ImagePageSource.make(url, quality: Constants.rasterLadder[0]))
                }
            } catch {
                return failed(url, error)
            }
        }
        return withExtendedLifetime(documents) {
            finish(sources, files: files, originalBytes: originalBytes, limit: limit)
        }
    }

    private func finish(
        _ sources: [PDFPageSource], files: [URL], originalBytes: Int, limit: SizeLimit
    ) -> ActionReport {
        let first = files[0]
        do throws(ActionFailure) {
            var data = try PDFAssembler.assemble(sources)
            if !limit.accepts(byteCount: data.count) {
                switch try PDFCompressor().compress(data, limit: limit) {
                case let .compressed(compressed, _, _): data = compressed
                case .alreadyUnderLimit: break
                case let .unreachable(smallestBytes): throw .unreachable(smallestBytes: smallestBytes)
                }
            }
            let destination = OutputNaming.merged(first: first)
            try OutputWriter.write(data, to: destination)
            return ActionReport(outputs: [ActionReport.Output(
                url: destination, sourceCount: files.count, originalBytes: originalBytes,
                finalBytes: data.count, pageCount: PDFDocument(data: data)?.pageCount ?? sources.count
            )])
        } catch {
            return failed(first, error)
        }
    }

    private func failed(_ url: URL, _ reason: ActionFailure) -> ActionReport {
        ActionReport(failures: [ActionReport.Failure(url: url, reason: reason)])
    }
}

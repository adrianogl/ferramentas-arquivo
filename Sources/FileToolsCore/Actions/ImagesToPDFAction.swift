import Foundation

public struct ImagesToPDFAction: ImmediateAction {
    public let id = ActionID.imagesToPDF
    private let ladder: [RasterQuality]

    public init(ladder: [RasterQuality] = Constants.rasterLadder) {
        self.ladder = ladder
    }

    public func run(_ urls: [URL], limit: SizeLimit) -> ActionReport {
        let images = naturalOrder(urls).filter { FileKind.of($0) == .image }
        guard let first = images.first else { return ActionReport() }
        var smallest = Int.max
        for quality in ladder {
            var sources: [PDFPageSource] = []
            for url in images {
                do {
                    sources.append(try ImagePageSource.make(url, quality: quality))
                } catch {
                    return failed(url, error)
                }
            }
            let data: Data
            do {
                data = try PDFAssembler.assemble(sources)
            } catch {
                return failed(first, error)
            }
            smallest = min(smallest, data.count)
            guard limit.accepts(byteCount: data.count) else { continue }
            return write(data, images: images)
        }
        return failed(first, .unreachable(smallestBytes: smallest))
    }

    private func write(_ data: Data, images: [URL]) -> ActionReport {
        let destination = OutputNaming.imagesPDF(firstImage: images[0])
        do throws(ActionFailure) {
            var originalBytes = 0
            for url in images { originalBytes += try ImagePageSource.fileSize(url) }
            try OutputWriter.write(data, to: destination)
            return ActionReport(outputs: [ActionReport.Output(
                url: destination, sourceCount: images.count, originalBytes: originalBytes,
                finalBytes: data.count, pageCount: images.count
            )])
        } catch {
            return failed(images[0], error)
        }
    }

    private func failed(_ url: URL, _ reason: ActionFailure) -> ActionReport {
        ActionReport(failures: [ActionReport.Failure(url: url, reason: reason)])
    }
}

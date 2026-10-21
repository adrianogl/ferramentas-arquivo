import Foundation
import PDFKit

public enum OrganizeExporter {
    public static func export(_ model: OrganizeModel, original: URL) -> ActionReport {
        do throws(ActionFailure) {
            guard model.canSave else { throw .unreadable }
            let originalBytes = try ImagePageSource.fileSize(original)
            var documents: [URL: PDFDocument] = [:]
            var sources: [PDFPageSource] = []
            for page in model.pages {
                switch page.source {
                case let .pdf(url, index):
                    let document: PDFDocument
                    if let cached = documents[url] {
                        document = cached
                    } else {
                        document = try PDFReader.open(url)
                        documents[url] = document
                    }
                    guard let pdfPage = document.page(at: index) else { throw .unreadable }
                    sources.append(.vector(pdfPage, extraRotation: page.rotation))
                case let .image(url):
                    let made = try ImagePageSource.make(url, quality: Constants.rasterLadder[0])
                    guard case let .image(image, pageSize, _) = made else { throw .unreadable }
                    sources.append(.image(image, pageSize: pageSize, rotation: page.rotation))
                }
            }
            let data = try withExtendedLifetime(documents) { () throws(ActionFailure) -> Data in
                try PDFAssembler.assemble(sources)
            }
            let destination = OutputNaming.organized(for: original)
            try OutputWriter.write(data, to: destination)
            return ActionReport(outputs: [ActionReport.Output(
                url: destination, sourceCount: 1, originalBytes: originalBytes,
                finalBytes: data.count, pageCount: model.pages.count
            )])
        } catch {
            return ActionReport(failures: [ActionReport.Failure(url: original, reason: error)])
        }
    }
}

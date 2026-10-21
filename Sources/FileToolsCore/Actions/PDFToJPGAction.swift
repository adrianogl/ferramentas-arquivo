import CoreGraphics
import Foundation
import PDFKit

public struct PDFToJPGAction: ImmediateAction {
    public let id = ActionID.pdfToJPG

    public init() {}

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
        let pageCount = document.pageCount
        guard pageCount > 0 else { throw .unreadable }
        if pageCount == 1 {
            let data = try encodePage(document, at: 0)
            let destination = OutputNaming.singleJPG(for: url)
            try OutputWriter.write(data, to: destination)
            return ActionReport.Output(
                url: destination, sourceCount: 1, originalBytes: originalBytes,
                finalBytes: data.count, pageCount: 1
            )
        }
        let folder = OutputNaming.pagesFolder(for: url)
        try OutputWriter.makeFolder(folder)
        let base = url.deletingPathExtension().lastPathComponent
        var total = 0
        do throws(ActionFailure) {
            for index in 0..<pageCount {
                let data = try encodePage(document, at: index)
                let name = OutputNaming.pageFileName(base: base, index: index + 1, pageCount: pageCount, ext: "jpg")
                try OutputWriter.write(data, to: folder.appending(path: name))
                total += data.count
            }
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
        return ActionReport.Output(
            url: folder, isFolder: true, sourceCount: 1, originalBytes: originalBytes,
            finalBytes: total, pageCount: pageCount
        )
    }

    private func encodePage(_ document: PDFDocument, at index: Int) throws(ActionFailure) -> Data {
        let quality = Constants.jpgExportQuality
        var result: Result<Data, ActionFailure> = .failure(.unreadable)
        autoreleasepool {
            guard let page = document.page(at: index),
                  let image = PageRasterizer.render(page, dpi: quality.dpi)
            else { return }
            do throws(ActionFailure) {
                result = .success(try JPEGEncoder.encode(image, quality: quality.jpegQuality))
            } catch {
                result = .failure(error)
            }
        }
        return try result.get()
    }
}

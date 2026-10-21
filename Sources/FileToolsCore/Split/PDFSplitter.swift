import Foundation
import PDFKit

public enum PDFSplitter {
    public static func split(_ url: URL, mode: SplitMode) -> ActionReport {
        do throws(ActionFailure) {
            let originalBytes = try ImagePageSource.fileSize(url)
            let document = try PDFReader.open(url)
            let output = try withExtendedLifetime(document) { () throws(ActionFailure) -> ActionReport.Output in
                switch mode {
                case .allPages:
                    try splitAll(document, source: url, originalBytes: originalBytes)
                case let .extract(pages):
                    try extract(pages, from: document, source: url, originalBytes: originalBytes)
                }
            }
            return ActionReport(outputs: [output])
        } catch {
            return ActionReport(failures: [ActionReport.Failure(url: url, reason: error)])
        }
    }

    private static func splitAll(
        _ document: PDFDocument, source: URL, originalBytes: Int
    ) throws(ActionFailure) -> ActionReport.Output {
        let pageCount = document.pageCount
        guard pageCount > 0 else { throw .unreadable }
        let folder = OutputNaming.pagesFolder(for: source)
        try OutputWriter.makeFolder(folder)
        let base = source.deletingPathExtension().lastPathComponent
        var total = 0
        do throws(ActionFailure) {
            for index in 0..<pageCount {
                let data = try assemble([index], from: document)
                let name = OutputNaming.pageFileName(base: base, index: index + 1, pageCount: pageCount, ext: "pdf")
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

    private static func extract(
        _ pages: [Int], from document: PDFDocument, source: URL, originalBytes: Int
    ) throws(ActionFailure) -> ActionReport.Output {
        guard !pages.isEmpty, pages.allSatisfy({ $0 >= 1 && $0 <= document.pageCount }) else {
            throw .unreadable
        }
        let data = try assemble(pages.map { $0 - 1 }, from: document)
        let destination = OutputNaming.extracted(for: source)
        try OutputWriter.write(data, to: destination)
        return ActionReport.Output(
            url: destination, sourceCount: 1, originalBytes: originalBytes,
            finalBytes: data.count, pageCount: pages.count
        )
    }

    private static func assemble(_ indexes: [Int], from document: PDFDocument) throws(ActionFailure) -> Data {
        var sources: [PDFPageSource] = []
        for index in indexes {
            guard let page = document.page(at: index) else { throw .unreadable }
            sources.append(.vector(page))
        }
        return try PDFAssembler.assemble(sources)
    }
}

import AppKit
import FileToolsCore
import PDFKit

@MainActor
final class ThumbnailCache {
    private var images: [UUID: CGImage] = [:]
    private let renderer = ThumbnailRenderer()

    func cached(_ id: UUID) -> CGImage? {
        images[id]
    }

    func load(_ page: OrganizePage) async -> CGImage? {
        if let image = images[page.id] { return image }
        guard let image = await renderer.render(page.source) else { return nil }
        images[page.id] = image
        return image
    }
}

private actor ThumbnailRenderer {
    private var documents: [URL: PDFDocument] = [:]

    func render(_ source: OrganizePage.Source) -> CGImage? {
        guard !Task.isCancelled else { return nil }
        switch source {
        case let .pdf(url, index):
            guard let page = document(at: url)?.page(at: index) else { return nil }
            return page.thumbnail(of: AppConstants.Organize.thumbnailSize, for: .cropBox)
                .cgImage(forProposedRect: nil, context: nil, hints: nil)
        case let .image(url):
            return try? ImageLoader.load(url, maxPixelSize: AppConstants.Organize.thumbnailMaxPixelSize)
        }
    }

    private func document(at url: URL) -> PDFDocument? {
        if let document = documents[url] { return document }
        let document = try? PDFReader.open(url)
        documents[url] = document
        return document
    }
}

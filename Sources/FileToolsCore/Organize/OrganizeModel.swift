import Foundation

public struct OrganizeModel: Sendable, Equatable {
    public private(set) var pages: [OrganizePage]

    public init(pdf: URL) throws(ActionFailure) {
        pages = try Self.pages(ofPDF: pdf)
    }

    public var canSave: Bool { !pages.isEmpty }

    public mutating func move(_ ids: Set<UUID>, to index: Int) {
        let clamped = min(max(index, 0), pages.count)
        let movedBeforeTarget = pages[..<clamped].filter { ids.contains($0.id) }.count
        let moved = pages.filter { ids.contains($0.id) }
        guard !moved.isEmpty else { return }
        var remaining = pages.filter { !ids.contains($0.id) }
        remaining.insert(contentsOf: moved, at: clamped - movedBeforeTarget)
        pages = remaining
    }

    public func dropIndex(moving ids: Set<UUID>, onto target: UUID) -> Int? {
        guard !ids.contains(target),
              let targetIndex = pages.firstIndex(where: { $0.id == target }),
              let firstMoved = pages.firstIndex(where: { ids.contains($0.id) })
        else { return nil }
        return firstMoved < targetIndex ? targetIndex + 1 : targetIndex
    }

    public mutating func delete(_ ids: Set<UUID>) {
        pages.removeAll { ids.contains($0.id) }
    }

    public mutating func rotate(_ ids: Set<UUID>, by degrees: Int) {
        for index in pages.indices where ids.contains(pages[index].id) {
            pages[index].rotation = ((pages[index].rotation + degrees) % 360 + 360) % 360
        }
    }

    public mutating func append(_ url: URL) throws(ActionFailure) {
        switch FileKind.of(url) {
        case .pdf:
            pages.append(contentsOf: try Self.pages(ofPDF: url))
        case .image:
            _ = try ImageLoader.load(url, maxPixelSize: 1)
            pages.append(OrganizePage(source: .image(url)))
        case .unsupported:
            throw .unreadable
        }
    }

    private static func pages(ofPDF url: URL) throws(ActionFailure) -> [OrganizePage] {
        let document = try PDFReader.open(url)
        return (0..<document.pageCount).map { OrganizePage(source: .pdf(url, index: $0)) }
    }
}

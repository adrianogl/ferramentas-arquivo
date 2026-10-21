import AppKit
import FileToolsCore
import Observation

@MainActor
@Observable
final class OrganizeViewModel {
    let original: URL
    private(set) var model: OrganizeModel
    private(set) var selection = PageSelection()
    var isSaving = false
    @ObservationIgnored let thumbnails = ThumbnailCache()
    @ObservationIgnored var undoManager: UndoManager?
    @ObservationIgnored var onAdd: (() -> Void)?
    @ObservationIgnored var onSave: (() -> Void)?
    @ObservationIgnored var onAppendFailures: (([ActionReport.Failure]) -> Void)?
    private var savedModel: OrganizeModel

    init(original: URL) throws(ActionFailure) {
        self.original = original
        let model = try OrganizeModel(pdf: original)
        self.model = model
        savedModel = model
    }

    var hasUnsavedChanges: Bool { model != savedModel }
    var canSave: Bool { model.canSave && !isSaving }
    var hasSelection: Bool { !selection.ids.isEmpty }
    var canEditSelection: Bool { hasSelection && !isSaving }

    func click(_ id: UUID, gesture: PageSelection.Gesture) {
        selection.click(id, gesture: gesture, order: model.pages.map(\.id))
    }

    func clearSelection() {
        selection.clear()
    }

    func deleteSelection() {
        guard hasSelection else { return }
        var next = model
        next.delete(selection.ids)
        apply(next, actionName: "Apagar páginas")
    }

    func rotateSelection(by degrees: Int) {
        guard hasSelection else { return }
        var next = model
        next.rotate(selection.ids, by: degrees)
        apply(next, actionName: "Girar páginas")
    }

    func drop(_ items: [String], onto target: UUID) -> Bool {
        guard !isSaving else { return false }
        if let dragged = items.lazy.compactMap(UUID.init(uuidString:)).first {
            return move(dragged, onto: target)
        }
        let urls = items.compactMap(Self.fileURL)
        guard !urls.isEmpty else { return false }
        append(urls)
        return true
    }

    func append(_ urls: [URL]) {
        guard !isSaving else { return }
        var next = model
        var failures: [ActionReport.Failure] = []
        for url in urls {
            do throws(ActionFailure) {
                try next.append(url)
            } catch {
                failures.append(ActionReport.Failure(url: url, reason: error))
            }
        }
        apply(next, actionName: "Adicionar páginas")
        if !failures.isEmpty { onAppendFailures?(failures) }
    }

    func markSaved(_ snapshot: OrganizeModel) {
        savedModel = snapshot
    }

    private func move(_ dragged: UUID, onto target: UUID) -> Bool {
        let ids = selection.ids.contains(dragged) ? selection.ids : [dragged]
        guard let index = model.dropIndex(moving: ids, onto: target) else { return false }
        if !selection.ids.contains(dragged) { selection.replace(with: dragged) }
        var next = model
        next.move(ids, to: index)
        apply(next, actionName: "Mover páginas")
        return true
    }

    private func apply(_ next: OrganizeModel, actionName: String) {
        let previous = model
        guard !isSaving, next != previous else { return }
        model = next
        selection.prune(to: next.pages.map(\.id))
        undoManager?.registerUndo(withTarget: self) { target in
            target.apply(previous, actionName: actionName)
        }
        undoManager?.setActionName(actionName)
    }

    private static func fileURL(_ text: String) -> URL? {
        if text.hasPrefix("file://") { return URL(string: text) }
        if text.hasPrefix("/") { return URL(fileURLWithPath: text) }
        return nil
    }
}

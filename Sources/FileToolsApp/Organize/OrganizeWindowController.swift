import AppKit
import FileToolsCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class OrganizeWindowController: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let url: URL
    private let coordinator: ActionCoordinator
    private let viewModel: OrganizeViewModel
    private let undoManager = UndoManager()
    private var window: NSWindow?
    private var keyMonitor: Any?

    init(url: URL, coordinator: ActionCoordinator) throws(ActionFailure) {
        self.url = url
        self.coordinator = coordinator
        viewModel = try OrganizeViewModel(original: url)
        super.init()
        viewModel.undoManager = undoManager
        viewModel.onAdd = { [weak self] in self?.add() }
        viewModel.onSave = { [weak self] in self?.save() }
        viewModel.onAppendFailures = { [weak self] in self?.showFailures($0) }
    }

    func show() {
        let window = window ?? makeWindow()
        if self.window == nil {
            self.window = window
            window.center()
            installKeyMonitor()
            Log.app.info("organizar aberto: \(self.viewModel.model.pages.count) páginas")
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        undoManager
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard viewModel.hasUnsavedChanges else { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Descartar alterações?"
        let discard = alert.addButton(withTitle: "Descartar")
        discard.hasDestructiveAction = true
        discard.keyEquivalent = ""
        let cancel = alert.addButton(withTitle: "Cancelar")
        cancel.keyEquivalent = "\r"
        alert.beginSheetModal(for: sender) { response in
            guard response == .alertFirstButtonReturn else { return }
            sender.close()
        }
        return false
    }

    func windowWillClose(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        undoManager.removeAllActions()
        window?.delegate = nil
        window = nil
        onClose?()
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: OrganizeView(viewModel: viewModel))
        hosting.sizingOptions = []
        hosting.sceneBridgingOptions = [.toolbars]
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = OrganizeText.title(for: url)
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.contentMinSize = AppConstants.Organize.minimumWindowSize
        window.setContentSize(AppConstants.Organize.windowSize)
        window.delegate = self
        return window
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated { self?.handleKey(event) ?? false }
            return handled ? nil : event
        }
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard let window, event.window === window, window.attachedSheet == nil else { return false }
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased()
        switch (event.keyCode, flags) {
        case (AppConstants.Organize.deleteKeyCode, []), (AppConstants.Organize.forwardDeleteKeyCode, []):
            viewModel.deleteSelection()
        case (AppConstants.Organize.leftArrowKeyCode, .command):
            viewModel.rotateSelection(by: -AppConstants.Organize.rotationStep)
        case (AppConstants.Organize.rightArrowKeyCode, .command):
            viewModel.rotateSelection(by: AppConstants.Organize.rotationStep)
        case (_, .command) where key == "s":
            save()
        case (_, .command) where key == "z":
            undoManager.undo()
        case (_, [.command, .shift]) where key == "z":
            undoManager.redo()
        default:
            return false
        }
        return true
    }

    private func add() {
        guard let window else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { [weak self, panel] response in
            guard response == .OK else { return }
            self?.viewModel.append(panel.urls)
        }
    }

    private func save() {
        guard viewModel.canSave else { return }
        viewModel.isSaving = true
        let snapshot = viewModel.model
        let original = url
        Task {
            let report = await Task.detached(priority: .userInitiated) {
                OrganizeExporter.export(snapshot, original: original)
            }.value
            coordinator.deliver(report, action: .organizePDF)
            viewModel.isSaving = false
            guard !report.outputs.isEmpty else { return }
            viewModel.markSaved(snapshot)
            window?.close()
        }
    }

    private func showFailures(_ failures: [ActionReport.Failure]) {
        let messages = coordinator.messages(for: ActionReport(failures: failures), action: .organizePDF)
        guard let first = messages.first else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = first.title
        alert.informativeText = messages.map(\.body).joined(separator: "\n")
        alert.addButton(withTitle: "OK")
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

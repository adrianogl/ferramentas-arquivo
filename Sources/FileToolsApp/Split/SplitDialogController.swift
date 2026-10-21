import AppKit
import FileToolsCore
import SwiftUI

@MainActor
final class SplitDialogController: NSObject, NSWindowDelegate {
    private let coordinator: ActionCoordinator
    private var panel: NSPanel?

    init(coordinator: ActionCoordinator) {
        self.coordinator = coordinator
    }

    func present(for url: URL, pageCount: Int, near cgPoint: CGPoint?) {
        dismiss()
        let form = SplitForm(fileName: url.lastPathComponent, pageCount: pageCount)
        let view = SplitDialogView(
            form: form,
            onCancel: { [weak self] in self?.dismiss() },
            onConfirm: { [weak self] mode in self?.confirm(url, mode: mode) })
        let panel = makePanel(title: form.title, content: view)
        self.panel = panel
        if let cgPoint {
            panel.setFrame(ScreenPlacement.frame(size: panel.frame.size, centeredAt: cgPoint), display: false)
        } else {
            panel.center()
        }
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        Log.app.info("dividir aberto: \(pageCount) páginas")
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSPanel) === panel else { return }
        panel = nil
    }

    private func confirm(_ url: URL, mode: SplitMode) {
        guard panel != nil else { return }
        dismiss()
        Task { [coordinator] in
            let report = await Task.detached(priority: .userInitiated) {
                PDFSplitter.split(url, mode: mode)
            }.value
            coordinator.deliver(report, action: .splitPDF)
        }
    }

    private func dismiss() {
        guard let panel else { return }
        self.panel = nil
        panel.close()
    }

    private func makePanel(title: String, content: SplitDialogView) -> NSPanel {
        let hosting = NSHostingView(rootView: content)
        let size = hosting.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        panel.title = title
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.delegate = self
        panel.contentView = hosting
        return panel
    }
}

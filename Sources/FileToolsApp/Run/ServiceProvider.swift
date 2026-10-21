import AppKit
import FileToolsCore

@MainActor
final class ServiceProvider: NSObject {
    private let coordinator: ActionCoordinator

    init(coordinator: ActionCoordinator) {
        self.coordinator = coordinator
    }

    @objc func optimizePDF(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.optimizePDF, pboard)
    }

    @objc func mergePDFs(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.mergePDFs, pboard)
    }

    @objc func splitPDF(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.splitPDF, pboard)
    }

    @objc func organizePDF(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.organizePDF, pboard)
    }

    @objc func imagesToPDF(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.imagesToPDF, pboard)
    }

    @objc func pdfToJPG(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.pdfToJPG, pboard)
    }

    @objc func pdfToMarkdown(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        handle(.pdfToMarkdown, pboard)
    }

    private func handle(_ id: ActionID, _ pboard: NSPasteboard) {
        let urls = (pboard.readObjects(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []
        guard !urls.isEmpty else { return }
        Task { await coordinator.run(id, urls: urls, near: nil) }
    }
}

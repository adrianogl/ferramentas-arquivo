import AppKit
import FileToolsCore

@MainActor
final class ActionCoordinator {
    private let settings: SettingsStore
    private let notifier: Notifier
    var presentSplit: ((URL, Int, CGPoint?) -> Void)?
    var presentOrganize: ((URL) -> Void)?

    init(settings: SettingsStore, notifier: Notifier) {
        self.settings = settings
        self.notifier = notifier
    }

    func run(_ id: ActionID, urls: [URL], near point: CGPoint?) async {
        if case .unavailable(let reason) = ActionAvailability.availability(of: id, for: urls) {
            Log.app.info("\(id.rawValue, privacy: .public) indisponível: \(reason, privacy: .public)")
            return
        }
        switch Constants.descriptor(id).interaction {
        case .immediate:
            guard let action = ActionCatalog.immediate(id) else { return }
            let limit = settings.sizeLimit
            let report = await Task.detached(priority: .userInitiated) {
                action.run(urls, limit: limit)
            }.value
            deliver(report, action: id)
        case .splitDialog:
            guard let present = presentSplit, let url = urls.first,
                let pageCount = (try? PDFReader.open(url))?.pageCount
            else {
                Log.app.info("dividir sem apresentação disponível")
                return
            }
            present(url, pageCount, point)
        case .organizeWindow:
            guard let present = presentOrganize, let url = urls.first else {
                Log.app.info("organizar sem apresentação disponível")
                return
            }
            present(url)
        }
    }

    func deliver(_ report: ActionReport, action: ActionID) {
        notifier.post(ReportFormatter.messages(for: report, action: action, limit: settings.sizeLimit))
        guard !report.outputs.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(report.outputs.map(\.url))
    }
}

enum ActionCatalog {
    static func immediate(_ id: ActionID) -> (any ImmediateAction)? {
        switch id {
        case .optimizePDF: OptimizePDFAction()
        case .mergePDFs: MergePDFsAction()
        case .imagesToPDF: ImagesToPDFAction()
        case .pdfToJPG: PDFToJPGAction()
        case .pdfToMarkdown: PDFToMarkdownAction()
        case .splitPDF, .organizePDF: nil
        }
    }
}

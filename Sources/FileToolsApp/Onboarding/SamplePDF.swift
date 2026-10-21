import AppKit
import CoreText

@MainActor
enum SamplePDF {
    static var url: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(AppConstants.Onboarding.sampleFolderName, isDirectory: true)
            .appendingPathComponent(AppConstants.Onboarding.sampleFileName)
    }

    static func make() throws -> URL {
        let url = url
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var mediaBox = CGRect(origin: .zero, size: AppConstants.Onboarding.samplePageSize)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        context.beginPDFPage(nil)
        drawText(in: context, page: mediaBox)
        context.endPDFPage()
        context.closePDF()
        return url
    }

    static func reveal() throws {
        NSWorkspace.shared.activateFileViewerSelecting([try make()])
    }

    static func matches(_ targets: [URL]) -> Bool {
        let key = normalizedPath(url)
        return targets.contains { normalizedPath($0) == key }
    }

    private static func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path.precomposedStringWithCanonicalMapping
    }

    private static func drawText(in context: CGContext, page: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let text = NSAttributedString(string: AppConstants.Onboarding.sampleText, attributes: [
            .font: NSFont.systemFont(ofSize: AppConstants.Onboarding.sampleFontSize, weight: .bold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph,
        ])
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let width = page.width - 2 * AppConstants.Onboarding.sampleTextInset
        let fitted = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRange(), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
        let box = CGRect(
            x: AppConstants.Onboarding.sampleTextInset,
            y: (page.height - fitted.height) / 2,
            width: width,
            height: ceil(fitted.height))
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: box, transform: nil), nil)
        CTFrameDraw(frame, context)
    }
}

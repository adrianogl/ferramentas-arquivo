import Foundation
import PDFKit
import Vision

public enum OCRRecognizer {
    public static func lines(in page: PDFPage) -> [String] {
        autoreleasepool {
            guard let image = PageRasterizer.render(page, dpi: Constants.Markdown.ocrDPI) else { return [] }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = Constants.Markdown.ocrLanguages
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
            } catch {
                return []
            }
            return (request.results ?? [])
                .sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                .compactMap { $0.topCandidates(1).first?.string }
        }
    }
}

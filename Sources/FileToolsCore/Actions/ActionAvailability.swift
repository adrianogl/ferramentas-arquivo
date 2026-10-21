import Foundation
import PDFKit

public enum ActionAvailability {
    public static func availability(
        of id: ActionID,
        for urls: [URL],
        pageCount: (URL) -> Int? = { (try? PDFReader.open($0))?.pageCount }
    ) -> Availability {
        let kinds = urls.map(FileKind.of)
        switch id {
        case .optimizePDF, .pdfToJPG, .pdfToMarkdown:
            return kinds.contains(.pdf) ? .available : .unavailable(reason: Constants.Reason.pdfOnly)
        case .mergePDFs:
            if urls.count < 2 { return .unavailable(reason: Constants.Reason.selectTwoOrMore) }
            return kinds.allSatisfy { $0 != .unsupported }
                ? .available : .unavailable(reason: Constants.Reason.pdfsAndImagesOnly)
        case .splitPDF:
            guard urls.count == 1, kinds[0] == .pdf else {
                return .unavailable(reason: Constants.Reason.selectOnePDF)
            }
            return (pageCount(urls[0]) ?? 0) > 1
                ? .available : .unavailable(reason: Constants.Reason.singlePage)
        case .organizePDF:
            return urls.count == 1 && kinds[0] == .pdf
                ? .available : .unavailable(reason: Constants.Reason.selectOnePDF)
        case .imagesToPDF:
            return !urls.isEmpty && kinds.allSatisfy { $0 == .image }
                ? .available : .unavailable(reason: Constants.Reason.imagesOnly)
        }
    }
}

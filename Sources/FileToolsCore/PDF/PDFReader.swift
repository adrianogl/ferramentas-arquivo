import Foundation
import PDFKit

public enum PDFReader {
    public static func open(_ data: Data) throws(ActionFailure) -> PDFDocument {
        guard let document = PDFDocument(data: data) else { throw .unreadable }
        return try validated(document)
    }

    public static func open(_ url: URL) throws(ActionFailure) -> PDFDocument {
        guard let document = PDFDocument(url: url) else { throw .unreadable }
        return try validated(document)
    }

    private static func validated(_ document: PDFDocument) throws(ActionFailure) -> PDFDocument {
        if document.isLocked, !document.unlock(withPassword: "") { throw .encrypted }
        return document
    }
}

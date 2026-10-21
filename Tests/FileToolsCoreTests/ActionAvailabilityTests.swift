import Foundation
import Testing
@testable import FileToolsCore

struct ActionAvailabilityTests {
    private let pdfA: URL
    private let pdfB: URL
    private let imageA: URL
    private let imageB: URL
    private let text: URL

    init() throws {
        let dir = try Fixtures.tempDirectory()
        pdfA = try Fixtures.write(Fixtures.textPDF(["a"]), named: "a.pdf", in: dir)
        pdfB = try Fixtures.write(Fixtures.textPDF(["b"]), named: "b.pdf", in: dir)
        imageA = dir.appending(path: "a.png")
        imageB = dir.appending(path: "b.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 8, height: 8), to: imageA, type: .png)
        try Fixtures.writeImage(Fixtures.noiseImage(width: 8, height: 8), to: imageB, type: .png)
        text = try Fixtures.write(Data("oi".utf8), named: "a.txt", in: dir)
    }

    private func check(_ id: ActionID, _ urls: [URL], pages: Int = 8) -> Availability {
        ActionAvailability.availability(of: id, for: urls, pageCount: { _ in pages })
    }

    private func unavailable(_ reason: String) -> Availability {
        .unavailable(reason: reason)
    }

    @Test(arguments: [ActionID.optimizePDF, .pdfToJPG, .pdfToMarkdown])
    func pdfActions(id: ActionID) {
        #expect(check(id, [pdfA]) == .available)
        #expect(check(id, [pdfA, imageA]) == .available)
        #expect(check(id, [imageA]) == unavailable("só para PDF"))
        #expect(check(id, [text]) == unavailable("só para PDF"))
        #expect(check(id, []) == unavailable("só para PDF"))
    }

    @Test func merge() {
        #expect(check(.mergePDFs, [pdfA, pdfB]) == .available)
        #expect(check(.mergePDFs, [pdfA, imageA]) == .available)
        #expect(check(.mergePDFs, [imageA, imageB]) == .available)
        #expect(check(.mergePDFs, [pdfA]) == unavailable("selecione 2 ou mais"))
        #expect(check(.mergePDFs, []) == unavailable("selecione 2 ou mais"))
        #expect(check(.mergePDFs, [pdfA, text]) == unavailable("só PDFs e imagens"))
    }

    @Test func split() {
        #expect(check(.splitPDF, [pdfA], pages: 8) == .available)
        #expect(check(.splitPDF, [pdfA], pages: 1) == unavailable("o PDF tem só 1 página"))
        #expect(check(.splitPDF, [pdfA, pdfB]) == unavailable("selecione 1 PDF"))
        #expect(check(.splitPDF, [imageA]) == unavailable("selecione 1 PDF"))
        #expect(check(.splitPDF, []) == unavailable("selecione 1 PDF"))
    }

    @Test func organize() {
        #expect(check(.organizePDF, [pdfA]) == .available)
        #expect(check(.organizePDF, [pdfA, pdfB]) == unavailable("selecione 1 PDF"))
        #expect(check(.organizePDF, [imageA]) == unavailable("selecione 1 PDF"))
        #expect(check(.organizePDF, []) == unavailable("selecione 1 PDF"))
    }

    @Test func imagesToPDF() {
        #expect(check(.imagesToPDF, [imageA]) == .available)
        #expect(check(.imagesToPDF, [imageA, imageB]) == .available)
        #expect(check(.imagesToPDF, [imageA, pdfA]) == unavailable("só para imagens"))
        #expect(check(.imagesToPDF, [pdfA]) == unavailable("só para imagens"))
        #expect(check(.imagesToPDF, []) == unavailable("só para imagens"))
    }

    @Test func defaultPageCountReadsRealPDF() {
        #expect(ActionAvailability.availability(of: .splitPDF, for: [pdfA]) == unavailable("o PDF tem só 1 página"))
    }

    @Test func descriptorsFollowSlotOrder() {
        #expect(Constants.actions.map(\.slot) == Array(0..<7))
        #expect(Constants.actions.map(\.id) == ActionID.allCases)
        #expect(Constants.descriptor(.splitPDF).interaction == .splitDialog)
        #expect(Constants.descriptor(.organizePDF).interaction == .organizeWindow)
        #expect(Constants.descriptor(.pdfToMarkdown).colorHex == "#22b8b0")
    }
}

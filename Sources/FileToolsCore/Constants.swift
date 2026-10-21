import CoreGraphics
import Foundation

public enum Constants {
    static let bytesPerMegabyte = 1_000_000.0
    static let defaultLimitMegabytes = 1.0
    static let limitMegabytesRange = 0.1...100.0
    static let minimumPageNumberWidth = 2
    static let normalWindowLayer = 0
    public static let imagePageLongSide: CGFloat = 842
    public static let jpgExportQuality = RasterQuality(dpi: 150, jpegQuality: 0.85)
    public static let rasterLadder = [
        RasterQuality(dpi: 200, jpegQuality: 0.80),
        RasterQuality(dpi: 150, jpegQuality: 0.70),
        RasterQuality(dpi: 150, jpegQuality: 0.55),
        RasterQuality(dpi: 120, jpegQuality: 0.50),
        RasterQuality(dpi: 100, jpegQuality: 0.45),
    ]

    public static let vacancySymbol = "plus"
    public static let vacancyColorHex = "#8e8e93"

    public static let actions: [ActionDescriptor] = [
        ActionDescriptor(
            id: .optimizePDF, title: "Otimizar PDF", shortLabel: "Otimizar", symbol: "arrow.down.doc",
            colorHex: "#ff5a5f", slot: 0, interaction: .immediate, progressTitle: "Otimizando…"),
        ActionDescriptor(
            id: .mergePDFs, title: "Juntar PDFs", shortLabel: "Juntar", symbol: "doc.on.doc",
            colorHex: "#2f8cff", slot: 1, interaction: .immediate, progressTitle: "Juntando…"),
        ActionDescriptor(
            id: .splitPDF, title: "Dividir PDF", shortLabel: "Dividir", symbol: "scissors",
            colorHex: "#ff9f0a", slot: 2, interaction: .splitDialog, progressTitle: "Dividindo…"),
        ActionDescriptor(
            id: .organizePDF, title: "Organizar PDF", shortLabel: "Organizar", symbol: "square.grid.2x2",
            colorHex: "#a970ff", slot: 3, interaction: .organizeWindow, progressTitle: "Abrindo…"),
        ActionDescriptor(
            id: .imagesToPDF, title: "Imagens para PDF", shortLabel: "Imagens→PDF", symbol: "photo.on.rectangle",
            colorHex: "#2fbf71", slot: 4, interaction: .immediate, progressTitle: "Gerando PDF…"),
        ActionDescriptor(
            id: .pdfToJPG, title: "PDF para JPG", shortLabel: "PDF→JPG", symbol: "photo",
            colorHex: "#e0a800", slot: 5, interaction: .immediate, progressTitle: "Convertendo…"),
        ActionDescriptor(
            id: .pdfToMarkdown, title: "PDF para Markdown", shortLabel: "Markdown", symbol: "doc.plaintext",
            colorHex: "#22b8b0", slot: 6, interaction: .immediate, progressTitle: "Extraindo texto…"),
    ]

    public static func descriptor(_ id: ActionID) -> ActionDescriptor {
        actions.first { $0.id == id }!
    }

    enum Reason {
        static let pdfOnly = "só para PDF"
        static let selectTwoOrMore = "selecione 2 ou mais"
        static let pdfsAndImagesOnly = "só PDFs e imagens"
        static let selectOnePDF = "selecione 1 PDF"
        static let singlePage = "o PDF tem só 1 página"
        static let imagesOnly = "só para imagens"
    }

    enum Suffix {
        static let optimized = "-otimizado"
        static let merged = "-juntado"
        static let extracted = "-extraido"
        static let organized = "-organizado"
        static let pagesFolder = "-paginas"
    }

    enum Markdown {
        static let headingRatio = 1.6
        static let subheadingRatio = 1.2
        static let maxBoldHeadingLength = 80
        static let ocrDPI = 200.0
        static let ocrLanguages = ["pt-BR", "en-US"]
    }

    enum SettingsKey {
        static let limitMegabytes = "limitMegabytes"
        static let triggerModifier = "triggerModifier"
        static let launchAtLogin = "launchAtLogin"
        static let onboardingCompleted = "onboardingCompleted"
    }
}

import Foundation

public enum ReportFormatter {
    public static func messages(for report: ActionReport, action: ActionID, limit: SizeLimit) -> [UserMessage] {
        let limitText = format(bytes: limit.bytes)
        var result = report.outputs.map { output(for: $0, action: action, limitText: limitText) }
        result += report.untouched.map { item in
            UserMessage(
                title: "\(item.url.lastPathComponent) já está ok",
                body: "\(format(bytes: item.bytes)), abaixo de \(limitText). Nenhum arquivo novo foi criado.",
                isError: false
            )
        }
        result += report.failures.map { failure(for: $0, limitText: limitText) }
        return result
    }

    public static func format(bytes: Int) -> String {
        guard bytes >= 1_000_000 else {
            return "\(Int((Double(bytes) / 1000).rounded())) KB"
        }
        let megabytes = (Double(bytes) / 1_000_000 * 10).rounded() / 10
        if megabytes == megabytes.rounded() {
            return "\(Int(megabytes)) MB"
        }
        return String(format: "%.1f", megabytes).replacingOccurrences(of: ".", with: ",") + " MB"
    }

    private static func output(for output: ActionReport.Output, action: ActionID, limitText: String) -> UserMessage {
        let sizes = "\(format(bytes: output.originalBytes)) → \(format(bytes: output.finalBytes)) · abaixo do limite de \(limitText)"
        let body: String
        switch action {
        case .optimizePDF:
            body = sizes
        case .imagesToPDF:
            body = "\(count(output.sourceCount, "imagem", "imagens")) · \(sizes)"
        case .mergePDFs:
            body = "\(count(output.sourceCount, "arquivo", "arquivos")) · \(sizes)"
        case .pdfToJPG:
            body = output.pageCount == 1
                ? "1 página convertida em JPG" : "\(output.pageCount) páginas convertidas em JPG"
        case .pdfToMarkdown:
            let text = output.pageCount == 1 ? "Texto de 1 página" : "Texto de \(output.pageCount) páginas"
            body = output.ocrPageCount > 0 ? "\(text) (\(output.ocrPageCount) com OCR)" : text
        case .splitPDF:
            if output.isFolder {
                body = "\(output.pageCount) PDFs, um por página"
            } else {
                body = output.pageCount == 1 ? "1 página extraída" : "\(output.pageCount) páginas extraídas"
            }
        case .organizePDF:
            body = output.pageCount == 1 ? "1 página salva" : "\(output.pageCount) páginas salvas"
        }
        return UserMessage(title: output.url.lastPathComponent, body: body, isError: false)
    }

    private static func failure(for failure: ActionReport.Failure, limitText: String) -> UserMessage {
        let name = failure.url.lastPathComponent
        switch failure.reason {
        case .unreachable(let smallestBytes):
            return UserMessage(
                title: "Não deu para chegar a \(limitText)",
                body: "\(name) ficou com \(format(bytes: smallestBytes)) na menor qualidade legível. O original não foi alterado.",
                isError: true
            )
        case .encrypted:
            return UserMessage(
                title: "PDF protegido por senha",
                body: "\(name) tem senha. Remova a senha no Preview e tente de novo.",
                isError: true
            )
        case .unreadable:
            return UserMessage(
                title: "Não deu para abrir o arquivo",
                body: "\(name) está corrompido ou num formato que o app não lê.",
                isError: true
            )
        case .writeFailed:
            return UserMessage(
                title: "Não deu para salvar",
                body: "Sem permissão para gravar na pasta de \(name). Copie o arquivo para outra pasta e tente de novo.",
                isError: true
            )
        case .noText:
            return UserMessage(
                title: "Nenhum texto encontrado",
                body: "\(name) não tem texto, nem com OCR. Nenhum arquivo foi criado.",
                isError: true
            )
        }
    }

    private static func count(_ n: Int, _ singular: String, _ plural: String) -> String {
        n == 1 ? "1 \(singular)" : "\(n) \(plural)"
    }
}

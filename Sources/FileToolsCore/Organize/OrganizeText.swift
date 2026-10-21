import Foundation

public enum OrganizeText {
    public static func title(for original: URL) -> String {
        "Organizar \(original.lastPathComponent)"
    }

    public static func status(pageCount: Int, selectedCount: Int) -> String {
        let pages = pageCount == 1 ? "1 página" : "\(pageCount) páginas"
        let selected = selectedCount == 1 ? "1 selecionada" : "\(selectedCount) selecionadas"
        return "\(pages) · \(selected)"
    }

    public static func saveHint(for original: URL) -> String {
        let base = original.deletingPathExtension().lastPathComponent
        return "Salvar gera \(base)\(Constants.Suffix.organized).pdf"
    }
}

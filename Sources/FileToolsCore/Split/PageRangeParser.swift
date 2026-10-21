import Foundation

public enum PageRangeParser {
    public static func parse(_ text: String, pageCount: Int) -> Result<[Int], PageRangeError> {
        var pages: [Int] = []
        for part in text.split(separator: ",", omittingEmptySubsequences: false) {
            let bounds = part.split(separator: "-", omittingEmptySubsequences: false).map(number)
            guard (1...2).contains(bounds.count), !bounds.contains(nil) else { return .failure(.invalidSyntax) }
            let numbers = bounds.compactMap { $0 }
            if let outside = numbers.first(where: { $0 < 1 || $0 > pageCount }) {
                return .failure(.pageOutOfRange(page: outside, pageCount: pageCount))
            }
            let first = numbers[0]
            let last = numbers[numbers.count - 1]
            pages.append(contentsOf: stride(from: first, through: last, by: first <= last ? 1 : -1))
        }
        return .success(pages)
    }

    private static func number(_ text: Substring) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(trimmed)
    }
}

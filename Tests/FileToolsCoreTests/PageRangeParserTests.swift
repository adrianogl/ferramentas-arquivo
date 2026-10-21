import Testing
@testable import FileToolsCore

@Suite struct PageRangeParserTests {
    @Test func parses() {
        #expect(PageRangeParser.parse("1-3, 5", pageCount: 8) == .success([1, 2, 3, 5]))
        #expect(PageRangeParser.parse(" 2 ,4-4", pageCount: 8) == .success([2, 4]))
        #expect(PageRangeParser.parse("5-3", pageCount: 8) == .success([5, 4, 3]))
    }

    @Test func errors() {
        #expect(PageRangeParser.parse("1-3, 9", pageCount: 8) == .failure(.pageOutOfRange(page: 9, pageCount: 8)))
        #expect(PageRangeParser.parse("0", pageCount: 8) == .failure(.pageOutOfRange(page: 0, pageCount: 8)))
        #expect(PageRangeParser.parse("", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeParser.parse("a-b", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeError.pageOutOfRange(page: 9, pageCount: 8).message == "Página 9 não existe (o PDF tem 8)")
        #expect(PageRangeError.invalidSyntax.message == "Use números e intervalos, como 1-3, 5")
    }

    @Test func zeroPageDocumentRejectsEveryPage() {
        #expect(PageRangeParser.parse("1", pageCount: 0) == .failure(.pageOutOfRange(page: 1, pageCount: 0)))
        #expect(PageRangeParser.parse("1-2", pageCount: 0) == .failure(.pageOutOfRange(page: 1, pageCount: 0)))
    }

    @Test func rejectsMalformedParts() {
        #expect(PageRangeParser.parse("1,,2", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeParser.parse("1-2-3", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeParser.parse("-3", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeParser.parse("3-", pageCount: 8) == .failure(.invalidSyntax))
        #expect(PageRangeParser.parse("99999999999999999999", pageCount: 8) == .failure(.invalidSyntax))
    }
}

import Testing
@testable import FileToolsCore

@Suite struct LimitInputTests {
    @Test func liveValueAcceptsCommaDecimals() {
        #expect(LimitInput.liveValue("0,5") == 0.5)
        #expect(LimitInput.liveValue("1,25") == 1.25)
    }

    @Test func liveValueRejectsOutOfRangeWhileTyping() {
        #expect(LimitInput.liveValue("0") == nil)
        #expect(LimitInput.liveValue("500") == nil)
    }

    @Test func normalizeClampsOutOfRange() {
        #expect(LimitInput.normalize("0", previous: 2) == 0.1)
        #expect(LimitInput.normalize("500", previous: 2) == 100)
    }

    @Test func normalizeKeepsPreviousForUnparseableText() {
        #expect(LimitInput.normalize("", previous: 2) == 2)
        #expect(LimitInput.normalize("abc", previous: 2) == 2)
    }

    @Test func normalizeKeepsValidValue() {
        #expect(LimitInput.normalize("1,25", previous: 2) == 1.25)
    }

    @Test func formatUsesComma() {
        #expect(LimitInput.format(0.5) == "0,5")
        #expect(LimitInput.format(1) == "1")
    }
}

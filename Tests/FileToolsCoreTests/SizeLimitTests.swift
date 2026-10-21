import Testing
@testable import FileToolsCore

@Suite struct SizeLimitTests {
    @Test func megabyteIsDecimal() { #expect(SizeLimit.megabytes(1).bytes == 1_000_000) }

    @Test func strictlyBelow() {
        let limit = SizeLimit.megabytes(1)
        #expect(limit.accepts(byteCount: 999_999))
        #expect(!limit.accepts(byteCount: 1_000_000))
    }

    @Test func fractional() { #expect(SizeLimit.megabytes(1.5).bytes == 1_500_000) }

    @Test func nonFiniteFallsBackToDefault() {
        #expect(SizeLimit.megabytes(.nan).bytes == 1_000_000)
        #expect(SizeLimit.megabytes(.infinity).bytes == 1_000_000)
        #expect(SizeLimit.megabytes(-.infinity).bytes == 1_000_000)
    }
}

import Testing
@testable import FileToolsCore

@Suite struct TriggerModifierTests {
    @Test func glyphMatchesTitlePrefix() {
        for modifier in TriggerModifier.allCases {
            #expect(modifier.title.hasPrefix(modifier.glyph))
        }
    }
}

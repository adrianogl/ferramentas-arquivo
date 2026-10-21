import Foundation
import Testing
@testable import FileToolsCore

@Suite struct TargetRuleTests {
    let a = URL(fileURLWithPath: "/t/a.pdf")
    let b = URL(fileURLWithPath: "/t/b.pdf")
    let c = URL(fileURLWithPath: "/t/c.pdf")

    @Test func clickedInsideSelectionUsesSelection() {
        #expect(TargetRule.resolve(selection: [a, b], clicked: b) == [a, b])
    }

    @Test func clickedOutsideUsesClicked() {
        #expect(TargetRule.resolve(selection: [a, b], clicked: c) == [c])
    }

    @Test func nothingClicked() {
        #expect(TargetRule.resolve(selection: [a], clicked: nil) == nil)
    }

    @Test func radialOnlyForPDFOrImage() throws {
        let d = try Fixtures.tempDirectory()
        let txt = d.appending(path: "x.txt")
        try Data("x".utf8).write(to: txt)
        #expect(!TargetRule.shouldShowRadial(for: [d]))
        #expect(!TargetRule.shouldShowRadial(for: [txt]))
        #expect(!TargetRule.shouldShowRadial(for: []))
    }
}

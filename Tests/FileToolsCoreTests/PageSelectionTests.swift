import Foundation
import Testing
@testable import FileToolsCore

@Suite struct PageSelectionTests {
    private let order = (0..<6).map { _ in UUID() }

    @Test func clickSelectsOne() {
        var selection = PageSelection()
        selection.click(order[1], gesture: .single, order: order)
        selection.click(order[3], gesture: .single, order: order)
        #expect(selection.ids == [order[3]])
        #expect(selection.anchor == order[3])
    }

    @Test func toggleAddsAndRemoves() {
        var selection = PageSelection()
        selection.click(order[1], gesture: .single, order: order)
        selection.click(order[4], gesture: .toggle, order: order)
        #expect(selection.ids == [order[1], order[4]])
        selection.click(order[1], gesture: .toggle, order: order)
        #expect(selection.ids == [order[4]])
        #expect(selection.anchor == order[1])
    }

    @Test func extendSelectsRangeFromAnchorInBothDirections() {
        var selection = PageSelection()
        selection.click(order[2], gesture: .single, order: order)
        selection.click(order[4], gesture: .extend, order: order)
        #expect(selection.ids == Set(order[2...4]))
        selection.click(order[0], gesture: .extend, order: order)
        #expect(selection.ids == Set(order[0...2]))
        #expect(selection.anchor == order[2])
    }

    @Test func extendWithoutAnchorSelectsOne() {
        var selection = PageSelection()
        selection.click(order[3], gesture: .extend, order: order)
        #expect(selection.ids == [order[3]])
        #expect(selection.anchor == order[3])
    }

    @Test func pruneDropsMissingPagesAndAnchor() {
        var selection = PageSelection()
        selection.click(order[1], gesture: .single, order: order)
        selection.click(order[2], gesture: .toggle, order: order)
        selection.prune(to: [order[0], order[1], order[3]])
        #expect(selection.ids == [order[1]])
        #expect(selection.anchor == nil)
        selection.click(order[3], gesture: .extend, order: order)
        #expect(selection.ids == [order[3]])
    }

    @Test func replaceSetsSelectionAndAnchor() {
        var selection = PageSelection()
        selection.replace(with: order[5])
        #expect(selection.ids == [order[5]])
        #expect(selection.anchor == order[5])
        selection.clear()
        #expect(selection.ids.isEmpty)
        #expect(selection.anchor == nil)
    }
}

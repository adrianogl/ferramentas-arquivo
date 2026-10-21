import Testing
@testable import FileToolsCore

@Suite struct ClickTargetRuleTests {
    private func node(_ role: String, subrole: String = "", identifier: String = "") -> AccessibilityNode {
        AccessibilityNode(role: role, subrole: subrole, identifier: identifier)
    }

    private var application: AccessibilityNode { node("AXApplication") }
    private var window: AccessibilityNode { node("AXWindow", subrole: "AXStandardWindow", identifier: "FinderWindow") }
    private var outerSplit: AccessibilityNode { node("AXSplitGroup") }
    private var innerSplit: AccessibilityNode { node("AXSplitGroup") }

    @Test func listViewRowAllowsClick() {
        let path = [
            node("AXStaticText"), node("AXCell"), node("AXRow", subrole: "AXOutlineRow"),
            node("AXOutline", identifier: "ListView"), node("AXScrollArea", identifier: "_NS:188"),
            innerSplit, outerSplit, window, application,
        ]
        #expect(ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func iconViewItemAllowsClick() {
        let path = [
            node("AXImage"), node("AXGroup"), node("AXList", subrole: "AXSectionList"),
            node("AXList", subrole: "AXCollectionList", identifier: "IconView"), node("AXScrollArea"),
            innerSplit, outerSplit, window, application,
        ]
        #expect(ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func columnViewBackgroundAllowsClick() {
        let path = [
            node("AXList"), node("AXScrollArea"), node("AXScrollArea"),
            node("AXBrowser", identifier: "ColumnView"), innerSplit, outerSplit, window, application,
        ]
        #expect(ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func galleryViewAllowsClick() {
        let path = [
            node("AXList", subrole: "AXCollectionList", identifier: "GalleryView"), node("AXScrollArea"),
            innerSplit, outerSplit, window, application,
        ]
        #expect(ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func desktopAllowsClick() {
        #expect(ClickTargetRule.allowsSyntheticClick(path: [node("AXGroup"), node("AXScrollArea"), application]))
        #expect(ClickTargetRule.allowsSyntheticClick(path: [node("AXScrollArea"), application]))
    }

    @Test func toolbarButtonBlocksClick() {
        let path = [node("AXButton"), node("AXToolbar"), window, application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func toolbarGroupBlocksClick() {
        let path = [node("AXGroup"), node("AXToolbar"), window, application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func windowButtonsBlockClick() {
        let path = [node("AXButton", subrole: "AXCloseButton"), window, application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func menuBarItemBlocksClick() {
        let path = [node("AXMenuBarItem"), node("AXMenuBar"), application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func sidebarRowBlocksClick() {
        let path = [
            node("AXStaticText"), node("AXCell"), node("AXRow", subrole: "AXOutlineRow"),
            node("AXOutline", identifier: "_NS:8"), node("AXScrollArea", identifier: "_NS:61"),
            outerSplit, window, application,
        ]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func pathBarBlocksClick() {
        let path = [node("AXStaticText"), node("AXList"), innerSplit, outerSplit, window, application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func controlInsideFileViewBlocksClick() {
        let base = [
            node("AXCell"), node("AXRow", subrole: "AXOutlineRow"), node("AXOutline", identifier: "ListView"),
            node("AXScrollArea"), innerSplit, outerSplit, window, application,
        ]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: [node("AXDisclosureTriangle")] + base))
        #expect(!ClickTargetRule.allowsSyntheticClick(path: [node("AXButton")] + base))
        #expect(!ClickTargetRule.allowsSyntheticClick(path: [node("AXTextField")] + base))
    }

    @Test func scrollBarBlocksClick() {
        let path = [
            node("AXScrollBar"), node("AXScrollArea"), node("AXBrowser", identifier: "ColumnView"),
            innerSplit, outerSplit, window, application,
        ]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func tabBlocksClick() {
        let path = [node("AXRadioButton"), node("AXTabGroup"), window, application]
        #expect(!ClickTargetRule.allowsSyntheticClick(path: path))
    }

    @Test func truncatedOrEmptyPathBlocksClick() {
        #expect(!ClickTargetRule.allowsSyntheticClick(path: []))
        #expect(!ClickTargetRule.allowsSyntheticClick(path: [node("AXList", identifier: "ListView"), node("AXScrollArea")]))
    }
}

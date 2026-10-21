import Foundation
import Testing
@testable import FileToolsCore

@Suite struct NaturalOrderTests {
    @Test func numbersCompareNumerically() {
        let urls = ["IMG_10.png", "IMG_2.png", "IMG_1.png"].map { URL(fileURLWithPath: "/t/\($0)") }
        #expect(naturalOrder(urls).map(\.lastPathComponent) == ["IMG_1.png", "IMG_2.png", "IMG_10.png"])
    }
}

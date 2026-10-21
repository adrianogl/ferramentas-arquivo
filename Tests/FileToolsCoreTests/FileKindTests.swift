import Foundation
import Testing
@testable import FileToolsCore

@Suite struct FileKindTests {
    @Test func textFileIsUnsupported() throws {
        let d = try Fixtures.tempDirectory()
        let txt = d.appending(path: "x.txt")
        try Data("x".utf8).write(to: txt)
        #expect(FileKind.of(txt) == .unsupported)
    }

    @Test func folderIsUnsupported() throws {
        #expect(FileKind.of(try Fixtures.tempDirectory()) == .unsupported)
    }
}

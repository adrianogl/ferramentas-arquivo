import Foundation
import Testing
@testable import FileToolsCore

struct OutputWriterTests {
    @Test func writesAndReadsBack() throws {
        let dir = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let target = dir.appending(path: "saida.pdf")
        let data = Data([1, 2, 3, 4])
        try OutputWriter.write(data, to: target)
        #expect(try Data(contentsOf: target) == data)
    }

    @Test func makesFolder() throws {
        let dir = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let folder = dir.appending(path: "paginas", directoryHint: .isDirectory)
        try OutputWriter.makeFolder(folder)
        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }

    @Test func readOnlyFolderFailsToWrite() throws {
        guard getuid() != 0 else {
            Issue.record("rodando como root; teste de pasta somente leitura ignorado")
            return
        }
        let dir = try Fixtures.tempDirectory()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
            try? FileManager.default.removeItem(at: dir)
        }
        #expect(throws: ActionFailure.writeFailed) {
            try OutputWriter.write(Data([1]), to: dir.appending(path: "saida.pdf"))
        }
        #expect(throws: ActionFailure.writeFailed) {
            try OutputWriter.makeFolder(dir.appending(path: "paginas", directoryHint: .isDirectory))
        }
    }
}

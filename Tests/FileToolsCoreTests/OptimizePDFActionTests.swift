import Foundation
import Testing
import UniformTypeIdentifiers
@testable import FileToolsCore

@Suite struct OptimizePDFActionTests {
    private func fileCount(_ directory: URL) throws -> Int {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).count
    }

    @Test func writesSiblingWithSuffix() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let src = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
        let before = try Data(contentsOf: src)
        let r = OptimizePDFAction().run([src], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["nota-otimizado.pdf"])
        #expect(r.outputs[0].finalBytes < 1_000_000)
        #expect(r.outputs[0].sourceCount == 1)
        #expect(r.outputs[0].originalBytes == before.count)
        #expect(r.outputs[0].pageCount == 2)
        #expect(try Data(contentsOf: src) == before)
    }

    @Test func smallFileCreatesNothing() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let src = try Fixtures.write(Fixtures.textPDF(["Reembolso"]), named: "pequeno.pdf", in: d)
        let r = OptimizePDFAction().run([src], limit: .megabytes(1))
        #expect(r.untouched.count == 1)
        #expect(r.outputs.isEmpty)
        #expect(try fileCount(d) == 1)
    }

    @Test func continuesAfterFailure() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let broken = try Fixtures.write(Data("x".utf8), named: "quebrado.pdf", in: d)
        let good = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
        let r = OptimizePDFAction().run([broken, good], limit: .megabytes(1))
        #expect(r.failures == [ActionReport.Failure(url: broken, reason: .unreadable)])
        #expect(r.outputs.count == 1)
    }

    @Test func unreachableWritesNothing() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let src = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
        let r = OptimizePDFAction().run([src], limit: SizeLimit(bytes: 5_000))
        guard case .unreachable = r.failures.first?.reason else {
            Issue.record("esperava .unreachable")
            return
        }
        #expect(r.failures[0].url == src)
        #expect(r.outputs.isEmpty)
        #expect(try fileCount(d) == 1)
    }

    @Test func ignoresNonPDFs() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let photo = d.appending(path: "foto.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 50, height: 50), to: photo, type: .png)
        let src = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
        let r = OptimizePDFAction().run([photo, src], limit: .megabytes(1))
        #expect(r.outputs.map(\.url.lastPathComponent) == ["nota-otimizado.pdf"])
        #expect(r.untouched.isEmpty)
        #expect(r.failures.isEmpty)
    }

    @Test func readOnlyFolder() throws {
        guard getuid() != 0 else {
            Issue.record("rodando como root; teste de pasta somente leitura ignorado")
            return
        }
        let d = try Fixtures.tempDirectory()
        let src = try Fixtures.write(Fixtures.scannedPDF(pages: 2), named: "nota.pdf", in: d)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: d.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: d.path)
            try? FileManager.default.removeItem(at: d)
        }
        let r = OptimizePDFAction().run([src], limit: .megabytes(1))
        #expect(r.failures == [ActionReport.Failure(url: src, reason: .writeFailed)])
        #expect(r.outputs.isEmpty)
    }
}

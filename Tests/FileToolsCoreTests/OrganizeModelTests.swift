import Foundation
import Testing
@testable import FileToolsCore

@Suite struct OrganizeModelTests {
    private func model(pages: Int, in d: URL) throws -> (OrganizeModel, URL) {
        let texts = (0..<pages).map { "p\($0)" }
        let url = try Fixtures.write(Fixtures.textPDF(texts), named: "nota.pdf", in: d)
        return (try OrganizeModel(pdf: url), url)
    }

    @Test func loadsPages() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let (m, url) = try model(pages: 4, in: d)
        #expect(m.pages.count == 4)
        #expect(m.pages.map(\.source) == (0...3).map { .pdf(url, index: $0) })
        #expect(m.pages.allSatisfy { $0.rotation == 0 })
        #expect(m.canSave)
    }

    @Test func moveKeepsRelativeOrder() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        let (initial, _) = try model(pages: 4, in: d)
        let p = initial.pages.map(\.id)
        var m = initial
        m.move([p[0], p[2]], to: 4)
        #expect(m.pages.map(\.id) == [p[1], p[3], p[0], p[2]])
        m = initial
        m.move([p[3]], to: 0)
        #expect(m.pages.map(\.id) == [p[3], p[0], p[1], p[2]])
        m = initial
        m.move([p[0]], to: 3)
        #expect(m.pages.map(\.id) == [p[1], p[2], p[0], p[3]])
    }

    @Test func deleteAndCanSave() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        var (m, _) = try model(pages: 3, in: d)
        m.delete(Set(m.pages.map(\.id)))
        #expect(m.pages.isEmpty)
        #expect(m.canSave == false)
    }

    @Test func rotateNormalizes() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        var (m, _) = try model(pages: 2, in: d)
        let first = m.pages[0].id
        for _ in 0..<5 { m.rotate([first], by: 90) }
        #expect(m.pages[0].rotation == 90)
        #expect(m.pages[1].rotation == 0)
        m.rotate([m.pages[1].id], by: -90)
        #expect(m.pages[1].rotation == 270)
    }

    @Test func appendsPDFAndImage() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        var (m, _) = try model(pages: 2, in: d)
        let other = try Fixtures.write(Fixtures.textPDF(["x", "y"]), named: "outro.pdf", in: d)
        try m.append(other)
        #expect(m.pages.count == 4)
        #expect(m.pages[2].source == .pdf(other, index: 0))
        #expect(m.pages[3].source == .pdf(other, index: 1))
        let photo = d.appending(path: "foto.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 40, height: 30), to: photo, type: .png)
        try m.append(photo)
        #expect(m.pages.count == 5)
        #expect(m.pages[4].source == .image(photo))
        let text = try Fixtures.write(Data("oi".utf8), named: "arquivo.txt", in: d)
        #expect(throws: ActionFailure.unreadable) { try m.append(text) }
        #expect(m.pages.count == 5)
    }

    @Test func appendEncryptedThrows() throws {
        let d = try Fixtures.tempDirectory()
        defer { try? FileManager.default.removeItem(at: d) }
        var (m, _) = try model(pages: 1, in: d)
        let locked = try Fixtures.write(Fixtures.encryptedPDF(), named: "senha.pdf", in: d)
        #expect(throws: ActionFailure.encrypted) { try m.append(locked) }
        #expect(m.pages.count == 1)
    }
}

@Suite struct OrganizeDropIndexTests {
    private func model(pages: Int) throws -> (OrganizeModel, URL) {
        let d = try Fixtures.tempDirectory()
        let url = try Fixtures.write(Fixtures.textPDF((0..<pages).map { "p\($0)" }), named: "nota.pdf", in: d)
        return (try OrganizeModel(pdf: url), d)
    }

    @Test func dropBackwardLandsOnTargetPosition() throws {
        var (m, d) = try model(pages: 8)
        defer { try? FileManager.default.removeItem(at: d) }
        let ids = m.pages.map(\.id)
        let index = try #require(m.dropIndex(moving: [ids[4]], onto: ids[2]))
        m.move([ids[4]], to: index)
        #expect(m.pages.map(\.id) == [ids[0], ids[1], ids[4], ids[2], ids[3], ids[5], ids[6], ids[7]])
    }

    @Test func dropForwardLandsOnTargetPosition() throws {
        var (m, d) = try model(pages: 8)
        defer { try? FileManager.default.removeItem(at: d) }
        let ids = m.pages.map(\.id)
        let index = try #require(m.dropIndex(moving: [ids[1], ids[2]], onto: ids[5]))
        m.move([ids[1], ids[2]], to: index)
        #expect(m.pages.map(\.id) == [ids[0], ids[3], ids[4], ids[5], ids[1], ids[2], ids[6], ids[7]])
    }

    @Test func dropOntoItselfOrUnknownIsIgnored() throws {
        let (m, d) = try model(pages: 3)
        defer { try? FileManager.default.removeItem(at: d) }
        let ids = m.pages.map(\.id)
        #expect(m.dropIndex(moving: [ids[1]], onto: ids[1]) == nil)
        #expect(m.dropIndex(moving: [UUID()], onto: ids[1]) == nil)
        #expect(m.dropIndex(moving: [ids[0]], onto: UUID()) == nil)
    }
}

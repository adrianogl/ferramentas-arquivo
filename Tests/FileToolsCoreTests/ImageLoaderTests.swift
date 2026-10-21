import CoreGraphics
import Foundation
import Testing
@testable import FileToolsCore

@Suite struct ImageLoaderTests {
    @Test func appliesExifOrientation() throws {
        let d = try Fixtures.tempDirectory()
        let u = d.appending(path: "foto.jpg")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: u, type: .jpeg, orientation: 6)
        let img = try ImageLoader.load(u)
        #expect(img.height > img.width)
    }

    @Test func doesNotUpscale() throws {
        let d = try Fixtures.tempDirectory()
        let u = d.appending(path: "pequena.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 400, height: 200), to: u, type: .png)
        let img = try ImageLoader.load(u, maxPixelSize: 2000)
        #expect(img.width == 400)
    }

    @Test func downscalesToMaxPixelSize() throws {
        let d = try Fixtures.tempDirectory()
        let u = d.appending(path: "grande.png")
        try Fixtures.writeImage(Fixtures.noiseImage(width: 800, height: 400), to: u, type: .png)
        let img = try ImageLoader.load(u, maxPixelSize: 200)
        #expect(max(img.width, img.height) == 200)
    }

    @Test func brokenImageIsUnreadable() throws {
        let d = try Fixtures.tempDirectory()
        let u = try Fixtures.write(Data((0..<512).map { _ in UInt8.random(in: 0...255) }), named: "quebrada.png", in: d)
        #expect(throws: ActionFailure.unreadable) { try ImageLoader.load(u) }
    }
}

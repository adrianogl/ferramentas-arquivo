import CoreGraphics
import Foundation
import Testing
@testable import FileToolsCore

struct RadialGeometryTests {
    @Test func slots() {
        #expect(RadialGeometry.slot(at: CGVector(dx: 0, dy: 90)) == 0)
        #expect(RadialGeometry.slot(at: CGVector(dx: 90, dy: 0)) == 2)
        #expect(RadialGeometry.slot(at: CGVector(dx: 0, dy: -90)) == 4)
        #expect(RadialGeometry.slot(at: CGVector(dx: -90, dy: 0)) == 6)
        #expect(RadialGeometry.slot(at: CGVector(dx: 64, dy: 64)) == 1)
        #expect(RadialGeometry.slot(at: CGVector(dx: 90 * sin(CGFloat.pi * 20 / 180), dy: 90 * cos(CGFloat.pi * 20 / 180))) == 0)
        #expect(RadialGeometry.slot(at: CGVector(dx: 90 * sin(CGFloat.pi * 25 / 180), dy: 90 * cos(CGFloat.pi * 25 / 180))) == 1)
        #expect(RadialGeometry.slot(at: CGVector(dx: 40, dy: 10)) == nil)
        #expect(RadialGeometry.slot(at: CGVector(dx: 200, dy: 0)) == nil)
    }

    @Test func vacancyAndWrapAround() {
        #expect(RadialGeometry.slot(at: CGVector(dx: -64, dy: 64)) == 7)
        #expect(RadialGeometry.slot(at: CGVector(dx: -90 * sin(CGFloat.pi * 20 / 180), dy: 90 * cos(CGFloat.pi * 20 / 180))) == 0)
    }
}

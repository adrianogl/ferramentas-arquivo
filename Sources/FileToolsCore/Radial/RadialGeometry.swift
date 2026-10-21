import CoreGraphics
import Foundation

public enum RadialGeometry {
    public static func slot(at offset: CGVector) -> Int? {
        let r = hypot(offset.dx, offset.dy)
        guard r >= Constants.radialCoreRadius, r <= Constants.radialDiameter / 2 else { return nil }
        let full = 2 * Double.pi
        let span = full / Double(Constants.radialSlotCount)
        var theta = atan2(Double(offset.dx), Double(offset.dy))
        if theta < 0 { theta += full }
        let index = Int(((theta + span / 2).truncatingRemainder(dividingBy: full)) / span)
        return min(index, Constants.radialSlotCount - 1)
    }
}

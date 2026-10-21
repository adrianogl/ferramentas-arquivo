import FileToolsCore
import SwiftUI

struct RadialSliceShape: Shape {
    var innerRadius: CGFloat = Constants.radialCoreRadius
    var outerRadius: CGFloat = Constants.radialRingOuter
    var span: Angle = .degrees(360 / Double(Constants.radialSlotCount))

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = Angle.degrees(-90) - span / 2
        let end = Angle.degrees(-90) + span / 2
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

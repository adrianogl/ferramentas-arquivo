import SwiftUI

struct BrandMark: View {
    private static let ringRadius: CGFloat = 22
    private static let ringWidth: CGFloat = 11
    private static let segmentLength: CGFloat = 14.8
    private static let firstSegmentAngle = -110.5
    private static let segmentSpacing = 45.0

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            context.scaleBy(x: scale, y: scale)
            context.fill(Self.body, with: .color(Color(brand: AppConstants.Brand.navy)))
            context.fill(Self.fold, with: .color(Color(brand: AppConstants.Brand.blue)))
            let sweep = Double(Self.segmentLength / Self.ringRadius)
            for index in 0..<8 {
                let start = Angle.degrees(Self.firstSegmentAngle + Double(index) * Self.segmentSpacing)
                let end = start + .radians(sweep)
                var arc = Path()
                arc.addArc(center: CGPoint(x: 50, y: 52), radius: Self.ringRadius, startAngle: start, endAngle: end, clockwise: false)
                context.stroke(arc, with: .color(Self.segmentColor(index)), lineWidth: Self.ringWidth)
            }
        }
        .accessibilityHidden(true)
    }

    private static func segmentColor(_ index: Int) -> Color {
        switch index {
        case 0: Color(brand: AppConstants.Brand.blue)
        case 7: Color(brand: AppConstants.Brand.secondaryText)
        default: .white
        }
    }

    private static let body: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 22, y: 6))
        path.addLine(to: CGPoint(x: 70, y: 6))
        path.addLine(to: CGPoint(x: 94, y: 30))
        path.addLine(to: CGPoint(x: 94, y: 78))
        path.addArc(tangent1End: CGPoint(x: 94, y: 94), tangent2End: CGPoint(x: 78, y: 94), radius: 16)
        path.addLine(to: CGPoint(x: 22, y: 94))
        path.addArc(tangent1End: CGPoint(x: 6, y: 94), tangent2End: CGPoint(x: 6, y: 78), radius: 16)
        path.addLine(to: CGPoint(x: 6, y: 22))
        path.addArc(tangent1End: CGPoint(x: 6, y: 6), tangent2End: CGPoint(x: 22, y: 6), radius: 16)
        path.closeSubpath()
        return path
    }()

    private static let fold: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 70, y: 6))
        path.addLine(to: CGPoint(x: 70, y: 22))
        path.addArc(tangent1End: CGPoint(x: 70, y: 30), tangent2End: CGPoint(x: 78, y: 30), radius: 8)
        path.addLine(to: CGPoint(x: 94, y: 30))
        path.closeSubpath()
        return path
    }()
}

import SwiftUI

struct TryItIllustration: View {
    private static let segmentCount = 8
    private static let ringRadius: CGFloat = 33
    private static let ringWidth: CGFloat = 14
    private static let segmentLength: CGFloat = 23.5
    private static let firstSegmentAngle = -110.0
    private static let segmentSpacing = 45.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(brand: AppConstants.Brand.lightGround))
                .strokeBorder(Color(brand: AppConstants.Brand.border), lineWidth: 1)
            fileIcon
                .frame(width: 54, height: 64)
                .offset(x: 22, y: 24)
            Text(AppConstants.Onboarding.sampleFileName)
                .font(.system(size: 11))
                .foregroundStyle(Color(brand: AppConstants.Brand.secondaryText))
                .frame(width: 80)
                .offset(x: 10, y: 94)
            radial
                .frame(width: 130, height: 130)
                .offset(x: 66, y: 66)
        }
        .frame(width: 200, height: 200)
        .accessibilityHidden(true)
    }

    private var fileIcon: some View {
        Canvas { context, _ in
            var page = Path()
            page.move(to: CGPoint(x: 6, y: 2))
            page.addLine(to: CGPoint(x: 34, y: 2))
            page.addLine(to: CGPoint(x: 52, y: 20))
            page.addLine(to: CGPoint(x: 52, y: 58))
            page.addArc(tangent1End: CGPoint(x: 52, y: 62), tangent2End: CGPoint(x: 48, y: 62), radius: 4)
            page.addLine(to: CGPoint(x: 6, y: 62))
            page.addArc(tangent1End: CGPoint(x: 2, y: 62), tangent2End: CGPoint(x: 2, y: 58), radius: 4)
            page.addLine(to: CGPoint(x: 2, y: 6))
            page.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: 6, y: 2), radius: 4)
            page.closeSubpath()
            context.fill(page, with: .color(.white))
            context.stroke(page, with: .color(Color(brand: AppConstants.Brand.inactive)), lineWidth: 2)
            let badge = Path(roundedRect: CGRect(x: 8, y: 44, width: 38, height: 11), cornerRadius: 2)
            context.fill(badge, with: .color(Color(brand: AppConstants.Brand.pdfBadge)))
            let label = context.resolve(Text("PDF").font(.system(size: 8, weight: .bold)).foregroundStyle(.white))
            context.draw(label, at: CGPoint(x: 27, y: 49.5))
        }
    }

    private var radial: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 100
            context.scaleBy(x: scale, y: scale)
            let center = CGPoint(x: 50, y: 50)
            context.fill(
                Path(ellipseIn: CGRect(x: 4, y: 4, width: 92, height: 92)),
                with: .color(Color(brand: AppConstants.Brand.navy).opacity(0.9)))
            let sweep = Double(Self.segmentLength / Self.ringRadius)
            for index in 0..<Self.segmentCount {
                let start = Angle.degrees(Self.firstSegmentAngle + Double(index) * Self.segmentSpacing)
                var arc = Path()
                arc.addArc(center: center, radius: Self.ringRadius, startAngle: start, endAngle: start + .radians(sweep), clockwise: false)
                context.stroke(arc, with: .color(Self.segmentColor(index)), lineWidth: Self.ringWidth)
            }
        }
    }

    private static func segmentColor(_ index: Int) -> Color {
        switch index {
        case 0: Color(brand: AppConstants.Brand.optimize)
        case segmentCount - 1: Color.white.opacity(0.15)
        default: Color.white.opacity(0.35)
        }
    }
}

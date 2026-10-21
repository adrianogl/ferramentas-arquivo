import FileToolsCore
import SwiftUI

struct RadialMenuView: View {
    let model: RadialMenuModel
    @Environment(\.colorScheme) private var colorScheme

    private typealias Metrics = AppConstants.Radial
    private let diameter = Constants.radialDiameter
    private var slotSpan: Double { 360 / Double(Constants.radialSlotCount) }

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: diameter, height: diameter)
                .glassEffect(.regular, in: Circle())
            RadialSeparators()
                .stroke(Color.primary.opacity(Metrics.separatorOpacity), lineWidth: 1)
            highlight
            core
            ForEach(0..<Constants.radialSlotCount, id: \.self) { slot in
                icon(for: slot)
                    .position(position(of: slot))
            }
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(model.isShown ? 1 : Metrics.hiddenScale)
        .blur(radius: model.isShown ? 0 : Metrics.hiddenBlur)
        .opacity(model.isShown ? 1 : 0)
        .frame(width: Metrics.panelSize, height: Metrics.panelSize)
    }

    private var activeAction: ActionDescriptor? {
        guard let id = model.runningAction ?? model.hoveredAction, model.isAvailable(id) else { return nil }
        return Constants.descriptor(id)
    }

    @ViewBuilder
    private var highlight: some View {
        if let action = activeAction {
            let color = Color(hex: action.colorHex)
            let rotation = Angle.degrees(Double(action.slot) * slotSpan)
            let ringRadius = (Constants.radialRingInner + Constants.radialRingOuter) / 2
            ZStack {
                RadialSliceShape()
                    .fill(color.opacity(Metrics.sliceFillOpacity))
                Circle()
                    .trim(from: 0, to: slotSpan / 360)
                    .stroke(color, style: StrokeStyle(
                        lineWidth: Constants.radialRingOuter - Constants.radialRingInner, lineCap: .round))
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .rotationEffect(.degrees(-90 - slotSpan / 2))
                    .shadow(color: color, radius: Metrics.glowRadius)
            }
            .frame(width: diameter, height: diameter)
            .rotationEffect(rotation)
        }
    }

    private var core: some View {
        let text = model.coreText
        return ZStack {
            Circle()
                .fill(.regularMaterial)
                .overlay(Circle().fill(Color.white.opacity(colorScheme == .dark ? Metrics.coreTintDark : Metrics.coreTintLight)))
                .overlay(Circle().strokeBorder(Color.white.opacity(colorScheme == .dark ? Metrics.coreBorderDark : 0), lineWidth: 1))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : Metrics.coreShadowOpacity), radius: Metrics.coreShadowRadius, y: Metrics.coreShadowOffset)
            VStack(spacing: Metrics.coreLineSpacing) {
                Text(text.title)
                    .font(.system(size: Metrics.titleSize, weight: .semibold))
                    .lineLimit(2)
                    .truncationMode(.middle)
                Text(text.line)
                    .font(.system(size: Metrics.detailSize, weight: text.isReason ? .medium : .regular))
                    .foregroundStyle(text.isReason ? AnyShapeStyle(Color(hex: Metrics.reasonColorHex)) : AnyShapeStyle(.primary))
                    .opacity(text.isReason ? 1 : Metrics.detailOpacity)
                    .lineLimit(2)
                    .truncationMode(.middle)
                if !text.hint.isEmpty {
                    Text(text.hint)
                        .font(.system(size: Metrics.detailSize))
                        .opacity(Metrics.detailOpacity)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Metrics.coreTextInset)
        }
        .frame(width: Metrics.coreDiameter, height: Metrics.coreDiameter)
    }

    @ViewBuilder
    private func icon(for slot: Int) -> some View {
        if let id = model.action(at: slot) {
            let action = Constants.descriptor(id)
            let color = Color(hex: action.colorHex)
            let available = model.isAvailable(id)
            let active = activeAction?.id == id
            VStack(spacing: Metrics.iconLabelSpacing) {
                RoundedRectangle(cornerRadius: Metrics.iconCornerRadius, style: .continuous)
                    .fill(active ? color : color.opacity(Metrics.iconFillOpacity))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metrics.iconCornerRadius, style: .continuous)
                            .strokeBorder(active ? .clear : color.opacity(Metrics.iconBorderOpacity), lineWidth: 1)
                    }
                    .background {
                        if active {
                            RoundedRectangle(cornerRadius: Metrics.iconCornerRadius + Metrics.iconRingWidth, style: .continuous)
                                .fill(color.opacity(Metrics.iconRingOpacity))
                                .padding(-Metrics.iconRingWidth)
                        }
                    }
                    .shadow(color: active ? color.opacity(Metrics.iconGlowOpacity) : .clear, radius: Metrics.iconGlowRadius, y: Metrics.iconGlowOffset)
                    .overlay {
                        Image(systemName: action.symbol)
                            .font(.system(size: Metrics.iconSymbolSize, weight: .semibold))
                            .foregroundStyle(active ? .white : color)
                    }
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                Text(action.shortLabel)
                    .font(.system(size: Metrics.labelSize, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? AnyShapeStyle(color) : AnyShapeStyle(.primary))
                    .fixedSize()
            }
            .opacity(available ? 1 : Metrics.unavailableOpacity)
        } else {
            let color = Color(hex: Constants.vacancyColorHex)
            RoundedRectangle(cornerRadius: Metrics.iconCornerRadius, style: .continuous)
                .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: Metrics.vacancyDash))
                .overlay {
                    Image(systemName: Constants.vacancySymbol)
                        .font(.system(size: Metrics.iconSymbolSize, weight: .semibold))
                        .foregroundStyle(color)
                }
                .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                .opacity(Metrics.vacancyOpacity)
        }
    }

    private func position(of slot: Int) -> CGPoint {
        let theta = Double(slot) * slotSpan * .pi / 180
        let r = Constants.radialIconRadius
        return CGPoint(x: diameter / 2 + r * sin(theta), y: diameter / 2 - r * cos(theta))
    }
}

private struct RadialSeparators: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let span = 2 * Double.pi / Double(Constants.radialSlotCount)
        var path = Path()
        for k in 0..<Constants.radialSlotCount {
            let theta = span / 2 + span * Double(k)
            let direction = CGVector(dx: sin(theta), dy: -cos(theta))
            path.move(to: CGPoint(
                x: center.x + Constants.radialCoreRadius * direction.dx,
                y: center.y + Constants.radialCoreRadius * direction.dy))
            path.addLine(to: CGPoint(
                x: center.x + Constants.radialRingOuter * direction.dx,
                y: center.y + Constants.radialRingOuter * direction.dy))
        }
        return path
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(brand: value)
    }
}

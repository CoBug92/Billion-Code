import SwiftUI

struct DenseGraphNodeView: View {
    let node: GraphNode
    let isSelected: Bool
    let isHighlighted: Bool
    let showsLabel: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                symbol
                    .frame(width: symbolSize, height: symbolSize)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())

                if showsLabel {
                    Text(node.shortName)
                        .font(.caption2.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Asset.Colors.surfacePrimary.swiftUIColor.opacity(0.92), in: Capsule())
                        .overlay(Capsule().stroke(.secondary.opacity(0.12)))
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isHighlighted ? 1 : 0.13)
        .accessibilityLabel(node.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Presentation

private extension DenseGraphNodeView {
    @ViewBuilder
    var symbol: some View {
        switch node.kind {
        case .person:
            PersonAvatarView(node: node, diameter: symbolSize, accentColor: node.kind.denseGraphColor)
                .overlay(selectionStroke(Circle()))
                .shadow(color: node.kind.denseGraphColor.opacity(isHighlighted ? 0.45 : 0.12), radius: 8)
        case .organization:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(node.kind.denseGraphColor.gradient)
                .overlay(selectionStroke(RoundedRectangle(cornerRadius: 4, style: .continuous)))
                .rotationEffect(.degrees(45))
                .shadow(color: node.kind.denseGraphColor.opacity(isHighlighted ? 0.42 : 0.12), radius: 7)
        case .university:
            DenseGraphTriangle()
                .fill(node.kind.denseGraphColor.gradient)
                .overlay(selectionStroke(DenseGraphTriangle()))
                .shadow(color: node.kind.denseGraphColor.opacity(isHighlighted ? 0.42 : 0.12), radius: 7)
        case .foundation, .family, .deal, .event:
            Capsule()
                .fill(node.kind.denseGraphColor.gradient)
                .overlay(selectionStroke(Capsule()))
        }
    }

    func selectionStroke<S: Shape>(_ shape: S) -> some View {
        shape.stroke(
            isSelected ? Color.white : node.kind.denseGraphColor.opacity(0.7),
            lineWidth: isSelected ? 3 : 1
        )
    }

    var symbolSize: CGFloat {
        switch node.kind {
        case .person: 22
        case .organization: 19
        case .university: 23
        case .foundation, .family, .deal, .event: 21
        }
    }

    var accessibilityValue: String {
        let kind: String
        switch node.kind {
        case .person: kind = "Человек"
        case .organization: kind = "Компания"
        case .university: kind = "Университет"
        case .foundation: kind = "Фонд"
        case .family: kind = "Семья"
        case .deal: kind = "Сделка"
        case .event: kind = "Событие"
        }
        return isSelected ? "\(kind), выбрано" : kind
    }
}

private struct DenseGraphTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    DenseGraphNodeView(
        node: DenseGraphFixture.performance.nodes[0],
        isSelected: true,
        isHighlighted: true,
        showsLabel: true,
        action: {}
    )
    .padding()
    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}

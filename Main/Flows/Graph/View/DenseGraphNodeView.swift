import SwiftUI

struct DenseGraphNodeView: View {
    let node: GraphNode
    let isSelected: Bool
    let isHighlighted: Bool
    let showsLabel: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            symbol
                .frame(width: symbolSize, height: symbolSize)
                .frame(width: .graphNodeTouchSize, height: .graphNodeTouchSize)
                .contentShape(Rectangle())
                .overlay(alignment: .top) {
                    if showsLabel {
                        Text(displayName)
                            .font(.caption2.weight(isSelected ? .semibold : .regular))
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Asset.Colors.surfacePrimary.swiftUIColor.opacity(0.92), in: Capsule())
                            .overlay(Capsule().stroke(.secondary.opacity(0.12)))
                            .offset(y: .graphNodeLabelOffset)
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
                .shadow(color: selectionShadowColor, radius: selectionShadowRadius)
        case .organization:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(node.kind.denseGraphColor.gradient)
                .overlay(selectionStroke(RoundedRectangle(cornerRadius: 4, style: .continuous)))
                .rotationEffect(.degrees(45))
                .shadow(color: selectionShadowColor, radius: selectionShadowRadius)
        case .university:
            DenseGraphTriangle()
                .fill(node.kind.denseGraphColor.gradient)
                .overlay(selectionStroke(DenseGraphTriangle()))
                .shadow(color: selectionShadowColor, radius: selectionShadowRadius)
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
        case .person: 34
        case .organization: 19
        case .university: 23
        case .foundation, .family, .deal, .event: 21
        }
    }

    var displayName: String {
        node.kind == .person ? node.name : node.shortName
    }

    var selectionShadowColor: Color {
        node.kind.denseGraphColor.opacity(isSelected ? 0.42 : .zero)
    }

    var selectionShadowRadius: CGFloat {
        isSelected ? 7 : .zero
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

// MARK: - Constants

private extension CGFloat {
    static let graphNodeTouchSize = 44.0
    static let graphNodeLabelOffset = 48.0
}

// MARK: - Preview

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

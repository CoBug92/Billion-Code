import SwiftUI

struct GraphNodeView: View {
    let node: GraphNode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: { label }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(node.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(L10n.Graph.Node.hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Computed properties

private extension GraphNodeView {
    var label: some View {
        VStack(spacing: Margin.x2) {
            PersonAvatarView(node: node, diameter: .portraitDiameter)
                .overlay {
                    Circle()
                        .stroke(
                            isSelected ? Asset.Colors.accentColor.swiftUIColor : Color.white.opacity(.portraitBorderOpacity),
                            lineWidth: isSelected ? .selectedBorderWidth : .portraitBorderWidth
                        )
                }
                .shadow(
                    color: Color.black.opacity(.shadowOpacity),
                    radius: .shadowRadius,
                    y: .shadowOffset
                )
            Text(node.shortName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(.minimumTextScale)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, Margin.x2)
                .padding(.vertical, Margin.x1)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .frame(
            minWidth: .nodeWidth,
            minHeight: .minimumTouchTarget
        )
    }

    var accessibilityValue: String {
        isSelected
            ? "\(node.kind.localizedTitle), \(L10n.Graph.Node.selected)"
            : node.kind.localizedTitle
    }
}

// MARK: - Constants

private extension CGFloat {
    static let minimumTouchTarget = 44.0
    static let minimumTextScale = 0.72
    static let nodeWidth = 92.0
    static let portraitBorderWidth = 1.5
    static let portraitDiameter = 64.0
    static let selectedBorderWidth = 4.0
    static let shadowRadius = 3.0
    static let shadowOffset = 1.0
}

private extension Double {
    static let portraitBorderOpacity = 0.9
    static let shadowOpacity = 0.12
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        GraphNodeView(
            node: GraphFixture.spike.nodes[0],
            isSelected: true,
            action: {}
        )
        GraphNodeView(
            node: GraphFixture.spike.nodes[1],
            isSelected: false,
            action: {}
        )
    }
    .padding()
}

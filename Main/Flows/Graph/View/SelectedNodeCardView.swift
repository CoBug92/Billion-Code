import SwiftUI

struct SelectedNodeCardView: View {
    let node: GraphNode
    let relationshipCount: Int

    var body: some View {
        HStack(spacing: Margin.x6) {
            Image(systemName: node.kind.symbolName)
                .font(.title3)
                .foregroundStyle(Asset.Colors.accentColor.swiftUIColor)
                .frame(
                    width: .iconFrame,
                    height: .iconFrame
                )
                .background(Asset.Colors.backgroundPrimary.swiftUIColor, in: Circle())
            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(node.name)
                    .font(.headline)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                Text(node.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: Margin.x3)
            Text(L10n.Graph.Card.relationships(relationshipCount))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(Margin.x7)
        .background(Asset.Colors.surfacePrimary.swiftUIColor)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconFrame = 44.0
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    SelectedNodeCardView(
        node: GraphFixture.spike.featuredNode,
        relationshipCount: 39
    )
}

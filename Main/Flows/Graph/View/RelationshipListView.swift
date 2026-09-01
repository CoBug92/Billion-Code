import SwiftUI

struct RelationshipListView: View {
    let node: GraphNode
    let relationships: [GraphRelationship]
    let graph: GraphData
    let onOpen: (GraphRelationship) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            Text(L10n.Graph.relationships)
                .font(.subheadline.bold())
                .padding(.horizontal, Margin.x8)

            if relationships.isEmpty {
                Text(L10n.Graph.Relationships.empty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Margin.x8)
            } else {
                ScrollView {
                    LazyVStack(spacing: .zero) {
                        ForEach(relationships) { relationship in
                            relationshipButton(relationship)
                            Divider()
                                .padding(.leading, Margin.x8)
                        }
                    }
                }
            }
        }
        .padding(.top, Margin.x5)
        .background(Asset.Colors.surfacePrimary.swiftUIColor)
    }
}

// MARK: - Layout

private extension RelationshipListView {
    func relationshipButton(_ relationship: GraphRelationship) -> some View {
        let otherNode = otherNode(for: relationship)

        return Button {
            onOpen(relationship)
        } label: {
            HStack(spacing: Margin.x5) {
                Image(systemName: relationship.status.symbolName)
                    .foregroundStyle(relationship.status == .disputed ? Color.orange : Color.secondary)
                    .frame(width: .statusIconWidth)
                VStack(alignment: .leading, spacing: Margin.x1) {
                    Text(otherNode?.name ?? relationship.id)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    Text("\(relationship.kind.localizedTitle) · \(relationship.status.localizedTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Margin.x4)
                Image(systemName: AppSymbols.chevron)
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Margin.x8)
            .frame(minHeight: .minimumRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.Graph.Relationship.open(otherNode?.name ?? relationship.id)
        )
        .accessibilityValue("\(relationship.kind.localizedTitle), \(relationship.status.localizedTitle)")
    }
}

// MARK: - Private methods

private extension RelationshipListView {
    func otherNode(for relationship: GraphRelationship) -> GraphNode? {
        let otherID = relationship.sourceID == node.id ? relationship.targetID : relationship.sourceID
        return graph.node(id: otherID)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let statusIconWidth = 24.0
    static let minimumRowHeight = 56.0
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    RelationshipListView(
        node: GraphFixture.spike.featuredNode,
        relationships: Array(GraphFixture.spike.relationships.prefix(3)),
        graph: GraphFixture.spike,
        onOpen: { _ in }
    )
    .frame(height: 220)
}

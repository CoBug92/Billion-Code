import SwiftUI

struct RelationshipDetailView: View {
    let relationship: GraphRelationship
    let source: GraphNode?
    let target: GraphNode?
    let sources: [GraphSource]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Margin.x8) {
                    entities
                    status
                    Text(relationship.explanation)
                        .font(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    if !relationship.contexts.isEmpty {
                        contexts
                    }
                    evidenceSummary
                    if !sources.isEmpty {
                        sourceList
                    }
                }
                .padding(Margin.x8)
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .navigationTitle(L10n.Graph.Relationship.Detail.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Layout

private extension RelationshipDetailView {
    var entities: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            Text(source?.name ?? relationship.sourceID)
                .font(.title3.bold())
            Text(target?.name ?? relationship.targetID)
                .font(.title3.bold())
        }
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .accessibilityElement(children: .combine)
    }

    var status: some View {
        HStack(spacing: Margin.x4) {
            Image(systemName: relationship.status.symbolName)
            VStack(alignment: .leading, spacing: Margin.x1) {
                Text(relationship.kind.localizedTitle)
                    .font(.headline)
                Text(relationship.status.localizedTitle)
                    .font(.subheadline)
            }
        }
        .foregroundStyle(relationship.status == .disputed ? Color.orange : Asset.Colors.accentColor.swiftUIColor)
        .accessibilityElement(children: .combine)
    }

    var contexts: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            Text(L10n.Graph.Relationship.Contexts.title)
                .font(.headline)
            ForEach(relationship.contexts) { context in
                Text(context.name)
                    .font(.subheadline)
            }
        }
    }

    var evidenceSummary: some View {
        Text(
            L10n.Graph.Relationship.Evidence.summary(
                relationship.claimIDs.count,
                relationship.sourceIDs.count
            )
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    var sourceList: some View {
        VStack(alignment: .leading, spacing: Margin.x4) {
            Text(L10n.Graph.Relationship.Sources.title)
                .font(.headline)
            ForEach(sources) { source in
                Link(destination: source.url) {
                    VStack(alignment: .leading, spacing: Margin.x1) {
                        Text(source.title)
                            .font(.subheadline.weight(.semibold))
                        Text("\(source.publisher) · \(source.tier)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let relationship = GraphFixture.spike.relationships[8]
    RelationshipDetailView(
        relationship: relationship,
        source: GraphFixture.spike.node(id: relationship.sourceID),
        target: GraphFixture.spike.node(id: relationship.targetID),
        sources: []
    )
}

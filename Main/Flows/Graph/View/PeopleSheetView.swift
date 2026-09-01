import SwiftUI

struct PeopleSheetView: View {
    let people: [GraphNode]
    let selectedNodeID: GraphNode.ID
    let onSelect: (GraphNode.ID) -> Void

    @State private var query = TechnicalString.empty

    var body: some View {
        NavigationStack {
            List(filteredPeople) { person in
                Button {
                    onSelect(person.id)
                } label: {
                    HStack(spacing: Margin.x5) {
                        Image(systemName: AppSymbols.person)
                            .foregroundStyle(Asset.Colors.accentColor.swiftUIColor)
                            .frame(
                                width: .minimumTouchTarget,
                                height: .minimumTouchTarget
                            )
                        VStack(alignment: .leading, spacing: Margin.x2) {
                            Text(person.name)
                                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                            Text(person.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: Margin.x4)
                        if person.id == selectedNodeID {
                            Image(systemName: AppSymbols.confirmed)
                                .accessibilityLabel(L10n.Graph.Node.selected)
                        }
                    }
                }
                .accessibilityHint(L10n.Graph.Node.hint)
            }
            .navigationTitle(L10n.Graph.Sheet.title)
            .searchable(
                text: $query,
                prompt: Text(L10n.Graph.Sheet.search)
            )
        }
    }
}

// MARK: - Computed properties

private extension PeopleSheetView {
    var filteredPeople: [GraphNode] {
        guard !query.isEmpty else { return people }
        return people.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let minimumTouchTarget = 44.0
}

// MARK: - Preview

#Preview {
    PeopleSheetView(
        people: GraphFixture.spike.nodes.filter { $0.kind == .person },
        selectedNodeID: GraphFixture.spike.featuredNodeID,
        onSelect: { _ in }
    )
}

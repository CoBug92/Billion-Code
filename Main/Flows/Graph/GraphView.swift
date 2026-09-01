import SwiftUI

struct GraphView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: GraphViewModel
    @State private var panelDetent = GraphPanelDetent.collapsed
    @State private var showsPeople = false
    @State private var presentedRelationship: GraphRelationship?

    init(viewModel: GraphViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    graphContent(bottomInset: panelDetent == .expanded ? .zero : .collapsedPanelInset)
                    GraphBottomPanel(
                        node: viewModel.selectedNode,
                        relationships: viewModel.selectedRelationships,
                        graph: viewModel.graph,
                        availableHeight: geometry.size.height,
                        topSafeArea: geometry.safeAreaInsets.top,
                        bottomSafeArea: geometry.safeAreaInsets.bottom,
                        onSelectNode: selectNode,
                        onOpenRelationship: { presentedRelationship = $0 },
                        detent: $panelDetent
                    )
                    .ignoresSafeArea(edges: panelDetent == .expanded ? .all : .bottom)
                }
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsPeople) {
                PeopleSheetView(
                    people: viewModel.people,
                    selectedNodeID: viewModel.selectedNodeID,
                    onSelect: { nodeID in
                        selectNode(nodeID)
                        showsPeople = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $presentedRelationship) { relationship in
                RelationshipDetailView(
                    relationship: relationship,
                    source: viewModel.graph.node(id: relationship.sourceID),
                    target: viewModel.graph.node(id: relationship.targetID),
                    sources: viewModel.graph.sources.filter { relationship.sourceIDs.contains($0.id) }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}

private extension GraphView {
    func graphContent(bottomInset: CGFloat) -> some View {
        VStack(spacing: .zero) {
            header
            GraphSceneView(viewModel: viewModel)
                .frame(maxHeight: .infinity)
        }
        .padding(.bottom, bottomInset)
    }

    var header: some View {
        HStack(alignment: .center, spacing: Margin.x6) {
            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(L10n.Graph.title)
                    .font(.title2.bold())
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                Text(L10n.Graph.Featured.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Margin.x4)
            Button { showsPeople = true } label: {
                Image(systemName: AppSymbols.people)
                    .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
            }
            .accessibilityLabel(L10n.Graph.People.open)
        }
        .padding(.horizontal, Margin.x8)
        .padding(.vertical, Margin.x5)
    }

    func selectNode(_ id: GraphNode.ID) {
        guard !reduceMotion else {
            viewModel.selectNode(id: id)
            return
        }
        withAnimation(.snappy) {
            viewModel.selectNode(id: id)
        }
    }
}

private extension CGFloat {
    static let collapsedPanelInset = 112.0
    static let minimumTouchTarget = 44.0
}

#Preview {
    GraphView(viewModel: GraphViewModel(graph: GraphFixture.spike))
}

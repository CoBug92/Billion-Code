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
                    GraphSceneView(
                        viewModel: viewModel,
                        panelDetent: panelDetent
                    )
                    .ignoresSafeArea()
                    header(topSafeArea: geometry.safeAreaInsets.top)
                    GraphBottomPanel(
                        node: viewModel.selectedNode,
                        chapterTitle: viewModel.activeChapter.title,
                        chapterAccent: viewModel.activeChapter.accentColor,
                        relationships: viewModel.selectedRelationships,
                        graph: viewModel.atlas.graphData,
                        availableHeight: geometry.size.height,
                        topSafeArea: geometry.safeAreaInsets.top,
                        bottomSafeArea: geometry.safeAreaInsets.bottom,
                        onSelectNode: selectNode,
                        onOpenRelationship: { presentedRelationship = $0 },
                        detent: $panelDetent
                    )
                    .ignoresSafeArea(edges: panelDetent == .expanded ? .all : .bottom)
                }
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
                    source: viewModel.atlas.node(id: relationship.sourceID),
                    target: viewModel.atlas.node(id: relationship.targetID),
                    sources: viewModel.atlas.sources.filter { relationship.sourceIDs.contains($0.id) }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Layout

private extension GraphView {
    func header(topSafeArea: CGFloat) -> some View {
        VStack {
            HStack(alignment: .center, spacing: Margin.x6) {
                VStack(alignment: .leading, spacing: Margin.x2) {
                    Text(L10n.Graph.title)
                        .font(.headline.bold())
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    Text(
                        L10n.Graph.Chapter.position(
                            viewModel.activeChapterIndex + 1,
                            viewModel.atlas.chapters.count
                        )
                    )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(viewModel.activeChapter.accentColor)
                }
                Spacer(minLength: Margin.x4)
                Button { showsPeople = true } label: {
                    Image(systemName: AppSymbols.people)
                        .frame(
                            width: .minimumTouchTarget,
                            height: .minimumTouchTarget
                        )
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Graph.People.open)
            }
            .padding(.top, topSafeArea + Margin.x3)
            .padding(.horizontal, Margin.x8)
            Spacer()
        }
    }
}

// MARK: - Private methods

private extension GraphView {
    func selectNode(_ id: GraphNode.ID) {
        if reduceMotion {
            viewModel.selectNode(id: id)
        } else {
            withAnimation(.smooth(duration: .chapterTransitionDuration)) {
                viewModel.selectNode(id: id)
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let minimumTouchTarget = 44.0
}

private extension Double {
    static let chapterTransitionDuration = 0.55
}

// MARK: - Preview

#Preview("Dark Atlas") {
    GraphView(viewModel: GraphViewModel(atlas: GraphAtlasFixture.editorial))
        .preferredColorScheme(.dark)
}

#Preview("Light Atlas") {
    GraphView(viewModel: GraphViewModel(atlas: GraphAtlasFixture.editorial))
        .preferredColorScheme(.light)
}

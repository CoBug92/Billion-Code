import SwiftUI

struct DenseGraphRootView: View {
    @State private var viewModel: DenseGraphViewModel
    @State private var panelDetent: DenseDossierDetent
    @State private var isDossierPresented: Bool
    @State private var didFocusInitialSelection = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: DenseGraphViewModel) {
        _viewModel = State(initialValue: viewModel)
        _isDossierPresented = State(initialValue: viewModel.hasSelection)
#if DEBUG
        let startsExpanded = ProcessInfo.processInfo.arguments.contains("-expandedDossier")
        _panelDetent = State(initialValue: startsExpanded ? .expanded : .compact)
#else
        _panelDetent = State(initialValue: .compact)
#endif
    }

    var body: some View {
        GeometryReader { geometry in
            DenseGraphSceneView(
                viewModel: viewModel,
                visibleGraphFrame: visibleGraphFrame(geometry: geometry)
            )
                .sheet(isPresented: $isDossierPresented, onDismiss: dossierDidDismiss) {
                    dossierSheet(geometry: geometry)
                }
                .onChange(of: viewModel.selectedNodeID, initial: true) { previousID, selectedID in
                    selectionDidChange(from: previousID, to: selectedID)
                }
                .onAppear {
                    focusInitialSelectionIfNeeded(geometry: geometry)
                }
        }
    }
}

// MARK: - Dossier presentation

private extension DenseGraphRootView {
    @ViewBuilder
    func dossierSheet(geometry: GeometryProxy) -> some View {
        if let node = viewModel.selectedNode, let dossier = viewModel.selectedDossier {
            DenseGraphDossierPanel(
                node: node,
                dossier: dossier,
                canNavigateBack: viewModel.canNavigateBack,
                detent: $panelDetent,
                onNavigate: { nodeID in navigate(to: nodeID, geometry: geometry) },
                onBack: navigateBack
            )
            .presentationDetents(
                Set(DenseDossierDetent.allCases.map(\.presentationDetent)),
                selection: nativeDetent
            )
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(Asset.Colors.surfacePrimary.swiftUIColor)
            .presentationBackgroundInteraction(
                .enabled(upThrough: DenseDossierDetent.compact.presentationDetent)
            )
            .presentationContentInteraction(.scrolls)
        }
    }

    var nativeDetent: Binding<PresentationDetent> {
        Binding(
            get: { panelDetent.presentationDetent },
            set: { panelDetent = DenseDossierDetent.resolve($0) }
        )
    }

    func selectionDidChange(from previousID: GraphNode.ID?, to selectedID: GraphNode.ID?) {
        guard selectedID != nil else {
            isDossierPresented = false
            return
        }
        if previousID != selectedID {
            panelDetent = .compact
        }
        isDossierPresented = true
    }

    func dossierDidDismiss() {
        guard viewModel.hasSelection else { return }
        viewModel.clearSelection()
    }
}

// MARK: - Navigation

private extension DenseGraphRootView {
    func navigate(to nodeID: GraphNode.ID, geometry: GeometryProxy) {
        guard viewModel.graph.node(id: nodeID) != nil else { return }
        let visibleGraphFrame = visibleGraphFrame(geometry: geometry)

        withAnimation(reduceMotion ? nil : .smooth(duration: .dossierNavigationAnimationDuration)) {
            panelDetent = .compact
            viewModel.navigate(
                to: nodeID,
                viewport: geometry.size,
                visibleGraphFrame: visibleGraphFrame
            )
        }
    }

    func navigateBack() {
        withAnimation(reduceMotion ? nil : .smooth(duration: .dossierNavigationAnimationDuration)) {
            panelDetent = .compact
            viewModel.navigateBack()
        }
    }

    func visibleGraphFrame(geometry: GeometryProxy) -> CGRect {
        let panelHeight = DenseDossierDetent.estimatedCoveredHeight(
            availableHeight: geometry.size.height,
            bottomSafeArea: geometry.safeAreaInsets.bottom
        )
        let panelTop = geometry.size.height - panelHeight
        return CGRect(
            x: .zero,
            y: geometry.safeAreaInsets.top,
            width: geometry.size.width,
            height: max(panelTop - geometry.safeAreaInsets.top, .zero)
        )
    }

    func focusInitialSelectionIfNeeded(geometry: GeometryProxy) {
        guard !didFocusInitialSelection, let selectedNodeID = viewModel.selectedNodeID else { return }
        didFocusInitialSelection = true
        viewModel.focus(
            on: selectedNodeID,
            viewport: geometry.size,
            visibleGraphFrame: visibleGraphFrame(geometry: geometry)
        )
    }
}

// MARK: - Constants

private extension Double {
    static let dossierNavigationAnimationDuration = 0.42
}

extension DenseDossierDetent {
    var presentationDetent: PresentationDetent {
        switch self {
        case .compact: .fraction(Self.compactFraction)
        case .expanded: .large
        }
    }

    static func resolve(_ presentationDetent: PresentationDetent) -> DenseDossierDetent {
        presentationDetent == .large ? .expanded : .compact
    }
}

// MARK: - Preview

#Preview("Graph with dossier") {
    DenseGraphRootView(viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance))
        .preferredColorScheme(.dark)
}

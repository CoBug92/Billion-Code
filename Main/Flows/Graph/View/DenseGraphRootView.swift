import Foundation
import SwiftUI

struct DenseGraphRootView: View {
    @State private var viewModel: DenseGraphViewModel
    @State private var panelDetent = DenseDossierDetent.compact

    init(viewModel: DenseGraphViewModel) {
        _viewModel = State(initialValue: viewModel)
#if DEBUG
        _panelDetent = State(
            initialValue: ProcessInfo.processInfo.arguments.contains("-expandedDossier") ? .expanded : .compact
        )
#endif
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                DenseGraphSceneView(viewModel: viewModel)

                if let node = viewModel.selectedNode, let dossier = viewModel.selectedDossier {
                    DenseGraphDossierPanel(
                        node: node,
                        dossier: dossier,
                        availableHeight: geometry.size.height,
                        topSafeArea: geometry.safeAreaInsets.top,
                        bottomSafeArea: geometry.safeAreaInsets.bottom,
                        canNavigateBack: viewModel.canNavigateBack,
                        detent: $panelDetent,
                        onNavigate: navigate,
                        onBack: navigateBack
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .ignoresSafeArea(edges: panelDetent == .expanded ? .all : .bottom)
                }
            }
            .animation(.snappy, value: viewModel.selectedNodeID)
        }
    }
}

private extension DenseGraphRootView {
    func navigate(to nodeID: GraphNode.ID) {
        panelDetent = .compact
        withAnimation(.smooth) {
            viewModel.navigate(to: nodeID)
        }
    }

    func navigateBack() {
        panelDetent = .compact
        withAnimation(.smooth) {
            viewModel.navigateBack()
        }
    }
}

#Preview("Graph with dossier") {
    DenseGraphRootView(viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance))
        .preferredColorScheme(.dark)
}

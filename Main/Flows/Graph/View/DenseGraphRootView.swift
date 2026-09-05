import Foundation
import SwiftUI

struct DenseGraphRootView: View {
    @State private var viewModel: DenseGraphViewModel
    @State private var panelDetent = DenseDossierDetent.collapsed
    @State private var compactPanelHeight = CGFloat.zero
    @State private var pendingFocusedNodeID: GraphNode.ID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: DenseGraphViewModel) {
        _viewModel = State(initialValue: viewModel)
#if DEBUG
        _panelDetent = State(
            initialValue: ProcessInfo.processInfo.arguments.contains("-expandedDossier") ? .expanded : .collapsed
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
                        bottomSafeArea: geometry.safeAreaInsets.bottom,
                        canNavigateBack: viewModel.canNavigateBack,
                        detent: $panelDetent,
                        onNavigate: { nodeID in
                            navigate(to: nodeID, geometry: geometry)
                        },
                        onBack: navigateBack,
                        onClose: closeDossier,
                        onCompactHeightChange: { nodeID, height in
                            updateCompactPanelHeight(height, for: nodeID, geometry: geometry)
                        }
                    )
                    .offset(y: geometry.safeAreaInsets.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(reduceMotion ? nil : .dossierSheet, value: viewModel.selectedNodeID)
            .onChange(of: viewModel.selectedNodeID) { _, selectedNodeID in
                guard selectedNodeID != nil else { return }
                guard pendingFocusedNodeID == nil else {
                    if pendingFocusedNodeID != selectedNodeID { pendingFocusedNodeID = nil }
                    return
                }
                panelDetent = .collapsed
            }
        }
    }
}

// MARK: - Private methods

private extension DenseGraphRootView {
    func navigate(to nodeID: GraphNode.ID, geometry: GeometryProxy) {
        guard viewModel.graph.node(id: nodeID) != nil else { return }
        pendingFocusedNodeID = nodeID
        let visibleGraphFrame = visibleGraphFrame(
            geometry: geometry,
            panelHeight: effectiveCompactPanelHeight(geometry: geometry)
        )

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
        pendingFocusedNodeID = viewModel.selectedNodeID
        withAnimation(reduceMotion ? nil : .smooth(duration: .dossierNavigationAnimationDuration)) {
            panelDetent = .compact
            viewModel.navigateBack()
        }
    }

    func closeDossier() {
        pendingFocusedNodeID = nil
        panelDetent = .collapsed
        viewModel.clearSelection()
    }

    func updateCompactPanelHeight(_ height: CGFloat, for nodeID: GraphNode.ID, geometry: GeometryProxy) {
        compactPanelHeight = height
        guard pendingFocusedNodeID == nodeID, viewModel.selectedNodeID == nodeID else { return }

        withAnimation(reduceMotion ? nil : .smooth(duration: .dossierNavigationAnimationDuration)) {
            viewModel.focus(
                on: nodeID,
                viewport: geometry.size,
                visibleGraphFrame: visibleGraphFrame(geometry: geometry, panelHeight: height)
            )
        }
        pendingFocusedNodeID = nil
    }

    func effectiveCompactPanelHeight(geometry: GeometryProxy) -> CGFloat {
        guard compactPanelHeight > .zero else {
            return DenseDossierDetent.fallbackCompactHeight(
                availableHeight: geometry.size.height,
                bottomSafeArea: geometry.safeAreaInsets.bottom
            )
        }
        return compactPanelHeight
    }

    func visibleGraphFrame(geometry: GeometryProxy, panelHeight: CGFloat) -> CGRect {
        let panelTop = geometry.size.height - panelHeight + geometry.safeAreaInsets.bottom
        return CGRect(
            x: .zero,
            y: geometry.safeAreaInsets.top,
            width: geometry.size.width,
            height: max(panelTop - geometry.safeAreaInsets.top, .zero)
        )
    }
}

// MARK: - Constants

private extension Double {
    static let dossierNavigationAnimationDuration = 0.45
}

private extension Animation {
    static let dossierSheet = Animation.spring(response: 0.4, dampingFraction: 0.94)
}

// MARK: - Preview

#Preview("Graph with dossier") {
    DenseGraphRootView(viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance))
        .preferredColorScheme(.dark)
}

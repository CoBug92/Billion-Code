import SwiftUI

struct GraphSceneView: View {
    let viewModel: GraphViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var focusedNodeID: GraphNode.ID?
    @State private var lastDragTranslation = CGSize.zero
    @State private var lastMagnification = 1.0
    @State private var focusTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                edges(viewport: geometry.size)
                nodes(viewport: geometry.size)
                controls
            }
            .clipped()
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Layout

private extension GraphSceneView {
    func edges(viewport: CGSize) -> some View {
        Canvas { context, _ in
            for relationship in viewModel.graph.relationships {
                guard
                    let source = viewModel.graph.node(id: relationship.sourceID),
                    let target = viewModel.graph.node(id: relationship.targetID)
                else { continue }

                var path = Path()
                path.move(to: viewModel.camera.screenPoint(for: source.position, viewport: viewport))
                path.addLine(to: viewModel.camera.screenPoint(for: target.position, viewport: viewport))

                context.stroke(
                    path,
                    with: .color(Asset.Colors.textPrimary.swiftUIColor.opacity(.edgeOpacity)),
                    style: relationship.status.strokeStyle
                )
            }
        }
        .contentShape(Rectangle())
        .gesture(panGesture)
        .simultaneousGesture(zoomGesture)
        .accessibilityHidden(true)
    }

    func nodes(viewport: CGSize) -> some View {
        ForEach(viewModel.graph.nodes) { node in
            GraphNodeView(
                node: node,
                isSelected: node.id == viewModel.selectedNodeID,
                action: { select(node: node) }
            )
            .position(viewModel.camera.screenPoint(for: node.position, viewport: viewport))
            .accessibilityFocused($focusedNodeID, equals: node.id)
        }
    }

    var controls: some View {
        VStack(spacing: Margin.x3) {
            controlButton(
                symbol: AppSymbols.zoomIn,
                label: L10n.Graph.Zoom.in,
                action: { viewModel.zoom(by: .controlZoomFactor) }
            )
            controlButton(
                symbol: AppSymbols.zoomOut,
                label: L10n.Graph.Zoom.out,
                action: { viewModel.zoom(by: 1 / .controlZoomFactor) }
            )
            controlButton(
                symbol: AppSymbols.resetCamera,
                label: L10n.Graph.Reset.camera,
                action: resetCamera
            )
        }
        .padding(Margin.x5)
    }

    func controlButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(
                    width: .minimumTouchTarget,
                    height: .minimumTouchTarget
                )
                .background(Asset.Colors.surfacePrimary.swiftUIColor, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Gestures

private extension GraphSceneView {
    var panGesture: some Gesture {
        DragGesture(minimumDistance: .minimumDragDistance)
            .onChanged { value in
                let delta = CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                )
                viewModel.pan(by: delta)
                lastDragTranslation = value.translation
            }
            .onEnded { _ in
                lastDragTranslation = .zero
            }
    }

    var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let factor = value.magnification / lastMagnification
                viewModel.zoom(by: factor)
                lastMagnification = value.magnification
            }
            .onEnded { _ in
                lastMagnification = 1
            }
    }
}

// MARK: - Private methods

private extension GraphSceneView {
    func select(node: GraphNode) {
        focusTask?.cancel()
        if reduceMotion {
            viewModel.selectNode(id: node.id)
            focusedNodeID = node.id
            return
        }

        withAnimation(.snappy(duration: .recenterDuration)) {
            viewModel.selectNode(id: node.id)
        }
        focusTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            focusedNodeID = node.id
        }
    }

    func resetCamera() {
        guard let featured = viewModel.graph.node(id: viewModel.graph.featuredNodeID) else { return }
        select(node: featured)
    }
}

// MARK: - Presentation

private extension GraphRelationship.Status {
    var strokeStyle: StrokeStyle {
        switch self {
        case .confirmed:
            StrokeStyle(lineWidth: .edgeLineWidth)
        case .disputed:
            StrokeStyle(
                lineWidth: .edgeLineWidth,
                dash: [.dashLength, .dashGap]
            )
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let minimumTouchTarget = 44.0
    static let minimumDragDistance = 8.0
    static let edgeLineWidth = 1.25
    static let dashLength = 6.0
    static let dashGap = 5.0
}

private extension Double {
    static let controlZoomFactor = 1.25
    static let recenterDuration = 0.3
    static let edgeOpacity = 0.34
}

// MARK: - Preview

#Preview {
    GraphSceneView(
        viewModel: GraphViewModel(graph: GraphFixture.spike)
    )
    .frame(height: 480)
}

import SwiftUI

struct DenseGraphSceneView: View {
    let viewModel: DenseGraphViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragStartCamera: GraphCamera?
    @State private var magnifyStartCamera: GraphCamera?
    @State private var searchText = ""
    @State private var suppressNodeSelection = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background
                edgeCanvas(viewport: geometry.size)

                ForEach(viewModel.visibleNodes(in: geometry.size)) { node in
                    DenseGraphNodeView(
                        node: node,
                        isSelected: viewModel.selectedNodeID == node.id,
                        isHighlighted: viewModel.isHighlighted(nodeID: node.id),
                        showsLabel: viewModel.shouldShowLabel(for: node)
                    ) {
                        select(node: node)
                    }
                    .position(viewModel.camera.screenPoint(for: node.position, viewport: geometry.size))
                }

                controls
            }
            .contentShape(Rectangle())
            .simultaneousGesture(panGesture)
            .simultaneousGesture(magnificationGesture)
            .accessibilityAction(named: "Сбросить масштаб") {
                resetCamera()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Canvas

private extension DenseGraphSceneView {
    func edgeCanvas(viewport: CGSize) -> some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            for edge in viewModel.graph.edges {
                guard viewModel.isEdgeVisible(edge) else { continue }
                guard
                    let source = viewModel.graph.node(id: edge.sourceID),
                    let target = viewModel.graph.node(id: edge.targetID)
                else { continue }

                let sourcePoint = viewModel.camera.screenPoint(for: source.position, viewport: viewport)
                let targetPoint = viewModel.camera.screenPoint(for: target.position, viewport: viewport)
                guard edgeIsVisible(source: sourcePoint, target: targetPoint, viewport: viewport) else { continue }

                let isHighlighted = viewModel.isHighlighted(edgeID: edge.id)
                let opacity = edgeOpacity(isHighlighted: isHighlighted)
                var path = Path()
                path.move(to: sourcePoint)
                path.addLine(to: targetPoint)
                context.stroke(
                    path,
                    with: .color(isHighlighted ? edge.kind.color.opacity(opacity) : .secondary.opacity(opacity)),
                    lineWidth: isHighlighted ? 2.2 : 0.75
                )

                if isHighlighted && viewModel.camera.scale >= 0.07 {
                    drawLabels(
                        for: edge,
                        source: sourcePoint,
                        target: targetPoint,
                        context: context
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    func drawLabels(
        for edge: DenseGraphEdge,
        source: CGPoint,
        target: CGPoint,
        context: GraphicsContext
    ) {
        let ordered = source.x <= target.x ? (source, target) : (target, source)
        let deltaX = ordered.1.x - ordered.0.x
        let deltaY = ordered.1.y - ordered.0.y
        let midpoint = CGPoint(
            x: (ordered.0.x + ordered.1.x) / 2,
            y: (ordered.0.y + ordered.1.y) / 2
        )
        let angle = Angle.radians(atan2(deltaY, deltaX))
        var labelContext = context
        labelContext.translateBy(x: midpoint.x, y: midpoint.y)
        labelContext.rotate(by: angle)

        let period = labelContext.resolve(
            Text(edge.period)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(edge.kind.color)
        )
        let detail = labelContext.resolve(
            Text(edge.detail)
                .font(.system(size: 8, weight: .regular, design: .rounded))
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor.opacity(0.72))
        )
        labelContext.draw(period, at: CGPoint(x: 0, y: -7), anchor: .bottom)
        labelContext.draw(detail, at: CGPoint(x: 0, y: 7), anchor: .top)
    }

    func edgeOpacity(isHighlighted: Bool) -> Double {
        if isHighlighted { return 0.9 }
        return viewModel.hasSelection ? 0.035 : 0.18
    }

    func edgeIsVisible(source: CGPoint, target: CGPoint, viewport: CGSize) -> Bool {
        let bounds = CGRect(origin: .zero, size: viewport).insetBy(dx: -100, dy: -100)
        return bounds.contains(source) || bounds.contains(target)
    }
}

// MARK: - Chrome

private extension DenseGraphSceneView {
    var background: some View {
        ZStack {
            Asset.Colors.backgroundPrimary.swiftUIColor
            RadialGradient(
                colors: [
                    Asset.Colors.chapterBlue.swiftUIColor.opacity(0.12),
                    Asset.Colors.backgroundPrimary.swiftUIColor.opacity(0)
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 520
            )
        }
        .onTapGesture {
            withAnimation(selectionAnimation) {
                viewModel.clearSelection()
            }
        }
    }

    var controls: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    search
                    filters
                }
                Spacer()
                Button(action: resetCamera) {
                    Image(systemName: "scope")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Показать весь граф")
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    var search: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Поиск", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Очистить поиск")
                }
            }
            .padding(.horizontal, 12)
            .frame(width: 230, height: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

            let results = viewModel.searchResults(matching: searchText)
            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { node in
                        Button {
                            searchText = ""
                            viewModel.selectNode(id: node.id)
                            viewModel.focus(on: node.id)
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(node.kind.denseGraphColor)
                                    .frame(width: 8, height: 8)
                                Text(node.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                            .padding(.horizontal, 12)
                            .frame(width: 230, height: 38)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    var filters: some View {
        HStack(spacing: 10) {
            filterButton(kind: .person, title: "Люди", shape: .circle)
            filterButton(kind: .organization, title: "Компании", shape: .diamond)
            filterButton(kind: .university, title: "Вузы", shape: .triangle)
        }
        .font(.caption2)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor.opacity(0.82))
        .padding(.horizontal, 11)
        .frame(minHeight: 44)
        .background(.ultraThinMaterial, in: Capsule())
    }

    func filterButton(kind: GraphEntityKind, title: String, shape: DenseLegendShape) -> some View {
        let isVisible = viewModel.isNodeKindVisible(kind)
        return Button {
            withAnimation(selectionAnimation) {
                viewModel.setNodeKind(kind, isVisible: !isVisible)
            }
        } label: {
            HStack(spacing: 4) {
                shape.view(color: kind.denseGraphColor)
                    .frame(width: 8, height: 8)
                Text(title)
            }
            .opacity(isVisible ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isVisible ? "Показано" : "Скрыто")
    }
}

// MARK: - Gestures

private extension DenseGraphSceneView {
    var panGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if dragStartCamera == nil {
                    dragStartCamera = viewModel.camera
                }
                guard var camera = dragStartCamera else { return }
                camera.pan(by: value.translation)
                viewModel.updateCamera(camera)
            }
            .onEnded { _ in
                dragStartCamera = nil
            }
    }

    var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                suppressNodeSelection = true
                if magnifyStartCamera == nil {
                    magnifyStartCamera = viewModel.camera
                }
                guard var camera = magnifyStartCamera else { return }
                camera.zoom(by: value.magnification)
                viewModel.updateCamera(camera)
            }
            .onEnded { _ in
                magnifyStartCamera = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    suppressNodeSelection = false
                }
            }
    }
}

// MARK: - Actions

private extension DenseGraphSceneView {
    var selectionAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.18)
    }

    func select(node: GraphNode) {
        guard !suppressNodeSelection else { return }
        let animation = viewModel.hasSelection ? selectionAnimation : nil
        withAnimation(animation) {
            viewModel.selectNode(id: node.id)
        }
    }

    func resetCamera() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) {
            viewModel.resetCamera()
        }
    }
}

private enum DenseLegendShape {
    case circle
    case diamond
    case triangle

    @ViewBuilder
    func view(color: Color) -> some View {
        switch self {
        case .circle:
            Circle().fill(color)
        case .diamond:
            RoundedRectangle(cornerRadius: 1).fill(color).rotationEffect(.degrees(45))
        case .triangle:
            Image(systemName: "triangle.fill").resizable().foregroundStyle(color)
        }
    }
}

#Preview("Dense graph") {
    DenseGraphSceneView(
        viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance)
    )
    .preferredColorScheme(.dark)
}

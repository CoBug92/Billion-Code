import SwiftUI

struct DenseGraphSceneView: View {
    let viewModel: DenseGraphViewModel
    let visibleGraphFrame: CGRect?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragStartCamera: GraphCamera?
    @State private var magnifyStartCamera: GraphCamera?
    @State private var searchText = ""
    @State private var suppressNodeSelection = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let renderFrame = viewModel.renderFrame(in: geometry.size)
            ZStack {
                ZStack {
                    background
                    edgeCanvas(edges: renderFrame.edges, viewport: geometry.size)

                    ForEach(renderFrame.nodes) { node in
                        DenseGraphNodeView(
                            node: node,
                            isSelected: viewModel.selectedNodeID == node.id,
                            isHighlighted: viewModel.isHighlighted(nodeID: node.id),
                            showsLabel: viewModel.shouldShowLabel(for: node)
                        ) {
                            select(node: node)
                        }
                        .position(
                            viewModel.camera.screenPoint(
                                for: viewModel.displayPosition(for: node),
                                viewport: geometry.size
                            )
                        )
                    }
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .simultaneousGesture(panGesture)
                .simultaneousGesture(magnificationGesture)

                controls(viewport: geometry.size)
                    .zIndex(1)
            }
        }
    }
}

// MARK: - Canvas

private extension DenseGraphSceneView {
    func edgeCanvas(edges: [DenseGraphEdge], viewport: CGSize) -> some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            for edge in edges {
                guard
                    let source = viewModel.node(id: edge.sourceID),
                    let target = viewModel.node(id: edge.targetID)
                else { continue }

                let sourcePoint = viewModel.camera.screenPoint(
                    for: viewModel.displayPosition(for: source),
                    viewport: viewport
                )
                let targetPoint = viewModel.camera.screenPoint(
                    for: viewModel.displayPosition(for: target),
                    viewport: viewport
                )
                guard viewModel.isLocalFocusActive
                    || edgeIsVisible(source: sourcePoint, target: targetPoint, viewport: viewport)
                else { continue }

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
            dismissSearch()
            withAnimation(selectionAnimation) {
                viewModel.clearSelection()
            }
        }
    }

    func controls(viewport: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            search
            filters
            if viewModel.hasSelection {
                DenseGraphFocusButton(isActive: viewModel.isLocalFocusActive) {
                    withAnimation(reduceMotion ? nil : .smooth(duration: .localFocusAnimationDuration)) {
                        viewModel.toggleLocalFocus(
                            viewport: viewport,
                            visibleGraphFrame: visibleGraphFrame ?? CGRect(origin: .zero, size: viewport)
                        )
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .focused($isSearchFocused)
                    .submitLabel(.done)
                    .onSubmit(dismissSearch)
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
                if isSearchFocused {
                    Button(action: dismissSearch) {
                        Image(systemName: AppSymbols.keyboardDismiss)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Скрыть клавиатуру")
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

            if isSearchFocused {
                let results = viewModel.searchResults(matching: searchText)
                if !results.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(results) { node in
                            Button {
                                selectSearchResult(node)
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
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    var filters: some View {
        HStack(spacing: 6) {
            filterButton(kind: .person, title: "Люди", shape: .circle)
            filterButton(kind: .organization, title: "Компании", shape: .diamond)
            filterButton(kind: .university, title: "Вузы", shape: .triangle)
        }
        .font(.caption2)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor.opacity(0.82))
        .padding(.horizontal, 8)
        .frame(width: 230)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity)
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
                suppressNodeSelection = true
                if dragStartCamera == nil {
                    dragStartCamera = viewModel.camera
                }
                guard let camera = dragStartCamera else { return }
                viewModel.panCamera(from: camera, by: value.translation)
            }
            .onEnded { _ in
                dragStartCamera = nil
                releaseNodeSelectionAfterGesture()
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
                releaseNodeSelectionAfterGesture()
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

    func releaseNodeSelectionAfterGesture() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            suppressNodeSelection = false
        }
    }

    func selectSearchResult(_ node: GraphNode) {
        dismissSearch()
        withAnimation(reduceMotion ? nil : .smooth(duration: .graphNavigationAnimationDuration)) {
            if viewModel.selectedNodeID != node.id {
                viewModel.selectNode(id: node.id)
            }
            viewModel.focus(on: node.id)
        }
    }

    func dismissSearch() {
        isSearchFocused = false
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

// MARK: - Constants

private extension Double {
    static let graphNavigationAnimationDuration = 0.45
    static let localFocusAnimationDuration = 0.55
}

// MARK: - Preview

#Preview("Dense graph") {
    DenseGraphSceneView(
        viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance),
        visibleGraphFrame: nil
    )
    .preferredColorScheme(.dark)
}

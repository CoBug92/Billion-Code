import SwiftUI

struct GraphSceneView: View {
    let viewModel: GraphViewModel
    let panelDetent: GraphPanelDetent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var focusedNodeID: GraphNode.ID?
    @State private var magnificationAnchor = UnitPoint.center

    var body: some View {
        GeometryReader { geometry in
            let positions = ChapterGraphLayout().layout(
                chapter: viewModel.activeChapter,
                atlas: viewModel.atlas,
                layoutVersion: viewModel.atlas.layoutVersion
            )
            let contentRect = sceneRect(geometry: geometry)

            ZStack {
                GraphAtlasBackgroundView(chapter: viewModel.activeChapter)
                chapterContent(
                    positions: positions,
                    contentRect: contentRect
                )
                .scaleEffect(
                    viewModel.magnification,
                    anchor: magnificationAnchor
                )
                portals
            }
            .contentShape(Rectangle())
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(chapterSwipeGesture)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: L10n.Graph.Chapter.Previous.action) {
            changeChapter(viewModel.selectPreviousChapter)
        }
        .accessibilityAction(named: L10n.Graph.Chapter.Next.action) {
            changeChapter(viewModel.selectNextChapter)
        }
    }
}

// MARK: - Layout

private extension GraphSceneView {
    func chapterContent(
        positions: [GraphNode.ID: NormalizedGraphPoint],
        contentRect: CGRect
    ) -> some View {
        ZStack {
            routes(positions: positions, contentRect: contentRect)
            nodes(positions: positions, contentRect: contentRect)
        }
    }

    func routes(
        positions: [GraphNode.ID: NormalizedGraphPoint],
        contentRect: CGRect
    ) -> some View {
        Canvas { context, _ in
            for route in viewModel.activeRoutes {
                guard
                    let source = positions[route.sourceID],
                    let target = positions[route.targetID]
                else { continue }

                let sourcePoint = screenPoint(source, in: contentRect)
                let targetPoint = screenPoint(target, in: contentRect)
                let controlPoint = curveControlPoint(
                    source: sourcePoint,
                    target: targetPoint,
                    routeID: route.id
                )
                var path = Path()
                path.move(to: sourcePoint)
                path.addQuadCurve(to: targetPoint, control: controlPoint)
                context.stroke(
                    path,
                    with: .color(viewModel.activeChapter.accentColor.opacity(.routeOpacity)),
                    style: route.strokeStyle
                )
            }
        }
        .accessibilityHidden(true)
    }

    func nodes(
        positions: [GraphNode.ID: NormalizedGraphPoint],
        contentRect: CGRect
    ) -> some View {
        ForEach(viewModel.activeNodes) { node in
            if let position = positions[node.id] {
                GraphNodeView(
                    node: node,
                    role: role(for: node),
                    isSelected: node.id == viewModel.selectedNodeID,
                    accentColor: viewModel.activeChapter.accentColor,
                    action: { select(node: node) }
                )
                .position(screenPoint(position, in: contentRect))
                .transition(.scale(scale: .nodeTransitionScale).combined(with: .opacity))
                .accessibilityFocused($focusedNodeID, equals: node.id)
            }
        }
    }

    var portals: some View {
        VStack {
            Spacer()
            HStack {
                if let previous = viewModel.previousChapter {
                    GraphChapterPortalView(
                        chapter: previous,
                        direction: .previous,
                        action: { changeChapter(viewModel.selectPreviousChapter) }
                    )
                }
                Spacer()
                if let next = viewModel.nextChapter {
                    GraphChapterPortalView(
                        chapter: next,
                        direction: .next,
                        action: { changeChapter(viewModel.selectNextChapter) }
                    )
                }
            }
            .padding(.horizontal, Margin.x5)
            .padding(.bottom, .portalBottomInset)
        }
    }

    func sceneRect(geometry: GeometryProxy) -> CGRect {
        let top = geometry.safeAreaInsets.top + .sceneTopInset
        let bottom = max(geometry.safeAreaInsets.bottom, .sceneBottomInset)
        return CGRect(
            x: .sceneHorizontalInset,
            y: top,
            width: max(geometry.size.width - .sceneHorizontalInset * 2, .zero),
            height: max(geometry.size.height - top - bottom, .minimumSceneHeight)
        )
    }

    func screenPoint(_ point: NormalizedGraphPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * point.x,
            y: rect.minY + rect.height * point.y
        )
    }

    func role(for node: GraphNode) -> GraphNodeVisualRole {
        if node.id == viewModel.activeChapter.heroNodeID {
            return .hero
        }
        return node.id == viewModel.selectedNodeID ? .selected : .member
    }

    func curveControlPoint(
        source: CGPoint,
        target: CGPoint,
        routeID: String
    ) -> CGPoint {
        let midpoint = CGPoint(x: (source.x + target.x) / 2, y: (source.y + target.y) / 2)
        let delta = CGVector(dx: target.x - source.x, dy: target.y - source.y)
        let length = max(hypot(delta.dx, delta.dy), 1)
        let direction = routeID.utf8.reduce(0) { $0 + Int($1) }.isMultiple(of: 2) ? 1.0 : -1.0
        return CGPoint(
            x: midpoint.x - delta.dy / length * .curveOffset * direction,
            y: midpoint.y + delta.dx / length * .curveOffset * direction
        )
    }
}

// MARK: - Gestures

private extension GraphSceneView {
    var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                magnificationAnchor = value.startAnchor
                viewModel.updateMagnification(value.magnification)
            }
            .onEnded { _ in
                if reduceMotion {
                    viewModel.resetMagnification()
                } else {
                    withAnimation(.snappy(duration: .zoomResetDuration)) {
                        viewModel.resetMagnification()
                    }
                }
                magnificationAnchor = .center
                Task { @MainActor in
                    await Task.yield()
                    viewModel.finishMagnificationGesture()
                }
            }
    }

    var chapterSwipeGesture: some Gesture {
        DragGesture(minimumDistance: .minimumSwipeDistance)
            .onEnded { value in
                changeChapter {
                    viewModel.handleChapterSwipe(
                        translation: value.translation,
                        predictedEndTranslation: value.predictedEndTranslation,
                        panelDetent: panelDetent
                    )
                }
            }
    }
}

// MARK: - Private methods

private extension GraphSceneView {
    func select(node: GraphNode) {
        if reduceMotion {
            viewModel.selectNode(id: node.id)
            focusedNodeID = node.id
        } else {
            withAnimation(.smooth(duration: .selectionDuration)) {
                viewModel.selectNode(id: node.id)
            }
            focusedNodeID = node.id
        }
    }

    func changeChapter(_ action: () -> Void) {
        if reduceMotion {
            action()
        } else {
            withAnimation(.smooth(duration: .chapterTransitionDuration)) {
                action()
            }
        }
    }
}

// MARK: - Presentation

private extension GraphRoute {
    var strokeStyle: StrokeStyle {
        let width = switch kind {
        case .sharedContext: CGFloat.sharedRouteWidth
        case .direct: CGFloat.directRouteWidth
        }
        return switch status {
        case .confirmed:
            StrokeStyle(lineWidth: width, lineCap: .round)
        case .disputed:
            StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                dash: [.dashLength, .dashGap]
            )
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let curveOffset = 28.0
    static let dashGap = 5.0
    static let dashLength = 7.0
    static let directRouteWidth = 2.8
    static let minimumSceneHeight = 320.0
    static let minimumSwipeDistance = 24.0
    static let nodeTransitionScale = 0.72
    static let portalBottomInset = 154.0
    static let sceneBottomInset = 180.0
    static let sceneHorizontalInset = 14.0
    static let sceneTopInset = 74.0
    static let sharedRouteWidth = 1.35
}

private extension Double {
    static let chapterTransitionDuration = 0.55
    static let routeOpacity = 0.78
    static let selectionDuration = 0.32
    static let zoomResetDuration = 0.24
}

// MARK: - Preview

#Preview("Tesla · Dark") {
    GraphSceneView(
        viewModel: GraphViewModel(atlas: GraphAtlasFixture.editorial),
        panelDetent: .collapsed
    )
    .preferredColorScheme(.dark)
}

#Preview("Tesla · Light") {
    GraphSceneView(
        viewModel: GraphViewModel(atlas: GraphAtlasFixture.editorial),
        panelDetent: .collapsed
    )
    .preferredColorScheme(.light)
}

#Preview("OpenAI · Dark") {
    let viewModel = GraphViewModel(atlas: GraphAtlasFixture.editorial)
    viewModel.selectChapter(id: "organization:openai")
    return GraphSceneView(
        viewModel: viewModel,
        panelDetent: .collapsed
    )
    .preferredColorScheme(.dark)
}

#Preview("OpenAI · Light") {
    let viewModel = GraphViewModel(atlas: GraphAtlasFixture.editorial)
    viewModel.selectChapter(id: "organization:openai")
    return GraphSceneView(
        viewModel: viewModel,
        panelDetent: .collapsed
    )
    .preferredColorScheme(.light)
}

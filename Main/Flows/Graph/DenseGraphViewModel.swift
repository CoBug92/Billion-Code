import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class DenseGraphViewModel {

    // MARK: - Properties

    let graph: DenseGraphData
    private(set) var camera = GraphCamera(
        center: GraphPoint(x: 5_000, y: 5_000),
        scale: 0.035
    )
    private(set) var selectedNodeID: GraphNode.ID?
    private(set) var highlightedNodeIDs = Set<GraphNode.ID>()
    private(set) var directlyConnectedNodeIDs = Set<GraphNode.ID>()
    private(set) var highlightedEdgeIDs = Set<DenseGraphEdge.ID>()
    private(set) var navigationHistory: [NavigationEntry] = []
    private(set) var hiddenNodeKinds = Set<GraphEntityKind>()
    private(set) var isLocalFocusActive = false

    private let nodesByID: [GraphNode.ID: GraphNode]
    private let edgesByNodeID: [GraphNode.ID: [DenseGraphEdge]]
    private let nodesInRenderingOrder: [GraphNode]
    private var localFocusNodeIDs = Set<GraphNode.ID>()
    private var localFocusPositions: [GraphNode.ID: GraphPoint] = [:]
    private var localFocusEdges: [DenseGraphEdge] = []
    private var cameraBeforeLocalFocus: GraphCamera?

    // MARK: - Init

    init(graph: DenseGraphData) {
        self.graph = graph
        nodesByID = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })

        var edgesByNodeID: [GraphNode.ID: [DenseGraphEdge]] = [:]
        for edge in graph.edges {
            edgesByNodeID[edge.sourceID, default: []].append(edge)
            edgesByNodeID[edge.targetID, default: []].append(edge)
        }
        self.edgesByNodeID = edgesByNodeID
        nodesInRenderingOrder = graph.nodes.sorted { left, right in
            let leftPriority = left.kind == .person ? 1 : 0
            let rightPriority = right.kind == .person ? 1 : 0
            return leftPriority == rightPriority ? left.id < right.id : leftPriority < rightPriority
        }
    }

    // MARK: - Computed properties

    var selectedNode: GraphNode? {
        selectedNodeID.flatMap { nodesByID[$0] }
    }

    var hasSelection: Bool {
        selectedNodeID != nil
    }

    var selectedDossier: EntityDossier? {
        selectedNodeID.flatMap { graph.dossier(id: $0) }
    }

    var canNavigateBack: Bool {
        !navigationHistory.isEmpty
    }

    func isNodeKindVisible(_ kind: GraphEntityKind) -> Bool {
        !hiddenNodeKinds.contains(kind)
    }

    func setNodeKind(_ kind: GraphEntityKind, isVisible: Bool) {
        exitLocalFocus()
        if isVisible {
            hiddenNodeKinds.remove(kind)
        } else {
            hiddenNodeKinds.insert(kind)
            if selectedNode?.kind == kind {
                clearSelection()
            }
        }
    }

    func searchResults(matching query: String, limit: Int = 8) -> [GraphNode] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        return graph.nodes
            .filter { node in
                isNodeKindVisible(node.kind)
                    && (node.name.localizedCaseInsensitiveContains(normalizedQuery)
                        || node.shortName.localizedCaseInsensitiveContains(normalizedQuery))
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Selection

    func selectNode(id: GraphNode.ID) {
        guard let node = nodesByID[id] else { return }
        guard selectedNodeID != id else {
            clearSelection()
            return
        }

        let isNodeInLocalFocus = localFocusNodeIDs.contains(node.id)
        let localFocusAnchor = isLocalFocusActive && isNodeInLocalFocus ? displayPosition(for: node) : nil
        if isLocalFocusActive && !isNodeInLocalFocus {
            exitLocalFocus()
        }
        navigationHistory.removeAll()
        applySelection(node)
        if let localFocusAnchor {
            rebuildLocalFocus(around: node, anchor: localFocusAnchor)
        }
    }

    func navigate(to id: GraphNode.ID) {
        navigate(to: id, focus: nil)
    }

    func navigate(to id: GraphNode.ID, viewport: CGSize, visibleGraphFrame: CGRect) {
        navigate(
            to: id,
            focus: NavigationFocus(
                viewport: viewport,
                screenPoint: CGPoint(x: visibleGraphFrame.midX, y: visibleGraphFrame.midY)
            )
        )
    }

    private func navigate(to id: GraphNode.ID, focus: NavigationFocus?) {
        guard
            let node = nodesByID[id],
            isNodeKindVisible(node.kind),
            selectedNodeID != id
        else { return }
        exitLocalFocus()
        if let selectedNodeID {
            navigationHistory.append(NavigationEntry(nodeID: selectedNodeID, camera: camera))
        }
        applySelection(node)
        if let focus {
            camera.recenter(on: node.position, at: focus.screenPoint, viewport: focus.viewport)
        } else {
            self.focus(on: node.id)
        }
    }

    func navigateBack() {
        guard let previous = navigationHistory.popLast(), let node = nodesByID[previous.nodeID] else { return }
        applySelection(node)
        camera = previous.camera
    }

    private func applySelection(_ node: GraphNode) {
        selectedNodeID = node.id
        let directEdges = edgesByNodeID[node.id, default: []]
        highlightedNodeIDs = [node.id]
        directlyConnectedNodeIDs = [node.id]
        highlightedEdgeIDs = Set(directEdges.map(\.id))

        for edge in directEdges {
            if let oppositeID = edge.opposite(node.id) {
                highlightedNodeIDs.insert(oppositeID)
                directlyConnectedNodeIDs.insert(oppositeID)
            }
        }

        guard node.kind == .person else { return }
        let institutionEdges = directEdges.filter { edge in
            guard let oppositeID = edge.opposite(node.id), let opposite = nodesByID[oppositeID] else { return false }
            return opposite.kind == .organization || opposite.kind == .university
        }

        for selectedEdge in institutionEdges {
            guard let institutionID = selectedEdge.opposite(node.id) else { continue }
            for edge in edgesByNodeID[institutionID, default: []] {
                guard edge.id == selectedEdge.id || periodsOverlap(selectedEdge, edge) else { continue }
                highlightedEdgeIDs.insert(edge.id)
                highlightedNodeIDs.insert(edge.sourceID)
                highlightedNodeIDs.insert(edge.targetID)
            }
        }
    }

    func clearSelection() {
        exitLocalFocus()
        selectedNodeID = nil
        highlightedNodeIDs.removeAll()
        directlyConnectedNodeIDs.removeAll()
        highlightedEdgeIDs.removeAll()
        navigationHistory.removeAll()
    }

    func isHighlighted(nodeID: GraphNode.ID) -> Bool {
        !hasSelection || highlightedNodeIDs.contains(nodeID)
    }

    func isHighlighted(edgeID: DenseGraphEdge.ID) -> Bool {
        hasSelection && highlightedEdgeIDs.contains(edgeID)
    }

    func shouldShowLabel(for node: GraphNode) -> Bool {
        if isLocalFocusActive {
            return true
        }
        if node.kind == .person {
            return true
        }
        if hasSelection {
            return directlyConnectedNodeIDs.contains(node.id)
        }
        return true
    }

    private func periodsOverlap(_ left: DenseGraphEdge, _ right: DenseGraphEdge) -> Bool {
        guard
            let leftPeriod = DenseGraphPeriod(left.period),
            let rightPeriod = DenseGraphPeriod(right.period)
        else { return false }
        return leftPeriod.overlaps(rightPeriod)
    }

    // MARK: - Camera

    func updateCamera(_ camera: GraphCamera) {
        self.camera = camera
    }

    func panCamera(from initialCamera: GraphCamera, by translation: CGSize) {
        var updatedCamera = initialCamera
        let ranges = cameraPanRanges
        updatedCamera.pan(
            by: translation,
            horizontalRange: ranges.horizontal,
            verticalRange: ranges.vertical
        )
        camera = updatedCamera
    }

    func focus(on nodeID: GraphNode.ID) {
        guard let node = nodesByID[nodeID] else { return }
        let ranges = cameraPanRanges
        camera.recenter(
            on: displayPosition(for: node),
            horizontalRange: ranges.horizontal,
            verticalRange: ranges.vertical
        )
    }

    func focus(on nodeID: GraphNode.ID, viewport: CGSize, visibleGraphFrame: CGRect) {
        guard let node = nodesByID[nodeID] else { return }
        let ranges = cameraPanRanges
        camera.recenter(
            on: displayPosition(for: node),
            at: CGPoint(x: visibleGraphFrame.midX, y: visibleGraphFrame.midY),
            viewport: viewport,
            horizontalRange: ranges.horizontal,
            verticalRange: ranges.vertical
        )
    }

    func renderFrame(in viewport: CGSize) -> RenderFrame {
        let nodes = visibleNodes(in: viewport)
        if isLocalFocusActive {
            return RenderFrame(nodes: nodes, edges: localFocusEdges)
        }
        var seenEdgeIDs = Set<DenseGraphEdge.ID>()
        var edges: [DenseGraphEdge] = []

        for node in nodes {
            for edge in edgesByNodeID[node.id, default: []] where isEdgeVisible(edge) {
                if seenEdgeIDs.insert(edge.id).inserted {
                    edges.append(edge)
                }
            }
        }

        return RenderFrame(nodes: nodes, edges: edges)
    }

    func visibleNodes(in viewport: CGSize, overscan: CGFloat = 80) -> [GraphNode] {
        var nodes = nodesInRenderingOrder.filter { node in
            guard isNodeKindVisible(node.kind) else { return false }
            guard !isLocalFocusActive || localFocusNodeIDs.contains(node.id) else { return false }
            let point = camera.screenPoint(for: displayPosition(for: node), viewport: viewport)
            return point.x >= -overscan
                && point.y >= -overscan
                && point.x <= viewport.width + overscan
                && point.y <= viewport.height + overscan
        }

        if let selectedNodeID, let selectedIndex = nodes.firstIndex(where: { $0.id == selectedNodeID }) {
            nodes.append(nodes.remove(at: selectedIndex))
        }
        return nodes
    }

    func node(id: GraphNode.ID) -> GraphNode? {
        nodesByID[id]
    }

    func displayPosition(for node: GraphNode) -> GraphPoint {
        guard isLocalFocusActive else { return node.position }
        return localFocusPositions[node.id] ?? node.position
    }

    func isEdgeVisible(_ edge: DenseGraphEdge) -> Bool {
        guard let source = nodesByID[edge.sourceID], let target = nodesByID[edge.targetID] else {
            return false
        }
        let kindsAreVisible = isNodeKindVisible(source.kind) && isNodeKindVisible(target.kind)
        guard isLocalFocusActive else { return kindsAreVisible }
        return kindsAreVisible
            && localFocusNodeIDs.contains(source.id)
            && localFocusNodeIDs.contains(target.id)
            && highlightedEdgeIDs.contains(edge.id)
    }

    // MARK: - Local focus

    func enterLocalFocus() {
        guard let selectedNode, !isLocalFocusActive else { return }
        cameraBeforeLocalFocus = camera
        rebuildLocalFocus(around: selectedNode, anchor: selectedNode.position)
        isLocalFocusActive = true
    }

    private func rebuildLocalFocus(around selectedNode: GraphNode, anchor: GraphPoint) {
        guard let result = DenseGraphLocalFocusLayout().layout(
            nodes: nodesInRenderingOrder,
            edges: graph.edges,
            selectedNode: selectedNode,
            highlightedNodeIDs: highlightedNodeIDs,
            directlyConnectedNodeIDs: directlyConnectedNodeIDs,
            highlightedEdgeIDs: highlightedEdgeIDs,
            anchor: anchor
        ) else { return }
        localFocusNodeIDs = result.nodeIDs
        localFocusPositions = result.positions
        localFocusEdges = result.edges
    }

    func exitLocalFocus() {
        guard isLocalFocusActive else { return }
        if let cameraBeforeLocalFocus {
            camera = cameraBeforeLocalFocus
        }
        cameraBeforeLocalFocus = nil
        localFocusNodeIDs.removeAll()
        localFocusPositions.removeAll()
        localFocusEdges.removeAll()
        isLocalFocusActive = false
    }

    func toggleLocalFocus() {
        if isLocalFocusActive {
            exitLocalFocus()
        } else {
            enterLocalFocus()
        }
    }

    private var cameraPanRanges: (horizontal: ClosedRange<Double>, vertical: ClosedRange<Double>) {
        guard
            isLocalFocusActive,
            let minimumX = localFocusPositions.values.map(\.x).min(),
            let maximumX = localFocusPositions.values.map(\.x).max(),
            let minimumY = localFocusPositions.values.map(\.y).min(),
            let maximumY = localFocusPositions.values.map(\.y).max()
        else {
            return (.zero ... .graphWorldSide, .zero ... .graphWorldSide)
        }
        return (
            minimumX - .localFocusPanPadding ... maximumX + .localFocusPanPadding,
            minimumY - .localFocusPanPadding ... maximumY + .localFocusPanPadding
        )
    }
}

private extension DenseGraphViewModel {
    struct NavigationFocus {
        let viewport: CGSize
        let screenPoint: CGPoint
    }
}

private extension Double {
    static let localFocusPanPadding = 800.0
    static let graphWorldSide = 10_000.0
}

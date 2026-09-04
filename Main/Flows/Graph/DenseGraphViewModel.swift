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

    private let nodesByID: [GraphNode.ID: GraphNode]
    private let edgesByNodeID: [GraphNode.ID: [DenseGraphEdge]]
    private let degreesByNodeID: [GraphNode.ID: Int]

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
        degreesByNodeID = edgesByNodeID.mapValues(\.count)
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

        navigationHistory.removeAll()
        applySelection(node)
    }

    func navigate(to id: GraphNode.ID) {
        guard
            let node = nodesByID[id],
            isNodeKindVisible(node.kind),
            selectedNodeID != id
        else { return }
        if let selectedNodeID {
            navigationHistory.append(NavigationEntry(nodeID: selectedNodeID, camera: camera))
        }
        applySelection(node)
        focus(on: node.id)
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
        if hasSelection {
            return directlyConnectedNodeIDs.contains(node.id)
        }
        return node.kind != .person || degreesByNodeID[node.id, default: .zero] >= 4
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

    func resetCamera() {
        camera = GraphCamera(center: GraphPoint(x: 5_000, y: 5_000), scale: 0.035)
    }

    func focus(on nodeID: GraphNode.ID) {
        guard let node = nodesByID[nodeID] else { return }
        camera.recenter(on: node.position)
    }

    func visibleNodes(in viewport: CGSize, overscan: CGFloat = 80) -> [GraphNode] {
        graph.nodes.filter { node in
            guard isNodeKindVisible(node.kind) else { return false }
            let point = camera.screenPoint(for: node.position, viewport: viewport)
            return point.x >= -overscan
                && point.y >= -overscan
                && point.x <= viewport.width + overscan
                && point.y <= viewport.height + overscan
        }
    }

    func isEdgeVisible(_ edge: DenseGraphEdge) -> Bool {
        guard let source = nodesByID[edge.sourceID], let target = nodesByID[edge.targetID] else {
            return false
        }
        return isNodeKindVisible(source.kind) && isNodeKindVisible(target.kind)
    }
}

extension DenseGraphViewModel {
    struct NavigationEntry: Equatable, Sendable {
        let nodeID: GraphNode.ID
        let camera: GraphCamera
    }
}

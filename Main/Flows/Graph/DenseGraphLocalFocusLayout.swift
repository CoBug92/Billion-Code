struct DenseGraphLocalFocusLayout {
    func layout(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        selectedNode: GraphNode,
        highlightedNodeIDs: Set<GraphNode.ID>,
        directlyConnectedNodeIDs: Set<GraphNode.ID>,
        highlightedEdgeIDs: Set<DenseGraphEdge.ID>,
        anchor: GraphPoint
    ) -> Result? {
        let orderedIDs = highlightedNodeIDs.sorted { leftID, rightID in
            priority(for: leftID, selectedNodeID: selectedNode.id, directNodeIDs: directlyConnectedNodeIDs)
                < priority(for: rightID, selectedNodeID: selectedNode.id, directNodeIDs: directlyConnectedNodeIDs)
        }
        let nodeIDs = Set(orderedIDs.prefix(.maximumLocalFocusNodes))
        let focusNodes = nodes.filter { nodeIDs.contains($0.id) }
        let focusEdges = edges.filter { edge in
            highlightedEdgeIDs.contains(edge.id)
                && nodeIDs.contains(edge.sourceID)
                && nodeIDs.contains(edge.targetID)
        }
        let positions = DenseGraphLayout().layout(
            nodes: focusNodes,
            edges: focusEdges,
            layoutVersion: .localFocusLayoutVersion
        )
        guard let selectedFocusPosition = positions[selectedNode.id] else { return nil }

        return Result(
            nodeIDs: nodeIDs,
            edges: focusEdges,
            positions: positions.mapValues { point in
                GraphPoint(
                    x: anchor.x + (point.x - selectedFocusPosition.x) * .localFocusSpread,
                    y: anchor.y + (point.y - selectedFocusPosition.y) * .localFocusSpread
                )
            }
        )
    }
}

// MARK: - Private methods

private extension DenseGraphLocalFocusLayout {
    func priority(
        for nodeID: GraphNode.ID,
        selectedNodeID: GraphNode.ID,
        directNodeIDs: Set<GraphNode.ID>
    ) -> (Int, String) {
        if nodeID == selectedNodeID { return (.zero, nodeID) }
        if directNodeIDs.contains(nodeID) { return (1, nodeID) }
        return (2, nodeID)
    }
}

// MARK: - Result

extension DenseGraphLocalFocusLayout {
    struct Result {
        let nodeIDs: Set<GraphNode.ID>
        let edges: [DenseGraphEdge]
        let positions: [GraphNode.ID: GraphPoint]
    }
}

// MARK: - Constants

private extension Int {
    static let localFocusLayoutVersion = 2_001
    static let maximumLocalFocusNodes = 20
}

private extension Double {
    static let localFocusSpread = 0.55
}

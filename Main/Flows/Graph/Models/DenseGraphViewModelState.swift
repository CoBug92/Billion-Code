extension DenseGraphViewModel {
    struct RenderFrame {
        let nodes: [GraphNode]
        let edges: [DenseGraphEdge]
    }

    struct NavigationEntry: Equatable, Sendable {
        let nodeID: GraphNode.ID
        let camera: GraphCamera
    }
}

import CoreGraphics
import Observation

@MainActor
@Observable
final class GraphViewModel {

    // MARK: - Properties

    let graph: GraphData
    private(set) var selectedNodeID: GraphNode.ID
    private(set) var camera: GraphCamera

    // MARK: - Init

    init(graph: GraphData) {
        precondition(graph.nodes.count <= 40, "The graph spike supports at most 40 visible nodes")
        precondition(graph.relationships.count <= 80, "The graph spike supports at most 80 visible relationships")
        self.graph = graph
        selectedNodeID = graph.featuredNodeID
        camera = GraphCamera(center: graph.featuredNode.position)
    }

    // MARK: - Computed properties

    var selectedNode: GraphNode {
        graph.node(id: selectedNodeID) ?? graph.featuredNode
    }

    var selectedRelationships: [GraphRelationship] {
        graph.relationships(for: selectedNodeID)
    }

    var people: [GraphNode] {
        graph.nodes.filter { $0.kind == .person }
    }

    // MARK: - Public methods

    func selectNode(id: GraphNode.ID) {
        guard let node = graph.node(id: id) else { return }
        selectedNodeID = node.id
        camera.recenter(on: node.position)
    }

    func resetCamera() {
        selectNode(id: graph.featuredNodeID)
    }

    func pan(by translation: CGSize) {
        camera.pan(by: translation)
    }

    func zoom(by factor: Double) {
        camera.zoom(by: factor)
    }

    func node(opposite relationship: GraphRelationship, from nodeID: GraphNode.ID) -> GraphNode? {
        let otherID = relationship.sourceID == nodeID ? relationship.targetID : relationship.sourceID
        return graph.node(id: otherID)
    }
}

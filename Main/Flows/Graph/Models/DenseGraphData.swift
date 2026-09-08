import Foundation

struct DenseGraphData: Sendable {
    let nodes: [GraphNode]
    let edges: [DenseGraphEdge]
    let dossiers: [GraphNode.ID: EntityDossier]

    init(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        dossiers: [GraphNode.ID: EntityDossier] = [:]
    ) {
        self.nodes = nodes
        self.edges = edges
        self.dossiers = dossiers
    }

    func node(id: GraphNode.ID) -> GraphNode? {
        nodes.first { $0.id == id }
    }

    func dossier(id: GraphNode.ID) -> EntityDossier? {
        dossiers[id]
    }
}

struct DenseGraphEdge: Identifiable, Equatable, Sendable {
    let id: String
    let sourceID: GraphNode.ID
    let targetID: GraphNode.ID
    let kind: Kind
    let period: String
    let detail: String

    enum Kind: Equatable, Sendable {
        case business
        case education
        case family
        case association
    }

    func connects(_ nodeID: GraphNode.ID) -> Bool {
        sourceID == nodeID || targetID == nodeID
    }

    func opposite(_ nodeID: GraphNode.ID) -> GraphNode.ID? {
        if sourceID == nodeID { return targetID }
        if targetID == nodeID { return sourceID }
        return nil
    }
}

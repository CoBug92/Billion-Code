import Foundation

struct GraphData: Equatable, Sendable {
    let featuredNodeID: GraphNode.ID
    let nodes: [GraphNode]
    let relationships: [GraphRelationship]
    let sources: [GraphSource]

    init(
        featuredNodeID: GraphNode.ID,
        nodes: [GraphNode],
        relationships: [GraphRelationship],
        sources: [GraphSource] = []
    ) {
        self.featuredNodeID = featuredNodeID
        self.nodes = nodes
        self.relationships = relationships
        self.sources = sources
    }
}

struct GraphSource: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let publisher: String
    let url: URL
    let tier: String
}

extension GraphData {
    var featuredNode: GraphNode {
        guard let node = nodes.first(where: { $0.id == featuredNodeID }) else {
            preconditionFailure("The graph fixture must contain its featured node")
        }
        return node
    }

    func node(id: GraphNode.ID) -> GraphNode? {
        nodes.first(where: { $0.id == id })
    }

    func relationships(for nodeID: GraphNode.ID) -> [GraphRelationship] {
        relationships.filter { relationship in
            relationship.sourceID == nodeID || relationship.targetID == nodeID
        }
    }
}

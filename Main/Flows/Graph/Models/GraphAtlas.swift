import Foundation

struct GraphAtlas: Equatable, Sendable {
    let featuredNodeID: GraphNode.ID
    let nodes: [GraphNode]
    let chapters: [GraphChapter]
    let relationships: [GraphRelationship]
    let sources: [GraphSource]
    let layoutVersion: Int

    var leadChapter: GraphChapter {
        guard let chapter = chapters.first else {
            preconditionFailure("The graph atlas must contain a lead chapter")
        }
        return chapter
    }

    var graphData: GraphData {
        GraphData(
            featuredNodeID: featuredNodeID,
            nodes: nodes,
            relationships: relationships,
            sources: sources
        )
    }

    func node(id: GraphNode.ID) -> GraphNode? {
        nodes.first { $0.id == id }
    }

    func chapter(id: GraphChapter.ID) -> GraphChapter? {
        chapters.first { $0.id == id }
    }

    func firstChapter(containing nodeID: GraphNode.ID) -> GraphChapter? {
        chapters.first { $0.memberIDs.contains(nodeID) }
    }

    func relationships(for nodeID: GraphNode.ID) -> [GraphRelationship] {
        relationships.filter { $0.sourceID == nodeID || $0.targetID == nodeID }
    }
}

struct GraphChapter: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let heroNodeID: GraphNode.ID
    let memberIDs: [GraphNode.ID]
    let routes: [GraphRoute]
    let accentIndex: Int

    func contains(_ nodeID: GraphNode.ID) -> Bool {
        memberIDs.contains(nodeID)
    }
}

struct GraphRoute: Identifiable, Equatable, Sendable {
    let id: String
    let sourceID: GraphNode.ID
    let targetID: GraphNode.ID
    let kind: Kind
    let status: GraphRelationship.Status
    let relationship: GraphRelationship

    enum Kind: Equatable, Sendable {
        case sharedContext
        case direct(GraphRelationship.Kind)
    }

    func connects(_ nodeID: GraphNode.ID) -> Bool {
        sourceID == nodeID || targetID == nodeID
    }
}

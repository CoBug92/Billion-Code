struct GraphRelationship: Identifiable, Equatable, Sendable {
    let id: String
    let sourceID: GraphNode.ID
    let targetID: GraphNode.ID
    let kind: Kind
    let status: Status
    let explanation: String
    let contexts: [Context]
    let claimIDs: [String]
    let sourceIDs: [String]

    init(
        id: String,
        sourceID: GraphNode.ID,
        targetID: GraphNode.ID,
        kind: Kind,
        status: Status,
        explanation: String,
        contexts: [Context] = [],
        claimIDs: [String] = [],
        sourceIDs: [String] = []
    ) {
        self.id = id
        self.sourceID = sourceID
        self.targetID = targetID
        self.kind = kind
        self.status = status
        self.explanation = explanation
        self.contexts = contexts
        self.claimIDs = claimIDs
        self.sourceIDs = sourceIDs
    }
}

extension GraphRelationship {
    enum Kind: Equatable, Sendable {
        case family
        case founded
        case cofounded
        case employment
        case executiveRole
        case boardRole
        case ownership
        case investment
        case deal
        case education
        case philanthropy
        case legalDispute
        case sharedContext
    }

    enum Status: Equatable, Sendable {
        case confirmed
        case disputed
    }

    struct Context: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        let relationshipKinds: [String]
    }
}

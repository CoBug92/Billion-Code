import Foundation

struct DenseGraphData: Sendable {
    let nodes: [GraphNode]
    let edges: [DenseGraphEdge]
    let dossiers: [GraphNode.ID: EntityDossier]
    let sections: [DenseGraphSection]
    let personSectionIDs: [GraphNode.ID: [DenseGraphSection.ID]]
    let sectionMemberships: [DenseGraphSectionMembership]

    init(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        dossiers: [GraphNode.ID: EntityDossier] = [:],
        sections: [DenseGraphSection] = [],
        personSectionIDs: [GraphNode.ID: [DenseGraphSection.ID]] = [:],
        sectionMemberships: [DenseGraphSectionMembership] = []
    ) {
        self.nodes = nodes
        self.edges = edges
        self.dossiers = dossiers
        self.sections = sections
        self.personSectionIDs = personSectionIDs
        self.sectionMemberships = sectionMemberships
    }

    func node(id: GraphNode.ID) -> GraphNode? {
        nodes.first { $0.id == id }
    }

    func dossier(id: GraphNode.ID) -> EntityDossier? {
        dossiers[id]
    }

    func section(id: DenseGraphSection.ID) -> DenseGraphSection? {
        sections.first { $0.id == id }
    }

    func sections(for personID: GraphNode.ID) -> [DenseGraphSection] {
        let sectionIDs = Set(personSectionIDs[personID, default: []])
        return sections.filter { sectionIDs.contains($0.id) }
    }

    func membershipPosition(
        for personID: GraphNode.ID,
        in sectionID: DenseGraphSection.ID
    ) -> GraphPoint? {
        sectionMemberships.first {
            $0.personID == personID && $0.sectionID == sectionID
        }?.position
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

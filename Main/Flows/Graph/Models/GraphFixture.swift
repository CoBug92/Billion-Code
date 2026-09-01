import Foundation

enum GraphFixture {
    static let spike: GraphData = {
        let nodes = makeNodes()
        return GraphData(
            featuredNodeID: nodes[0].id,
            nodes: nodes,
            relationships: makeRelationships(nodes: nodes)
        )
    }()
}

// MARK: - Private methods

private extension GraphFixture {
    static func makeNodes() -> [GraphNode] {
        let center = GraphNode(
            id: "person:alexey-vorontsov",
            kind: .person,
            name: L10n.Graph.Fixture.Featured.name,
            shortName: L10n.Graph.Fixture.Featured.shortName,
            summary: L10n.Graph.Fixture.Featured.summary,
            position: GraphPoint(x: .worldCenter, y: .worldCenter)
        )
        let kinds = GraphEntityKind.allCases
        let surroundingNodes = (1 ..< 40).map { index in
            let ringMetadata = ringMetadata(for: index)
            let angle = Double(ringMetadata.slot) / Double(ringMetadata.count) * 2 * Double.pi
                + Double(ringMetadata.ring) * 0.19
            let radius = Double(ringMetadata.ring) * 1_400
            let kind = kinds[index % kinds.count]

            return GraphNode(
                id: "\(kind.idPrefix):fixture-\(index)",
                kind: kind,
                name: kind.fixtureName(index: index),
                shortName: kind.fixtureShortName(index: index),
                summary: kind.fixtureSummary,
                position: GraphPoint(
                    x: .worldCenter + cos(angle) * radius,
                    y: .worldCenter + sin(angle) * radius
                )
            )
        }
        return [center] + surroundingNodes
    }

    static func ringMetadata(for index: Int) -> (ring: Int, slot: Int, count: Int) {
        switch index {
        case 1 ... 8:
            (1, index - 1, 8)
        case 9 ... 21:
            (2, index - 9, 13)
        default:
            (3, index - 22, 18)
        }
    }

    static func makeRelationships(nodes: [GraphNode]) -> [GraphRelationship] {
        let centerRelationships = (1 ..< nodes.count).map { index in
            relationship(
                index: index,
                source: nodes[0],
                target: nodes[index]
            )
        }
        let ringRelationships = (1 ..< nodes.count).map { index in
            let targetIndex = index == nodes.count - 1 ? 1 : index + 1
            return relationship(
                index: 40 + index,
                source: nodes[index],
                target: nodes[targetIndex]
            )
        }
        let chords = [
            relationship(index: 79, source: nodes[4], target: nodes[22]),
            relationship(index: 80, source: nodes[9], target: nodes[31])
        ]
        return centerRelationships + ringRelationships + chords
    }

    static func relationship(index: Int, source: GraphNode, target: GraphNode) -> GraphRelationship {
        let isDisputed = index.isMultiple(of: 9)
        return GraphRelationship(
            id: "relationship:fixture-\(index)",
            sourceID: source.id,
            targetID: target.id,
            kind: GraphRelationship.Kind.allFixtureKinds[index % GraphRelationship.Kind.allFixtureKinds.count],
            status: isDisputed ? .disputed : .confirmed,
            explanation: isDisputed
                ? L10n.Graph.Fixture.Relationship.disputed
                : L10n.Graph.Fixture.Relationship.confirmed
        )
    }
}

// MARK: - Fixture metadata

private extension GraphEntityKind {
    var idPrefix: String {
        switch self {
        case .person: "person"
        case .organization: "organization"
        case .university: "university"
        case .foundation: "foundation"
        case .family: "family"
        case .deal: "deal"
        case .event: "event"
        }
    }

    func fixtureName(index: Int) -> String {
        switch self {
        case .person: L10n.Graph.Fixture.Entity.Person.name(index)
        case .organization: L10n.Graph.Fixture.Entity.Organization.name(index)
        case .university: L10n.Graph.Fixture.Entity.University.name(index)
        case .foundation: L10n.Graph.Fixture.Entity.Foundation.name(index)
        case .family: L10n.Graph.Fixture.Entity.Family.name(index)
        case .deal: L10n.Graph.Fixture.Entity.Deal.name(index)
        case .event: L10n.Graph.Fixture.Entity.Event.name(index)
        }
    }

    func fixtureShortName(index: Int) -> String {
        switch self {
        case .person: L10n.Graph.Fixture.Entity.Person.shortName(index)
        case .organization: L10n.Graph.Fixture.Entity.Organization.shortName(index)
        case .university: L10n.Graph.Fixture.Entity.University.shortName(index)
        case .foundation: L10n.Graph.Fixture.Entity.Foundation.shortName(index)
        case .family: L10n.Graph.Fixture.Entity.Family.shortName(index)
        case .deal: L10n.Graph.Fixture.Entity.Deal.shortName(index)
        case .event: L10n.Graph.Fixture.Entity.Event.shortName(index)
        }
    }

    var fixtureSummary: String {
        switch self {
        case .person: L10n.Graph.Fixture.Entity.Person.summary
        case .organization: L10n.Graph.Fixture.Entity.Organization.summary
        case .university: L10n.Graph.Fixture.Entity.University.summary
        case .foundation: L10n.Graph.Fixture.Entity.Foundation.summary
        case .family: L10n.Graph.Fixture.Entity.Family.summary
        case .deal: L10n.Graph.Fixture.Entity.Deal.summary
        case .event: L10n.Graph.Fixture.Entity.Event.summary
        }
    }
}

private extension GraphRelationship.Kind {
    static let allFixtureKinds: [Self] = [
        .family,
        .founded,
        .employment,
        .boardRole,
        .ownership,
        .investment,
        .deal,
        .education,
        .philanthropy,
        .legalDispute
    ]
}

private extension Double {
    static let worldCenter = 5_000.0
}

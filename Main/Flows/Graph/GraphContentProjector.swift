import Foundation

enum GraphProjectionError: Error, Equatable {
    case editionNotFound(String)
    case featuredPersonMissing(String)
}

struct GraphContentProjector {
    func project(
        snapshot: ContentSnapshot,
        editionID: String,
        displayMode: GraphDisplayMode
    ) throws -> GraphData {
        guard let edition = snapshot.edition(id: editionID) else {
            throw GraphProjectionError.editionNotFound(editionID)
        }
        guard snapshot.entity(id: edition.featuredPersonID)?.kind == .person else {
            throw GraphProjectionError.featuredPersonMissing(edition.featuredPersonID)
        }

        let visibleEntityIDs = Set(edition.visibleEntityIDs)
        let visibleRelationshipIDs = Set(edition.visibleRelationshipIDs)
        let entities = snapshot.entities.filter { visibleEntityIDs.contains($0.id) }
        let contentRelationships = snapshot.relationships.filter { visibleRelationshipIDs.contains($0.id) }
        let presentationRelationships = relationships(
            entities: entities,
            relationships: contentRelationships,
            snapshot: snapshot,
            displayMode: displayMode
        )
        let visibleEntities = displayMode == .peopleOnly
            ? entities.filter { $0.kind == .person }
            : entities
        let unpositioned = visibleEntities.map { entity in
            GraphNode(
                id: entity.id,
                kind: GraphEntityKind(entity.kind),
                name: entity.name,
                shortName: entity.shortName,
                summary: entity.summary,
                portrait: entity.media.flatMap(Self.portraitReference),
                position: GraphPoint(x: .zero, y: .zero)
            )
        }
        let positions = StableOrganicGraphLayout().layout(
            nodes: unpositioned,
            relationships: presentationRelationships,
            featuredNodeID: edition.featuredPersonID,
            layoutVersion: snapshot.layoutVersion
        )
        let nodes = unpositioned.map { node in
            GraphNode(
                id: node.id,
                kind: node.kind,
                name: node.name,
                shortName: node.shortName,
                summary: node.summary,
                portrait: node.portrait,
                position: positions[node.id] ?? GraphPoint(x: 5_000, y: 5_000)
            )
        }
        return GraphData(
            featuredNodeID: edition.featuredPersonID,
            nodes: nodes,
            relationships: presentationRelationships,
            sources: snapshot.sources.map {
                GraphSource(id: $0.id, title: $0.title, publisher: $0.publisher, url: $0.url, tier: $0.tier)
            }
        )
    }
}

private extension GraphContentProjector {
    struct ContextMembership {
        let personID: String
        let context: ContentEntity
        let relationship: ContentRelationship
        let claimIDs: Set<String>
        let sourceIDs: Set<String>
    }

    func relationships(
        entities: [ContentEntity],
        relationships: [ContentRelationship],
        snapshot: ContentSnapshot,
        displayMode: GraphDisplayMode
    ) -> [GraphRelationship] {
        guard displayMode == .peopleOnly else {
            return relationships.map { directRelationship($0, snapshot: snapshot) }
        }

        let personIDs = Set(entities.filter { $0.kind == .person }.map(\.id))
        let direct = relationships
            .filter { personIDs.contains($0.sourceEntityID) && personIDs.contains($0.targetEntityID) }
            .map { directRelationship($0, snapshot: snapshot) }
        let contexts = contextRelationships(
            entities: entities,
            relationships: relationships,
            personIDs: personIDs,
            snapshot: snapshot
        )
        return merge(direct + contexts)
    }

    func directRelationship(
        _ relationship: ContentRelationship,
        snapshot: ContentSnapshot
    ) -> GraphRelationship {
        GraphRelationship(
            id: relationship.id,
            sourceID: relationship.sourceEntityID,
            targetID: relationship.targetEntityID,
            kind: GraphRelationship.Kind(relationship.kind),
            status: relationship.status == .confirmed ? .confirmed : .disputed,
            explanation: relationship.claimIDs.compactMap { snapshot.claim(id: $0)?.text }.joined(separator: " "),
            claimIDs: relationship.claimIDs,
            sourceIDs: sourceIDs(for: relationship, snapshot: snapshot).sorted()
        )
    }

    func contextRelationships(
        entities: [ContentEntity],
        relationships: [ContentRelationship],
        personIDs: Set<String>,
        snapshot: ContentSnapshot
    ) -> [GraphRelationship] {
        let entityByID = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        let memberships = relationships.compactMap { relationship -> ContextMembership? in
            let personID: String
            let contextID: String
            if personIDs.contains(relationship.sourceEntityID), !personIDs.contains(relationship.targetEntityID) {
                personID = relationship.sourceEntityID
                contextID = relationship.targetEntityID
            } else if personIDs.contains(relationship.targetEntityID), !personIDs.contains(relationship.sourceEntityID) {
                personID = relationship.targetEntityID
                contextID = relationship.sourceEntityID
            } else {
                return nil
            }
            guard let context = entityByID[contextID] else { return nil }
            return ContextMembership(
                personID: personID,
                context: context,
                relationship: relationship,
                claimIDs: Set(relationship.claimIDs),
                sourceIDs: sourceIDs(for: relationship, snapshot: snapshot)
            )
        }

        var result: [GraphRelationship] = []
        for contextID in Set(memberships.map(\.context.id)).sorted() {
            let members = memberships.filter { $0.context.id == contextID }.sorted { $0.personID < $1.personID }
            for leftIndex in members.indices {
                for rightIndex in members.indices where rightIndex > leftIndex {
                    let left = members[leftIndex]
                    let right = members[rightIndex]
                    let sharedSources = left.sourceIDs.intersection(right.sourceIDs)
                    guard !sharedSources.isEmpty else { continue }
                    let ids = [left.personID, right.personID].sorted()
                    result.append(
                        GraphRelationship(
                            id: "presentation:\(ids[0])--\(ids[1])--\(contextID)",
                            sourceID: ids[0],
                            targetID: ids[1],
                            kind: .sharedContext,
                            status: .confirmed,
                            explanation: "Подтверждённый совместный контекст: \(left.context.name). "
                                + "Это не утверждение о личном знакомстве.",
                            contexts: [
                                GraphRelationship.Context(
                                    id: contextID,
                                    name: left.context.name,
                                    relationshipKinds: [left.relationship.kind.rawValue, right.relationship.kind.rawValue].sorted()
                                )
                            ],
                            claimIDs: left.claimIDs.union(right.claimIDs).sorted(),
                            sourceIDs: sharedSources.sorted()
                        )
                    )
                }
            }
        }
        return result
    }

    func merge(_ relationships: [GraphRelationship]) -> [GraphRelationship] {
        let grouped = Dictionary(grouping: relationships) { relationship in
            [relationship.sourceID, relationship.targetID].sorted().joined(separator: "|")
        }
        return grouped.keys.sorted().compactMap { key in
            guard let group = grouped[key], let first = group.first else { return nil }
            let contexts = group.flatMap(\.contexts)
            let kinds = Set(group.map(\.kind))
            return GraphRelationship(
                id: "presentation:\(key.replacingOccurrences(of: "|", with: "--"))",
                sourceID: [first.sourceID, first.targetID].sorted()[0],
                targetID: [first.sourceID, first.targetID].sorted()[1],
                kind: kinds.count == 1 ? first.kind : .sharedContext,
                status: group.contains(where: { $0.status == .disputed }) ? .disputed : .confirmed,
                explanation: group.map(\.explanation).filter { !$0.isEmpty }.joined(separator: "\n\n"),
                contexts: Array(Dictionary(grouping: contexts, by: \.id).compactMap { $0.value.first }).sorted { $0.id < $1.id },
                claimIDs: Array(Set(group.flatMap(\.claimIDs))).sorted(),
                sourceIDs: Array(Set(group.flatMap(\.sourceIDs))).sorted()
            )
        }
    }

    func sourceIDs(for relationship: ContentRelationship, snapshot: ContentSnapshot) -> Set<String> {
        Set(relationship.claimIDs.flatMap { snapshot.claim(id: $0)?.sourceIDs ?? [] })
    }

    static func portraitReference(_ media: ContentMedia) -> GraphNode.PortraitReference? {
        let resource = media.bundledResource ?? media.sha256 + media.fileExtension
        return GraphNode.PortraitReference(
            bundledResource: resource,
            accessibilityAttribution: media.attribution
        )
    }
}

private extension ContentMedia {
    var fileExtension: String {
        switch mimeType {
        case "image/png": ".png"
        case "image/heic": ".heic"
        default: ".jpg"
        }
    }
}

private extension GraphEntityKind {
    init(_ kind: ContentEntityKind) {
        self = switch kind {
        case .person: .person
        case .organization: .organization
        case .university: .university
        case .foundation: .foundation
        case .family: .family
        case .deal: .deal
        case .event: .event
        }
    }
}

private extension GraphRelationship.Kind {
    init(_ kind: ContentRelationship.Kind) {
        self = switch kind {
        case .family: .family
        case .founded: .founded
        case .cofounded: .cofounded
        case .employment: .employment
        case .executiveRole: .executiveRole
        case .boardRole: .boardRole
        case .ownership: .ownership
        case .investment: .investment
        case .deal: .deal
        case .education: .education
        case .philanthropy: .philanthropy
        case .legalDispute: .legalDispute
        }
    }
}

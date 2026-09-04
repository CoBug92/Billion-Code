import Foundation

enum GraphAtlasProjectionError: Error, Equatable {
    case missingLeadChapter(String)
    case noChapters
}

struct GraphAtlasProjector {
    private let graphProjector: GraphContentProjector

    init(graphProjector: GraphContentProjector = GraphContentProjector()) {
        self.graphProjector = graphProjector
    }

    func project(
        snapshot: ContentSnapshot,
        editionID: String,
        configuration: GraphAtlasConfiguration
    ) throws -> GraphAtlas {
        let graph = try graphProjector.project(
            snapshot: snapshot,
            editionID: editionID,
            displayMode: .peopleOnly
        )
        let directKinds = directPersonRelationshipKinds(snapshot: snapshot, editionID: editionID)
        let chapters = configuration.chapterOrder.compactMap { contextID in
            makeChapter(
                contextID: contextID,
                graph: graph,
                snapshot: snapshot,
                directKinds: directKinds,
                accentIndex: configuration.chapterOrder.firstIndex(of: contextID) ?? .zero
            )
        }

        guard !chapters.isEmpty else {
            throw GraphAtlasProjectionError.noChapters
        }
        guard let leadIndex = chapters.firstIndex(where: { $0.id == configuration.leadChapterID }) else {
            throw GraphAtlasProjectionError.missingLeadChapter(configuration.leadChapterID)
        }
        let orderedChapters = [chapters[leadIndex]]
            + chapters[..<leadIndex]
            + chapters[chapters.index(after: leadIndex)...]

        return GraphAtlas(
            featuredNodeID: graph.featuredNodeID,
            nodes: graph.nodes,
            chapters: Array(orderedChapters),
            relationships: graph.relationships,
            sources: graph.sources,
            layoutVersion: snapshot.layoutVersion
        )
    }
}

private extension GraphAtlasProjector {
    struct PersonPair: Hashable {
        let first: String
        let second: String

        init(_ left: String, _ right: String) {
            let values = [left, right].sorted()
            first = values[0]
            second = values[1]
        }
    }

    func makeChapter(
        contextID: String,
        graph: GraphData,
        snapshot: ContentSnapshot,
        directKinds: [PersonPair: GraphRelationship.Kind],
        accentIndex: Int
    ) -> GraphChapter? {
        let relationships = graph.relationships.filter { relationship in
            relationship.contexts.contains { $0.id == contextID }
        }
        guard !relationships.isEmpty, let context = snapshot.entity(id: contextID) else {
            return nil
        }

        let memberIDs = Set(relationships.flatMap { [$0.sourceID, $0.targetID] })
        let heroNodeID = memberIDs.contains(graph.featuredNodeID)
            ? graph.featuredNodeID
            : memberIDs.sorted()[0]
        let routes = relationships.map { relationship in
            let pair = PersonPair(relationship.sourceID, relationship.targetID)
            let kind = directKinds[pair].map(GraphRoute.Kind.direct) ?? .sharedContext
            return GraphRoute(
                id: "route:\(contextID)--\(pair.first)--\(pair.second)",
                sourceID: pair.first,
                targetID: pair.second,
                kind: kind,
                status: relationship.status,
                relationship: relationship
            )
        }

        return GraphChapter(
            id: contextID,
            title: context.name,
            heroNodeID: heroNodeID,
            memberIDs: memberIDs.sorted(),
            routes: routes.sorted { $0.id < $1.id },
            accentIndex: accentIndex
        )
    }

    func directPersonRelationshipKinds(
        snapshot: ContentSnapshot,
        editionID: String
    ) -> [PersonPair: GraphRelationship.Kind] {
        guard let edition = snapshot.edition(id: editionID) else { return [:] }
        let visibleIDs = Set(edition.visibleRelationshipIDs)
        let personIDs = Set(snapshot.entities.filter { $0.kind == .person }.map(\.id))
        return Dictionary(
            snapshot.relationships.compactMap { relationship -> (PersonPair, GraphRelationship.Kind)? in
                guard
                    visibleIDs.contains(relationship.id),
                    personIDs.contains(relationship.sourceEntityID),
                    personIDs.contains(relationship.targetEntityID)
                else { return nil }
                return (
                    PersonPair(relationship.sourceEntityID, relationship.targetEntityID),
                    GraphRelationship.Kind(relationship.kind)
                )
            },
            uniquingKeysWith: { first, _ in first }
        )
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

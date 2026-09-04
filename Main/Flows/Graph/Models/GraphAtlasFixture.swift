enum GraphAtlasFixture {
    static let editorial: GraphAtlas = {
        let people = Array(GraphFixture.spike.nodes.filter { $0.kind == .person }.prefix(6))
        let featuredID = people[0].id
        let teslaMembers = people.map(\.id)
        let openAIMembers = Array(people.prefix(4)).map(\.id)
        let teslaRoutes = makeRoutes(
            chapterID: "organization:tesla",
            heroID: featuredID,
            memberIDs: teslaMembers
        )
        let openAIRoutes = makeRoutes(
            chapterID: "organization:openai",
            heroID: featuredID,
            memberIDs: openAIMembers
        )
        let relationships = (teslaRoutes + openAIRoutes).map(\.relationship)
        return GraphAtlas(
            featuredNodeID: featuredID,
            nodes: people,
            chapters: [
                GraphChapter(
                    id: "organization:tesla",
                    title: "Tesla",
                    heroNodeID: featuredID,
                    memberIDs: teslaMembers,
                    routes: teslaRoutes,
                    accentIndex: 0
                ),
                GraphChapter(
                    id: "organization:openai",
                    title: "OpenAI",
                    heroNodeID: featuredID,
                    memberIDs: openAIMembers,
                    routes: openAIRoutes,
                    accentIndex: 2
                )
            ],
            relationships: relationships,
            sources: [],
            layoutVersion: 1
        )
    }()
}

private extension GraphAtlasFixture {
    static func makeRoutes(
        chapterID: String,
        heroID: String,
        memberIDs: [String]
    ) -> [GraphRoute] {
        memberIDs.filter { $0 != heroID }.map { targetID in
            let relationship = GraphRelationship(
                id: "relationship:\(chapterID)--\(targetID)",
                sourceID: heroID,
                targetID: targetID,
                kind: .sharedContext,
                status: .confirmed,
                explanation: L10n.Graph.Fixture.Relationship.confirmed,
                contexts: [
                    GraphRelationship.Context(
                        id: chapterID,
                        name: chapterID,
                        relationshipKinds: []
                    )
                ]
            )
            return GraphRoute(
                id: "route:\(chapterID)--\(targetID)",
                sourceID: heroID,
                targetID: targetID,
                kind: .sharedContext,
                status: .confirmed,
                relationship: relationship
            )
        }
    }
}

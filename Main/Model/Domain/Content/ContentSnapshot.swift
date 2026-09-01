import Foundation

struct ContentSnapshot: Equatable, Sendable {
    let contentVersion: String
    let manifestRevision: Int
    let entities: [ContentEntity]
    let claims: [ContentClaim]
    let sources: [ContentSource]
    let relationships: [ContentRelationship]
    let editions: [ContentEdition]
    let fallbackEditionID: String
    let layoutVersion: Int
    let layoutEntityIDs: Set<String>

    var entityIDs: Set<String> {
        Set(entities.map(\.id))
    }

    func entity(id: String) -> ContentEntity? {
        entities.first { $0.id == id }
    }

    func claim(id: String) -> ContentClaim? {
        claims.first { $0.id == id }
    }

    func source(id: String) -> ContentSource? {
        sources.first { $0.id == id }
    }

    func edition(id: String) -> ContentEdition? {
        editions.first { $0.id == id }
    }
}

extension ContentSnapshot {
    init(
        contentVersion: String,
        manifestRevision: Int,
        entityIDs: Set<String>,
        layoutEntityIDs: Set<String>
    ) {
        self.init(
            contentVersion: contentVersion,
            manifestRevision: manifestRevision,
            entities: entityIDs.sorted().map {
                ContentEntity(
                    id: $0,
                    kind: .person,
                    name: $0,
                    shortName: $0,
                    summary: "",
                    media: nil
                )
            },
            claims: [],
            sources: [],
            relationships: [],
            editions: [],
            fallbackEditionID: "",
            layoutVersion: 1,
            layoutEntityIDs: layoutEntityIDs
        )
    }
}

import Foundation

/// Валидирует используемую приложением graph-подвыборку schema v1 и строит immutable snapshot.
/// Полная проверка JSON Schema остаётся обязательным publisher/build-time gate.
struct SpikeContentSnapshotValidator: ContentSnapshotValidating {
    func validate(_ data: Data, manifestRevision: Int) async throws -> ContentSnapshot {
        let payload = try JSONDecoder().decode(Payload.self, from: data)

        guard payload.schemaVersion == Int.supportedSchemaVersion else {
            throw ContentValidationError.unsupportedSchema(payload.schemaVersion)
        }

        try ensureUnique(payload.entities.map(\.id))
        try ensureUnique(payload.claims.map(\.id))
        try ensureUnique(payload.sources.map(\.id))
        try ensureUnique(payload.relationships.map(\.id))
        try ensureUnique(payload.editions.map(\.id))

        let entityIDs = Set(payload.entities.map(\.id))
        let claimIDs = Set(payload.claims.map(\.id))
        let sourceIDs = Set(payload.sources.map(\.id))
        let relationshipIDs = Set(payload.relationships.map(\.id))
        let validClaimSubjectIDs = entityIDs.union(relationshipIDs)
        let layoutEntityIDs = try uniqueLayoutEntityIDs(payload.graphLayout.positions)

        guard payload.editions.contains(where: { $0.id == payload.fallbackEditionID }) else {
            throw ContentValidationError.missingFallbackEdition(payload.fallbackEditionID)
        }

        for claim in payload.claims {
            guard validClaimSubjectIDs.contains(claim.subjectID) else {
                throw ContentValidationError.invalidClaimSubject(claim.id)
            }
            guard !claim.sourceIDs.isEmpty else {
                throw ContentValidationError.missingClaimSource(claim.id)
            }
            for sourceID in claim.sourceIDs where !sourceIDs.contains(sourceID) {
                throw ContentValidationError.danglingReference(sourceID)
            }
        }

        for relationship in payload.relationships {
            guard entityIDs.contains(relationship.sourceEntityID) else {
                throw ContentValidationError.danglingReference(relationship.sourceEntityID)
            }
            guard entityIDs.contains(relationship.targetEntityID) else {
                throw ContentValidationError.danglingReference(relationship.targetEntityID)
            }
            guard !relationship.claimIDs.isEmpty else {
                throw ContentValidationError.missingRelationshipClaim(relationship.id)
            }
            for claimID in relationship.claimIDs where !claimIDs.contains(claimID) {
                throw ContentValidationError.danglingReference(claimID)
            }
            if relationship.status == .disputed {
                let positions = Set(
                    relationship.claimIDs.compactMap { claimID in
                        payload.claims.first { $0.id == claimID }?.relationshipPosition
                    }
                )
                guard positions == [.supports, .challenges] else {
                    throw ContentValidationError.disputedRelationshipWithoutOpposingClaims(relationship.id)
                }
            }
        }

        for edition in payload.editions {
            guard entityIDs.contains(edition.featuredPersonID) else {
                throw ContentValidationError.danglingVisibleEntity(edition.featuredPersonID)
            }
            for entityID in edition.visibleEntityIDs {
                guard entityIDs.contains(entityID) else {
                    throw ContentValidationError.danglingVisibleEntity(entityID)
                }
                guard layoutEntityIDs.contains(entityID) else {
                    throw ContentValidationError.missingLayoutPosition(entityID)
                }
            }
            for relationshipID in edition.visibleRelationshipIDs where !relationshipIDs.contains(relationshipID) {
                throw ContentValidationError.danglingReference(relationshipID)
            }
        }

        return ContentSnapshot(
            contentVersion: payload.contentVersion,
            manifestRevision: manifestRevision,
            entities: payload.entities,
            claims: payload.claims,
            sources: payload.sources,
            relationships: payload.relationships,
            editions: payload.editions,
            fallbackEditionID: payload.fallbackEditionID,
            layoutVersion: payload.graphLayout.layoutVersion,
            layoutEntityIDs: layoutEntityIDs
        )
    }

    private func ensureUnique(_ ids: [String]) throws {
        var seen = Set<String>()
        for id in ids where !seen.insert(id).inserted {
            throw ContentValidationError.duplicateID(id)
        }
    }

    private func uniqueLayoutEntityIDs(_ positions: [Position]) throws -> Set<String> {
        var result = Set<String>()
        for position in positions where !result.insert(position.entityID).inserted {
            throw ContentValidationError.duplicateLayoutPosition(position.entityID)
        }
        return result
    }
}

private extension SpikeContentSnapshotValidator {
    struct Payload: Decodable {
        let schemaVersion: Int
        let contentVersion: String
        let fallbackEditionID: String
        let entities: [ContentEntity]
        let claims: [ContentClaim]
        let sources: [ContentSource]
        let relationships: [ContentRelationship]
        let editions: [ContentEdition]
        let graphLayout: GraphLayout

        enum CodingKeys: String, CodingKey {
            case schemaVersion
            case contentVersion
            case fallbackEditionID = "fallbackEditionId"
            case entities
            case claims
            case sources
            case relationships
            case editions
            case graphLayout
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
            contentVersion = try container.decode(String.self, forKey: .contentVersion)
            fallbackEditionID = try container.decode(String.self, forKey: .fallbackEditionID)
            entities = try container.decode([ContentEntity].self, forKey: .entities)
            claims = try container.decodeIfPresent([ContentClaim].self, forKey: .claims) ?? []
            sources = try container.decodeIfPresent([ContentSource].self, forKey: .sources) ?? []
            relationships = try container.decodeIfPresent([ContentRelationship].self, forKey: .relationships) ?? []
            graphLayout = try container.decode(GraphLayout.self, forKey: .graphLayout)

            if let complete = try? container.decode([ContentEdition].self, forKey: .editions) {
                editions = complete
            } else {
                let legacy = try container.decode([LegacyEdition].self, forKey: .editions)
                let featuredID = entities.first(where: { $0.kind == .person })?.id
                    ?? legacy.first?.visibleEntityIDs.first
                    ?? ""
                editions = legacy.map {
                    ContentEdition(
                        id: $0.id,
                        featuredPersonID: featuredID,
                        visibleEntityIDs: $0.visibleEntityIDs,
                        visibleRelationshipIDs: []
                    )
                }
            }
        }
    }

    struct LegacyEdition: Decodable {
        let id: String
        let visibleEntityIDs: [String]

        enum CodingKeys: String, CodingKey {
            case id
            case visibleEntityIDs = "visibleEntityIds"
        }
    }

    struct GraphLayout: Decodable {
        let layoutVersion: Int
        let positions: [Position]

        enum CodingKeys: String, CodingKey {
            case layoutVersion
            case positions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            layoutVersion = try container.decodeIfPresent(Int.self, forKey: .layoutVersion) ?? 1
            positions = try container.decode([Position].self, forKey: .positions)
        }
    }

    struct Position: Decodable {
        let entityID: String

        enum CodingKeys: String, CodingKey {
            case entityID = "entityId"
        }
    }
}

private extension Int {
    static let supportedSchemaVersion = 1
}

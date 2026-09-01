import Foundation
import Testing
@testable import BillionCode

@Suite("GraphContentProjector")
struct GraphContentProjectorTests {
    @Test("canonical seed projects thirteen people and hides organizations")
    func projectsPeopleOnlySeed() async throws {
        let snapshot = try await canonicalSnapshot()

        let graph = try GraphContentProjector().project(
            snapshot: snapshot,
            editionID: snapshot.fallbackEditionID,
            displayMode: .peopleOnly
        )

        #expect(graph.nodes.count == 13)
        #expect(graph.nodes.allSatisfy { $0.kind == .person })
        #expect(graph.featuredNodeID == "person:elon-musk")
        #expect(Set(graph.relationships.map(\.id)).count == graph.relationships.count)
        #expect(graph.relationships.allSatisfy { $0.sourceID != $0.targetID })
    }

    @Test("multiple shared contexts merge into a single edge")
    func mergesSharedContexts() async throws {
        let snapshot = try await canonicalSnapshot()
        let graph = try GraphContentProjector().project(
            snapshot: snapshot,
            editionID: snapshot.fallbackEditionID,
            displayMode: .peopleOnly
        )

        let edge = graph.relationships.first {
            Set([$0.sourceID, $0.targetID]) == Set(["person:elon-musk", "person:reid-hoffman"])
        }

        #expect(edge?.contexts.map(\.name).sorted() == ["OpenAI", "PayPal"])
    }

    @Test("shared organization without shared evidence source does not create an edge")
    func requiresSharedEvidenceSource() throws {
        let snapshot = evidenceMismatchSnapshot()
        let graph = try GraphContentProjector().project(
            snapshot: snapshot,
            editionID: "edition:test",
            displayMode: .peopleOnly
        )

        #expect(graph.relationships.isEmpty)
    }

    private func canonicalSnapshot() async throws -> ContentSnapshot {
        let data = try await BundledSeedContentProvider().loadSeed()
        return try await SpikeContentSnapshotValidator().validate(data, manifestRevision: .zero)
    }

    private func evidenceMismatchSnapshot() -> ContentSnapshot {
        let people = ["person:a", "person:b"].map {
            ContentEntity(id: $0, kind: .person, name: $0, shortName: $0, summary: "", media: nil)
        }
        let organization = ContentEntity(
            id: "organization:c",
            kind: .organization,
            name: "C",
            shortName: "C",
            summary: "",
            media: nil
        )
        let claims = [
            ContentClaim(id: "claim:a", subjectID: "relationship:a", text: "A", sourceIDs: ["source:a"]),
            ContentClaim(id: "claim:b", subjectID: "relationship:b", text: "B", sourceIDs: ["source:b"])
        ]
        let relationships = [
            ContentRelationship(
                id: "relationship:a",
                sourceEntityID: "person:a",
                targetEntityID: "organization:c",
                kind: .employment,
                status: .confirmed,
                claimIDs: ["claim:a"]
            ),
            ContentRelationship(
                id: "relationship:b",
                sourceEntityID: "person:b",
                targetEntityID: "organization:c",
                kind: .employment,
                status: .confirmed,
                claimIDs: ["claim:b"]
            )
        ]
        return ContentSnapshot(
            contentVersion: "test",
            manifestRevision: .zero,
            entities: people + [organization],
            claims: claims,
            sources: [
                ContentSource(id: "source:a", title: "A", publisher: "A", url: URL(string: "https://a.example")!, tier: "primary"),
                ContentSource(id: "source:b", title: "B", publisher: "B", url: URL(string: "https://b.example")!, tier: "primary")
            ],
            relationships: relationships,
            editions: [
                ContentEdition(
                    id: "edition:test",
                    featuredPersonID: "person:a",
                    visibleEntityIDs: ["person:a", "person:b", "organization:c"],
                    visibleRelationshipIDs: relationships.map(\.id)
                )
            ],
            fallbackEditionID: "edition:test",
            layoutVersion: 1,
            layoutEntityIDs: ["person:a", "person:b", "organization:c"]
        )
    }
}

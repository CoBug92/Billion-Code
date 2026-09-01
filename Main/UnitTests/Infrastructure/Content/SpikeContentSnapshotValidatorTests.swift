import Foundation
import Testing
@testable import BillionCode

@Suite("SpikeContentSnapshotValidator")
struct SpikeContentSnapshotValidatorTests {
    @Test("принимает связный graph envelope")
    func acceptsValidEnvelope() async throws {
        let snapshot = try await SpikeContentSnapshotValidator().validate(
            validPayload,
            manifestRevision: 8
        )

        #expect(snapshot.contentVersion == "2026.09.01+sample")
        #expect(snapshot.manifestRevision == 8)
        #expect(snapshot.entityIDs == ["person:sample", "organization:sample"])
    }

    @Test("отклоняет видимый узел без позиции")
    func rejectsMissingPosition() async {
        var didRejectExpectedError = false

        do {
            _ = try await SpikeContentSnapshotValidator().validate(
                payloadWithMissingPosition,
                manifestRevision: 8
            )
        } catch ContentValidationError.missingLayoutPosition("organization:sample") {
            didRejectExpectedError = true
        } catch {}

        #expect(didRejectExpectedError)
    }

    @Test("отклоняет disputed связь без противоположных claims")
    func rejectsOneSidedDispute() async {
        let data = Data(
            """
            {
              "schemaVersion": 1,
              "contentVersion": "test",
              "fallbackEditionId": "edition:test",
              "entities": [
                { "id": "person:a", "kind": "person" },
                { "id": "person:b", "kind": "person" }
              ],
              "claims": [{
                "id": "claim:a", "subjectId": "relationship:a", "text": "A",
                "relationshipPosition": "supports", "sourceIds": ["source:a"]
              }],
              "sources": [{
                "id": "source:a", "title": "A", "publisher": "A",
                "url": "https://a.example", "tier": "primary"
              }],
              "relationships": [{
                "id": "relationship:a", "sourceEntityId": "person:a", "targetEntityId": "person:b",
                "kind": "family", "status": "disputed", "claimIds": ["claim:a"]
              }],
              "editions": [{
                "id": "edition:test", "featuredPersonId": "person:a",
                "visibleEntityIds": ["person:a", "person:b"],
                "visibleRelationshipIds": ["relationship:a"]
              }],
              "graphLayout": {
                "positions": [{ "entityId": "person:a" }, { "entityId": "person:b" }]
              }
            }
            """.utf8
        )
        var rejected = false

        do {
            _ = try await SpikeContentSnapshotValidator().validate(data, manifestRevision: 1)
        } catch ContentValidationError.disputedRelationshipWithoutOpposingClaims("relationship:a") {
            rejected = true
        } catch {}

        #expect(rejected)
    }

    // MARK: - Properties

    private var validPayload: Data {
        payload(positions: """
        [
          { "entityId": "person:sample" },
          { "entityId": "organization:sample" }
        ]
        """)
    }

    private var payloadWithMissingPosition: Data {
        payload(positions: """
        [
          { "entityId": "person:sample" }
        ]
        """)
    }

    // MARK: - Private methods

    private func payload(positions: String) -> Data {
        Data(
            """
            {
              "schemaVersion": 1,
              "contentVersion": "2026.09.01+sample",
              "fallbackEditionId": "edition:2026-09-01-sample",
              "entities": [
                { "id": "person:sample", "kind": "person" },
                { "id": "organization:sample", "kind": "organization" }
              ],
              "editions": [
                {
                  "id": "edition:2026-09-01-sample",
                  "visibleEntityIds": ["person:sample", "organization:sample"]
                }
              ],
              "graphLayout": {
                "positions": \(positions)
              }
            }
            """.utf8
        )
    }
}

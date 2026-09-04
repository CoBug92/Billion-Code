import Testing
@testable import BillionCode

@Suite("GraphAtlasProjector")
struct GraphAtlasProjectorTests {
    @Test("Canonical seed becomes the five configured editorial chapters")
    func canonicalChapters() async throws {
        let snapshot = try await canonicalSnapshot()

        let atlas = try GraphAtlasProjector().project(
            snapshot: snapshot,
            editionID: snapshot.fallbackEditionID,
            configuration: .muskDesignSpike
        )

        #expect(atlas.chapters.map(\.id) == [
            "organization:tesla",
            "organization:spacex",
            "organization:openai",
            "organization:paypal",
            "organization:zip2"
        ])
        #expect(atlas.chapters.map(\.memberIDs.count) == [6, 2, 5, 4, 2])
        #expect(atlas.leadChapter.id == "organization:tesla")
        #expect(atlas.chapters.flatMap(\.memberIDs).allSatisfy { atlas.node(id: $0)?.kind == .person })
    }

    @Test("A direct family relation strengthens its route inside a shared chapter")
    func directRouteSemantics() async throws {
        let snapshot = try await canonicalSnapshot()
        let atlas = try GraphAtlasProjector().project(
            snapshot: snapshot,
            editionID: snapshot.fallbackEditionID,
            configuration: .muskDesignSpike
        )

        let route = atlas.leadChapter.routes.first {
            Set([$0.sourceID, $0.targetID]) == Set(["person:elon-musk", "person:kimbal-musk"])
        }

        #expect(route?.kind == .direct(.family))
        #expect(route?.status == .confirmed)
    }

    private func canonicalSnapshot() async throws -> ContentSnapshot {
        let data = try await BundledSeedContentProvider().loadSeed()
        return try await SpikeContentSnapshotValidator().validate(data, manifestRevision: .zero)
    }
}

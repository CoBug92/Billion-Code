import Foundation
import Testing
@testable import BillionCode

@Suite("FileContentCache")
struct FileContentCacheTests {
    @Test("promotion сохраняет previous и current как полные payload")
    func promotionRotatesPointers() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = FileContentCache(rootDirectory: directory)
        let first = cached("first", revision: 1)
        let second = cached("second", revision: 2)

        try await cache.promote(first)
        try await cache.promote(second)

        #expect(try await cache.readCurrent() == second)
        #expect(try await cache.readPrevious() == first)
    }

    @Test("повреждённый current pointer не мешает ContentStore открыть previous")
    func corruptedCurrentFallsBackToPrevious() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = FileContentCache(rootDirectory: directory)
        let first = cached("first", revision: 1)
        let second = cached("second", revision: 2)
        try await cache.promote(first)
        try await cache.promote(second)
        try Data("corrupted".utf8).write(
            to: directory.appendingPathComponent("current.json"),
            options: .atomic
        )
        let store = ContentStore(
            cache: cache,
            seedProvider: StaticFileCacheSeedProvider(),
            validator: FileCacheMarkerValidator()
        )

        let state = await store.bootstrap()

        #expect(state == .cached(snapshot("first", revision: 1)))
    }

    // MARK: - Private methods

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}

private struct StaticFileCacheSeedProvider: SeedContentProviding {
    func loadSeed() async throws -> Data {
        Data("seed".utf8)
    }
}

private struct FileCacheMarkerValidator: ContentSnapshotValidating {
    func validate(_ data: Data, manifestRevision: Int) async throws -> ContentSnapshot {
        guard let value = String(data: data, encoding: .utf8) else {
            throw FileContentCacheTestError.invalidData
        }
        return snapshot(value, revision: manifestRevision)
    }
}

private enum FileContentCacheTestError: Error {
    case invalidData
}

private func cached(_ value: String, revision: Int) -> CachedContent {
    CachedContent(
        data: Data(value.utf8),
        manifestRevision: revision
    )
}

private func snapshot(_ value: String, revision: Int) -> ContentSnapshot {
    ContentSnapshot(
        contentVersion: value,
        manifestRevision: revision,
        entityIDs: ["person:sample"],
        layoutEntityIDs: ["person:sample"]
    )
}

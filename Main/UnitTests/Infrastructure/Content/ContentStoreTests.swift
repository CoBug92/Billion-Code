import Foundation
import Testing
@testable import BillionCode

@Suite("ContentStore")
struct ContentStoreTests {
    @Test("bootstrap выбирает current раньше previous и seed")
    func bootstrapUsesCurrent() async {
        let cache = InMemoryContentCache(
            current: cached("current", revision: 3),
            previous: cached("previous", revision: 2)
        )
        let store = makeStore(cache: cache, seed: data("seed"))

        let state = await store.bootstrap()

        #expect(state == .cached(snapshot("current", revision: 3)))
    }

    @Test("повреждённый current откатывается на previous")
    func corruptedCurrentUsesPrevious() async {
        let cache = InMemoryContentCache(
            current: cached("invalid", revision: 3),
            previous: cached("previous", revision: 2)
        )
        let store = makeStore(cache: cache, seed: data("seed"))

        let state = await store.bootstrap()

        #expect(state == .cached(snapshot("previous", revision: 2)))
    }

    @Test("при пустом кэше используется bundled seed")
    func emptyCacheUsesSeed() async {
        let store = makeStore(
            cache: InMemoryContentCache(),
            seed: data("seed")
        )

        let state = await store.bootstrap()

        #expect(state == .seed(snapshot("seed", revision: .zero)))
    }

    @Test("ошибка всех fallback приводит к fatalSeedFailure")
    func invalidFallbacksAreFatal() async {
        let cache = InMemoryContentCache(
            current: cached("invalid", revision: 3),
            previous: cached("invalid", revision: 2)
        )
        let store = makeStore(cache: cache, seed: data("invalid"))

        let state = await store.bootstrap()

        #expect(state == .fatalSeedFailure)
    }

    @Test("невалидный payload не попадает в cache")
    func validationFailurePreservesCurrent() async {
        let initial = cached("current", revision: 3)
        let cache = InMemoryContentCache(current: initial)
        let store = makeStore(cache: cache, seed: data("seed"))
        _ = await store.bootstrap()

        var didThrow = false
        do {
            try await store.install(cached("invalid", revision: 4))
        } catch {
            didThrow = true
        }

        let entries = await cache.entries()
        #expect(didThrow)
        #expect(entries.current == initial)
        #expect(entries.previous == nil)
        #expect(await store.state == .cached(snapshot("current", revision: 3)))
    }

    @Test("ошибка atomic promotion сохраняет last-known-good")
    func promotionFailurePreservesCurrent() async {
        let initial = cached("current", revision: 3)
        let cache = InMemoryContentCache(
            current: initial,
            shouldFailPromotion: true
        )
        let store = makeStore(cache: cache, seed: data("seed"))
        _ = await store.bootstrap()

        var didThrow = false
        do {
            try await store.install(cached("fresh", revision: 4))
        } catch {
            didThrow = true
        }

        let entries = await cache.entries()
        #expect(didThrow)
        #expect(entries.current == initial)
        #expect(entries.previous == nil)
        #expect(await store.state == .cached(snapshot("current", revision: 3)))
    }

    @Test("успешная установка сдвигает current в previous")
    func successfulInstallPromotesAtomically() async throws {
        let initial = cached("current", revision: 3)
        let fresh = cached("fresh", revision: 4)
        let cache = InMemoryContentCache(current: initial)
        let store = makeStore(cache: cache, seed: data("seed"))
        _ = await store.bootstrap()

        let installed = try await store.install(fresh)

        let entries = await cache.entries()
        #expect(installed == snapshot("fresh", revision: 4))
        #expect(entries.current == fresh)
        #expect(entries.previous == initial)
        #expect(await store.state == .fresh(snapshot("fresh", revision: 4)))
    }

    // MARK: - Private methods

    private func makeStore(
        cache: InMemoryContentCache,
        seed: Data
    ) -> ContentStore {
        ContentStore(
            cache: cache,
            seedProvider: StaticSeedContentProvider(data: seed),
            validator: MarkerContentSnapshotValidator()
        )
    }
}

private actor InMemoryContentCache: ContentCache {
    private var current: CachedContent?
    private var previous: CachedContent?
    private let shouldFailPromotion: Bool

    init(
        current: CachedContent? = nil,
        previous: CachedContent? = nil,
        shouldFailPromotion: Bool = false
    ) {
        self.current = current
        self.previous = previous
        self.shouldFailPromotion = shouldFailPromotion
    }

    func readCurrent() async throws -> CachedContent? {
        current
    }

    func readPrevious() async throws -> CachedContent? {
        previous
    }

    func promote(_ content: CachedContent) async throws {
        guard !shouldFailPromotion else {
            throw ContentStoreTestError.promotionFailed
        }
        previous = current
        current = content
    }

    func entries() -> (current: CachedContent?, previous: CachedContent?) {
        (current, previous)
    }
}

private struct StaticSeedContentProvider: SeedContentProviding {
    let data: Data

    func loadSeed() async throws -> Data {
        data
    }
}

private struct MarkerContentSnapshotValidator: ContentSnapshotValidating {
    func validate(_ data: Data, manifestRevision: Int) async throws -> ContentSnapshot {
        guard let value = String(data: data, encoding: .utf8), value != "invalid" else {
            throw ContentStoreTestError.validationFailed
        }
        return snapshot(value, revision: manifestRevision)
    }
}

private enum ContentStoreTestError: Error {
    case promotionFailed
    case validationFailed
}

private func data(_ value: String) -> Data {
    Data(value.utf8)
}

private func cached(_ value: String, revision: Int) -> CachedContent {
    CachedContent(data: data(value), manifestRevision: revision)
}

private func snapshot(_ value: String, revision: Int) -> ContentSnapshot {
    ContentSnapshot(
        contentVersion: value,
        manifestRevision: revision,
        entityIDs: ["person:sample"],
        layoutEntityIDs: ["person:sample"]
    )
}

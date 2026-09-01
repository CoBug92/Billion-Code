import Foundation

actor ContentStore {
    // MARK: - Properties

    private let cache: any ContentCache
    private let seedProvider: any SeedContentProviding
    private let validator: any ContentSnapshotValidating

    private(set) var state: ContentStoreState?

    // MARK: - Init

    init(
        cache: any ContentCache,
        seedProvider: any SeedContentProviding,
        validator: any ContentSnapshotValidating
    ) {
        self.cache = cache
        self.seedProvider = seedProvider
        self.validator = validator
    }

    // MARK: - Public methods

    @discardableResult
    func bootstrap() async -> ContentStoreState {
        if let snapshot = await validatedCurrent() {
            let newState = ContentStoreState.cached(snapshot)
            state = newState
            return newState
        }

        if let snapshot = await validatedPrevious() {
            let newState = ContentStoreState.cached(snapshot)
            state = newState
            return newState
        }

        if let snapshot = await validatedSeed() {
            let newState = ContentStoreState.seed(snapshot)
            state = newState
            return newState
        }

        state = .fatalSeedFailure
        return .fatalSeedFailure
    }

    @discardableResult
    func install(_ content: CachedContent) async throws -> ContentSnapshot {
        let previousState = state
        state = .refreshing(previousState?.snapshot)

        do {
            let snapshot = try await validator.validate(
                content.data,
                manifestRevision: content.manifestRevision
            )
            try await cache.promote(content)
            state = .fresh(snapshot)
            return snapshot
        } catch {
            state = previousState
            throw error
        }
    }

    // MARK: - Private methods

    private func validatedCurrent() async -> ContentSnapshot? {
        do {
            guard let content = try await cache.readCurrent() else {
                return nil
            }
            return try await validator.validate(
                content.data,
                manifestRevision: content.manifestRevision
            )
        } catch {
            return nil
        }
    }

    private func validatedPrevious() async -> ContentSnapshot? {
        do {
            guard let content = try await cache.readPrevious() else {
                return nil
            }
            return try await validator.validate(
                content.data,
                manifestRevision: content.manifestRevision
            )
        } catch {
            return nil
        }
    }

    private func validatedSeed() async -> ContentSnapshot? {
        do {
            let data = try await seedProvider.loadSeed()
            return try await validator.validate(data, manifestRevision: .zero)
        } catch {
            return nil
        }
    }
}

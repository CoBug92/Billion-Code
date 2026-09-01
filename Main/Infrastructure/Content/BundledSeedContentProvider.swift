import Foundation

struct BundledSeedContentProvider: SeedContentProviding {
    private let resourceURL: URL?

    init(bundle: Bundle = .main) {
        resourceURL = bundle.url(forResource: "musk-cluster-v1", withExtension: "json")
    }

    func loadSeed() async throws -> Data {
        guard let resourceURL else {
            throw BundledSeedError.resourceMissing
        }
        return try Data(contentsOf: resourceURL, options: .mappedIfSafe)
    }
}

private enum BundledSeedError: Error {
    case resourceMissing
}

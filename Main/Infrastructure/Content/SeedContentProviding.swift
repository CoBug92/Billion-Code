import Foundation

/// Источник bundled seed, который доступен без сети и файлового кэша.
protocol SeedContentProviding: Sendable {
    /// Загружает точные байты bundled seed.
    /// - Returns: JSON payload из application bundle.
    func loadSeed() async throws -> Data
}

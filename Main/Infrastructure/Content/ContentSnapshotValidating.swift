import Foundation

/// Преобразует transport bytes в полностью проверенный неизменяемый snapshot.
protocol ContentSnapshotValidating: Sendable {
    /// Проверяет decode и domain invariants вне `MainActor`.
    /// - Parameters:
    ///   - data: Точные байты payload после size/checksum-проверки.
    ///   - manifestRevision: Ревизия manifest, которая ссылается на payload.
    /// - Returns: Snapshot, безопасный для публикации в UI.
    func validate(_ data: Data, manifestRevision: Int) async throws -> ContentSnapshot
}

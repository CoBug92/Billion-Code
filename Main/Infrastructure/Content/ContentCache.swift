/// Хранилище last-known-good content payload и его предыдущей версии.
protocol ContentCache: Sendable {
    /// Возвращает активный payload или `nil`, если кэш ещё не создан.
    func readCurrent() async throws -> CachedContent?

    /// Возвращает предыдущий payload для fallback или `nil`, если его нет.
    func readPrevious() async throws -> CachedContent?

    /// Атомарно делает проверенный payload текущим, сохраняя прежний как previous.
    /// - Parameter content: Payload, уже принятый domain validator.
    func promote(_ content: CachedContent) async throws
}

import Foundation

struct CachedContent: Equatable, Sendable {
    let data: Data
    let manifestRevision: Int
}

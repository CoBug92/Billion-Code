enum ContentStoreState: Equatable, Sendable {
    case seed(ContentSnapshot)
    case cached(ContentSnapshot)
    case refreshing(ContentSnapshot?)
    case fresh(ContentSnapshot)
    case stale(ContentSnapshot)
    case requiresAppUpdate(ContentSnapshot?)
    case fatalSeedFailure

    var snapshot: ContentSnapshot? {
        switch self {
        case .seed(let snapshot),
             .cached(let snapshot),
             .fresh(let snapshot),
             .stale(let snapshot):
            snapshot
        case .refreshing(let snapshot),
             .requiresAppUpdate(let snapshot):
            snapshot
        case .fatalSeedFailure:
            nil
        }
    }
}

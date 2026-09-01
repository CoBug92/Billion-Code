extension GraphEntityKind {
    var localizedTitle: String {
        switch self {
        case .person: L10n.Graph.Entity.person
        case .organization: L10n.Graph.Entity.organization
        case .university: L10n.Graph.Entity.university
        case .foundation: L10n.Graph.Entity.foundation
        case .family: L10n.Graph.Entity.family
        case .deal: L10n.Graph.Entity.deal
        case .event: L10n.Graph.Entity.event
        }
    }

    var symbolName: String {
        switch self {
        case .person: AppSymbols.person
        case .organization: AppSymbols.organization
        case .university: AppSymbols.university
        case .foundation: AppSymbols.foundation
        case .family: AppSymbols.family
        case .deal: AppSymbols.deal
        case .event: AppSymbols.event
        }
    }
}

extension GraphRelationship.Kind {
    var localizedTitle: String {
        switch self {
        case .family: L10n.Graph.Relationship.Kind.family
        case .founded: L10n.Graph.Relationship.Kind.founded
        case .cofounded: L10n.Graph.Relationship.Kind.cofounded
        case .employment: L10n.Graph.Relationship.Kind.employment
        case .executiveRole: L10n.Graph.Relationship.Kind.executiveRole
        case .boardRole: L10n.Graph.Relationship.Kind.boardRole
        case .ownership: L10n.Graph.Relationship.Kind.ownership
        case .investment: L10n.Graph.Relationship.Kind.investment
        case .deal: L10n.Graph.Relationship.Kind.deal
        case .education: L10n.Graph.Relationship.Kind.education
        case .philanthropy: L10n.Graph.Relationship.Kind.philanthropy
        case .legalDispute: L10n.Graph.Relationship.Kind.legalDispute
        case .sharedContext: L10n.Graph.Relationship.Kind.sharedContext
        }
    }
}

extension GraphRelationship.Status {
    var localizedTitle: String {
        switch self {
        case .confirmed: L10n.Graph.Relationship.confirmed
        case .disputed: L10n.Graph.Relationship.disputed
        }
    }

    var symbolName: String {
        switch self {
        case .confirmed: AppSymbols.confirmed
        case .disputed: AppSymbols.disputed
        }
    }
}

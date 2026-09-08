import Foundation

struct EntityDossier: Equatable, Sendable {
    let entityID: GraphNode.ID
    let kind: GraphEntityKind
    let description: String
    let operatingPeriod: String?
    let lastReviewedOn: String
    let facts: [DossierFact]
    let links: [DossierEntityLink]
    let timeline: [DossierTimelineEvent]
    let wealth: DossierWealth?
    let personDetails: DossierPersonDetails?
    let education: [DossierEntityLink]

    var currentLinks: [DossierEntityLink] {
        links.filter(\.isCurrent)
    }

    var sortedLinks: [DossierEntityLink] {
        links.sorted {
            if $0.isCurrent != $1.isCurrent { return $0.isCurrent }
            return $0.startYear > $1.startYear
        }
    }
}

struct DossierPersonDetails: Equatable, Sendable {
    let birthDate: DossierBirthDate
    let deathDate: DossierBirthDate?
}

struct DossierBirthDate: Equatable, Sendable {
    let year: Int
    let month: Int?
    let day: Int?

    init(year: Int, month: Int? = nil, day: Int? = nil) {
        self.year = year
        self.month = month
        self.day = day
    }
}

struct DossierFact: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    let source: DossierSource?
}

struct DossierEntityLink: Identifiable, Equatable, Sendable {
    let id: String
    let entityID: GraphNode.ID?
    let name: String
    let role: String
    let period: String
    let startYear: Int
    let isCurrent: Bool
    let source: DossierSource?
}

struct DossierTimelineEvent: Identifiable, Equatable, Sendable {
    let id: String
    let year: Int
    let title: String
    let description: String
    let linkedEntityID: GraphNode.ID?
    let source: DossierSource?
}

struct DossierWealth: Equatable, Sendable {
    let amountUSD: UInt64
    let asOf: String
    let methodology: String
    let source: DossierSource
    let components: [DossierWealthComponent]
    let history: [DossierWealthPoint]
}

struct DossierWealthComponent: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let detail: String
}

struct DossierWealthPoint: Identifiable, Equatable, Sendable {
    let id: String
    let year: Int
    let amountUSD: UInt64
}

struct DossierSource: Identifiable, Equatable, Sendable {
    let id: String
    let publisher: String
    let title: String
    let url: URL?
}

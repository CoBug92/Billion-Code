struct DenseGraphProfile: Sendable {
    let id: String
    let name: String
    let affiliations: [DenseGraphAffiliation]
    let industryIDs: [String]

    init(
        id: String,
        name: String,
        affiliations: [DenseGraphAffiliation],
        industryIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.affiliations = affiliations
        self.industryIDs = industryIDs
    }
}

struct DenseGraphAffiliation: Sendable {
    let entityID: String
    let entityName: String
    let entityKind: GraphEntityKind
    let edgeKind: DenseGraphEdge.Kind
    let period: String
    let detail: String

    static func work(
        _ id: String,
        _ name: String,
        _ period: String,
        _ role: String
    ) -> Self {
        Self(
            entityID: "organization:\(id)",
            entityName: name,
            entityKind: .organization,
            edgeKind: .business,
            period: period,
            detail: role
        )
    }

    static func study(
        _ id: String,
        _ name: String,
        _ period: String,
        _ program: String
    ) -> Self {
        Self(
            entityID: "university:\(id)",
            entityName: name,
            entityKind: .university,
            edgeKind: .education,
            period: period,
            detail: "(\(program))"
        )
    }
}

import Foundation

enum ContentEntityKind: String, Codable, CaseIterable, Sendable {
    case person
    case organization
    case university
    case foundation
    case family
    case deal
    case event
}

struct ContentMedia: Codable, Equatable, Sendable {
    let bundledResource: String?
    let mimeType: String
    let sha256: String
    let license: String
    let attribution: String
}

struct ContentEntity: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let kind: ContentEntityKind
    let name: String
    let shortName: String
    let summary: String
    let media: ContentMedia?

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case shortName
        case summary
        case media
    }

    init(
        id: String,
        kind: ContentEntityKind,
        name: String,
        shortName: String,
        summary: String,
        media: ContentMedia?
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.shortName = shortName
        self.summary = summary
        self.media = media
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(ContentEntityKind.self, forKey: .kind)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? id
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName) ?? name
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        media = try container.decodeIfPresent(ContentMedia.self, forKey: .media)
    }
}

struct ContentClaim: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let subjectID: String
    let text: String
    let sourceIDs: [String]
    let relationshipPosition: RelationshipPosition?

    enum CodingKeys: String, CodingKey {
        case id
        case subjectID = "subjectId"
        case text
        case sourceIDs = "sourceIds"
        case relationshipPosition
    }

    init(
        id: String,
        subjectID: String,
        text: String,
        sourceIDs: [String],
        relationshipPosition: RelationshipPosition? = nil
    ) {
        self.id = id
        self.subjectID = subjectID
        self.text = text
        self.sourceIDs = sourceIDs
        self.relationshipPosition = relationshipPosition
    }

    enum RelationshipPosition: String, Codable, Hashable, Sendable {
        case supports
        case challenges
    }
}

struct ContentSource: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let publisher: String
    let url: URL
    let tier: String
}

struct ContentRelationship: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let sourceEntityID: String
    let targetEntityID: String
    let kind: Kind
    let status: Status
    let claimIDs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case sourceEntityID = "sourceEntityId"
        case targetEntityID = "targetEntityId"
        case kind
        case status
        case claimIDs = "claimIds"
    }
}

extension ContentRelationship {
    enum Kind: String, Codable, Sendable {
        case family
        case founded
        case cofounded
        case employment
        case executiveRole = "executive_role"
        case boardRole = "board_role"
        case ownership
        case investment
        case deal
        case education
        case philanthropy
        case legalDispute = "legal_dispute"
    }

    enum Status: String, Codable, Sendable {
        case confirmed
        case disputed
    }
}

struct ContentEdition: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let featuredPersonID: String
    let visibleEntityIDs: [String]
    let visibleRelationshipIDs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case featuredPersonID = "featuredPersonId"
        case visibleEntityIDs = "visibleEntityIds"
        case visibleRelationshipIDs = "visibleRelationshipIds"
    }
}

import Foundation

struct GraphNode: Identifiable, Equatable, Sendable {
    let id: String
    let kind: GraphEntityKind
    let name: String
    let shortName: String
    let summary: String
    let portrait: PortraitReference?
    let position: GraphPoint

    init(
        id: String,
        kind: GraphEntityKind,
        name: String,
        shortName: String,
        summary: String,
        portrait: PortraitReference? = nil,
        position: GraphPoint
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.shortName = shortName
        self.summary = summary
        self.portrait = portrait
        self.position = position
    }
}

extension GraphNode {
    struct PortraitReference: Equatable, Sendable {
        let bundledResource: String?
        let remoteURL: URL?
        let accessibilityAttribution: String

        init(
            bundledResource: String? = nil,
            remoteURL: URL? = nil,
            accessibilityAttribution: String
        ) {
            self.bundledResource = bundledResource
            self.remoteURL = remoteURL
            self.accessibilityAttribution = accessibilityAttribution
        }
    }
}

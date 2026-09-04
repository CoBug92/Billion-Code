struct ChapterGraphLayout {
    func layout(
        chapter: GraphChapter,
        atlas: GraphAtlas,
        layoutVersion: Int
    ) -> [GraphNode.ID: NormalizedGraphPoint] {
        let heroID = atlas.node(id: chapter.heroNodeID)?.id ?? chapter.heroNodeID
        let members = chapter.memberIDs
            .filter { $0 != heroID }
            .sorted {
                stableHash("\(layoutVersion):\(chapter.id):\($0)")
                    < stableHash("\(layoutVersion):\(chapter.id):\($1)")
            }
        var result = [heroID: NormalizedGraphPoint(x: 0.5, y: 0.43)]

        for (index, nodeID) in members.enumerated() {
            result[nodeID] = anchor(index: index, count: members.count)
        }
        return result
    }
}

private extension ChapterGraphLayout {
    func anchor(index: Int, count: Int) -> NormalizedGraphPoint {
        let anchors: [NormalizedGraphPoint] = switch count {
        case 0: []
        case 1: [NormalizedGraphPoint(x: 0.5, y: 0.72)]
        case 2: [
            NormalizedGraphPoint(x: 0.24, y: 0.7),
            NormalizedGraphPoint(x: 0.76, y: 0.7)
        ]
        case 3: [
            NormalizedGraphPoint(x: 0.2, y: 0.66),
            NormalizedGraphPoint(x: 0.8, y: 0.66),
            NormalizedGraphPoint(x: 0.5, y: 0.8)
        ]
        case 4: [
            NormalizedGraphPoint(x: 0.2, y: 0.22),
            NormalizedGraphPoint(x: 0.8, y: 0.22),
            NormalizedGraphPoint(x: 0.2, y: 0.68),
            NormalizedGraphPoint(x: 0.8, y: 0.68)
        ]
        default: [
            NormalizedGraphPoint(x: 0.2, y: 0.2),
            NormalizedGraphPoint(x: 0.8, y: 0.2),
            NormalizedGraphPoint(x: 0.16, y: 0.64),
            NormalizedGraphPoint(x: 0.84, y: 0.64),
            NormalizedGraphPoint(x: 0.5, y: 0.8),
            NormalizedGraphPoint(x: 0.3, y: 0.82),
            NormalizedGraphPoint(x: 0.7, y: 0.82)
        ]
        }
        return anchors[min(index, anchors.count - 1)]
    }

    func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64.fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* UInt64.fnvPrime
        }
    }
}

private extension UInt64 {
    static let fnvOffset: UInt64 = 14_695_981_039_346_656_037
    static let fnvPrime: UInt64 = 1_099_511_628_211
}

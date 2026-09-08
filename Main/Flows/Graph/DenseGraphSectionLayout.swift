import Foundation

struct DenseGraphSectionLayout {
    func layout(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        personSectionIDs: [GraphNode.ID: [DenseGraphSection.ID]],
        sectionTitles: [DenseGraphSection.ID: String],
        layoutVersion: Int
    ) -> Result {
        let people = nodes.filter { $0.kind == .person }
        var peopleBySection: [DenseGraphSection.ID: [GraphNode]] = [:]
        for person in people {
            let sectionIDs = personSectionIDs[person.id, default: [String.otherSectionID]]
            for sectionID in sectionIDs {
                peopleBySection[sectionID, default: []].append(person)
            }
        }
        let unsortedSections: [WeightedSection] = peopleBySection.map { entry in
            WeightedSection(id: entry.key, count: entry.value.count)
        }
        let weightedSections = unsortedSections.sorted { left, right in
            left.count == right.count ? left.id < right.id : left.count > right.count
        }
        let regions = split(
            sections: weightedSections,
            region: DenseGraphSection.Region(
                minimumX: .worldInset,
                minimumY: .worldInset,
                maximumX: .graphWorldSide - .worldInset,
                maximumY: .graphWorldSide - .worldInset
            )
        )

        let sections = weightedSections.enumerated().compactMap { index, item -> DenseGraphSection? in
            guard let region = regions[item.id] else { return nil }
            return DenseGraphSection(
                id: item.id,
                title: sectionTitles[item.id] ?? item.id,
                personCount: item.count,
                region: region,
                accentIndex: index
            )
        }
        var membershipPositions: [GraphNode.ID: [DenseGraphSection.ID: GraphPoint]] = [:]
        for section in sections {
            let sectionPeople = peopleBySection[section.id, default: []].sorted { $0.id < $1.id }
            let sectionPositions = personPositions(
                people: sectionPeople,
                region: section.region,
                layoutVersion: layoutVersion
            )
            for (personID, position) in sectionPositions {
                membershipPositions[personID, default: [:]][section.id] = position
            }
        }
        var positions: [GraphNode.ID: GraphPoint] = Dictionary(uniqueKeysWithValues: people.compactMap { person in
            guard
                let primarySectionID = personSectionIDs[person.id]?.first,
                let position = membershipPositions[person.id]?[primarySectionID]
            else { return nil }
            return (person.id, position)
        })
        positions.merge(
            entityPositions(
                nodes: nodes,
                edges: edges,
                personPositions: positions,
                layoutVersion: layoutVersion
            ),
            uniquingKeysWith: { first, _ in first }
        )
        let memberships = membershipPositions.flatMap { personID, positionsBySection in
            positionsBySection.map { sectionID, position in
                DenseGraphSectionMembership(
                    personID: personID,
                    sectionID: sectionID,
                    position: position
                )
            }
        }
        .sorted { $0.id < $1.id }
        return Result(
            positions: positions,
            sections: sections,
            memberships: memberships
        )
    }
}

// MARK: - Result

extension DenseGraphSectionLayout {
    struct Result: Sendable {
        let positions: [GraphNode.ID: GraphPoint]
        let sections: [DenseGraphSection]
        let memberships: [DenseGraphSectionMembership]
    }
}

// MARK: - Section layout

private extension DenseGraphSectionLayout {
    struct WeightedSection {
        let id: String
        let count: Int
    }

    func split(
        sections: [WeightedSection],
        region: DenseGraphSection.Region
    ) -> [DenseGraphSection.ID: DenseGraphSection.Region] {
        guard let first = sections.first else { return [:] }
        guard sections.count > 1 else { return [first.id: region] }

        let total = sections.reduce(.zero) { $0 + $1.count }
        let splitIndex = balancedSplitIndex(sections: sections, total: total)
        let leading = Array(sections[..<splitIndex])
        let trailing = Array(sections[splitIndex...])
        let leadingCount = leading.reduce(.zero) { $0 + $1.count }
        let fraction = Double(leadingCount) / Double(total)
        let regions = divided(region: region, fraction: fraction)
        return split(sections: leading, region: regions.leading)
            .merging(split(sections: trailing, region: regions.trailing)) { first, _ in first }
    }

    func balancedSplitIndex(sections: [WeightedSection], total: Int) -> Int {
        var runningTotal = 0
        var bestIndex = 1
        var bestDifference = Int.max
        for index in 1 ..< sections.count {
            runningTotal += sections[index - 1].count
            let difference = abs(total - runningTotal * 2)
            if difference < bestDifference {
                bestDifference = difference
                bestIndex = index
            }
        }
        return bestIndex
    }

    func divided(
        region: DenseGraphSection.Region,
        fraction: Double
    ) -> (leading: DenseGraphSection.Region, trailing: DenseGraphSection.Region) {
        if region.width >= region.height {
            let divider = region.minimumX + region.width * fraction
            return (
                DenseGraphSection.Region(
                    minimumX: region.minimumX,
                    minimumY: region.minimumY,
                    maximumX: divider,
                    maximumY: region.maximumY
                ),
                DenseGraphSection.Region(
                    minimumX: divider,
                    minimumY: region.minimumY,
                    maximumX: region.maximumX,
                    maximumY: region.maximumY
                )
            )
        }
        let divider = region.minimumY + region.height * fraction
        return (
            DenseGraphSection.Region(
                minimumX: region.minimumX,
                minimumY: region.minimumY,
                maximumX: region.maximumX,
                maximumY: divider
            ),
            DenseGraphSection.Region(
                minimumX: region.minimumX,
                minimumY: divider,
                maximumX: region.maximumX,
                maximumY: region.maximumY
            )
        )
    }
}

// MARK: - Node layout

private extension DenseGraphSectionLayout {
    func personPositions(
        people: [GraphNode],
        region: DenseGraphSection.Region,
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        guard !people.isEmpty else { return [:] }
        let content = region.insetBy(dx: .sectionPadding, dy: .sectionPadding)
        let aspectRatio = max(content.width / max(content.height, 1), 0.1)
        let columns = max(Int(ceil(sqrt(Double(people.count) * aspectRatio))), 1)
        let rows = max(Int(ceil(Double(people.count) / Double(columns))), 1)
        let cellWidth = content.width / Double(columns)
        let cellHeight = content.height / Double(rows)

        return Dictionary(uniqueKeysWithValues: people.enumerated().map { index, person in
            let column = index % columns
            let row = index / columns
            let hash = stableHash("person:\(layoutVersion):\(person.id)")
            let jitterX = normalizedJitter(hash) * cellWidth * .personJitterFraction
            let jitterY = normalizedJitter(hash >> 16) * cellHeight * .personJitterFraction
            return (
                person.id,
                GraphPoint(
                    x: content.minimumX + (Double(column) + 0.5) * cellWidth + jitterX,
                    y: content.minimumY + (Double(row) + 0.5) * cellHeight + jitterY
                )
            )
        })
    }

    func entityPositions(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        personPositions: [GraphNode.ID: GraphPoint],
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        var personPointsByEntityID: [GraphNode.ID: [GraphPoint]] = [:]
        for edge in edges {
            if let point = personPositions[edge.sourceID] {
                personPointsByEntityID[edge.targetID, default: []].append(point)
            }
            if let point = personPositions[edge.targetID] {
                personPointsByEntityID[edge.sourceID, default: []].append(point)
            }
        }

        return Dictionary(uniqueKeysWithValues: nodes.compactMap { node in
            guard node.kind != .person else { return nil }
            let points = personPointsByEntityID[node.id, default: []]
            let center = average(points: points) ?? GraphPoint(x: .worldCenter, y: .worldCenter)
            let hash = stableHash("entity:\(layoutVersion):\(node.id)")
            return (
                node.id,
                GraphPoint(
                    x: (center.x + normalizedJitter(hash) * .entityJitter).clampedToWorld,
                    y: (center.y + normalizedJitter(hash >> 16) * .entityJitter).clampedToWorld
                )
            )
        })
    }

    func average(points: [GraphPoint]) -> GraphPoint? {
        guard !points.isEmpty else { return nil }
        let totals = points.reduce((x: 0.0, y: 0.0)) { partial, point in
            (partial.x + point.x, partial.y + point.y)
        }
        return GraphPoint(
            x: totals.x / Double(points.count),
            y: totals.y / Double(points.count)
        )
    }

    func normalizedJitter(_ value: UInt64) -> Double {
        Double(value % 10_001) / 5_000 - 1
    }

    func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64.fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* UInt64.fnvPrime
        }
    }
}

// MARK: - Constants

private extension Double {
    static let entityJitter = 110.0
    static let graphWorldSide = 10_000.0
    static let personJitterFraction = 0.24
    static let sectionPadding = 170.0
    static let worldCenter = 5_000.0
    static let worldInset = 180.0

    var clampedToWorld: Double {
        min(max(self, .worldInset), .graphWorldSide - .worldInset)
    }
}

private extension String {
    static let otherSectionID = "other"
}

private extension UInt64 {
    static let fnvOffset: UInt64 = 14_695_981_039_346_656_037
    static let fnvPrime: UInt64 = 1_099_511_628_211
}

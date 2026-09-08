import Foundation

struct DenseGraphLayout {
    func layout(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        let sortedNodes = nodes.sorted { $0.id < $1.id }
        let sortedEdges = edges.sorted { $0.id < $1.id }
        if sortedNodes.count > Int.forceLayoutNodeLimit {
            return scalableLayout(nodes: sortedNodes, edges: sortedEdges, layoutVersion: layoutVersion)
        }
        var points = Dictionary(uniqueKeysWithValues: sortedNodes.map { node in
            (node.id, initialPoint(id: node.id, version: layoutVersion))
        })

        for iteration in 0 ..< Int.iterations {
            var movement = Dictionary(uniqueKeysWithValues: sortedNodes.map { ($0.id, DenseVector.zero) })
            applyRepulsion(nodes: sortedNodes, points: points, movement: &movement)
            applyAttraction(edges: sortedEdges, points: points, movement: &movement)
            let temperature = Double.maximumMovement
                * (1 - Double(iteration) / Double(Int.iterations))
                + .minimumMovement
            move(nodes: sortedNodes, points: &points, movement: movement, limit: temperature)
        }
        resolveCollisions(nodes: sortedNodes, points: &points)
        return normalize(points)
    }
}

// MARK: - Large graph layout

private extension DenseGraphLayout {
    func scalableLayout(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        let side = max(Int(ceil(sqrt(Double(nodes.count) * 1.28))), 2)
        let inset = 260.0
        let spacing = (Double.graphWorldSide - inset * 2) / Double(side - 1)
        let nodesByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        var occupied = Set<Int>()
        var cellsByID: [GraphNode.ID: Int] = [:]

        let institutions = nodes
            .filter { $0.kind != .person }
            .sorted { stableHash("\(layoutVersion):\($0.id)") < stableHash("\(layoutVersion):\($1.id)") }
        for node in institutions {
            let preferred = Int(stableHash("institution:\(layoutVersion):\(node.id)") % UInt64(side * side))
            let cell = firstFreeCell(startingAt: preferred, side: side, occupied: occupied)
            occupied.insert(cell)
            cellsByID[node.id] = cell
        }

        var businessAnchorsByPersonID: [GraphNode.ID: GraphNode.ID] = [:]
        for edge in edges where edge.kind == .business {
            guard
                let source = nodesByID[edge.sourceID],
                let target = nodesByID[edge.targetID]
            else { continue }
            if source.kind == .person, target.kind != .person {
                businessAnchorsByPersonID[source.id] = businessAnchorsByPersonID[source.id] ?? target.id
            } else if target.kind == .person, source.kind != .person {
                businessAnchorsByPersonID[target.id] = businessAnchorsByPersonID[target.id] ?? source.id
            }
        }

        for person in nodes.filter({ $0.kind == .person }) {
            let preferred: Int
            if
                let anchorID = businessAnchorsByPersonID[person.id],
                let anchorCell = cellsByID[anchorID] {
                preferred = nearestFreeCell(
                    to: anchorCell,
                    side: side,
                    seed: stableHash("person:\(layoutVersion):\(person.id)"),
                    occupied: occupied
                )
            } else {
                let hashed = Int(stableHash("person:\(layoutVersion):\(person.id)") % UInt64(side * side))
                preferred = firstFreeCell(startingAt: hashed, side: side, occupied: occupied)
            }
            occupied.insert(preferred)
            cellsByID[person.id] = preferred
        }

        return Dictionary(uniqueKeysWithValues: nodes.compactMap { node in
            guard let cell = cellsByID[node.id] else { return nil }
            let column = cell % side
            let row = cell / side
            return (
                node.id,
                GraphPoint(
                    x: inset + Double(column) * spacing,
                    y: inset + Double(row) * spacing
                )
            )
        })
    }

    func firstFreeCell(startingAt preferred: Int, side: Int, occupied: Set<Int>) -> Int {
        let count = side * side
        for offset in 0 ..< count {
            let cell = (preferred + offset) % count
            if !occupied.contains(cell) { return cell }
        }
        return preferred
    }

    func nearestFreeCell(to anchor: Int, side: Int, seed: UInt64, occupied: Set<Int>) -> Int {
        let anchorColumn = anchor % side
        let anchorRow = anchor / side
        for radius in 1 ..< side {
            var candidates: [Int] = []
            for row in max(0, anchorRow - radius) ... min(side - 1, anchorRow + radius) {
                for column in max(0, anchorColumn - radius) ... min(side - 1, anchorColumn + radius) {
                    guard abs(column - anchorColumn) == radius || abs(row - anchorRow) == radius else { continue }
                    candidates.append(row * side + column)
                }
            }
            guard !candidates.isEmpty else { continue }
            let start = Int(seed % UInt64(candidates.count))
            for offset in candidates.indices {
                let cell = candidates[(start + offset) % candidates.count]
                if !occupied.contains(cell) { return cell }
            }
        }
        return firstFreeCell(startingAt: Int(seed % UInt64(side * side)), side: side, occupied: occupied)
    }
}

// MARK: - Forces

private extension DenseGraphLayout {
    func applyRepulsion(
        nodes: [GraphNode],
        points: [GraphNode.ID: GraphPoint],
        movement: inout [GraphNode.ID: DenseVector]
    ) {
        for leftIndex in nodes.indices {
            for rightIndex in nodes.indices where rightIndex > leftIndex {
                let left = nodes[leftIndex]
                let right = nodes[rightIndex]
                guard let leftPoint = points[left.id], let rightPoint = points[right.id] else { continue }
                var delta = DenseVector(from: rightPoint, to: leftPoint)
                if delta.length < .epsilon {
                    delta = deterministicDirection(left.id + right.id)
                }
                let force = Double.repulsion / max(delta.length * delta.length, .minimumDistanceSquared)
                let vector = delta.normalized * force
                movement[left.id, default: .zero] += vector
                movement[right.id, default: .zero] -= vector
            }
        }
    }

    func applyAttraction(
        edges: [DenseGraphEdge],
        points: [GraphNode.ID: GraphPoint],
        movement: inout [GraphNode.ID: DenseVector]
    ) {
        for edge in edges {
            guard let source = points[edge.sourceID], let target = points[edge.targetID] else { continue }
            let delta = DenseVector(from: source, to: target)
            let idealLength = edge.kind == .family ? Double.familyEdgeLength : .affiliationEdgeLength
            let vector = delta.normalized * ((delta.length - idealLength) * .attraction)
            movement[edge.sourceID, default: .zero] += vector
            movement[edge.targetID, default: .zero] -= vector
        }
    }

    func move(
        nodes: [GraphNode],
        points: inout [GraphNode.ID: GraphPoint],
        movement: [GraphNode.ID: DenseVector],
        limit: Double
    ) {
        for node in nodes {
            guard let point = points[node.id] else { continue }
            let gravity = DenseVector(from: point, to: .worldCenter) * .gravity
            let vector = (movement[node.id, default: .zero] + gravity).limited(to: limit)
            points[node.id] = point + vector
        }
    }
}

// MARK: - Collision resolution

private extension DenseGraphLayout {
    func resolveCollisions(
        nodes: [GraphNode],
        points: inout [GraphNode.ID: GraphPoint]
    ) {
        for _ in 0 ..< Int.collisionPasses {
            var moved = false
            for leftIndex in nodes.indices {
                for rightIndex in nodes.indices where rightIndex > leftIndex {
                    let leftID = nodes[leftIndex].id
                    let rightID = nodes[rightIndex].id
                    guard let left = points[leftID], let right = points[rightID] else { continue }
                    var delta = DenseVector(from: left, to: right)
                    if delta.length < .epsilon {
                        delta = deterministicDirection(leftID + rightID)
                    }
                    guard delta.length < .minimumNodeDistance else { continue }
                    let correction = delta.normalized * ((Double.minimumNodeDistance - delta.length) / 2 + 1)
                    points[leftID] = left - correction
                    points[rightID] = right + correction
                    moved = true
                }
            }
            if !moved { return }
        }
    }
}

// MARK: - Determinism

private extension DenseGraphLayout {
    func initialPoint(id: String, version: Int) -> GraphPoint {
        let hash = stableHash("\(version):\(id)")
        return GraphPoint(
            x: Double(hash % 8_001) - 4_000,
            y: Double((hash >> 20) % 8_001) - 4_000
        )
    }

    func normalize(_ points: [GraphNode.ID: GraphPoint]) -> [GraphNode.ID: GraphPoint] {
        guard
            let minimumX = points.values.map(\.x).min(),
            let maximumX = points.values.map(\.x).max(),
            let minimumY = points.values.map(\.y).min(),
            let maximumY = points.values.map(\.y).max()
        else { return points }

        let width = max(maximumX - minimumX, 1)
        let height = max(maximumY - minimumY, 1)
        let scale = Double.normalizedSide / max(width, height)
        let sourceCenter = GraphPoint(
            x: (minimumX + maximumX) / 2,
            y: (minimumY + maximumY) / 2
        )

        return points.mapValues { point in
            GraphPoint(
                x: Double.worldCenter + (point.x - sourceCenter.x) * scale,
                y: Double.worldCenter + (point.y - sourceCenter.y) * scale
            )
        }
    }

    func deterministicDirection(_ value: String) -> DenseVector {
        let angle = Double(stableHash(value) % 10_000) / 10_000 * 2 * Double.pi
        return DenseVector(x: cos(angle), y: sin(angle))
    }

    func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64.fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* UInt64.fnvPrime
        }
    }
}

private struct DenseVector {
    let x: Double
    let y: Double

    static let zero = DenseVector(x: .zero, y: .zero)

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from source: GraphPoint, to target: GraphPoint) {
        x = target.x - source.x
        y = target.y - source.y
    }

    var length: Double {
        hypot(x, y)
    }

    var normalized: DenseVector {
        let denominator = max(length, .epsilon)
        return DenseVector(x: x / denominator, y: y / denominator)
    }

    func limited(to maximum: Double) -> DenseVector {
        guard length > maximum else { return self }
        return normalized * maximum
    }

    static func + (left: DenseVector, right: DenseVector) -> DenseVector {
        DenseVector(x: left.x + right.x, y: left.y + right.y)
    }

    static func += (left: inout DenseVector, right: DenseVector) {
        left = left + right
    }

    static func -= (left: inout DenseVector, right: DenseVector) {
        left = DenseVector(x: left.x - right.x, y: left.y - right.y)
    }

    static func * (left: DenseVector, right: Double) -> DenseVector {
        DenseVector(x: left.x * right, y: left.y * right)
    }
}

private extension GraphPoint {
    static let worldCenter = GraphPoint(x: 5_000, y: 5_000)

    static func + (left: GraphPoint, right: DenseVector) -> GraphPoint {
        GraphPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: GraphPoint, right: DenseVector) -> GraphPoint {
        GraphPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

private extension Double {
    static let affiliationEdgeLength = 1_450.0
    static let attraction = 0.016
    static let epsilon = 0.001
    static let familyEdgeLength = 1_700.0
    static let graphWorldSide = 10_000.0
    static let gravity = 0.0012
    static let maximumMovement = 95.0
    static let minimumDistanceSquared = 10_000.0
    static let minimumMovement = 4.0
    static let minimumNodeDistance = 720.0
    static let normalizedSide = 9_200.0
    static let repulsion = 64_000_000.0
    static let worldCenter = 5_000.0
}

private extension Int {
    static let collisionPasses = 16
    static let forceLayoutNodeLimit = 600
    static let iterations = 140
}

private extension UInt64 {
    static let fnvOffset: UInt64 = 14_695_981_039_346_656_037
    static let fnvPrime: UInt64 = 1_099_511_628_211
}

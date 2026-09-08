import Foundation

struct DenseGraphLayout {
    func layout(
        nodes: [GraphNode],
        edges: [DenseGraphEdge],
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        let sortedNodes = nodes.sorted { $0.id < $1.id }
        let sortedEdges = edges.sorted { $0.id < $1.id }
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
    static let iterations = 140
}

private extension UInt64 {
    static let fnvOffset: UInt64 = 14_695_981_039_346_656_037
    static let fnvPrime: UInt64 = 1_099_511_628_211
}

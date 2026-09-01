import Foundation

struct StableOrganicGraphLayout {
    func layout(
        nodes: [GraphNode],
        relationships: [GraphRelationship],
        featuredNodeID: GraphNode.ID,
        layoutVersion: Int
    ) -> [GraphNode.ID: GraphPoint] {
        let sortedNodes = nodes.sorted { $0.id < $1.id }
        guard !sortedNodes.isEmpty else { return [:] }

        var positions = Dictionary(uniqueKeysWithValues: sortedNodes.map { node in
            (node.id, initialPoint(for: node.id, featuredNodeID: featuredNodeID, version: layoutVersion))
        })
        let sortedEdges = relationships.sorted { $0.id < $1.id }

        for iteration in 0 ..< Int.iterations {
            let temperature = Double.maximumStep * (1 - Double(iteration) / Double(Int.iterations)) + .minimumStep
            var displacement = Dictionary(uniqueKeysWithValues: sortedNodes.map { ($0.id, Vector.zero) })

            for leftIndex in sortedNodes.indices {
                for rightIndex in sortedNodes.indices where rightIndex > leftIndex {
                    let left = sortedNodes[leftIndex]
                    let right = sortedNodes[rightIndex]
                    guard let leftPoint = positions[left.id], let rightPoint = positions[right.id] else { continue }
                    var delta = Vector(from: rightPoint, to: leftPoint)
                    if delta.length < .epsilon {
                        delta = deterministicDirection(for: left.id + right.id)
                    }
                    let force = Double.repulsion / max(delta.length * delta.length, .minimumDistanceSquared)
                    let vector = delta.normalized * force
                    displacement[left.id, default: .zero] += vector
                    displacement[right.id, default: .zero] -= vector
                }
            }

            for edge in sortedEdges {
                guard let source = positions[edge.sourceID], let target = positions[edge.targetID] else { continue }
                let delta = Vector(from: source, to: target)
                let force = (delta.length - .idealEdgeLength) * .attraction
                let vector = delta.normalized * force
                displacement[edge.sourceID, default: .zero] += vector
                displacement[edge.targetID, default: .zero] -= vector
            }

            for node in sortedNodes where node.id != featuredNodeID {
                guard let point = positions[node.id] else { continue }
                let gravity = Vector(from: point, to: .worldCenter) * .gravity
                displacement[node.id, default: .zero] += gravity
            }

            for node in sortedNodes where node.id != featuredNodeID {
                guard let point = positions[node.id] else { continue }
                let movement = displacement[node.id, default: .zero].limited(to: temperature)
                positions[node.id] = (point + movement).clamped
            }
            positions[featuredNodeID] = .worldCenter
        }

        resolveCollisions(
            positions: &positions,
            nodeIDs: sortedNodes.map(\.id),
            featuredNodeID: featuredNodeID
        )
        positions[featuredNodeID] = .worldCenter
        return positions
    }
}

private extension StableOrganicGraphLayout {
    func initialPoint(for id: String, featuredNodeID: String, version: Int) -> GraphPoint {
        guard id != featuredNodeID else { return .worldCenter }
        let hash = stableHash("\(version):\(id)")
        let angle = Double(hash % 10_000) / 10_000 * 2 * Double.pi
        let radius = 1_700 + Double((hash >> 16) % 2_400)
        return GraphPoint(
            x: GraphPoint.worldCenter.x + cos(angle) * radius,
            y: GraphPoint.worldCenter.y + sin(angle) * radius
        ).clamped
    }

    func resolveCollisions(
        positions: inout [String: GraphPoint],
        nodeIDs: [String],
        featuredNodeID: String
    ) {
        for _ in 0 ..< Int.collisionPasses {
            var didMove = false
            for leftIndex in nodeIDs.indices {
                for rightIndex in nodeIDs.indices where rightIndex > leftIndex {
                    let leftID = nodeIDs[leftIndex]
                    let rightID = nodeIDs[rightIndex]
                    guard let left = positions[leftID], let right = positions[rightID] else { continue }
                    var delta = Vector(from: left, to: right)
                    if delta.length < .epsilon {
                        delta = deterministicDirection(for: leftID + rightID)
                    }
                    guard delta.length < .minimumNodeDistance else { continue }
                    let correction = delta.normalized * ((Double.minimumNodeDistance - delta.length) / 2 + 1)
                    if leftID != featuredNodeID {
                        positions[leftID] = (left - correction).clamped
                    }
                    if rightID != featuredNodeID {
                        positions[rightID] = (right + correction).clamped
                    }
                    didMove = true
                }
            }
            if !didMove { return }
        }
    }

    func deterministicDirection(for value: String) -> Vector {
        let angle = Double(stableHash(value) % 10_000) / 10_000 * 2 * Double.pi
        return Vector(x: cos(angle), y: sin(angle))
    }

    func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64.fnvOffset) { partial, byte in
            (partial ^ UInt64(byte)) &* UInt64.fnvPrime
        }
    }
}

private struct Vector {
    var x: Double
    var y: Double

    static let zero = Vector(x: .zero, y: .zero)

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

    var normalized: Vector {
        let divisor = max(length, .epsilon)
        return Vector(x: x / divisor, y: y / divisor)
    }

    func limited(to maximum: Double) -> Vector {
        guard length > maximum else { return self }
        return normalized * maximum
    }

    static func += (left: inout Vector, right: Vector) {
        left = Vector(x: left.x + right.x, y: left.y + right.y)
    }

    static func -= (left: inout Vector, right: Vector) {
        left = Vector(x: left.x - right.x, y: left.y - right.y)
    }

    static func * (left: Vector, right: Double) -> Vector {
        Vector(x: left.x * right, y: left.y * right)
    }
}

private extension GraphPoint {
    static let worldCenter = GraphPoint(x: 5_000, y: 5_000)

    var clamped: GraphPoint {
        GraphPoint(
            x: min(max(x, .worldInset), .worldMaximum),
            y: min(max(y, .worldInset), .worldMaximum)
        )
    }

    static func + (left: GraphPoint, right: Vector) -> GraphPoint {
        GraphPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: GraphPoint, right: Vector) -> GraphPoint {
        GraphPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

private extension Double {
    static let attraction = 0.018
    static let epsilon = 0.001
    static let gravity = 0.006
    static let idealEdgeLength = 1_600.0
    static let maximumStep = 90.0
    static let minimumStep = 4.0
    static let minimumNodeDistance = 760.0
    static let minimumDistanceSquared = 10_000.0
    static let repulsion = 48_000_000.0
    static let worldInset = 600.0
    static let worldMaximum = 9_400.0
}

private extension Int {
    static let collisionPasses = 24
    static let iterations = 180
}

private extension UInt64 {
    static let fnvOffset: UInt64 = 14_695_981_039_346_656_037
    static let fnvPrime: UInt64 = 1_099_511_628_211
}

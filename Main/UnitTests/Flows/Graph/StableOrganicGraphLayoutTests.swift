import Foundation
import Testing
@testable import BillionCode

@Suite("StableOrganicGraphLayout")
struct StableOrganicGraphLayoutTests {
    @Test("layout is deterministic, order-independent and centered")
    func deterministicLayout() {
        let nodes = (0 ..< 13).map { index in
            GraphNode(
                id: "person:\(index)",
                kind: .person,
                name: "Person \(index)",
                shortName: "P. \(index)",
                summary: "",
                position: GraphPoint(x: .zero, y: .zero)
            )
        }
        let relationships = (1 ..< 13).map { index in
            GraphRelationship(
                id: "relationship:\(index)",
                sourceID: "person:0",
                targetID: "person:\(index)",
                kind: .sharedContext,
                status: .confirmed,
                explanation: ""
            )
        }
        let layout = StableOrganicGraphLayout()

        let first = layout.layout(
            nodes: nodes,
            relationships: relationships,
            featuredNodeID: "person:0",
            layoutVersion: 1
        )
        let second = layout.layout(
            nodes: Array(nodes.reversed()),
            relationships: Array(relationships.reversed()),
            featuredNodeID: "person:0",
            layoutVersion: 1
        )

        #expect(first == second)
        #expect(first["person:0"] == GraphPoint(x: 5_000, y: 5_000))
        #expect(first.values.allSatisfy { $0.x.isFinite && $0.y.isFinite })

        let points = Array(first.values)
        for leftIndex in points.indices {
            for rightIndex in points.indices where rightIndex > leftIndex {
                #expect(hypot(points[leftIndex].x - points[rightIndex].x, points[leftIndex].y - points[rightIndex].y) >= 759)
            }
        }
    }
}

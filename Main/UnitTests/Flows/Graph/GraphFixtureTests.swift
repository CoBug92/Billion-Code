import Testing
@testable import BillionCode

@Suite("Graph spike fixture")
struct GraphFixtureTests {
    @Test("40 nodes and 80 relationships satisfy the spike limit")
    func spikeLimits() {
        let graph = GraphFixture.spike

        #expect(graph.nodes.count == 40)
        #expect(graph.relationships.count == 80)
        #expect(Set(graph.nodes.map(\.id)).count == graph.nodes.count)
        #expect(Set(graph.relationships.map(\.id)).count == graph.relationships.count)
    }

    @Test("Every relationship points to existing nodes")
    func relationshipReferences() {
        let graph = GraphFixture.spike
        let nodeIDs = Set(graph.nodes.map(\.id))

        for relationship in graph.relationships {
            #expect(nodeIDs.contains(relationship.sourceID))
            #expect(nodeIDs.contains(relationship.targetID))
        }
    }

    @Test("All world positions are stable and in range")
    func worldPositions() {
        let firstRead = GraphFixture.spike.nodes.map(\.position)
        let secondRead = GraphFixture.spike.nodes.map(\.position)

        #expect(firstRead == secondRead)
        #expect(firstRead.allSatisfy { 0 ... 10_000 ~= $0.x })
        #expect(firstRead.allSatisfy { 0 ... 10_000 ~= $0.y })
    }
}

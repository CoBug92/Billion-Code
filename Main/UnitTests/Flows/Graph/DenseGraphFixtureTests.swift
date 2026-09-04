import Testing
@testable import BillionCode

@Suite("Dense native graph fixture")
struct DenseGraphFixtureTests {
    @Test("Fixture contains 26 people and a dense affiliation network")
    func expectedScale() {
        let graph = DenseGraphFixture.performance
        let people = graph.nodes.filter { $0.kind == .person }

        #expect(people.count == 26)
        #expect(graph.nodes.count >= 90)
        #expect(graph.edges.count >= 100)
    }

    @Test("Every person has education and business affiliations")
    func completePeople() {
        let graph = DenseGraphFixture.performance

        for person in graph.nodes where person.kind == .person {
            let edges = graph.edges.filter { $0.connects(person.id) }
            #expect(edges.contains { $0.kind == .business })
            #expect(edges.contains { $0.kind == .education })
        }
    }

    @Test("Every edge points to unique existing nodes")
    func validReferences() {
        let graph = DenseGraphFixture.performance
        let nodeIDs = Set(graph.nodes.map(\.id))

        #expect(nodeIDs.count == graph.nodes.count)
        #expect(Set(graph.edges.map(\.id)).count == graph.edges.count)
        for edge in graph.edges {
            #expect(nodeIDs.contains(edge.sourceID))
            #expect(nodeIDs.contains(edge.targetID))
            #expect(edge.sourceID != edge.targetID)
        }
    }
}

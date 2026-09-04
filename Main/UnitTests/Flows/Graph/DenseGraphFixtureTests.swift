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
            #expect(graph.dossier(id: person.id)?.wealth != nil)
            #expect(graph.dossier(id: person.id)?.personDetails != nil)
            #expect(graph.dossier(id: person.id)?.education.isEmpty == false)
        }
        #expect(graph.nodes.filter { $0.kind == .person && $0.portrait != nil }.count == 24)
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

    @Test("Every node has a matching dossier")
    func completeDossiers() {
        let graph = DenseGraphFixture.performance

        #expect(graph.dossiers.count == graph.nodes.count)
        for node in graph.nodes {
            let dossier = graph.dossier(id: node.id)
            #expect(dossier?.entityID == node.id)
            #expect(dossier?.kind == node.kind)
            #expect(dossier?.description.isEmpty == false)
        }
    }

    @Test("Organizations and universities use specific public-facing types")
    func specificEntityTypes() {
        let graph = DenseGraphFixture.performance

        for node in graph.nodes where node.kind == .organization || node.kind == .university {
            let primaryFact = graph.dossier(id: node.id)?.facts.first?.value
            #expect(primaryFact?.isEmpty == false)
            #expect(primaryFact != "Компания или профессиональная организация")
            #expect(primaryFact != "Технологические продукты и сервисы")
            #expect(primaryFact != "Университет")
        }
    }

    @Test("Dossier links are current-first and point to graph nodes")
    func dossierLinks() {
        let graph = DenseGraphFixture.performance

        for dossier in graph.dossiers.values {
            for link in dossier.links {
                if let entityID = link.entityID {
                    #expect(graph.node(id: entityID) != nil)
                }
            }
            let currentCount = dossier.sortedLinks.prefix { $0.isCurrent }.count
            #expect(dossier.sortedLinks.dropFirst(currentCount).allSatisfy { !$0.isCurrent })
        }
    }
}

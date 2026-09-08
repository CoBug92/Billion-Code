import Testing
@testable import BillionCode

@Suite("Dense native graph fixture")
struct DenseGraphFixtureTests {
    @Test("Fixture covers the complete 2026 U.S. annual list and its related people")
    func expectedScale() {
        let graph = DenseGraphFixture.performance
        let people = graph.nodes.filter { $0.kind == .person }
        let catalog = AmericanBillionairesCatalog.current
        let annualIDs = Set(catalog.people.filter(\.isAmericanBillionaire2026).map(\.id))
        let graphIDs = Set(people.map(\.id))

        #expect(catalog.annualAmericanBillionaireCount == 989)
        #expect(annualIDs.count == 989)
        #expect(annualIDs.isSubset(of: graphIDs))
        #expect(people.count >= 1_400)
        #expect(graph.nodes.count >= 1_900)
        #expect(graph.edges.count >= 4_000)
    }

    @Test("Annual billionaire records expose sourced dossier data without invented education")
    func completePeople() {
        let graph = DenseGraphFixture.performance
        let annualPeople = AmericanBillionairesCatalog.current.people.filter(\.isAmericanBillionaire2026)

        for person in annualPeople {
            let dossier = graph.dossier(id: person.id)
            let edges = graph.edges.filter { $0.connects(person.id) }
            #expect(graph.node(id: person.id) != nil)
            #expect(dossier?.wealth != nil)
            #expect(dossier?.facts.contains { $0.id.hasSuffix(":forbes-rank") } == true)
            if !person.education.isEmpty {
                #expect(edges.contains { $0.kind == .education })
                #expect(dossier?.education.isEmpty == false)
            }
            if !person.sourcesOfWealth.isEmpty || person.organizationName != nil {
                #expect(edges.contains { $0.kind == .business })
            }
        }
        #expect(graph.nodes.filter { $0.kind == .person && $0.portrait != nil }.count >= 77)
    }

    @Test("Imported related-person references resolve inside the graph")
    func importedRelationshipsResolve() {
        let graph = DenseGraphFixture.performance
        let graphIDs = Set(graph.nodes.map(\.id))
        let relatedIDs = AmericanBillionairesCatalog.current.people
            .flatMap(\.relatedPeople)
            .map(\.personID)

        #expect(Set(relatedIDs).isSubset(of: graphIDs))
        #expect(graph.edges.filter { $0.kind == .association }.count >= 1_000)
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

    @Test("University dossiers expose an operating period and unique alumni")
    func universityPresentationData() {
        let graph = DenseGraphFixture.performance

        for university in graph.nodes where university.kind == .university {
            let dossier = graph.dossier(id: university.id)
            let alumniIDs = dossier?.links.compactMap(\.entityID) ?? []

            #expect(dossier?.operatingPeriod?.isEmpty == false)
            #expect(Set(alumniIDs).count == alumniIDs.count)
            #expect(dossier?.facts.contains { $0.id.hasSuffix(":people") } == false)
            #expect(dossier?.facts.contains { $0.id.hasSuffix(":founded") } == false)
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

    @Test("Featured company dossiers expose operating years and editorial highlights")
    func featuredCompanyDetails() {
        let graph = DenseGraphFixture.performance
        let expectedHighlights = [
            "organization:tesla",
            "organization:openai",
            "organization:microsoft",
            "organization:meta",
            "organization:credit-suisse"
        ]

        #expect(graph.dossier(id: "organization:tesla")?.operatingPeriod == "2003–н.в.")
        #expect(graph.dossier(id: "organization:credit-suisse")?.operatingPeriod == "1856–2023")
        for organizationID in expectedHighlights {
            let highlights = OrganizationDossierHighlights.events[organizationID]
            #expect(highlights?.isEmpty == false)
            #expect(highlights?.allSatisfy { $0.source != nil } == true)
        }
    }

    @Test("Organization dossiers expose operating periods and graph context")
    func organizationDossierContext() {
        let graph = DenseGraphFixture.performance

        for organization in graph.nodes where organization.kind == .organization {
            let dossier = graph.dossier(id: organization.id)
            #expect(dossier?.operatingPeriod?.isEmpty == false)
            #expect(dossier?.facts.contains { $0.id.hasSuffix(":graph-links") } == true)
            #expect(dossier?.timeline.isEmpty == false)
        }
    }

    @Test("Dossier timelines run from newest to oldest")
    func reverseChronologicalTimelines() {
        let graph = DenseGraphFixture.performance

        for dossier in graph.dossiers.values {
            let years = dossier.timeline.map(\.year)
            #expect(years == years.sorted(by: >))
        }
    }
}

import Foundation

struct AmericanBillionairesCatalog: Decodable, Sendable {
    let schemaVersion: Int
    let edition: String
    let wealthSnapshotDate: String
    let annualAmericanBillionaireCount: Int
    let sources: [String]
    let people: [Person]

    static let current = load()

    var peopleByID: [GraphNode.ID: Person] {
        Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })
    }

    var profiles: [DenseGraphProfile] {
        people.map { person in
            DenseGraphProfile(
                id: person.id,
                name: person.displayName,
                affiliations: person.affiliations,
                industryIDs: person.industries
            )
        }
    }

    var relationshipEdges: [DenseGraphEdge] {
        let includedIDs = Set(people.map(\.id))
        var edgesByID: [DenseGraphEdge.ID: DenseGraphEdge] = [:]

        for person in people {
            for related in person.relatedPeople where includedIDs.contains(related.personID) {
                let pair = [person.id, related.personID].sorted()
                guard pair[0] != pair[1] else { continue }
                let id = "edge:forbes-related:\(pair[0])--\(pair[1])"
                let detail = Self.localizedRelationship(related.relationship)
                if edgesByID[id] == nil || detail != "связанная персона" {
                    edgesByID[id] = DenseGraphEdge(
                        id: id,
                        sourceID: pair[0],
                        targetID: pair[1],
                        kind: .association,
                        period: "",
                        detail: detail
                    )
                }
            }
        }
        return edgesByID.values.sorted { $0.id < $1.id }
    }

    var organizationActivityByID: [GraphNode.ID: String] {
        var result: [GraphNode.ID: String] = [:]
        for person in people {
            let activity = person.industries.isEmpty
                ? "Источник состояния в рейтинге Forbes 2026"
                : person.industries.joined(separator: ", ")
            for affiliation in person.affiliations where affiliation.entityKind == .organization {
                result[affiliation.entityID] = activity
            }
        }
        return result
    }

    private static func localizedRelationship(_ value: String) -> String {
        let exact: [String: String] = [
            "": "связанная персона",
            "Family": "семейная связь",
            "Sibling": "братья / сёстры",
            "Spouse": "супруги",
            "Cofounder": "сооснователи",
            "Business Partner": "деловые партнёры",
            "Business Associate": "деловая связь",
            "Competitor": "конкуренты",
            "Colleague": "коллеги",
            "Friend": "друзья",
            "Fellow Board Member": "вместе в совете директоров"
        ]
        if let localized = exact[value] { return localized }

        let prefixes = [
            ("Related by origin of wealth: ", "связаны через источник состояния: "),
            ("Related by financial asset: ", "связаны через актив: "),
            ("Related by education: ", "связаны через образование: ")
        ]
        for (prefix, localized) in prefixes where value.hasPrefix(prefix) {
            return localized + value.dropFirst(prefix.count)
        }
        return value
    }
}

extension AmericanBillionairesCatalog {
    struct Person: Decodable, Sendable {
        let id: GraphNode.ID
        let sourceURI: String
        let name: String
        let nameRu: String?
        let portraitURL: URL?
        let isAmericanBillionaire2026: Bool
        let annualRank: Int?
        let netWorthUSD: UInt64
        let wealthAsOf: String
        let birthDate: String?
        let citizenship: String?
        let residenceCity: String?
        let residenceState: String?
        let residenceCountry: String?
        let industries: [String]
        let sourcesOfWealth: [String]
        let organizationName: String?
        let organizationTitle: String?
        let education: [Education]
        let relatedPeople: [RelatedPerson]

        var displayName: String {
            nameRu?.nonEmpty ?? name
        }

        var affiliations: [DenseGraphAffiliation] {
            var result: [DenseGraphAffiliation] = []
            var entityIDs = Set<GraphNode.ID>()

            for item in education where !item.school.isEmpty {
                let affiliation = DenseGraphAffiliation.study(
                    AmericanBillionairesCatalog.slug(item.school),
                    item.school,
                    "—",
                    item.degree?.nonEmpty ?? "программа не указана"
                )
                if entityIDs.insert(affiliation.entityID).inserted {
                    result.append(affiliation)
                }
            }

            if let organizationName = organizationName?.nonEmpty {
                let affiliation = DenseGraphAffiliation.work(
                    AmericanBillionairesCatalog.slug(organizationName),
                    organizationName,
                    "2026–н.в.",
                    organizationTitle?.nonEmpty ?? "руководящая роль"
                )
                entityIDs.insert(affiliation.entityID)
                result.append(affiliation)
            }

            for source in sourcesOfWealth where !source.isEmpty {
                let affiliation = DenseGraphAffiliation.work(
                    AmericanBillionairesCatalog.slug(source),
                    source,
                    "2026–н.в.",
                    "источник состояния · Forbes 2026"
                )
                if entityIDs.insert(affiliation.entityID).inserted {
                    result.append(affiliation)
                }
            }
            return result
        }

        var residence: String? {
            let parts = [residenceCity, residenceState, Self.countryName(residenceCountry)]
                .compactMap { $0?.nonEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }

        private static func countryName(_ code: String?) -> String? {
            guard let code else { return nil }
            return Locale(identifier: "ru_RU").localizedString(forRegionCode: code.uppercased()) ?? code.uppercased()
        }
    }

    struct Education: Decodable, Sendable {
        let school: String
        let degree: String?
    }

    struct RelatedPerson: Decodable, Sendable {
        let personID: GraphNode.ID
        let name: String
        let relationship: String
    }
}

private extension AmericanBillionairesCatalog {
    static func load() -> AmericanBillionairesCatalog {
        guard
            let url = Bundle.main.url(forResource: "american-billionaires-2026", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(AmericanBillionairesCatalog.self, from: data)
        else {
            assertionFailure("american-billionaires-2026.json is missing or invalid")
            return AmericanBillionairesCatalog(
                schemaVersion: 1,
                edition: "Unavailable",
                wealthSnapshotDate: "",
                annualAmericanBillionaireCount: 0,
                sources: [],
                people: []
            )
        }
        return catalog
    }

    static func slug(_ value: String) -> String {
        let latin = value.applyingTransform(.toLatin, reverse: false) ?? value
        let folded = latin.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let parts = folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return parts.joined(separator: "-").lowercased()
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

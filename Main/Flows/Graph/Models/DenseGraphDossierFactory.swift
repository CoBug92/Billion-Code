import Foundation

enum DenseGraphDossierFactory {
    static func make(nodes: [GraphNode], edges: [DenseGraphEdge]) -> [GraphNode.ID: EntityDossier] {
        let nodesByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        return Dictionary(uniqueKeysWithValues: nodes.map { node in
            let connected = edges.filter { $0.connects(node.id) }
            let links = connected.compactMap { edge -> DossierEntityLink? in
                guard let otherID = edge.opposite(node.id), let other = nodesByID[otherID] else { return nil }
                let period = DenseGraphPeriod(edge.period)
                return DossierEntityLink(
                    id: edge.id,
                    entityID: other.id,
                    name: other.name,
                    role: edge.detail,
                    period: edge.period,
                    startYear: period?.startYear ?? .zero,
                    isCurrent: edge.period.contains("н.в."),
                    source: edge.kind == .association ? forbesSource : nil
                )
            }
            return (node.id, dossier(for: node, links: links))
        })
    }
}

private extension DenseGraphDossierFactory {
    static let catalogPeopleByID = AmericanBillionairesCatalog.current.peopleByID
    static let catalogOrganizationActivity = AmericanBillionairesCatalog.current.organizationActivityByID

    static let forbesSource = DossierSource(
        id: "source:forbes-real-time",
        publisher: "Forbes",
        title: "Real-Time Billionaires",
        url: URL(string: "https://www.forbes.com/real-time-billionaires/")
    )

    static let forbesAnnualSource = DossierSource(
        id: "source:forbes-billionaires-2026",
        publisher: "Forbes",
        title: "World’s Billionaires 2026",
        url: URL(string: "https://www.forbes.com/billionaires/")
    )

    static let publicEstimateSource = DossierSource(
        id: "source:public-estimates",
        publisher: "Открытые источники",
        title: "Оценки долей и капитала",
        url: nil
    )

    static func dossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        switch node.kind {
        case .person:
            personDossier(for: node, links: links)
        case .organization:
            organizationDossier(for: node, links: links)
        case .university:
            universityDossier(for: node, links: links)
        case .foundation, .family, .deal, .event:
            genericDossier(for: node, links: links)
        }
    }

    static func personDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        let work = links.filter { $0.entityID?.hasPrefix("organization:") == true }
        let education = links.filter { $0.entityID?.hasPrefix("university:") == true }
        let relatedPeople = links.filter { $0.entityID?.hasPrefix("person:") == true }
        let current = work.filter(\.isCurrent)
        let description: String
        if let first = work.min(by: { $0.startYear < $1.startYear }),
           let latest = work.max(by: { $0.startYear < $1.startYear }) {
            let educationText = education.isEmpty ? "" : " Образовательный контур: \(education.map(\.name).joined(separator: ", "))."
            let currentText = current.isEmpty ? "" : " Текущая связка в графе: \(current.map(\.name).joined(separator: ", "))."
            description = "Путь от роли «\(first.role)» в \(first.name) до этапа «\(latest.role)» в \(latest.name)."
                + educationText
                + currentText
        } else {
            description = "Датированный профиль связей человека в текущей версии графа."
        }

        var facts = [
            DossierFact(
                id: "\(node.id):status",
                label: "Сейчас связан",
                value: current.isEmpty ? "Текущие роли не указаны" : current.map(\.name).joined(separator: ", "),
                source: nil
            ),
            DossierFact(
                id: "\(node.id):education",
                label: "Образование",
                value: education.isEmpty ? "Не указано" : education.map(\.name).joined(separator: ", "),
                source: nil
            )
        ]
        if let record = catalogPeopleByID[node.id] {
            if let annualRank = record.annualRank {
                facts.append(
                    DossierFact(
                        id: "\(node.id):forbes-rank",
                        label: "Forbes 2026",
                        value: "№\(annualRank) в мировом списке",
                        source: forbesAnnualSource
                    )
                )
            }
            if !record.sourcesOfWealth.isEmpty {
                facts.append(
                    DossierFact(
                        id: "\(node.id):wealth-source",
                        label: "Источник состояния",
                        value: record.sourcesOfWealth.joined(separator: ", "),
                        source: record.isAmericanBillionaire2026 ? forbesAnnualSource : forbesSource
                    )
                )
            }
            if !record.industries.isEmpty {
                facts.append(
                    DossierFact(
                        id: "\(node.id):industry",
                        label: "Отрасль",
                        value: record.industries.joined(separator: ", "),
                        source: record.isAmericanBillionaire2026 ? forbesAnnualSource : forbesSource
                    )
                )
            }
            if let residence = record.residence {
                facts.append(
                    DossierFact(
                        id: "\(node.id):residence",
                        label: "Место проживания",
                        value: residence,
                        source: record.isAmericanBillionaire2026 ? forbesAnnualSource : forbesSource
                    )
                )
            }
        }
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: description,
            operatingPeriod: nil,
            lastReviewedOn: "04.09.2026",
            facts: facts,
            links: work + relatedPeople,
            timeline: timeline(from: links),
            wealth: wealthByPersonID[node.id],
            personDetails: personDetailsByID[node.id],
            education: education
        )
    }

    static func organizationDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        let founders = links.filter {
            let role = $0.role.lowercased()
            return role.contains("основател") || role.contains("соосновател")
        }
        let people = uniquePeople(in: links)
        let activity = organizationActivity[node.id]
            ?? catalogOrganizationActivity[node.id]
            ?? "Деловые активы и профессиональная деятельность"
        let operatingPeriod = organizationOperatingPeriod(for: node.id, links: links)
        var facts = [
            DossierFact(id: "\(node.id):activity", label: "Вид деятельности", value: activity, source: nil)
        ]
        if let year = foundationYears[node.id] {
            facts.append(DossierFact(id: "\(node.id):founded", label: "Основана", value: String(year), source: nil))
        }
        facts.append(
            DossierFact(
                id: "\(node.id):founders",
                label: "Основатели в графе",
                value: founders.isEmpty ? "Не представлены" : founders.map(\.name).joined(separator: ", "),
                source: nil
            )
        )
        facts.append(
            DossierFact(
                id: "\(node.id):graph-links",
                label: "Связей в графе",
                value: "\(people.count) \(russianPeopleUnit(people.count))",
                source: nil
            )
        )
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: organizationDescription(
                name: node.name,
                activity: activity,
                founders: founders,
                people: people
            ),
            operatingPeriod: operatingPeriod,
            lastReviewedOn: "04.09.2026",
            facts: facts,
            links: links,
            timeline: organizationTimeline(for: node.id, links: links),
            wealth: nil,
            personDetails: nil,
            education: []
        )
    }

    static func universityDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        let metadata = universityMetadata[node.id] ?? (
            type: "Исследовательский университет",
            location: "Не указано",
            operatingPeriod: "—"
        )
        let alumni = uniquePeople(in: links)
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: "\(node.name) — образовательная организация. Здесь собраны программы и периоды обучения людей из текущего графа.",
            operatingPeriod: universityOperatingPeriod(from: metadata.operatingPeriod),
            lastReviewedOn: "04.09.2026",
            facts: [
                DossierFact(id: "\(node.id):type", label: "Тип", value: metadata.type, source: nil),
                DossierFact(id: "\(node.id):location", label: "Местоположение", value: metadata.location, source: nil)
            ],
            links: alumni,
            timeline: timeline(from: alumni),
            wealth: nil,
            personDetails: nil,
            education: []
        )
    }

    static func uniquePeople(in links: [DossierEntityLink]) -> [DossierEntityLink] {
        var seenEntityIDs = Set<GraphNode.ID>()
        return links.filter { link in
            guard let entityID = link.entityID else { return true }
            return seenEntityIDs.insert(entityID).inserted
        }
    }

    static func universityOperatingPeriod(from foundationYear: String) -> String {
        guard foundationYear != "—", !foundationYear.contains("–") else { return foundationYear }
        return "\(foundationYear)–н.в."
    }

    static func genericDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: node.summary.isEmpty ? "Сущность текущего доказательного графа." : node.summary,
            operatingPeriod: nil,
            lastReviewedOn: "04.09.2026",
            facts: [],
            links: links,
            timeline: timeline(from: links),
            wealth: nil,
            personDetails: nil,
            education: []
        )
    }

    static func timeline(from links: [DossierEntityLink]) -> [DossierTimelineEvent] {
        links
            .filter { $0.startYear > .zero }
            .sorted {
                if $0.startYear != $1.startYear { return $0.startYear > $1.startYear }
                return $0.id < $1.id
            }
            .map {
                DossierTimelineEvent(
                    id: "timeline:\($0.id)",
                    year: $0.startYear,
                    title: $0.name,
                    description: "\($0.role) · \($0.period)",
                    linkedEntityID: $0.entityID,
                    source: $0.source
                )
            }
    }

    static func organizationTimeline(
        for organizationID: GraphNode.ID,
        links: [DossierEntityLink]
    ) -> [DossierTimelineEvent] {
        (timeline(from: links) + (OrganizationDossierHighlights.events[organizationID] ?? []))
            .appendingFoundationEvent(
                for: organizationID,
                year: foundationYears[organizationID]
            )
            .sorted {
                if $0.year != $1.year { return $0.year > $1.year }
                return $0.id < $1.id
            }
    }

    static func organizationDescription(
        name: String,
        activity: String,
        founders: [DossierEntityLink],
        people: [DossierEntityLink]
    ) -> String {
        let foundersText = founders.isEmpty
            ? "В текущем графе основатели не выделены отдельной связью."
            : "Основатели/сооснователи в графе: \(founders.map(\.name).joined(separator: ", "))."
        let peopleText = people.isEmpty
            ? "Связанные люди появятся по мере расширения графа."
            : "Карточка связывает \(people.count) \(russianPeopleUnit(people.count)) через роли, учебные и карьерные траектории."
        return "\(name) — \(activity.lowercased()). \(foundersText) \(peopleText)"
    }

    static func organizationOperatingPeriod(
        for organizationID: GraphNode.ID,
        links: [DossierEntityLink]
    ) -> String? {
        if let highlightedPeriod = OrganizationDossierHighlights.operatingPeriods[organizationID] {
            return highlightedPeriod
        }
        if let foundationYear = foundationYears[organizationID] {
            return "\(foundationYear)–н.в."
        }
        let startedLinks = links.filter { $0.startYear > .zero }
        guard let firstYear = startedLinks.map(\.startYear).min() else { return nil }
        if links.contains(where: \.isCurrent) { return "\(firstYear)–н.в." }
        guard let lastYear = startedLinks.map(\.startYear).max(), lastYear != firstYear else {
            return "\(firstYear)"
        }
        return "\(firstYear)–\(lastYear)"
    }

    static func russianPeopleUnit(_ count: Int) -> String {
        let lastTwoDigits = count % 100
        if 11...14 ~= lastTwoDigits { return "человек" }
        return switch count % 10 {
        case 1: "человек"
        case 2...4: "человека"
        default: "человек"
        }
    }

    static let wealthByPersonID: [GraphNode.ID: DossierWealth] = {
        let values: [GraphNode.ID: UInt64] = [
            "person:elon-musk": 872_300_000_000, "person:kimbal-musk": 700_000_000,
            "person:jb-straubel": 1_100_000_000, "person:martin-eberhard": 500_000_000,
            "person:marc-tarpenning": 500_000_000, "person:ian-wright": 20_000_000,
            "person:gwynne-shotwell": 1_000_000_000, "person:sam-altman": 2_000_000_000,
            "person:greg-brockman": 500_000_000, "person:ilya-sutskever": 1_000_000_000,
            "person:peter-thiel": 32_900_000_000, "person:max-levchin": 3_500_000_000,
            "person:reid-hoffman": 2_700_000_000, "person:larry-page": 279_700_000_000,
            "person:sergey-brin": 258_200_000_000, "person:eric-schmidt": 35_000_000_000,
            "person:sundar-pichai": 1_300_000_000, "person:susan-wojcicki": 800_000_000,
            "person:mark-zuckerberg": 209_900_000_000, "person:dustin-moskovitz": 10_300_000_000,
            "person:sheryl-sandberg": 2_400_000_000, "person:bill-gates": 111_300_000_000,
            "person:steve-ballmer": 152_600_000_000, "person:satya-nadella": 1_400_000_000,
            "person:jeff-bezos": 267_600_000_000, "person:jensen-huang": 197_200_000_000,
            "person:steve-jobs": 10_200_000_000, "person:tim-cook": 2_300_000_000,
            "person:larry-ellison": 204_600_000_000, "person:marc-benioff": 10_100_000_000,
            "person:patrick-collison": 7_200_000_000, "person:john-collison": 7_200_000_000,
            "person:jack-dorsey": 5_100_000_000, "person:evan-spiegel": 2_500_000_000,
            "person:bobby-murphy": 2_600_000_000, "person:brian-chesky": 11_900_000_000,
            "person:travis-kalanick": 4_000_000_000, "person:dara-khosrowshahi": 250_000_000,
            "person:paul-allen": 20_300_000_000, "person:andy-jassy": 500_000_000,
            "person:mackenzie-scott": 31_000_000_000, "person:howard-schultz": 3_000_000_000,
            "person:reed-hastings": 4_000_000_000, "person:marc-randolph": 100_000_000,
            "person:larry-fink": 1_200_000_000, "person:michael-bloomberg": 104_700_000_000,
            "person:stephen-schwarzman": 44_000_000_000, "person:ken-griffin": 47_800_000_000,
            "person:jamie-dimon": 2_300_000_000, "person:warren-buffett": 150_000_000_000,
            "person:charlie-munger": 2_600_000_000, "person:sam-walton": 8_600_000_000,
            "person:alice-walton": 106_000_000_000, "person:rob-walton": 103_000_000_000,
            "person:michael-dell": 148_000_000_000, "person:mark-cuban": 5_700_000_000,
            "person:marc-andreessen": 1_800_000_000, "person:ben-horowitz": 3_500_000_000,
            "person:vinod-khosla": 9_200_000_000, "person:john-doerr": 15_200_000_000,
            "person:mary-meeker": 400_000_000, "person:mary-barra": 250_000_000,
            "person:henry-ford": 1_200_000_000, "person:alfred-sloan": 250_000_000,
            "person:gordon-moore": 7_000_000_000, "person:robert-noyce": 3_700_000_000,
            "person:andy-grove": 500_000_000, "person:lisa-su": 1_300_000_000,
            "person:pat-gelsinger": 200_000_000, "person:morris-chang": 3_300_000_000,
            "person:safra-catz": 2_100_000_000, "person:diane-greene": 600_000_000,
            "person:ursula-burns": 50_000_000, "person:whitney-wolfe-herd": 500_000_000,
            "person:brian-armstrong": 11_200_000_000, "person:fred-ehrsam": 3_000_000_000,
            "person:aaron-levie": 100_000_000, "person:drew-houston": 2_800_000_000,
            "person:melinda-french-gates": 30_000_000_000,
            "person:lauren-powell-jobs": 13_000_000_000,
            "person:anne-wojcicki": 700_000_000, "person:brian-acton": 2_500_000_000,
            "person:jan-koum": 13_000_000_000, "person:noubar-afeyan": 1_900_000_000,
            "person:robert-langer": 1_500_000_000,
            "person:jim-walton": 128_000_000_000, "person:lukas-walton": 36_000_000_000,
            "person:charles-koch": 67_000_000_000, "person:julia-koch": 74_000_000_000,
            "person:chase-koch": 2_000_000_000, "person:jacqueline-mars": 42_000_000_000,
            "person:john-mars": 42_000_000_000, "person:abigail-johnson": 35_000_000_000,
            "person:edward-johnson-iii": 10_000_000_000, "person:phil-knight": 38_000_000_000,
            "person:travis-knight": 2_000_000_000, "person:miriam-adelson": 32_000_000_000,
            "person:sheldon-adelson": 35_000_000_000, "person:thomas-peterffy": 65_000_000_000,
            "person:stephen-cohen": 21_000_000_000, "person:ray-dalio": 16_000_000_000,
            "person:david-tepper": 20_000_000_000, "person:george-soros": 7_000_000_000,
            "person:jim-simons": 31_000_000_000, "person:donald-bren": 18_000_000_000,
            "person:stephen-ross": 10_000_000_000, "person:sam-zell": 5_000_000_000,
            "person:rupert-murdoch": 21_000_000_000, "person:lachlan-murdoch": 3_000_000_000,
            "person:michael-rubin": 11_000_000_000, "person:robert-kraft": 12_000_000_000,
            "person:jerry-jones": 16_000_000_000, "person:stanley-kroenke": 19_000_000_000,
            "person:ann-walton-kroenke": 12_000_000_000,
            "person:diane-hendricks": 23_000_000_000, "person:tom-gores": 9_000_000_000,
            "person:tilman-fertitta": 11_000_000_000, "person:robert-f-smith": 10_000_000_000,
            "person:henry-kravis": 12_000_000_000, "person:george-roberts": 12_000_000_000,
            "person:david-rubenstein": 4_000_000_000, "person:marc-rowan": 8_000_000_000,
            "person:josh-kushner": 3_000_000_000, "person:vlad-tenev": 6_000_000_000
        ]
        let forbesIDs: Set<GraphNode.ID> = [
            "person:elon-musk", "person:peter-thiel", "person:reid-hoffman", "person:larry-page",
            "person:sergey-brin", "person:mark-zuckerberg", "person:dustin-moskovitz",
            "person:sheryl-sandberg", "person:bill-gates", "person:steve-ballmer",
            "person:satya-nadella", "person:jeff-bezos", "person:jensen-huang",
            "person:larry-ellison", "person:marc-benioff", "person:patrick-collison",
            "person:john-collison", "person:jack-dorsey", "person:evan-spiegel",
            "person:bobby-murphy", "person:brian-chesky", "person:travis-kalanick",
            "person:mackenzie-scott", "person:howard-schultz", "person:reed-hastings",
            "person:michael-bloomberg", "person:stephen-schwarzman", "person:ken-griffin",
            "person:jamie-dimon", "person:warren-buffett", "person:alice-walton",
            "person:rob-walton", "person:michael-dell", "person:mark-cuban",
            "person:marc-andreessen", "person:ben-horowitz", "person:vinod-khosla",
            "person:john-doerr", "person:lisa-su", "person:morris-chang",
            "person:safra-catz", "person:brian-armstrong", "person:fred-ehrsam",
            "person:drew-houston", "person:melinda-french-gates",
            "person:lauren-powell-jobs", "person:brian-acton", "person:jan-koum",
            "person:noubar-afeyan", "person:robert-langer", "person:jim-walton",
            "person:lukas-walton", "person:charles-koch", "person:julia-koch",
            "person:jacqueline-mars", "person:john-mars", "person:abigail-johnson",
            "person:phil-knight", "person:miriam-adelson", "person:thomas-peterffy",
            "person:stephen-cohen", "person:ray-dalio", "person:david-tepper",
            "person:donald-bren", "person:stephen-ross", "person:rupert-murdoch",
            "person:michael-rubin", "person:robert-kraft", "person:jerry-jones",
            "person:stanley-kroenke", "person:ann-walton-kroenke",
            "person:diane-hendricks", "person:tom-gores", "person:tilman-fertitta",
            "person:robert-f-smith", "person:henry-kravis", "person:george-roberts",
            "person:marc-rowan", "person:josh-kushner", "person:vlad-tenev"
        ]
        var result = values.mapValues { amount in
            DossierWealth(
                amountUSD: amount,
                asOf: "04.09.2026",
                methodology: "Оценка капитала по открытым данным о долях и активах.",
                source: publicEstimateSource,
                components: [],
                history: [DossierWealthPoint(id: "2026", year: 2026, amountUSD: amount)]
            )
        }
        for id in forbesIDs {
            guard let amount = values[id] else { continue }
            result[id] = DossierWealth(
                amountUSD: amount,
                asOf: "04.09.2026",
                methodology: "Оценка состояния по Forbes Real-Time Billionaires.",
                source: forbesSource,
                components: [],
                history: [DossierWealthPoint(id: "2026", year: 2026, amountUSD: amount)]
            )
        }
        for person in AmericanBillionairesCatalog.current.people where person.netWorthUSD > 0 {
            let source = person.isAmericanBillionaire2026 ? forbesAnnualSource : forbesSource
            result[person.id] = DossierWealth(
                amountUSD: person.netWorthUSD,
                asOf: person.wealthAsOf,
                methodology: person.isAmericanBillionaire2026
                    ? "Годовая оценка состояния Forbes на 1 марта 2026 года."
                    : "Оценка по профилю Forbes Real-Time Billionaires.",
                source: source,
                components: person.sourcesOfWealth.enumerated().map { index, value in
                    DossierWealthComponent(
                        id: "\(person.id):wealth-component:\(index)",
                        label: value,
                        detail: "Указанный Forbes источник состояния"
                    )
                },
                history: [
                    DossierWealthPoint(id: "\(person.id):wealth-2026", year: 2026, amountUSD: person.netWorthUSD)
                ]
            )
        }
        return result
    }()

    static let personDetailsByID: [GraphNode.ID: DossierPersonDetails] = {
        func details(_ year: Int, _ month: Int? = nil, _ day: Int? = nil) -> DossierPersonDetails {
            DossierPersonDetails(birthDate: .init(year: year, month: month, day: day), ageReferenceDate: nil)
        }
        var values: [GraphNode.ID: DossierPersonDetails] = [
            "person:elon-musk": details(1971, 6, 28), "person:kimbal-musk": details(1972, 9, 20),
            "person:jb-straubel": details(1975, 12, 20), "person:martin-eberhard": details(1960, 5, 15),
            "person:marc-tarpenning": details(1964, 6, 1), "person:ian-wright": details(1956),
            "person:gwynne-shotwell": details(1963, 11, 23), "person:sam-altman": details(1985, 4, 22),
            "person:greg-brockman": details(1987, 11, 29), "person:ilya-sutskever": details(1986, 12, 8),
            "person:peter-thiel": details(1967, 10, 11), "person:max-levchin": details(1975, 7, 11),
            "person:reid-hoffman": details(1967, 8, 5), "person:larry-page": details(1973, 3, 26),
            "person:sergey-brin": details(1973, 8, 21), "person:eric-schmidt": details(1955, 4, 27),
            "person:sundar-pichai": details(1972, 6, 10), "person:mark-zuckerberg": details(1984, 5, 14),
            "person:dustin-moskovitz": details(1984, 5, 22), "person:sheryl-sandberg": details(1969, 8, 28),
            "person:bill-gates": details(1955, 10, 28), "person:steve-ballmer": details(1956, 3, 24),
            "person:satya-nadella": details(1967, 8, 19), "person:jeff-bezos": details(1964, 1, 12),
            "person:jensen-huang": details(1963, 2, 17), "person:tim-cook": details(1960, 11, 1),
            "person:larry-ellison": details(1944, 8, 17), "person:marc-benioff": details(1964, 9, 25),
            "person:patrick-collison": details(1988, 9, 9), "person:john-collison": details(1990, 8, 6),
            "person:jack-dorsey": details(1976, 11, 19), "person:evan-spiegel": details(1990, 6, 4),
            "person:bobby-murphy": details(1988, 7, 19), "person:brian-chesky": details(1981, 8, 29),
            "person:travis-kalanick": details(1976, 8, 6), "person:dara-khosrowshahi": details(1969, 5, 28),
            "person:andy-jassy": details(1968, 1, 13), "person:mackenzie-scott": details(1970, 4, 7),
            "person:howard-schultz": details(1953, 7, 19), "person:reed-hastings": details(1960, 10, 8),
            "person:marc-randolph": details(1958, 4, 29), "person:larry-fink": details(1952, 11, 2),
            "person:michael-bloomberg": details(1942, 2, 14),
            "person:stephen-schwarzman": details(1947, 2, 14),
            "person:ken-griffin": details(1968, 10, 15), "person:jamie-dimon": details(1956, 3, 13),
            "person:warren-buffett": details(1930, 8, 30), "person:alice-walton": details(1949, 10, 7),
            "person:rob-walton": details(1944, 10, 28), "person:michael-dell": details(1965, 2, 23),
            "person:mark-cuban": details(1958, 7, 31),
            "person:marc-andreessen": details(1971, 7, 9), "person:ben-horowitz": details(1966, 6, 13),
            "person:vinod-khosla": details(1955, 1, 28), "person:john-doerr": details(1951, 6, 29),
            "person:mary-meeker": details(1959, 9), "person:mary-barra": details(1961, 12, 24),
            "person:lisa-su": details(1969, 11, 7), "person:pat-gelsinger": details(1961, 3, 5),
            "person:morris-chang": details(1931, 7, 10), "person:safra-catz": details(1961, 12, 1),
            "person:diane-greene": details(1955, 6, 9), "person:ursula-burns": details(1958, 9, 20),
            "person:whitney-wolfe-herd": details(1989, 7, 1),
            "person:brian-armstrong": details(1983, 1, 25), "person:fred-ehrsam": details(1988, 5, 10),
            "person:aaron-levie": details(1985, 12, 27), "person:drew-houston": details(1983, 3, 4),
            "person:melinda-french-gates": details(1964, 8, 15),
            "person:lauren-powell-jobs": details(1963, 11, 6),
            "person:anne-wojcicki": details(1973, 7, 28), "person:brian-acton": details(1972, 2, 17),
            "person:jan-koum": details(1976, 2, 24), "person:noubar-afeyan": details(1962, 7, 25),
            "person:robert-langer": details(1948, 8, 29),
            "person:jim-walton": details(1948, 6, 7), "person:lukas-walton": details(1986, 9, 22),
            "person:charles-koch": details(1935, 11, 1), "person:julia-koch": details(1962, 4, 12),
            "person:chase-koch": details(1977, 6, 15), "person:jacqueline-mars": details(1939, 10, 10),
            "person:john-mars": details(1935, 10, 15), "person:abigail-johnson": details(1961, 12, 19),
            "person:phil-knight": details(1938, 2, 24), "person:travis-knight": details(1973, 9, 13),
            "person:miriam-adelson": details(1945, 10, 10), "person:thomas-peterffy": details(1944, 9, 30),
            "person:stephen-cohen": details(1956, 6, 11), "person:ray-dalio": details(1949, 8, 8),
            "person:david-tepper": details(1957, 9, 11), "person:george-soros": details(1930, 8, 12),
            "person:donald-bren": details(1932, 5, 11), "person:stephen-ross": details(1940, 5, 10),
            "person:rupert-murdoch": details(1931, 3, 11), "person:lachlan-murdoch": details(1971, 9, 8),
            "person:michael-rubin": details(1972, 7, 21), "person:robert-kraft": details(1941, 6, 5),
            "person:jerry-jones": details(1942, 10, 13), "person:stanley-kroenke": details(1947, 7, 29),
            "person:ann-walton-kroenke": details(1948, 12, 18),
            "person:diane-hendricks": details(1947, 3, 2), "person:tom-gores": details(1964, 7, 31),
            "person:tilman-fertitta": details(1957, 6, 25), "person:robert-f-smith": details(1962, 12, 1),
            "person:henry-kravis": details(1944, 1, 6), "person:george-roberts": details(1943, 10, 11),
            "person:david-rubenstein": details(1949, 8, 11), "person:marc-rowan": details(1962, 8, 19),
            "person:josh-kushner": details(1985, 6, 12), "person:vlad-tenev": details(1987, 2, 13)
        ]
        values["person:edward-johnson-iii"] = DossierPersonDetails(
            birthDate: .init(year: 1930, month: 6, day: 29),
            ageReferenceDate: .init(year: 2022, month: 3, day: 23)
        )
        values["person:sheldon-adelson"] = DossierPersonDetails(
            birthDate: .init(year: 1933, month: 8, day: 4),
            ageReferenceDate: .init(year: 2021, month: 1, day: 11)
        )
        values["person:jim-simons"] = DossierPersonDetails(
            birthDate: .init(year: 1938, month: 4, day: 25),
            ageReferenceDate: .init(year: 2024, month: 5, day: 10)
        )
        values["person:sam-zell"] = DossierPersonDetails(
            birthDate: .init(year: 1941, month: 9, day: 28),
            ageReferenceDate: .init(year: 2023, month: 5, day: 18)
        )
        values["person:paul-allen"] = DossierPersonDetails(
            birthDate: .init(year: 1953, month: 1, day: 21),
            ageReferenceDate: .init(year: 2018, month: 10, day: 15)
        )
        values["person:charlie-munger"] = DossierPersonDetails(
            birthDate: .init(year: 1924, month: 1, day: 1),
            ageReferenceDate: .init(year: 2023, month: 11, day: 28)
        )
        values["person:sam-walton"] = DossierPersonDetails(
            birthDate: .init(year: 1918, month: 3, day: 29),
            ageReferenceDate: .init(year: 1992, month: 4, day: 5)
        )
        values["person:henry-ford"] = DossierPersonDetails(
            birthDate: .init(year: 1863, month: 7, day: 30),
            ageReferenceDate: .init(year: 1947, month: 4, day: 7)
        )
        values["person:alfred-sloan"] = DossierPersonDetails(
            birthDate: .init(year: 1875, month: 5, day: 23),
            ageReferenceDate: .init(year: 1966, month: 2, day: 17)
        )
        values["person:gordon-moore"] = DossierPersonDetails(
            birthDate: .init(year: 1929, month: 1, day: 3),
            ageReferenceDate: .init(year: 2023, month: 3, day: 24)
        )
        values["person:robert-noyce"] = DossierPersonDetails(
            birthDate: .init(year: 1927, month: 12, day: 12),
            ageReferenceDate: .init(year: 1990, month: 6, day: 3)
        )
        values["person:andy-grove"] = DossierPersonDetails(
            birthDate: .init(year: 1936, month: 9, day: 2),
            ageReferenceDate: .init(year: 2016, month: 3, day: 21)
        )
        values["person:steve-jobs"] = DossierPersonDetails(
            birthDate: .init(year: 1955, month: 2, day: 24),
            ageReferenceDate: .init(year: 2011, month: 10, day: 5)
        )
        values["person:susan-wojcicki"] = DossierPersonDetails(
            birthDate: .init(year: 1968, month: 7, day: 5),
            ageReferenceDate: .init(year: 2024, month: 8, day: 9)
        )
        for person in AmericanBillionairesCatalog.current.people {
            guard
                let birthDate = person.birthDate,
                let parsed = parseBirthDate(birthDate)
            else { continue }
            values[person.id] = DossierPersonDetails(birthDate: parsed, ageReferenceDate: nil)
        }
        return values
    }()

    static func parseBirthDate(_ value: String) -> DossierBirthDate? {
        let components = value.split(separator: "-").compactMap { Int($0) }
        guard let year = components.first else { return nil }
        return DossierBirthDate(
            year: year,
            month: components.count > 1 ? components[1] : nil,
            day: components.count > 2 ? components[2] : nil
        )
    }

    static let organizationActivity: [String: String] = [
        "organization:tesla": "Электромобили, энергетика и программное обеспечение",
        "organization:spacex": "Космические технологии и запуски",
        "organization:openai": "Исследования и продукты в области искусственного интеллекта",
        "organization:paypal": "Цифровые платежи",
        "organization:google": "Интернет-сервисы, реклама и технологии",
        "organization:alphabet": "Холдинговая технологическая компания",
        "organization:meta": "Социальные платформы и технологии",
        "organization:microsoft": "Программное обеспечение и облачные сервисы",
        "organization:amazon": "Электронная коммерция и облачные сервисы",
        "organization:nvidia": "Вычислительные платформы и полупроводники",
        "organization:apple": "Потребительская электроника и программное обеспечение",
        "organization:linkedin": "Профессиональная социальная сеть",
        "organization:stripe": "Платёжная инфраструктура",
        "organization:yc": "Акселератор технологических компаний",
        "organization:world-bank": "Международный институт развития",
        "organization:treasury": "Государственное управление финансами",
        "organization:zip2": "Онлайн-каталоги, карты и городские медиасервисы",
        "organization:neuralink": "Нейротехнологии и интерфейсы мозг—компьютер",
        "organization:xai": "Разработка моделей и продуктов искусственного интеллекта",
        "organization:x": "Социальная сеть и цифровая медиаплатформа",
        "organization:boring": "Транспортные тоннели и инфраструктурное строительство",
        "organization:kitchen": "Ресторанный бизнес и локальные продовольственные системы",
        "organization:big-green": "Некоммерческие образовательные программы о питании",
        "organization:square-roots": "Городские фермы и агротехнологии",
        "organization:redwood": "Переработка аккумуляторов и производство материалов для батарей",
        "organization:nuvomedia": "Электронные книги и портативные устройства чтения",
        "organization:inevit": "Инженерные решения для электротранспорта",
        "organization:wrightspeed": "Электрические силовые установки для коммерческого транспорта",
        "organization:aerospace": "Исследования и инженерная поддержка космических программ",
        "organization:microcosm": "Ракетные двигатели и малые космические системы",
        "organization:loopt": "Мобильные сервисы геолокации",
        "organization:reddit": "Социальная платформа тематических сообществ",
        "organization:ssi": "Исследования безопасного сверхинтеллекта",
        "organization:sullivan": "Корпоративное право и юридический консалтинг",
        "organization:credit-suisse": "Банковские и инвестиционные услуги",
        "organization:palantir": "Платформы анализа данных для бизнеса и государства",
        "organization:founders-fund": "Венчурные инвестиции в технологические компании",
        "organization:netmeridian": "Инструменты автоматизированного маркетинга",
        "organization:slide": "Социальные приложения и цифровой контент",
        "organization:affirm": "Потребительское кредитование и BNPL-платежи",
        "organization:socialnet": "Социальная сеть знакомств и поиска единомышленников",
        "organization:greylock": "Венчурные инвестиции в программные компании",
        "organization:fujitsu": "Корпоративные ИТ-системы и электроника",
        "organization:sun": "Серверы, рабочие станции и корпоративное ПО",
        "organization:novell": "Сетевое и инфраструктурное программное обеспечение",
        "organization:applied": "Оборудование для производства полупроводников",
        "organization:mckinsey": "Управленческий консалтинг",
        "organization:intel": "Проектирование и производство полупроводников",
        "organization:youtube": "Видеохостинг и цифровая медиаплатформа",
        "organization:bain": "Управленческий консалтинг",
        "organization:asana": "Программное обеспечение для управления командной работой",
        "organization:pg": "Потребительские товары и товары повседневного спроса",
        "organization:blue-origin": "Ракетно-космические системы и суборбитальные полёты",
        "organization:de-shaw": "Количественные инвестиции и управление активами",
        "organization:fitel": "Телекоммуникационные финансовые сети",
        "organization:bankers-trust": "Инвестиционно-банковские услуги",
        "organization:lsi": "Полупроводники и интегральные схемы",
        "organization:atari": "Аркадные автоматы, игровые консоли и видеоигры",
        "organization:next": "Рабочие станции и объектно-ориентированные операционные системы",
        "organization:pixar": "Компьютерная анимация и кинопроизводство",
        "organization:ibm": "Корпоративные вычислительные системы и консалтинг",
        "organization:compaq": "Персональные компьютеры и серверы",
        "organization:ampex": "Магнитная запись и видеотехнологии",
        "organization:oracle": "Корпоративные базы данных и облачные сервисы",
        "organization:salesforce": "CRM-платформа и облачные бизнес-приложения",
        "organization:auctomatic": "Инструменты для продавцов на онлайн-маркетплейсах",
        "organization:twitter": "Социальная сеть коротких публичных сообщений",
        "organization:block": "Финансовые технологии и платежные сервисы",
        "organization:snap": "Камера, визуальные коммуникации и социальные сервисы",
        "organization:airbnb": "Маркетплейс краткосрочной аренды жилья и путешествий",
        "organization:scour": "Поиск мультимедиа и обмен файлами",
        "organization:red-swoosh": "P2P-доставка цифрового контента",
        "organization:uber": "Платформа мобильности, доставки и логистики",
        "organization:allen-company": "Инвестиционный банк и медиаконсалтинг",
        "organization:iac": "Интернет-холдинг потребительских сервисов",
        "organization:expedia": "Онлайн-сервисы бронирования путешествий",
        "organization:honeywell": "Промышленная автоматизация, аэрокосмические и инженерные системы",
        "organization:vulcan": "Инвестиции, филантропия, медиа и недвижимость",
        "organization:aws": "Облачная инфраструктура и платформенные сервисы",
        "organization:yield-giving": "Филантропические гранты и распределение капитала",
        "organization:xerox": "Печать, копировальная техника и корпоративные документы",
        "organization:starbucks": "Кофейни, потребительский ритейл и брендированные напитки",
        "organization:pure-software": "Инструменты разработки и отладки программного обеспечения",
        "organization:netflix": "Стриминг, производство контента и подписочные медиа",
        "organization:first-boston": "Инвестиционно-банковские услуги и рынки капитала",
        "organization:blackrock": "Управление активами, ETF и инвестиционная инфраструктура",
        "organization:salomon-brothers": "Инвестиционный банк и торговля ценными бумагами",
        "organization:bloomberg": "Финансовые данные, терминалы и деловая медиаинформация",
        "organization:lehman-brothers": "Инвестиционный банк и рынки капитала",
        "organization:blackstone": "Альтернативные инвестиции и private equity",
        "organization:citadel": "Хедж-фонд и управление капиталом",
        "organization:citadel-securities": "Маркет-мейкинг и электронная торговая инфраструктура",
        "organization:american-express": "Платёжные карты, кредитные продукты и travel-сервисы",
        "organization:citigroup": "Банковские услуги, рынки капитала и глобальные финансы",
        "organization:jpmorgan": "Банковские услуги, инвестиционный банк и управление активами",
        "organization:buffett-partnership": "Инвестиционное партнёрство",
        "organization:berkshire": "Инвестиционный холдинг и страховой конгломерат",
        "organization:munger-tolles": "Юридическая фирма и корпоративное право",
        "organization:jc-penney": "Универмаги и розничная торговля",
        "organization:walmart": "Массовый ритейл, логистика и электронная коммерция",
        "organization:first-commerce": "Финансовые услуги и региональный банкинг",
        "organization:crystal-bridges": "Художественный музей и культурная институция",
        "organization:conner-winters": "Юридические услуги и коммерческое право",
        "organization:dell": "Компьютеры, серверы, хранение данных и корпоративная инфраструктура",
        "organization:msd-capital": "Инвестиционный офис и управление семейным капиталом",
        "organization:micro-solutions": "Системная интеграция и компьютерные решения",
        "organization:broadcast-com": "Интернет-аудио и потоковые медиа",
        "organization:dallas-mavericks": "Профессиональный баскетбольный клуб и спортивный бизнес",
        "organization:ncsa": "Исследовательский центр суперкомпьютеров и интернет-технологий",
        "organization:netscape": "Веб-браузеры и ранняя интернет-инфраструктура",
        "organization:a16z": "Венчурные инвестиции в технологические компании",
        "organization:loudcloud": "Облачная инфраструктура и корпоративное ПО",
        "organization:kleiner-perkins": "Венчурные инвестиции в технологические и биотехнологические компании",
        "organization:khosla-ventures": "Венчурные инвестиции в deep tech, климат и программные компании",
        "organization:morgan-stanley": "Инвестиционный банк, брокерские услуги и управление капиталом",
        "organization:bond-capital": "Венчурные инвестиции в growth-stage компании",
        "organization:gm": "Автомобили, промышленное производство и мобильность",
        "organization:edison-illuminating": "Электроснабжение и городская энергетическая инфраструктура",
        "organization:ford": "Автомобили и массовое промышленное производство",
        "organization:hyatt-roller-bearing": "Шарикоподшипники и промышленное производство",
        "organization:fairchild": "Полупроводники и интегральные схемы",
        "organization:texas-instruments": "Полупроводники, аналоговые чипы и встроенные системы",
        "organization:amd": "Процессоры, графические ускорители и вычислительные платформы",
        "organization:vmware": "Виртуализация, облачная инфраструктура и корпоративное ПО",
        "organization:tsmc": "Контрактное производство полупроводников",
        "organization:donaldson-lufkin": "Инвестиционный банк и брокерские услуги",
        "organization:veon": "Телекоммуникационные сети и цифровые сервисы",
        "organization:tinder": "Мобильные знакомства и потребительские социальные приложения",
        "organization:bumble": "Платформа знакомств и социальных коммуникаций",
        "organization:deloitte": "Консалтинг, аудит и профессиональные услуги",
        "organization:coinbase": "Криптовалютная биржа и блокчейн-инфраструктура",
        "organization:goldman-sachs": "Инвестиционный банк и финансовые рынки",
        "organization:paradigm": "Инвестиции в криптоинфраструктуру и Web3",
        "organization:box": "Облачное хранение, совместная работа и управление контентом",
        "organization:bit9": "Кибербезопасность и защита конечных точек",
        "organization:dropbox": "Облачное хранение файлов и совместная работа",
        "organization:gates-foundation": "Глобальная филантропия, здравоохранение и образование",
        "organization:pivotal-ventures": "Инвестиции и инициативы для расширения возможностей женщин и семей",
        "organization:emerson-collective": "Импакт-инвестиции, медиа, образование и иммиграционные инициативы",
        "organization:passport-capital": "Инвестиционное управление и хедж-фонд",
        "organization:23andme": "Потребительская генетика и биотехнологические данные",
        "organization:yahoo": "Интернет-портал, поиск, почта и цифровые медиа",
        "organization:whatsapp": "Мессенджер и мобильные коммуникации",
        "organization:signal-foundation": "Некоммерческая инфраструктура приватных коммуникаций",
        "organization:perseptive-biosystems": "Биотехнологическое оборудование и аналитические системы",
        "organization:flagship-pioneering": "Создание и финансирование биотехнологических компаний",
        "organization:moderna": "mRNA-терапии, вакцины и биотехнологии",
        "organization:arvest": "Региональный банкинг и финансовые услуги",
        "organization:builders-vision": "Импакт-инвестиции, климат и устойчивые продовольственные системы",
        "organization:arthur-d-little": "Управленческий и технологический консалтинг",
        "organization:koch-industries": "Промышленный конгломерат, энергетика, химия и сырьевые цепочки",
        "organization:julia-koch-foundation": "Семейная филантропия и грантовые программы",
        "organization:stand-together": "Филантропическая сеть и общественные инициативы",
        "organization:mars-inc": "Кондитерские изделия, корма для животных и семейный consumer goods-бизнес",
        "organization:fidelity": "Управление активами, брокерские и пенсионные сервисы",
        "organization:blue-ribbon-sports": "Дистрибуция спортивной обуви и ранний предшественник Nike",
        "organization:nike": "Спортивная одежда, обувь и глобальный потребительский бренд",
        "organization:laika": "Анимационная студия и производство stop-motion фильмов",
        "organization:adelson-clinic": "Медицинские программы лечения зависимостей",
        "organization:comdex": "Выставки компьютерной индустрии и технологические конференции",
        "organization:las-vegas-sands": "Казино-курорты, гостиницы и развлекательная недвижимость",
        "organization:interactive-brokers": "Электронный брокеридж и торговая инфраструктура",
        "organization:gruenthal": "Брокерские услуги и торговля ценными бумагами",
        "organization:sac-capital": "Хедж-фонд и активный трейдинг",
        "organization:point72": "Управление активами и multi-strategy инвестиции",
        "organization:bridgewater": "Макро-хедж-фонд и институциональное управление капиталом",
        "organization:appaloosa": "Хедж-фонд и distressed investing",
        "organization:soros-fund": "Инвестиционное управление и глобальные рынки",
        "organization:open-society": "Филантропия, гражданские институты и правовые инициативы",
        "organization:stony-brook": "Публичный исследовательский университет и математическая школа",
        "organization:renaissance": "Количественные инвестиции и математические торговые модели",
        "organization:bren-company": "Девелопмент и инвестиции в недвижимость",
        "organization:irvine-company": "Девелопмент, офисная, жилая и торговая недвижимость",
        "organization:related-companies": "Девелопмент, городская недвижимость и mixed-use проекты",
        "organization:equity-group": "Инвестиции в недвижимость и частные компании",
        "organization:news-corp": "Медиа, издательский бизнес и новостные активы",
        "organization:fox": "Телевизионные сети, новости и спортивные медиа",
        "organization:gsi-commerce": "Электронная коммерция и инфраструктура онлайн-ритейла",
        "organization:fanatics": "Спортивный мерчандайзинг, коллекционные товары и betting-сервисы",
        "organization:rand-whitney": "Упаковка, бумага и промышленное производство",
        "organization:kraft-group": "Холдинг в упаковке, спорте, недвижимости и private equity",
        "organization:new-england-patriots": "Профессиональный футбольный клуб NFL",
        "organization:jones-oil-land": "Энергетика, нефть и земельные активы",
        "organization:dallas-cowboys": "Профессиональный футбольный клуб NFL и спортивная медиаинфраструктура",
        "organization:kroenke-group": "Девелопмент, торговая недвижимость и спортивные активы",
        "organization:arsenal": "Профессиональный футбольный клуб Premier League",
        "organization:la-rams": "Профессиональный футбольный клуб NFL",
        "organization:denver-nuggets": "Профессиональный баскетбольный клуб NBA",
        "organization:abc-supply": "Оптовая дистрибуция кровельных и строительных материалов",
        "organization:platinum-equity": "Private equity и операционные преобразования компаний",
        "organization:detroit-pistons": "Профессиональный баскетбольный клуб NBA",
        "organization:landrys": "Рестораны, казино, гостиницы и развлекательный холдинг",
        "organization:houston-rockets": "Профессиональный баскетбольный клуб NBA",
        "organization:vista-equity": "Private equity в enterprise software",
        "organization:bear-stearns": "Инвестиционный банк и рынки капитала",
        "organization:kkr": "Private equity, кредитные стратегии и альтернативные инвестиции",
        "organization:white-house": "Федеральная исполнительная администрация США",
        "organization:carlyle": "Альтернативные инвестиции, private equity и real assets",
        "organization:drexel-burnham": "Инвестиционный банк и рынок high-yield облигаций",
        "organization:apollo-global": "Альтернативные инвестиции, private equity и private credit",
        "organization:thrive-capital": "Венчурные инвестиции в интернет- и software-компании",
        "organization:oscar-health": "Технологичная медицинская страховка",
        "organization:celeris": "Финансовые технологии и торговое ПО",
        "organization:robinhood": "Розничный брокеридж, финтех и потребительские инвестиции"
    ]

    static let foundationYears: [String: Int] = [
        "organization:zip2": 1995, "organization:tesla": 2003, "organization:spacex": 2002,
        "organization:openai": 2015, "organization:paypal": 1998, "organization:google": 1998,
        "organization:alphabet": 2015, "organization:meta": 2004, "organization:microsoft": 1975,
        "organization:amazon": 1994, "organization:nvidia": 1993, "organization:linkedin": 2002,
        "organization:stripe": 2010, "organization:neuralink": 2016, "organization:xai": 2023,
        "organization:apple": 1976, "organization:next": 1985, "organization:pixar": 1979,
        "organization:oracle": 1977, "organization:salesforce": 1999, "organization:twitter": 2006,
        "organization:block": 2009, "organization:snap": 2011, "organization:airbnb": 2008,
        "organization:uber": 2009, "organization:expedia": 1996, "organization:starbucks": 1971,
        "organization:netflix": 1997, "organization:blackrock": 1988, "organization:bloomberg": 1981,
        "organization:blackstone": 1985, "organization:citadel": 1990,
        "organization:citadel-securities": 2002, "organization:berkshire": 1839,
        "organization:walmart": 1962, "organization:dell": 1984, "organization:netscape": 1994,
        "organization:a16z": 2009, "organization:gm": 1908, "organization:ford": 1903,
        "organization:fairchild": 1957, "organization:intel": 1968, "organization:amd": 1969,
        "organization:vmware": 1998, "organization:tsmc": 1987, "organization:coinbase": 2012,
        "organization:box": 2005, "organization:dropbox": 2007, "organization:moderna": 2010,
        "organization:yahoo": 1994, "organization:whatsapp": 2009, "organization:bumble": 2014,
        "organization:23andme": 2006, "organization:koch-industries": 1940,
        "organization:mars-inc": 1911, "organization:fidelity": 1946, "organization:nike": 1971,
        "organization:las-vegas-sands": 1988, "organization:interactive-brokers": 1978,
        "organization:point72": 2014, "organization:bridgewater": 1975,
        "organization:renaissance": 1982, "organization:irvine-company": 1864,
        "organization:related-companies": 1972, "organization:news-corp": 1980,
        "organization:fox": 2019, "organization:fanatics": 1995, "organization:kraft-group": 1998,
        "organization:new-england-patriots": 1959, "organization:dallas-cowboys": 1960,
        "organization:arsenal": 1886, "organization:la-rams": 1936,
        "organization:denver-nuggets": 1967, "organization:abc-supply": 1982,
        "organization:platinum-equity": 1995, "organization:detroit-pistons": 1941,
        "organization:landrys": 1980, "organization:houston-rockets": 1967,
        "organization:vista-equity": 2000, "organization:kkr": 1976,
        "organization:carlyle": 1987, "organization:apollo-global": 1990,
        "organization:thrive-capital": 2009, "organization:oscar-health": 2012,
        "organization:robinhood": 2013, "organization:builders-vision": 2021
    ]

    static let universityMetadata: [String: (type: String, location: String, operatingPeriod: String)] = [
        "university:auburn": ("Публичный исследовательский университет", "Оберн, Алабама, США", "1856"),
        "university:auckland": ("Публичный исследовательский университет", "Окленд, Новая Зеландия", "1883"),
        "university:berkeley": ("Публичный исследовательский университет", "Беркли, Калифорния, США", "1868"),
        "university:booth": ("Бизнес-школа", "Чикаго, Иллинойс, США", "1898"),
        "university:brown": ("Частный исследовательский университет", "Провиденс, Род-Айленд, США", "1764"),
        "university:chicago": ("Частный исследовательский университет", "Чикаго, Иллинойс, США", "1890"),
        "university:duke": ("Частный исследовательский университет", "Дарем, Северная Каролина, США", "1838"),
        "university:harvard": ("Частный исследовательский университет", "Кембридж, Массачусетс, США", "1636"),
        "university:iit": ("Публичный технический институт", "Кхарагпур, Индия", "1951"),
        "university:manipal": ("Частный технический институт", "Манипал, Индия", "1957"),
        "university:maryland": ("Публичный исследовательский университет", "Колледж-Парк, Мэриленд, США", "1856"),
        "university:michigan": ("Публичный исследовательский университет", "Анн-Арбор, Мичиган, США", "1817"),
        "university:mit": ("Частный исследовательский университет", "Кембридж, Массачусетс, США", "1861"),
        "university:mst": ("Публичный технический университет", "Ролла, Миссури, США", "1870"),
        "university:northwestern": ("Частный исследовательский университет", "Эванстон, Иллинойс, США", "1851"),
        "university:nyu": ("Частный исследовательский университет", "Нью-Йорк, США", "1831"),
        "university:oregon-state": ("Публичный исследовательский университет", "Корваллис, Орегон, США", "1868"),
        "university:oxford": ("Исследовательский университет", "Оксфорд, Великобритания", "около 1096"),
        "university:princeton": ("Частный исследовательский университет", "Принстон, Нью-Джерси, США", "1746"),
        "university:queens": ("Публичный исследовательский университет", "Кингстон, Онтарио, Канада", "1841"),
        "university:reed": ("Частный колледж свободных искусств", "Портленд, Орегон, США", "1908"),
        "university:risd": ("Частный колледж искусства и дизайна", "Провиденс, Род-Айленд, США", "1877"),
        "university:stanford": ("Частный исследовательский университет", "Стэнфорд, Калифорния, США", "1885"),
        "university:toronto": ("Публичный исследовательский университет", "Торонто, Канада", "1827"),
        "university:ucla": ("Публичный исследовательский университет", "Лос-Анджелес, Калифорния, США", "1919"),
        "university:ucsc": ("Публичный исследовательский университет", "Санта-Круз, Калифорния, США", "1965"),
        "university:uiuc": ("Публичный исследовательский университет", "Эрбана-Шампейн, Иллинойс, США", "1867"),
        "university:upenn": ("Частный исследовательский университет", "Филадельфия, Пенсильвания, США", "1740"),
        "university:usc": ("Частный исследовательский университет", "Лос-Анджелес, Калифорния, США", "1880"),
        "university:uwm": ("Публичный исследовательский университет", "Милуоки, Висконсин, США", "1956"),
        "university:wharton": ("Бизнес-школа", "Филадельфия, Пенсильвания, США", "1881"),
        "university:washington-state": ("Публичный исследовательский университет", "Пулман, Вашингтон, США", "1890"),
        "university:northern-michigan": ("Публичный университет", "Маркетт, Мичиган, США", "1899"),
        "university:bowdoin": ("Частный колледж свободных искусств", "Брансуик, Мэн, США", "1794"),
        "university:hamilton": ("Частный колледж свободных искусств", "Клинтон, Нью-Йорк, США", "1793"),
        "university:johns-hopkins": ("Частный исследовательский университет", "Балтимор, Мэриленд, США", "1876"),
        "university:yale": ("Частный исследовательский университет", "Нью-Хейвен, Коннектикут, США", "1701"),
        "university:tufts": ("Частный исследовательский университет", "Медфорд, Массачусетс, США", "1852"),
        "university:nebraska": ("Публичный исследовательский университет", "Линкольн, Небраска, США", "1869"),
        "university:columbia": ("Частный исследовательский университет", "Нью-Йорк, США", "1754"),
        "university:missouri": ("Публичный исследовательский университет", "Колумбия, Миссури, США", "1839"),
        "university:trinity": ("Частный университет", "Сан-Антонио, Техас, США", "1869"),
        "university:wooster": ("Частный колледж свободных искусств", "Вустер, Огайо, США", "1866"),
        "university:ut-austin": ("Публичный исследовательский университет", "Остин, Техас, США", "1883"),
        "university:indiana": ("Публичный исследовательский университет", "Блумингтон, Индиана, США", "1820"),
        "university:iit-delhi": ("Публичный технический институт", "Дели, Индия", "1961"),
        "university:cmu": ("Частный исследовательский университет", "Питтсбург, Пенсильвания, США", "1900"),
        "university:rice": ("Частный исследовательский университет", "Хьюстон, Техас, США", "1912"),
        "university:depauw": ("Частный колледж свободных искусств", "Гринкасл, Индиана, США", "1837"),
        "university:cornell": ("Частный исследовательский университет", "Итака, Нью-Йорк, США", "1865"),
        "university:kettering": ("Частный инженерный университет", "Флинт, Мичиган, США", "1919"),
        "university:detroit-business": ("Профессиональный бизнес-институт", "Детройт, Мичиган, США", "1850"),
        "university:caltech": ("Частный исследовательский университет", "Пасадина, Калифорния, США", "1891"),
        "university:grinnell": ("Частный колледж свободных искусств", "Гриннелл, Айова, США", "1846"),
        "university:ccny": ("Публичный колледж", "Нью-Йорк, США", "1847"),
        "university:santa-clara": ("Частный университет", "Санта-Клара, Калифорния, США", "1851"),
        "university:upenn-law": ("Юридическая школа", "Филадельфия, Пенсильвания, США", "1850"),
        "university:vermont": ("Публичный исследовательский университет", "Берлингтон, Вермонт, США", "1791"),
        "university:polytechnic-nyu": ("Инженерная школа", "Бруклин, Нью-Йорк, США", "1854"),
        "university:smu": ("Частный исследовательский университет", "Даллас, Техас, США", "1911"),
        "university:sjsu": ("Публичный университет", "Сан-Хосе, Калифорния, США", "1857"),
        "university:mcgill": ("Публичный исследовательский университет", "Монреаль, Канада", "1821"),
        "university:arkansas": ("Публичный исследовательский университет", "Фейетвилл, Арканзас, США", "1871"),
        "university:colorado-college": ("Частный колледж свободных искусств", "Колорадо-Спрингс, Колорадо, США", "1874"),
        "university:central-arkansas": ("Публичный университет", "Конвей, Арканзас, США", "1907"),
        "university:texas-am": ("Публичный исследовательский университет", "Колледж-Стейшен, Техас, США", "1876"),
        "university:bryn-mawr": ("Частный женский колледж свободных искусств", "Брин-Мар, Пенсильвания, США", "1885"),
        "university:hobart-william-smith": ("Частные колледжи свободных искусств", "Женева, Нью-Йорк, США", "1822"),
        "university:oregon": ("Публичный исследовательский университет", "Юджин, Орегон, США", "1876"),
        "university:portland-state": ("Публичный исследовательский университет", "Портленд, Орегон, США", "1946"),
        "university:hebrew-university": ("Публичный исследовательский университет", "Иерусалим, Израиль", "1918"),
        "university:clarkson": ("Частный технологический университет", "Потсдам, Нью-Йорк, США", "1896"),
        "university:long-island": ("Частный университет", "Бруквилл, Нью-Йорк, США", "1926"),
        "university:pittsburgh": ("Публичный исследовательский университет", "Питтсбург, Пенсильвания, США", "1787"),
        "university:lse": ("Публичный исследовательский университет", "Лондон, Великобритания", "1895"),
        "university:washington": ("Публичный исследовательский университет", "Сиэтл, Вашингтон, США", "1861"),
        "university:wayne-state-law": ("Юридическая школа", "Детройт, Мичиган, США", "1927"),
        "university:villanova": ("Частный католический университет", "Вилланова, Пенсильвания, США", "1842"),
        "university:lincoln": ("Публичный университет", "Джефферсон-Сити, Миссури, США", "1866"),
        "university:osseo-fairchild": ("Средняя школа", "Оссео, Висконсин, США", "—"),
        "university:michigan-state": ("Публичный исследовательский университет", "Ист-Лансинг, Мичиган, США", "1855"),
        "university:claremont-mckenna": ("Частный колледж свободных искусств", "Клермонт, Калифорния, США", "1946"),
        "university:uc-hastings": ("Юридический колледж", "Сан-Франциско, Калифорния, США", "1878"),
        "university:uchicago-law": ("Юридическая школа", "Чикаго, Иллинойс, США", "1902"),
        "university:houston": ("Публичный исследовательский университет", "Хьюстон, Техас, США", "1927")
    ]
}

private extension Array where Element == DossierTimelineEvent {
    func appendingFoundationEvent(
        for organizationID: GraphNode.ID,
        year: Int?
    ) -> [DossierTimelineEvent] {
        guard let year else { return self }
        return self + [
            DossierTimelineEvent(
                id: "timeline:\(organizationID):founded",
                year: year,
                title: "Основание",
                description: "Компания появляется как отдельная организация в графе.",
                linkedEntityID: organizationID,
                source: nil
            )
        ]
    }
}

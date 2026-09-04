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
                    source: fixtureSource
                )
            }
            return (node.id, dossier(for: node, links: links))
        })
    }
}

private extension DenseGraphDossierFactory {
    static let fixtureSource = DossierSource(
        id: "source:dense-design-fixture",
        publisher: "Код миллиарда",
        title: "Локальный набор для проверки дизайна; требуется публикационный аудит",
        url: nil,
        status: .requiresAudit
    )

    static let forbesSource = DossierSource(
        id: "source:forbes-real-time",
        publisher: "Forbes",
        title: "Real-Time Billionaires",
        url: URL(string: "https://www.forbes.com/real-time-billionaires/"),
        status: .requiresAudit
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
        let current = work.filter(\.isCurrent)
        let description: String
        if let first = work.min(by: { $0.startYear < $1.startYear }),
           let latest = work.max(by: { $0.startYear < $1.startYear }) {
            description = "Путь от роли «\(first.role)» в \(first.name) до работы с \(latest.name). "
                + "Хронология показывает зафиксированные связи без причинных выводов."
        } else {
            description = "Датированный профиль связей человека в текущей версии графа."
        }

        let facts = [
            DossierFact(
                id: "\(node.id):status",
                label: "Сейчас связан",
                value: current.isEmpty ? "Нет подтверждённых текущих ролей" : current.map(\.name).joined(separator: ", "),
                source: fixtureSource
            ),
            DossierFact(
                id: "\(node.id):education",
                label: "Образование",
                value: education.isEmpty ? "Не указано" : education.map(\.name).joined(separator: ", "),
                source: fixtureSource
            )
        ]
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: description,
            lastReviewedOn: "04.09.2026",
            facts: facts,
            links: work,
            timeline: timeline(from: links),
            wealth: node.id == "person:elon-musk" ? elonWealth : nil
        )
    }

    static func organizationDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        let founders = links.filter {
            let role = $0.role.lowercased()
            return role.contains("основател") || role.contains("соосновател")
        }
        let activity = organizationActivity[node.id] ?? "Компания или профессиональная организация"
        var facts = [
            DossierFact(id: "\(node.id):activity", label: "Вид деятельности", value: activity, source: fixtureSource)
        ]
        if let year = foundationYears[node.id] {
            facts.append(DossierFact(id: "\(node.id):founded", label: "Основана", value: String(year), source: fixtureSource))
        }
        facts.append(
            DossierFact(
                id: "\(node.id):founders",
                label: "Основатели в графе",
                value: founders.isEmpty ? "Не представлены" : founders.map(\.name).joined(separator: ", "),
                source: fixtureSource
            )
        )
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: "\(node.name) — \(activity.lowercased()). "
                + "В досье показаны люди и роли из текущей evidence network.",
            lastReviewedOn: "04.09.2026",
            facts: facts,
            links: links,
            timeline: timeline(from: links),
            wealth: nil
        )
    }

    static func universityDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        let metadata = universityMetadata[node.id] ?? ("Университет", "Местоположение требует проверки", "Требует проверки")
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: "\(node.name) — образовательная организация. Здесь собраны программы и периоды обучения людей из текущего графа.",
            lastReviewedOn: "04.09.2026",
            facts: [
                DossierFact(id: "\(node.id):type", label: "Тип", value: metadata.0, source: fixtureSource),
                DossierFact(id: "\(node.id):location", label: "Местоположение", value: metadata.1, source: fixtureSource),
                DossierFact(id: "\(node.id):founded", label: "Основан", value: metadata.2, source: fixtureSource),
                DossierFact(id: "\(node.id):people", label: "Людей в графе", value: String(links.count), source: fixtureSource)
            ],
            links: links,
            timeline: timeline(from: links),
            wealth: nil
        )
    }

    static func genericDossier(for node: GraphNode, links: [DossierEntityLink]) -> EntityDossier {
        EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: node.summary.isEmpty ? "Сущность текущего доказательного графа." : node.summary,
            lastReviewedOn: "04.09.2026",
            facts: [],
            links: links,
            timeline: timeline(from: links),
            wealth: nil
        )
    }

    static func timeline(from links: [DossierEntityLink]) -> [DossierTimelineEvent] {
        links
            .filter { $0.startYear > .zero }
            .sorted { $0.startYear < $1.startYear }
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

    static let elonWealth = DossierWealth(
        amountUSD: 891_900_000_000,
        asOf: "01.09.2026",
        methodology: "Предварительная точечная оценка Forbes из design seed; перед публикацией требуется повторная редакционная проверка.",
        source: forbesSource,
        components: [
            DossierWealthComponent(id: "aggregate", label: "Совокупная оценка", detail: "Декомпозиция капитала пока не опубликована")
        ],
        history: [DossierWealthPoint(id: "2026", year: 2026, amountUSD: 891_900_000_000)]
    )

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
        "organization:treasury": "Государственное управление финансами"
    ]

    static let foundationYears: [String: Int] = [
        "organization:zip2": 1995, "organization:tesla": 2003, "organization:spacex": 2002,
        "organization:openai": 2015, "organization:paypal": 1998, "organization:google": 1998,
        "organization:alphabet": 2015, "organization:meta": 2004, "organization:microsoft": 1975,
        "organization:amazon": 1994, "organization:nvidia": 1993, "organization:linkedin": 2002,
        "organization:stripe": 2010, "organization:neuralink": 2016, "organization:xai": 2023
    ]

    static let universityMetadata: [String: (String, String, String)] = [
        "university:auckland": ("Публичный исследовательский университет", "Окленд, Новая Зеландия", "1883"),
        "university:berkeley": ("Публичный исследовательский университет", "Беркли, Калифорния, США", "1868"),
        "university:booth": ("Бизнес-школа", "Чикаго, Иллинойс, США", "1898"),
        "university:harvard": ("Частный исследовательский университет", "Кембридж, Массачусетс, США", "1636"),
        "university:iit": ("Публичный технический институт", "Кхарагпур, Индия", "1951"),
        "university:manipal": ("Частный технический институт", "Манипал, Индия", "1957"),
        "university:maryland": ("Публичный исследовательский университет", "Колледж-Парк, Мэриленд, США", "1856"),
        "university:michigan": ("Публичный исследовательский университет", "Анн-Арбор, Мичиган, США", "1817"),
        "university:mit": ("Частный исследовательский университет", "Кембридж, Массачусетс, США", "1861"),
        "university:northwestern": ("Частный исследовательский университет", "Эванстон, Иллинойс, США", "1851"),
        "university:oregon-state": ("Публичный исследовательский университет", "Корваллис, Орегон, США", "1868"),
        "university:oxford": ("Исследовательский университет", "Оксфорд, Великобритания", "около 1096"),
        "university:princeton": ("Частный исследовательский университет", "Принстон, Нью-Джерси, США", "1746"),
        "university:queens": ("Публичный исследовательский университет", "Кингстон, Онтарио, Канада", "1841"),
        "university:stanford": ("Частный исследовательский университет", "Стэнфорд, Калифорния, США", "1885"),
        "university:toronto": ("Публичный исследовательский университет", "Торонто, Канада", "1827"),
        "university:ucla": ("Публичный исследовательский университет", "Лос-Анджелес, Калифорния, США", "1919"),
        "university:ucsc": ("Публичный исследовательский университет", "Санта-Круз, Калифорния, США", "1965"),
        "university:uiuc": ("Публичный исследовательский университет", "Эрбана-Шампейн, Иллинойс, США", "1867"),
        "university:upenn": ("Частный исследовательский университет", "Филадельфия, Пенсильвания, США", "1740"),
        "university:uwm": ("Публичный исследовательский университет", "Милуоки, Висконсин, США", "1956"),
        "university:wharton": ("Бизнес-школа", "Филадельфия, Пенсильвания, США", "1881")
    ]
}

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
                    source: nil
                )
            }
            return (node.id, dossier(for: node, links: links))
        })
    }
}

private extension DenseGraphDossierFactory {
    static let forbesSource = DossierSource(
        id: "source:forbes-real-time",
        publisher: "Forbes",
        title: "Real-Time Billionaires",
        url: URL(string: "https://www.forbes.com/real-time-billionaires/")
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
        let current = work.filter(\.isCurrent)
        let description: String
        if let first = work.min(by: { $0.startYear < $1.startYear }),
           let latest = work.max(by: { $0.startYear < $1.startYear }) {
            description = "Путь от роли «\(first.role)» в \(first.name) до работы с \(latest.name). "
                + "Ниже — ключевые этапы карьеры и связанные компании."
        } else {
            description = "Датированный профиль связей человека в текущей версии графа."
        }

        let facts = [
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
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: description,
            operatingPeriod: nil,
            lastReviewedOn: "04.09.2026",
            facts: facts,
            links: work,
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
        let activity = organizationActivity[node.id] ?? "Технологические продукты и сервисы"
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
        return EntityDossier(
            entityID: node.id,
            kind: node.kind,
            description: "\(node.name) — \(activity.lowercased()). Ниже — основатели, руководители и ключевые связи.",
            operatingPeriod: OrganizationDossierHighlights.operatingPeriods[node.id],
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
            location: "США",
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

    static func organizationTimeline(
        for organizationID: GraphNode.ID,
        links: [DossierEntityLink]
    ) -> [DossierTimelineEvent] {
        (timeline(from: links) + (OrganizationDossierHighlights.events[organizationID] ?? []))
            .sorted {
                if $0.year != $1.year { return $0.year < $1.year }
                return $0.id < $1.id
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
            "person:travis-kalanick": 4_000_000_000, "person:dara-khosrowshahi": 250_000_000
        ]
        let forbesIDs: Set<GraphNode.ID> = [
            "person:elon-musk", "person:peter-thiel", "person:reid-hoffman", "person:larry-page",
            "person:sergey-brin", "person:mark-zuckerberg", "person:dustin-moskovitz",
            "person:sheryl-sandberg", "person:bill-gates", "person:steve-ballmer",
            "person:satya-nadella", "person:jeff-bezos", "person:jensen-huang",
            "person:larry-ellison", "person:marc-benioff", "person:patrick-collison",
            "person:john-collison", "person:jack-dorsey", "person:evan-spiegel",
            "person:bobby-murphy", "person:brian-chesky", "person:travis-kalanick"
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
            "person:travis-kalanick": details(1976, 8, 6), "person:dara-khosrowshahi": details(1969, 5, 28)
        ]
        values["person:steve-jobs"] = DossierPersonDetails(
            birthDate: .init(year: 1955, month: 2, day: 24),
            ageReferenceDate: .init(year: 2011, month: 10, day: 5)
        )
        values["person:susan-wojcicki"] = DossierPersonDetails(
            birthDate: .init(year: 1968, month: 7, day: 5),
            ageReferenceDate: .init(year: 2024, month: 8, day: 9)
        )
        return values
    }()

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
        "organization:expedia": "Онлайн-сервисы бронирования путешествий"
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
        "organization:uber": 2009, "organization:expedia": 1996
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
        "university:wharton": ("Бизнес-школа", "Филадельфия, Пенсильвания, США", "1881")
    ]
}

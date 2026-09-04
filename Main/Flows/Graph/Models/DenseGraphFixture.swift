enum DenseGraphFixture {
    static let performance: DenseGraphData = makeGraph()
}

// MARK: - Graph construction

private extension DenseGraphFixture {
    static func makeGraph() -> DenseGraphData {
        let personNodes = profiles.map { profile in
            GraphNode(
                id: profile.id,
                kind: .person,
                name: profile.name,
                shortName: shortName(profile.name),
                summary: "",
                position: GraphPoint(x: .zero, y: .zero)
            )
        }
        var entityNodes: [GraphNode.ID: GraphNode] = [:]
        var edges: [DenseGraphEdge] = []

        for profile in profiles {
            for affiliation in profile.affiliations {
                entityNodes[affiliation.entityID] = GraphNode(
                    id: affiliation.entityID,
                    kind: affiliation.entityKind,
                    name: affiliation.entityName,
                    shortName: affiliation.entityName,
                    summary: "",
                    position: GraphPoint(x: .zero, y: .zero)
                )
                edges.append(
                    DenseGraphEdge(
                        id: "edge:\(profile.id)--\(affiliation.entityID)",
                        sourceID: profile.id,
                        targetID: affiliation.entityID,
                        kind: affiliation.edgeKind,
                        period: affiliation.period,
                        detail: affiliation.detail
                    )
                )
            }
        }
        edges.append(
            DenseGraphEdge(
                id: "edge:elon--kimbal-family",
                sourceID: "person:elon-musk",
                targetID: "person:kimbal-musk",
                kind: .family,
                period: "",
                detail: "братья"
            )
        )
        let unpositioned = personNodes + entityNodes.values.sorted { $0.id < $1.id }
        let positions = DenseGraphLayout().layout(nodes: unpositioned, edges: edges, layoutVersion: 1)
        let nodes = unpositioned.map { node in
            GraphNode(
                id: node.id,
                kind: node.kind,
                name: node.name,
                shortName: node.shortName,
                summary: node.summary,
                position: positions[node.id] ?? GraphPoint(x: 5_000, y: 5_000)
            )
        }
        return DenseGraphData(
            nodes: nodes,
            edges: edges,
            dossiers: DenseGraphDossierFactory.make(nodes: nodes, edges: edges)
        )
    }

    static func shortName(_ name: String) -> String {
        let parts = name.split(separator: " ")
        guard let first = parts.first, let last = parts.last else { return name }
        return parts.count > 1 ? "\(first.prefix(1)). \(last)" : name
    }
}

// MARK: - Profiles

private extension DenseGraphFixture {
    static let profiles: [DenseGraphProfile] = [
        DenseGraphProfile(
            id: "person:elon-musk",
            name: "Илон Маск",
            affiliations: [
                .study("queens", "Queen’s University", "1989–1991", "экономика / физика"),
                .study("upenn", "University of Pennsylvania", "1992–1997", "BA, физика / BS, экономика"),
                .study("stanford", "Stanford University", "1995", "PhD, прикладная физика · не окончил"),
                .work("zip2", "Zip2", "1995–1999", "сооснователь"),
                .work("paypal", "PayPal", "1999–2000", "CEO X.com"),
                .work("spacex", "SpaceX", "2002–н.в.", "основатель / CEO"),
                .work("tesla", "Tesla", "2008–н.в.", "CEO"),
                .work("openai", "OpenAI", "2015–2018", "сопредседатель"),
                .work("neuralink", "Neuralink", "2016–н.в.", "сооснователь"),
                .work("boring", "The Boring Company", "2016–н.в.", "основатель"),
                .work("x", "X", "2022–н.в.", "владелец"),
                .work("xai", "xAI", "2023–н.в.", "основатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:kimbal-musk",
            name: "Кимбал Маск",
            affiliations: [
                .study("queens", "Queen’s University", "1991–1995", "BCom, бизнес"),
                .work("zip2", "Zip2", "1995–1999", "сооснователь"),
                .work("kitchen", "The Kitchen", "2004–н.в.", "сооснователь"),
                .work("big-green", "Big Green", "2011–н.в.", "основатель"),
                .work("square-roots", "Square Roots", "2016–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:jb-straubel",
            name: "Джей-Би Страубель",
            affiliations: [
                .study("stanford", "Stanford University", "1994–2000", "BS/MS, энергосистемы"),
                .work("tesla", "Tesla", "2004–2019", "CTO"),
                .work("redwood", "Redwood Materials", "2017–н.в.", "основатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:martin-eberhard",
            name: "Мартин Эберхард",
            affiliations: [
                .study("uiuc", "University of Illinois", "1978–1984", "BS/MS, электротехника"),
                .work("nuvomedia", "NuvoMedia", "1997–2000", "сооснователь"),
                .work("tesla", "Tesla", "2003–2007", "сооснователь / CEO"),
                .work("inevit", "inEVit", "2016–2017", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:marc-tarpenning",
            name: "Марк Тарпеннинг",
            affiliations: [
                .study("berkeley", "UC Berkeley", "1980–1985", "BA, информатика"),
                .work("nuvomedia", "NuvoMedia", "1997–2000", "сооснователь"),
                .work("tesla", "Tesla", "2003–2008", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:ian-wright",
            name: "Иэн Райт",
            affiliations: [
                .study("auckland", "University of Auckland", "1977–1980", "BE, электротехника"),
                .work("tesla", "Tesla", "2003–2004", "сооснователь"),
                .work("wrightspeed", "Wrightspeed", "2005–н.в.", "основатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:gwynne-shotwell",
            name: "Гвинн Шотвелл",
            affiliations: [
                .study("northwestern", "Northwestern University", "1982–1988", "BS/MS, инженерия"),
                .work("aerospace", "The Aerospace Corporation", "1988–1998", "инженер"),
                .work("microcosm", "Microcosm", "1998–2002", "директор"),
                .work("spacex", "SpaceX", "2008–н.в.", "президент / COO")
            ]
        ),
        DenseGraphProfile(
            id: "person:sam-altman",
            name: "Сэм Альтман",
            affiliations: [
                .study("stanford", "Stanford University", "2003–2005", "информатика · не окончил"),
                .work("loopt", "Loopt", "2005–2012", "сооснователь / CEO"),
                .work("yc", "Y Combinator", "2014–2019", "президент"),
                .work("reddit", "Reddit", "2014", "CEO"),
                .work("openai", "OpenAI", "2019–н.в.", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:greg-brockman",
            name: "Грег Брокман",
            affiliations: [
                .study("harvard", "Harvard University", "2006–2008", "математика / информатика"),
                .study("mit", "MIT", "2008–2010", "информатика · не окончил"),
                .work("stripe", "Stripe", "2010–2015", "CTO"),
                .work("openai", "OpenAI", "2015–н.в.", "президент")
            ]
        ),
        DenseGraphProfile(
            id: "person:ilya-sutskever",
            name: "Илья Суцкевер",
            affiliations: [
                .study("toronto", "University of Toronto", "2000–2013", "BSc/PhD, информатика"),
                .work("google", "Google", "2013–2015", "исследователь Google Brain"),
                .work("openai", "OpenAI", "2015–2024", "главный исследователь"),
                .work("ssi", "Safe Superintelligence", "2024–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:peter-thiel",
            name: "Питер Тиль",
            affiliations: [
                .study("stanford", "Stanford University", "1985–1992", "BA, философия / JD"),
                .work("sullivan", "Sullivan & Cromwell", "1992–1993", "юрист"),
                .work("credit-suisse", "Credit Suisse", "1993–1996", "трейдер"),
                .work("paypal", "PayPal", "2000–2002", "сооснователь / CEO"),
                .work("palantir", "Palantir", "2003–н.в.", "сооснователь / председатель"),
                .work("founders-fund", "Founders Fund", "2005–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:max-levchin",
            name: "Макс Левчин",
            affiliations: [
                .study("uiuc", "University of Illinois", "1993–1997", "BS, информатика"),
                .work("netmeridian", "NetMeridian", "1996–1998", "сооснователь"),
                .work("paypal", "PayPal", "1998–2002", "сооснователь / CTO"),
                .work("slide", "Slide", "2004–2010", "основатель / CEO"),
                .work("affirm", "Affirm", "2012–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:reid-hoffman",
            name: "Рид Хоффман",
            affiliations: [
                .study("stanford", "Stanford University", "1986–1990", "BS, символические системы"),
                .study("oxford", "University of Oxford", "1990–1993", "MSt, философия"),
                .work("apple", "Apple", "1994–1996", "менеджер продукта"),
                .work("fujitsu", "Fujitsu", "1996–1997", "менеджер"),
                .work("socialnet", "SocialNet", "1997–2000", "основатель"),
                .work("paypal", "PayPal", "2000–2002", "COO"),
                .work("linkedin", "LinkedIn", "2002–2007", "сооснователь / CEO"),
                .work("greylock", "Greylock Partners", "2010–н.в.", "партнёр")
            ]
        ),
        DenseGraphProfile(
            id: "person:larry-page",
            name: "Ларри Пейдж",
            affiliations: [
                .study("michigan", "University of Michigan", "1991–1995", "BSE, компьютерная инженерия"),
                .study("stanford", "Stanford University", "1995–1998", "MS, информатика"),
                .work("google", "Google", "1998–2015", "сооснователь / CEO"),
                .work("alphabet", "Alphabet", "2015–2019", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:sergey-brin",
            name: "Сергей Брин",
            affiliations: [
                .study("maryland", "University of Maryland", "1990–1993", "BS, математика / информатика"),
                .study("stanford", "Stanford University", "1993–1995", "MS, информатика"),
                .work("google", "Google", "1998–2015", "сооснователь"),
                .work("alphabet", "Alphabet", "2015–2019", "президент")
            ]
        ),
        DenseGraphProfile(
            id: "person:eric-schmidt",
            name: "Эрик Шмидт",
            affiliations: [
                .study("princeton", "Princeton University", "1972–1976", "BSE, электротехника"),
                .study("berkeley", "UC Berkeley", "1976–1982", "MS/PhD, EECS"),
                .work("sun", "Sun Microsystems", "1983–1997", "CTO"),
                .work("novell", "Novell", "1997–2001", "CEO"),
                .work("google", "Google", "2001–2011", "CEO"),
                .work("alphabet", "Alphabet", "2015–2017", "председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:sundar-pichai",
            name: "Сундар Пичаи",
            affiliations: [
                .study("iit", "IIT Kharagpur", "1989–1993", "BTech, металлургия"),
                .study("stanford", "Stanford University", "1993–1995", "MS, материаловедение"),
                .study("wharton", "Wharton School", "2000–2002", "MBA"),
                .work("applied", "Applied Materials", "1995–2002", "инженер"),
                .work("mckinsey", "McKinsey", "2002–2004", "консультант"),
                .work("google", "Google", "2004–н.в.", "CEO с 2015"),
                .work("alphabet", "Alphabet", "2019–н.в.", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:susan-wojcicki",
            name: "Сьюзен Воджицки",
            affiliations: [
                .study("harvard", "Harvard University", "1986–1990", "BA, история / литература"),
                .study("ucsc", "UC Santa Cruz", "1991–1993", "MS, экономика"),
                .study("ucla", "UCLA", "1996–1998", "MBA"),
                .work("intel", "Intel", "1990–1991", "маркетинг"),
                .work("bain", "Bain & Company", "1991–1994", "консультант"),
                .work("google", "Google", "1999–2014", "SVP"),
                .work("youtube", "YouTube", "2014–2023", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:mark-zuckerberg",
            name: "Марк Цукерберг",
            affiliations: [
                .study("harvard", "Harvard University", "2002–2004", "информатика / психология · не окончил"),
                .work("meta", "Meta", "2004–н.в.", "основатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:dustin-moskovitz",
            name: "Дастин Московиц",
            affiliations: [
                .study("harvard", "Harvard University", "2002–2004", "экономика · не окончил"),
                .work("meta", "Meta", "2004–2008", "сооснователь"),
                .work("asana", "Asana", "2008–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:sheryl-sandberg",
            name: "Шерил Сэндберг",
            affiliations: [
                .study("harvard", "Harvard University", "1987–1995", "BA, экономика / MBA"),
                .work("world-bank", "World Bank", "1991–1993", "исследователь"),
                .work("treasury", "U.S. Treasury", "1996–2001", "руководитель аппарата"),
                .work("google", "Google", "2001–2008", "VP"),
                .work("meta", "Meta", "2008–2022", "COO")
            ]
        ),
        DenseGraphProfile(
            id: "person:bill-gates",
            name: "Билл Гейтс",
            affiliations: [
                .study("harvard", "Harvard University", "1973–1975", "математика · не окончил"),
                .work("microsoft", "Microsoft", "1975–2000", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:steve-ballmer",
            name: "Стив Балмер",
            affiliations: [
                .study("harvard", "Harvard University", "1973–1977", "BA, прикладная математика"),
                .study("stanford", "Stanford University", "1979–1980", "MBA · не окончил"),
                .work("pg", "Procter & Gamble", "1977–1979", "менеджер продукта"),
                .work("microsoft", "Microsoft", "1980–2014", "CEO с 2000")
            ]
        ),
        DenseGraphProfile(
            id: "person:satya-nadella",
            name: "Сатья Наделла",
            affiliations: [
                .study("manipal", "Manipal Institute of Technology", "1984–1988", "BE, электротехника"),
                .study("uwm", "UW–Milwaukee", "1988–1990", "MS, информатика"),
                .study("booth", "Chicago Booth", "1995–1997", "MBA"),
                .work("sun", "Sun Microsystems", "1990–1992", "инженер"),
                .work("microsoft", "Microsoft", "1992–н.в.", "CEO с 2014")
            ]
        ),
        DenseGraphProfile(
            id: "person:jeff-bezos",
            name: "Джефф Безос",
            affiliations: [
                .study("princeton", "Princeton University", "1982–1986", "BSE, электротехника / информатика"),
                .work("fitel", "Fitel", "1986–1988", "руководитель разработки"),
                .work("bankers-trust", "Bankers Trust", "1988–1990", "VP"),
                .work("de-shaw", "D. E. Shaw", "1990–1994", "SVP"),
                .work("amazon", "Amazon", "1994–2021", "основатель / CEO"),
                .work("blue-origin", "Blue Origin", "2000–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:jensen-huang",
            name: "Дженсен Хуанг",
            affiliations: [
                .study("oregon-state", "Oregon State University", "1980–1984", "BSEE, электротехника"),
                .study("stanford", "Stanford University", "1990–1992", "MS, электротехника"),
                .work("lsi", "LSI Logic", "1985–1993", "директор"),
                .work("nvidia", "NVIDIA", "1993–н.в.", "сооснователь / CEO")
            ]
        )
    ]
}

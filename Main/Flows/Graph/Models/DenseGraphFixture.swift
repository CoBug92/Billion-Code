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
                portrait: portraitReference(for: profile.id),
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
                portrait: node.portrait,
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

    static func portraitReference(for personID: GraphNode.ID) -> GraphNode.PortraitReference? {
        guard let resource = portraitResources[personID] else { return nil }
        return GraphNode.PortraitReference(
            bundledResource: resource,
            accessibilityAttribution: "Wikimedia Commons"
        )
    }

    static let portraitResources: [GraphNode.ID: String] = [
        "person:elon-musk": "elon-musk.jpg", "person:kimbal-musk": "kimbal-musk.jpg",
        "person:jb-straubel": "jb-straubel.jpg", "person:martin-eberhard": "martin-eberhard.jpg",
        "person:gwynne-shotwell": "gwynne-shotwell.jpg", "person:sam-altman": "sam-altman.jpg",
        "person:greg-brockman": "greg-brockman.jpg", "person:ilya-sutskever": "ilya-sutskever.jpg",
        "person:peter-thiel": "peter-thiel.jpg", "person:max-levchin": "max-levchin.jpg",
        "person:reid-hoffman": "reid-hoffman.jpg", "person:larry-page": "larry-page.jpg",
        "person:sergey-brin": "sergey-brin.jpg", "person:eric-schmidt": "eric-schmidt.jpg",
        "person:sundar-pichai": "sundar-pichai.jpg", "person:susan-wojcicki": "susan-wojcicki.jpg",
        "person:mark-zuckerberg": "mark-zuckerberg.jpg", "person:dustin-moskovitz": "dustin-moskovitz.jpg",
        "person:sheryl-sandberg": "sheryl-sandberg.jpg", "person:bill-gates": "bill-gates.jpg",
        "person:steve-ballmer": "steve-ballmer.jpg", "person:satya-nadella": "satya-nadella.jpg",
        "person:jeff-bezos": "jeff-bezos.jpg", "person:jensen-huang": "jensen-huang.jpg",
        "person:steve-jobs": "steve-jobs.jpg", "person:tim-cook": "tim-cook.jpg",
        "person:larry-ellison": "larry-ellison.jpg", "person:marc-benioff": "marc-benioff.jpg",
        "person:patrick-collison": "patrick-collison.jpg", "person:john-collison": "john-collison.jpg",
        "person:jack-dorsey": "jack-dorsey.jpg", "person:evan-spiegel": "evan-spiegel.jpg",
        "person:bobby-murphy": "bobby-murphy.jpg", "person:brian-chesky": "brian-chesky.jpg",
        "person:travis-kalanick": "travis-kalanick.jpg", "person:dara-khosrowshahi": "dara-khosrowshahi.jpg",
        "person:paul-allen": "paul-allen.jpg", "person:andy-jassy": "andy-jassy.jpg",
        "person:mackenzie-scott": "mackenzie-scott.jpg", "person:howard-schultz": "howard-schultz.jpg",
        "person:reed-hastings": "reed-hastings.jpg", "person:marc-randolph": "marc-randolph.jpg",
        "person:larry-fink": "larry-fink.jpg", "person:michael-bloomberg": "michael-bloomberg.jpg",
        "person:jamie-dimon": "jamie-dimon.jpg", "person:charlie-munger": "charlie-munger.jpg",
        "person:sam-walton": "sam-walton.jpg", "person:alice-walton": "alice-walton.jpg",
        "person:rob-walton": "rob-walton.jpg", "person:michael-dell": "michael-dell.jpg",
        "person:mark-cuban": "mark-cuban.jpg", "person:marc-andreessen": "marc-andreessen.jpg",
        "person:ben-horowitz": "ben-horowitz.jpg", "person:john-doerr": "john-doerr.jpg",
        "person:mary-meeker": "mary-meeker.jpg", "person:mary-barra": "mary-barra.jpg",
        "person:henry-ford": "henry-ford.jpg", "person:alfred-sloan": "alfred-sloan.jpg",
        "person:gordon-moore": "gordon-moore.jpg", "person:robert-noyce": "robert-noyce.jpg",
        "person:lisa-su": "lisa-su.jpg", "person:pat-gelsinger": "pat-gelsinger.jpg",
        "person:morris-chang": "morris-chang.jpg", "person:safra-catz": "safra-catz.jpg",
        "person:ursula-burns": "ursula-burns.jpg", "person:diane-greene": "diane-greene.jpg",
        "person:brian-armstrong": "brian-armstrong.jpg",
        "person:fred-ehrsam": "fred-ehrsam.jpg", "person:aaron-levie": "aaron-levie.jpg",
        "person:drew-houston": "drew-houston.jpg",
        "person:lauren-powell-jobs": "lauren-powell-jobs.jpg",
        "person:anne-wojcicki": "anne-wojcicki.jpg", "person:jan-koum": "jan-koum.jpg",
        "person:noubar-afeyan": "noubar-afeyan.jpg", "person:vinod-khosla": "vinod-khosla.jpg",
        "person:warren-buffett": "warren-buffett.jpg",
        "person:whitney-wolfe-herd": "whitney-wolfe-herd.jpg"
    ]
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
        ),
        DenseGraphProfile(
            id: "person:steve-jobs",
            name: "Стив Джобс",
            affiliations: [
                .study("reed", "Reed College", "1972–1974", "гуманитарные курсы · не окончил"),
                .work("atari", "Atari", "1974–1975", "техник"),
                .work("apple", "Apple", "1976–2011", "сооснователь / CEO"),
                .work("next", "NeXT", "1985–1997", "основатель / CEO"),
                .work("pixar", "Pixar", "1986–2006", "председатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:tim-cook",
            name: "Тим Кук",
            affiliations: [
                .study("auburn", "Auburn University", "1978–1982", "BS, промышленная инженерия"),
                .study("duke", "Duke University", "1986–1988", "MBA"),
                .work("ibm", "IBM", "1982–1994", "директор производства"),
                .work("compaq", "Compaq", "1997–1998", "VP"),
                .work("apple", "Apple", "1998–н.в.", "CEO с 2011")
            ]
        ),
        DenseGraphProfile(
            id: "person:larry-ellison",
            name: "Ларри Эллисон",
            affiliations: [
                .study("uiuc", "University of Illinois", "1962–1964", "естественные науки · не окончил"),
                .study("chicago", "University of Chicago", "1966", "физика / математика · не окончил"),
                .work("ampex", "Ampex", "1973–1977", "программист"),
                .work("oracle", "Oracle", "1977–н.в.", "сооснователь / CTO / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:marc-benioff",
            name: "Марк Бениофф",
            affiliations: [
                .study("usc", "University of Southern California", "1982–1986", "BS, бизнес-администрирование"),
                .work("apple", "Apple", "1984–1986", "стажёр"),
                .work("oracle", "Oracle", "1986–1999", "VP"),
                .work("salesforce", "Salesforce", "1999–н.в.", "основатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:patrick-collison",
            name: "Патрик Коллисон",
            affiliations: [
                .study("mit", "MIT", "2006–2007", "информатика · не окончил"),
                .work("auctomatic", "Auctomatic", "2007–2008", "сооснователь"),
                .work("stripe", "Stripe", "2010–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:john-collison",
            name: "Джон Коллисон",
            affiliations: [
                .study("harvard", "Harvard University", "2009–2010", "физика · не окончил"),
                .work("auctomatic", "Auctomatic", "2007–2008", "сооснователь"),
                .work("stripe", "Stripe", "2010–н.в.", "сооснователь / президент")
            ]
        ),
        DenseGraphProfile(
            id: "person:jack-dorsey",
            name: "Джек Дорси",
            affiliations: [
                .study("mst", "Missouri S&T", "1995–1997", "информатика"),
                .study("nyu", "New York University", "1997–1999", "информатика · не окончил"),
                .work("twitter", "Twitter", "2006–2021", "сооснователь / CEO"),
                .work("block", "Block", "2009–н.в.", "сооснователь / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:evan-spiegel",
            name: "Эван Шпигель",
            affiliations: [
                .study("stanford", "Stanford University", "2008–2012", "product design"),
                .work("snap", "Snap", "2011–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:bobby-murphy",
            name: "Бобби Мёрфи",
            affiliations: [
                .study("stanford", "Stanford University", "2008–2010", "математические и вычислительные науки"),
                .work("snap", "Snap", "2011–н.в.", "сооснователь / CTO")
            ]
        ),
        DenseGraphProfile(
            id: "person:brian-chesky",
            name: "Брайан Чески",
            affiliations: [
                .study("risd", "Rhode Island School of Design", "1999–2004", "BFA, промышленный дизайн"),
                .work("airbnb", "Airbnb", "2008–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:travis-kalanick",
            name: "Трэвис Каланик",
            affiliations: [
                .study("ucla", "UCLA", "1994–1998", "компьютерная инженерия · не окончил"),
                .work("scour", "Scour", "1997–2000", "сооснователь"),
                .work("red-swoosh", "Red Swoosh", "2001–2007", "сооснователь"),
                .work("uber", "Uber", "2009–2017", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:dara-khosrowshahi",
            name: "Дара Хосровшахи",
            affiliations: [
                .study("brown", "Brown University", "1987–1991", "BS, электротехника"),
                .work("allen-company", "Allen & Company", "1991–1998", "аналитик"),
                .work("iac", "IAC", "1998–2005", "CFO"),
                .work("expedia", "Expedia", "2005–2017", "CEO"),
                .work("uber", "Uber", "2017–н.в.", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:paul-allen",
            name: "Пол Аллен",
            affiliations: [
                .study("washington-state", "Washington State University", "1971–1974", "информатика · не окончил"),
                .work("honeywell", "Honeywell", "1974–1975", "программист"),
                .work("microsoft", "Microsoft", "1975–1983", "сооснователь"),
                .work("vulcan", "Vulcan", "1986–2018", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:andy-jassy",
            name: "Энди Джесси",
            affiliations: [
                .study("harvard", "Harvard University", "1986–1997", "BA / MBA"),
                .work("amazon", "Amazon", "1997–н.в.", "CEO с 2021"),
                .work("aws", "Amazon Web Services", "2003–2021", "руководитель")
            ]
        ),
        DenseGraphProfile(
            id: "person:mackenzie-scott",
            name: "Маккензи Скотт",
            affiliations: [
                .study("princeton", "Princeton University", "1988–1992", "BA, английская литература"),
                .work("de-shaw", "D. E. Shaw", "1992–1994", "аналитик"),
                .work("amazon", "Amazon", "1994–1996", "ранний сотрудник"),
                .work("yield-giving", "Yield Giving", "2019–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:howard-schultz",
            name: "Говард Шульц",
            affiliations: [
                .study("northern-michigan", "Northern Michigan University", "1971–1975", "BA, коммуникации"),
                .work("xerox", "Xerox", "1976–1979", "продажи"),
                .work("starbucks", "Starbucks", "1982–2018", "CEO / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:reed-hastings",
            name: "Рид Хастингс",
            affiliations: [
                .study("bowdoin", "Bowdoin College", "1978–1983", "BA, математика"),
                .study("stanford", "Stanford University", "1985–1988", "MS, информатика"),
                .work("pure-software", "Pure Software", "1991–1997", "основатель"),
                .work("netflix", "Netflix", "1997–2023", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:marc-randolph",
            name: "Марк Рэндольф",
            affiliations: [
                .study("hamilton", "Hamilton College", "1976–1980", "BA, геология"),
                .work("pure-software", "Pure Software", "1996–1997", "VP marketing"),
                .work("netflix", "Netflix", "1997–2003", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:larry-fink",
            name: "Ларри Финк",
            affiliations: [
                .study("ucla", "UCLA", "1970–1976", "BA / MBA"),
                .work("first-boston", "First Boston", "1976–1988", "управляющий директор"),
                .work("blackrock", "BlackRock", "1988–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:michael-bloomberg",
            name: "Майкл Блумберг",
            affiliations: [
                .study("johns-hopkins", "Johns Hopkins University", "1960–1964", "BS, электротехника"),
                .study("harvard", "Harvard University", "1964–1966", "MBA"),
                .work("salomon-brothers", "Salomon Brothers", "1966–1981", "партнёр"),
                .work("bloomberg", "Bloomberg", "1981–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:stephen-schwarzman",
            name: "Стивен Шварцман",
            affiliations: [
                .study("yale", "Yale University", "1965–1969", "BA"),
                .study("harvard", "Harvard University", "1970–1972", "MBA"),
                .work("lehman-brothers", "Lehman Brothers", "1972–1985", "управляющий директор"),
                .work("blackstone", "Blackstone", "1985–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:ken-griffin",
            name: "Кен Гриффин",
            affiliations: [
                .study("harvard", "Harvard University", "1986–1989", "BA, экономика"),
                .work("citadel", "Citadel", "1990–н.в.", "основатель / CEO"),
                .work("citadel-securities", "Citadel Securities", "2002–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:jamie-dimon",
            name: "Джейми Даймон",
            affiliations: [
                .study("tufts", "Tufts University", "1974–1978", "BA, психология / экономика"),
                .study("harvard", "Harvard University", "1980–1982", "MBA"),
                .work("american-express", "American Express", "1982–1985", "ассистент Сэнди Вейла"),
                .work("citigroup", "Citigroup", "1998–1998", "президент"),
                .work("jpmorgan", "JPMorgan Chase", "2004–н.в.", "CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:warren-buffett",
            name: "Уоррен Баффетт",
            affiliations: [
                .study("nebraska", "University of Nebraska", "1947–1950", "BS, бизнес"),
                .study("columbia", "Columbia University", "1950–1951", "MS, экономика"),
                .work("buffett-partnership", "Buffett Partnership", "1956–1969", "основатель"),
                .work("berkshire", "Berkshire Hathaway", "1965–н.в.", "председатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:charlie-munger",
            name: "Чарли Мангер",
            affiliations: [
                .study("michigan", "University of Michigan", "1941–1943", "математика"),
                .study("harvard", "Harvard University", "1945–1948", "JD"),
                .work("munger-tolles", "Munger, Tolles & Olson", "1962–н.в.", "сооснователь"),
                .work("berkshire", "Berkshire Hathaway", "1978–2023", "вице-председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:sam-walton",
            name: "Сэм Уолтон",
            affiliations: [
                .study("missouri", "University of Missouri", "1936–1940", "BA, экономика"),
                .work("jc-penney", "JCPenney", "1940–1942", "стажёр-менеджер"),
                .work("walmart", "Walmart", "1962–1992", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:alice-walton",
            name: "Элис Уолтон",
            affiliations: [
                .study("trinity", "Trinity University", "1967–1971", "BA, экономика"),
                .work("first-commerce", "First Commerce", "1971–1979", "аналитик"),
                .work("walmart", "Walmart", "1988–н.в.", "акционер / наследница"),
                .work("crystal-bridges", "Crystal Bridges Museum", "2005–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:rob-walton",
            name: "Роб Уолтон",
            affiliations: [
                .study("wooster", "College of Wooster", "1962–1966", "BA"),
                .study("columbia", "Columbia University", "1966–1969", "JD"),
                .work("conner-winters", "Conner & Winters", "1969–1978", "юрист"),
                .work("walmart", "Walmart", "1978–2015", "председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:michael-dell",
            name: "Майкл Делл",
            affiliations: [
                .study("ut-austin", "University of Texas at Austin", "1983–1984", "premed · не окончил"),
                .work("dell", "Dell Technologies", "1984–н.в.", "основатель / CEO"),
                .work("msd-capital", "MSD Capital", "1998–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:mark-cuban",
            name: "Марк Кьюбан",
            affiliations: [
                .study("indiana", "Indiana University", "1977–1981", "BS, бизнес"),
                .work("micro-solutions", "MicroSolutions", "1983–1990", "основатель"),
                .work("broadcast-com", "Broadcast.com", "1995–1999", "сооснователь"),
                .work("dallas-mavericks", "Dallas Mavericks", "2000–н.в.", "владелец")
            ]
        ),
        DenseGraphProfile(
            id: "person:marc-andreessen",
            name: "Марк Андриссен",
            affiliations: [
                .study("uiuc", "University of Illinois", "1989–1993", "BS, информатика"),
                .work("ncsa", "NCSA", "1992–1993", "разработчик Mosaic"),
                .work("netscape", "Netscape", "1994–1999", "сооснователь"),
                .work("a16z", "Andreessen Horowitz", "2009–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:ben-horowitz",
            name: "Бен Хоровиц",
            affiliations: [
                .study("columbia", "Columbia University", "1984–1988", "BA, информатика"),
                .study("ucla", "UCLA", "1988–1990", "MS, информатика"),
                .work("netscape", "Netscape", "1995–1999", "VP"),
                .work("loudcloud", "Loudcloud", "1999–2007", "сооснователь / CEO"),
                .work("a16z", "Andreessen Horowitz", "2009–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:vinod-khosla",
            name: "Винод Хосла",
            affiliations: [
                .study("iit-delhi", "IIT Delhi", "1971–1976", "BTech, электротехника"),
                .study("cmu", "Carnegie Mellon University", "1976–1978", "MS, биомедицинская инженерия"),
                .study("stanford", "Stanford University", "1978–1980", "MBA"),
                .work("sun", "Sun Microsystems", "1982–1984", "сооснователь"),
                .work("kleiner-perkins", "Kleiner Perkins", "1986–2004", "партнёр"),
                .work("khosla-ventures", "Khosla Ventures", "2004–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:john-doerr",
            name: "Джон Дорр",
            affiliations: [
                .study("rice", "Rice University", "1969–1973", "BS/MS, электротехника"),
                .study("harvard", "Harvard University", "1974–1976", "MBA"),
                .work("intel", "Intel", "1974–1980", "инженер / продавец"),
                .work("kleiner-perkins", "Kleiner Perkins", "1980–н.в.", "партнёр")
            ]
        ),
        DenseGraphProfile(
            id: "person:mary-meeker",
            name: "Мэри Микер",
            affiliations: [
                .study("depauw", "DePauw University", "1977–1981", "BA, психология"),
                .study("cornell", "Cornell University", "1984–1986", "MBA"),
                .work("morgan-stanley", "Morgan Stanley", "1991–2010", "аналитик"),
                .work("kleiner-perkins", "Kleiner Perkins", "2010–2018", "партнёр"),
                .work("bond-capital", "Bond Capital", "2018–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:mary-barra",
            name: "Мэри Барра",
            affiliations: [
                .study("kettering", "Kettering University", "1980–1985", "BS, электротехника"),
                .study("stanford", "Stanford University", "1988–1990", "MBA"),
                .work("gm", "General Motors", "1980–н.в.", "CEO с 2014")
            ]
        ),
        DenseGraphProfile(
            id: "person:henry-ford",
            name: "Генри Форд",
            affiliations: [
                .study("detroit-business", "Detroit Business Institute", "1887–1888", "бухгалтерия"),
                .work("edison-illuminating", "Edison Illuminating Company", "1891–1899", "главный инженер"),
                .work("ford", "Ford Motor Company", "1903–1947", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:alfred-sloan",
            name: "Альфред Слоун",
            affiliations: [
                .study("mit", "MIT", "1892–1895", "BS, электротехника"),
                .work("hyatt-roller-bearing", "Hyatt Roller Bearing", "1899–1916", "президент"),
                .work("gm", "General Motors", "1918–1956", "CEO / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:gordon-moore",
            name: "Гордон Мур",
            affiliations: [
                .study("berkeley", "UC Berkeley", "1946–1950", "BS, химия"),
                .study("caltech", "Caltech", "1950–1954", "PhD, химия"),
                .work("fairchild", "Fairchild Semiconductor", "1957–1968", "сооснователь"),
                .work("intel", "Intel", "1968–1997", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:robert-noyce",
            name: "Роберт Нойс",
            affiliations: [
                .study("grinnell", "Grinnell College", "1945–1949", "BA, физика"),
                .study("mit", "MIT", "1949–1953", "PhD, физика"),
                .work("fairchild", "Fairchild Semiconductor", "1957–1968", "сооснователь"),
                .work("intel", "Intel", "1968–1990", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:andy-grove",
            name: "Энди Гроув",
            affiliations: [
                .study("ccny", "City College of New York", "1957–1960", "BS, химическая инженерия"),
                .study("berkeley", "UC Berkeley", "1960–1963", "PhD, химическая инженерия"),
                .work("fairchild", "Fairchild Semiconductor", "1963–1968", "исследователь"),
                .work("intel", "Intel", "1968–2005", "CEO / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:lisa-su",
            name: "Лиза Су",
            affiliations: [
                .study("mit", "MIT", "1986–1994", "BS/MS/PhD, электротехника"),
                .work("texas-instruments", "Texas Instruments", "1994–1995", "технический сотрудник"),
                .work("ibm", "IBM", "1995–2007", "VP semiconductor R&D"),
                .work("amd", "AMD", "2012–н.в.", "CEO с 2014")
            ]
        ),
        DenseGraphProfile(
            id: "person:pat-gelsinger",
            name: "Пэт Гелсингер",
            affiliations: [
                .study("santa-clara", "Santa Clara University", "1979–1983", "BS, электротехника"),
                .study("stanford", "Stanford University", "1983–1985", "MS, электротехника"),
                .work("intel", "Intel", "1979–2024", "CTO / CEO"),
                .work("vmware", "VMware", "2012–2021", "CEO"),
            ]
        ),
        DenseGraphProfile(
            id: "person:morris-chang",
            name: "Моррис Чанг",
            affiliations: [
                .study("harvard", "Harvard University", "1949–1950", "гуманитарные науки"),
                .study("mit", "MIT", "1950–1953", "BS/MS, машиностроение"),
                .study("stanford", "Stanford University", "1961–1964", "PhD, электротехника"),
                .work("texas-instruments", "Texas Instruments", "1958–1983", "VP"),
                .work("tsmc", "TSMC", "1987–2018", "основатель / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:safra-catz",
            name: "Сафра Кац",
            affiliations: [
                .study("upenn", "University of Pennsylvania", "1979–1983", "BA"),
                .study("upenn-law", "Penn Carey Law", "1983–1986", "JD"),
                .work("donaldson-lufkin", "Donaldson, Lufkin & Jenrette", "1986–1999", "управляющий директор"),
                .work("oracle", "Oracle", "1999–н.в.", "CEO с 2014")
            ]
        ),
        DenseGraphProfile(
            id: "person:diane-greene",
            name: "Дайан Грин",
            affiliations: [
                .study("vermont", "University of Vermont", "1972–1976", "BS, машиностроение"),
                .study("mit", "MIT", "1976–1978", "MS, naval architecture"),
                .study("berkeley", "UC Berkeley", "1986–1988", "MS, информатика"),
                .work("vmware", "VMware", "1998–2008", "сооснователь / CEO"),
                .work("google", "Google", "2015–2019", "CEO Google Cloud")
            ]
        ),
        DenseGraphProfile(
            id: "person:ursula-burns",
            name: "Урсула Бёрнс",
            affiliations: [
                .study("polytechnic-nyu", "Polytechnic Institute of NYU", "1976–1980", "BS, машиностроение"),
                .study("columbia", "Columbia University", "1980–1981", "MS, машиностроение"),
                .work("xerox", "Xerox", "1980–2016", "CEO / председатель"),
                .work("veon", "VEON", "2017–2020", "председатель / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:whitney-wolfe-herd",
            name: "Уитни Вулф Херд",
            affiliations: [
                .study("smu", "Southern Methodist University", "2007–2011", "BA, международные исследования"),
                .work("tinder", "Tinder", "2012–2014", "сооснователь / VP marketing"),
                .work("bumble", "Bumble", "2014–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:brian-armstrong",
            name: "Брайан Армстронг",
            affiliations: [
                .study("rice", "Rice University", "2001–2006", "BA/MS, экономика / информатика"),
                .work("deloitte", "Deloitte", "2005–2010", "консультант"),
                .work("airbnb", "Airbnb", "2011–2012", "инженер"),
                .work("coinbase", "Coinbase", "2012–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:fred-ehrsam",
            name: "Фред Эрсам",
            affiliations: [
                .study("duke", "Duke University", "2006–2010", "BS, информатика / экономика"),
                .work("goldman-sachs", "Goldman Sachs", "2010–2012", "трейдер"),
                .work("coinbase", "Coinbase", "2012–2017", "сооснователь"),
                .work("paradigm", "Paradigm", "2018–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:aaron-levie",
            name: "Аарон Леви",
            affiliations: [
                .study("usc", "University of Southern California", "2003–2005", "бизнес · не окончил"),
                .work("box", "Box", "2005–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:drew-houston",
            name: "Дрю Хьюстон",
            affiliations: [
                .study("mit", "MIT", "2001–2005", "BS, информатика"),
                .work("bit9", "Bit9", "2005–2006", "инженер"),
                .work("dropbox", "Dropbox", "2007–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:melinda-french-gates",
            name: "Мелинда Френч Гейтс",
            affiliations: [
                .study("duke", "Duke University", "1982–1987", "BA, информатика / MBA"),
                .work("microsoft", "Microsoft", "1987–1996", "менеджер продукта"),
                .work("gates-foundation", "Gates Foundation", "2000–2024", "сопредседатель"),
                .work("pivotal-ventures", "Pivotal Ventures", "2015–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:lauren-powell-jobs",
            name: "Лорен Пауэлл Джобс",
            affiliations: [
                .study("upenn", "University of Pennsylvania", "1981–1985", "BA/BS, политология / экономика"),
                .study("stanford", "Stanford University", "1989–1991", "MBA"),
                .work("goldman-sachs", "Goldman Sachs", "1985–1988", "трейдер"),
                .work("emerson-collective", "Emerson Collective", "2004–н.в.", "основатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:anne-wojcicki",
            name: "Энн Воджицки",
            affiliations: [
                .study("yale", "Yale University", "1991–1996", "BS, биология"),
                .work("passport-capital", "Passport Capital", "1996–2000", "аналитик"),
                .work("23andme", "23andMe", "2006–н.в.", "сооснователь / CEO")
            ]
        ),
        DenseGraphProfile(
            id: "person:brian-acton",
            name: "Брайан Эктон",
            affiliations: [
                .study("stanford", "Stanford University", "1990–1994", "BS, информатика"),
                .work("apple", "Apple", "1992–1996", "инженер"),
                .work("yahoo", "Yahoo", "1996–2007", "инженер"),
                .work("whatsapp", "WhatsApp", "2009–2014", "сооснователь"),
                .work("signal-foundation", "Signal Foundation", "2018–н.в.", "сооснователь")
            ]
        ),
        DenseGraphProfile(
            id: "person:jan-koum",
            name: "Ян Кум",
            affiliations: [
                .study("sjsu", "San Jose State University", "1995–1997", "информатика · не окончил"),
                .work("yahoo", "Yahoo", "1997–2007", "инженер"),
                .work("whatsapp", "WhatsApp", "2009–2014", "сооснователь / CEO"),
                .work("meta", "Meta", "2014–2018", "руководитель WhatsApp")
            ]
        ),
        DenseGraphProfile(
            id: "person:noubar-afeyan",
            name: "Нубар Афеян",
            affiliations: [
                .study("mcgill", "McGill University", "1980–1983", "BS, химическая инженерия"),
                .study("mit", "MIT", "1983–1987", "PhD, биохимическая инженерия"),
                .work("perseptive-biosystems", "PerSeptive Biosystems", "1991–1998", "основатель / CEO"),
                .work("flagship-pioneering", "Flagship Pioneering", "2000–н.в.", "основатель / CEO"),
                .work("moderna", "Moderna", "2010–н.в.", "сооснователь / председатель")
            ]
        ),
        DenseGraphProfile(
            id: "person:robert-langer",
            name: "Роберт Лангер",
            affiliations: [
                .study("cornell", "Cornell University", "1966–1970", "BS, химическая инженерия"),
                .study("mit", "MIT", "1970–1974", "ScD, химическая инженерия"),
                .work("moderna", "Moderna", "2010–н.в.", "сооснователь")
            ]
        )
    ]
}

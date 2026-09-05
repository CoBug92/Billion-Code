import Foundation

enum OrganizationDossierHighlights {
    static let operatingPeriods: [GraphNode.ID: String] = [
        "organization:zip2": "1995–1999", "organization:tesla": "2003–н.в.",
        "organization:spacex": "2002–н.в.", "organization:openai": "2015–н.в.",
        "organization:paypal": "1998–н.в.", "organization:google": "1998–н.в.",
        "organization:alphabet": "2015–н.в.", "organization:meta": "2004–н.в.",
        "organization:microsoft": "1975–н.в.", "organization:amazon": "1994–н.в.",
        "organization:nvidia": "1993–н.в.", "organization:linkedin": "2002–н.в.",
        "organization:stripe": "2010–н.в.", "organization:neuralink": "2016–н.в.",
        "organization:xai": "2023–н.в.", "organization:credit-suisse": "1856–2023"
    ]

    static let events: [GraphNode.ID: [DossierTimelineEvent]] = [
        "organization:tesla": [
            DossierTimelineEvent(
                id: "timeline:tesla-sec-settlement",
                year: 2018,
                title: "Суд и соглашение с SEC",
                description: "После иска SEC суд утвердил соглашение: Илон Маск покинул пост председателя совета, "
                    + "а Tesla усилила независимый контроль.",
                linkedEntityID: "person:elon-musk",
                source: teslaSECSource
            )
        ],
        "organization:openai": [
            DossierTimelineEvent(
                id: "timeline:openai-leadership-crisis",
                year: 2023,
                title: "Кризис управления",
                description: "Совет директоров отстранил Сэма Альтмана; через несколько дней он вернулся на пост CEO, "
                    + "а состав совета изменился.",
                linkedEntityID: "person:sam-altman",
                source: openAILeadershipSource
            )
        ],
        "organization:microsoft": [
            DossierTimelineEvent(
                id: "timeline:microsoft-antitrust-ruling",
                year: 2000,
                title: "Антимонопольное дело",
                description: "Федеральный суд США признал нарушения антимонопольного законодательства; "
                    + "дело привело к многолетнему судебному контролю.",
                linkedEntityID: nil,
                source: microsoftAntitrustSource
            )
        ],
        "organization:meta": [
            DossierTimelineEvent(
                id: "timeline:facebook-ftc-privacy",
                year: 2019,
                title: "Скандал вокруг приватности",
                description: "Facebook согласилась выплатить FTC 5 млрд долларов и перестроить корпоративный "
                    + "контроль за приватностью пользователей.",
                linkedEntityID: "person:mark-zuckerberg",
                source: facebookFTCSource
            )
        ],
        "organization:credit-suisse": [
            DossierTimelineEvent(
                id: "timeline:credit-suisse-ubs-takeover",
                year: 2023,
                title: "Кризис и поглощение",
                description: "После утраты доверия FINMA одобрила экстренное поглощение Credit Suisse банком UBS "
                    + "при поддержке властей Швейцарии.",
                linkedEntityID: nil,
                source: creditSuisseFINMASource
            )
        ]
    ]
}

// MARK: - Sources

private extension OrganizationDossierHighlights {
    static let teslaSECSource = DossierSource(
        id: "source:tesla-sec-settlement",
        publisher: "U.S. Securities and Exchange Commission",
        title: "Statement Regarding Agreed Settlements With Elon Musk and Tesla",
        url: URL(string: "https://www.sec.gov/newsroom/speeches-statements/clayton-settlements-elon-musk-tesla")
    )

    static let openAILeadershipSource = DossierSource(
        id: "source:openai-leadership-2023",
        publisher: "OpenAI",
        title: "Sam Altman returns as CEO, OpenAI has a new initial board",
        url: URL(string: "https://openai.com/index/sam-altman-returns-as-ceo-openai-has-a-new-initial-board/")
    )

    static let microsoftAntitrustSource = DossierSource(
        id: "source:microsoft-antitrust",
        publisher: "U.S. Department of Justice",
        title: "U.S. v. Microsoft Corporation",
        url: URL(string: "https://www.justice.gov/atr/case/us-v-microsoft-corporation-browser-and-middleware")
    )

    static let facebookFTCSource = DossierSource(
        id: "source:facebook-ftc-2019",
        publisher: "U.S. Federal Trade Commission",
        title: "FTC Imposes $5 Billion Penalty and Sweeping New Privacy Restrictions on Facebook",
        url: URL(
            string: "https://www.ftc.gov/news-events/news/press-releases/2019/07/"
                + "ftc-imposes-5-billion-penalty-sweeping-new-privacy-restrictions-facebook"
        )
    )

    static let creditSuisseFINMASource = DossierSource(
        id: "source:credit-suisse-ubs-2023",
        publisher: "FINMA",
        title: "FINMA approves merger of UBS and Credit Suisse",
        url: URL(string: "https://www.finma.ch/en/news/2023/03/20230319-mm-cs-ubs/")
    )
}

struct GraphAtlasConfiguration: Equatable, Sendable {
    let leadChapterID: GraphChapter.ID
    let chapterOrder: [GraphChapter.ID]

    static let muskDesignSpike = GraphAtlasConfiguration(
        leadChapterID: "organization:tesla",
        chapterOrder: [
            "organization:tesla",
            "organization:spacex",
            "organization:openai",
            "organization:paypal",
            "organization:zip2"
        ]
    )
}

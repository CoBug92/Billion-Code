struct DenseGraphSectionMembership: Identifiable, Equatable, Sendable {
    let personID: GraphNode.ID
    let sectionID: DenseGraphSection.ID
    let position: GraphPoint

    var id: String {
        "\(personID)|\(sectionID)"
    }
}

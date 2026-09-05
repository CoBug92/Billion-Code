import Foundation
import SwiftUI

// MARK: - Presentation

extension DenseGraphDossierPanel {
    var universityCloudVariant: UniversityCloudVariant {
#if DEBUG
        debugVariant(argument: "-universityCloudVariant") ?? .soft
#else
        .soft
#endif
    }

    var personMetadata: String? {
        guard let details = dossier.personDetails else { return nil }
        let birthDate = details.birthDate
        let reference = details.ageReferenceDate ?? currentDateComponents
        let birthText: String
        if let month = birthDate.month, let day = birthDate.day {
            birthText = "\(day) \(russianMonth(month)) \(birthDate.year)"
        } else {
            birthText = "\(birthDate.year) год"
        }
        let personAge = age(from: birthDate, through: reference)
        return "\(birthText) (\(personAge) \(ageUnit(personAge)))"
    }

    var headerMetadata: String? {
        switch node.kind {
        case .organization, .university:
            dossier.operatingPeriod
        default:
            personMetadata
        }
    }

    var eyebrowText: String? {
        switch node.kind {
        case .person, .organization: nil
        case .university: dossier.facts.first { $0.id.hasSuffix(":type") }?.value
        default: node.kind.dossierTitle
        }
    }

    var organizationActivity: String {
        dossier.facts.first { $0.id.hasSuffix(":activity") }?.value ?? node.summary
    }

    var organizationFounders: [DossierEntityLink] {
        dossier.sortedLinks.filter { link in
            let role = link.role.lowercased()
            return role.contains("основател") || role.contains("соосновател")
        }
    }

    var organizationRelatedPeople: [DossierEntityLink] {
        let founderIDs = Set(organizationFounders.map(\.id))
        return dossier.sortedLinks.filter { !founderIDs.contains($0.id) }
    }

    var organizationPeopleClouds: some View {
        OrganizationPeopleClouds(
            founders: organizationFounders,
            relatedPeople: organizationRelatedPeople,
            onNavigate: onNavigate
        )
    }

    var universityTypeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Graph.Dossier.type.uppercased())
                .font(.caption2.bold())
                .tracking(0.9)
                .foregroundStyle(node.kind.denseGraphColor)
            Text(dossier.facts.first { $0.id.hasSuffix(":type") }?.value ?? node.summary)
                .font(.headline)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            if let location = dossier.facts.first(where: { $0.id.hasSuffix(":location") })?.value {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    var universityPeopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Graph.Dossier.peopleAndPrograms)
                .font(.headline)
            UniversityPeopleClouds(
                people: dossier.sortedLinks,
                showsStudyPeriod: false,
                usesHorizontalLayout: false,
                onNavigate: onNavigate
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    var timelineYearAnchors: [(year: Int, eventID: DossierTimelineEvent.ID)] {
        var seenYears = Set<Int>()
        return dossier.timeline.compactMap { event in
            guard seenYears.insert(event.year).inserted else { return nil }
            return (event.year, event.id)
        }
    }

    func timelineTint(for event: DossierTimelineEvent) -> Color {
        guard let entityID = event.linkedEntityID else { return node.kind.denseGraphColor }
        if entityID.hasPrefix("university:") {
            return GraphEntityKind.university.denseGraphColor
        }
        if entityID.hasPrefix("organization:") {
            let link = dossier.links.first { $0.entityID == entityID }
            return link?.isCurrent == false ? .secondary : GraphEntityKind.organization.denseGraphColor
        }
        return node.kind.denseGraphColor
    }

    func color(for link: DossierEntityLink) -> Color {
        if link.entityID?.hasPrefix("organization:") == true {
            return GraphEntityKind.organization.denseGraphColor
        }
        if link.entityID?.hasPrefix("university:") == true {
            return GraphEntityKind.university.denseGraphColor
        }
        return GraphEntityKind.person.denseGraphColor
    }

    func formatUSD(_ amount: UInt64) -> String {
        let value = Double(amount)
        if value >= 1_000_000_000 {
            return "~$" + (value / 1_000_000_000).formatted(.number.precision(.fractionLength(0...1))) + " млрд"
        }
        if value >= 1_000_000 {
            return "~$" + (value / 1_000_000).formatted(.number.precision(.fractionLength(0...1))) + " млн"
        }
        return "~$" + value.formatted(.number.notation(.compactName))
    }
}

// MARK: - Private helpers

private extension DenseGraphDossierPanel {
    func debugVariant<Variant: RawRepresentable>(argument: String) -> Variant? where Variant.RawValue == Int {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: argument),
              arguments.indices.contains(index + 1),
              let rawValue = Int(arguments[index + 1]) else { return nil }
        return Variant(rawValue: rawValue)
    }

    var currentDateComponents: DossierBirthDate {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return DossierBirthDate(
            year: components.year ?? 2026,
            month: components.month,
            day: components.day
        )
    }

    func age(from birth: DossierBirthDate, through reference: DossierBirthDate) -> Int {
        var result = reference.year - birth.year
        if let birthMonth = birth.month, let referenceMonth = reference.month {
            let birthDay = birth.day ?? 1
            let referenceDay = reference.day ?? 1
            if (referenceMonth, referenceDay) < (birthMonth, birthDay) { result -= 1 }
        }
        return max(result, 0)
    }

    func russianMonth(_ month: Int) -> String {
        let months = [
            "января", "февраля", "марта", "апреля", "мая", "июня",
            "июля", "августа", "сентября", "октября", "ноября", "декабря"
        ]
        return months.indices.contains(month - 1) ? months[month - 1] : ""
    }

    func ageUnit(_ age: Int) -> String {
        let lastTwoDigits = age % 100
        if 11...14 ~= lastTwoDigits { return "лет" }
        return switch age % 10 {
        case 1: "год"
        case 2...4: "года"
        default: "лет"
        }
    }
}

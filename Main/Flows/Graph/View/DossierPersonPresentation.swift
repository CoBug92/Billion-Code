import Foundation
import SwiftUI

extension DenseGraphDossierPanel {
    var personMetadata: String? {
        guard let details = dossier.personDetails else { return nil }
        let birthText = formattedDate(details.birthDate)
        if let deathDate = details.deathDate {
            return "\(birthText) — \(formattedDate(deathDate))"
        }
        let personAge = age(from: details.birthDate, through: currentDateComponents)
        return "\(birthText) — \(personAge) \(ageUnit(personAge))"
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
        case .person, .organization:
            nil
        case .university:
            universityType
        default:
            node.kind.dossierTitle
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

    var universityType: String {
        dossier.facts.first { $0.id.hasSuffix(":type") }?.value ?? node.summary
    }

    var universityLocation: String {
        dossier.facts.first { $0.id.hasSuffix(":location") }?.value ?? ""
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

private extension DenseGraphDossierPanel {
    func formattedDate(_ date: DossierBirthDate) -> String {
        if let month = date.month, let day = date.day {
            return "\(day) \(russianMonth(month)) \(date.year)"
        }
        return "\(date.year) год"
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

import Foundation

extension DenseGraphDossierPanel {
    var universityCloudVariant: UniversityCloudVariant {
#if DEBUG
        debugVariant(argument: "-universityCloudVariant") ?? .soft
#else
        .soft
#endif
    }

    var wealthCardVariant: WealthCardVariant {
#if DEBUG
        debugVariant(argument: "-wealthCardVariant") ?? .gradient
#else
        .gradient
#endif
    }

    var personUniversityCloudVariant: PersonUniversityCloudVariant {
#if DEBUG
        debugVariant(argument: "-personUniversityCloudVariant") ?? .cloud
#else
        .cloud
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
}

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

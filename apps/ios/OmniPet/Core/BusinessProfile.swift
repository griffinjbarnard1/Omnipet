import Foundation

struct BusinessProfile: Identifiable, Hashable {
    enum Category: String {
        case vet = "Vet"
        case daycare = "Daycare"
        case grooming = "Grooming"
        case boarding = "Boarding"
    }

    enum PartnershipStatus {
        case partner
        case nonPartner

        var label: String {
            switch self {
            case .partner: return "Partner"
            case .nonPartner: return "Non-Partner"
            }
        }
    }

    let id: UUID
    let name: String
    let category: Category
    let distanceMiles: Double
    let partnershipStatus: PartnershipStatus
    let summary: String
    let requirements: [String]

    static let sample: [BusinessProfile] = [
        .init(
            id: UUID(),
            name: "Canal Street Vet",
            category: .vet,
            distanceMiles: 1.2,
            partnershipStatus: .partner,
            summary: "AAHA-accredited clinic with same-day urgent visits.",
            requirements: ["Rabies", "DHPP", "Recent fecal test"]
        ),
        .init(
            id: UUID(),
            name: "Pine & Paw Grooming",
            category: .grooming,
            distanceMiles: 2.8,
            partnershipStatus: .nonPartner,
            summary: "Hand-scissor specialists and breed-specific grooming packages.",
            requirements: ["Rabies", "Bordetella"]
        ),
        .init(
            id: UUID(),
            name: "Happy Trails Boarding",
            category: .boarding,
            distanceMiles: 4.1,
            partnershipStatus: .partner,
            summary: "Overnight suites, play yard webcams, and med administration.",
            requirements: ["Rabies", "Bordetella", "Canine influenza"]
        )
    ]
}

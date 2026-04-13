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

    enum ListingType: String {
        case business = "Business"
        case individual = "Individual"
    }

    let id: UUID
    let name: String
    let category: Category
    let distanceMiles: Double
    let partnershipStatus: PartnershipStatus
    let listingType: ListingType
    let summary: String
    let requirements: [String]

    static let sample: [BusinessProfile] = [
        .init(
            id: UUID(),
            name: "Canal Street Vet",
            category: .vet,
            distanceMiles: 1.2,
            partnershipStatus: .partner,
            listingType: .business,
            summary: "AAHA-accredited clinic with same-day urgent visits.",
            requirements: ["Rabies", "DHPP", "Recent fecal test"]
        ),
        .init(
            id: UUID(),
            name: "Pine & Paw Grooming",
            category: .grooming,
            distanceMiles: 2.8,
            partnershipStatus: .nonPartner,
            listingType: .business,
            summary: "Hand-scissor specialists and breed-specific grooming packages.",
            requirements: ["Rabies", "Bordetella"]
        ),
        .init(
            id: UUID(),
            name: "Happy Trails Boarding",
            category: .boarding,
            distanceMiles: 4.1,
            partnershipStatus: .partner,
            listingType: .business,
            summary: "Overnight suites, play yard webcams, and med administration.",
            requirements: ["Rabies", "Bordetella", "Canine influenza"]
        ),
        .init(
            id: UUID(),
            name: "Riley's Home Pet Sitting",
            category: .boarding,
            distanceMiles: 5.2,
            partnershipStatus: .nonPartner,
            listingType: .individual,
            summary: "Independent in-home boarding host with fenced yard and one-family-at-a-time stays.",
            requirements: ["Rabies", "Bordetella"]
        )
    ]
}

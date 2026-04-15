import Foundation
import CoreLocation

struct LocationPoint: Hashable, Codable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct BusinessProfile: Identifiable, Hashable {
    enum Category: String, Codable {
        case vet = "Vet"
        case daycare = "Daycare"
        case grooming = "Grooming"
        case boarding = "Boarding"
    }

    enum PartnershipStatus: String, Codable {
        case partner
        case nonPartner

        var label: String {
            switch self {
            case .partner: return "Partner"
            case .nonPartner: return "Non-Partner"
            }
        }
    }

    enum ListingType: String, Codable {
        case business = "Business"
        case individual = "Individual"
    }

    enum VetUrgency: String, CaseIterable, Codable {
        case routine = "Routine"
        case urgent = "Urgent"
        case emergency = "Emergency"
    }

    enum GroomingService: String, CaseIterable, Codable {
        case fullGroom = "Full Groom"
        case bathAndBrush = "Bath & Brush"
        case nailTrim = "Nail Trim"
    }

    enum VisitIntent: Hashable, Codable {
        case vet(reason: String, urgency: VetUrgency)
        case daycare(date: Date)
        case grooming(service: GroomingService, date: Date)
        case boarding(checkIn: Date, checkOut: Date)

        var summary: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            switch self {
            case let .vet(reason, urgency):
                let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                return "Vet visit (\(urgency.rawValue))\(trimmed.isEmpty ? "" : ": \(trimmed)")"
            case let .daycare(date):
                return "Daycare on \(formatter.string(from: date))"
            case let .grooming(service, date):
                return "\(service.rawValue) on \(formatter.string(from: date))"
            case let .boarding(checkIn, checkOut):
                let df = DateFormatter()
                df.dateStyle = .medium
                return "Boarding \(df.string(from: checkIn)) → \(df.string(from: checkOut))"
            }
        }
    }

    struct ReviewSummary: Hashable, Codable {
        let averageRating: Double
        let reviewCount: Int

        var ratingText: String { String(format: "%.1f", averageRating) }
    }

    let id: UUID
    let name: String
    let category: Category
    let distanceMiles: Double
    let partnershipStatus: PartnershipStatus
    let listingType: ListingType
    let summary: String
    let requirements: [String]
    let phoneNumber: String?
    let websiteURL: URL?
    let coordinate: LocationPoint?
    let reviews: ReviewSummary
    let acceptsAppointments: Bool
    let allowsMessaging: Bool

    static let sample: [BusinessProfile] = [
        .init(
            id: UUID(),
            name: "Canal Street Vet",
            category: .vet,
            distanceMiles: 1.2,
            partnershipStatus: .partner,
            listingType: .business,
            summary: "AAHA-accredited clinic with same-day urgent visits.",
            requirements: ["Rabies", "DHPP", "Recent fecal test"],
            phoneNumber: "2125550102",
            websiteURL: URL(string: "https://example.com/canal-street-vet"),
            coordinate: .init(latitude: 40.7193, longitude: -74.0005),
            reviews: .init(averageRating: 4.8, reviewCount: 231),
            acceptsAppointments: true,
            allowsMessaging: true
        ),
        .init(
            id: UUID(),
            name: "Pine & Paw Grooming",
            category: .grooming,
            distanceMiles: 2.8,
            partnershipStatus: .nonPartner,
            listingType: .business,
            summary: "Hand-scissor specialists and breed-specific grooming packages.",
            requirements: ["Rabies", "Bordetella"],
            phoneNumber: "2125550148",
            websiteURL: URL(string: "https://example.com/pine-paw-grooming"),
            coordinate: .init(latitude: 40.7341, longitude: -73.9962),
            reviews: .init(averageRating: 4.6, reviewCount: 112),
            acceptsAppointments: true,
            allowsMessaging: false
        ),
        .init(
            id: UUID(),
            name: "Happy Trails Boarding",
            category: .boarding,
            distanceMiles: 4.1,
            partnershipStatus: .partner,
            listingType: .business,
            summary: "Overnight suites, play yard webcams, and med administration.",
            requirements: ["Rabies", "Bordetella", "Canine influenza"],
            phoneNumber: "2125550161",
            websiteURL: URL(string: "https://example.com/happy-trails-boarding"),
            coordinate: .init(latitude: 40.7029, longitude: -74.0164),
            reviews: .init(averageRating: 4.7, reviewCount: 176),
            acceptsAppointments: true,
            allowsMessaging: true
        ),
        .init(
            id: UUID(),
            name: "Riley's Home Pet Sitting",
            category: .boarding,
            distanceMiles: 5.2,
            partnershipStatus: .nonPartner,
            listingType: .individual,
            summary: "Independent in-home boarding host with fenced yard and one-family-at-a-time stays.",
            requirements: ["Rabies", "Bordetella"],
            phoneNumber: nil,
            websiteURL: nil,
            coordinate: .init(latitude: 40.7441, longitude: -73.9798),
            reviews: .init(averageRating: 4.9, reviewCount: 58),
            acceptsAppointments: false,
            allowsMessaging: true
        )
    ]
}

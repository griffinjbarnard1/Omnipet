import Foundation

enum Species: String, Codable, CaseIterable {
    case dog = "Dog"
    case cat = "Cat"
}

struct PetPass: Identifiable, Hashable {
    enum VaccineStatus: String {
        case green
        case yellow
        case red

        var label: String {
            switch self {
            case .green: return "Ready"
            case .yellow: return "Expiring Soon"
            case .red: return "Needs Update"
            }
        }
    }

    let id: UUID
    let petName: String
    let breed: String
    let ageDescription: String
    let vaccineStatus: VaccineStatus
    var species: Species

    static let sample = PetPass(
        id: UUID(),
        petName: "Mochi",
        breed: "Mini Goldendoodle",
        ageDescription: "3 years",
        vaccineStatus: .yellow,
        species: .dog
    )
}

struct VaultDocument: Identifiable, Hashable {
    enum DocumentType: String {
        case medical = "Medical"
        case certificates = "Certificates"
        case identity = "Identity"
        case diet = "Diet"
    }

    let id: UUID
    let title: String
    let type: DocumentType
    let expiresOn: Date?

    static let sampleDocuments: [VaultDocument] = [
        .init(id: UUID(), title: "Rabies Vaccination", type: .medical, expiresOn: Self.date("2026-06-04")),
        .init(id: UUID(), title: "Bordetella Certificate", type: .certificates, expiresOn: Self.date("2026-05-11")),
        .init(id: UUID(), title: "Microchip Registration", type: .identity, expiresOn: nil),
        .init(id: UUID(), title: "Prescription Diet Notes", type: .diet, expiresOn: nil)
    ]

    private static func date(_ iso: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: iso)
    }
}

extension VaultDocument {
    /// Maps document titles to the canonical requirement key they satisfy.
    /// This avoids brittle substring stripping — each document type explicitly
    /// declares which requirement it fulfills.
    private static let titleToRequirementKey: [String: String] = [
        "rabies vaccination": "rabies",
        "rabies certificate": "rabies",
        "bordetella certificate": "bordetella",
        "bordetella vaccination": "bordetella",
        "dhpp vaccination": "dhpp",
        "dhpp certificate": "dhpp",
        "fvrcp vaccination": "fvrcp",
        "fvrcp certificate": "fvrcp",
        "canine influenza vaccination": "canine influenza",
        "canine influenza certificate": "canine influenza",
        "recent fecal test": "recent fecal test",
        "fecal test": "recent fecal test",
    ]

    var normalizedTitle: String {
        let lower = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.titleToRequirementKey[lower] ?? lower
    }

    var expirationText: String {
        guard let expiresOn else { return "No expiration" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return expiresOn < Date() ? "Expired \(f.string(from: expiresOn))" : "Expires \(f.string(from: expiresOn))"
    }

    var isExpired: Bool {
        guard let expiresOn else { return false }
        return expiresOn < Date()
    }
}

struct ShareActivityEvent: Identifiable, Hashable, Codable {
    enum Status: String, Codable {
        case sent = "Sent"
        case opened = "Opened"
        case actionNeeded = "Action Needed"
    }

    let id: UUID
    let businessName: String
    let detail: String
    let sentAtText: String
    let status: Status
    let sharedDocumentTitles: [String]
    let shareDurationLabel: String

    static let sampleEvents: [ShareActivityEvent] = [
        .init(id: UUID(), businessName: "Canal Street Vet", detail: "Intro pack sent with rabies certificate", sentAtText: "Today, 2:14 PM", status: .sent, sharedDocumentTitles: ["Rabies Vaccination"], shareDurationLabel: "24 hours"),
        .init(id: UUID(), businessName: "Pine & Paw Grooming", detail: "Business opened secure link", sentAtText: "Today, 10:31 AM", status: .opened, sharedDocumentTitles: ["Rabies Vaccination", "Bordetella Certificate"], shareDurationLabel: "7 days"),
        .init(id: UUID(), businessName: "Happy Trails Boarding", detail: "Missing distemper vaccine proof", sentAtText: "Yesterday, 6:07 PM", status: .actionNeeded, sharedDocumentTitles: [], shareDurationLabel: "24 hours")
    ]
}

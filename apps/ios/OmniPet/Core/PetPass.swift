import Foundation

enum Species: String, Codable, CaseIterable {
    case dog = "Dog"
    case cat = "Cat"
}

struct PetPass: Identifiable, Hashable, Codable {
    let id: UUID
    var petName: String
    var breed: String
    var ageDescription: String
    var species: Species

    static let sample = PetPass(
        id: UUID(),
        petName: "Mochi",
        breed: "Mini Goldendoodle",
        ageDescription: "3 years",
        species: .dog
    )
}

struct PetProfile: Identifiable, Hashable, Codable {
    let id: UUID
    var pass: PetPass

    init(id: UUID = UUID(), pass: PetPass) {
        self.id = id
        self.pass = pass
    }

    static let sample: [PetProfile] = [
        .init(pass: .sample),
        .init(pass: .init(id: UUID(), petName: "Luna", breed: "Domestic Shorthair", ageDescription: "5 years", species: .cat))
    ]
}

struct VaultDocument: Identifiable, Hashable, Codable {
    enum DocumentType: String, Codable, CaseIterable {
        case medical = "Medical"
        case certificates = "Certificates"
        case identity = "Identity"
        case diet = "Diet"
    }

    let id: UUID
    let petID: UUID
    let title: String
    let type: DocumentType
    let expiresOn: Date?

    static let sampleDocuments: [VaultDocument] = [
        .init(id: UUID(), petID: PetPass.sample.id, title: "Rabies Vaccination", type: .medical, expiresOn: Self.date("2026-06-04")),
        .init(id: UUID(), petID: PetPass.sample.id, title: "Bordetella Certificate", type: .certificates, expiresOn: Self.date("2026-05-11")),
        .init(id: UUID(), petID: PetPass.sample.id, title: "Microchip Registration", type: .identity, expiresOn: nil),
        .init(id: UUID(), petID: PetPass.sample.id, title: "Prescription Diet Notes", type: .diet, expiresOn: nil)
    ]

    private static func date(_ iso: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: iso)
    }
}

extension VaultDocument {
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

    var isExpiringSoon: Bool {
        guard let expiresOn, !isExpired else { return false }
        let horizon = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiresOn <= horizon
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
    let petID: UUID
    let detail: String
    let sentAt: Date
    let status: Status
    let sharedDocumentTitles: [String]
    let shareDurationLabel: String
    let policyVersion: String
    let serverMessageID: String

    var sentAtText: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.timeStyle = .short

        if cal.isDateInToday(sentAt) {
            return "Today, \(f.string(from: sentAt))"
        } else if cal.isDateInYesterday(sentAt) {
            return "Yesterday, \(f.string(from: sentAt))"
        } else {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: sentAt)
        }
    }

    static let sampleEvents: [ShareActivityEvent] = [
        .init(id: UUID(), businessName: "Canal Street Vet", petID: PetPass.sample.id, detail: "Intro pack sent with rabies certificate", sentAt: Date().addingTimeInterval(-3600), status: .sent, sharedDocumentTitles: ["Rabies Vaccination"], shareDurationLabel: "24 hours", policyVersion: "v1", serverMessageID: UUID().uuidString),
        .init(id: UUID(), businessName: "Pine & Paw Grooming", petID: PetPass.sample.id, detail: "Business opened secure link", sentAt: Date().addingTimeInterval(-7200), status: .opened, sharedDocumentTitles: ["Rabies Vaccination", "Bordetella Certificate"], shareDurationLabel: "7 days", policyVersion: "v1", serverMessageID: UUID().uuidString),
        .init(id: UUID(), businessName: "Happy Trails Boarding", petID: PetPass.sample.id, detail: "Missing distemper vaccine proof", sentAt: Date().addingTimeInterval(-86400), status: .actionNeeded, sharedDocumentTitles: [], shareDurationLabel: "24 hours", policyVersion: "v1", serverMessageID: UUID().uuidString)
    ]
}

struct SearchHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let query: String
    let createdAt: Date
}

import Foundation

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

    static let sample = PetPass(
        id: UUID(),
        petName: "Mochi",
        breed: "Mini Goldendoodle",
        ageDescription: "3 years",
        vaccineStatus: .yellow
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
    let expirationText: String

    static let sampleDocuments: [VaultDocument] = [
        .init(id: UUID(), title: "Rabies Vaccination", type: .medical, expirationText: "Expires Jun 04, 2026"),
        .init(id: UUID(), title: "Bordetella Certificate", type: .certificates, expirationText: "Expires May 11, 2026"),
        .init(id: UUID(), title: "Microchip Registration", type: .identity, expirationText: "No expiration"),
        .init(id: UUID(), title: "Prescription Diet Notes", type: .diet, expirationText: "Updated Mar 28, 2026")
    ]
}

extension VaultDocument {
    var normalizedTitle: String {
        title
            .lowercased()
            .replacingOccurrences(of: "vaccination", with: "")
            .replacingOccurrences(of: "certificate", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ShareActivityEvent: Identifiable, Hashable {
    enum Status: String {
        case sent = "Sent"
        case opened = "Opened"
        case actionNeeded = "Action Needed"
    }

    let id: UUID
    let businessName: String
    let detail: String
    let sentAtText: String
    let status: Status

    static let sampleEvents: [ShareActivityEvent] = [
        .init(id: UUID(), businessName: "Canal Street Vet", detail: "Intro pack sent with rabies certificate", sentAtText: "Today, 2:14 PM", status: .sent),
        .init(id: UUID(), businessName: "Pine & Paw Grooming", detail: "Business opened secure link", sentAtText: "Today, 10:31 AM", status: .opened),
        .init(id: UUID(), businessName: "Happy Trails Boarding", detail: "Missing distemper vaccine proof", sentAtText: "Yesterday, 6:07 PM", status: .actionNeeded)
    ]
}

import Foundation

@MainActor
final class AppState: ObservableObject {
    enum DiscoveryCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case vet = "Vet"
        case daycare = "Daycare"
        case grooming = "Grooming"
        case boarding = "Boarding"

        var id: String { rawValue }

        var businessCategory: BusinessProfile.Category? {
            switch self {
            case .all: return nil
            case .vet: return .vet
            case .daycare: return .daycare
            case .grooming: return .grooming
            case .boarding: return .boarding
            }
        }
    }

    @Published var discoveryQuery = ""
    @Published var selectedDiscoveryCategory: DiscoveryCategory = .all

    @Published private(set) var businesses: [BusinessProfile]
    @Published private(set) var petPass: PetPass
    @Published private(set) var documents: [VaultDocument]
    @Published private(set) var events: [ShareActivityEvent]

    init(
        businesses: [BusinessProfile] = BusinessProfile.sample,
        petPass: PetPass = .sample,
        documents: [VaultDocument] = VaultDocument.sampleDocuments,
        events: [ShareActivityEvent] = ShareActivityEvent.sampleEvents
    ) {
        self.businesses = businesses
        self.petPass = petPass
        self.documents = documents
        self.events = events
    }

    var filteredBusinesses: [BusinessProfile] {
        businesses
            .filter { business in
                guard let selected = selectedDiscoveryCategory.businessCategory else {
                    return true
                }
                return business.category == selected
            }
            .filter { business in
                guard !discoveryQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return true
                }
                let q = discoveryQuery.lowercased()
                return business.name.lowercased().contains(q)
                    || business.summary.lowercased().contains(q)
                    || business.requirements.joined(separator: " ").lowercased().contains(q)
            }
            .sorted { $0.distanceMiles < $1.distanceMiles }
    }

    func logCheckIn(for business: BusinessProfile) {
        let newEvent = ShareActivityEvent(
            id: UUID(),
            businessName: business.name,
            detail: "Check-In requested with \(documents.count) record(s)",
            sentAtText: "Just now",
            status: .sent
        )
        events.insert(newEvent, at: 0)
    }

    func sendVaultRecords() {
        let destination = businesses.first(where: { $0.partnershipStatus == .partner })?.name ?? "Selected business"
        let newEvent = ShareActivityEvent(
            id: UUID(),
            businessName: destination,
            detail: "Vault summary sent with \(documents.count) attached document(s)",
            sentAtText: "Just now",
            status: .sent
        )
        events.insert(newEvent, at: 0)
    }
}

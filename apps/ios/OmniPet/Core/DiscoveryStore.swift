import Foundation

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var query = "Groomers open on Sunday"
    @Published var selectedCategory: BusinessProfile.Category?
    @Published private(set) var businesses: [BusinessProfile] = BusinessProfile.sample
    @Published private(set) var petPass: PetPass = .sample
    @Published private(set) var documents: [VaultDocument] = VaultDocument.sampleDocuments
    @Published private(set) var activityEvents: [ShareActivityEvent] = ShareActivityEvent.sampleEvents

    var filteredBusinesses: [BusinessProfile] {
        businesses
            .filter { business in
                guard let selectedCategory else { return true }
                return business.category == selectedCategory
            }
            .filter { business in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return true }
                let normalized = trimmed.lowercased()
                return business.name.lowercased().contains(normalized)
                    || business.summary.lowercased().contains(normalized)
                    || business.category.rawValue.lowercased().contains(normalized)
            }
    }

    func availability(for business: BusinessProfile) -> RequirementAvailability {
        let available = Set(documents.map(\.normalizedTitle))
        let missing = business.requirements.filter { !available.contains($0.lowercased()) }
        return RequirementAvailability(
            missingRequirements: missing,
            isReadyForCheckIn: missing.isEmpty
        )
    }

    func checkIn(with business: BusinessProfile) {
        let availability = availability(for: business)
        let event = ShareActivityEvent(
            id: UUID(),
            businessName: business.name,
            detail: availability.isReadyForCheckIn
                ? "Discovery handshake complete with vault packet."
                : "Discovery handshake paused. Missing: \(availability.missingRequirements.joined(separator: ", "))",
            sentAtText: "Today, just now",
            status: availability.isReadyForCheckIn ? .sent : .actionNeeded
        )
        activityEvents.insert(event, at: 0)
    }
}

struct RequirementAvailability: Hashable {
    let missingRequirements: [String]
    let isReadyForCheckIn: Bool
}

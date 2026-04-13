import Foundation
import MapKit

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var selectedTab: AppTab = .discovery
    @Published var query = ""
    @Published var selectedCategory: BusinessProfile.Category? {
        didSet { scheduleRefresh() }
    }
    @Published private(set) var businesses: [BusinessProfile] = BusinessProfile.sample
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published private(set) var petPass: PetPass = .sample
    @Published private(set) var documents: [VaultDocument] = VaultDocument.sampleDocuments
    @Published private(set) var activityEvents: [ShareActivityEvent] = ShareActivityEvent.sampleEvents
    private var searchTask: Task<Void, Never>?

    var filteredBusinesses: [BusinessProfile] {
        businesses
            .filter { business in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return true }
                let normalized = trimmed.lowercased()
                return business.name.lowercased().contains(normalized)
                    || business.summary.lowercased().contains(normalized)
                    || business.category.rawValue.lowercased().contains(normalized)
            }
    }

    init() {
        scheduleRefresh(immediate: true)
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        scheduleRefresh()
    }

    func refreshNow() {
        scheduleRefresh(immediate: true)
    }

    private func scheduleRefresh(immediate: Bool = false) {
        searchTask?.cancel()
        searchTask = Task {
            if !immediate {
                try? await Task.sleep(for: .milliseconds(350))
            }
            guard !Task.isCancelled else { return }
            await refreshBusinesses()
        }
    }

    private func refreshBusinesses() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let live = try await loadLiveBusinesses()
            if live.isEmpty {
                businesses = BusinessProfile.sample
            } else {
                businesses = live
            }
        } catch {
            businesses = BusinessProfile.sample
            lastError = "Live search unavailable. Showing sample businesses."
        }
    }

    private func loadLiveBusinesses() async throws -> [BusinessProfile] {
        let terms = searchTerms()
        var collected: [BusinessProfile] = []
        for term in terms {
            let results = try await searchPlaces(term: term)
            collected.append(contentsOf: results)
        }

        let deduped = Dictionary(grouping: collected, by: \.name.lowercased())
            .compactMap { $0.value.min(by: { $0.distanceMiles < $1.distanceMiles }) }
            .sorted(by: { $0.distanceMiles < $1.distanceMiles })

        return Array(deduped.prefix(20))
    }

    private func searchTerms() -> [String] {
        switch selectedCategory {
        case .vet:
            return ["veterinarian"]
        case .daycare:
            return ["dog daycare", "pet daycare"]
        case .grooming:
            return ["pet groomer", "dog grooming"]
        case .boarding:
            return ["pet boarding", "dog boarding", "pet sitter in home"]
        case nil:
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return [trimmed] }
            return ["veterinarian", "dog daycare", "pet groomer", "pet boarding", "pet sitter in home"]
        }
    }

    private func searchPlaces(term: String) async throws -> [BusinessProfile] {
        var request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.resultTypes = [.pointOfInterest]
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { item in
            profile(from: item, fallbackTerm: term)
        }
    }

    private func profile(from item: MKMapItem, fallbackTerm: String) -> BusinessProfile? {
        guard let name = item.name else { return nil }
        let lower = "\(name) \(item.pointOfInterestCategory?.rawValue ?? "") \(fallbackTerm)".lowercased()

        let category = inferCategory(from: lower)
        if let selectedCategory, category != selectedCategory {
            return nil
        }

        let isIndividual = lower.contains("pet sitter")
            || lower.contains("in-home")
            || lower.contains("at home")

        let requirements: [String]
        switch category {
        case .vet: requirements = ["Rabies", "DHPP", "Recent fecal test"]
        case .daycare: requirements = ["Rabies", "Bordetella", "DHPP"]
        case .grooming: requirements = ["Rabies", "Bordetella"]
        case .boarding: requirements = ["Rabies", "Bordetella", "Canine influenza"]
        }

        return BusinessProfile(
            id: UUID(),
            name: name,
            category: category,
            distanceMiles: item.placemark.location?.distance(from: CLLocation(latitude: 40.7128, longitude: -74.0060)).map { $0 / 1609.34 } ?? 0,
            partnershipStatus: .nonPartner,
            listingType: isIndividual ? .individual : .business,
            summary: item.placemark.title ?? "Live internet listing via Apple Maps search.",
            requirements: requirements,
            phoneNumber: item.phoneNumber?.filter { $0.isNumber },
            websiteURL: item.url
        )
    }

    private func inferCategory(from string: String) -> BusinessProfile.Category {
        if string.contains("vet") || string.contains("veterinar") || string.contains("animal hospital") { return .vet }
        if string.contains("daycare") { return .daycare }
        if string.contains("groom") { return .grooming }
        return .boarding
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

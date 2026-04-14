import Foundation
import MapKit
import CoreLocation
import SwiftUI

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var selectedTab: AppTab = .discovery

    @Published var query: String {
        didSet {
            UserDefaults.standard.set(query, forKey: Self.queryKey)
            scheduleRefresh()
        }
    }

    @Published var selectedCategory: BusinessProfile.Category? {
        didSet {
            if let raw = selectedCategory?.rawValue {
                UserDefaults.standard.set(raw, forKey: Self.categoryKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.categoryKey)
            }
            scheduleRefresh()
        }
    }

    @Published private(set) var businesses: [BusinessProfile] = BusinessProfile.sample
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    @Published var petPass: PetPass = .sample {
        didSet { VaultPersistence.savePetPass(petPass) }
    }
    @Published private(set) var documents: [VaultDocument] = VaultDocument.sampleDocuments {
        didSet { VaultPersistence.saveDocuments(documents) }
    }
    @Published private(set) var activityEvents: [ShareActivityEvent] = ShareActivityEvent.sampleEvents
    @Published private(set) var userLocation: CLLocation?

    private var searchTask: Task<Void, Never>?
    private let locationProvider = LocationProvider()

    private static let queryKey = "omnipet.discovery.query"
    private static let categoryKey = "omnipet.discovery.category"

    private static let fallbackCenter = CLLocation(latitude: 40.7128, longitude: -74.0060)

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

    /// Computed vaccine status based on actual document state.
    var vaccineStatus: VaccineStatus {
        guard !documents.isEmpty else { return .red }
        let hasExpired = documents.contains { $0.isExpired }
        let hasExpiringSoon = documents.contains { $0.isExpiringSoon }
        if hasExpired { return .red }
        if hasExpiringSoon { return .yellow }
        return .green
    }

    init() {
        let defaults = UserDefaults.standard
        self.query = defaults.string(forKey: Self.queryKey) ?? ""
        if let raw = defaults.string(forKey: Self.categoryKey),
           let cat = BusinessProfile.Category(rawValue: raw) {
            self.selectedCategory = cat
        } else {
            self.selectedCategory = nil
        }

        // Restore persisted vault data; fall back to samples on first launch.
        if let storedPass = VaultPersistence.loadPetPass() {
            self.petPass = storedPass
        }
        if let storedDocs = VaultPersistence.loadDocuments() {
            self.documents = storedDocs
        }
        if let stored = ActivityPersistence.load(), !stored.isEmpty {
            self.activityEvents = stored
        }

        Task { [weak self] in
            guard let self else { return }
            let loc = await self.locationProvider.currentLocation()
            await MainActor.run {
                self.userLocation = loc
                self.scheduleRefresh(immediate: true)
            }
        }

        scheduleRefresh(immediate: true)
    }

    func updateQuery(_ newValue: String) {
        query = newValue
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

        let deduped = Dictionary(grouping: collected, by: { $0.name.lowercased() })
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

    private var centerLocation: CLLocation {
        userLocation ?? Self.fallbackCenter
    }

    private func searchPlaces(term: String) async throws -> [BusinessProfile] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.resultTypes = [.pointOfInterest]
        let center = centerLocation.coordinate
        request.region = MKCoordinateRegion(
            center: center,
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

        guard let category = inferCategory(from: lower) else { return nil }
        if let selectedCategory, category != selectedCategory {
            return nil
        }

        let isIndividual = lower.contains("pet sitter")
            || lower.contains("in-home")
            || lower.contains("at home")

        let reqs = requirements(for: category, species: petPass.species)

        let itemLocation = item.placemark.location
        let distanceMeters = itemLocation?.distance(from: centerLocation) ?? 0

        return BusinessProfile(
            id: UUID(),
            name: name,
            category: category,
            distanceMiles: distanceMeters / 1609.34,
            partnershipStatus: .nonPartner,
            listingType: isIndividual ? .individual : .business,
            summary: item.placemark.title ?? "Live internet listing via Apple Maps search.",
            requirements: reqs,
            phoneNumber: item.phoneNumber?.filter { $0.isNumber },
            websiteURL: item.url,
            coordinate: itemLocation?.coordinate
        )
    }

    func requirements(for category: BusinessProfile.Category, species: Species) -> [String] {
        switch (species, category) {
        case (.dog, .vet): return ["Rabies", "DHPP", "Recent fecal test"]
        case (.cat, .vet): return ["Rabies", "FVRCP", "Recent fecal test"]
        case (.dog, .daycare): return ["Rabies", "Bordetella", "DHPP"]
        case (.cat, .daycare): return ["Rabies", "FVRCP"]
        case (.dog, .grooming): return ["Rabies", "Bordetella"]
        case (.cat, .grooming): return ["Rabies"]
        case (.dog, .boarding): return ["Rabies", "Bordetella", "Canine influenza"]
        case (.cat, .boarding): return ["Rabies", "FVRCP"]
        }
    }

    func updateSpecies(_ species: Species) {
        petPass.species = species
        scheduleRefresh()
    }

    func addDocument(_ document: VaultDocument) {
        documents.append(document)
    }

    func deleteDocument(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
    }

    func deleteActivityEvent(at offsets: IndexSet) {
        activityEvents.remove(atOffsets: offsets)
        ActivityPersistence.save(activityEvents)
    }

    private func inferCategory(from string: String) -> BusinessProfile.Category? {
        if string.contains("vet") || string.contains("veterinar") || string.contains("animal hospital") { return .vet }
        if string.contains("daycare") { return .daycare }
        if string.contains("groom") { return .grooming }
        if string.contains("boarding") || string.contains("pet sitter") || string.contains("kennel") { return .boarding }
        return nil
    }

    func availability(for business: BusinessProfile) -> RequirementAvailability {
        let validTitles = Set(documents.filter { !$0.isExpired }.map(\.normalizedTitle))
        let expiredTitles = Set(documents.filter { $0.isExpired }.map(\.normalizedTitle))

        var missing: [String] = []
        var expired: [String] = []
        for req in business.requirements {
            let key = req.lowercased()
            if validTitles.contains(key) { continue }
            if expiredTitles.contains(key) { expired.append(req) } else { missing.append(req) }
        }

        let isBlocking = business.category != .vet
        let ready = !isBlocking || (missing.isEmpty && expired.isEmpty)

        return RequirementAvailability(
            missingRequirements: missing,
            expiredRequirements: expired,
            isReadyForCheckIn: ready,
            requirementsAreAdvisory: !isBlocking
        )
    }

    func checkIn(
        with business: BusinessProfile,
        intent: BusinessProfile.VisitIntent? = nil,
        sharedDocumentTitles: [String]? = nil,
        shareDurationLabel: String? = nil
    ) {
        let availability = availability(for: business)
        var parts: [String] = []
        if availability.isReadyForCheckIn {
            parts.append("Care Handshake complete with Vault packet.")
        } else {
            var gaps: [String] = []
            if !availability.missingRequirements.isEmpty {
                gaps.append("missing \(availability.missingRequirements.joined(separator: ", "))")
            }
            if !availability.expiredRequirements.isEmpty {
                gaps.append("expired \(availability.expiredRequirements.joined(separator: ", "))")
            }
            parts.append("Care Handshake paused. \(gaps.joined(separator: "; ")).")
        }
        if let intent {
            parts.append("Intent: \(intent.summary).")
        }
        let resolvedTitles = sharedDocumentTitles ?? documents.filter { !$0.isExpired }.map(\.title)
        let resolvedDuration = shareDurationLabel ?? "24 hours"
        let event = ShareActivityEvent(
            id: UUID(),
            businessName: business.name,
            detail: parts.joined(separator: " "),
            sentAt: Date(),
            status: availability.isReadyForCheckIn ? .sent : .actionNeeded,
            sharedDocumentTitles: resolvedTitles,
            shareDurationLabel: resolvedDuration
        )
        activityEvents.insert(event, at: 0)
        ActivityPersistence.save(activityEvents)
    }

    var hasExpiringSoonDocuments: Bool {
        documents.contains { $0.isExpiringSoon || $0.isExpired }
    }
}

// MARK: - Vaccine Status (computed, not stored)

enum VaccineStatus: String {
    case green, yellow, red

    var label: String {
        switch self {
        case .green: return "Ready"
        case .yellow: return "Expiring Soon"
        case .red: return "Needs Update"
        }
    }
}

struct RequirementAvailability: Hashable {
    let missingRequirements: [String]
    let expiredRequirements: [String]
    let isReadyForCheckIn: Bool
    let requirementsAreAdvisory: Bool
}

// MARK: - Persistence

enum ActivityPersistence {
    private static var fileURL: URL? { OmniPetStorage.url(for: "activity.json") }

    static func load() -> [ShareActivityEvent]? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ShareActivityEvent].self, from: data)
    }

    static func save(_ events: [ShareActivityEvent]) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum VaultPersistence {
    private static var docsURL: URL? { OmniPetStorage.url(for: "documents.json") }
    private static var petPassURL: URL? { OmniPetStorage.url(for: "petpass.json") }

    static func loadDocuments() -> [VaultDocument]? {
        guard let url = docsURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([VaultDocument].self, from: data)
    }

    static func saveDocuments(_ docs: [VaultDocument]) {
        guard let url = docsURL, let data = try? JSONEncoder().encode(docs) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func loadPetPass() -> PetPass? {
        guard let url = petPassURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PetPass.self, from: data)
    }

    static func savePetPass(_ pass: PetPass) {
        guard let url = petPassURL, let data = try? JSONEncoder().encode(pass) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

/// Shared storage directory under Application Support/omnipet/.
enum OmniPetStorage {
    private static let folderName = "omnipet"

    static func url(for fileName: String) -> URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }
}

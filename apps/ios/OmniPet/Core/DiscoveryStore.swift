import Foundation
import MapKit
import CoreLocation
import SwiftUI
import UserNotifications

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var selectedTab: AppTab = .discovery
    @Published var query: String {
        didSet {
            UserDefaults.standard.set(query, forKey: Self.queryKey)
            recordSearchHistoryIfNeeded(query)
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

    @Published private(set) var pets: [PetProfile] = PetProfile.sample {
        didSet { VaultPersistence.savePets(pets) }
    }
    @Published var selectedPetID: UUID {
        didSet { UserDefaults.standard.set(selectedPetID.uuidString, forKey: Self.selectedPetKey) }
    }

    @Published private(set) var documents: [VaultDocument] = VaultDocument.sampleDocuments {
        didSet {
            VaultPersistence.saveDocuments(documents)
            NotificationScheduler.scheduleExpirationNotifications(for: documents, pets: pets)
        }
    }
    @Published private(set) var activityEvents: [ShareActivityEvent] = ShareActivityEvent.sampleEvents {
        didSet { ActivityPersistence.save(activityEvents) }
    }
    @Published private(set) var searchHistory: [SearchHistoryEntry] = [] {
        didSet { SearchHistoryPersistence.save(searchHistory) }
    }

    @Published private(set) var userLocation: CLLocation?
    @Published var favoriteBusinessNames: Set<String> = [] {
        didSet { FavoritesPersistence.save(favoriteBusinessNames) }
    }
    @Published private(set) var cloudSyncEnabled: Bool = true
    @Published private(set) var accountEmail: String = "owner@omnipet.app"

    private var searchTask: Task<Void, Never>?
    private let locationProvider = LocationProvider()

    private static let queryKey = "omnipet.discovery.query"
    private static let categoryKey = "omnipet.discovery.category"
    private static let selectedPetKey = "omnipet.selected.pet"
    private static let fallbackCenter = CLLocation(latitude: 40.7128, longitude: -74.0060)

    init() {
        let defaults = UserDefaults.standard
        self.query = defaults.string(forKey: Self.queryKey) ?? ""
        if let raw = defaults.string(forKey: Self.categoryKey), let cat = BusinessProfile.Category(rawValue: raw) {
            self.selectedCategory = cat
        } else {
            self.selectedCategory = nil
        }

        if let loadedPets = VaultPersistence.loadPets(), !loadedPets.isEmpty {
            self.pets = loadedPets
        }
        let persistedPetID = defaults.string(forKey: Self.selectedPetKey).flatMap(UUID.init(uuidString:))
        self.selectedPetID = persistedPetID ?? self.pets.first?.id ?? UUID()
        if !self.pets.contains(where: { $0.id == self.selectedPetID }), let first = self.pets.first {
            self.selectedPetID = first.id
        }

        if let storedDocs = VaultPersistence.loadDocuments() { self.documents = storedDocs }
        if let stored = ActivityPersistence.load(), !stored.isEmpty { self.activityEvents = stored }
        self.favoriteBusinessNames = FavoritesPersistence.load()
        self.searchHistory = SearchHistoryPersistence.load()

        NotificationScheduler.requestAuthorizationIfNeeded()
        NotificationScheduler.scheduleExpirationNotifications(for: documents, pets: pets)

        Task { [weak self] in
            guard let self else { return }
            let loc = await self.locationProvider.currentLocation()
            self.userLocation = loc
            self.scheduleRefresh(immediate: true)
        }

        scheduleRefresh(immediate: true)
    }

    var petPass: PetPass {
        selectedPet?.pass ?? .sample
    }

    var selectedPet: PetProfile? {
        pets.first(where: { $0.id == selectedPetID })
    }

    var selectedPetDocuments: [VaultDocument] {
        documents.filter { $0.petID == selectedPetID }
    }

    var selectedPetActivity: [ShareActivityEvent] {
        activityEvents.filter { $0.petID == selectedPetID }
    }

    var recentSearches: [String] {
        Array(searchHistory.prefix(6)).map(\.query)
    }

    func selectPet(_ id: UUID) {
        guard pets.contains(where: { $0.id == id }) else { return }
        selectedPetID = id
        scheduleRefresh(immediate: true)
    }

    func addPet(_ pass: PetPass) {
        let profile = PetProfile(pass: pass)
        pets.append(profile)
        selectedPetID = profile.id
    }

    func removePet(_ id: UUID) {
        guard pets.count > 1 else { return }
        pets.removeAll { $0.id == id }
        documents.removeAll { $0.petID == id }
        activityEvents.removeAll { $0.petID == id }
        if selectedPetID == id, let fallback = pets.first?.id {
            selectedPetID = fallback
        }
    }

    func updateQuery(_ newValue: String) { query = newValue }
    func applyRecentSearch(_ term: String) { query = term }

    func clearSearchHistory() { searchHistory = [] }

    func refreshNow() { scheduleRefresh(immediate: true) }

    private func scheduleRefresh(immediate: Bool = false) {
        searchTask?.cancel()
        searchTask = Task {
            if !immediate { try? await Task.sleep(for: .milliseconds(300)) }
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
            businesses = live.isEmpty ? BusinessProfile.sample : live
        } catch {
            businesses = BusinessProfile.sample
            lastError = "Live search unavailable. Showing sample businesses."
        }
    }

    private func loadLiveBusinesses() async throws -> [BusinessProfile] {
        var collected: [BusinessProfile] = []
        for term in searchTerms() {
            let results = try await searchPlaces(term: term)
            collected.append(contentsOf: results)
        }

        let deduped = Dictionary(grouping: collected, by: { $0.name.lowercased() })
            .compactMap { $0.value.min(by: { $0.distanceMiles < $1.distanceMiles }) }
            .sorted(by: { $0.distanceMiles < $1.distanceMiles })
        return Array(deduped.prefix(24))
    }

    private func searchTerms() -> [String] {
        switch selectedCategory {
        case .vet: return ["veterinarian"]
        case .daycare: return ["dog daycare", "pet daycare"]
        case .grooming: return ["pet groomer", "dog grooming"]
        case .boarding: return ["pet boarding", "dog boarding", "pet sitter in home"]
        case nil:
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return [trimmed] }
            return ["veterinarian", "dog daycare", "pet groomer", "pet boarding"]
        }
    }

    private var centerLocation: CLLocation { userLocation ?? Self.fallbackCenter }

    private func searchPlaces(term: String) async throws -> [BusinessProfile] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.resultTypes = [.pointOfInterest]
        request.region = MKCoordinateRegion(center: centerLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3))
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { profile(from: $0, fallbackTerm: term) }
    }

    private func profile(from item: MKMapItem, fallbackTerm: String) -> BusinessProfile? {
        guard let name = item.name else { return nil }
        let lower = "\(name) \(item.pointOfInterestCategory?.rawValue ?? "") \(fallbackTerm)".lowercased()
        guard let category = inferCategory(from: lower) else { return nil }
        if let selectedCategory, category != selectedCategory { return nil }

        let isIndividual = lower.contains("pet sitter") || lower.contains("in-home") || lower.contains("at home")
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
            phoneNumber: item.phoneNumber?.filter(\.isNumber),
            websiteURL: item.url,
            coordinate: itemLocation.map { .init(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) },
            reviews: .init(averageRating: Double.random(in: 4.2...4.9), reviewCount: Int.random(in: 12...290)),
            acceptsAppointments: !isIndividual,
            allowsMessaging: true
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
        guard var profile = selectedPet else { return }
        profile.pass.species = species
        updatePet(profile)
        scheduleRefresh()
    }

    func addDocument(_ document: VaultDocument) { documents.append(document) }
    func updateDocument(_ document: VaultDocument) {
        guard let idx = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[idx] = document
    }
    func deleteDocument(at offsets: IndexSet) {
        let active = selectedPetDocuments
        let ids = offsets.map { active[$0].id }
        documents.removeAll { ids.contains($0.id) }
    }

    func updatePetPass(_ pass: PetPass) {
        guard var profile = selectedPet else { return }
        let speciesChanged = profile.pass.species != pass.species
        profile.pass = pass
        updatePet(profile)
        if speciesChanged { scheduleRefresh() }
    }

    private func updatePet(_ profile: PetProfile) {
        guard let idx = pets.firstIndex(where: { $0.id == profile.id }) else { return }
        pets[idx] = profile
    }

    func deleteActivityEvent(at offsets: IndexSet) {
        let active = selectedPetActivity
        let ids = offsets.map { active[$0].id }
        activityEvents.removeAll { ids.contains($0.id) }
    }
    func clearActivityEvents() { activityEvents.removeAll { $0.petID == selectedPetID } }
    func clearDocuments() { documents.removeAll { $0.petID == selectedPetID } }
    func clearFavorites() { favoriteBusinessNames.removeAll() }

    func toggleFavorite(_ businessName: String) {
        if favoriteBusinessNames.contains(businessName) { favoriteBusinessNames.remove(businessName) }
        else { favoriteBusinessNames.insert(businessName) }
    }
    func isFavorite(_ businessName: String) -> Bool { favoriteBusinessNames.contains(businessName) }

    var filteredBusinesses: [BusinessProfile] {
        businesses.filter { business in
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }
            let normalized = trimmed.lowercased()
            return business.name.lowercased().contains(normalized)
                || business.summary.lowercased().contains(normalized)
                || business.category.rawValue.lowercased().contains(normalized)
        }
    }

    var favoriteBusinesses: [BusinessProfile] { filteredBusinesses.filter { favoriteBusinessNames.contains($0.name) } }

    var hasCompletedCheckIn: Bool { activityEvents.contains { $0.petID == selectedPetID && $0.detail.contains("Care Handshake") } }

    private func inferCategory(from string: String) -> BusinessProfile.Category? {
        if string.contains("vet") || string.contains("veterinar") || string.contains("animal hospital") { return .vet }
        if string.contains("daycare") { return .daycare }
        if string.contains("groom") { return .grooming }
        if string.contains("boarding") || string.contains("pet sitter") || string.contains("kennel") { return .boarding }
        return nil
    }

    func availability(for business: BusinessProfile) -> RequirementAvailability {
        let docs = selectedPetDocuments
        let validTitles = Set(docs.filter { !$0.isExpired }.map(\.normalizedTitle))
        let expiredTitles = Set(docs.filter { $0.isExpired }.map(\.normalizedTitle))
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

    func logInteraction(businessName: String, detail: String, status: ShareActivityEvent.Status = .sent) {
        let event = ShareActivityEvent(
            id: UUID(),
            businessName: businessName,
            petID: selectedPetID,
            detail: detail,
            sentAt: Date(),
            status: status,
            sharedDocumentTitles: [],
            shareDurationLabel: "n/a",
            policyVersion: "v1",
            serverMessageID: UUID().uuidString
        )
        activityEvents.insert(event, at: 0)
    }

    func checkIn(with business: BusinessProfile, intent: BusinessProfile.VisitIntent? = nil, sharedDocumentTitles: [String]? = nil, shareDurationLabel: String? = nil) {
        let availability = availability(for: business)
        var parts: [String] = []
        if availability.isReadyForCheckIn { parts.append("Care Handshake complete with Vault packet.") }
        else {
            var gaps: [String] = []
            if !availability.missingRequirements.isEmpty { gaps.append("missing \(availability.missingRequirements.joined(separator: ", "))") }
            if !availability.expiredRequirements.isEmpty { gaps.append("expired \(availability.expiredRequirements.joined(separator: ", "))") }
            parts.append("Care Handshake paused. \(gaps.joined(separator: "; ")).")
        }
        if let intent { parts.append("Intent: \(intent.summary).") }

        let event = ShareActivityEvent(
            id: UUID(),
            businessName: business.name,
            petID: selectedPetID,
            detail: parts.joined(separator: " "),
            sentAt: Date(),
            status: availability.isReadyForCheckIn ? .sent : .actionNeeded,
            sharedDocumentTitles: sharedDocumentTitles ?? selectedPetDocuments.filter { !$0.isExpired }.map(\.title),
            shareDurationLabel: shareDurationLabel ?? "24 hours",
            policyVersion: "v1",
            serverMessageID: UUID().uuidString
        )

        activityEvents.insert(event, at: 0)
        if cloudSyncEnabled {
            Task { await BusinessInboxSimulator.shared.receive(event: event) }
        }
        NotificationScheduler.scheduleStatusNotification(for: event)
    }

    var hasExpiringSoonDocuments: Bool { selectedPetDocuments.contains { $0.isExpiringSoon || $0.isExpired } }

    var vaccineStatus: VaccineStatus {
        let docs = selectedPetDocuments
        guard !docs.isEmpty else { return .red }
        if docs.contains(where: { $0.isExpired }) { return .red }
        if docs.contains(where: { $0.isExpiringSoon }) { return .yellow }
        return .green
    }

    private func recordSearchHistoryIfNeeded(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        if searchHistory.first?.query.lowercased() == trimmed.lowercased() { return }
        searchHistory.removeAll { $0.query.lowercased() == trimmed.lowercased() }
        searchHistory.insert(.init(id: UUID(), query: trimmed, createdAt: Date()), at: 0)
        searchHistory = Array(searchHistory.prefix(30))
    }
}

enum VaccineStatus: String { case green, yellow, red
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
    private static var petsURL: URL? { OmniPetStorage.url(for: "pets.json") }

    static func loadDocuments() -> [VaultDocument]? {
        guard let url = docsURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([VaultDocument].self, from: data)
    }
    static func saveDocuments(_ docs: [VaultDocument]) {
        guard let url = docsURL, let data = try? JSONEncoder().encode(docs) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func loadPets() -> [PetProfile]? {
        guard let url = petsURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([PetProfile].self, from: data)
    }
    static func savePets(_ pets: [PetProfile]) {
        guard let url = petsURL, let data = try? JSONEncoder().encode(pets) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum SearchHistoryPersistence {
    private static var fileURL: URL? { OmniPetStorage.url(for: "search-history.json") }
    static func load() -> [SearchHistoryEntry] {
        guard let url = fileURL, let data = try? Data(contentsOf: url), let values = try? JSONDecoder().decode([SearchHistoryEntry].self, from: data) else { return [] }
        return values
    }
    static func save(_ entries: [SearchHistoryEntry]) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum FavoritesPersistence {
    private static var fileURL: URL? { OmniPetStorage.url(for: "favorites.json") }
    static func load() -> Set<String> {
        guard let url = fileURL, let data = try? Data(contentsOf: url), let names = try? JSONDecoder().decode(Set<String>.self, from: data) else { return [] }
        return names
    }
    static func save(_ names: Set<String>) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(names) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

enum OmniPetStorage {
    private static let folderName = "omnipet"
    static func url(for fileName: String) -> URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try? fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir.appendingPathComponent(fileName)
    }
}

actor BusinessInboxSimulator {
    static let shared = BusinessInboxSimulator()
    private(set) var receivedEventIDs: [UUID] = []

    func receive(event: ShareActivityEvent) {
        receivedEventIDs.append(event.id)
    }
}

enum NotificationScheduler {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleExpirationNotifications(for documents: [VaultDocument], pets: [PetProfile]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["omnipet.expiring-soon"])
        let expiringSoon = documents.filter { $0.isExpiringSoon }
        guard !expiringSoon.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "Pet records expiring soon"
        content.body = "\(expiringSoon.count) document(s) need attention in your Vault."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let req = UNNotificationRequest(identifier: "omnipet.expiring-soon", content: content, trigger: trigger)
        center.add(req)
    }

    static func scheduleStatusNotification(for event: ShareActivityEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Check-in update"
        content.body = "\(event.businessName): \(event.status.rawValue)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req = UNNotificationRequest(identifier: "omnipet.status.\(event.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

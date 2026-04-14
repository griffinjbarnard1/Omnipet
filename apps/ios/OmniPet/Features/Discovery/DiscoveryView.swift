import SwiftUI
import MapKit
import CoreLocation

struct DiscoveryView: View {
    enum ViewMode: String, CaseIterable, Hashable {
        case list = "List"
        case map = "Map"
    }

    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var viewMode: ViewMode = .list
    @State private var selectedBusiness: BusinessProfile?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )

    var body: some View {
        NavigationStack {
            Group {
                switch viewMode {
                case .list: listContent
                case .map: mapContent
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Discover")
            .navigationDestination(item: $selectedBusiness) { business in
                BusinessProfileView(business: business)
            }
        }
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            ForEach(discoveryStore.filteredBusinesses) { business in
                if let coord = business.coordinate {
                    Annotation(business.name, coordinate: coord) {
                        Button {
                            selectedBusiness = business
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(business.partnershipStatus == .partner ? OmniPetColor.emerald : OmniPetColor.grayPin)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(business.name), \(business.category.rawValue), \(String(format: "%.1f", business.distanceMiles)) miles")
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: discoveryStore.filteredBusinesses.map(\.id)) {
            recenterMap()
        }
        .onAppear {
            recenterMap()
        }
    }

    private var listContent: some View {
        List {
                Section {
                    TextField(
                        "Search vets, daycare, grooming, boarding, pet sitters…",
                        text: Binding(
                            get: { discoveryStore.query },
                            set: { discoveryStore.updateQuery($0) }
                        )
                    )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Categories") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryTag(label: "Vet", symbol: "stethoscope", category: .vet)
                            categoryTag(label: "Daycare", symbol: "figure.2.and.child.holdinghands", category: .daycare)
                            categoryTag(label: "Grooming", symbol: "scissors", category: .grooming)
                            categoryTag(label: "Boarding", symbol: "house", category: .boarding)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if discoveryStore.hasExpiringSoonDocuments {
                    Section("Smart Suggestions") {
                        Label("Expiring Soon? Send an updated record pack", systemImage: "sparkles")
                            .foregroundStyle(OmniPetColor.warning)
                    }
                }

                Section("Care Handshake") {
                    flowStageChip(
                        title: "Find",
                        detail: "Search nearby pet services by category or natural language.",
                        symbol: "magnifyingglass"
                    )
                    flowStageChip(
                        title: "Prepare",
                        detail: "Review requirements and fix any missing records in Vault.",
                        symbol: "checklist"
                    )
                    flowStageChip(
                        title: "Share",
                        detail: "Check-in with Vault to send a professional packet.",
                        symbol: "paperplane"
                    )
                }

                Section("Nearby Businesses (\(discoveryStore.filteredBusinesses.count))") {
                    if discoveryStore.isLoading {
                        Label("Searching live internet listings…", systemImage: "network")
                            .foregroundStyle(.secondary)
                    }
                    if let error = discoveryStore.lastError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(OmniPetColor.warning)
                    }
                    if !discoveryStore.isLoading && discoveryStore.filteredBusinesses.isEmpty {
                        ContentUnavailableView(
                            "No results",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term or clear your category filter.")
                        )
                    }
                    ForEach(discoveryStore.filteredBusinesses) { business in
                        Button {
                            selectedBusiness = business
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(business.name)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(business.distanceMiles, specifier: "%.1f") mi")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 6) {
                                    Text(business.category.rawValue)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(OmniPetColor.emerald.opacity(0.15), in: Capsule())
                                        .foregroundStyle(OmniPetColor.emerald)
                                    if business.listingType == .individual {
                                        Text("Individual")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(OmniPetColor.warning.opacity(0.15), in: Capsule())
                                            .foregroundStyle(OmniPetColor.warning)
                                    }
                                }
                                Text(business.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Label(business.partnershipStatus.label, systemImage: business.partnershipStatus == .partner ? "checkmark.seal.fill" : "mappin")
                                    .font(.caption)
                                    .foregroundStyle(business.partnershipStatus == .partner ? OmniPetColor.emerald : OmniPetColor.grayPin)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
        }
        .refreshable {
            discoveryStore.refreshNow()
        }
    }

    private func categoryTag(label: String, symbol: String, category: BusinessProfile.Category) -> some View {
        let isSelected = discoveryStore.selectedCategory == category
        return Label(label, systemImage: symbol)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(OmniPetColor.emerald.opacity(0.2)) : AnyShapeStyle(.quaternary), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? OmniPetColor.emerald : .clear, lineWidth: 1)
            }
            .onTapGesture {
                discoveryStore.selectedCategory = discoveryStore.selectedCategory == category ? nil : category
            }
    }

    private func recenterMap() {
        let coords = discoveryStore.filteredBusinesses.compactMap(\.coordinate)
        guard let first = coords.first else { return }
        if coords.count == 1 {
            cameraPosition = .region(MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)))
            return
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max(0.02, (maxLat - minLat) * 1.4), longitudeDelta: max(0.02, (maxLon - minLon) * 1.4))
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func flowStageChip(title: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

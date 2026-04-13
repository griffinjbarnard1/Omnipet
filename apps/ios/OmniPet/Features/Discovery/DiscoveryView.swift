import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore

    var body: some View {
        NavigationStack {
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

                Section("Smart Suggestions") {
                    Label("Expiring Soon? Send an updated record pack", systemImage: "sparkles")
                        .foregroundStyle(OmniPetColor.warning)
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

                Section("Nearby Businesses") {
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
                        NavigationLink {
                            BusinessProfileView(business: business)
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
                                Text(business.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Label(business.partnershipStatus.label, systemImage: business.partnershipStatus == .partner ? "checkmark.seal.fill" : "mappin")
                                    .font(.caption)
                                    .foregroundStyle(business.partnershipStatus == .partner ? OmniPetColor.emerald : OmniPetColor.grayPin)
                                Text(business.listingType.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .refreshable {
                discoveryStore.refreshNow()
            }
        }
    }

    private func categoryTag(label: String, symbol: String, category: BusinessProfile.Category) -> some View {
        let isSelected = discoveryStore.selectedCategory == category
        Label(label, systemImage: symbol)
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

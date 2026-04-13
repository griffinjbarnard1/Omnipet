import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search vets, grooming, boarding…", text: $appState.discoveryQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Categories") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AppState.DiscoveryCategory.allCases) { category in
                                categoryTag(for: category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Smart Suggestions") {
                    Label("Expiring Soon? Send an updated record pack", systemImage: "sparkles")
                        .foregroundStyle(OmniPetColor.warning)
                }

                Section("Nearby Businesses") {
                    if appState.filteredBusinesses.isEmpty {
                        ContentUnavailableView(
                            "No matching businesses",
                            systemImage: "mappin.slash",
                            description: Text("Try a broader query or switch to another category.")
                        )
                    }

                    ForEach(appState.filteredBusinesses) { business in
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
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Discovery")
        }
    }

    private func categoryTag(for category: AppState.DiscoveryCategory) -> some View {
        let isSelected = appState.selectedDiscoveryCategory == category

        return Button {
            appState.selectedDiscoveryCategory = category
        } label: {
            Text(category.rawValue)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? OmniPetColor.emerald.opacity(0.2) : Color.quaternary, in: Capsule())
                .foregroundStyle(isSelected ? OmniPetColor.emerald : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

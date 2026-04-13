import SwiftUI

struct DiscoveryView: View {
    @State private var query = "Groomers open on Sunday"
    private let businesses = BusinessProfile.sample

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search vets, grooming, boarding…", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Categories") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryTag(label: "Vet", symbol: "stethoscope")
                            categoryTag(label: "Daycare", symbol: "figure.2.and.child.holdinghands")
                            categoryTag(label: "Grooming", symbol: "scissors")
                            categoryTag(label: "Boarding", symbol: "house")
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Smart Suggestions") {
                    Label("Expiring Soon? Send an updated record pack", systemImage: "sparkles")
                        .foregroundStyle(OmniPetColor.warning)
                }

                Section("Nearby Businesses") {
                    ForEach(businesses) { business in
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

    private func categoryTag(label: String, symbol: String) -> some View {
        Label(label, systemImage: symbol)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: Capsule())
    }
}

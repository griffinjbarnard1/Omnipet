import SwiftUI

struct BusinessProfileView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    let business: BusinessProfile

    var body: some View {
        let availability = discoveryStore.availability(for: business)
        List {
            Section("Business") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(business.name)
                            .font(.title3.bold())
                        Spacer()
                        Text(business.category.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                    Text(business.summary)
                        .foregroundStyle(.secondary)
                    Label(business.partnershipStatus.label, systemImage: business.partnershipStatus == .partner ? "checkmark.seal.fill" : "mappin")
                        .foregroundStyle(business.partnershipStatus == .partner ? OmniPetColor.emerald : OmniPetColor.grayPin)
                }
                .padding(.vertical, 4)
            }

            Section("Requirements Checklist") {
                ForEach(business.requirements, id: \.self) { requirement in
                    let isMissing = availability.missingRequirements.contains(requirement)
                    Label(requirement, systemImage: isMissing ? "exclamationmark.circle" : "checkmark.circle")
                        .foregroundStyle(isMissing ? OmniPetColor.warning : .primary)
                }
            }

            if !availability.isReadyForCheckIn {
                Section("Gaps Identified") {
                    Text("Add missing records in Vault before check-in can be completed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(availability.missingRequirements, id: \.self) { requirement in
                        Label(requirement, systemImage: "xmark.circle")
                            .foregroundStyle(OmniPetColor.danger)
                    }
                }
            }

            Section("Handshake") {
                Button("Check-In with Vault") {
                    discoveryStore.checkIn(with: business)
                }
                .disabled(!availability.isReadyForCheckIn)
                .buttonStyle(.borderedProminent)
                Button("Call Business") { }
                Button("Open Website") { }
            }
        }
        .navigationTitle("Business Profile")
    }
}

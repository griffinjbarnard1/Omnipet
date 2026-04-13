import SwiftUI

struct BusinessProfileView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @Environment(\.openURL) private var openURL
    @State private var didShowCheckInConfirmation = false
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
                        Text("\(business.category.rawValue) · \(business.listingType.rawValue)")
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
                    Button("Fix in Vault") {
                        discoveryStore.selectedTab = .vault
                    }
                }
            }

            Section("Handshake") {
                Button("Check-In with Vault") {
                    discoveryStore.checkIn(with: business)
                    didShowCheckInConfirmation = true
                }
                .disabled(!availability.isReadyForCheckIn)
                .buttonStyle(.borderedProminent)
                Button("Call Business") {
                    guard
                        let number = business.phoneNumber,
                        let url = URL(string: "tel://\(number)")
                    else { return }
                    openURL(url)
                }
                .disabled(business.phoneNumber == nil)
                Button("Open Website") {
                    guard let url = business.websiteURL else { return }
                    openURL(url)
                }
                .disabled(business.websiteURL == nil)
            }
        }
        .navigationTitle("Business Profile")
        .alert("Check-in sent", isPresented: $didShowCheckInConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your Vault packet was logged in Activity.")
        }
    }
}

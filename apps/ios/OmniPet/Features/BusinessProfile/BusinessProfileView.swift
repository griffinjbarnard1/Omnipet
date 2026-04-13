import SwiftUI

struct BusinessProfileView: View {
    @EnvironmentObject private var appState: AppState
    let business: BusinessProfile

    var body: some View {
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
                    Label(requirement, systemImage: "checkmark.circle")
                }
            }

            Section("Handshake") {
                Button("Check-In with Vault") {
                    appState.logCheckIn(for: business)
                }
                .buttonStyle(.borderedProminent)
                Button("Call Business") { }
                Button("Open Website") { }
            }
        }
        .navigationTitle("Business Profile")
    }
}

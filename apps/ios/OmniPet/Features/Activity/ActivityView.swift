import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore

    var body: some View {
        NavigationStack {
            if discoveryStore.activityEvents.isEmpty {
                ContentUnavailableView(
                    "No Activity Yet",
                    systemImage: "paperplane",
                    description: Text("Check in with a business via the Discovery tab to send your first Vault packet.")
                )
                .navigationTitle("Activity")
            } else {
                List {
                    ForEach(discoveryStore.activityEvents) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.businessName)
                                    .font(.headline)
                                Spacer()
                                Text(event.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color(for: event.status).opacity(0.15), in: Capsule())
                                    .foregroundStyle(color(for: event.status))
                                    .accessibilityLabel("Status: \(event.status.rawValue)")
                            }
                            Text(event.detail)
                                .font(.subheadline)
                            if !event.sharedDocumentTitles.isEmpty {
                                Text("Shared: \(event.sharedDocumentTitles.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Access: \(event.shareDurationLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(event.sentAtText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        discoveryStore.deleteActivityEvent(at: offsets)
                    }
                }
                .navigationTitle("Activity")
            }
        }
    }

    private func color(for status: ShareActivityEvent.Status) -> Color {
        switch status {
        case .sent: return OmniPetColor.grayPin
        case .opened: return OmniPetColor.emerald
        case .actionNeeded: return OmniPetColor.danger
        }
    }
}

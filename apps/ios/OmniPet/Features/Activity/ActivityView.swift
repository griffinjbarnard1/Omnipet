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
                        NavigationLink(value: event) {
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
                                    .lineLimit(2)
                                Text(event.sentAtText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { offsets in
                        discoveryStore.deleteActivityEvent(at: offsets)
                    }
                }
                .navigationTitle("Activity")
                .navigationDestination(for: ShareActivityEvent.self) { event in
                    ActivityDetailView(event: event)
                }
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

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let event: ShareActivityEvent

    var body: some View {
        List {
            Section("Business") {
                HStack {
                    Text(event.businessName)
                        .font(.title3.bold())
                    Spacer()
                    Text(event.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(statusColor)
                }
            }

            Section("Details") {
                Text(event.detail)
                    .font(.subheadline)
            }

            if !event.sharedDocumentTitles.isEmpty {
                Section("Shared Documents") {
                    ForEach(event.sharedDocumentTitles, id: \.self) { title in
                        Label(title, systemImage: "doc.text")
                    }
                }
            }

            Section("Share Settings") {
                HStack {
                    Text("Access Duration")
                    Spacer()
                    Text(event.shareDurationLabel)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Sent")
                    Spacer()
                    Text(event.sentAtText)
                        .foregroundStyle(.secondary)
                }
            }

            if event.status == .actionNeeded {
                Section {
                    Label("This handshake has gaps — update your records in the Vault and try again.", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(OmniPetColor.warning)
                }
            }
        }
        .navigationTitle(event.businessName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch event.status {
        case .sent: return OmniPetColor.grayPin
        case .opened: return OmniPetColor.emerald
        case .actionNeeded: return OmniPetColor.danger
        }
    }
}

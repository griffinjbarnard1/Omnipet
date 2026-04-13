import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                if appState.events.isEmpty {
                    ContentUnavailableView(
                        "No activity yet",
                        systemImage: "clock.badge.xmark",
                        description: Text("Shared records and check-ins will appear here.")
                    )
                }

                ForEach(appState.events) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(event.businessName)
                                .font(.headline)
                            Spacer()
                            Text(event.status.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(color(for: event.status))
                        }
                        Text(event.detail)
                            .font(.subheadline)
                        Text(event.sentAtText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Activity")
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

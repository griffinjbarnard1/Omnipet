import SwiftUI

struct ActivityView: View {
    private let events = ShareActivityEvent.sampleEvents

    var body: some View {
        NavigationStack {
            List(events) { event in
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

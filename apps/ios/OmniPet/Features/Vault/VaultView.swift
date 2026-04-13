import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var isPresentingScanner = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pet Pass") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(discoveryStore.petPass.petName)
                            .font(.title3.bold())
                        Text("\(discoveryStore.petPass.breed) · \(discoveryStore.petPass.ageDescription)")
                            .foregroundStyle(.secondary)
                        Text(discoveryStore.petPass.vaccineStatus.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(statusColor)
                    }
                    .padding(.vertical, 8)
                }

                Section("Documents") {
                    ForEach(discoveryStore.documents) { document in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.title)
                                .font(.headline)
                            Text("\(document.type.rawValue) · \(document.expirationText)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("Scan Document") {
                        isPresentingScanner = true
                    }
                    .buttonStyle(.bordered)

                    Button("Send Records") { }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Vault")
            .sheet(isPresented: $isPresentingScanner) {
                NavigationStack {
                    ScannerView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    isPresentingScanner = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var statusColor: Color {
        switch discoveryStore.petPass.vaccineStatus {
        case .green: return OmniPetColor.emerald
        case .yellow: return OmniPetColor.warning
        case .red: return OmniPetColor.danger
        }
    }
}

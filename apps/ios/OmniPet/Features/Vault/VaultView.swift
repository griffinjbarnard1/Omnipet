import SwiftUI

struct VaultView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isPresentingScanner = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pet Pass") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(appState.petPass.petName)
                            .font(.title3.bold())
                        Text("\(appState.petPass.breed) · \(appState.petPass.ageDescription)")
                            .foregroundStyle(.secondary)
                        Text(appState.petPass.vaccineStatus.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(statusColor)
                    }
                    .padding(.vertical, 8)
                }

                Section("Documents") {
                    ForEach(appState.documents) { document in
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

                    Button("Send Records") {
                        appState.sendVaultRecords()
                    }
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
        switch appState.petPass.vaccineStatus {
        case .green: return OmniPetColor.emerald
        case .yellow: return OmniPetColor.warning
        case .red: return OmniPetColor.danger
        }
    }
}

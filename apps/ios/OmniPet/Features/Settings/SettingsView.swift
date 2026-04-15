import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var showResetOnboardingConfirm = false
    @State private var showClearActivityConfirm = false
    @State private var showClearDocumentsConfirm = false
    @State private var showResetAllConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pet") {
                    HStack {
                        Image(systemName: discoveryStore.petPass.species == .dog ? "dog.fill" : "cat.fill")
                            .font(.title2)
                            .foregroundStyle(OmniPetColor.emerald)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(discoveryStore.petPass.petName)
                                .font(.headline)
                            Text("\(discoveryStore.petPass.breed) · \(discoveryStore.petPass.ageDescription)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Data") {
                    HStack {
                        Text("Pets")
                        Spacer()
                        Text("\(discoveryStore.pets.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Documents (active pet)")
                        Spacer()
                        Text("\(discoveryStore.selectedPetDocuments.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Activity Events")
                        Spacer()
                        Text("\(discoveryStore.selectedPetActivity.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Favorites")
                        Spacer()
                        Text("\(discoveryStore.favoriteBusinessNames.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Actions") {
                    Button("Replay Onboarding") {
                        showResetOnboardingConfirm = true
                    }
                    Button("Clear Activity History", role: .destructive) {
                        showClearActivityConfirm = true
                    }
                    .disabled(discoveryStore.selectedPetActivity.isEmpty)
                    Button("Clear All Documents", role: .destructive) {
                        showClearDocumentsConfirm = true
                    }
                    .disabled(discoveryStore.selectedPetDocuments.isEmpty)
                }

                Section("Danger Zone") {
                    Button("Reset Everything", role: .destructive) {
                        showResetAllConfirm = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Replay Onboarding?", isPresented: $showResetOnboardingConfirm, titleVisibility: .visible) {
                Button("Replay") {
                    UserDefaults.standard.set(false, forKey: "omnipet.onboarding.completed")
                    discoveryStore.selectedTab = .discovery
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The onboarding flow will show next time you open the app.")
            }
            .confirmationDialog("Clear Activity?", isPresented: $showClearActivityConfirm, titleVisibility: .visible) {
                Button("Clear All Activity", role: .destructive) {
                    discoveryStore.clearActivityEvents()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all check-in history.")
            }
            .confirmationDialog("Clear Documents?", isPresented: $showClearDocumentsConfirm, titleVisibility: .visible) {
                Button("Clear All Documents", role: .destructive) {
                    discoveryStore.clearDocuments()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all vault documents.")
            }
            .confirmationDialog("Reset Everything?", isPresented: $showResetAllConfirm, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) {
                    discoveryStore.clearDocuments()
                    discoveryStore.clearActivityEvents()
                    discoveryStore.clearFavorites()
                    discoveryStore.updatePetPass(.sample)
                    UserDefaults.standard.set(false, forKey: "omnipet.onboarding.completed")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all documents, activity, favorites, and reset your pet pass. This cannot be undone.")
            }
        }
    }
}

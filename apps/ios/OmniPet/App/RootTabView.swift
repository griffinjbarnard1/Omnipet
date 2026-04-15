import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    @State private var showOnboarding = false

    private var actionNeededCount: Int {
        discoveryStore.activityEvents.filter { $0.status == .actionNeeded }.count
    }

    var body: some View {
        TabView(selection: $discoveryStore.selectedTab) {
            DiscoveryView()
                .tag(AppTab.discovery)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            VaultView()
                .tag(AppTab.vault)
                .tabItem {
                    Label("Vault", systemImage: "wallet.pass")
                }

            ActivityView()
                .tag(AppTab.activity)
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
                .badge(actionNeededCount > 0 ? actionNeededCount : 0)

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "omnipet.onboarding.completed") {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "omnipet.onboarding.completed")
                showOnboarding = false
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore
    let onComplete: () -> Void

    @State private var page = 0
    @State private var petName = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var species: Species = .dog

    var body: some View {
        NavigationStack {
            TabView(selection: $page) {
                // Page 1: Welcome
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(OmniPetColor.emerald)
                    Text("Welcome to OmniPet")
                        .font(.largeTitle.bold())
                    Text("Your pet's portable care passport.\nFind providers, share records, and never re-enter vaccine info again.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                    Button("Get Started") {
                        withAnimation { page = 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 40)
                }
                .tag(0)

                // Page 2: Set up pet
                Form {
                    Section {
                        VStack(spacing: 4) {
                            Image(systemName: "dog")
                                .font(.system(size: 40))
                                .foregroundStyle(OmniPetColor.emerald)
                            Text("Set Up Your Pet")
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }

                    Section("Pet Details") {
                        TextField("Pet name", text: $petName)
                            .textInputAutocapitalization(.words)
                        TextField("Breed (e.g. Labrador)", text: $breed)
                            .textInputAutocapitalization(.words)
                        TextField("Age (e.g. 3 years)", text: $age)
                    }

                    Section("Species") {
                        Picker("Species", selection: $species) {
                            ForEach(Species.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Button("Save & Start Discovering") {
                            let trimmedName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedName.isEmpty {
                                let pass = PetPass(
                                    id: UUID(),
                                    petName: trimmedName,
                                    breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
                                    ageDescription: age.trimmingCharacters(in: .whitespacesAndNewlines),
                                    species: species
                                )
                                discoveryStore.updatePetPass(pass)
                            }
                            onComplete()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Section {
                        Button("Skip for now") {
                            onComplete()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                    }
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .interactiveDismissDisabled()
        }
    }
}

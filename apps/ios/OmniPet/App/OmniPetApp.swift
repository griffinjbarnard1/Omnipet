import SwiftUI

@main
struct OmniPetApp: App {
    @StateObject private var discoveryStore = DiscoveryStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(discoveryStore)
        }
    }
}

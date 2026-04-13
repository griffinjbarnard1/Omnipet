import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            DiscoveryView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            VaultView()
                .tabItem {
                    Label("Vault", systemImage: "wallet.pass")
                }

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

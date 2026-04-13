import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var discoveryStore: DiscoveryStore

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
        }
    }
}

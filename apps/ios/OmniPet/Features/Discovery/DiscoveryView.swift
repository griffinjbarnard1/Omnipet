import SwiftUI

struct DiscoveryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Action Cards") {
                    Text("Find a Vet")
                    Text("Book Daycare")
                    Text("Local Groomers")
                    Text("Boarding")
                }

                Section("Smart Suggestions") {
                    Text("Expiring Soon?")
                }
            }
            .navigationTitle("Search anywhere…")
        }
    }
}

import SwiftUI

struct BusinessProfileView: View {
    var body: some View {
        List {
            Section("Business") {
                Text("AI-enriched profile")
                Text("Ratings, phone, website")
            }
            Section("Handshake") {
                Button("Check-In with Vault") { }
            }
        }
        .navigationTitle("Business Profile")
    }
}

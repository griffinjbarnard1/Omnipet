import SwiftUI

struct VaultView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Pet Pass") {
                    Text("Holographic Pet Pass")
                    Text("Vaccine status badge")
                }

                Section("Documents") {
                    Text("Medical")
                    Text("Certificates")
                    Text("Identity")
                    Text("Recipes / Diet")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Send Records") { }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .navigationTitle("Vault")
        }
    }
}

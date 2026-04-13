import SwiftUI

struct ScannerView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Smart Scanner")
                .font(.title2.bold())
            Text("Needs more light for data extraction.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

import SwiftUI

struct ScannerView: View {
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 24)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(OmniPetColor.grayPin)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 34))
                        Text("Align your document inside the frame")
                            .font(.headline)
                    }
                    .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 10) {
                Label("Light is low; move near a window", systemImage: "sun.max")
                Label("Blurry text detected", systemImage: "camera.metering.unknown")
                Label("Auto-tag suggestions: Rabies, Jan 2027", systemImage: "sparkles")
                    .foregroundStyle(OmniPetColor.emerald)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Capture") { }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("Smart Scanner")
    }
}

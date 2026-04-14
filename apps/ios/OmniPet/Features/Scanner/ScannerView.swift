import SwiftUI
import VisionKit

/// Wraps VNDocumentCameraViewController for real document scanning.
/// After the user captures pages, dismisses into the AddDocumentSheet
/// so they can tag the title, type, and expiration.
struct DocumentCameraView: UIViewControllerRepresentable {
    let onScanCompleted: ([UIImage]) -> Void
    let onCancelled: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted, onCancelled: onCancelled)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanCompleted: ([UIImage]) -> Void
        let onCancelled: () -> Void

        init(onScanCompleted: @escaping ([UIImage]) -> Void, onCancelled: @escaping () -> Void) {
            self.onScanCompleted = onScanCompleted
            self.onCancelled = onCancelled
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onScanCompleted(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancelled()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancelled()
        }
    }
}

/// Fallback view shown when the device doesn't support document scanning (e.g. Simulator).
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
                        Text("Document scanning is not available on this device")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("Use \"Add Document\" to manually enter your records.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }

            Spacer()
        }
        .padding()
        .navigationTitle("Smart Scanner")
    }
}

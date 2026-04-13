import SwiftUI

struct ActivityView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Recent Activity")
                Text("Sent")
                Text("Opened")
                Text("Action Needed")
            }
            .navigationTitle("Activity")
        }
    }
}

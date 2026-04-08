import SwiftUI

struct ExposureGuidanceView: View {
    var body: some View {
        List {
            Section("Safe Listening Guidance") {
                Text("Keep long sessions at lower volume. Start near 30-40%.")
                Text("Avoid placing speaker devices directly next to baby's ears.")
                Text("This app does not claim medical-grade hearing protection or certification.")
            }
        }
        .navigationTitle("Exposure Guidance")
    }
}

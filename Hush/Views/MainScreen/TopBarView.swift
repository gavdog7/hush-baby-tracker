import SwiftUI

struct TopBarView: View {
    var body: some View {
        HStack {
            // Profile icon (de-emphasized, left)
            Button(action: {
                // TODO: Open settings
            }) {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Baby name (center, tappable for quick stats)
            Button(action: {
                // TODO: Show quick stats overlay
            }) {
                Text("Baby")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Sync status indicator (right)
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44) // ~8% of screen on iPhone
    }
}

#Preview {
    TopBarView()
}

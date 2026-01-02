import SwiftUI

struct TopBarView: View {
    let babyName: String
    let onProfileTapped: () -> Void
    let onBabyNameTapped: () -> Void

    var body: some View {
        HStack {
            // Profile icon (de-emphasized, left)
            Button(action: onProfileTapped) {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Baby name (center, tappable for quick stats)
            Button(action: onBabyNameTapped) {
                Text(babyName)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Sync status indicator (right)
            SyncStatusIndicator(status: .synced)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44) // ~8% of screen on iPhone
    }
}

// MARK: - Sync Status

enum SyncStatus {
    case synced
    case syncing
    case offline
}

struct SyncStatusIndicator: View {
    let status: SyncStatus

    var body: some View {
        switch status {
        case .synced:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        case .syncing:
            ProgressView()
                .controlSize(.small)
        case .offline:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    TopBarView(
        babyName: "Emma",
        onProfileTapped: {},
        onBabyNameTapped: {}
    )
}

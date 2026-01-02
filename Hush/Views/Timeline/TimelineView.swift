import SwiftUI

struct TimelineView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Future section (3 hours)
                    TimelineFutureSection()

                    // Now indicator
                    NowIndicatorView()

                    // Past section (6 hours)
                    TimelinePastSection()
                }
                .frame(minHeight: geometry.size.height)
            }
            .refreshable {
                // TODO: Pull to refresh
            }
        }
    }
}

struct TimelineFutureSection: View {
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder for predictions
            Text("Future predictions will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimelinePastSection: View {
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder for past events
            Text("Past events will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 100)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TimelineView()
}

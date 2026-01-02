import SwiftUI

struct ActionButtonsView: View {
    let isSleeping: Bool
    let activeSleepDuration: String?
    let onEatTapped: () -> Void
    let onSleepTapped: () -> Void
    let onDiaperTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "EAT",
                icon: "fork.knife",
                color: .eat,
                action: onEatTapped
            )

            ActionButton(
                title: isSleeping ? "WAKE" : "SLEEP",
                subtitle: activeSleepDuration,
                icon: isSleeping ? "sun.max.fill" : "moon.fill",
                color: .sleep,
                isActive: isSleeping,
                action: onSleepTapped
            )

            ActionButton(
                title: "DIAPER",
                icon: "humidity.fill",
                color: .diaper,
                action: onDiaperTapped
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct ActionButton: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isActive
                    ? color.opacity(0.3)
                    : color.opacity(0.15)
            )
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: title)
    }
}

#Preview("Default") {
    ActionButtonsView(
        isSleeping: false,
        activeSleepDuration: nil,
        onEatTapped: {},
        onSleepTapped: {},
        onDiaperTapped: {}
    )
}

#Preview("Sleeping") {
    ActionButtonsView(
        isSleeping: true,
        activeSleepDuration: "1h 23m",
        onEatTapped: {},
        onSleepTapped: {},
        onDiaperTapped: {}
    )
}

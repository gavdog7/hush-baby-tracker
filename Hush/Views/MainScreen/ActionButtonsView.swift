import SwiftUI

struct ActionButtonsView: View {
    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "EAT",
                icon: "fork.knife",
                color: .eat
            ) {
                // TODO: Trigger eat flow
            }

            ActionButton(
                title: "SLEEP",
                icon: "moon.fill",
                color: .sleep
            ) {
                // TODO: Trigger sleep flow
            }

            ActionButton(
                title: "DIAPER",
                icon: "humidity.fill",
                color: .diaper
            ) {
                // TODO: Trigger diaper flow
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionButtonsView()
}

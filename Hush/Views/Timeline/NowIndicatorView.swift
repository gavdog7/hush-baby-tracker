import SwiftUI

struct NowIndicatorView: View {
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(height: 1)

            Text(currentTime, format: .dateTime.hour().minute())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    NowIndicatorView()
}

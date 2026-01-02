import SwiftUI

struct MainScreenView: View {
    var body: some View {
        VStack(spacing: 0) {
            TopBarView()
            ActionButtonsView()
            TimelineView()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    MainScreenView()
}

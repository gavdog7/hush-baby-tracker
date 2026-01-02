import SwiftUI

struct MainScreenView: View {
    @State private var viewModel = TimelineViewModel()
    @State private var showSettings = false
    @State private var showQuickStats = false

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                babyName: viewModel.currentBaby?.name ?? "Baby",
                onProfileTapped: { showSettings = true },
                onBabyNameTapped: { showQuickStats = true }
            )

            ActionButtonsView(
                isSleeping: viewModel.isSleeping,
                activeSleepDuration: viewModel.activeSleepDuration,
                onEatTapped: viewModel.onEatTapped,
                onSleepTapped: viewModel.onSleepTapped,
                onDiaperTapped: viewModel.onDiaperTapped
            )

            TimelineView(viewModel: viewModel)
        }
        .background(Color.darkBackground)
        .task {
            await setupDemoData()
            await viewModel.loadEvents()
        }
        .sheet(isPresented: $showSettings) {
            SettingsPlaceholderView()
        }
        .overlay {
            if showQuickStats, let baby = viewModel.currentBaby {
                QuickStatsOverlay(
                    baby: baby,
                    viewModel: viewModel,
                    isPresented: $showQuickStats
                )
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.eventService.errorMessage != nil },
            set: { if !$0 { viewModel.eventService.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.eventService.errorMessage = nil
            }
        } message: {
            if let error = viewModel.eventService.errorMessage {
                Text(error)
            }
        }
        .confirmationDialog(
            "Baby is currently sleeping",
            isPresented: Binding(
                get: { viewModel.eventService.showSleepConflictSheet },
                set: { viewModel.eventService.showSleepConflictSheet = $0 }
            ),
            titleVisibility: .visible
        ) {
            if let sleep = viewModel.eventService.activeSleep {
                Button("End Sleep") {
                    viewModel.eventService.endSleep(event: sleep)
                    Task { await viewModel.loadEvents() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let duration = viewModel.activeSleepDuration {
                Text("Duration: \(duration)")
            }
        }
    }

    // Temporary: Create demo baby for testing
    private func setupDemoData() async {
        let babyRepo = BabyRepository()
        let userRepo = UserRepository()

        // Check if we already have a baby
        if let existingBaby = try? babyRepo.fetchFirstBaby() {
            viewModel.currentBaby = existingBaby
            viewModel.currentUserId = existingBaby.primaryCaregiverId
            return
        }

        // Create demo user and baby
        let user = User(
            email: "demo@example.com",
            displayName: "Demo User"
        )
        _ = try? userRepo.createOrUpdate(user)
        viewModel.currentUserId = user.id

        let baby = Baby(
            name: "Emma",
            birthDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            primaryCaregiverId: user.id
        )
        _ = try? babyRepo.create(baby)
        viewModel.currentBaby = baby
    }
}

// MARK: - Placeholder Views

struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Baby") {
                    Text("Name: Emma")
                    Text("Age: 3 months")
                }
                Section("Settings") {
                    Text("Default bottle size: 4 oz")
                    Text("Units: Imperial (oz)")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuickStatsOverlay: View {
    let baby: Baby
    let viewModel: TimelineViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text(baby.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isSleeping {
                        StatRow(
                            label: "Current state",
                            value: "Sleeping for \(viewModel.activeSleepDuration ?? "0m")",
                            icon: "moon.fill",
                            color: .sleep
                        )
                    } else {
                        StatRow(
                            label: "Current state",
                            value: "Awake",
                            icon: "sun.max.fill",
                            color: .orange
                        )
                    }

                    // Placeholder stats - would come from actual data
                    StatRow(
                        label: "Last feed",
                        value: "1h ago (3.5 oz)",
                        icon: "fork.knife",
                        color: .eat
                    )

                    StatRow(
                        label: "Last diaper",
                        value: "45m ago (wet)",
                        icon: "humidity.fill",
                        color: .diaper
                    )
                }
                .padding()
            }
            .frame(maxWidth: 300)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
    }
}

#Preview {
    MainScreenView()
}

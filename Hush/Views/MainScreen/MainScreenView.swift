import SwiftUI

struct MainScreenView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = TimelineViewModel()
    @State private var showSettings = false
    @State private var showQuickStats = false
    @State private var showOnboarding = false
    @State private var napPrediction: NapPrediction?

    private let wakeWindowPredictor = WakeWindowPredictor()

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

            TimelineView(viewModel: viewModel, napPrediction: napPrediction)
        }
        .background(Color.darkBackground)
        .task {
            await loadBaby()
            await viewModel.loadEvents()
            updatePrediction()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView { baby in
                viewModel.currentBaby = baby
                viewModel.currentUserId = baby.primaryCaregiverId
                showOnboarding = false
                Task { await viewModel.loadEvents() }
                updatePrediction()
            }
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
                    updatePrediction()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let duration = viewModel.activeSleepDuration {
                Text("Duration: \(duration)")
            }
        }
        .onChange(of: viewModel.events) { _, _ in
            updatePrediction()
        }
    }

    private func loadBaby() async {
        let babyRepo = BabyRepository()

        // Try to load existing baby
        if let existingBaby = try? babyRepo.fetchFirstBaby() {
            viewModel.currentBaby = existingBaby
            viewModel.currentUserId = authService.currentUser?.id ?? existingBaby.primaryCaregiverId
            return
        }

        // No baby exists, show onboarding
        showOnboarding = true
    }

    private func updatePrediction() {
        guard let baby = viewModel.currentBaby else {
            napPrediction = nil
            return
        }

        // Find last wake time (end of last sleep, or start of baby tracking)
        let lastWakeTime: Date

        if let lastSleep = viewModel.sleepEvents.first(where: { $0.endTime != nil }),
           let endTime = lastSleep.endTime {
            lastWakeTime = endTime.utc
        } else {
            // No sleep data, use 2 hours ago as default
            lastWakeTime = Date().addingTimeInterval(-2 * 3600)
        }

        // Only predict if baby is awake
        if viewModel.isSleeping {
            napPrediction = nil
        } else {
            napPrediction = wakeWindowPredictor.predictNextNap(
                baby: baby,
                lastWakeTime: lastWakeTime
            )
        }
    }
}

// MARK: - Quick Stats Overlay

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

                Text(baby.ageDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    // Current state
                    if viewModel.isSleeping {
                        StatRow(
                            label: "Current state",
                            value: "Sleeping for \(viewModel.activeSleepDuration ?? "0m")",
                            icon: "moon.fill",
                            color: .sleep
                        )
                    } else {
                        let awakeTime = calculateAwakeTime()
                        StatRow(
                            label: "Current state",
                            value: "Awake for \(awakeTime)",
                            icon: "sun.max.fill",
                            color: .orange
                        )
                    }

                    // Last feed
                    if let lastFeed = viewModel.eatEvents.first {
                        let timeAgo = lastFeed.startTime.relativeDisplay
                        let amount = lastFeed.data.eatData?.amountConsumedOz ?? lastFeed.data.eatData?.amountPreparedOz ?? 0
                        StatRow(
                            label: "Last feed",
                            value: "\(timeAgo) (\(String(format: "%.1f", amount)) oz)",
                            icon: "fork.knife",
                            color: .eat
                        )
                    }

                    // Last diaper
                    if let lastDiaper = viewModel.diaperEvents.first {
                        let timeAgo = lastDiaper.startTime.relativeDisplay
                        let contents = lastDiaper.data.diaperData?.contents.displayName.lowercased() ?? "diaper"
                        StatRow(
                            label: "Last diaper",
                            value: "\(timeAgo) (\(contents))",
                            icon: "humidity.fill",
                            color: .diaper
                        )
                    }

                    // Last sleep
                    if let lastSleep = viewModel.sleepEvents.first(where: { $0.endTime != nil }) {
                        StatRow(
                            label: "Last sleep",
                            value: "\(lastSleep.durationDisplay) (ended \(lastSleep.endTime?.relativeDisplay ?? ""))",
                            icon: "moon.fill",
                            color: .sleep
                        )
                    }
                }
                .padding()
            }
            .frame(maxWidth: 320)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
    }

    private func calculateAwakeTime() -> String {
        guard let lastSleep = viewModel.sleepEvents.first(where: { $0.endTime != nil }),
              let endTime = lastSleep.endTime else {
            return "a while"
        }

        return EventTimestamp.formatDuration(endTime.durationUntilNow)
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
        .environment(AuthService())
}

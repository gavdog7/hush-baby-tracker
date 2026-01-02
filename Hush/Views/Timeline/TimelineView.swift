import SwiftUI

struct TimelineView: View {
    let viewModel: TimelineViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .top) {
                        // Time markers
                        TimeMarkersView(viewModel: viewModel, height: geometry.size.height * 1.5)

                        // Events layer
                        EventsLayer(viewModel: viewModel, height: geometry.size.height * 1.5)

                        // Now indicator
                        NowIndicatorView()
                            .id("now")
                            .offset(y: geometry.size.height * 1.5 * viewModel.position(for: viewModel.currentTime))
                    }
                    .frame(height: geometry.size.height * 1.5)
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear {
                    // Scroll to "now" indicator
                    proxy.scrollTo("now", anchor: .center)
                }
            }
        }
    }
}

// MARK: - Time Markers

struct TimeMarkersView: View {
    let viewModel: TimelineViewModel
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(timeMarkers, id: \.self) { date in
                TimeMarkerRow(date: date, viewModel: viewModel)
                    .frame(height: height / CGFloat(totalMarkers))
            }
        }
        .frame(height: height)
    }

    private var timeMarkers: [Date] {
        var markers: [Date] = []
        let calendar = Calendar.current

        // Round to nearest hour
        let startHour = calendar.dateInterval(of: .hour, for: viewModel.windowStart)?.start ?? viewModel.windowStart

        var current = startHour
        while current <= viewModel.windowEnd {
            markers.append(current)
            current = calendar.date(byAdding: .hour, value: 1, to: current) ?? current
        }

        return markers
    }

    private var totalMarkers: Int {
        max(1, Int(viewModel.totalWindowHours) + 1)
    }
}

struct TimeMarkerRow: View {
    let date: Date
    let viewModel: TimelineViewModel

    var body: some View {
        HStack {
            Text(date, format: .dateTime.hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Events Layer

struct EventsLayer: View {
    let viewModel: TimelineViewModel
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Sleep events
            ForEach(viewModel.sleepEvents) { event in
                EventBlockView(event: event, viewModel: viewModel)
                    .offset(y: height * viewModel.position(for: event.startTime.utc))
            }

            // Active sleep extending to now
            if let activeSleep = viewModel.eventService.activeSleep {
                ActiveSleepBlockView(event: activeSleep, viewModel: viewModel, totalHeight: height)
            }

            // Eat events
            ForEach(viewModel.eatEvents) { event in
                EventBlockView(event: event, viewModel: viewModel)
                    .offset(y: height * viewModel.position(for: event.startTime.utc))
            }

            // Diaper events
            ForEach(viewModel.diaperEvents) { event in
                EventBlockView(event: event, viewModel: viewModel)
                    .offset(y: height * viewModel.position(for: event.startTime.utc))
            }

            // Prepared bottles
            ForEach(viewModel.eventService.preparedBottles) { bottle in
                PreparedBottleIndicator(event: bottle, viewModel: viewModel)
            }
        }
        .padding(.leading, 55) // Space for time markers
    }
}

// MARK: - Event Block

struct EventBlockView: View {
    let event: Event
    let viewModel: TimelineViewModel

    @State private var isExpanded = false

    var body: some View {
        let blockHeight = calculateHeight()

        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: event.eventType.icon)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.startTime.timeDisplay)
                        .font(.caption2)

                    if event.endTime != nil {
                        Text(event.durationDisplay)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if isExpanded {
                        eventDetails
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(height: max(36, blockHeight), alignment: .top)
            .background(eventColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(eventColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func calculateHeight() -> CGFloat {
        guard let duration = event.duration else { return 36 }
        // Minimum height of 36, scale with duration
        let scaledHeight = viewModel.height(forDuration: duration) * 400 // Approximate timeline height
        return max(36, min(scaledHeight, 200))
    }

    private var eventColor: Color {
        switch event.eventType {
        case .eat: return .eat
        case .sleep: return .sleep
        case .diaper: return .diaper
        }
    }

    @ViewBuilder
    private var eventDetails: some View {
        switch event.eventType {
        case .eat:
            if let eatData = event.data.eatData {
                Text("Prepared: \(String(format: "%.1f", eatData.amountPreparedOz)) oz")
                    .font(.caption2)
                if let consumed = eatData.amountConsumedOz {
                    Text("Consumed: \(String(format: "%.1f", consumed)) oz")
                        .font(.caption2)
                }
            }
        case .diaper:
            if let diaperData = event.data.diaperData {
                Text(diaperData.contents.displayName)
                    .font(.caption2)
            }
        case .sleep:
            EmptyView()
        }

        if let notes = event.notes, !notes.isEmpty {
            Text(notes)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Active Sleep Block

struct ActiveSleepBlockView: View {
    let event: Event
    let viewModel: TimelineViewModel
    let totalHeight: CGFloat

    var body: some View {
        let startY = totalHeight * viewModel.position(for: event.startTime.utc)
        let nowY = totalHeight * viewModel.position(for: viewModel.currentTime)
        let blockHeight = startY - nowY

        VStack(spacing: 4) {
            Text(event.durationDisplay)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: max(40, blockHeight))
        .background(
            Color.sleep.opacity(0.3)
                .overlay(
                    PulsingOverlay()
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.sleep, lineWidth: 2)
        )
        .offset(y: nowY)
    }
}

struct PulsingOverlay: View {
    @State private var isAnimating = false

    var body: some View {
        Color.sleep.opacity(isAnimating ? 0.1 : 0.3)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Prepared Bottle Indicator

struct PreparedBottleIndicator: View {
    let event: Event
    let viewModel: TimelineViewModel

    var body: some View {
        guard let eatData = event.data.eatData else { return AnyView(EmptyView()) }

        let warningLevel = eatData.expiryWarningLevel(
            preparationTime: event.startTime,
            refrigeratedExpiryHours: viewModel.currentBaby?.settings.refrigeratedExpiryHours ?? 24
        )

        return AnyView(
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(warningColor(for: warningLevel))

                if let remaining = eatData.timeUntilExpiry(
                    preparationTime: event.startTime,
                    refrigeratedExpiryHours: viewModel.currentBaby?.settings.refrigeratedExpiryHours ?? 24
                ) {
                    Text("Expires in \(formatTimeRemaining(remaining))")
                        .font(.caption2)
                        .foregroundStyle(warningColor(for: warningLevel))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(warningColor(for: warningLevel).opacity(0.15))
            .clipShape(Capsule())
        )
    }

    private func warningColor(for level: ExpiryWarningLevel) -> Color {
        switch level {
        case .safe: return .green
        case .warning: return .yellow
        case .urgent: return .red
        case .expired: return .gray
        case .none: return .clear
        }
    }

    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        if interval <= 0 { return "Expired" }

        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

#Preview {
    TimelineView(viewModel: TimelineViewModel())
}

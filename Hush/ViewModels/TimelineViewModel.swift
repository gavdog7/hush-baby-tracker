import Foundation
import SwiftUI

/// ViewModel for the timeline view
@MainActor
@Observable
final class TimelineViewModel {
    // MARK: - Dependencies

    private let eventRepository: EventRepository
    let eventService: EventService

    // MARK: - State

    /// The current baby being tracked
    var currentBaby: Baby?

    /// The current user
    var currentUserId: UUID?

    /// Events in the visible time window
    private(set) var events: [Event] = []

    /// Whether data is loading
    private(set) var isLoading = false

    /// The current time (updated every minute)
    var currentTime = Date()

    /// Time window configuration
    let pastHours: Double = 6
    let futureHours: Double = 3

    /// Timer for updating current time
    @ObservationIgnored
    private var timer: Timer?

    init(
        eventRepository: EventRepository? = nil,
        eventService: EventService? = nil
    ) {
        self.eventRepository = eventRepository ?? EventRepository()
        self.eventService = eventService ?? EventService()

        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Time Window

    /// The start of the visible time window (pastHours ago)
    var windowStart: Date {
        currentTime.addingTimeInterval(-pastHours * 3600)
    }

    /// The end of the visible time window (futureHours ahead)
    var windowEnd: Date {
        currentTime.addingTimeInterval(futureHours * 3600)
    }

    /// Total hours in the visible window
    var totalWindowHours: Double {
        pastHours + futureHours
    }

    // MARK: - Data Loading

    /// Loads events for the current baby within the time window
    func loadEvents() async {
        guard let baby = currentBaby else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            events = try eventRepository.fetchEvents(
                babyId: baby.id,
                from: windowStart,
                to: windowEnd
            )

            // Also refresh active state
            eventService.refreshState(babyId: baby.id)
        } catch {
            eventService.errorMessage = error.localizedDescription
        }
    }

    /// Refreshes the timeline
    func refresh() async {
        await loadEvents()
    }

    // MARK: - Event Actions

    /// Handles tapping the sleep button
    func onSleepTapped() {
        guard let baby = currentBaby, let userId = currentUserId else { return }
        eventService.toggleSleep(babyId: baby.id, loggedBy: userId)
        Task { await loadEvents() }
    }

    /// Handles tapping the eat button
    func onEatTapped() {
        guard let baby = currentBaby, let userId = currentUserId else { return }

        // Quick log: prepare bottle with default size
        let defaultSize = baby.settings.defaultBottleSizeOz
        eventService.prepareBottle(
            babyId: baby.id,
            loggedBy: userId,
            amountOz: defaultSize
        )
        Task { await loadEvents() }
    }

    /// Handles tapping the diaper button
    func onDiaperTapped() {
        guard let baby = currentBaby, let userId = currentUserId else { return }

        // Quick log: diaper with "both" as default
        eventService.logDiaper(
            babyId: baby.id,
            loggedBy: userId,
            contents: .both
        )
        Task { await loadEvents() }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = Date()
            }
        }
    }

    // MARK: - Event Position Calculation

    /// Calculates the vertical position (0-1) for a given date in the timeline
    func position(for date: Date) -> Double {
        let windowSeconds = totalWindowHours * 3600
        let offsetFromStart = date.timeIntervalSince(windowStart)
        let normalized = offsetFromStart / windowSeconds

        // Invert so past is at bottom, future at top
        return 1 - normalized
    }

    /// Calculates height (0-1) for a duration in the timeline
    func height(forDuration seconds: TimeInterval) -> Double {
        let windowSeconds = totalWindowHours * 3600
        return seconds / windowSeconds
    }

    // MARK: - Grouped Events

    /// Events grouped by type for display
    var sleepEvents: [Event] {
        events.filter { $0.eventType == .sleep }
    }

    var eatEvents: [Event] {
        events.filter { $0.eventType == .eat }
    }

    var diaperEvents: [Event] {
        events.filter { $0.eventType == .diaper }
    }

    // MARK: - Active States

    var isSleeping: Bool {
        eventService.activeSleep != nil
    }

    var isFeeding: Bool {
        eventService.activeFeeding != nil
    }

    var activeSleepDuration: String? {
        guard let sleep = eventService.activeSleep else { return nil }
        return sleep.durationDisplay
    }

    var activeFeedingDuration: String? {
        guard let feeding = eventService.activeFeeding else { return nil }
        guard let eatData = feeding.data.eatData,
              let feedingStart = eatData.feedingStartedAt else { return nil }
        return EventTimestamp.formatDuration(feedingStart.durationUntilNow)
    }
}

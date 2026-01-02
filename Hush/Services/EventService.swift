import Foundation
import SwiftUI

/// Coordinates event logging with validation and haptic feedback
@MainActor
@Observable
final class EventService {
    private let eventRepository: EventRepository
    private let sleepValidator: SleepValidator
    private let feedingValidator: FeedingValidator

    // MARK: - State

    /// The currently active sleep event, if any
    private(set) var activeSleep: Event?

    /// The currently active feeding event, if any
    private(set) var activeFeeding: Event?

    /// Prepared bottles waiting to be used
    private(set) var preparedBottles: [Event] = []

    /// Error message to display
    var errorMessage: String?

    /// Whether an action sheet should be shown for sleep conflict
    var showSleepConflictSheet = false

    /// Whether an action sheet should be shown for feeding conflict
    var showFeedingConflictSheet = false

    init(
        eventRepository: EventRepository? = nil,
        sleepValidator: SleepValidator? = nil,
        feedingValidator: FeedingValidator? = nil
    ) {
        self.eventRepository = eventRepository ?? EventRepository()
        self.sleepValidator = sleepValidator ?? SleepValidator()
        self.feedingValidator = feedingValidator ?? FeedingValidator()
    }

    // MARK: - State Refresh

    /// Refreshes the active state from the database
    func refreshState(babyId: UUID) {
        do {
            activeSleep = try sleepValidator.getActiveSleep(babyId: babyId)
            activeFeeding = try feedingValidator.getActiveFeeding(babyId: babyId)
            preparedBottles = try feedingValidator.getPreparedBottles(babyId: babyId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sleep Actions

    /// Starts or ends a sleep based on current state
    func toggleSleep(babyId: UUID, loggedBy: UUID) {
        if let activeSleep = activeSleep {
            endSleep(event: activeSleep)
        } else {
            startSleep(babyId: babyId, loggedBy: loggedBy)
        }
    }

    /// Starts a new sleep
    func startSleep(babyId: UUID, loggedBy: UUID) {
        do {
            try sleepValidator.validateNewSleep(babyId: babyId)

            let event = Event(
                babyId: babyId,
                loggedBy: loggedBy,
                eventType: .sleep,
                data: .sleep(SleepEventData())
            )

            activeSleep = try eventRepository.create(event)
            triggerHaptic(.success)
        } catch let error as ValidationError {
            if case .sleepAlreadyActive = error {
                showSleepConflictSheet = true
            }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Ends an active sleep
    func endSleep(event: Event) {
        do {
            try sleepValidator.validateEndSleep(event: event)

            var updatedEvent = event
            updatedEvent.endTime = EventTimestamp()

            activeSleep = nil
            _ = try eventRepository.update(updatedEvent)
            triggerHaptic(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Feeding Actions

    /// Prepares a new bottle
    func prepareBottle(
        babyId: UUID,
        loggedBy: UUID,
        amountOz: Double,
        isRefrigerated: Bool = false
    ) {
        let event = Event(
            babyId: babyId,
            loggedBy: loggedBy,
            eventType: .eat,
            data: .eat(EatEventData(
                amountPreparedOz: amountOz,
                isRefrigerated: isRefrigerated
            ))
        )

        do {
            let created = try eventRepository.create(event)
            preparedBottles.append(created)
            triggerHaptic(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Starts feeding from a prepared bottle
    func startFeeding(event: Event, refrigeratedExpiryHours: Int = 24) {
        do {
            try feedingValidator.validateFeedingStart(babyId: event.babyId)
            try feedingValidator.validateBottleNotExpired(event: event, refrigeratedExpiryHours: refrigeratedExpiryHours)

            guard var eatData = event.data.eatData else { return }

            eatData.feedingStartedAt = EventTimestamp()

            var updatedEvent = event
            updatedEvent.data = .eat(eatData)

            activeFeeding = try eventRepository.update(updatedEvent)

            // Remove from prepared bottles
            preparedBottles.removeAll { $0.id == event.id }
            triggerHaptic(.success)
        } catch let error as ValidationError {
            if case .feedingAlreadyActive = error {
                showFeedingConflictSheet = true
            }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Finishes a feeding with the remaining amount
    func finishFeeding(event: Event, amountRemainingOz: Double) {
        do {
            try feedingValidator.validateFinishFeeding(event: event, amountRemainingOz: amountRemainingOz)

            guard var eatData = event.data.eatData else { return }

            eatData.amountRemainingOz = amountRemainingOz

            var updatedEvent = event
            updatedEvent.data = .eat(eatData)
            updatedEvent.endTime = EventTimestamp()

            _ = try eventRepository.update(updatedEvent)
            activeFeeding = nil
            triggerHaptic(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Discards a bottle (marks as expired/discarded)
    func discardBottle(event: Event) {
        do {
            try eventRepository.delete(event)
            preparedBottles.removeAll { $0.id == event.id }
            if activeFeeding?.id == event.id {
                activeFeeding = nil
            }
            triggerHaptic(.warning)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Diaper Actions

    /// Logs a diaper change
    func logDiaper(babyId: UUID, loggedBy: UUID, contents: DiaperContents = .both) {
        let event = Event(
            babyId: babyId,
            loggedBy: loggedBy,
            eventType: .diaper,
            data: .diaper(DiaperEventData(contents: contents))
        )

        do {
            _ = try eventRepository.create(event)
            triggerHaptic(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Event Management

    /// Updates an event's notes
    func updateNotes(event: Event, notes: String?) {
        var updatedEvent = event
        updatedEvent.notes = notes

        do {
            _ = try eventRepository.update(updatedEvent)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes an event
    func deleteEvent(_ event: Event) {
        do {
            try eventRepository.delete(event)
            refreshState(babyId: event.babyId)
            triggerHaptic(.warning)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

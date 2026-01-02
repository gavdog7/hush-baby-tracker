import Foundation

/// Validates feeding-related business rules
@MainActor
final class FeedingValidator {
    private let eventRepository: EventRepository

    init(eventRepository: EventRepository? = nil) {
        self.eventRepository = eventRepository ?? EventRepository()
    }

    /// Validates that a new feeding can be started from a prepared bottle
    /// - Throws: ValidationError.feedingAlreadyActive if there's an active feeding
    func validateFeedingStart(babyId: UUID) throws {
        let activeEvents = try eventRepository.fetchActiveEvents(babyId: babyId, eventType: .eat)

        // Check for any feeding in progress
        for event in activeEvents {
            guard let eatData = event.data.eatData else { continue }

            if eatData.feedingStartedAt != nil {
                throw ValidationError.feedingAlreadyActive(
                    startedAt: eatData.feedingStartedAt ?? event.startTime,
                    duration: eatData.feedingStartedAt?.durationUntilNow ?? event.activeDuration
                )
            }
        }
    }

    /// Validates that a bottle is not expired before starting to feed
    func validateBottleNotExpired(event: Event, refrigeratedExpiryHours: Int = 24) throws {
        guard event.eventType == .eat,
              let eatData = event.data.eatData else {
            throw ValidationError.invalidEventType
        }

        if eatData.isExpired(preparationTime: event.startTime, refrigeratedExpiryHours: refrigeratedExpiryHours) {
            throw ValidationError.bottleExpired
        }
    }

    /// Validates the amount remaining when finishing a feeding
    func validateFinishFeeding(event: Event, amountRemainingOz: Double) throws {
        guard event.eventType == .eat,
              let eatData = event.data.eatData else {
            throw ValidationError.invalidEventType
        }

        guard amountRemainingOz >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard amountRemainingOz <= eatData.amountPreparedOz else {
            throw ValidationError.invalidAmount
        }
    }

    /// Gets the currently active feeding, if any
    func getActiveFeeding(babyId: UUID) throws -> Event? {
        let activeEvents = try eventRepository.fetchActiveEvents(babyId: babyId, eventType: .eat)

        for event in activeEvents {
            guard let eatData = event.data.eatData else { continue }
            if eatData.feedingStartedAt != nil {
                return event
            }
        }

        return nil
    }

    /// Gets all prepared bottles (not yet started feeding)
    func getPreparedBottles(babyId: UUID) throws -> [Event] {
        return try eventRepository.fetchPreparedBottles(babyId: babyId)
    }

    /// Checks if any prepared bottle is expired
    func getExpiredBottles(babyId: UUID, refrigeratedExpiryHours: Int = 24) throws -> [Event] {
        let bottles = try getPreparedBottles(babyId: babyId)
        return bottles.filter { event in
            guard let eatData = event.data.eatData else { return false }
            return eatData.isExpired(
                preparationTime: event.startTime,
                refrigeratedExpiryHours: refrigeratedExpiryHours
            )
        }
    }
}

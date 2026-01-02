import Foundation

/// Validates sleep-related business rules
@MainActor
final class SleepValidator {
    private let eventRepository: EventRepository

    init(eventRepository: EventRepository? = nil) {
        self.eventRepository = eventRepository ?? EventRepository()
    }

    /// Validates that a new sleep can be started
    /// - Throws: ValidationError.sleepAlreadyActive if there's an active sleep
    func validateNewSleep(babyId: UUID) throws {
        let activeEvents = try eventRepository.fetchActiveEvents(babyId: babyId, eventType: .sleep)

        if let activeSleep = activeEvents.first {
            throw ValidationError.sleepAlreadyActive(
                startedAt: activeSleep.startTime,
                duration: activeSleep.activeDuration
            )
        }
    }

    /// Gets the currently active sleep, if any
    func getActiveSleep(babyId: UUID) throws -> Event? {
        let activeEvents = try eventRepository.fetchActiveEvents(babyId: babyId, eventType: .sleep)
        return activeEvents.first
    }

    /// Validates ending a sleep
    func validateEndSleep(event: Event) throws {
        guard event.eventType == .sleep else {
            throw ValidationError.invalidEventType
        }

        guard event.isActive else {
            throw ValidationError.eventAlreadyEnded
        }
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case sleepAlreadyActive(startedAt: EventTimestamp, duration: TimeInterval)
    case feedingAlreadyActive(startedAt: EventTimestamp, duration: TimeInterval)
    case invalidEventType
    case eventAlreadyEnded
    case bottleExpired
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .sleepAlreadyActive(_, let duration):
            return "Baby is currently sleeping (\(EventTimestamp.formatDuration(duration)))"
        case .feedingAlreadyActive(_, let duration):
            return "Baby is currently feeding (\(EventTimestamp.formatDuration(duration)))"
        case .invalidEventType:
            return "Invalid event type for this operation"
        case .eventAlreadyEnded:
            return "This event has already ended"
        case .bottleExpired:
            return "This bottle has expired"
        case .invalidAmount:
            return "Invalid amount entered"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .sleepAlreadyActive:
            return "End the current sleep before starting a new one"
        case .feedingAlreadyActive:
            return "Finish or discard the current feeding first"
        case .bottleExpired:
            return "Discard this bottle and prepare a new one"
        default:
            return nil
        }
    }
}

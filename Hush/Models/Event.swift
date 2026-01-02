import Foundation

/// Represents a tracked event (feeding, sleep, or diaper change)
struct Event: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let babyId: UUID
    let loggedBy: UUID
    let eventType: EventType
    var startTime: EventTimestamp
    var endTime: EventTimestamp?
    var data: EventData
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        babyId: UUID,
        loggedBy: UUID,
        eventType: EventType,
        startTime: EventTimestamp = EventTimestamp(),
        endTime: EventTimestamp? = nil,
        data: EventData,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.babyId = babyId
        self.loggedBy = loggedBy
        self.eventType = eventType
        self.startTime = startTime
        self.endTime = endTime
        self.data = data
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Computed Properties

    /// Whether this event is currently active (no end time)
    var isActive: Bool {
        endTime == nil && deletedAt == nil
    }

    /// Whether this event has been soft-deleted
    var isDeleted: Bool {
        deletedAt != nil
    }

    /// The duration of this event, if it has ended
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return startTime.duration(to: end)
    }

    /// The duration from start until now (for active events)
    var activeDuration: TimeInterval {
        startTime.durationUntilNow
    }

    /// Formatted duration string
    var durationDisplay: String {
        if let duration = duration {
            return EventTimestamp.formatDuration(duration)
        } else {
            return EventTimestamp.formatDuration(activeDuration)
        }
    }
}

// MARK: - Event Type

enum EventType: String, Codable, CaseIterable {
    case eat
    case sleep
    case diaper

    var displayName: String {
        switch self {
        case .eat: return "Feeding"
        case .sleep: return "Sleep"
        case .diaper: return "Diaper"
        }
    }

    var icon: String {
        switch self {
        case .eat: return "fork.knife"
        case .sleep: return "moon.fill"
        case .diaper: return "humidity.fill"
        }
    }
}

// MARK: - Polymorphic Event Data

/// Container for type-specific event data
enum EventData: Codable, Equatable, Hashable {
    case eat(EatEventData)
    case sleep(SleepEventData)
    case diaper(DiaperEventData)

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "eat":
            let data = try container.decode(EatEventData.self, forKey: .data)
            self = .eat(data)
        case "sleep":
            let data = try container.decode(SleepEventData.self, forKey: .data)
            self = .sleep(data)
        case "diaper":
            let data = try container.decode(DiaperEventData.self, forKey: .data)
            self = .diaper(data)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown event type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .eat(let data):
            try container.encode("eat", forKey: .type)
            try container.encode(data, forKey: .data)
        case .sleep(let data):
            try container.encode("sleep", forKey: .type)
            try container.encode(data, forKey: .data)
        case .diaper(let data):
            try container.encode("diaper", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }

    // MARK: - Accessors

    var eatData: EatEventData? {
        if case .eat(let data) = self { return data }
        return nil
    }

    var sleepData: SleepEventData? {
        if case .sleep(let data) = self { return data }
        return nil
    }

    var diaperData: DiaperEventData? {
        if case .diaper(let data) = self { return data }
        return nil
    }
}

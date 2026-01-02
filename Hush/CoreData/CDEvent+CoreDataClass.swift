import Foundation
import CoreData

@objc(CDEvent)
public class CDEvent: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var babyId: UUID?
    @NSManaged public var loggedBy: UUID?
    @NSManaged public var eventType: String?
    @NSManaged public var startTimeUTC: Date?
    @NSManaged public var startTimeTimezone: String?
    @NSManaged public var startTimeOffset: Int32
    @NSManaged public var endTimeUTC: Date?
    @NSManaged public var endTimeTimezone: String?
    @NSManaged public var endTimeOffset: Int32
    @NSManaged public var dataJSON: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var deletedAt: Date?
    @NSManaged public var baby: CDBaby?
}

// MARK: - Identifiable

extension CDEvent: Identifiable {}

// MARK: - Domain Model Conversion

extension CDEvent {
    /// Converts to domain model
    func toEvent() -> Event? {
        guard let id = id,
              let babyId = babyId,
              let loggedBy = loggedBy,
              let eventTypeString = eventType,
              let eventType = EventType(rawValue: eventTypeString),
              let startTimeUTC = startTimeUTC,
              let startTimeTimezone = startTimeTimezone,
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }

        let startTime = EventTimestamp(
            utc: startTimeUTC,
            timezoneIdentifier: startTimeTimezone,
            offsetSeconds: Int(startTimeOffset)
        )

        var endTime: EventTimestamp?
        if let endUTC = endTimeUTC, let endTZ = endTimeTimezone {
            endTime = EventTimestamp(
                utc: endUTC,
                timezoneIdentifier: endTZ,
                offsetSeconds: Int(endTimeOffset)
            )
        }

        let data = decodeEventData(type: eventType)

        return Event(
            id: id,
            babyId: babyId,
            loggedBy: loggedBy,
            eventType: eventType,
            startTime: startTime,
            endTime: endTime,
            data: data,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    /// Updates from domain model
    func update(from event: Event) {
        self.id = event.id
        self.babyId = event.babyId
        self.loggedBy = event.loggedBy
        self.eventType = event.eventType.rawValue
        self.startTimeUTC = event.startTime.utc
        self.startTimeTimezone = event.startTime.timezoneIdentifier
        self.startTimeOffset = Int32(event.startTime.offsetSeconds)

        if let endTime = event.endTime {
            self.endTimeUTC = endTime.utc
            self.endTimeTimezone = endTime.timezoneIdentifier
            self.endTimeOffset = Int32(endTime.offsetSeconds)
        } else {
            self.endTimeUTC = nil
            self.endTimeTimezone = nil
            self.endTimeOffset = 0
        }

        self.dataJSON = encodeEventData(event.data)
        self.notes = event.notes
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
        self.deletedAt = event.deletedAt
    }

    private func decodeEventData(type: EventType) -> EventData {
        guard let json = dataJSON,
              let data = json.data(using: .utf8) else {
            return defaultEventData(for: type)
        }

        do {
            return try JSONDecoder().decode(EventData.self, from: data)
        } catch {
            return defaultEventData(for: type)
        }
    }

    private func encodeEventData(_ eventData: EventData) -> String {
        do {
            let data = try JSONEncoder().encode(eventData)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }

    private func defaultEventData(for type: EventType) -> EventData {
        switch type {
        case .eat:
            return .eat(EatEventData(amountPreparedOz: 4.0))
        case .sleep:
            return .sleep(SleepEventData())
        case .diaper:
            return .diaper(DiaperEventData())
        }
    }
}

// MARK: - Fetch Requests

extension CDEvent {
    /// Fetch events for a baby, ordered by start time descending
    static func fetchRequest(babyId: UUID, includeDeleted: Bool = false) -> NSFetchRequest<CDEvent> {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")

        if includeDeleted {
            request.predicate = NSPredicate(format: "babyId == %@", babyId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "babyId == %@ AND deletedAt == nil", babyId as CVarArg)
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDEvent.startTimeUTC, ascending: false)
        ]

        return request
    }

    /// Fetch active events of a specific type for a baby
    static func fetchActiveRequest(babyId: UUID, eventType: EventType) -> NSFetchRequest<CDEvent> {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")

        request.predicate = NSPredicate(
            format: "babyId == %@ AND eventType == %@ AND endTimeUTC == nil AND deletedAt == nil",
            babyId as CVarArg,
            eventType.rawValue
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDEvent.startTimeUTC, ascending: false)
        ]

        return request
    }

    /// Fetch events within a time range
    static func fetchRequest(babyId: UUID, from startDate: Date, to endDate: Date) -> NSFetchRequest<CDEvent> {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")

        request.predicate = NSPredicate(
            format: "babyId == %@ AND startTimeUTC >= %@ AND startTimeUTC <= %@ AND deletedAt == nil",
            babyId as CVarArg,
            startDate as CVarArg,
            endDate as CVarArg
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDEvent.startTimeUTC, ascending: false)
        ]

        return request
    }
}

import Foundation
import CoreData

/// Repository for managing Event persistence
@MainActor
final class EventRepository: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? PersistenceController.shared.viewContext
    }

    // MARK: - CRUD Operations

    /// Creates a new event
    func create(_ event: Event) throws -> Event {
        let cdEvent = CDEvent(context: context)
        cdEvent.update(from: event)

        // Link to baby if exists
        if let baby = try? fetchCDBaby(id: event.babyId) {
            cdEvent.baby = baby
        }

        try context.save()
        return event
    }

    /// Fetches an event by ID
    func fetch(id: UUID) throws -> Event? {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toEvent()
    }

    /// Updates an existing event
    func update(_ event: Event) throws -> Event {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1

        guard let cdEvent = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        cdEvent.update(from: updatedEvent)

        try context.save()
        return updatedEvent
    }

    /// Soft deletes an event
    func delete(_ event: Event) throws {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1

        guard let cdEvent = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        cdEvent.deletedAt = Date()
        cdEvent.updatedAt = Date()

        try context.save()
    }

    /// Permanently deletes an event (use sparingly)
    func permanentlyDelete(_ event: Event) throws {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1

        guard let cdEvent = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        context.delete(cdEvent)
        try context.save()
    }

    // MARK: - Query Operations

    /// Fetches all events for a baby
    func fetchEvents(babyId: UUID, includeDeleted: Bool = false) throws -> [Event] {
        let request = CDEvent.fetchRequest(babyId: babyId, includeDeleted: includeDeleted)
        let results = try context.fetch(request)
        return results.compactMap { $0.toEvent() }
    }

    /// Fetches events within a time range
    func fetchEvents(babyId: UUID, from startDate: Date, to endDate: Date) throws -> [Event] {
        let request = CDEvent.fetchRequest(babyId: babyId, from: startDate, to: endDate)
        let results = try context.fetch(request)
        return results.compactMap { $0.toEvent() }
    }

    /// Fetches the most recent event of a type
    func fetchMostRecent(babyId: UUID, eventType: EventType) throws -> Event? {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(
            format: "babyId == %@ AND eventType == %@ AND deletedAt == nil",
            babyId as CVarArg,
            eventType.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDEvent.startTimeUTC, ascending: false)
        ]
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toEvent()
    }

    /// Fetches active events (no end time) of a specific type
    func fetchActiveEvents(babyId: UUID, eventType: EventType) throws -> [Event] {
        let request = CDEvent.fetchActiveRequest(babyId: babyId, eventType: eventType)
        let results = try context.fetch(request)
        return results.compactMap { $0.toEvent() }
    }

    /// Fetches any active event (sleep or feeding in progress)
    func fetchAnyActiveEvent(babyId: UUID) throws -> Event? {
        let request = NSFetchRequest<CDEvent>(entityName: "CDEvent")
        request.predicate = NSPredicate(
            format: "babyId == %@ AND endTimeUTC == nil AND deletedAt == nil AND (eventType == %@ OR eventType == %@)",
            babyId as CVarArg,
            EventType.sleep.rawValue,
            EventType.eat.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDEvent.startTimeUTC, ascending: false)
        ]
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toEvent()
    }

    /// Checks if there's an active sleep
    func hasActiveSleep(babyId: UUID) throws -> Bool {
        let events = try fetchActiveEvents(babyId: babyId, eventType: .sleep)
        return !events.isEmpty
    }

    /// Checks if there's an active feeding
    func hasActiveFeeding(babyId: UUID) throws -> Bool {
        let events = try fetchActiveEvents(babyId: babyId, eventType: .eat)
        return events.contains { event in
            guard let eatData = event.data.eatData else { return false }
            return eatData.feedingStartedAt != nil && event.endTime == nil
        }
    }

    /// Fetches prepared bottles (not yet feeding, not finished)
    func fetchPreparedBottles(babyId: UUID) throws -> [Event] {
        let events = try fetchActiveEvents(babyId: babyId, eventType: .eat)
        return events.filter { event in
            guard let eatData = event.data.eatData else { return false }
            return eatData.feedingStartedAt == nil
        }
    }

    // MARK: - Helper

    private func fetchCDBaby(id: UUID) throws -> CDBaby? {
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found."
        case .saveFailed:
            return "Failed to save changes."
        case .invalidData:
            return "The data is invalid."
        }
    }
}

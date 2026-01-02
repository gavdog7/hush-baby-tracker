import CoreData

/// Manages the Core Data stack for the app
@MainActor
final class PersistenceController {
    /// Shared instance for production use
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add sample data for previews
        let context = controller.container.viewContext
        controller.createSampleData(in: context)
        return controller
    }()

    /// The Core Data container
    let container: NSPersistentContainer

    /// The main view context
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Creates a new background context for async operations
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Hush")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for encryption at rest (NSFileProtectionComplete)
            let storeDescription = container.persistentStoreDescriptions.first
            storeDescription?.setOption(
                FileProtectionType.complete as NSObject,
                forKey: NSPersistentStoreFileProtectionKey
            )
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save

    /// Saves the view context if there are changes
    func save() {
        let context = viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            // In production, handle this more gracefully
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }

    /// Saves a background context
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data background save error: \(nsError), \(nsError.userInfo)")
        }
    }

    // MARK: - Sample Data for Previews

    private func createSampleData(in context: NSManagedObjectContext) {
        // Create sample baby
        let baby = CDBaby(context: context)
        baby.id = UUID()
        baby.name = "Emma"
        baby.birthDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        baby.primaryCaregiverId = UUID()
        baby.settingsJSON = "{}"
        baby.createdAt = Date()

        // Create sample events
        let now = Date()

        // Sleep event (ended 2 hours ago)
        let sleepEvent = CDEvent(context: context)
        sleepEvent.id = UUID()
        sleepEvent.babyId = baby.id
        sleepEvent.loggedBy = baby.primaryCaregiverId
        sleepEvent.eventType = "sleep"
        sleepEvent.startTimeUTC = now.addingTimeInterval(-4 * 3600)
        sleepEvent.startTimeTimezone = TimeZone.current.identifier
        sleepEvent.startTimeOffset = Int32(TimeZone.current.secondsFromGMT())
        sleepEvent.endTimeUTC = now.addingTimeInterval(-2 * 3600)
        sleepEvent.endTimeTimezone = TimeZone.current.identifier
        sleepEvent.endTimeOffset = Int32(TimeZone.current.secondsFromGMT())
        sleepEvent.dataJSON = "{\"type\":\"sleep\",\"data\":{}}"
        sleepEvent.createdAt = now.addingTimeInterval(-4 * 3600)
        sleepEvent.updatedAt = now.addingTimeInterval(-2 * 3600)
        sleepEvent.baby = baby

        // Feed event (1 hour ago)
        let feedEvent = CDEvent(context: context)
        feedEvent.id = UUID()
        feedEvent.babyId = baby.id
        feedEvent.loggedBy = baby.primaryCaregiverId
        feedEvent.eventType = "eat"
        feedEvent.startTimeUTC = now.addingTimeInterval(-1 * 3600)
        feedEvent.startTimeTimezone = TimeZone.current.identifier
        feedEvent.startTimeOffset = Int32(TimeZone.current.secondsFromGMT())
        feedEvent.endTimeUTC = now.addingTimeInterval(-0.5 * 3600)
        feedEvent.endTimeTimezone = TimeZone.current.identifier
        feedEvent.endTimeOffset = Int32(TimeZone.current.secondsFromGMT())
        feedEvent.dataJSON = "{\"type\":\"eat\",\"data\":{\"amountPreparedOz\":4.0,\"amountRemainingOz\":0.5,\"isRefrigerated\":false}}"
        feedEvent.createdAt = now.addingTimeInterval(-1 * 3600)
        feedEvent.updatedAt = now.addingTimeInterval(-0.5 * 3600)
        feedEvent.baby = baby

        // Diaper event (30 min ago)
        let diaperEvent = CDEvent(context: context)
        diaperEvent.id = UUID()
        diaperEvent.babyId = baby.id
        diaperEvent.loggedBy = baby.primaryCaregiverId
        diaperEvent.eventType = "diaper"
        diaperEvent.startTimeUTC = now.addingTimeInterval(-0.5 * 3600)
        diaperEvent.startTimeTimezone = TimeZone.current.identifier
        diaperEvent.startTimeOffset = Int32(TimeZone.current.secondsFromGMT())
        diaperEvent.dataJSON = "{\"type\":\"diaper\",\"data\":{\"contents\":\"wet\"}}"
        diaperEvent.createdAt = now.addingTimeInterval(-0.5 * 3600)
        diaperEvent.updatedAt = now.addingTimeInterval(-0.5 * 3600)
        diaperEvent.baby = baby

        try? context.save()
    }
}

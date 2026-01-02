import Foundation
import CoreData

/// Repository for managing Baby persistence
@MainActor
final class BabyRepository: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? PersistenceController.shared.viewContext
    }

    // MARK: - CRUD Operations

    /// Creates a new baby
    func create(_ baby: Baby) throws -> Baby {
        let cdBaby = CDBaby(context: context)
        cdBaby.update(from: baby)

        try context.save()
        return baby
    }

    /// Fetches a baby by ID
    func fetch(id: UUID) throws -> Baby? {
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toBaby()
    }

    /// Updates an existing baby
    func update(_ baby: Baby) throws -> Baby {
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
        request.fetchLimit = 1

        guard let cdBaby = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        cdBaby.update(from: baby)
        try context.save()
        return baby
    }

    /// Deletes a baby and all associated data
    func delete(_ baby: Baby) throws {
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.predicate = NSPredicate(format: "id == %@", baby.id as CVarArg)
        request.fetchLimit = 1

        guard let cdBaby = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        context.delete(cdBaby)
        try context.save()
    }

    // MARK: - Query Operations

    /// Fetches all babies for a user (as primary or caregiver)
    func fetchBabies(userId: UUID) throws -> [Baby] {
        // Fetch babies where user is primary
        let primaryRequest = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        primaryRequest.predicate = NSPredicate(format: "primaryCaregiverId == %@", userId as CVarArg)

        let primaryBabies = try context.fetch(primaryRequest)

        // Fetch babies where user is a caregiver
        let caregiverRequest = NSFetchRequest<CDBabyCaregiver>(entityName: "CDBabyCaregiver")
        caregiverRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)

        let caregiverLinks = try context.fetch(caregiverRequest)
        let caregiverBabyIds = caregiverLinks.compactMap { $0.babyId }

        // Fetch those babies
        var allBabies = primaryBabies
        for babyId in caregiverBabyIds {
            let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
            request.predicate = NSPredicate(format: "id == %@", babyId as CVarArg)
            if let babies = try? context.fetch(request) {
                allBabies.append(contentsOf: babies)
            }
        }

        // Remove duplicates and convert
        let uniqueIds = Set(allBabies.compactMap { $0.id })
        return allBabies
            .filter { baby in
                guard let id = baby.id else { return false }
                return uniqueIds.contains(id)
            }
            .compactMap { $0.toBaby() }
    }

    /// Fetches the first baby (for single-baby MVP)
    func fetchFirstBaby() throws -> Baby? {
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDBaby.createdAt, ascending: true)
        ]

        let results = try context.fetch(request)
        return results.first?.toBaby()
    }

    // MARK: - Caregiver Management

    /// Adds a caregiver to a baby
    func addCaregiver(babyId: UUID, userId: UUID, role: CaregiverRole) throws {
        let cdCaregiver = CDBabyCaregiver(context: context)
        cdCaregiver.babyId = babyId
        cdCaregiver.userId = userId
        cdCaregiver.role = role.rawValue
        cdCaregiver.joinedAt = Date()

        // Link to baby
        let request = NSFetchRequest<CDBaby>(entityName: "CDBaby")
        request.predicate = NSPredicate(format: "id == %@", babyId as CVarArg)
        if let baby = try context.fetch(request).first {
            cdCaregiver.baby = baby
        }

        try context.save()
    }

    /// Removes a caregiver from a baby
    func removeCaregiver(babyId: UUID, userId: UUID) throws {
        let request = NSFetchRequest<CDBabyCaregiver>(entityName: "CDBabyCaregiver")
        request.predicate = NSPredicate(
            format: "babyId == %@ AND userId == %@",
            babyId as CVarArg,
            userId as CVarArg
        )

        let results = try context.fetch(request)
        for caregiver in results {
            context.delete(caregiver)
        }

        try context.save()
    }

    /// Fetches all caregivers for a baby
    func fetchCaregivers(babyId: UUID) throws -> [BabyCaregiver] {
        let request = NSFetchRequest<CDBabyCaregiver>(entityName: "CDBabyCaregiver")
        request.predicate = NSPredicate(format: "babyId == %@", babyId as CVarArg)

        let results = try context.fetch(request)
        return results.compactMap { $0.toBabyCaregiver() }
    }

    /// Gets the role for a user with a specific baby
    func getRole(babyId: UUID, userId: UUID) throws -> CaregiverRole? {
        // Check if primary
        if let baby = try fetch(id: babyId), baby.primaryCaregiverId == userId {
            return .primary
        }

        // Check caregiver links
        let request = NSFetchRequest<CDBabyCaregiver>(entityName: "CDBabyCaregiver")
        request.predicate = NSPredicate(
            format: "babyId == %@ AND userId == %@",
            babyId as CVarArg,
            userId as CVarArg
        )
        request.fetchLimit = 1

        if let result = try context.fetch(request).first,
           let roleString = result.role,
           let role = CaregiverRole(rawValue: roleString) {
            return role
        }

        return nil
    }
}

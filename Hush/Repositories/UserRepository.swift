import Foundation
import CoreData

/// Repository for managing User persistence
@MainActor
final class UserRepository: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? PersistenceController.shared.viewContext
    }

    // MARK: - CRUD Operations

    /// Creates or updates a user
    func createOrUpdate(_ user: User) throws -> User {
        // Check if user exists
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        request.fetchLimit = 1

        if let existing = try context.fetch(request).first {
            existing.update(from: user)
        } else {
            let cdUser = CDUser(context: context)
            cdUser.update(from: user)
        }

        try context.save()
        return user
    }

    /// Fetches a user by ID
    func fetch(id: UUID) throws -> User? {
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toUser()
    }

    /// Fetches a user by email
    func fetch(email: String) throws -> User? {
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toUser()
    }

    /// Updates a user
    func update(_ user: User) throws -> User {
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        request.fetchLimit = 1

        guard let cdUser = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        cdUser.update(from: user)
        try context.save()
        return user
    }

    /// Deletes a user
    func delete(_ user: User) throws {
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        request.fetchLimit = 1

        guard let cdUser = try context.fetch(request).first else {
            throw RepositoryError.notFound
        }

        context.delete(cdUser)
        try context.save()
    }

    // MARK: - Current User

    /// Gets the current logged-in user (stored in UserDefaults)
    func getCurrentUser() throws -> User? {
        guard let userIdString = UserDefaults.standard.string(forKey: "currentUserId"),
              let userId = UUID(uuidString: userIdString) else {
            return nil
        }

        return try fetch(id: userId)
    }

    /// Sets the current logged-in user
    func setCurrentUser(_ user: User?) {
        if let user = user {
            UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentUserId")
        }
    }
}

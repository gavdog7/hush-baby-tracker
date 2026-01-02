import Foundation
import CoreData

@objc(CDUser)
public class CDUser: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var createdAt: Date?
}

// MARK: - Identifiable

extension CDUser: Identifiable {}

// MARK: - Domain Model Conversion

extension CDUser {
    /// Converts to domain model
    func toUser() -> User? {
        guard let id = id,
              let email = email,
              let displayName = displayName,
              let createdAt = createdAt else {
            return nil
        }

        return User(
            id: id,
            email: email,
            displayName: displayName,
            createdAt: createdAt
        )
    }

    /// Updates from domain model
    func update(from user: User) {
        self.id = user.id
        self.email = user.email
        self.displayName = user.displayName
        self.createdAt = user.createdAt
    }
}

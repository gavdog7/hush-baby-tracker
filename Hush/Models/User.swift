import Foundation

/// Represents a caregiver who can log events for babies
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let email: String
    var displayName: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

// MARK: - Firebase User Mapping

extension User {
    /// Creates a User from Firebase Auth user data
    init(firebaseUID: String, email: String?, displayName: String?) {
        // Use Firebase UID as a deterministic UUID seed
        self.id = UUID(uuidString: firebaseUID) ?? UUID()
        self.email = email ?? ""
        self.displayName = displayName ?? "Caregiver"
        self.createdAt = Date()
    }
}

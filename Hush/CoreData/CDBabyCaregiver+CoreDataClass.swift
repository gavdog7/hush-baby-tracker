import Foundation
import CoreData

@objc(CDBabyCaregiver)
public class CDBabyCaregiver: NSManagedObject {
    @NSManaged public var babyId: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var role: String?
    @NSManaged public var joinedAt: Date?
    @NSManaged public var baby: CDBaby?
}

// MARK: - Identifiable

extension CDBabyCaregiver: Identifiable {
    public var id: String {
        guard let babyId = babyId, let userId = userId else {
            return UUID().uuidString
        }
        return "\(babyId)-\(userId)"
    }
}

// MARK: - Domain Model Conversion

extension CDBabyCaregiver {
    /// Converts to domain model
    func toBabyCaregiver() -> BabyCaregiver? {
        guard let babyId = babyId,
              let userId = userId,
              let roleString = role,
              let role = CaregiverRole(rawValue: roleString),
              let joinedAt = joinedAt else {
            return nil
        }

        return BabyCaregiver(
            babyId: babyId,
            userId: userId,
            role: role,
            joinedAt: joinedAt
        )
    }

    /// Updates from domain model
    func update(from caregiver: BabyCaregiver) {
        self.babyId = caregiver.babyId
        self.userId = caregiver.userId
        self.role = caregiver.role.rawValue
        self.joinedAt = caregiver.joinedAt
    }
}

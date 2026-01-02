import Foundation
import CoreData

@objc(CDBaby)
public class CDBaby: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var birthDate: Date?
    @NSManaged public var primaryCaregiverId: UUID?
    @NSManaged public var settingsJSON: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var events: NSSet?
    @NSManaged public var caregivers: NSSet?
}

// MARK: - Identifiable

extension CDBaby: Identifiable {}

// MARK: - Relationship Accessors

extension CDBaby {
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: CDEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: CDEvent)

    @objc(addCaregiversObject:)
    @NSManaged public func addToCaregivers(_ value: CDBabyCaregiver)

    @objc(removeCaregiversObject:)
    @NSManaged public func removeFromCaregivers(_ value: CDBabyCaregiver)
}

// MARK: - Domain Model Conversion

extension CDBaby {
    /// Converts to domain model
    func toBaby() -> Baby? {
        guard let id = id,
              let name = name,
              let birthDate = birthDate,
              let primaryCaregiverId = primaryCaregiverId,
              let createdAt = createdAt else {
            return nil
        }

        let settings = decodeSettings()

        return Baby(
            id: id,
            name: name,
            birthDate: birthDate,
            primaryCaregiverId: primaryCaregiverId,
            settings: settings,
            createdAt: createdAt
        )
    }

    /// Updates from domain model
    func update(from baby: Baby) {
        self.id = baby.id
        self.name = baby.name
        self.birthDate = baby.birthDate
        self.primaryCaregiverId = baby.primaryCaregiverId
        self.settingsJSON = encodeSettings(baby.settings)
        self.createdAt = baby.createdAt
    }

    private func decodeSettings() -> BabySettings {
        guard let json = settingsJSON,
              let data = json.data(using: .utf8) else {
            return BabySettings()
        }

        do {
            return try JSONDecoder().decode(BabySettings.self, from: data)
        } catch {
            return BabySettings()
        }
    }

    private func encodeSettings(_ settings: BabySettings) -> String {
        do {
            let data = try JSONEncoder().encode(settings)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
}

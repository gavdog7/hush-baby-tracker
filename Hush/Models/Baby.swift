import Foundation

/// Represents a baby being tracked in the app
struct Baby: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var birthDate: Date
    let primaryCaregiverId: UUID
    var settings: BabySettings
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        primaryCaregiverId: UUID,
        settings: BabySettings = BabySettings(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.primaryCaregiverId = primaryCaregiverId
        self.settings = settings
        self.createdAt = createdAt
    }

    // MARK: - Age Calculations

    /// The baby's age in days
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }

    /// The baby's age in weeks
    var ageInWeeks: Int {
        ageInDays / 7
    }

    /// The baby's age in months (approximate)
    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }

    /// Human-readable age string (e.g., "3 months", "6 weeks")
    var ageDisplay: String {
        let months = ageInMonths
        let weeks = ageInWeeks

        if months >= 2 {
            return "\(months) months"
        } else if weeks >= 1 {
            return "\(weeks) \(weeks == 1 ? "week" : "weeks")"
        } else {
            let days = ageInDays
            return "\(days) \(days == 1 ? "day" : "days")"
        }
    }
}

// MARK: - Baby Settings

/// User-configurable settings for a baby
struct BabySettings: Codable, Equatable, Hashable {
    /// Default bottle size in ounces
    var defaultBottleSizeOz: Double

    /// Refrigerated bottle expiry time in hours (max 24)
    var refrigeratedExpiryHours: Int

    /// Whether to use metric units (ml instead of oz)
    var useMetricUnits: Bool

    init(
        defaultBottleSizeOz: Double = 4.0,
        refrigeratedExpiryHours: Int = 24,
        useMetricUnits: Bool = false
    ) {
        self.defaultBottleSizeOz = defaultBottleSizeOz
        self.refrigeratedExpiryHours = min(24, max(1, refrigeratedExpiryHours))
        self.useMetricUnits = useMetricUnits
    }

    /// Converts oz to ml if using metric
    func displayAmount(_ oz: Double) -> String {
        if useMetricUnits {
            let ml = oz * 29.5735
            return String(format: "%.0f ml", ml)
        } else {
            return String(format: "%.1f oz", oz)
        }
    }
}

// MARK: - Baby Caregiver Relationship

/// Represents the relationship between a baby and a caregiver
struct BabyCaregiver: Identifiable, Codable, Equatable, Hashable {
    var id: String { "\(babyId)-\(userId)" }

    let babyId: UUID
    let userId: UUID
    let role: CaregiverRole
    let joinedAt: Date

    init(babyId: UUID, userId: UUID, role: CaregiverRole, joinedAt: Date = Date()) {
        self.babyId = babyId
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAt
    }
}

/// The role a caregiver has for a baby
enum CaregiverRole: String, Codable, CaseIterable {
    case primary
    case caregiver

    var displayName: String {
        switch self {
        case .primary: return "Primary Caregiver"
        case .caregiver: return "Caregiver"
        }
    }

    /// Whether this role can delete the baby or remove other caregivers
    var canManageBaby: Bool {
        self == .primary
    }
}

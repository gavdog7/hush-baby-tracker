import Foundation

/// Data specific to feeding (eat) events
struct EatEventData: Codable, Equatable, Hashable {
    /// Amount of formula prepared in ounces
    var amountPreparedOz: Double

    /// Amount remaining after feeding in ounces (nil if still feeding or not yet fed)
    var amountRemainingOz: Double?

    /// When the baby started feeding from this bottle (nil if bottle is just prepared)
    var feedingStartedAt: EventTimestamp?

    /// Whether this bottle is stored in the refrigerator
    var isRefrigerated: Bool

    init(
        amountPreparedOz: Double,
        amountRemainingOz: Double? = nil,
        feedingStartedAt: EventTimestamp? = nil,
        isRefrigerated: Bool = false
    ) {
        self.amountPreparedOz = amountPreparedOz
        self.amountRemainingOz = amountRemainingOz
        self.feedingStartedAt = feedingStartedAt
        self.isRefrigerated = isRefrigerated
    }

    // MARK: - Computed Properties

    /// The amount consumed (prepared - remaining)
    var amountConsumedOz: Double? {
        guard let remaining = amountRemainingOz else { return nil }
        return amountPreparedOz - remaining
    }

    /// The current state of this bottle
    var state: BottleState {
        // If there's an amount remaining recorded, the feeding is finished
        if amountRemainingOz != nil {
            return .finished
        }

        // If feeding has started, we're actively feeding
        if feedingStartedAt != nil {
            return .feeding
        }

        // Otherwise just prepared (ready to feed)
        return isRefrigerated ? .refrigerated : .prepared
    }
}

// MARK: - Bottle State

/// The lifecycle state of a prepared bottle
enum BottleState: String, Codable {
    /// Bottle is prepared but baby hasn't started feeding (room temperature)
    case prepared

    /// Bottle is prepared and stored in refrigerator
    case refrigerated

    /// Baby is currently feeding from this bottle
    case feeding

    /// Feeding is complete
    case finished

    /// Bottle has expired and should be discarded
    case expired

    var displayName: String {
        switch self {
        case .prepared: return "Prepared"
        case .refrigerated: return "Refrigerated"
        case .feeding: return "Feeding"
        case .finished: return "Finished"
        case .expired: return "Expired"
        }
    }

    var isActive: Bool {
        self == .prepared || self == .refrigerated || self == .feeding
    }
}

// MARK: - Expiry Calculation

extension EatEventData {
    /// Calculates when this bottle will expire based on its state
    /// - Parameters:
    ///   - preparationTime: When the bottle was prepared
    ///   - refrigeratedExpiryHours: User setting for refrigerated expiry (max 24)
    /// - Returns: The expiry date, or nil if the bottle is finished/already handled
    func expiryDate(preparationTime: EventTimestamp, refrigeratedExpiryHours: Int = 24) -> Date? {
        switch state {
        case .prepared:
            // Room temp, not fed: 2 hours from preparation
            return preparationTime.utc.addingTimeInterval(2 * 60 * 60)

        case .refrigerated:
            // Refrigerated: configurable up to 24 hours
            let hours = min(24, max(1, refrigeratedExpiryHours))
            return preparationTime.utc.addingTimeInterval(Double(hours) * 60 * 60)

        case .feeding:
            // Once feeding starts: 1 hour from feeding start
            guard let feedingStart = feedingStartedAt else { return nil }
            return feedingStart.utc.addingTimeInterval(1 * 60 * 60)

        case .finished, .expired:
            return nil
        }
    }

    /// Time remaining until expiry
    func timeUntilExpiry(preparationTime: EventTimestamp, refrigeratedExpiryHours: Int = 24) -> TimeInterval? {
        guard let expiry = expiryDate(preparationTime: preparationTime, refrigeratedExpiryHours: refrigeratedExpiryHours) else {
            return nil
        }
        return expiry.timeIntervalSince(Date())
    }

    /// Whether this bottle is expired
    func isExpired(preparationTime: EventTimestamp, refrigeratedExpiryHours: Int = 24) -> Bool {
        guard let remaining = timeUntilExpiry(preparationTime: preparationTime, refrigeratedExpiryHours: refrigeratedExpiryHours) else {
            return false
        }
        return remaining <= 0
    }

    /// The expiry warning level based on time remaining
    func expiryWarningLevel(preparationTime: EventTimestamp, refrigeratedExpiryHours: Int = 24) -> ExpiryWarningLevel {
        guard let remaining = timeUntilExpiry(preparationTime: preparationTime, refrigeratedExpiryHours: refrigeratedExpiryHours) else {
            return .none
        }

        if remaining <= 0 {
            return .expired
        } else if remaining < 15 * 60 { // < 15 minutes
            return .urgent
        } else if remaining < 30 * 60 { // < 30 minutes
            return .warning
        } else {
            return .safe
        }
    }
}

/// Warning levels for bottle expiry
enum ExpiryWarningLevel {
    case none      // No expiry tracking (finished bottle)
    case safe      // > 30 minutes remaining (green)
    case warning   // 15-30 minutes remaining (yellow)
    case urgent    // < 15 minutes remaining (red)
    case expired   // Past expiry (grey strikethrough)
}

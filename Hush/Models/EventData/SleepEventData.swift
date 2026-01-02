import Foundation

/// Data specific to sleep events
///
/// Sleep events are simple - timing is stored in the parent Event's
/// startTime and endTime. This struct exists for consistency and
/// future extensibility.
struct SleepEventData: Codable, Equatable, Hashable {
    // Currently empty - timing handled by parent Event
    // Reserved for future fields like:
    // - sleepQuality: SleepQuality?
    // - location: SleepLocation?
    // - wokeUpReason: WakeReason?

    init() {}
}

// MARK: - Sleep State Helper

/// Helpers for working with sleep events
enum SleepState {
    case sleeping
    case awake

    var displayName: String {
        switch self {
        case .sleeping: return "Sleeping"
        case .awake: return "Awake"
        }
    }

    var icon: String {
        switch self {
        case .sleeping: return "moon.fill"
        case .awake: return "sun.max.fill"
        }
    }
}

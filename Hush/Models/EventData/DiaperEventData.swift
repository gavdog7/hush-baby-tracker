import Foundation

/// Data specific to diaper change events
struct DiaperEventData: Codable, Equatable, Hashable {
    /// What was in the diaper
    var contents: DiaperContents

    init(contents: DiaperContents = .both) {
        self.contents = contents
    }
}

// MARK: - Diaper Contents

/// What was found in the diaper
enum DiaperContents: String, Codable, CaseIterable {
    case wet
    case dirty
    case both

    var displayName: String {
        switch self {
        case .wet: return "Wet"
        case .dirty: return "Dirty"
        case .both: return "Both"
        }
    }

    var icon: String {
        switch self {
        case .wet: return "drop.fill"
        case .dirty: return "leaf.fill"
        case .both: return "drop.fill"
        }
    }

    var shortDisplay: String {
        switch self {
        case .wet: return "W"
        case .dirty: return "D"
        case .both: return "W+D"
        }
    }
}

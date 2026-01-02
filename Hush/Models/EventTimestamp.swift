import Foundation

/// Represents a timestamp with timezone information for proper display of historical events.
///
/// Events are stored in UTC but displayed in the timezone where they occurred.
/// This ensures historical events don't shift when users change timezones.
struct EventTimestamp: Codable, Equatable, Hashable {
    /// The timestamp in UTC
    let utc: Date

    /// The timezone identifier where the event occurred (e.g., "America/New_York")
    let timezoneIdentifier: String

    /// The offset in seconds from UTC at the time of the event
    let offsetSeconds: Int

    /// Creates a timestamp for the current moment in the device's current timezone
    init() {
        self.utc = Date()
        let tz = TimeZone.current
        self.timezoneIdentifier = tz.identifier
        self.offsetSeconds = tz.secondsFromGMT(for: utc)
    }

    /// Creates a timestamp with explicit values
    init(utc: Date, timezoneIdentifier: String, offsetSeconds: Int) {
        self.utc = utc
        self.timezoneIdentifier = timezoneIdentifier
        self.offsetSeconds = offsetSeconds
    }

    /// Creates a timestamp from a date, using the current timezone
    init(date: Date) {
        self.utc = date
        let tz = TimeZone.current
        self.timezoneIdentifier = tz.identifier
        self.offsetSeconds = tz.secondsFromGMT(for: date)
    }

    /// Creates a timestamp from a date in a specific timezone
    init(date: Date, timezone: TimeZone) {
        self.utc = date
        self.timezoneIdentifier = timezone.identifier
        self.offsetSeconds = timezone.secondsFromGMT(for: date)
    }

    // MARK: - Display Properties

    /// The timezone where this event occurred
    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? TimeZone.current
    }

    /// Returns the date for display in the original timezone
    /// This ensures historical events are shown in the timezone where they occurred
    var localDisplay: Date {
        utc
    }

    /// Formats the time for display in the original timezone
    func formatted(style: Date.FormatStyle = .dateTime) -> String {
        var adjustedStyle = style
        adjustedStyle.timeZone = timezone
        return utc.formatted(adjustedStyle)
    }

    /// Returns a relative time string (e.g., "2 hours ago")
    var relativeDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: utc, relativeTo: Date())
    }

    /// Returns just the time portion formatted for timeline display
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: utc)
    }

    /// Returns time with "Yesterday" prefix if applicable
    var timeDisplayWithDay: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(utc) {
            return timeDisplay
        } else if calendar.isDateInYesterday(utc) {
            return "Yesterday \(timeDisplay)"
        } else {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: utc)
        }
    }
}

// MARK: - Comparable

extension EventTimestamp: Comparable {
    static func < (lhs: EventTimestamp, rhs: EventTimestamp) -> Bool {
        lhs.utc < rhs.utc
    }
}

// MARK: - Duration Calculation

extension EventTimestamp {
    /// Calculates the duration between this timestamp and another
    func duration(to end: EventTimestamp) -> TimeInterval {
        end.utc.timeIntervalSince(utc)
    }

    /// Calculates the duration from this timestamp to now
    var durationUntilNow: TimeInterval {
        Date().timeIntervalSince(utc)
    }

    /// Returns a formatted duration string (e.g., "1h 23m")
    func formattedDuration(to end: EventTimestamp) -> String {
        let interval = duration(to: end)
        return Self.formatDuration(interval)
    }

    /// Formats a time interval as a human-readable duration
    static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

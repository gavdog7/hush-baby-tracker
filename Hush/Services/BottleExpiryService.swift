import Foundation
import UserNotifications

/// Manages bottle expiry tracking and notifications
@MainActor
final class BottleExpiryService {
    private let eventRepository: EventRepository
    private let notificationCenter = UNUserNotificationCenter.current()

    /// How many minutes before expiry to send notification
    private let warningMinutes = 15

    init(eventRepository: EventRepository? = nil) {
        self.eventRepository = eventRepository ?? EventRepository()
    }

    // MARK: - Notification Scheduling

    /// Schedules an expiry notification for a bottle
    func scheduleExpiryNotification(
        for event: Event,
        refrigeratedExpiryHours: Int = 24
    ) {
        guard event.eventType == .eat,
              let eatData = event.data.eatData,
              let expiryDate = eatData.expiryDate(
                  preparationTime: event.startTime,
                  refrigeratedExpiryHours: refrigeratedExpiryHours
              ) else {
            return
        }

        // Schedule notification 15 minutes before expiry
        let notificationDate = expiryDate.addingTimeInterval(-Double(warningMinutes) * 60)

        // Don't schedule if already past
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bottle Expiring Soon"
        content.body = "Your \(String(format: "%.1f", eatData.amountPreparedOz)) oz bottle expires in \(warningMinutes) minutes"
        content.sound = .default
        content.categoryIdentifier = "BOTTLE_EXPIRY"
        content.userInfo = ["eventId": event.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notificationDate
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "bottle-expiry-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule bottle expiry notification: \(error)")
            }
        }
    }

    /// Cancels the expiry notification for a bottle
    func cancelExpiryNotification(for event: Event) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["bottle-expiry-\(event.id.uuidString)"]
        )
    }

    /// Cancels all bottle expiry notifications
    func cancelAllExpiryNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            let bottleIds = requests
                .filter { $0.identifier.hasPrefix("bottle-expiry-") }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: bottleIds)
        }
    }

    // MARK: - Expiry Checking

    /// Checks all prepared bottles and returns expired ones
    func getExpiredBottles(
        babyId: UUID,
        refrigeratedExpiryHours: Int = 24
    ) throws -> [Event] {
        let preparedBottles = try eventRepository.fetchPreparedBottles(babyId: babyId)

        return preparedBottles.filter { event in
            guard let eatData = event.data.eatData else { return false }
            return eatData.isExpired(
                preparationTime: event.startTime,
                refrigeratedExpiryHours: refrigeratedExpiryHours
            )
        }
    }

    /// Checks all prepared bottles and returns ones expiring soon (within warning window)
    func getBottlesExpiringSoon(
        babyId: UUID,
        refrigeratedExpiryHours: Int = 24
    ) throws -> [Event] {
        let preparedBottles = try eventRepository.fetchPreparedBottles(babyId: babyId)

        return preparedBottles.filter { event in
            guard let eatData = event.data.eatData else { return false }

            guard let remaining = eatData.timeUntilExpiry(
                preparationTime: event.startTime,
                refrigeratedExpiryHours: refrigeratedExpiryHours
            ) else {
                return false
            }

            // Between 0 and warning threshold
            return remaining > 0 && remaining <= Double(warningMinutes) * 60
        }
    }

    // MARK: - Notification Categories

    /// Registers notification categories for bottle actions
    func registerNotificationCategories() {
        let startFeedingAction = UNNotificationAction(
            identifier: "START_FEEDING",
            title: "Start Feeding",
            options: [.foreground]
        )

        let discardAction = UNNotificationAction(
            identifier: "DISCARD",
            title: "Discard",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "BOTTLE_EXPIRY",
            actions: [startFeedingAction, discardAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([category])
    }
}

// MARK: - Quiet Hours

extension BottleExpiryService {
    /// Checks if the current time is within quiet hours
    func isWithinQuietHours(
        start: Int = 22,  // 10 PM
        end: Int = 6      // 6 AM
    ) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        if start > end {
            // Crosses midnight (e.g., 22:00 - 06:00)
            return hour >= start || hour < end
        } else {
            // Same day (e.g., 14:00 - 18:00)
            return hour >= start && hour < end
        }
    }

    /// Schedules a notification respecting quiet hours
    func scheduleExpiryNotificationWithQuietHours(
        for event: Event,
        refrigeratedExpiryHours: Int = 24,
        quietHoursEnabled: Bool = true,
        quietStart: Int = 22,
        quietEnd: Int = 6
    ) {
        guard event.eventType == .eat,
              let eatData = event.data.eatData,
              let expiryDate = eatData.expiryDate(
                  preparationTime: event.startTime,
                  refrigeratedExpiryHours: refrigeratedExpiryHours
              ) else {
            return
        }

        var notificationDate = expiryDate.addingTimeInterval(-Double(warningMinutes) * 60)

        // Adjust for quiet hours if enabled
        if quietHoursEnabled {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: notificationDate)

            let isQuiet: Bool
            if quietStart > quietEnd {
                isQuiet = hour >= quietStart || hour < quietEnd
            } else {
                isQuiet = hour >= quietStart && hour < quietEnd
            }

            if isQuiet {
                // Delay to end of quiet hours
                var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                components.hour = quietEnd
                components.minute = 0

                if let adjustedDate = calendar.date(from: components) {
                    // If the adjusted time is before the original, add a day
                    if adjustedDate <= notificationDate {
                        notificationDate = calendar.date(byAdding: .day, value: 1, to: adjustedDate) ?? adjustedDate
                    } else {
                        notificationDate = adjustedDate
                    }
                }
            }
        }

        // Don't schedule if already past
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bottle Expiring Soon"
        content.body = "Your \(String(format: "%.1f", eatData.amountPreparedOz)) oz bottle expires in \(warningMinutes) minutes"
        content.sound = .default
        content.categoryIdentifier = "BOTTLE_EXPIRY"
        content.userInfo = ["eventId": event.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notificationDate
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "bottle-expiry-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule bottle expiry notification: \(error)")
            }
        }
    }
}

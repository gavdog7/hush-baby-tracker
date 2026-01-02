import Foundation

/// Predicts optimal nap times based on baby's age and historical patterns
@MainActor
final class WakeWindowPredictor {
    private let eventRepository: EventRepository

    /// Minimum successful sleep duration to include in calculations (20 minutes)
    private let minimumSleepDuration: TimeInterval = 20 * 60

    /// Number of days for rolling average calculation
    private let rollingWindowDays = 14

    /// Minimum data points required for personalization
    private let minimumDataPoints = 5

    init(eventRepository: EventRepository? = nil) {
        self.eventRepository = eventRepository ?? EventRepository()
    }

    // MARK: - Prediction

    /// Generates a nap prediction for the given baby
    func predictNextNap(baby: Baby, lastWakeTime: Date) -> NapPrediction {
        // Get age-based default range
        let ageRange = getAgeBasedRange(babyAgeDays: baby.ageInDays)

        // Try to get personalized range
        let personalizedRange = getPersonalizedRange(babyId: baby.id)

        // Blend ranges if we have enough data
        let (minMinutes, maxMinutes) = blendRanges(
            ageRange: ageRange,
            personalizedRange: personalizedRange
        )

        // Apply time-of-day adjustments
        let adjustment = getTimeOfDayAdjustment(for: lastWakeTime)
        let adjustedMin = Int(Double(minMinutes) * adjustment)
        let adjustedMax = Int(Double(maxMinutes) * adjustment)

        // Calculate predicted window
        let predictedStart = lastWakeTime.addingTimeInterval(Double(adjustedMin) * 60)
        let predictedEnd = lastWakeTime.addingTimeInterval(Double(adjustedMax) * 60)

        // Determine confidence
        let confidence: PredictionConfidence = (personalizedRange != nil && personalizedRange!.dataPoints >= 10)
            ? .high
            : .learning

        return NapPrediction(
            baby: baby,
            predictedStart: predictedStart,
            predictedEnd: predictedEnd,
            wakeWindowMinutes: (adjustedMin, adjustedMax),
            confidence: confidence,
            basedOnDataPoints: personalizedRange?.dataPoints ?? 0,
            explanation: generateExplanation(
                baby: baby,
                isPersonalized: personalizedRange != nil,
                avgWakeWindow: personalizedRange?.avgMinutes
            )
        )
    }

    // MARK: - Age-Based Defaults

    /// Returns the default wake window range for a baby's age (in minutes)
    private func getAgeBasedRange(babyAgeDays: Int) -> (min: Int, max: Int) {
        let weeks = babyAgeDays / 7
        let months = babyAgeDays / 30

        switch true {
        case weeks < 4:     // 0-4 weeks
            return (30, 60)
        case weeks < 12:    // 4-12 weeks
            return (60, 90)
        case months < 4:    // 3-4 months
            return (75, 120)
        case months < 7:    // 5-7 months (use 5 as lower bound)
            return (120, 180)
        case months < 10:   // 7-10 months
            return (150, 210)
        case months < 14:   // 10-14 months
            return (180, 240)
        case months < 18:   // 14-18 months
            return (240, 360)
        default:            // 18+ months
            return (300, 420)
        }
    }

    /// Handles blending between age ranges during transitions
    func getBlendedWakeWindowRange(babyAgeDays: Int) -> (min: Int, max: Int) {
        let currentRange = getAgeBasedRange(babyAgeDays: babyAgeDays)

        // Check if we're within 7 days of a transition
        let transitionDays = [28, 84, 120, 210, 300, 420, 540] // Age thresholds in days
        var transitionProgress: Double?

        for threshold in transitionDays {
            let daysFromThreshold = babyAgeDays - threshold
            if daysFromThreshold >= 0 && daysFromThreshold < 7 {
                transitionProgress = Double(daysFromThreshold) / 7.0
                break
            }
        }

        guard let progress = transitionProgress else {
            return currentRange
        }

        // Get the previous range
        let previousRange = getAgeBasedRange(babyAgeDays: babyAgeDays - 7)

        // Blend: start at 80% old, 20% new → 100% new over 7 days
        let oldWeight = 1.0 - (progress * 0.8)
        let newWeight = progress * 0.8 + 0.2

        let blendedMin = Int(Double(previousRange.min) * oldWeight + Double(currentRange.min) * newWeight)
        let blendedMax = Int(Double(previousRange.max) * oldWeight + Double(currentRange.max) * newWeight)

        return (blendedMin, blendedMax)
    }

    // MARK: - Personalization

    private struct PersonalizedData {
        let avgMinutes: Int
        let dataPoints: Int
    }

    private func getPersonalizedRange(babyId: UUID) -> PersonalizedData? {
        // Get sleep events from the last 14 days
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -rollingWindowDays,
            to: Date()
        ) ?? Date()

        guard let events = try? eventRepository.fetchEvents(
            babyId: babyId,
            from: startDate,
            to: Date()
        ) else {
            return nil
        }

        // Filter to successful sleeps
        let sleepEvents = events
            .filter { $0.eventType == .sleep }
            .filter { event in
                guard let duration = event.duration else { return false }
                return duration >= minimumSleepDuration
            }
            .sorted { $0.startTime.utc < $1.startTime.utc }

        guard sleepEvents.count >= minimumDataPoints else {
            return nil
        }

        // Calculate wake windows (time between sleeps)
        var wakeWindows: [TimeInterval] = []

        for i in 1..<sleepEvents.count {
            let previousSleep = sleepEvents[i - 1]
            let currentSleep = sleepEvents[i]

            guard let previousEnd = previousSleep.endTime else { continue }

            let wakeWindow = currentSleep.startTime.utc.timeIntervalSince(previousEnd.utc)

            // Only include reasonable wake windows (15 min to 8 hours)
            if wakeWindow >= 15 * 60 && wakeWindow <= 8 * 60 * 60 {
                wakeWindows.append(wakeWindow)
            }
        }

        guard !wakeWindows.isEmpty else { return nil }

        let avgSeconds = wakeWindows.reduce(0, +) / Double(wakeWindows.count)
        let avgMinutes = Int(avgSeconds / 60)

        return PersonalizedData(avgMinutes: avgMinutes, dataPoints: wakeWindows.count)
    }

    private func blendRanges(
        ageRange: (min: Int, max: Int),
        personalizedRange: PersonalizedData?
    ) -> (min: Int, max: Int) {
        guard let personalized = personalizedRange else {
            return ageRange
        }

        // Clamp personalized average to 0.8x-1.2x of age-based bounds
        let clampedAvg = max(
            Int(Double(ageRange.min) * 0.8),
            min(Int(Double(ageRange.max) * 1.2), personalized.avgMinutes)
        )

        // Create a range around the average (±15%)
        let rangeSpread = 0.15
        let minMinutes = Int(Double(clampedAvg) * (1 - rangeSpread))
        let maxMinutes = Int(Double(clampedAvg) * (1 + rangeSpread))

        return (minMinutes, maxMinutes)
    }

    // MARK: - Time of Day Adjustment

    private func getTimeOfDayAdjustment(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)

        if hour < 9 {
            return 0.9  // Earlier naps tend to have shorter wake windows
        } else if hour >= 17 {
            return 1.1  // Evening naps often have longer wake windows
        } else {
            return 1.0
        }
    }

    // MARK: - Explanation

    private func generateExplanation(
        baby: Baby,
        isPersonalized: Bool,
        avgWakeWindow: Int?
    ) -> String {
        if isPersonalized, let avg = avgWakeWindow {
            let hours = avg / 60
            let mins = avg % 60
            let durationStr = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
            return "Based on \(baby.name)'s age (\(baby.ageDisplay)) and average wake time this week (\(durationStr))"
        } else {
            return "Based on typical wake windows for \(baby.ageDisplay)-olds. Predictions will improve as we learn \(baby.name)'s patterns."
        }
    }
}

// MARK: - Nap Prediction

struct NapPrediction: Identifiable {
    let id = UUID()
    let baby: Baby
    let predictedStart: Date
    let predictedEnd: Date
    let wakeWindowMinutes: (min: Int, max: Int)
    let confidence: PredictionConfidence
    let basedOnDataPoints: Int
    let explanation: String

    /// Formatted time range for display (e.g., "2:30 - 3:00 PM")
    var timeRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"

        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "h:mm a"

        return "\(formatter.string(from: predictedStart)) - \(endFormatter.string(from: predictedEnd))"
    }

    /// Whether this prediction is currently active (now is within the window)
    var isActive: Bool {
        let now = Date()
        return now >= predictedStart && now <= predictedEnd
    }

    /// Whether this prediction is in the future
    var isFuture: Bool {
        Date() < predictedStart
    }
}

enum PredictionConfidence: String {
    case high = "high"
    case learning = "learning"

    var displayText: String {
        switch self {
        case .high: return "High confidence"
        case .learning: return "Still learning"
        }
    }

    var icon: String {
        switch self {
        case .high: return "checkmark.circle.fill"
        case .learning: return "sparkles"
        }
    }
}

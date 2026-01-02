# Baby Tracker App
## Product Requirements Document v1.1
**Date:** January 2026

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Design Principles](#2-product-vision--design-principles)
3. [App Naming & Branding Suggestions](#3-app-naming--branding-suggestions)
4. [Functional Requirements](#4-functional-requirements)
5. [Formula Safety Rules (Evidence-Based)](#5-formula-safety-rules-evidence-based)
6. [Wake Window Guidelines (Evidence-Based)](#6-wake-window-guidelines-evidence-based)
7. [Technical Requirements](#7-technical-requirements)
8. [Data Model](#8-data-model)
9. [UI/UX Specifications](#9-uiux-specifications)
10. [Notification Strategy](#10-notification-strategy)
11. [Privacy & Security](#11-privacy--security)
12. [Edge Cases & State Management](#12-edge-cases--state-management)
13. [Data Export Specification](#13-data-export-specification)
14. [Future Roadmap (Post-MVP)](#14-future-roadmap-post-mvp)
15. [Success Metrics](#15-success-metrics)
16. [Appendix: Huckleberry Pain Points](#appendix-huckleberry-pain-points)

---

## 1. Executive Summary

This document outlines the requirements for a radically simplified baby tracking app designed for infants aged 0-18 months. The app focuses on three essential tracking categories—Eat (formula bottles), Sleep, and Diaper—with a timeline-centric interface that prioritizes one-handed operation and minimal cognitive load for exhausted caregivers.

The core differentiator is ruthless simplicity: one page, one timeline, three buttons. Where competitors like Huckleberry have become bloated with features, this app does fewer things but does them better. The timeline shows both history and predictions, making caregiver handovers seamless and day planning intuitive.

---

## 2. Product Vision & Design Principles

### Vision Statement

> The easiest-to-use baby tracking app in the world. Every interaction should be completable one-handed in under 3 seconds. The timeline tells you everything you need to know at a glance.

### Core Design Principles

- **One-Page Philosophy:** The entire app lives on a single screen. Settings exist but are accessed infrequently; the main timeline is where users spend 95% of their time.

- **Happy Path Optimization:** The default flow is ultra-streamlined with zero configuration required. One tap logs an event with smart defaults. Power users can access settings, but the happy path requires no navigation, no decisions, no friction.

- **Timeline-Centric:** The timeline is the product. It shows history, current state, and predictions in one scrollable view.

- **One-Handed Operation:** Every action must be completable with one hand while holding a baby. Large tap targets, minimal typing.

- **Reduce Cognitive Load:** Do calculations for the user. Don't ask them to subtract bottle amounts—ask what's left and calculate consumption. Hide complexity behind sensible defaults.

- **Essential Only:** Track only what matters for daily caregiving. No weight tracking, no bath logging, no tummy time counters.

- **Offline-First Reliability:** Works offline, syncs seamlessly when online. Caregivers must trust their data is safe.

### Configurability Philosophy

Configuration exists for users who need it, but defaults should work for 90% of users without any changes. Settings are accessed via a profile icon that's visually de-emphasized. The app never prompts users to configure anything—it just works out of the box.

### Competitive Positioning

Huckleberry and similar apps have accumulated feature bloat: weight tracking, bath logging, medicine schedules, temperature charts, and multi-page navigation. This creates friction for the core use case. Our app wins by doing less, better. We are the "do one thing well" alternative for parents who want simplicity.

---

## 3. App Naming & Branding Suggestions

The name should convey simplicity, clarity, and ease of use. It should feel calm and trustworthy—the opposite of the chaos of new parenthood.

### Recommended Names

1. **Glance** — See everything at a glance. Simple, memorable, conveys the timeline-at-a-glance value proposition.

2. **Hush** — Calm, quiet, simple. Contrasts with the noise of feature-heavy apps. Evokes peaceful baby moments.

3. **Nudge** — Gentle reminders for wake windows and bottle expiry. Friendly and non-intrusive.

4. **Tempo** — The rhythm of your baby's day. Elegant, references the timeline-based design.

5. **TinyLog** — Descriptive, cute, emphasizes minimal logging. Clear what the app does.

### Branding Direction

- **Color palette:** Soft, calming colors—muted blues, gentle greens, warm neutrals. Avoid bright primary colors.

- **Typography:** Clean sans-serif fonts with excellent readability at various sizes. Use SF Pro (iOS native) for optimal system integration.

- **Tone:** Reassuring, helpful, never condescending. Speak to exhausted parents with empathy.

- **App icon:** Simple, recognizable silhouette. Consider a timeline element, a gentle wave, or an abstract baby-related shape.

---

## 4. Functional Requirements

### 4.1 Main Timeline View

The timeline is the heart of the app, occupying approximately 75% of the screen real estate.

#### Timeline Specifications

| Attribute | Specification |
|-----------|---------------|
| Default View | 6 hours in the past, 3 hours in the future (9-hour window) |
| Scroll Direction | Vertical scroll—up to see future, down to see past |
| Current Time | Clearly marked with a "now" indicator line |
| Event Display | Color-coded blocks for Sleep, Eat, Diaper events |
| Active States | Ongoing sleep and prepared bottles shown prominently at "now" line |
| Predictions | Wake window predictions shown as semi-transparent blocks in the future |
| Bottle Expiry | Active bottles show countdown timer and visual expiry indicator |

#### Rationale for Timeline Window

The 6-hour past / 3-hour future default is optimized for caregiver handovers. When one parent takes over from another, they need to quickly see: when the baby last ate, when they last slept, when the last diaper change occurred, and what's coming up soon. Six hours of history covers a typical caregiving shift; three hours forward shows the next nap window and feeding opportunity without overwhelming the display.

### 4.2 Tracking Categories

Three action buttons at the top of the screen: **Eat**, **Sleep**, **Diaper**.

#### Eat (Formula Bottle) Tracking

| Field | Details |
|-------|---------|
| Bottle Made | Timestamp when formula was prepared (defaults to "now" with one tap) |
| Amount Prepared | Volume in oz or ml (remembers last used amount as default) |
| Feeding Started | Optional timestamp when feeding began |
| Amount Remaining | User enters what's LEFT; app calculates consumption |
| Expiry Timer | Countdown shown on timeline from bottle creation |
| Notes | Optional free-text field (hidden by default, accessible via "Add note" link) |

#### Bottle States

A bottle progresses through distinct states:

| State | Description | Timeline Display |
|-------|-------------|------------------|
| Prepared | Bottle made but feeding not started | Green bottle icon with expiry countdown (2hr) |
| Feeding | Feeding in progress | Pulsing green indicator, expiry countdown (1hr from start) |
| Finished | Feeding complete, amount remaining logged | Solid green block showing amount consumed |
| Expired | Time limit exceeded | Red/grey strikethrough, marked as waste |

#### Sleep Tracking

| Field | Details |
|-------|---------|
| Sleep Start | One tap to start (defaults to "now") |
| Sleep End | One tap to end current sleep session |
| Duration | Auto-calculated and displayed |
| Wake Window | Prediction for next sleep shown on timeline |
| Notes | Optional free-text field (hidden by default) |

#### Active Sleep Indicator

When baby is currently sleeping, the timeline shows:
- A purple block extending from sleep start time to the "now" line
- Running duration counter displayed on the block (e.g., "1h 23m")
- The Sleep button changes to "End Sleep" with a stop icon

#### Diaper Tracking

| Field | Details |
|-------|---------|
| Timestamp | One tap to log (defaults to "now") |
| Contents | Quick toggle: Wet / Dirty / Both |
| Notes | Optional free-text field (hidden by default) |

### 4.3 Active State Handling

The app must gracefully handle ongoing events:

#### Preventing Multiple Active Sleeps

When user taps "Sleep" while a sleep session is already active:

1. Show a bottom sheet: "Baby is currently sleeping (1h 23m)"
2. Two options:
   - **"End Sleep"** — Ends current sleep at current time, does not start new sleep
   - **"Cancel"** — Dismisses sheet, no action taken

This requires one extra tap but prevents accidental duplicate sleeps.

#### Prepared Bottle Reminder

If a bottle is prepared but feeding hasn't started within 30 minutes, show a subtle reminder on the timeline (not a push notification—that would be too aggressive for MVP).

### 4.4 Caregiver Handover Support

While there's no explicit "handover" feature, the design optimizes for this use case:

- **Glanceable Summary:** The visible timeline window (6hr past) shows everything a new caregiver needs
- **Quick Stats:** Tapping the baby's name in the header shows: last feed (time + amount), last sleep (time + duration), last diaper (time + type)
- **Caregiver Attribution:** Who logged each event is visible when tapping into event details

### 4.5 Event Editing & History

- **Tap to Edit:** Tapping any event on the timeline opens edit mode for that event.

- **Time Adjustment:** All timestamps can be manually adjusted ("baby fell asleep 10 minutes ago").

- **Delete Events:** Swipe-to-delete or delete button in edit mode.

- **Caregiver Attribution:** Who logged the event is recorded automatically. Viewable by tapping into event details (not cluttering main timeline).

- **Future: Undo History:** Post-MVP, maintain edit history so accidental changes can be reverted.

### 4.6 Profile & Settings

Accessed via a small, visually de-emphasized profile icon in the corner. Users should rarely need to access this.

- **Baby Info:** Name, birthdate (used to calculate age-appropriate wake windows).

- **Caregivers:** Primary caregiver manages invite codes for additional caregivers.

- **Formula Settings:** Default bottle size, expiry window override (for refrigerated bottles).

- **Units:** oz vs ml preference.

- **Notifications:** Toggle for bottle expiry and wake window reminders.

- **Dark Mode:** System default / always on / always off.

- **Export Data:** One-tap CSV export to clipboard or share sheet.

---

## 5. Formula Safety Rules (Evidence-Based)

These guidelines are derived from CDC, FDA, and American Academy of Pediatrics recommendations. They work out of the box with sensible defaults; configuration is available for edge cases but not required.

### Expiry Windows

| Scenario | Time Limit |
|----------|------------|
| Prepared formula, room temperature, NOT fed | 2 hours from preparation |
| Prepared formula, room temperature, feeding STARTED | 1 hour from first sip |
| Prepared formula, refrigerated | 24 hours from preparation |
| Opened powder formula container | 30 days (or per manufacturer) |

### App Implementation

- **Default Expiry:** 2 hours from bottle preparation (room temperature scenario).

- **Feeding Started Override:** When user logs "feeding started," expiry changes to 1 hour from that moment.

- **Visual Countdown:** Show remaining time on timeline. Change color as expiry approaches (green → yellow at 30min → red at 15min).

- **Notification:** Optional push notification at 15 minutes before expiry (default: on).

- **Configurable:** Users can adjust expiry windows in settings if using refrigerated bottles. This is an edge case; most users won't touch this.

### Sources

CDC Infant Formula Preparation and Storage guidelines; FDA Safe Handling of Infant Formula; American Academy of Pediatrics HealthyChildren.org recommendations.

---

## 6. Wake Window Guidelines (Evidence-Based)

Wake windows are the period between when a baby wakes up and when they should next sleep. These guidelines are derived from pediatric sleep research and sources including the American Academy of Pediatrics, Taking Cara Babies, and the Sleep Foundation.

### Age-Based Wake Window Defaults

| Age | Wake Window Range | Typical Naps/Day |
|-----|-------------------|------------------|
| 0-4 weeks | 30-60 minutes | 6-8 naps |
| 4-12 weeks | 60-90 minutes | 4-6 naps |
| 3-4 months | 75-120 minutes | 3-5 naps |
| 5-7 months | 2-3 hours | 2-3 naps |
| 7-10 months | 2.5-3.5 hours | 2 naps |
| 10-14 months | 3-4 hours | 1-2 naps |
| 14-18 months | 4-6 hours | 1 nap |

### Algorithm Specification

The wake window prediction algorithm is designed to be simple, explainable, and conservative.

#### Inputs

```
baby_age_days: int              # Calculated from birth_date
last_wake_time: timestamp       # When baby woke from last sleep
sleep_history: [SleepEvent]     # Last 14 days of sleep data
current_time: timestamp
```

#### Algorithm Pseudocode

```python
def predict_next_sleep_window(baby_age_days, last_wake_time, sleep_history, current_time):
    # Step 1: Get age-based defaults
    base_range = get_age_based_range(baby_age_days)
    # Returns (min_minutes, max_minutes), e.g., (75, 120) for 3-4 months

    # Step 2: Calculate historical average (if sufficient data)
    recent_wake_windows = []
    for sleep in sleep_history[-14_days]:
        if sleep.previous_wake_time:
            wake_duration = sleep.start_time - sleep.previous_wake_time
            # Only include "successful" sleeps (baby slept > 20 minutes)
            if sleep.duration_minutes >= 20:
                recent_wake_windows.append(wake_duration)

    # Step 3: Compute personalized range
    if len(recent_wake_windows) >= 5:
        # Enough data to personalize
        avg_wake = mean(recent_wake_windows)
        std_wake = std_deviation(recent_wake_windows)

        # Use historical data, but clamp to age-appropriate bounds
        personal_min = max(avg_wake - std_wake, base_range.min * 0.8)
        personal_max = min(avg_wake + std_wake, base_range.max * 1.2)
    else:
        # Cold start: use age-based defaults
        personal_min = base_range.min
        personal_max = base_range.max

    # Step 4: Apply time-of-day adjustment
    hour_of_day = last_wake_time.hour
    if hour_of_day < 9:
        # First wake window of day: bias shorter (baby often tired)
        adjustment = 0.9
    elif hour_of_day > 17:
        # Evening: bias longer (building sleep pressure for night)
        adjustment = 1.1
    else:
        adjustment = 1.0

    adjusted_min = personal_min * adjustment
    adjusted_max = personal_max * adjustment

    # Step 5: Calculate predicted window
    predicted_start = last_wake_time + adjusted_min
    predicted_end = last_wake_time + adjusted_max

    return {
        "range_start": predicted_start,
        "range_end": predicted_end,
        "confidence": "high" if len(recent_wake_windows) >= 10 else "learning",
        "explanation": generate_explanation(baby_age_days, recent_wake_windows)
    }

def generate_explanation(baby_age_days, history):
    age_months = baby_age_days // 30
    if len(history) >= 5:
        avg_mins = mean(history)
        return f"Based on {baby_name}'s age ({age_months} months) and average wake time this week ({format_duration(avg_mins)})"
    else:
        return f"Based on typical wake windows for {age_months}-month-olds. Predictions will improve as we learn {baby_name}'s patterns."
```

#### Edge Cases

- **No sleep data yet:** Use age-based defaults with "learning" confidence indicator
- **Irregular day (travel, illness):** Algorithm continues using rolling 14-day average; one bad day doesn't skew predictions significantly
- **Age transition:** When baby crosses an age threshold, blend old and new ranges over 7 days to avoid jarring prediction changes

### Display

- Show prediction as a range on the timeline: shaded block from `range_start` to `range_end`
- Label: "Nap window" with time range (e.g., "2:30 - 3:00 PM")
- Tappable to show explanation text

---

## 7. Technical Requirements

### 7.1 Platform

| Attribute | Specification |
|-----------|---------------|
| Platform | iOS only (MVP) |
| Target Device | iPhone 16 Pro and later (optimized), iPhone 12+ (supported) |
| Min iOS Version | iOS 17+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI (required—no React Native) |

#### Rationale for SwiftUI

SwiftUI provides the best path to a polished, native iOS experience. Key advantages:
- Native performance characteristics
- Seamless integration with iOS system features (widgets, shortcuts, notifications)
- Access to latest iOS APIs without bridging overhead
- Smaller app binary size
- No cross-platform abstraction tax

### 7.2 Performance Requirements

The app must feel instant and fluid. Target device: iPhone 16 Pro.

| Metric | Requirement |
|--------|-------------|
| Cold Launch | < 1.0 second to interactive timeline |
| Warm Launch | < 0.3 seconds |
| Timeline Scroll | 120fps smooth scrolling (ProMotion) |
| Event Logging | < 100ms from tap to visual confirmation |
| Memory Usage | < 100MB typical, < 200MB peak |
| Battery Impact | Negligible background drain (< 1%/hour when backgrounded) |
| App Size | < 30MB download size |

#### Performance Testing

- Profile with Instruments before each release
- Automated performance regression tests in CI
- Test with 1,000+ events to ensure timeline remains responsive

### 7.3 Authentication & User Management

- **Primary Caregiver:** Signs up with email. This is the account owner.

- **Invite System:** Primary generates invite codes/links. Secondary caregivers sign up and enter code to join.

- **Authentication:** Email + password or Sign in with Apple (preferred).

- **Session:** Stay logged in unless explicitly logged out.

- **Permissions:** All caregivers can log/edit events. Only primary can delete baby or remove caregivers.

### 7.4 Data Sync & Conflict Resolution

- **Cloud Backend:** Firebase Firestore recommended for real-time sync with offline support.

- **Offline Support:** Local Core Data cache. App fully functional offline.

- **Sync Indicator:** Subtle visual indicator showing sync status (checkmark = synced, spinner = syncing, warning = offline with pending changes).

- **Data Retention:** All data retained indefinitely. Export provides full history.

#### Conflict Resolution Strategy

Simple last-write-wins is dangerous for baby data. Implement event-aware conflict detection:

```swift
struct ConflictDetector {
    /// Detects if a synced event conflicts with a local event
    func detectConflict(incoming: Event, local: Event) -> ConflictType? {
        // Same event ID = direct edit conflict
        if incoming.id == local.id && incoming.updatedAt != local.updatedAt {
            return .directEdit(incoming, local)
        }

        // Different IDs but overlapping time + same type = possible duplicate
        if incoming.babyId == local.babyId &&
           incoming.eventType == local.eventType &&
           incoming.id != local.id &&
           timesOverlap(incoming, local, thresholdMinutes: 5) {
            return .possibleDuplicate(incoming, local)
        }

        return nil
    }
}

enum ConflictResolution {
    case keepLocal
    case keepRemote
    case keepBoth  // For possible duplicates that are actually distinct
    case merge     // For direct edits, take latest non-null fields
}
```

#### Conflict UI

When conflicts are detected on sync:

1. **Direct Edit Conflict:** Show non-blocking banner: "This event was edited on another device. [View Changes]"
   - Tapping shows diff and lets user choose which version to keep

2. **Possible Duplicate:** Show banner: "Similar event logged by [Caregiver] at [time]. [Review]"
   - Tapping shows both events side-by-side
   - Options: "Keep Both" / "Keep Mine" / "Keep Theirs"

3. **No Conflict:** Sync silently

Design principle: Never lose data silently. When in doubt, keep both and let user clean up.

### 7.5 Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Local Storage | Core Data with CloudKit sync, or Core Data + Firebase |
| Backend | Firebase (Auth + Firestore) |
| Push Notifications | APNs via Firebase Cloud Messaging |
| Analytics | Privacy-respecting, minimal: PostHog or self-hosted Plausible |

---

## 8. Data Model

### Timestamp Handling

All timestamps are stored in UTC with timezone offset preserved. This ensures:
- Accurate sync between caregivers in different timezones
- Historical events display in the local time they occurred (not shifted)
- DST transitions handled correctly

```swift
struct EventTimestamp {
    let utc: Date                    // Absolute moment in time (for sync/ordering)
    let timezoneIdentifier: String   // e.g., "America/New_York"
    let offsetSeconds: Int           // Offset at time of creation (handles DST)

    var localDisplay: String {
        // Returns time formatted in original local timezone
    }
}
```

### Core Entities

#### User

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| email | String | Login email |
| display_name | String | Name shown to other caregivers |
| created_at | Timestamp | Account creation time |

#### Baby

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | String | Baby's name |
| birth_date | Date | Used to calculate age for wake windows |
| primary_caregiver_id | UUID (FK) | References User |
| settings | JSON | Default bottle size, units, etc. |
| created_at | Timestamp | Record creation time |

#### BabyCaregiver (Join Table)

| Field | Type | Description |
|-------|------|-------------|
| baby_id | UUID (FK) | References Baby |
| user_id | UUID (FK) | References User |
| role | Enum | primary / caregiver |
| joined_at | Timestamp | When caregiver was added |

#### Event (All tracking events)

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| baby_id | UUID (FK) | References Baby |
| logged_by | UUID (FK) | References User who logged it |
| event_type | Enum | eat / sleep / diaper |
| start_time | EventTimestamp | When event started (see Timestamp Handling) |
| end_time | EventTimestamp? | When event ended (null if ongoing) |
| data | JSON | Event-specific fields (see below) |
| notes | String? | Optional notes |
| created_at | Timestamp | Record creation time (UTC) |
| updated_at | Timestamp | Last update time (UTC) |
| deleted_at | Timestamp? | Soft delete timestamp |

### Event Data JSON Structures

**Eat Event:**

| Field | Type | Description |
|-------|------|-------------|
| amount_prepared | Float | Volume prepared (oz or ml) |
| amount_remaining | Float? | Volume remaining after feeding (null if not yet finished) |
| feeding_started_at | Timestamp? | When feeding began (null if bottle prepared but not yet fed) |

The `start_time` on the Event record represents when the bottle was prepared. This is the reference point for expiry calculations.

State derivation:
- `feeding_started_at == null` → Bottle prepared, not yet feeding
- `feeding_started_at != null && end_time == null` → Feeding in progress
- `end_time != null` → Feeding complete

```json
{
  "amount_prepared": 4,
  "amount_remaining": 0.5,
  "feeding_started_at": "2026-01-02T08:20:00Z"
}
```

**Sleep Event:**

No additional data fields. All timing captured in `start_time` and `end_time`.

```json
{}
```

**Diaper Event:**

| Field | Type | Description |
|-------|------|-------------|
| contents | Enum | "wet" / "dirty" / "both" |

```json
{
  "contents": "wet"
}
```

### Required Indexes

For timeline queries to perform well with large datasets:

```sql
-- Primary timeline query: events for a baby in time range
CREATE INDEX idx_events_baby_time ON events(baby_id, start_time DESC);

-- Finding active/ongoing events
CREATE INDEX idx_events_baby_active ON events(baby_id, event_type, end_time)
  WHERE end_time IS NULL AND deleted_at IS NULL;

-- Sync queries
CREATE INDEX idx_events_updated ON events(baby_id, updated_at DESC);

-- User's babies lookup
CREATE INDEX idx_baby_caregiver ON baby_caregiver(user_id, baby_id);
```

---

## 9. UI/UX Specifications

### Screen Layout

The app has ONE primary screen with the following layout from top to bottom:

| Section | Description |
|---------|-------------|
| Top Bar (~8%) | Profile icon (left corner, de-emphasized), baby name (center, tappable for quick stats), sync status indicator (right corner) |
| Action Buttons (~12%) | Three large buttons: EAT \| SLEEP \| DIAPER — equal width, large tap targets |
| Timeline (~80%) | Scrollable timeline showing past events, current time marker, active states, and future predictions |

### Interaction Patterns

- **Quick Log:** Single tap on action button logs event at current time with defaults. User can edit immediately or ignore.

- **Event Cards:** Tap any event on timeline to expand into a card for viewing/editing details.

- **Scroll Behavior:** Pull down to see future predictions; pull up to see older history.

- **Number Input:** For bottle amounts, use a quick stepper (+ and - buttons) not a keyboard. Faster one-handed.

- **Haptics:** Subtle haptic feedback on successful logging to confirm without requiring visual attention.

- **Notes Field:** Hidden by default. Small "Add note" link appears when editing an event. Notes are for edge cases, not the happy path.

### Active State Display

#### Active Sleep

When baby is sleeping:
- Purple block extends from sleep start to the "now" line
- Running timer displayed on block: "1h 23m"
- Block animates subtly (gentle pulse or shimmer) to indicate "live" state
- Sleep button transforms: icon becomes stop symbol, label changes to "End Sleep"

#### Prepared Bottle (Not Yet Feeding)

When bottle is prepared but feeding hasn't started:
- Green bottle icon pinned near "now" line
- Countdown timer: "Expires in 1h 42m"
- Color transitions: green → yellow (30min) → red (15min) → grey strikethrough (expired)
- Tapping bottle opens quick action: "Start Feeding" / "Discard" / "Edit"

#### Feeding In Progress

When actively feeding:
- Pulsing green indicator at "now" line
- Shows: "Feeding (started 12 min ago)"
- Expiry countdown based on feeding start time
- Tapping opens: "Finish Feeding" flow (enter amount remaining)

### Color Coding

| Event Type | Suggested Color | Notes |
|------------|-----------------|-------|
| Sleep | Soft purple/lavender (#9B8AA5) | Calming, associated with rest |
| Eat | Soft green (#7BAE7F) | Growth, nourishment |
| Diaper | Soft yellow/amber (#E5C07B) | Warm, attention-getting for important hygiene |
| Predictions | Semi-transparent | Use same colors at ~30% opacity for future events |
| Expiry Warning | Red/orange gradient | Urgency without alarm |

### Dark Mode

Dark mode is essential for nighttime feedings. Colors should be adjusted to reduce brightness while maintaining the same hue relationships. Use true black (#000000) backgrounds for OLED screens to maximize battery savings and reduce eye strain in dark rooms.

### Quick Stats Overlay

Tapping baby name in header shows a quick stats overlay (not a new page):

| Stat | Display |
|------|---------|
| Last Feed | "2h 15m ago (4oz)" |
| Last Sleep | "45 min (ended 1h ago)" |
| Last Diaper | "3h ago (wet)" |
| Awake For | "1h 32m" (if currently awake) |
| Sleeping For | "45m" (if currently sleeping) |

Overlay dismisses on tap outside or swipe down.

---

## 10. Notification Strategy

Notifications should be helpful, not nagging. Default to fewer notifications; let users opt into more.

### Notification Types

| Notification | Default | Trigger | Content |
|--------------|---------|---------|---------|
| Bottle Expiry | ON | 15 min before expiry | "Bottle expires in 15 minutes" |
| Wake Window | OFF | When predicted window starts | "Nap window starting—[Baby] may be getting tired" |
| Feeding Due | OFF | 3 hours since last feed | "[Baby] last ate 3 hours ago" |

### Multi-Caregiver Notifications

- All caregivers receive notifications by default
- Each caregiver can independently mute notifications in their settings
- Future: "Active caregiver" mode where only one person receives notifications (post-MVP)

### Notification Principles

- **Actionable:** Every notification should lead to a clear action
- **Dismissable:** Easy to dismiss, never nag repeatedly for same event
- **Respectful:** No notifications between 10pm-6am unless explicitly enabled
- **Batched:** If multiple things need attention, combine into one notification

### Implementation

Use local notifications for time-based alerts (bottle expiry). This works offline and doesn't require server infrastructure.

```swift
func scheduleBottleExpiryNotification(bottle: EatEvent) {
    let expiryTime = bottle.effectiveExpiryTime  // Accounts for feeding_started_at
    let notifyTime = expiryTime.addingTimeInterval(-15 * 60)  // 15 min before

    let content = UNMutableNotificationContent()
    content.title = "Bottle Expiring Soon"
    content.body = "Formula prepared at \(bottle.startTime.formatted()) expires in 15 minutes"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: notifyTime.timeIntervalSinceNow,
        repeats: false
    )

    // Cancel on feeding completion or bottle discard
}
```

---

## 11. Privacy & Security

### Data Protection

| Aspect | Implementation |
|--------|----------------|
| Encryption in Transit | TLS 1.3 for all API communication |
| Encryption at Rest | iOS Data Protection (NSFileProtectionComplete) |
| Backend Encryption | Firebase/Firestore default encryption |
| Authentication | Firebase Auth with secure token management |

### Privacy Principles

- **Minimal Data Collection:** Only collect data necessary for app functionality
- **No Advertising:** Never sell or share data with advertisers
- **No Third-Party Analytics IDs:** If using analytics, use privacy-respecting tools without cross-app tracking
- **User Control:** Users can export all their data and delete their account

### Analytics Policy

Analytics should answer product questions, not track individuals:

**Collected (anonymized):**
- Feature usage counts (how often each button is tapped)
- Crash reports
- Performance metrics (launch time, scroll performance)
- Retention metrics (DAU/MAU, session length)

**Never collected:**
- Baby names or personal information
- Specific event times or details
- Location data
- Device identifiers that persist across installs

### Data Deletion

- **Delete Event:** Soft delete with 30-day recovery window, then permanent deletion
- **Delete Baby:** Removes all events and caregiver associations after confirmation
- **Delete Account:** Removes all user data. If sole caregiver, prompts to transfer or delete baby data.

### GDPR/CCPA Compliance

- Privacy policy clearly explains data practices
- Users can request data export (JSON format)
- Users can request account deletion
- No data processing beyond core app functionality

---

## 12. Edge Cases & State Management

### Midnight & Day Transitions

The timeline should handle day boundaries gracefully:

- **Visual Separator:** Light horizontal line with date label when scrolling across midnight
- **Relative Times:** Display "Yesterday 11:30 PM" instead of just "11:30 PM" for clarity
- **Predictions Across Midnight:** Wake window predictions continue smoothly; no jarring reset at midnight

### Timezone Handling

**Strategy:** Store UTC + original timezone, display in original local time.

| Scenario | Behavior |
|----------|----------|
| Normal use | Events display in device's current timezone |
| Reviewing history after travel | Historical events show in the timezone where they occurred |
| Caregivers in different timezones | Each sees events in their own timezone (sync uses UTC) |

**Implementation:**
```swift
// When creating an event
let event = Event(
    startTime: EventTimestamp(
        utc: Date(),
        timezoneIdentifier: TimeZone.current.identifier,
        offsetSeconds: TimeZone.current.secondsFromGMT()
    )
)

// When displaying
func formatForDisplay(_ timestamp: EventTimestamp) -> String {
    // Use original timezone for context-preserving display
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: timestamp.timezoneIdentifier)
    return formatter.string(from: timestamp.utc)
}
```

### Daylight Saving Time

DST transitions are handled automatically by storing UTC:

- **Spring Forward:** No issue—UTC is unambiguous
- **Fall Back:** No issue—UTC is unambiguous
- **Display Quirk:** Events logged during the "repeated" hour (2:00 AM occurs twice) will display correctly because we store the offset at creation time

### Preventing Invalid States

#### Multiple Active Sleeps

Enforced at both UI and data layers:

**UI Prevention:**
```swift
func handleSleepButtonTap() {
    if let activeSleep = findActiveSleep() {
        showEndSleepSheet(activeSleep)  // "Baby is sleeping (1h 23m). End sleep?"
    } else {
        startNewSleep()
    }
}
```

**Data Layer Validation:**
```swift
func validateNewSleep(_ newSleep: SleepEvent) throws {
    let activeSleeps = events.filter {
        $0.eventType == .sleep &&
        $0.endTime == nil &&
        $0.deletedAt == nil
    }
    if !activeSleeps.isEmpty {
        throw ValidationError.sleepAlreadyActive(activeSleeps.first!)
    }
}
```

#### Multiple Active Bottles

Unlike sleep, multiple prepared bottles are valid (batch preparation). However, only one feeding can be "in progress":

```swift
func validateFeedingStart(_ bottle: EatEvent) throws {
    let activeFeedings = events.filter {
        $0.eventType == .eat &&
        $0.data.feedingStartedAt != nil &&
        $0.endTime == nil
    }
    if !activeFeedings.isEmpty {
        throw ValidationError.feedingAlreadyActive(activeFeedings.first!)
    }
}
```

### Age Threshold Transitions

When baby's age crosses a wake window threshold:

- **No Jarring Change:** Blend predictions over 7 days
- **Example:** Baby turns 4 months (75-120min range → 2-3 hour range)
  - Day 1: Use 80% old range, 20% new range
  - Day 4: Use 50% old, 50% new
  - Day 7: Use 100% new range

```swift
func getBlendedWakeWindowRange(babyAgeDays: Int) -> (min: Int, max: Int) {
    let currentRange = getAgeBasedRange(babyAgeDays)
    let previousRange = getAgeBasedRange(babyAgeDays - 7)

    // If ranges are different, we're in a transition period
    if currentRange != previousRange {
        let daysSinceTransition = daysIntoNewAgeRange(babyAgeDays)
        let blendFactor = min(1.0, Double(daysSinceTransition) / 7.0)

        return (
            min: Int(lerp(previousRange.min, currentRange.min, blendFactor)),
            max: Int(lerp(previousRange.max, currentRange.max, blendFactor))
        )
    }
    return currentRange
}
```

---

## 13. Data Export Specification

### CSV Format

Export should produce a clean CSV that's easy to paste into an LLM for analysis or import into spreadsheets.

#### Columns

```
date, time, event_type, duration_minutes, amount_prepared_oz, amount_consumed_oz, diaper_contents, logged_by, notes
```

#### Example Output

```csv
date,time,event_type,duration_minutes,amount_prepared_oz,amount_consumed_oz,diaper_contents,logged_by,notes
2026-01-02,08:15,eat,,4,3.5,,,
2026-01-02,09:30,sleep,45,,,,,Fussy before sleep
2026-01-02,10:20,diaper,,,,wet,Gavin,
2026-01-02,11:00,eat,,4,4,,,Finished whole bottle
2026-01-02,12:15,sleep,90,,,,,
2026-01-02,14:00,diaper,,,,both,Leanne,Blowout
```

### Export Options

- **Copy to Clipboard:** One-tap copy for pasting into ChatGPT, Claude, etc.

- **Share Sheet:** iOS share sheet for sending via email, AirDrop, saving to Files.

- **Date Range:** Option to export last 24 hours, last 7 days, last 30 days, or all time.

- **Include Headers:** First row contains column names.

---

## 14. Future Roadmap (Post-MVP)

These features are explicitly out of scope for MVP but should be considered for future iterations.

1. **Multi-child support:** Tabs or selector to switch between children.

2. **Breastfeeding tracking:** Duration per side, pumping volumes.

3. **Solids tracking:** For babies 6+ months starting complementary foods.

4. **Paid analytics tier:** Questionnaire + data analysis for personalized recommendations.

5. **Edit history / undo:** Full audit trail of changes with ability to revert.

6. **Widgets:** iOS home screen widgets showing last feed time, next predicted nap.

7. **Apple Watch app:** Quick logging from wrist.

8. **Siri shortcuts:** "Hey Siri, log a diaper change" voice integration.

9. **Android version:** Expand to Android after iOS product-market fit.

10. **Baby Brezza integration:** Auto-log when Baby Brezza dispenses formula (if API available).

---

## 15. Success Metrics

### MVP Success Criteria

- **Time to First Log:** New user can log first event within 60 seconds of opening app.

- **Log Speed:** Average time to log an event < 3 seconds (excluding notes).

- **Day 7 Retention:** > 50% of users who log one event return within 7 days.

- **Sync Reliability:** > 99.5% of events sync successfully across devices.

- **App Store Rating:** Target 4.5+ stars with emphasis on "simple" and "easy" in reviews.

- **Multi-caregiver Usage:** > 40% of active babies have 2+ caregivers logging.

### Prediction Accuracy

Wake window predictions should be genuinely helpful:

- **Metric:** "Prediction Hit Rate" — percentage of naps that start within the predicted window
- **Target:** > 70% of naps fall within predicted range after 2 weeks of use
- **Measurement:** Compare predicted window (range_start to range_end) against actual sleep start times
- **Feedback Loop:** If accuracy drops below 60% for a baby, show "learning" indicator and expand predicted ranges

---

## Appendix: Huckleberry Pain Points

Key problems with the incumbent that this app directly addresses:

| Huckleberry Problem | Our Solution |
|---------------------|--------------|
| Too many features cluttering main screen (weight, bath, tummy time, medicine, temperature) | Three buttons only: Eat, Sleep, Diaper |
| Timeline doesn't look forward—only shows history | Timeline shows both past and future predictions |
| Requires mental math for bottle consumption | User enters amount remaining; app calculates consumption |
| No bottle expiry tracking | Countdown timer from bottle prep with visual alerts |
| Multiple pages/tabs to navigate | Single-page design—everything on one screen |
| Unreliable offline sync | Offline-first architecture with clear sync status |
| Verbose, unhelpful insights | Simple, explainable wake window algorithm with pseudocode spec |
| $120/year for features most don't use | Free core features; sustainable model TBD |

---

*— End of Document —*

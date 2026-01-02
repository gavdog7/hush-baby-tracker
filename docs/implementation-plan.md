# Hush - Implementation Plan

## Overview

This document outlines the implementation plan for Hush, a simplified baby tracking iOS app. The plan is organized into phases, with each phase building on the previous one to deliver incremental value.

**Target Platform:** iOS 17+ (SwiftUI)
**Target Devices:** iPhone 16 Pro and later (optimized), iPhone 12+ (supported)
**Backend:** Firebase (Auth + Firestore)
**Architecture:** Offline-first with cloud sync

---

## Critical Review Notes

*Last reviewed: January 2026*

This implementation plan has been critically reviewed against the PRD v1.1. Key alignment items:
- Phase ordering prioritizes core functionality before polish
- Performance and dark mode are addressed early (essential for nighttime use)
- All PRD-specified validations and edge cases are captured
- Success metrics and out-of-scope items match PRD exactly

---

## Phase 1: Foundation & Core Data Layer

### 1.1 Project Setup
- [ ] Create Xcode project with SwiftUI lifecycle
- [ ] Configure project structure (MVVM architecture)
- [ ] Set up Swift Package Manager dependencies
- [ ] Configure Firebase project and add SDK
- [ ] Set up development, staging, and production environments
- [ ] Configure code signing and provisioning profiles

### 1.2 Data Models
- [ ] Implement `EventTimestamp` struct with UTC + timezone handling:
  - Store `utc: Date`, `timezoneIdentifier: String`, `offsetSeconds: Int`
  - Implement `localDisplay` computed property for original timezone display
  - Historical events display in timezone where they occurred (not shifted to current timezone)
  - Multi-caregiver: each caregiver sees events in their own timezone for new events
- [ ] Implement core entities:
  - [ ] `User` model (id, email, display_name, created_at)
  - [ ] `Baby` model with settings JSON (id, name, birth_date, primary_caregiver_id, settings, created_at)
  - [ ] `BabyCaregiver` join model (baby_id, user_id, role enum: primary/caregiver, joined_at)
  - [ ] `Event` model with polymorphic data (id, baby_id, logged_by, event_type, start_time, end_time, data JSON, notes, created_at, updated_at, deleted_at)
- [ ] Implement event data structs:
  - [ ] `EatEventData` (amount_prepared, amount_remaining, feeding_started_at)
  - [ ] `SleepEventData` (empty—timing in parent Event)
  - [ ] `DiaperEventData` (contents: wet/dirty/both)
- [ ] Add Codable conformance for all models
- [ ] Implement state derivation logic for bottle states (prepared/feeding/finished/expired)

### 1.3 Local Persistence (Core Data)
- [ ] Create Core Data model (.xcdatamodeld)
- [ ] Implement Core Data stack with NSPersistentContainer
- [ ] Configure NSFileProtectionComplete for encryption at rest
- [ ] Create managed object subclasses
- [ ] Implement repository pattern for data access:
  - [ ] `EventRepository`
  - [ ] `BabyRepository`
  - [ ] `UserRepository`
- [ ] Add required indexes for performance:
  - [ ] `idx_events_baby_time` (baby_id, start_time DESC)
  - [ ] `idx_events_baby_active` (baby_id, event_type, end_time) WHERE end_time IS NULL AND deleted_at IS NULL
  - [ ] `idx_events_updated` (baby_id, updated_at DESC)
  - [ ] `idx_baby_caregiver` (user_id, baby_id)
- [ ] Write unit tests for data layer

### 1.4 Data Validation Layer
- [ ] Implement validation for preventing multiple active sleeps:
  ```swift
  func validateNewSleep(_ newSleep: SleepEvent) throws {
      // Check for existing active sleeps, throw ValidationError.sleepAlreadyActive if found
  }
  ```
- [ ] Implement validation for preventing multiple active feedings:
  ```swift
  func validateFeedingStart(_ bottle: EatEvent) throws {
      // Check for existing active feedings, throw ValidationError.feedingAlreadyActive if found
  }
  ```
- [ ] Unit tests for validation logic

---

## Phase 2: Authentication & User Management

### 2.1 Firebase Authentication
- [ ] Implement Sign in with Apple flow (preferred method)
- [ ] Implement email/password authentication (fallback)
- [ ] Create `AuthService` to manage authentication state
- [ ] Implement secure token storage in Keychain
- [ ] Handle session persistence (stay logged in)

### 2.2 User Onboarding
- [ ] Create minimal onboarding flow:
  - [ ] Sign in / Sign up screen (Sign in with Apple prominent)
  - [ ] Add baby screen (name + birthdate only)
- [ ] Implement invite code generation for primary caregiver
- [ ] Implement invite code redemption for secondary caregivers

### 2.3 User Settings
- [ ] Create settings data model
- [ ] Implement settings persistence
- [ ] Build settings UI (accessed via profile icon):
  - [ ] Baby info editing
  - [ ] Caregiver management (primary can remove caregivers)
  - [ ] Formula settings:
    - [ ] Default bottle size
    - [ ] Expiry window override (for refrigerated bottles: up to 24 hours)
  - [ ] Unit preferences (oz/ml)
  - [ ] Notification toggles (per-caregiver)
  - [ ] Dark mode toggle (system default / always on / always off)

### 2.4 Permissions Model
- [ ] Implement role-based permissions:
  - [ ] All caregivers: can log/edit events
  - [ ] Primary caregiver only: can delete baby, remove caregivers
- [ ] Enforce permissions in UI and data layer

---

## Phase 3: Main Screen Layout & Timeline UI

### 3.1 Main Screen Layout (per PRD specifications)
- [ ] Create top bar (~8% of screen):
  - [ ] Profile icon (de-emphasized, left)
  - [ ] Baby name (center, tappable for quick stats)
  - [ ] Sync status indicator (right)
- [ ] Create action buttons row (~12-15% of screen):
  - [ ] Three equal-width buttons: EAT | SLEEP | DIAPER
  - [ ] Large tap targets for one-handed operation
- [ ] Create timeline container (~75-80% of screen per PRD)
- [ ] Ensure one-handed operation with large tap targets

### 3.2 Timeline Foundation
- [ ] Create `TimelineView` as main container
- [ ] Implement custom vertical scroll timeline:
  - [ ] Scroll UP to see future
  - [ ] Scroll DOWN to see past
- [ ] Add "now" indicator line with current time
- [ ] Implement 6-hour past / 3-hour future default window (9-hour total)
- [ ] Add date separators for midnight transitions:
  - [ ] Light horizontal line with date label
  - [ ] Display "Yesterday 11:30 PM" format for clarity
- [ ] Implement pull-to-refresh gesture

### 3.3 Event Rendering
- [ ] Create `EventBlockView` for timeline events
- [ ] Implement color coding:
  - [ ] Sleep: soft purple (#9B8AA5)
  - [ ] Eat: soft green (#7BAE7F)
  - [ ] Diaper: soft amber (#E5C07B)
- [ ] Add event duration labels
- [ ] Implement tap-to-expand for event details
- [ ] Show caregiver attribution in expanded details

### 3.4 Active State Display
- [ ] Implement active sleep indicator:
  - [ ] Purple block extending from sleep start to "now" line
  - [ ] Running duration counter displayed on block (e.g., "1h 23m")
  - [ ] Subtle pulse/shimmer animation to indicate "live" state
  - [ ] Sleep button transforms: stop icon, "End Sleep" label
- [ ] Implement prepared bottle indicator (not yet feeding):
  - [ ] Green bottle icon pinned near "now" line
  - [ ] Countdown timer: "Expires in 1h 42m"
  - [ ] Color transitions (consistent with Phase 5.2):
    - [ ] Green: > 30 minutes remaining
    - [ ] Yellow: 15-30 minutes remaining
    - [ ] Red: < 15 minutes remaining
    - [ ] Grey strikethrough: expired
  - [ ] Tap to show: "Start Feeding" / "Discard" / "Edit"
- [ ] Implement feeding-in-progress indicator:
  - [ ] Pulsing green indicator at "now" line
  - [ ] Shows: "Feeding (started 12 min ago)"
  - [ ] Expiry countdown based on feeding start time (1 hour from feeding start)
- [ ] Implement 30-minute prepared bottle reminder:
  - [ ] Subtle visual reminder on timeline if bottle prepared but feeding hasn't started

---

## Phase 4: Event Logging

### 4.1 Quick Log (Happy Path)
- [ ] Implement single-tap logging with smart defaults
- [ ] Add haptic feedback on successful log
- [ ] Show visual confirmation (< 100ms response)
- [ ] Remember last-used bottle size as default

### 4.2 Eat (Formula) Tracking
- [ ] Create bottle preparation flow:
  - [ ] One-tap to create bottle at "now"
  - [ ] Stepper for amount (+ and - buttons, no keyboard)
  - [ ] Remember last-used bottle size as default
- [ ] Implement bottle states with state derivation:
  - [ ] Prepared (feeding_started_at == null, room temp)
  - [ ] Refrigerated (feeding_started_at == null, marked as refrigerated in settings)
  - [ ] Feeding (feeding_started_at != null && end_time == null)
  - [ ] Finished (end_time != null)
  - [ ] Expired (time limit exceeded based on state)
- [ ] Create "Start Feeding" action
- [ ] Create "Finish Feeding" flow:
  - [ ] User enters amount REMAINING
  - [ ] App auto-calculates consumption (amount_prepared - amount_remaining)
  - [ ] Display calculated consumption for user confirmation before saving
- [ ] Implement "Discard" action for expired/unused bottles

### 4.3 Sleep Tracking
- [ ] Implement sleep start (one tap)
- [ ] Implement sleep end (one tap)
- [ ] Prevent multiple active sleeps with bottom sheet:
  - [ ] Show: "Baby is currently sleeping (1h 23m)"
  - [ ] Options: "End Sleep" / "Cancel"
  - [ ] Use data validation layer to enforce
- [ ] Auto-calculate and display duration

### 4.4 Diaper Tracking
- [ ] Implement one-tap diaper log
- [ ] Create quick toggle for contents (Wet/Dirty/Both)
- [ ] Default to "Both" for fastest logging

### 4.5 Event Editing
- [ ] Create event detail/edit view
- [ ] Implement time adjustment (all timestamps editable)
- [ ] Add optional notes field (hidden by default, "Add note" link)
- [ ] Implement swipe-to-delete
- [ ] Show caregiver attribution in detail view
- [ ] Implement soft delete with deleted_at timestamp

---

## Phase 5: Bottle Expiry System

### 5.1 Expiry Timer Logic
- [ ] Implement expiry calculation per scenario:
  - [ ] Room temperature, not fed: 2 hours from preparation
  - [ ] Room temperature, feeding started: 1 hour from feeding start
  - [ ] Refrigerated (configurable): up to 24 hours from preparation
- [ ] Create `BottleExpiryService`
- [ ] Handle state transitions for expiry
- [ ] Read expiry override from user settings for refrigerated bottles

### 5.2 Visual Expiry Indicators
- [ ] Show countdown timer on timeline
- [ ] Implement color transitions:
  - [ ] Green: > 30 minutes remaining
  - [ ] Yellow: 15-30 minutes remaining
  - [ ] Red: < 15 minutes remaining
  - [ ] Grey strikethrough: expired

### 5.3 Expiry Notifications
- [ ] Schedule local notifications at 15 minutes before expiry
- [ ] Cancel notifications when bottle is finished/discarded
- [ ] Respect notification settings and quiet hours

---

## Phase 6: Wake Window Predictions

### 6.1 Algorithm Implementation
- [ ] Implement age-based wake window defaults (per PRD table):
  - 0-4 weeks: 30-60 min
  - 4-12 weeks: 60-90 min
  - 3-4 months: 75-120 min
  - 5-7 months: 2-3 hours
  - 7-10 months: 2.5-3.5 hours
  - 10-14 months: 3-4 hours
  - 14-18 months: 4-6 hours
- [ ] Create `WakeWindowPredictor` service
- [ ] Implement historical average calculation (14-day rolling):
  - [ ] Only include "successful" sleeps (duration >= 20 minutes)
  - [ ] Require minimum 5 data points for personalization
  - [ ] Clamp personalized range to 0.8x-1.2x of age-based bounds
- [ ] Implement time-of-day adjustments:
  - [ ] Before 9 AM: 0.9x adjustment (shorter)
  - [ ] After 5 PM: 1.1x adjustment (longer)
  - [ ] Otherwise: 1.0x
- [ ] Implement confidence scoring:
  - [ ] "high" if >= 10 recent wake windows
  - [ ] "learning" otherwise
- [ ] Implement accuracy feedback loop (per PRD):
  - [ ] Track "Prediction Hit Rate" — percentage of naps starting within predicted window
  - [ ] If accuracy drops below 60% for a baby, show "learning" indicator
  - [ ] Expand predicted ranges when accuracy is low

### 6.2 Age Transition Handling
- [ ] Calculate baby age from birthdate
- [ ] Implement 7-day blending for age threshold transitions:
  ```swift
  func getBlendedWakeWindowRange(babyAgeDays: Int) -> (min: Int, max: Int) {
      // Blend previous and current range over 7 days
      // Day 1: 80% old, 20% new
      // Day 4: 50% old, 50% new
      // Day 7: 100% new
  }
  ```

### 6.3 Prediction Display
- [ ] Show predicted nap window on timeline (semi-transparent, ~30% opacity)
- [ ] Use same event colors at reduced opacity for predictions
- [ ] Display as time range (e.g., "2:30 - 3:00 PM") with "Nap window" label
- [ ] Make tappable to show explanation
- [ ] Generate user-friendly explanation text:
  - [ ] Personalized: "Based on {baby_name}'s age ({X} months) and average wake time this week ({duration})"
  - [ ] Cold start: "Based on typical wake windows for {X}-month-olds. Predictions will improve as we learn {baby_name}'s patterns."

---

## Phase 7: Cloud Sync

### 7.1 Firebase Firestore Integration
- [ ] Set up Firestore collections and documents
- [ ] Implement Firestore security rules
- [ ] Create `SyncService` for bidirectional sync

### 7.2 Offline-First Architecture
- [ ] Implement local-first write pattern (write to Core Data first)
- [ ] Queue changes when offline
- [ ] Sync automatically when connectivity restored
- [ ] Show sync status indicator:
  - [ ] Checkmark: synced
  - [ ] Spinner: syncing
  - [ ] Warning: offline with pending changes

### 7.3 Conflict Resolution
- [ ] Implement `ConflictDetector` (per PRD spec):
  ```swift
  struct ConflictDetector {
      func detectConflict(incoming: Event, local: Event) -> ConflictType? {
          // Same event ID = direct edit conflict
          // Different IDs but overlapping time + same type = possible duplicate
      }
  }
  ```
- [ ] Detect direct edit conflicts (same ID, different updatedAt)
- [ ] Detect possible duplicates (events within 5 min threshold)
- [ ] Create conflict resolution UI:
  - [ ] Direct edit: non-blocking banner with "View Changes" action
  - [ ] Possible duplicate: banner with "Review" showing side-by-side comparison
- [ ] Implement resolution actions:
  - [ ] Keep Local / Keep Remote / Keep Both / Merge (latest non-null fields)
- [ ] Design principle: Never lose data silently

### 7.4 Active State Validation During Sync
- [ ] Validate active states when syncing from remote:
  - [ ] If remote has active sleep and local has different active sleep, treat as conflict
  - [ ] If remote has active feeding and local has different active feeding, treat as conflict
- [ ] Use same validation logic as local data layer (Phase 1.4)
- [ ] Present conflicts to user rather than silently accepting invalid states

### 7.5 Multi-Caregiver Sync
- [ ] Real-time sync between caregivers
- [ ] Attribute events to logging caregiver
- [ ] Handle concurrent edits gracefully
- [ ] Display events in each caregiver's own timezone (sync uses UTC)

---

## Phase 8: Quick Stats & Handover Support

### 8.1 Quick Stats Overlay
- [ ] Create overlay triggered by tapping baby name in header
- [ ] Display stats:
  - [ ] Last feed: "{time} ago ({amount}oz)"
  - [ ] Last sleep: "{duration} (ended {time} ago)"
  - [ ] Last diaper: "{time} ago ({type})"
  - [ ] Current state: "Awake for {duration}" or "Sleeping for {duration}"
- [ ] Dismiss on tap outside or swipe down

### 8.2 Timeline Optimization for Handover
- [ ] Ensure 6-hour window shows complete shift history
- [ ] Highlight active states prominently at "now" line
- [ ] Show upcoming predictions clearly in future section

---

## Phase 9: Notifications

### 9.1 Local Notifications
- [ ] Request notification permissions
- [ ] Implement bottle expiry notification (15 min before, default: ON)
- [ ] Implement wake window notification (when predicted window starts, default: OFF)
- [ ] Implement feeding due notification (3 hours since last feed, default: OFF)

### 9.2 Notification Management
- [ ] Implement quiet hours (10pm-6am default, configurable)
  - [ ] Respect user's timezone for quiet hours calculation
  - [ ] Handle DST transitions correctly (quiet hours should be consistent local time)
- [ ] Allow per-caregiver notification settings
- [ ] Batch multiple alerts into single notification
- [ ] Ensure all notifications lead to clear actions
- [ ] Easy dismissal, never nag repeatedly for same event

---

## Phase 10: Data Export & Account Management

### 10.1 CSV Export
- [ ] Implement CSV generation per PRD format:
  ```
  date,time,event_type,duration_minutes,amount_prepared_oz,amount_consumed_oz,diaper_contents,logged_by,notes
  ```
- [ ] Add date range filtering (24h, 7d, 30d, all time)

### 10.2 Export Options
- [ ] Implement copy to clipboard (for pasting into LLMs)
- [ ] Integrate with iOS share sheet (email, AirDrop, Files)
- [ ] Include column headers

### 10.3 Data Management
- [ ] Implement soft delete for events (30-day recovery window, then permanent)
- [ ] Implement "Delete Baby" with confirmation (removes all events and caregiver associations)
- [ ] Implement "Delete Account":
  - [ ] Removes all user data
  - [ ] If sole caregiver, prompt to transfer or delete baby data
- [ ] JSON export for GDPR/CCPA data requests

---

## Phase 11: Privacy, Security & Analytics

### 11.1 Security Implementation
- [ ] Verify TLS 1.3 for all API communication
- [ ] Confirm iOS Data Protection (NSFileProtectionComplete) is enabled
- [ ] Verify Firebase/Firestore default encryption
- [ ] Secure token management in Keychain
- [ ] Security audit before launch

### 11.2 Privacy-Respecting Analytics
- [ ] Choose analytics tool (PostHog or self-hosted Plausible)
- [ ] Implement anonymized metrics only:
  - [ ] Feature usage counts
  - [ ] Crash reports
  - [ ] Performance metrics (launch time, scroll performance)
  - [ ] Retention metrics (DAU/MAU, session length)
- [ ] Ensure NEVER collected:
  - [ ] Baby names or personal information
  - [ ] Specific event times or details
  - [ ] Location data
  - [ ] Persistent device identifiers

### 11.3 Compliance
- [ ] Write privacy policy explaining data practices
- [ ] Implement data export request handling
- [ ] Implement account deletion request handling
- [ ] GDPR/CCPA compliance verification

---

## Phase 12: Dark Mode & Polish

### 12.1 Dark Mode
- [ ] Implement dark mode color palette
- [ ] Use true black (#000000) for OLED screens
- [ ] Adjust event colors for reduced brightness while maintaining hue relationships
- [ ] Support system default / always on / always off

### 12.2 Accessibility
- [ ] Add VoiceOver labels to all controls
- [ ] Ensure Dynamic Type support
- [ ] Test with accessibility inspector
- [ ] Verify large tap targets work for motor accessibility

---

## Phase 13: Performance Optimization

### 13.1 Performance Targets
- [ ] Profile with Instruments before each release
- [ ] Achieve cold launch < 1.0 second to interactive timeline
- [ ] Achieve warm launch < 0.3 seconds
- [ ] Achieve 120fps timeline scrolling (ProMotion)
- [ ] Achieve event logging < 100ms from tap to visual confirmation
- [ ] Test with 1,000+ events to ensure timeline remains responsive

### 13.2 Resource Limits
- [ ] Keep memory < 100MB typical, < 200MB peak
- [ ] Keep battery impact < 1%/hour when backgrounded
- [ ] Keep app size < 30MB download

---

## Phase 14: Edge Cases & Robustness

### 14.1 Timezone Handling
- [ ] Handle timezone changes gracefully:
  - [ ] Normal use: display in device's current timezone
  - [ ] Historical events: show in timezone where they occurred
  - [ ] Multi-caregiver: each sees events in their own timezone
- [ ] Handle DST transitions (UTC storage makes this automatic)
- [ ] Handle midnight/day boundaries with visual separators

### 14.2 State Validation
- [ ] Enforce no multiple active sleeps (UI + data layer)
- [ ] Enforce no multiple active feedings (UI + data layer)
- [ ] Handle edge cases in bottle states (expired during feeding, etc.)

---

## Phase 15: Testing & Launch Prep

### 15.1 Testing
- [ ] Unit tests for all services and models
- [ ] UI tests for critical flows:
  - [ ] Quick log for each event type
  - [ ] Sleep start/end flow
  - [ ] Bottle prepare → feed → finish flow
  - [ ] Event editing
- [ ] Performance regression tests in CI
- [ ] Manual QA checklist
- [ ] Beta testing via TestFlight

### 15.2 App Store Preparation
- [ ] Create app icons (all required sizes)
- [ ] Write App Store description
- [ ] Create screenshots for all device sizes
- [ ] Write privacy policy
- [ ] Submit for App Store review

---

## Technical Architecture

### Project Structure
```
Hush/
├── App/
│   ├── HushApp.swift
│   └── AppDelegate.swift          # For push notification handling (UIApplicationDelegate adapter)
├── Models/
│   ├── User.swift
│   ├── Baby.swift
│   ├── Event.swift
│   ├── EventTimestamp.swift
│   └── EventData/
│       ├── EatEventData.swift
│       ├── SleepEventData.swift
│       └── DiaperEventData.swift
├── Views/
│   ├── MainScreen/
│   │   ├── MainScreenView.swift
│   │   ├── TopBarView.swift
│   │   └── ActionButtonsView.swift
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── EventBlockView.swift
│   │   ├── NowIndicatorView.swift
│   │   ├── ActiveStateView.swift
│   │   └── PredictionBlockView.swift
│   ├── Actions/
│   │   ├── EatFlowView.swift
│   │   ├── SleepFlowView.swift
│   │   └── DiaperFlowView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   ├── Auth/
│   │   ├── SignInView.swift
│   │   └── OnboardingView.swift
│   └── Components/
│       ├── QuickStatsOverlay.swift
│       ├── SyncIndicator.swift
│       └── ConflictBannerView.swift
├── ViewModels/
│   ├── TimelineViewModel.swift
│   ├── EventViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── AuthService.swift
│   ├── SyncService.swift
│   ├── EventService.swift
│   ├── WakeWindowPredictor.swift
│   ├── BottleExpiryService.swift
│   ├── NotificationService.swift
│   ├── ConflictDetector.swift
│   └── AnalyticsService.swift
├── Repositories/
│   ├── EventRepository.swift
│   ├── BabyRepository.swift
│   └── UserRepository.swift
├── Validation/
│   ├── SleepValidator.swift
│   └── FeedingValidator.swift
├── CoreData/
│   └── Hush.xcdatamodeld
├── Firebase/
│   └── GoogleService-Info.plist
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### Key Dependencies
- **Firebase iOS SDK** - Authentication & Firestore
- **Core Data** - Local persistence
- **PostHog** or **Plausible** - Privacy-respecting analytics

### Design Patterns
- **MVVM** - View/ViewModel separation
- **Repository Pattern** - Data access abstraction
- **Service Layer** - Business logic encapsulation
- **Offline-First** - Local writes with background sync
- **Validation Layer** - Centralized state validation

---

## Success Criteria (MVP)

Per PRD requirements:
- [ ] Time to first log: < 60 seconds
- [ ] Average log time: < 3 seconds (excluding notes)
- [ ] Day 7 retention: > 50%
- [ ] Sync reliability: > 99.5%
- [ ] Multi-caregiver usage: > 40% of active babies have 2+ caregivers
- [ ] App size: < 30MB
- [ ] Cold launch: < 1.0 second
- [ ] Warm launch: < 0.3 seconds
- [ ] App Store rating target: 4.5+ stars
- [ ] Wake window prediction hit rate: > 70% after 2 weeks of use

---

## Out of Scope (Post-MVP)

Explicitly deferred per PRD:
- Multi-child support
- Breastfeeding tracking
- Solids tracking
- Paid analytics tier
- Edit history / undo
- iOS widgets
- Apple Watch app
- Siri shortcuts
- Android version
- Baby Brezza integration
- "Active caregiver" mode (where only one person receives notifications)

---

*This plan will be updated as implementation progresses.*

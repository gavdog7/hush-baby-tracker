# Hush - Implementation Plan
## Baby Tracker App

Based on PRD v1.0 (January 2026)

---

## Overview

This document outlines the implementation plan for Hush, a radically simplified baby tracking app. The plan is organized into phases that can be executed incrementally, with each phase delivering working functionality.

**Tech Stack Decision:** SwiftUI (native iOS) with Firebase (Auth + Firestore) for the backend. This provides the best native feel, performance, and real-time sync capabilities.

---

## Phase 1: Project Setup & Core Infrastructure

### Objectives
- Establish project foundation with proper architecture
- Set up development environment and tooling
- Create base app structure

### Tasks

1. **Xcode Project Setup**
   - Create new SwiftUI project targeting iOS 16+
   - Configure bundle identifier, app icons placeholder
   - Set up Git repository with .gitignore

2. **Architecture Setup**
   - Implement MVVM architecture pattern
   - Create folder structure:
     ```
     Hush/
     ├── App/
     │   └── HushApp.swift
     ├── Models/
     ├── Views/
     │   ├── Components/
     │   └── Screens/
     ├── ViewModels/
     ├── Services/
     ├── Utilities/
     └── Resources/
     ```

3. **Dependencies**
   - Add Firebase SDK via Swift Package Manager
   - Configure Firebase project (dev environment)

4. **Design System Foundation**
   - Define color palette (light/dark mode)
     - Sleep: `#B4A7D6` (lavender)
     - Eat: `#93C47D` (soft green)
     - Diaper: `#FFD966` (soft amber)
   - Set up typography using SF Pro
   - Create reusable button styles

### Deliverable
Empty app shell with proper architecture, Firebase configured, design tokens defined.

---

## Phase 2: Data Layer & Local Storage

### Objectives
- Implement data models
- Set up Core Data for offline-first storage
- Create repository pattern for data access

### Tasks

1. **Core Data Models**
   - `CDUser` entity
   - `CDEvent` entity with event_type enum
   - Set up Core Data stack with CloudKit container (future-proofing)

2. **Domain Models**
   ```swift
   enum EventType: String, Codable {
       case eat, sleep, diaper
   }

   struct Event: Identifiable {
       let id: UUID
       let babyId: UUID
       let loggedBy: UUID
       let eventType: EventType
       var startTime: Date
       var endTime: Date?
       var data: EventData
       var notes: String?
   }

   enum EventData {
       case eat(EatData)
       case sleep
       case diaper(DiaperData)
   }

   struct EatData {
       var amountPrepared: Double
       var amountRemaining: Double?
       var feedingStarted: Date?
       var bottleMadeAt: Date
   }

   struct DiaperData {
       var contents: DiaperContents
   }

   enum DiaperContents: String {
       case wet, dirty, both
   }
   ```

3. **Repository Layer**
   - `EventRepository` protocol
   - `LocalEventRepository` implementation (Core Data)
   - CRUD operations for events

4. **Unit Preferences**
   - User defaults for oz/ml preference
   - Conversion utilities

### Deliverable
Working local data persistence, can save/load events offline.

---

## Phase 3: Core UI - Timeline View

### Objectives
- Build the main timeline interface
- Implement scroll behavior and time display
- Create event visualization

### Tasks

1. **Timeline Container**
   - Vertical scrolling timeline view
   - 9-hour window (6hr past, 3hr future)
   - Current time "now" indicator line
   - Auto-scroll to current time on launch

2. **Time Axis**
   - Hour markers on left side
   - Date separators for multi-day view
   - Smooth scrolling with momentum

3. **Event Blocks**
   - Color-coded blocks for each event type
   - Duration-based height for sleep events
   - Point markers for instant events (diaper)
   - Semi-transparent blocks for predictions

4. **Event Interaction**
   - Tap event to select/expand
   - Basic event card overlay for details

5. **Top Bar**
   - Profile icon (left) - placeholder for now
   - Sync status indicator (right) - placeholder

### Deliverable
Scrollable timeline displaying mock events with correct visual styling.

---

## Phase 4: Event Tracking (Eat, Sleep, Diaper)

### Objectives
- Implement the three action buttons
- Build event logging flows
- Enable event editing

### Tasks

1. **Action Button Bar**
   - Three large buttons: EAT | SLEEP | DIAPER
   - Equal width, 44pt minimum tap target
   - Haptic feedback on tap

2. **Quick Log Behavior**
   - Single tap creates event at current time with defaults
   - Event card opens for optional editing
   - Dismiss to save, explicit cancel to discard

3. **Eat Event Flow**
   - Stepper for amount prepared (0.5 oz increments)
   - Remember last amount as default
   - "Feeding started" toggle/timestamp
   - "Amount remaining" stepper (calculates consumption)
   - Bottle expiry countdown display

4. **Sleep Event Flow**
   - "Start sleep" creates open-ended event
   - Active sleep shown on timeline with growing duration
   - "End sleep" button appears while sleep active
   - Auto-calculate and display duration

5. **Diaper Event Flow**
   - Quick toggle: Wet / Dirty / Both
   - Instant log (no duration)

6. **Event Editing**
   - Tap timeline event to edit
   - Adjust all timestamps with date/time picker
   - Swipe-to-delete gesture
   - Notes field (optional, collapsed by default)

7. **Time Adjustment UX**
   - Quick adjustments: "-5m", "-10m", "-15m", "-30m" buttons
   - Full date/time picker for precise control

### Deliverable
Fully functional event logging for all three types, editable events.

---

## Phase 5: Bottle Expiry System

### Objectives
- Implement formula safety timers
- Visual countdown on timeline
- Optional notifications

### Tasks

1. **Expiry Calculation**
   - 2-hour default from bottle preparation
   - Switch to 1-hour from feeding started (if logged)
   - Configurable expiry windows in settings

2. **Visual Countdown**
   - Show remaining time on active bottle events
   - Color progression: green → yellow (30min) → red (15min) → expired

3. **Expired Bottle Handling**
   - Visual strikethrough or fade for expired bottles
   - Keep in history but clearly marked

4. **Notifications** (if time permits)
   - Local notification at 15min before expiry
   - Configurable on/off in settings

### Deliverable
Working bottle expiry system with visual feedback.

---

## Phase 6: Authentication & Multi-Caregiver

### Objectives
- Implement user authentication
- Enable multi-caregiver collaboration
- Track who logged each event

### Tasks

1. **Firebase Auth Setup**
   - Email/password authentication
   - Sign in with Apple
   - Persistent sessions

2. **Onboarding Flow**
   - Sign up / Sign in screen
   - Baby profile creation (name, birthdate)
   - Skip to local-only mode option

3. **Caregiver Attribution**
   - Auto-assign logged_by to current user
   - Display caregiver name in event details (not main timeline)

4. **Invite System**
   - Primary caregiver generates invite code
   - Secondary caregiver enters code to join
   - Deep link support for invite URLs

5. **Permissions**
   - All caregivers: log, edit events
   - Primary only: delete baby, remove caregivers

### Deliverable
Working auth flow, multiple caregivers can join and log events.

---

## Phase 7: Cloud Sync

### Objectives
- Real-time data synchronization
- Offline-first with background sync
- Conflict resolution

### Tasks

1. **Firestore Data Structure**
   ```
   users/{userId}
   babies/{babyId}
   babies/{babyId}/caregivers/{oduserId}
   babies/{babyId}/events/{eventId}
   ```

2. **Sync Service**
   - `SyncService` class managing Firestore listeners
   - Optimistic local updates
   - Background sync when online

3. **Offline Queue**
   - Queue local changes when offline
   - Process queue when connectivity restored
   - Last-write-wins conflict resolution

4. **Sync Status UI**
   - Green checkmark: synced
   - Spinner: syncing
   - Warning icon: offline/error

5. **Real-time Updates**
   - Firestore snapshot listeners
   - Merge remote changes with local state
   - UI updates automatically

### Deliverable
Events sync across devices in real-time, works offline.

---

## Phase 8: Wake Window Predictions

### Objectives
- Implement age-based wake window algorithm
- Display predictions on timeline
- Explainable recommendations

### Tasks

1. **Age Calculation**
   - Calculate baby's age from birthdate
   - Map to wake window range per PRD table

2. **Prediction Algorithm**
   - Base prediction on age defaults
   - Adjust based on last 7 days of actual sleep data
   - First wake window of day: use lower bound
   - Last wake window: use upper bound

3. **Timeline Integration**
   - Show predicted nap window as semi-transparent block
   - Display as range ("Nap in 1.5-2 hrs")
   - Update prediction when sleep event logged

4. **Explainability**
   - Tap prediction to see reasoning
   - "Based on Eddie's age (4 months) and average wake time this week (1h 45m)"

### Deliverable
Working wake window predictions displayed on timeline.

---

## Phase 9: Settings & Profile

### Objectives
- Implement settings screen
- Profile management
- Data export

### Tasks

1. **Settings Screen**
   - Accessed via profile icon
   - Sheet presentation (maintains one-page feel)

2. **Baby Settings**
   - Edit name, birthdate
   - Default bottle size
   - Unit preference (oz/ml)

3. **Formula Settings**
   - Expiry window customization
   - Preparation method notes

4. **App Settings**
   - Dark mode toggle (system/on/off)
   - Notification preferences

5. **Caregiver Management**
   - View current caregivers
   - Generate new invite code
   - Remove caregiver (primary only)

6. **Data Export**
   - CSV generation per PRD spec
   - Date range selection (24h, 7d, 30d, all)
   - Copy to clipboard
   - Share sheet

### Deliverable
Complete settings with export functionality.

---

## Phase 10: Polish & Launch Prep

### Objectives
- UI polish and animations
- Performance optimization
- App Store preparation

### Tasks

1. **Animations**
   - Smooth event card expansion
   - Timeline scroll physics tuning
   - Button press feedback

2. **Haptics**
   - Success haptic on event log
   - Selection haptic on button tap
   - Warning haptic on expiry alert

3. **Dark Mode Polish**
   - Test all screens in dark mode
   - True black backgrounds for OLED
   - Adjust colors for visibility

4. **Performance**
   - Profile and optimize timeline rendering
   - Lazy loading for old events
   - Memory management for long sessions

5. **Error Handling**
   - Graceful degradation on network errors
   - User-friendly error messages
   - Crash reporting setup (Firebase Crashlytics)

6. **App Store Assets**
   - App icon (final design)
   - Screenshots for various device sizes
   - App Store description
   - Privacy policy

7. **TestFlight**
   - Internal testing build
   - Beta tester recruitment
   - Feedback collection

### Deliverable
Production-ready app submitted to App Store.

---

## Implementation Order & Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Data Layer)
    ↓
Phase 3 (Timeline UI)
    ↓
Phase 4 (Event Tracking) ←── Core MVP functionality
    ↓
Phase 5 (Bottle Expiry)
    ↓
Phase 6 (Auth) ←── Required for multi-user
    ↓
Phase 7 (Cloud Sync)
    ↓
Phase 8 (Predictions)
    ↓
Phase 9 (Settings)
    ↓
Phase 10 (Polish)
```

**Minimum Viable Product (Phases 1-5):** Single-user, offline-only app with core tracking functionality.

**Full MVP (Phases 1-9):** Multi-caregiver support with cloud sync.

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Timeline performance with many events | Implement virtualized list, limit visible events |
| Sync conflicts between caregivers | Last-write-wins with timestamp; consider CRDTs post-MVP |
| Offline reliability | Extensive testing of offline scenarios; queue all operations |
| Wake window accuracy | Make algorithm transparent; allow manual override |
| App Store rejection | Follow HIG strictly; no health claims without disclaimers |

---

## Testing Strategy

1. **Unit Tests**
   - Data models and conversions
   - Expiry calculations
   - Wake window algorithm

2. **Integration Tests**
   - Repository CRUD operations
   - Sync service behavior

3. **UI Tests**
   - Event logging flows
   - Timeline interaction
   - Settings changes

4. **Manual Testing**
   - Real-world usage with actual baby schedules
   - Multi-device sync scenarios
   - Offline/online transitions

---

## Success Criteria (from PRD)

- [ ] Time to first log < 60 seconds
- [ ] Average log time < 3 seconds
- [ ] Day 7 retention > 50%
- [ ] Sync reliability > 99.5%
- [ ] App Store rating target: 4.5+ stars

---

*Document created: January 2026*

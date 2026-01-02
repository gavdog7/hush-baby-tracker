# Hush - Implementation Plan

## Overview

This document outlines the implementation plan for Hush, a simplified baby tracking iOS app. The plan is organized into phases, with each phase building on the previous one to deliver incremental value.

**Target Platform:** iOS 17+ (SwiftUI)
**Backend:** Firebase (Auth + Firestore)
**Architecture:** Offline-first with cloud sync

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
- [ ] Implement `EventTimestamp` struct with UTC + timezone handling
- [ ] Implement core entities:
  - [ ] `User` model
  - [ ] `Baby` model with settings JSON
  - [ ] `BabyCaregiver` join model
  - [ ] `Event` model with polymorphic data (eat/sleep/diaper)
- [ ] Implement `EatEventData`, `SleepEventData`, `DiaperEventData` structs
- [ ] Add Codable conformance for all models

### 1.3 Local Persistence (Core Data)
- [ ] Create Core Data model (.xcdatamodeld)
- [ ] Implement Core Data stack with NSPersistentContainer
- [ ] Create managed object subclasses
- [ ] Implement repository pattern for data access:
  - [ ] `EventRepository`
  - [ ] `BabyRepository`
  - [ ] `UserRepository`
- [ ] Add required indexes for performance
- [ ] Write unit tests for data layer

---

## Phase 2: Authentication & User Management

### 2.1 Firebase Authentication
- [ ] Implement Sign in with Apple flow
- [ ] Implement email/password authentication
- [ ] Create `AuthService` to manage authentication state
- [ ] Implement secure token storage in Keychain
- [ ] Handle session persistence (stay logged in)

### 2.2 User Onboarding
- [ ] Create minimal onboarding flow:
  - [ ] Sign in / Sign up screen
  - [ ] Add baby screen (name + birthdate only)
- [ ] Implement invite code generation for primary caregiver
- [ ] Implement invite code redemption for secondary caregivers

### 2.3 User Settings
- [ ] Create settings data model
- [ ] Implement settings persistence
- [ ] Build settings UI (accessed via profile icon):
  - [ ] Baby info editing
  - [ ] Caregiver management
  - [ ] Unit preferences (oz/ml)
  - [ ] Notification toggles
  - [ ] Dark mode toggle

---

## Phase 3: Timeline UI

### 3.1 Timeline Foundation
- [ ] Create `TimelineView` as main container
- [ ] Implement custom vertical scroll timeline
- [ ] Add "now" indicator line with current time
- [ ] Implement 6-hour past / 3-hour future default window
- [ ] Add date separators for midnight transitions
- [ ] Implement pull-to-refresh gesture

### 3.2 Event Rendering
- [ ] Create `EventBlockView` for timeline events
- [ ] Implement color coding:
  - [ ] Sleep: purple (#9B8AA5)
  - [ ] Eat: green (#7BAE7F)
  - [ ] Diaper: amber (#E5C07B)
- [ ] Add event duration labels
- [ ] Implement tap-to-expand for event details

### 3.3 Active State Display
- [ ] Implement active sleep indicator:
  - [ ] Purple block extending to "now" line
  - [ ] Running duration counter
  - [ ] Subtle pulse animation
- [ ] Implement prepared bottle indicator:
  - [ ] Green bottle icon with expiry countdown
  - [ ] Color transitions (green → yellow → red → grey)
- [ ] Implement feeding-in-progress indicator

### 3.4 Main Screen Layout
- [ ] Create top bar with:
  - [ ] Profile icon (de-emphasized, left)
  - [ ] Baby name (center, tappable)
  - [ ] Sync status indicator (right)
- [ ] Create three action buttons (Eat, Sleep, Diaper)
- [ ] Integrate timeline view (80% of screen)
- [ ] Ensure one-handed operation with large tap targets

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
  - [ ] Stepper for amount (no keyboard)
- [ ] Implement bottle states:
  - [ ] Prepared → Feeding → Finished/Expired
- [ ] Create "Start Feeding" action
- [ ] Create "Finish Feeding" flow:
  - [ ] Enter amount remaining
  - [ ] Auto-calculate consumption
- [ ] Implement "Discard" action for expired/unused bottles

### 4.3 Sleep Tracking
- [ ] Implement sleep start (one tap)
- [ ] Implement sleep end (one tap)
- [ ] Prevent multiple active sleeps:
  - [ ] Show bottom sheet when tapping Sleep during active sleep
  - [ ] "End Sleep" and "Cancel" options
- [ ] Auto-calculate and display duration

### 4.4 Diaper Tracking
- [ ] Implement one-tap diaper log
- [ ] Create quick toggle for contents (Wet/Dirty/Both)
- [ ] Default to "Both" for fastest logging

### 4.5 Event Editing
- [ ] Create event detail/edit view
- [ ] Implement time adjustment (all timestamps editable)
- [ ] Add optional notes field (hidden by default)
- [ ] Implement swipe-to-delete
- [ ] Show caregiver attribution in detail view

---

## Phase 5: Bottle Expiry System

### 5.1 Expiry Timer Logic
- [ ] Implement expiry calculation:
  - [ ] 2 hours from preparation (room temp, not fed)
  - [ ] 1 hour from feeding start
- [ ] Create `BottleExpiryService`
- [ ] Handle state transitions for expiry

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
- [ ] Respect notification settings

---

## Phase 6: Wake Window Predictions

### 6.1 Algorithm Implementation
- [ ] Implement age-based wake window defaults (per PRD table)
- [ ] Create `WakeWindowPredictor` service
- [ ] Implement historical average calculation (14-day rolling)
- [ ] Add time-of-day adjustments
- [ ] Implement confidence scoring ("high" vs "learning")

### 6.2 Age Transition Handling
- [ ] Implement 7-day blending for age threshold transitions
- [ ] Calculate baby age from birthdate

### 6.3 Prediction Display
- [ ] Show predicted nap window on timeline (semi-transparent)
- [ ] Display as time range (e.g., "2:30 - 3:00 PM")
- [ ] Make tappable to show explanation
- [ ] Generate user-friendly explanation text

---

## Phase 7: Cloud Sync

### 7.1 Firebase Firestore Integration
- [ ] Set up Firestore collections and documents
- [ ] Implement Firestore security rules
- [ ] Create `SyncService` for bidirectional sync

### 7.2 Offline-First Architecture
- [ ] Implement local-first write pattern
- [ ] Queue changes when offline
- [ ] Sync automatically when connectivity restored
- [ ] Show sync status indicator

### 7.3 Conflict Resolution
- [ ] Implement `ConflictDetector` (per PRD spec)
- [ ] Detect direct edit conflicts
- [ ] Detect possible duplicates (events within 5 min)
- [ ] Create conflict resolution UI:
  - [ ] Banner for edit conflicts
  - [ ] Side-by-side comparison for duplicates
- [ ] Implement resolution actions (Keep Local/Remote/Both/Merge)

### 7.4 Multi-Caregiver Sync
- [ ] Real-time sync between caregivers
- [ ] Attribute events to logging caregiver
- [ ] Handle concurrent edits gracefully

---

## Phase 8: Quick Stats & Handover Support

### 8.1 Quick Stats Overlay
- [ ] Create overlay triggered by tapping baby name
- [ ] Display:
  - [ ] Last feed (time + amount)
  - [ ] Last sleep (duration + when ended)
  - [ ] Last diaper (time + type)
  - [ ] Current awake/sleep duration
- [ ] Dismiss on tap outside or swipe down

### 8.2 Timeline Optimization for Handover
- [ ] Ensure 6-hour window shows complete shift history
- [ ] Highlight active states prominently
- [ ] Show upcoming predictions clearly

---

## Phase 9: Notifications

### 9.1 Local Notifications
- [ ] Request notification permissions
- [ ] Implement bottle expiry notification (15 min before)
- [ ] Implement wake window notification (optional, off by default)
- [ ] Implement feeding due notification (optional, off by default)

### 9.2 Notification Management
- [ ] Respect quiet hours (10pm-6am default)
- [ ] Allow per-caregiver notification settings
- [ ] Batch multiple alerts into single notification

---

## Phase 10: Data Export

### 10.1 CSV Export
- [ ] Implement CSV generation per PRD format
- [ ] Include all columns: date, time, event_type, duration, amounts, etc.
- [ ] Add date range filtering (24h, 7d, 30d, all)

### 10.2 Export Options
- [ ] Implement copy to clipboard
- [ ] Integrate with iOS share sheet
- [ ] Include column headers

---

## Phase 11: Polish & Performance

### 11.1 Dark Mode
- [ ] Implement dark mode color palette
- [ ] Use true black (#000000) for OLED
- [ ] Support system default / always on / always off

### 11.2 Performance Optimization
- [ ] Profile with Instruments
- [ ] Ensure cold launch < 1.0 second
- [ ] Ensure warm launch < 0.3 seconds
- [ ] Achieve 120fps timeline scrolling
- [ ] Test with 1,000+ events
- [ ] Keep memory < 100MB typical

### 11.3 Accessibility
- [ ] Add VoiceOver labels to all controls
- [ ] Ensure Dynamic Type support
- [ ] Test with accessibility inspector

### 11.4 Edge Cases
- [ ] Handle timezone changes gracefully
- [ ] Handle DST transitions
- [ ] Handle midnight/day boundaries
- [ ] Validate against multiple active sleeps
- [ ] Validate against multiple active feedings

---

## Phase 12: Testing & Launch Prep

### 12.1 Testing
- [ ] Unit tests for all services and models
- [ ] UI tests for critical flows
- [ ] Performance regression tests in CI
- [ ] Manual QA checklist
- [ ] Beta testing via TestFlight

### 12.2 App Store Preparation
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
│   └── AppDelegate.swift
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
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── EventBlockView.swift
│   │   ├── NowIndicatorView.swift
│   │   └── PredictionBlockView.swift
│   ├── Actions/
│   │   ├── ActionButtonsView.swift
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
│       └── SyncIndicator.swift
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
│   └── NotificationService.swift
├── Repositories/
│   ├── EventRepository.swift
│   ├── BabyRepository.swift
│   └── UserRepository.swift
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

### Design Patterns
- **MVVM** - View/ViewModel separation
- **Repository Pattern** - Data access abstraction
- **Service Layer** - Business logic encapsulation
- **Offline-First** - Local writes with background sync

---

## Success Criteria (MVP)

Per PRD requirements:
- [ ] Time to first log: < 60 seconds
- [ ] Average log time: < 3 seconds
- [ ] Day 7 retention: > 50%
- [ ] Sync reliability: > 99.5%
- [ ] App size: < 30MB
- [ ] Cold launch: < 1.0 second

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

---

*This plan will be updated as implementation progresses.*

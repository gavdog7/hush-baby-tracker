# Baby Tracker App
## Product Requirements Document v1.0
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
10. [Data Export Specification](#10-data-export-specification)
11. [Future Roadmap (Post-MVP)](#11-future-roadmap-post-mvp)
12. [Success Metrics](#12-success-metrics)
13. [Appendix: Huckleberry Pain Points](#appendix-huckleberry-pain-points)

---

## 1. Executive Summary

This document outlines the requirements for a radically simplified baby tracking app designed for infants aged 0-18 months. The app focuses on three essential tracking categories—Eat (formula bottles), Sleep, and Diaper—with a timeline-centric interface that prioritizes one-handed operation and minimal cognitive load for exhausted caregivers.

The core differentiator is ruthless simplicity: one page, one timeline, three buttons. Where competitors like Huckleberry have become bloated with features, this app does fewer things but does them better. The timeline shows both history and predictions, making caregiver handovers seamless and day planning intuitive.

---

## 2. Product Vision & Design Principles

### Vision Statement

> The easiest-to-use baby tracking app in the world. Every interaction should be completable one-handed in under 3 seconds. The timeline tells you everything you need to know at a glance.

### Core Design Principles

- **One-Page Philosophy:** The entire app lives on a single screen. No navigation between tabs, no buried settings, no cognitive overhead.

- **Timeline-Centric:** The timeline is the product. It shows history, current state, and predictions in one scrollable view.

- **One-Handed Operation:** Every action must be completable with one hand while holding a baby. Large tap targets, minimal typing.

- **Reduce Cognitive Load:** Do calculations for the user. Don't ask them to subtract bottle amounts—ask what's left and calculate consumption.

- **Essential Only:** Track only what matters for daily caregiving. No weight tracking, no bath logging, no tummy time counters.

- **Offline-First Reliability:** Works offline, syncs seamlessly when online. Caregivers must trust their data is safe.

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

- **Typography:** Clean sans-serif fonts with excellent readability at various sizes. Consider SF Pro (iOS native) or Inter.

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
| Notes | Optional free-text field |

#### Sleep Tracking

| Field | Details |
|-------|---------|
| Sleep Start | One tap to start (defaults to "now") |
| Sleep End | One tap to end current sleep session |
| Duration | Auto-calculated and displayed |
| Wake Window | Prediction for next sleep shown on timeline |
| Notes | Optional free-text field |

#### Diaper Tracking

| Field | Details |
|-------|---------|
| Timestamp | One tap to log (defaults to "now") |
| Contents | Quick toggle: Wet / Dirty / Both |
| Notes | Optional free-text field |

### 4.3 Event Editing & History

- **Tap to Edit:** Tapping any event on the timeline opens edit mode for that event.

- **Time Adjustment:** All timestamps can be manually adjusted ("baby fell asleep 10 minutes ago").

- **Delete Events:** Swipe-to-delete or delete button in edit mode.

- **Caregiver Attribution:** Who logged the event is recorded automatically. Viewable by tapping into event details (not cluttering main timeline).

- **Future: Undo History:** Post-MVP, maintain edit history so accidental changes can be reverted.

### 4.4 Profile & Settings

Accessed via a small profile icon in the corner. Minimal settings to maintain simplicity.

- **Baby Info:** Name, birthdate (used to calculate age-appropriate wake windows).

- **Caregivers:** Primary caregiver manages invite codes for additional caregivers.

- **Formula Settings:** Default bottle size, preparation method (Baby Brezza / manual), expiry window.

- **Units:** oz vs ml preference.

- **Dark Mode:** System default / always on / always off.

- **Export Data:** One-tap CSV export to clipboard or share sheet.

---

## 5. Formula Safety Rules (Evidence-Based)

These guidelines are derived from CDC, FDA, and American Academy of Pediatrics recommendations. They should be configurable but these are the intelligent defaults.

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

- **Visual Countdown:** Show remaining time on timeline. Change color as expiry approaches (green → yellow → red).

- **Notification:** Optional push notification at 15 minutes before expiry.

- **Configurable:** Allow users to adjust expiry windows in settings (some may use refrigerated bottles).

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

### Algorithm Design

The wake window algorithm should be simple and explainable:

- **Start with Age Defaults:** Use the baby's age to determine the base wake window range.

- **Learn from History:** Track actual sleep patterns over the past 7-14 days. If baby consistently sleeps well at 2.5 hours but struggles at 3 hours, bias toward 2.5 hours.

- **Time-of-Day Adjustment:** First wake window of the day is typically shorter; last wake window before bed is typically longer.

- **Display as Range:** Show "Next nap in 2-2.5 hours" not a single precise time. Parents need flexibility.

- **Explainability:** User can tap on prediction to see "Based on Eddie's age (4 months) and his average wake time this week (1h 45m)."

---

## 7. Technical Requirements

### 7.1 Platform

| Attribute | Specification |
|-----------|---------------|
| Platform | iOS only (MVP) |
| Min iOS Version | iOS 16+ (covers ~95% of active devices) |
| Language | Swift / SwiftUI recommended for native feel |
| Alternative | React Native acceptable if faster to market; plan for native rewrite later |

### 7.2 Authentication & User Management

- **Primary Caregiver:** Signs up with email. This is the account owner.

- **Invite System:** Primary generates invite codes/links. Secondary caregivers sign up and enter code to join.

- **Authentication:** Email + password or Sign in with Apple.

- **Session:** Stay logged in unless explicitly logged out.

- **Permissions:** All caregivers can log/edit events. Only primary can delete baby or remove caregivers.

### 7.3 Data Sync

- **Cloud Backend:** Firebase Firestore or Supabase recommended for real-time sync.

- **Offline Support:** Local SQLite/Core Data cache. App fully functional offline.

- **Sync Strategy:** Optimistic updates with conflict resolution based on timestamp (last-write-wins for MVP).

- **Sync Indicator:** Subtle visual indicator showing sync status (green checkmark = synced, spinner = syncing, warning = offline).

- **Data Retention:** All data retained indefinitely. Export provides full history.

### 7.4 Suggested Tech Stack

- **Frontend:** SwiftUI (native iOS) or React Native with Expo

- **Backend:** Firebase (Auth + Firestore) or Supabase (Postgres + Auth)

- **Local Storage:** Core Data (native) or WatermelonDB (React Native)

- **Push Notifications:** Firebase Cloud Messaging or Apple Push Notifications

- **Analytics:** Mixpanel or Amplitude (privacy-respecting, minimal tracking)

---

## 8. Data Model

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
| start_time | Timestamp | When event started |
| end_time | Timestamp? | When event ended (null if ongoing) |
| data | JSON | Event-specific fields (see below) |
| notes | String? | Optional notes |
| created_at | Timestamp | Record creation time |
| updated_at | Timestamp | Last update time |
| deleted_at | Timestamp? | Soft delete timestamp |

### Event Data JSON Structures

**Eat Event:**
```json
{
  "amount_prepared": 4,
  "amount_remaining": 0.5,
  "feeding_started": "2026-01-02T08:20:00Z",
  "bottle_made_at": "2026-01-02T08:15:00Z"
}
```

**Sleep Event:**
```json
{}
```
*(times captured in start_time/end_time)*

**Diaper Event:**
```json
{
  "contents": "wet" | "dirty" | "both"
}
```

---

## 9. UI/UX Specifications

### Screen Layout

The app has ONE primary screen with the following layout from top to bottom:

| Section | Description |
|---------|-------------|
| Top Bar (~8%) | Profile icon (left corner), sync status indicator (right corner) |
| Action Buttons (~12%) | Three large buttons: EAT \| SLEEP \| DIAPER — equal width, large tap targets |
| Timeline (~80%) | Scrollable timeline showing past events, current time marker, and future predictions |

### Interaction Patterns

- **Quick Log:** Single tap on action button logs event at current time with defaults. User can edit immediately or ignore.

- **Event Cards:** Tap any event on timeline to expand into a card for viewing/editing details.

- **Scroll Behavior:** Pull down to see future predictions; pull up to see older history.

- **Number Input:** For bottle amounts, use a quick stepper (+ and - buttons) not a keyboard. Faster one-handed.

- **Haptics:** Subtle haptic feedback on successful logging to confirm without requiring visual attention.

### Color Coding

| Event Type | Suggested Color | Notes |
|------------|-----------------|-------|
| Sleep | Soft purple/lavender | Calming, associated with rest |
| Eat | Soft green | Growth, nourishment |
| Diaper | Soft yellow/amber | Warm, attention-getting for important hygiene |
| Predictions | Semi-transparent | Use same colors at ~30% opacity for future events |
| Expiry Warning | Red/orange gradient | Urgency without alarm |

### Dark Mode

Dark mode is essential for nighttime feedings. Colors should be adjusted to reduce brightness while maintaining the same hue relationships. Use true black backgrounds for OLED screens.

---

## 10. Data Export Specification

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

## 11. Future Roadmap (Post-MVP)

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

## 12. Success Metrics

### MVP Success Criteria

- **Time to First Log:** New user can log first event within 60 seconds of opening app.

- **Log Speed:** Average time to log an event < 3 seconds (excluding notes).

- **Day 7 Retention:** > 50% of users who log one event return within 7 days.

- **Sync Reliability:** > 99.5% of events sync successfully across devices.

- **App Store Rating:** Target 4.5+ stars with emphasis on "simple" and "easy" in reviews.

- **Multi-caregiver Usage:** > 40% of active babies have 2+ caregivers logging.

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
| Verbose, unhelpful insights | Simple, explainable wake window algorithm |
| $120/year for features most don't use | Free MVP; future paid tier focused on analytics only |

---

*— End of Document —*
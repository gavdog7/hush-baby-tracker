# CLAUDE.md

> **Project**: Hush - Simplified baby tracking iOS app
> **Architecture**: Swift/SwiftUI + Firebase (Auth + Firestore) + Core Data
> **Platform**: iOS 17+ (iPhone 12+ supported, iPhone 16 Pro optimized)

---

## Project Overview

Hush is an iOS baby tracking app designed for exhausted parents. It prioritizes speed and simplicity: one-tap logging for feeds, sleep, and diapers with a visual timeline. The app uses an offline-first architecture with Firebase cloud sync for multi-caregiver support.

**Key features:**
- Timeline-based event display (6h past / 3h future)
- One-tap quick logging with haptic feedback
- Formula bottle tracking with expiry timers
- Wake window predictions based on baby's age and patterns
- Multi-caregiver sync with conflict resolution
- Dark mode optimized for nighttime use

---

## Critical Rules

1. **Push after every change** - Do not accumulate changes locally. Each meaningful change must be committed and pushed immediately.
2. **Read before modifying** - Never propose changes to code you haven't read. Understand existing patterns first.
3. **Stop at architecture decisions** - Major architectural changes require explicit human approval before implementation.
4. **No silent failures** - Document blockers and concerns; don't proceed hoping issues resolve themselves.

---

## Development Lifecycle (PRIME Loop)

Follow this cycle for features and tasks:

```
PLAN → RESEARCH → IMPLEMENT → MEASURE → EVOLVE
```

- **Plan**: Define objectives, break into tasks, identify risks
- **Research**: Read existing code, understand patterns, gather context
- **Implement**: Build incrementally, test as you go
- **Measure**: Validate against requirements, run tests
- **Evolve**: Refactor based on findings, update documentation

---

## Project Structure

```
Hush/
├── App/
│   ├── HushApp.swift             # App entry point
│   └── AppDelegate.swift         # Push notification handling
├── Models/
│   ├── User.swift
│   ├── Baby.swift
│   ├── Event.swift
│   ├── EventTimestamp.swift      # UTC + timezone handling
│   └── EventData/
│       ├── EatEventData.swift
│       ├── SleepEventData.swift
│       └── DiaperEventData.swift
├── Views/
│   ├── MainScreen/
│   ├── Timeline/
│   ├── Actions/
│   ├── Settings/
│   ├── Auth/
│   └── Components/
├── ViewModels/
├── Services/
│   ├── AuthService.swift
│   ├── SyncService.swift
│   ├── EventService.swift
│   ├── WakeWindowPredictor.swift
│   ├── BottleExpiryService.swift
│   ├── NotificationService.swift
│   └── ConflictDetector.swift
├── Repositories/
│   ├── EventRepository.swift
│   ├── BabyRepository.swift
│   └── UserRepository.swift
├── Validation/
│   ├── SleepValidator.swift
│   └── FeedingValidator.swift
├── CoreData/
│   └── Hush.xcdatamodeld
└── Resources/
    └── Assets.xcassets
docs/
├── PRD.md                        # Product requirements
└── implementation-plan.md        # Phased implementation plan
```

---

## Code Standards

### Swift/SwiftUI Conventions

```swift
// Use Swift's strong typing - avoid Any/AnyObject
// Prefer struct over class for data models
// Use @MainActor for UI-related code
// Handle optionals explicitly (guard let, if let)
// Use async/await over completion handlers
// Document public APIs with /// comments
```

### Patterns in This Codebase

- **Architecture**: MVVM with Repository pattern
- **State Management**: `@Observable` classes with `@MainActor`
- **Data Access**: Repository pattern abstracts Core Data
- **Business Logic**: Service layer encapsulation
- **Sync**: Offline-first with background cloud sync
- **Validation**: Centralized validators for business rules
- **Error Handling**: Explicit error types, user-facing messages
- **Concurrency**: Swift structured concurrency (async/await, Task)

### Testing Requirements

- Unit tests for all services and validators
- UI tests for critical flows (quick log, sleep flow, bottle flow)
- Test files mirror source structure in `HushTests/`
- Tests must pass before push

---

## iOS-Specific Notes

### Required Permissions

The app requires these permissions:
- **Notifications** - For bottle expiry alerts, wake window reminders
- **Background App Refresh** - For sync when backgrounded

### Firebase Integration

- **Authentication**: Sign in with Apple (primary), email/password (fallback)
- **Firestore**: Real-time sync between caregivers
- **Security Rules**: Enforce caregiver access per baby
- Tokens stored securely in Keychain

### Offline-First Architecture

- All writes go to Core Data first, then sync to Firestore
- App must be fully functional without network
- Sync status indicator shows: synced / syncing / offline with pending
- Conflicts are detected and surfaced to user, never resolved silently

---

## Key Business Rules

These validations are critical and enforced at both UI and data layer:

1. **No multiple active sleeps** - Only one sleep can be in progress at a time
2. **No multiple active feedings** - Only one bottle feeding can be active
3. **Bottle expiry rules**:
   - Room temp, not fed: 2 hours from preparation
   - Room temp, feeding started: 1 hour from feeding start
   - Refrigerated: configurable up to 24 hours

---

## Git Workflow

### Commit Conventions

```
<type>: <description>

Types: feat, fix, docs, refactor, test, chore

Examples:
feat: add bottle expiry countdown timer
fix: resolve timezone display in timeline
docs: update implementation plan with phase 3
```

### Push Cadence

**Push to remote after:**
- Completing any task
- Before ending any session
- After resolving any blocker

**Push checklist:**
1. Code compiles without warnings
2. Tests pass
3. Meaningful commit message

---

## Decision Escalation

| Situation | Action |
|-----------|--------|
| Which approach for a bug fix | Proceed with best judgment |
| API/interface design choice | Recommend and explain rationale |
| Architecture change | **STOP** - Ask for approval |
| Security concern | **STOP** - Report immediately |
| Scope addition | **STOP** - Confirm with human |
| Performance tradeoff | Recommend with tradeoff analysis |

---

## Problem-Solving Protocol

When stuck, follow this sequence:

### 1. Self-Diagnose
- Re-read error messages carefully
- Check recent changes that might have caused it
- Search codebase for similar patterns

### 2. Research
- Check Apple documentation
- Look for existing solutions in codebase
- Review Firebase documentation if sync-related

### 3. Experiment
- Try isolated fixes
- Add diagnostic logging
- Test assumptions in isolation

### 4. Escalate
If still stuck, document:
- What you're trying to do
- What's happening vs. expected
- What you've tried
- Your hypothesis on root cause

---

## Session Checklists

### Starting Work

- [ ] Pull latest from remote
- [ ] Review recent commits for context
- [ ] Check for any pending issues or TODOs
- [ ] Verify project builds and tests pass

### Ending Work

- [ ] All changes committed with clear messages
- [ ] Pushed to remote
- [ ] No uncommitted files
- [ ] Brief note on what's next (if applicable)

---

## Quick Reference

### Build Commands

```bash
# Build for simulator
xcodebuild -scheme Hush -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild -scheme Hush -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Open in Xcode
open Hush.xcodeproj
```

### Key Files

| What | Where |
|------|-------|
| App entry | `Hush/App/HushApp.swift` |
| Timeline | `Hush/Views/Timeline/TimelineView.swift` |
| Event logging | `Hush/Services/EventService.swift` |
| Sync logic | `Hush/Services/SyncService.swift` |
| Wake predictions | `Hush/Services/WakeWindowPredictor.swift` |
| Implementation plan | `docs/implementation-plan.md` |

---

### Performance Targets

- Cold launch: < 1.0 second
- Warm launch: < 0.3 seconds
- Event logging: < 100ms tap-to-confirmation
- Timeline scroll: 120fps (ProMotion)
- Memory: < 100MB typical

---

*Last updated: January 2026*

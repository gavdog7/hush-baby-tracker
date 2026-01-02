# Backend Technology Decision

> **Decision**: Firebase (Authentication + Cloud Firestore)
> **Status**: Accepted
> **Date**: January 2026

---

## Context

Hush is an iOS baby tracking app designed for exhausted parents. The backend must support multiple caregivers (e.g., both parents) viewing and logging events in real-time, while working reliably in low-connectivity situations (3am feedings with spotty wifi).

---

## Requirements

| Requirement | Priority | Rationale |
|-------------|----------|-----------|
| **Offline-first** | Critical | Must work without internet, sync when reconnected |
| **Real-time sync** | Critical | Multiple caregivers see updates instantly |
| **User authentication** | Critical | Sign in with Apple, secure access |
| **Push notifications** | High | Bottle expiry alerts, wake window reminders |
| **Low maintenance** | High | Solo dev, no server management |
| **Privacy** | High | Baby data is sensitive |
| **Cost-effective** | Medium | Free/cheap at small scale |

---

## Decision

**Firebase** (Authentication + Cloud Firestore) was selected as the backend.

### Why Firebase

| Factor | Assessment |
|--------|------------|
| **Offline support** | Firestore has automatic offline caching and sync built-in |
| **Real-time sync** | Native listener-based updates, no polling needed |
| **All-in-one** | Auth + database + notifications in one SDK |
| **iOS SDK maturity** | Well-documented, Swift-friendly, actively maintained |
| **Free tier** | 50K reads/day, 20K writes/day — likely free forever at baby-app scale |
| **Time to MVP** | Syncing working in days, not weeks |
| **Sign in with Apple** | First-class support |

---

## Alternatives Considered

### 1. Supabase (PostgreSQL + Realtime)

Open-source Firebase alternative with PostgreSQL backend.

**Pros:**
- SQL database (familiar, powerful queries)
- Can self-host for full data control
- Good real-time support via websockets
- Sign in with Apple supported
- Predictable pricing

**Cons:**
- No built-in offline support — would require custom implementation
- Offline sync is complex to build correctly (conflict resolution, queue management)

**Verdict**: Offline-first would require weeks of custom development. Dealbreaker for MVP.

---

### 2. CloudKit (Apple's iCloud backend)

Native Apple solution where data lives in user's iCloud account.

**Pros:**
- Best privacy story — Apple stores data, not a third party
- Excellent offline support, built-in
- Free (Apple subsidizes via iCloud storage)
- Automatic authentication with Apple ID

**Cons:**
- Multi-caregiver sharing via CKShare is clunky
- Users must manually set up iCloud sharing
- iOS/macOS only — permanently locks out Android
- Less documentation and community support

**Verdict**: Privacy is excellent, but multi-caregiver UX is poor. Would require users to understand iCloud sharing concepts.

---

### 3. Custom Backend (Vapor/Node.js + PostgreSQL)

Build a custom REST/GraphQL API with own database.

**Pros:**
- Total control over data model, hosting, and logic
- No vendor lock-in
- Can optimize for specific use cases

**Cons:**
- Must build offline sync from scratch (complex)
- Must build real-time layer (websockets)
- Server costs ($5-20/month minimum)
- On-call for outages and maintenance
- Weeks/months of development time

**Verdict**: Maximum flexibility, but massive time investment for features Firebase provides out of the box.

---

### 4. Realm (MongoDB Mobile Database)

Mobile-first database with built-in sync (Realm Sync).

**Pros:**
- Excellent offline support — designed for mobile
- Realm Sync handles conflict resolution well
- Object-based API is intuitive

**Cons:**
- Would replace Core Data entirely (migration effort)
- Separate auth setup required
- Paid beyond limited free tier
- Different paradigm from rest of iOS ecosystem

**Verdict**: Strong technical choice, but adds cost and requires replacing Core Data layer.

---

### 5. AWS Amplify

Amazon's mobile backend platform.

**Pros:**
- Full feature set (auth, API, storage, notifications)
- DataStore has offline sync capability
- Good if already in AWS ecosystem

**Cons:**
- More complex setup than Firebase
- iOS SDK less polished
- AWS console is overwhelming
- Similar cost structure to Firebase

**Verdict**: Capable but more complex for equivalent features.

---

## Comparison Matrix

| Solution | Offline | Real-time | Easy Setup | Multi-user | Cost |
|----------|---------|-----------|------------|------------|------|
| **Firebase** | Yes | Yes | Yes | Yes | Free* |
| Supabase | No | Yes | Yes | Yes | Free* |
| CloudKit | Yes | Yes | Yes | Awkward | Free |
| Custom Backend | No | No | No | Yes | $$$ |
| Realm | Yes | Yes | Medium | Yes | $$ |
| AWS Amplify | Yes | Yes | No | Yes | Free* |

*Free at expected scale

---

## Tradeoffs Accepted

By choosing Firebase, we accept:

1. **Google dependency** — Data passes through Google infrastructure
   - Mitigated by: Firestore security rules, encryption at rest and in transit
   - Baby names and sensitive details stay on device where possible

2. **Vendor lock-in** — Data model is Firestore-specific (NoSQL documents)
   - Mitigated by: Clean repository pattern allows swapping backends later
   - Export functionality provides data portability

3. **NoSQL limitations** — Complex queries are harder than SQL
   - Mitigated by: Baby tracking domain is simple, document model fits well

4. **Pricing risk** — Costs scale with reads/writes if app goes viral
   - Mitigated by: Monitor usage, optimize queries, set budget alerts

---

## Security Considerations

Firebase security is implemented via:

1. **Firestore Security Rules** — Enforce that caregivers can only access babies they're linked to
2. **Authentication** — Sign in with Apple as primary method
3. **Encryption** — TLS 1.3 in transit, AES-256 at rest (Firebase default)
4. **Token management** — Stored in iOS Keychain, not UserDefaults

---

## Future Migration Path

If we need to move away from Firebase:

1. **Repository pattern** isolates Firebase from business logic
2. **Domain models** are independent of Firestore documents
3. **Export functionality** (Phase 10) provides data portability
4. Most likely migration targets:
   - Supabase (if offline can be solved)
   - Self-hosted solution (if scale demands it)
   - CloudKit (if privacy becomes primary concern)

---

## References

- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
- [Firestore Offline Capabilities](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

*This document records the architectural decision for future reference. Revisit if requirements change significantly.*

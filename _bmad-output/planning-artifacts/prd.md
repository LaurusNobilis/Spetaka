---
stepsCompleted: [step-01-init, step-02-discovery, step-02b-vision, step-02c-executive-summary, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish, step-12-complete]
inputDocuments:
  - "_bmad-output/planning-artifacts/product-brief-Spetaka-2026-02-25.md"
  - "_bmad-output/brainstorming/brainstorming-session-2026-02-25.md"
workflowType: 'prd'
date: "2026-02-26"
author: Laurus
classification:
  projectType: mobile_app
  domain: personal_productivity_relationship_management
  complexity: low-medium
  projectContext: greenfield
---

# Product Requirements Document - Spetaka

**Author:** Laurus
**Date:** 2026-02-26

## Executive Summary

Spetaka is a personal relationship companion for Android — built for people who want to actively care for the friends and family that matter most. It answers one question when you open it: *"Who deserves my care today?"* Then it makes acting on that answer effortless.

The app surfaces the right people at the right time through a smart priority view that combines overdue unacknowledged events, today's dates, and upcoming milestones — ordered by a dynamic priority score that factors relationship category, urgency, and care history. From any friend card, a single tap places a call, sends an SMS, or opens WhatsApp. On return, a pre-filled acquittement closes the loop.

Spetaka is built on a strict **pull philosophy**: zero notifications, zero badges, zero widgets — now and in all future versions. It exists when you choose it. This is not a constraint — it is the product's identity.

The v1 release targets Laurus as primary user and close circle as early adopters, distributed via the Google Play Store. It is built in Flutter with SQLite (Drift) for offline-first storage and WebDAV with transparent encryption for user-controlled sync — no third-party server, no compromise on privacy.

This is a clean rebuild from a validated Ionic prototype. The core priority model was proven. The rebuild delivers it with professional architecture, good engineering practices, and a foundation worthy of long-term maintenance and platform expansion.

### What Makes This Special

Every existing tool either nags you into caring (notification-driven apps, birthday reminders) or treats your relationships like a pipeline to manage (CRMs, contact managers). Spetaka is built on a different premise: **caring people don't need to be reminded — they need to be empowered**.

Key differentiators:
- **Pull, not push** — the app exists on your terms. No system interrupts your life to tell you to care.
- **Person-first, not event-first** — the atomic unit is the friend, not the date. Events serve the relationship, not the calendar.
- **One-tap from intention to gesture** — the friction between "I should reach out" and actually doing it has been eliminated by design.
- **Privacy by conviction** — encrypted WebDAV from day one. Your relationship data never touches a third-party server.
- **Built to grow with you** — for the already-intentional person *and* the person who wants to become one. Spetaka makes the right action obvious and frictionless until caring becomes a quiet ritual.

## Project Classification

| Attribute | Value |
|---|---|
| **Project Type** | Mobile App (Android-first, Flutter, Play Store) |
| **Domain** | Personal Productivity — Relationship Management |
| **Complexity** | Low-Medium (no regulated domain; privacy via self-imposed design principles) |
| **Project Context** | Greenfield — clean Flutter rebuild from validated Ionic prototype |
| **Target Platform v1** | Android (Samsung S25 primary device) |
| **Future Platforms** | iOS (Flutter shared codebase), macOS companion |

## Success Criteria

### User Success

Spetaka succeeds for a user when they measurably reach out more — not because a machine nudged them, but because the app made the intention effortless to act on.

**North star:** *"I actually reached out more to the people I love, and I was there when the people I care about needed me."*

**Behavioral indicators of user success:** acquittements logged growing month-over-month; daily view opened ≥ 3×/week; >80% of friend cards have at least one event; missed events trending toward zero; last contact dates recent on active cards.

**The anti-metric:** notifications or reminders sent = 0, always. Engagement is pull-driven — if users are engaged, it's because they chose to be.

**Personal validation gate (pre-Play Store release):**
- Laurus uses the daily view at least 3×/week for 4 consecutive weeks
- At least 5 friend cards active with events
- Acquittements being logged regularly — the contact loop is closing
- Zero data loss incidents

### Business Success

Spetaka is non-commercially motivated in v1. The objective is genuine quality — letting it drive organic growth.

**Core objective:** Be the app people tell their friends about because it made them a better friend.

| Horizon | Objective |
|---|---|
| Personal (v1) | Laurus uses it daily and it improves his relationship quality |
| Friends (v1 release) | Close circle adopts it; organic word-of-mouth begins |
| Play Store (growth) | >40% 30-day retention; users returning after install |
| Organic installs | Growing without paid acquisition |

**Distribution signal:** Any installs from outside Laurus's direct circle within 3 months of Play Store release indicates organic reach.

### Technical Success

| Requirement | Target |
|---|---|
| WebDAV sync reliability | Zero data loss incidents; data survives app reinstall |
| Offline-first | Full functionality without network connection |
| Daily view performance | Opens and priority recomputation feel instantaneous |
| No crashes on primary device | Zero critical crashes on Samsung S25 |
| Play Store compliance | Passes review; publishable in production track |
| Code quality | Professional architecture; maintainable and extensible for future phases |

### Measurable Outcomes

The single metric that matters above all others: **acquittements logged**. If users are acknowledging contact gestures inside Spetaka, they are reaching out to the people they love.

| KPI | Measure | Target |
|---|---|---|
| Acquittements/month | Real contact gestures made | Growing MoM — primary health metric |
| Daily view opens/week | Habitual engagement | ≥ 3/week per active user |
| Friend cards with ≥ 1 event | App genuinely in use | > 80% of users |
| Missed events rate | Core promise kept | Trending → 0 |
| 30-day retention (Play Store) | Users returning after install | > 40% |
| Organic installs | Word-of-mouth signal | Growing without paid acquisition |

## User Journeys

### Journey 1 — First Open: From Stranger to Ritual (Onboarding — Happy Path)

**Persona:** Laurus — intentional friend, geographically dispersed circle. Has tried calendar reminders, failed. The kind of person who thinks "I should call Thomas" on Tuesday and remembers on Friday when it's too late.

**Opening scene:** He installs Spetaka from the Play Store. He opens it for the first time — no tutorial, no onboarding wizard. A clean empty state with a clear prompt.

**Rising action:** He creates his first fiche — searches his phone contacts, selects Thomas, imports name and mobile in one tap. Adds a birthday (three weeks out) and a regular check-in cadence (every 3 weeks). The daily view is quiet — Thomas isn't urgent yet.

**Climax:** Ten days later, Laurus opens Spetaka on a Tuesday morning. Thomas appears in the heart briefing — birthday in 8 days, check-in cadence slightly overdue. He taps the WhatsApp button. The conversation opens pre-targeted. He sends a message. He returns to Spetaka — the acquittement prompt appears, pre-filled: *"WhatsApp message — today."* One tap to confirm.

**Resolution:** He hasn't missed Thomas's birthday. The app didn't remind him — he chose to open it. It just made sure he knew what mattered when he did.

**Capabilities revealed:** Contact import from phone, fiche creation, event + cadence setup, daily view priority surfacing, 1-tap action buttons, return-to-app acquittement prompt.

---

### Journey 2 — The Daily Ritual (Core Habit Loop — Returning User)

**Persona:** Same Laurus, 6 weeks in. 12 friend cards, 28 events. Spetaka is a quiet Tuesday morning ritual.

**Opening scene:** He opens the app at 8am. Heart briefing: 🔴 Sophie — birthday today. 🔴 Marc — check-in overdue 11 days. 💛 Isabelle — important life event in 2 days (new job). 💛 Théo — cadence due tomorrow.

**Rising action:** He calls Sophie — first time in two months, 20 minutes. Returns to Spetaka. Acquittement: *"Called — today."* He adds a note: *"She's moving to Lyon in April."* Confirms in one tap. He sends Marc a WhatsApp voice message. Acquittement: *"Voice message — today."* Isabelle and Théo are for tomorrow. He closes the app. Twelve minutes total.

**Resolution:** Two relationships reinforced, two more queued. No guilt about what he didn't do. The people who mattered today got his attention.

**Capabilities revealed:** Multi-entry daily view ordered by priority, enriched acquittement with action type + note, care score update after acquittement, partial-day usage.

---

### Journey 3 — WebDAV Setup (Technical Friction Point)

**Persona:** Same Laurus, Day 1, after creating his first 3 fiches. He wants his data off the device.

**Opening scene:** Settings → Sync. WebDAV configuration screen: server URL, username, password, passphrase field. Clear copy: *"Your passphrase encrypts everything before it leaves your device. It is never sent to the server. If you lose it, your data cannot be recovered."*

**Rising action:** He enters his Nextcloud URL, credentials, and passphrase. Taps "Test connection" — success. Enables sync. Initial upload completes in 4 seconds for 3 fiches.

**Edge case:** He misremembers his server password. The test fails. Error message is specific: *"Connection failed — check your server URL and credentials."* He corrects the URL (http → https). Second attempt succeeds.

**Resolution:** His data is encrypted and stored on his own server. He could reinstall the app tomorrow, re-enter his passphrase, and have everything back.

**Capabilities revealed:** WebDAV configuration UI, passphrase setup with clear UX copy, connection test with actionable error messages, initial sync with progress feedback, transparent encryption model explained in-app.

---

### Journey 4 — Re-engagement After a Gap (Recovery — Returning After Absence)

**Persona:** Same Laurus, 18 days since he last opened Spetaka. A busy period — work, travel, life.

**Opening scene:** He opens the app. No badge, no notification guilt-tripping him. Just the daily view, quietly updated. Heart briefing is dense: 3 urgents, 4 importants.

**Rising action:** He sees Édouard — check-in overdue 16 days, and a concern flag he set two months ago: *"going through a difficult divorce."* The priority score has surfaced him to the top. Laurus feels a pang — he genuinely forgot. He taps the card, reads the note, calls.

He works through the list over two mornings — not all at once, just what feels right each day. The daily view handles the queue; he handles the relationships.

**Climax:** On day 3, the heart briefing is clear. Not because Spetaka pressured him — because he chose to act when he was ready.

**Resolution:** The 18-day gap didn't break the system. No punitive streak lost, no shame mechanic. The people who needed attention were there, waiting. Laurus caught up at his own pace.

**Capabilities revealed:** Priority elevation for concern-flagged friends, care score reflecting gap in contact, system stability during extended non-use, absence of guilt/streak mechanics — pull philosophy intact under stress.

---

### Journey Requirements Summary

| Capability Area | Journeys |
|---|---|
| Contact import from phone | J1 |
| Fiche creation + event / cadence setup | J1 |
| Daily view with dynamic priority scoring | J1, J2, J4 |
| Heart briefing 2+2 (urgents / importants) | J2, J4 |
| 1-tap action buttons (Call, SMS, WhatsApp) | J1, J2 |
| Return-to-app acquittement prompt | J1, J2 |
| Enriched acquittement (type + note) | J2 |
| Concern / préoccupation flag + priority elevation | J4 |
| Care score tracking + history | J2, J4 |
| WebDAV configuration + passphrase setup | J3 |
| Connection test with actionable error messages | J3 |
| No punishment / no streak mechanics | J4 |
| Graceful re-engagement after absence | J4 |

## Mobile App Specific Requirements

### Project-Type Overview

Spetaka is a Flutter-based Android application distributed via the Google Play Store. It is offline-first by design, single-user, and requires no backend server. WebDAV sync is the only network operation. The app targets Android v1 with a clean iOS path for Phase 3.

### Technical Architecture Considerations

| Concern | Decision |
|---|---|
| Framework | Flutter (Dart) — single codebase, Android-first |
| Local persistence | SQLite via Drift (type-safe, offline-first) |
| Network | WebDAV only — no REST API, no Firebase, no third-party server |
| Encryption | Passphrase-based AES-256, applied before WebDAV transmission |
| Key derivation | PBKDF2 or Argon2 |
| Minimum Android version | API 26+ (Android 8.0) — covers >95% of active devices |

### Platform Requirements

| Requirement | Detail |
|---|---|
| Primary target | Android (Samsung S25, Android 15) |
| Minimum Android version | API 26+ (Android 8.0) |
| Screen sizes | Phone form factor; tablet not required for v1 |
| Orientation | Portrait primary; landscape not required for v1 |
| Future platform | iOS — Flutter shared codebase, native feel |

### Device Permissions

| Permission | Purpose | Handling if Denied |
|---|---|---|
| `READ_CONTACTS` | Import friend from phone contacts | Manual entry fallback — fully functional without permission |
| `INTERNET` | WebDAV sync only | App remains fully functional offline; sync disabled |

**Permission request strategy:** `READ_CONTACTS` requested at the moment the user first taps "Import from contacts" — not on first launch. Clear rationale shown: *"To import your friend's name and number — nothing is sent anywhere."* If denied, manual name/number entry is available.

### Offline Mode

The app is fully functional offline. WebDAV sync is background-only and non-blocking. All reads and writes go to local SQLite database. Sync is opportunistic — when network is available and WebDAV is configured.

| Scenario | Behaviour |
|---|---|
| No network | Full app functionality; sync silently skipped |
| WebDAV unavailable | Local data intact; sync retried next launch |
| First install (no sync configured) | App fully usable; sync optional |
| Reinstall with WebDAV configured | Re-enter passphrase → full restore from WebDAV |

### Push Strategy

**None.** No push notifications, no local notifications, no scheduled notifications, no badges, no widgets — permanent, not a v1 limitation. Zero notification surface is the product's identity and must be enforced at the architecture level: no FCM integration, no notification channels, no WorkManager notification tasks.

### Store Compliance

| Requirement | Detail |
|---|---|
| Distribution | Google Play Store — production track |
| Privacy policy | Required (contacts permission triggers mandatory disclosure) |
| Data safety form | Contacts data read, not shared; no data sent to third parties |
| Target SDK | Latest stable Android SDK at time of build |
| App signing | Play App Signing (Google-managed) |
| Age rating | Everyone (no mature content, no monetisation) |
| Release gate | 4 weeks personal daily use + zero data loss before public release |

### Implementation Considerations

- **Contact import:** Android `ContactsContract` API via Flutter plugin (e.g., `flutter_contacts`). Only name and primary mobile number imported. No photo import in v1.
- **Action intents:** `tel://` for calls, `sms://` for SMS, `https://wa.me/` for WhatsApp. WhatsApp deep link requires international format — normalisation needed at fiche creation.
- **Return-to-app detection:** `AppLifecycleState.resumed` to trigger acquittement prompt after user returns from phone/messaging action.
- **WebDAV client:** `webdav_client` Flutter package or equivalent, behind an abstraction layer for testability.
- **Encryption:** AES-256 symmetric encryption; key derivation via PBKDF2 or Argon2.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Personal-validation MVP — the launch gate is Laurus using the app daily for 4 consecutive weeks with zero data loss, before any public Play Store release. This is the right approach for a personal tool built to share: validate the experience on yourself before asking others to trust it.

**Solo build:** Single developer (Laurus). Scope must be achievable solo without cutting core value. No cuts to the MVP feature set — all listed capabilities are necessary for the core loop to function. The features are tightly coupled: daily view without acquittements = no loop closure; acquittements without fiches = no context. The MVP is indivisible.

**Resource requirement:** Flutter + Dart proficiency, Android development environment, access to a WebDAV server (Nextcloud or equivalent) for testing.

### MVP Feature Set (Phase 1)

**Core user journeys supported:** J1 (onboarding), J2 (daily ritual), J3 (WebDAV setup), J4 (re-engagement after absence).

**Must-have capabilities:**

| Capability | Notes |
|---|---|
| Friend cards (fiches) | Name, mobile (contacts import or manual), multi-tags, free-text notes |
| Editable event types | 5 defaults; user-editable list |
| Daily view with dynamic priority scoring | Overdue + today + next 3 days; weighted score |
| Heart briefing 2+2 | 2 urgent + 2 important at top of daily view |
| 1-tap actions | Call, SMS, WhatsApp from friend card |
| Post-action return flow | On app resume, friend card reopens pre-focused for acquittement + conversation note |
| Enriched acquittement | Action type selector + optional free-text note about the conversation |
| Concern / préoccupation flag | Marks a friend as going through something; elevates priority; visible on card |
| Care score (internal) | Computed from acquittement history; used by priority algorithm; not necessarily exposed in UI v1 |
| WebDAV encrypted storage | Passphrase-based AES-256; transparent to user after setup |

**Storage fallback (if WebDAV proves too complex for v1):**

If WebDAV integration is not achievable within v1 scope, Phase 1 ships with a **manual file export/import** mechanism instead:
- Export: encrypted JSON file saved to device storage
- Import: select file → enter passphrase → restore
- Same data model and encryption; different transport
- WebDAV promoted to Phase 1.5 / early Phase 2

This fallback preserves the privacy guarantee and data portability without blocking the MVP launch.

### Post-MVP Features (Phase 2 — Growth)

| Feature | Rationale for deferral |
|---|---|
| Draft messages & rotation | Core loop works without it |
| Concern follow-up auto-event creation | Acquittement notes cover the intent in v1 |
| "Last contact" visible on card | Useful; not blocking |
| "Lost from sight" auto-surfacing | Addressable via cadence events in v1 |
| LLM-assisted message drafting (local, offline) | Galaxy AI / Gemma — independent of core loop |
| Full gamification RPG system | Independent of LLM; non-blocking |
| WebDAV (if deferred from v1) | Phase 1.5 if fallback was used |

### Vision (Phase 3 — Expansion)

| Feature | Notes |
|---|---|
| iOS version | Flutter shared codebase — clean path when ready |
| Shared friends view (partner/spouse) | Opt-in, selective, private-by-default |
| macOS companion app | After Android + iOS stable |
| Photos on friend cards | After WebDAV storage is stable |

### Risk Mitigation Strategy

**Technical risks:**

| Risk | Mitigation |
|---|---|
| WebDAV encryption complexity | File export/import fallback defined and scoped |
| `AppLifecycleState.resumed` unreliable on some Android OEMs | Test on Samsung S25 early; fallback: manual "I just reached out" button on card |
| WhatsApp deep link requires international number format | Normalise number at fiche creation; clear UX guidance if format invalid |
| Flutter plugin quality/maintenance | Evaluate `flutter_contacts` and `webdav_client` early in build; have fallback plugins identified |

**Market risks:**

| Risk | Mitigation |
|---|---|
| Solo developer motivation / time | Personal-use validation gate keeps feedback loop tight and motivation real |
| Play Store contacts permission scrutiny | Privacy policy drafted early; data safety form accurate; permission rationale clear in-app |

**Resource risks:**

| Risk | Mitigation |
|---|---|
| Solo build takes longer than expected | WebDAV fallback pre-defined; no external dependencies or team coordination required |
| Scope creep pressure from Phase 2 ideas | Hard deferral list maintained; PRD is the boundary document |

**Permanent constraint across all phases:** pull philosophy. Zero notifications, zero badges, zero widgets — every version, every platform, no exceptions.

## Functional Requirements

### Friend Management (Fiches)

- **FR1:** User can create a friend card (fiche) by importing contact details from the phone's address book
- **FR2:** User can create a friend card manually by entering name and mobile number
- **FR3:** User can assign one or more category tags to a friend card
- **FR4:** User can add and edit free-text context notes on a friend card
- **FR5:** User can view all friend cards in a list
- **FR6:** User can open a friend card to see full details, events, and contact history
- **FR7:** User can edit any field on a friend card at any time
- **FR8:** User can delete a friend card
- **FR9:** User can mark a friend as having an active concern (préoccupation flag) with a short descriptive note
- **FR10:** User can clear an active concern flag from a friend card

### Event & Cadence Management

- **FR11:** User can add an event to a friend card with a date, type, and optional free-text comment
- **FR12:** User can add a recurring check-in cadence to a friend card with a configurable interval
- **FR13:** User can edit or delete any event on a friend card
- **FR14:** User can view the list of event types and edit it (add, rename, delete, reorder)
- **FR15:** System provides 5 default event types at first launch: birthday, wedding anniversary, important life event, regular check-in, important appointment
- **FR16:** User can manually mark an event as acknowledged (acquitted) from the friend card

### Daily View & Priority Engine

- **FR17:** User can open a daily view showing friends who need attention today
- **FR18:** System surfaces overdue unacknowledged events, today's events, and events within the next 3 days in the daily view
- **FR19:** System orders the daily view by a dynamic priority score weighted by: event type importance, days overdue, friend category, active concern flag (×2), and low care score
- **FR20:** System displays a heart briefing at the top of the daily view: 2 urgent entries and 2 important entries
- **FR21:** User can tap any entry in the daily view to open the corresponding friend card

### Actions & Communication

- **FR22:** User can initiate a phone call to a friend with one tap from their card
- **FR23:** User can initiate an SMS to a friend with one tap from their card
- **FR24:** User can open a WhatsApp conversation with a friend with one tap from their card
- **FR25:** System detects when the user returns to the app after a communication action and presents the friend's card pre-focused for acquittement and note-taking

### Acquittement & Contact History

- **FR26:** User can log an acquittement on a friend card specifying the action type (call, SMS, WhatsApp message, voice message, seen in person)
- **FR27:** User can add a free-text note to an acquittement describing what was discussed or any relevant context
- **FR28:** System pre-fills the acquittement prompt with the detected action type and current timestamp when triggered by post-action return
- **FR29:** User can confirm the pre-filled acquittement in one tap
- **FR30:** System maintains a chronological contact history log per friend card (acquittements with type, date, note)
- **FR31:** System updates the friend's care score after each acquittement is logged

### Sync & Storage

- **FR32:** User can configure a WebDAV server connection (URL, username, password, encryption passphrase)
- **FR33:** User can test the WebDAV connection before enabling sync
- **FR34:** System encrypts all data with the user's passphrase before transmitting to WebDAV
- **FR35:** System syncs data to WebDAV automatically when network is available and sync is configured
- **FR36:** User can restore all data from WebDAV after reinstall by re-entering their passphrase
- **FR37:** User can export all data to an encrypted local file as a standalone backup
- **FR38:** User can import and restore data from a previously exported encrypted file

### Settings & Configuration

- **FR39:** User can view and edit all app settings from a dedicated settings screen
- **FR40:** User can update or reset their WebDAV sync configuration including passphrase
- **FR41:** System operates with full functionality when no network connection is available

## Non-Functional Requirements

### Performance

- **NFR1:** The daily view loads and renders its full content within 1 second on the primary target device (Samsung S25)
- **NFR2:** Priority score recomputation completes within 500ms — the daily view never shows a loading state for ranking
- **NFR3:** Tapping a 1-tap action button (Call, SMS, WhatsApp) launches the target app within 500ms
- **NFR4:** Friend card opens within 300ms of tap from any screen
- **NFR5:** WebDAV sync runs as a background operation with no perceptible UI impact

### Security & Privacy

- **NFR6:** All on-device data is encrypted at rest using AES-256 with a key derived from the user's passphrase (PBKDF2 or Argon2)
- **NFR7:** All data transmitted to WebDAV is encrypted client-side before leaving the device — the server never receives plaintext
- **NFR8:** The user's passphrase is never stored, transmitted, or logged — only the in-memory derived key is used during an active session
- **NFR9:** The app requests only `READ_CONTACTS` and `INTERNET` permissions, each requested at first point of use, not at install
- **NFR10:** No analytics, telemetry, crash reporting, or advertising SDKs are included — zero data transmitted to any third-party service

### Reliability & Data Integrity

- **NFR11:** The local SQLite database is the single source of truth — no data loss after any unexpected app termination or device restart
- **NFR12:** WebDAV sync failures must not corrupt or partially overwrite local data — all sync operations are atomic or safely resumable
- **NFR13:** A full restore from WebDAV reproduces all friend cards, events, acquittements, and settings without data loss
- **NFR14:** The exported backup file is a complete, self-contained snapshot restorable to any device

### Accessibility

- **NFR15:** All interactive elements meet the minimum touch target size of 48×48dp (Android Material Design baseline)
- **NFR16:** Text content meets WCAG AA contrast ratio (4.5:1 minimum for normal text)
- **NFR17:** Core flows (daily view, friend card, acquittement) are navigable with Android TalkBack screen reader





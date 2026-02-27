---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - "_bmad-output/brainstorming/brainstorming-session-2026-02-25.md"
date: "2026-02-25"
author: Laurus
---

# Product Brief: Spetaka

## Executive Summary

Spetaka is a personal relationship companion for Android — designed for people who
want to actively show love to the friends who matter most. It surfaces who needs your
attention today, and makes reaching out as frictionless as a single tap.

Unlike CRMs, calendar reminders, or notification-driven apps, Spetaka operates on a
**pull philosophy**: no interruptions, no badges, no guilt. You open it when you're
ready to care, and it tells you exactly who deserves that care right now.

The app begins as a personal tool for its creator, built for publishing on the
Google Play Store so friends with the same values can benefit from it too.

---

## Core Vision

### Problem Statement

Maintaining genuine friendships requires intentional effort — but life creates noise
that buries that intention. People who care deeply about their friends still forget
birthdays, miss the right moment to reach out, or lose track of who they haven't
spoken to in months. The problem isn't lack of love — it's lack of a system that
respects both the relationship and the user's autonomy.

### Problem Impact

Without the right tool:
- Important dates pass unacknowledged, creating distance and regret
- The cognitive overhead of "who should I contact?" goes unresolved
- Reaching out gets delayed because the friction of finding a number and composing
  a message feels like too much in a busy moment
- Friends gradually drift — not from indifference, but from inattention

### Why Existing Solutions Fall Short

| Solution | Failure Mode |
|---|---|
| Calendar reminders | Event-focused, not relationship-focused. No context. No action shortcut. |
| Phone contacts | Zero intentionality. No dates, no history, no priority. |
| CRMs (Monica, Clay) | Designed for professionals. Heavy, complex, intimidating for personal use. |
| Birthday apps | Single-purpose, notification-heavy. Contrary to the pull philosophy. |
| Previous Spetaka (Ionic) | Proved the priority concept works — but lacked contact integration, was not rebuilt on a solid foundation, and left LLM/gamification unfinished. |

The existing Ionic version validated the core hypothesis: **prioritizing friend needs
for action works**. The rebuild takes that validated core and makes it complete.

### Proposed Solution

Spetaka is rebuilt from scratch as a native Android application. It centers on two
things done exceptionally well:

1. **A daily view** that surfaces the right friends at the right time — combining
   overdue unacknowledged events, today's dates, and upcoming priorities into a
   single, human, actionable view
2. **1-tap actions** — call, SMS, WhatsApp — directly from any friend card, with
   automatic acquittement prompts on return

Everything else (WebDAV sync, event types, drafts, care scoring) exists to serve
these two pillars.

### Key Differentiators

- **Pull, not push** — zero notifications, ever. Spetaka exists when you choose it.
- **Friend-first, not event-first** — the atomic unit is the person, not the date
- **Proven core, clean rebuild** — the priority model was validated in v1; v2 gets
  it right architecturally
- **Privacy by design** — WebDAV with transparent encryption; your data never touches
  a third-party server
- **Built to share** — personal tool first, Play Store ready from day one

---

## Target Users

### Primary Users

#### Persona — The Intentional Friend

**Profile:**
An adult who maintains a meaningful but geographically dispersed circle of friends
and family. They are busy — work, life, responsibilities fill their days — but they
hold their relationships as a genuine priority, not an afterthought. They don't want
to be reminded by a machine; they want to *choose* to show up. Tech-comfortable,
privacy-aware, and frustrated by tools that are either too heavy (CRMs) or too noisy
(notification-driven apps).

**Demographics:** No fixed target demographic defined. The unifying trait is
*intentionality about friendship*, not age, profession, or geography.

**Their core problem:**
They care deeply but life creates noise. Friends' important dates slip by. The "I
should reach out" thought appears and disappears without action. The friction between
intention and gesture — finding the number, composing a message — is enough to kill
the moment.

**What they want from Spetaka:**
Open the app when they have a moment of care, see immediately who deserves attention
today, and act in one or two taps. Then close it. No friction, no guilt, no noise.

**Their "aha!" moment:**
The first time they open the daily view and see a friend's name surface — someone
they hadn't thought of recently — and realize Spetaka remembered what they forgot.

---

### Secondary Users

#### Future — Shared Relationship View (Partner / Close Friend)

Not in scope for v1, but identified as a meaningful future direction: the ability
to share a subset of friends and events with a trusted person (spouse, close friend).
Common friends would appear in both views; events could be co-managed. This preserves
the personal, pull-based philosophy while adding a collaborative layer for households
or tight-knit pairs.

**Design constraint for future consideration:** sharing must be opt-in, selective,
and private-by-default. It should never feel like surveillance.

---

### User Journey

#### Discovery
A user hears about Spetaka from a friend (Laurus's circle) or finds it on the Play
Store by searching for "friend reminder" or "relationship tracker". The privacy-first,
no-notification positioning is an immediate differentiator that earns a download.

#### Onboarding — Day One
1. Open the app for the first time
2. Create the first friend card (fiche) — link from phone contacts or enter manually:
   name, mobile number, optional category and notes
3. Add one or two events to that friend (birthday, regular check-in cadence)
4. Land on the daily view — see their first friend already surfaced if a date is near

The first friend card *is* the onboarding. No tutorial needed beyond that gesture.

#### Core Daily Usage
User opens Spetaka intentionally — no push, no badge. The daily view shows who needs
attention: overdue unacknowledged events, today's dates, upcoming within 3 days. They
tap a name, see the friend card, tap Call or WhatsApp, reach out. On return, they
acknowledge the action. Done.

#### Success Moment
The first birthday they don't miss. The first time a friend says "I was just thinking
about you" — and Spetaka had surfaced their name the day before.

#### Long-term Habit
Spetaka becomes a quiet ritual. Not a daily obligation — a tool they reach for when
they want to be intentional. The history and care score build silently over months,
making the daily view smarter and more personal over time.

---

## Success Metrics

### User Success

Spetaka succeeds for a user when they measurably reach out more — not because they
were reminded by a machine, but because the app made the intention effortless to act
on. The north star metric for user success is:

> **"I actually reached out more to the people I love, and I was there when people I
> care about needed me."**

**Behavioral signals that indicate user success:**
- Regular acquittements logged — the user is completing contact gestures, not just
  opening the app
- Zero missed events for tracked friends over a rolling 30-day period
- Friend cards with recent "last contact" dates — relationships are active, not stale
- The daily view is opened at least once a week — the app is a habit, not abandoned

**The anti-metric:** Number of notifications or reminders sent — because Spetaka
sends zero. If a user is engaged, it's because they *chose* to be.

---

### Business Objectives

Spetaka is not commercially motivated in v1. The objective is to build something
that genuinely helps people care for each other — and let quality drive organic
growth. A secondary goal is establishing a credible Play Store presence that enables
future distribution to a broader audience.

**Core objective:** Be the app that people tell their friends about because it made
them a better friend.

**Horizon objectives:**
| Horizon | Objective |
|---|---|
| Personal (v1) | Laurus uses it daily and it improves his relationship quality |
| Friends (v1 release) | Close circle adopts it; organic word-of-mouth begins |
| Play Store (growth) | Users retained past 30 days — they're using it, not just trying it |

---

### Key Performance Indicators

| KPI | What it measures | Target |
|---|---|---|
| Daily view opens per week | Habitual engagement | ≥ 3 opens/week per active user |
| Acquittements logged per month | Real contact gestures made | Growing month-over-month |
| Friend cards with ≥ 1 event | App is genuinely set up, not empty | > 80% of users |
| 30-day retention (Play Store) | Users returning after install | > 40% |
| Missed events rate | Core promise kept | Trending toward 0 |
| Organic installs | Word-of-mouth signal | Growing without paid acquisition |

**The one metric that matters above all:** acquittements logged. If users are
acknowledging contact gestures inside Spetaka, they are reaching out to the people
they love. That is the entire point.

---

## MVP Scope

### Core Features (v1)

The MVP delivers the two pillars of Spetaka and nothing more: a smart daily view
and frictionless 1-tap actions. Every feature below is necessary to fulfill the
core promise.

| Feature | Description |
|---|---|
| **Friend cards** | One card per friend: name, mobile number (linked from phone contacts), multi-tags/category, free-text context notes |
| **Editable event types** | 5 default types (birthday, anniversary, important life event, regular check-in, important appointment) — fully editable by user |
| **Daily view** | Surfaces overdue unacknowledged events + today's dates + next 3 days, ordered by dynamic priority score |
| **Heart briefing 2+2** | Top of daily view: 2 urgent (overdue, active concern, within 24h) + 2 important (next 3 days, near cadences) |
| **Dynamic priority score** | Weighted by event type, days overdue, friend category, active concern flag, care score |
| **1-tap actions** | Call, SMS, WhatsApp directly from friend card — one tap, no friction |
| **Auto-acquittement prompt** | On return to app after action, pre-filled acquittement proposed — confirm in 1 tap |
| **Enriched acquittement** | Action type selector: message sent, called, seen in person, voice message |
| **WebDAV encrypted storage** | Passphrase set once at install; all data encrypted transparently; no third-party server |

### Out of Scope for MVP

These are explicitly deferred — not forgotten, just not v1:

| Deferred Feature | Rationale |
|---|---|
| Draft messages & rotation | Nice to have; core loop works without it |
| Concern follow-up tracking | Adds complexity; acquittement notes cover the intent |
| "Last contact" on card | Useful but not blocking the core use case |
| "Lost from sight" auto-surfacing | Can be addressed via cadence events in v1 |
| LLM message drafting | Phase 2 — requires Galaxy AI / Gemma integration |
| Gamification (RPG system) | Phase 2 — independent of core loop |
| Shared friends view (spouse/partner) | Future — requires sync architecture extension |
| Photos on friend cards | After WebDAV storage is stable |
| macOS / web app | After Android version is stable |
| iOS version | Future — architecture chosen (Flutter) to make this clean when ready |

### MVP Success Criteria

The MVP is considered successful when:
- Laurus uses the daily view at least 3×/week for 4 consecutive weeks
- At least 5 friend cards are active with events
- Acquittements are being logged regularly (the contact loop is closing)
- No critical bugs on Android (Samsung S25 primary target device)
- WebDAV sync is reliable and data survives app reinstall

**Go/no-go for Play Store release:** personal daily use validated over 4 weeks with
zero data loss incidents.

### Future Vision

**Phase 2 (Enrichment):**
- LLM-assisted message drafting (local, offline — Galaxy AI / Gemma via MediaPipe)
- Gamification: RPG-inspired progress system (XP, classes, Friend Forest) —
  no punishment mechanics, ever
- Draft message library with rotation for recurring contacts
- Concern follow-up system with automatic event creation

**Phase 3 (Platform):**
- iOS version (Flutter makes this a clean path — shared codebase, native feel)
- Shared friends view for partner/spouse (opt-in, selective, private-by-default)
- macOS companion app

**Guiding constraint across all phases:** pull philosophy is permanent. Zero
notifications, zero badges, zero widgets — in every version, on every platform.

### Technology Stack

| Layer | Choice | Rationale |
|---|---|---|
| Framework | **Flutter (Dart)** | Single codebase for Android now + iOS future; excellent offline-first; strong native feel |
| Local storage | SQLite via Drift | Type-safe, offline-first, reliable on Android |
| Sync | WebDAV + encryption | User-controlled, no third-party server, passphrase-based |
| Target platform v1 | Android (Samsung S25) | Primary device; Play Store distribution |
| Future platform | iOS | Flutter path is clean when ready |
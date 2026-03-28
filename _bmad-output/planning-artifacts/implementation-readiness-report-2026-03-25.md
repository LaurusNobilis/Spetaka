---
name: implementation-readiness-report
date: 2026-03-25
project: Spetaka
stepsCompleted: [step-01-document-discovery, step-02-prd-analysis, step-03-epic-coverage-validation, step-04-ux-alignment, step-05-epic-quality-review, step-06-final-assessment]
documentsSelected:
  prd: prd.md
  architecture: architecture.md
  architectureAddendum: architecture-phase2-addendum.md
  epics: epics.md
  ux: ux-design-specification.md
---

# Implementation Readiness Assessment Report

**Date:** 2026-03-25
**Project:** Spetaka

---

## Step 1 — Document Inventory

| Document Type | File | Size | Last Modified |
|---|---|---|---|
| PRD | `prd.md` | 31,491 bytes | Mar 25, 2026 |
| Architecture (Main) | `architecture.md` | 43,412 bytes | Mar 1, 2026 |
| Architecture (Addendum) | `architecture-phase2-addendum.md` | 24,953 bytes | Mar 25, 2026 |
| Epics & Stories | `epics.md` | 107,178 bytes | Mar 25, 2026 |
| UX Design | `ux-design-specification.md` | 54,462 bytes | Feb 26, 2026 |

**No duplicate conflicts found.** Architecture addendum is complementary to main architecture doc; both will be used.

---

## Step 3 — Epic Coverage Validation

### FR Coverage Matrix (Phase 1 — In-Scope)

| FR | PRD Requirement (summary) | Epic / Story | Impl Status |
|---|---|---|---|
| FR1 | Create friend card via contact import | Epic 2 · Story 2.1 | ✅ done |
| FR2 | Create friend card manually | Epic 2 · Story 2.2 | ✅ done |
| FR3 | Assign category tags | Epic 2 · Story 2.3 | ✅ done |
| FR4 | Add/edit free-text notes | Epic 2 · Story 2.4 | ✅ done |
| FR5 | View friend cards list | Epic 2 · Story 2.5 | ✅ done |
| FR6 | Open friend card detail | Epic 2 · Story 2.6 | ✅ done |
| FR7 | Edit any field on friend card | Epic 2 · Story 2.7 | ✅ done |
| FR8 | Delete friend card | Epic 2 · Story 2.8 | ✅ done |
| FR9 | Set concern/préoccupation flag + note | Epic 2 · Story 2.9 | ✅ done |
| FR10 | Clear concern flag | Epic 2 · Story 2.9 | ✅ done |
| FR15 | Add dated event (date, type, comment) | Epic 3 · Story 3.1 | ✅ done |
| FR16 | Add recurring check-in cadence | Epic 3 · Story 3.2 | ✅ done |
| FR17 | Edit or delete event | Epic 3 · Story 3.3 | ✅ done |
| FR18 | View/edit event types list | Epic 3 · Story 3.4 | ✅ done |
| FR19 | 5 default event types at first launch | Epic 3 · Story 3.1 | ✅ done |
| FR20 | Manual event acknowledgement | Epic 3 · Story 3.5 | ✅ done |
| FR22 | Open daily view | Epic 4 · Story 4.2 | ✅ done |
| FR23 | Surface overdue / today / +3 days | Epic 4 · Story 4.2 | ✅ done |
| FR24 | Dynamic priority score ordering | Epic 4 · Story 4.1 | ✅ done |
| FR25 | Heart briefing 2+2 | Epic 4 · Story 4.3 | ✅ done |
| FR26 | Tap entry → open friend card | Epic 4 · Story 4.6 | ✅ done |
| FR27 | 1-tap phone call | Epic 5 · Story 5.1 | ✅ done |
| FR28 | 1-tap SMS | Epic 5 · Story 5.1 | ✅ done |
| FR29 | 1-tap WhatsApp | Epic 5 · Story 5.1 | ✅ done |
| FR30 | Return-to-app detection + pre-focus for acquittement | Epic 5 · Story 5.2 | ✅ done |
| FR31 | Log acquittement with action type | Epic 5 · Story 5.3 | ✅ done |
| FR32 | Add note to acquittement | Epic 5 · Story 5.3 | ✅ done |
| FR33 | Pre-fill acquittement prompt on return | Epic 5 · Story 5.3 | ✅ done |
| FR34 | Confirm pre-filled acquittement in one tap | Epic 5 · Story 5.3 | ✅ done |
| FR35 | Chronological contact history log per friend | Epic 5 · Story 5.4 | ✅ done |
| FR36 | Update care score after acquittement | Epic 5 · Story 5.5 | ✅ done |
| FR42 | Export encrypted local backup | Epic 6 · Story 6.1 | ✅ done |
| FR43 | Import/restore from encrypted backup | Epic 6 · Story 6.1 | ✅ done |
| FR48 | Settings screen | Epic 7 · Story 7.1 | ✅ done |
| FR49 | Update backup passphrase + reset settings | Epic 7 · Story 7.1 | ✅ done |
| FR50 | Full functionality offline | Epic 7 · Story 7.2 | ✅ done |

### NFR Coverage Matrix (Phase 1 — In-Scope)

| NFR | Requirement (summary) | Epic / Story | Impl Status |
|---|---|---|---|
| NFR1 | Daily view renders < 1 second | Epic 4 · Story 4.2 | ✅ done |
| NFR2 | Priority recomputation < 500ms | Epic 4 · Story 4.1 | ✅ done |
| NFR3 | 1-tap action launches < 500ms | Epic 5 · Story 5.1 | ✅ done |
| NFR4 | Friend card opens < 300ms | Epic 2 · Stories 2.5/2.6 | ✅ done |
| NFR6 | AES-256-GCM at rest, PBKDF2 key derivation, all PII fields | Epic 1 · Stories 1.3/1.7/1.8 | ✅ done |
| NFR8 | Passphrase never stored/transmitted/logged | Epic 1 · Story 1.3 | ✅ done |
| NFR9 | READ_CONTACTS only; INTERNET not requested Phase 1 | Epic 1 · Story 1.1 | ✅ done |
| NFR10 | No analytics/telemetry/crash reporting/ad SDKs | Epic 1 · Story 1.1 | ✅ done |
| NFR11 | SQLite single source of truth | Epic 1 · Story 1.2 | ✅ done |
| NFR13 | Full restore all-or-nothing (single Drift transaction) | Epic 6 · Story 6.1 | ✅ done |
| NFR14 | Backup file is self-contained and portable | Epic 6 · Story 6.1 | ✅ done |
| NFR15 | 48×48dp minimum touch targets | Epic 7 · Story 7.3 | ✅ done |
| NFR16 | WCAG AA contrast (4.5:1) | Epic 7 · Story 7.3 | ✅ done |
| NFR17 | TalkBack navigability for core flows | Epic 7 · Story 7.3 | ✅ done |

### Coverage Statistics

- **Total Phase 1 FRs:** 35
- **FRs covered in epics:** 35
- **FR coverage:** 100% ✅

- **Total Phase 1 NFRs:** 14
- **NFRs covered in epics:** 14
- **NFR coverage:** 100% ✅

---

### ⚠️ Issues Found During Coverage Validation

#### ISSUE 1 — CRITICAL: Story 4.7 exists but is NOT in epics.md

**Story:** `4-7-swipe-navigation-daily-friends` — "Swipe navigation Daily View ↔ Friends List"

**Current state:** The implementation artifact `4-7-swipe-navigation-daily-friends.md` exists and sprint-status.yaml lists it as `review`. It is a real, in-progress feature. However, **it does not appear anywhere in `epics.md`**.

**Impact:**
- Epic 4 in epics.md lists only 6 stories (4.1–4.6); Story 4.7 is a phantom
- The story itself notes: *"this story key is not currently listed in sprint-status.yaml"* (out of date — it IS listed now)
- No FR maps to swipe navigation — it is a UX enhancement beyond PRD requirements; however it alters the app shell and GoRouter structure (ShellRoute refactor) which could affect ALL other stories' navigation assumptions
- The story is in `review` status, meaning code changes are already in flight

**Recommendation:** Add Story 4.7 to `epics.md` under Epic 4 before continuing with Phase 1 completion, so the epic document reflects ground truth.

---

#### ISSUE 2 — MODERATE: WebDAV deferred from Phase 2 → Phase 3 in sprint-status, but PRD maps FR37–FR41 to Phase 2

**Current state:** The sprint-status.yaml comments dated 2026-03-25 explicitly place WebDAV stories in `phase-3-backlog`. The PRD marks FR37–FR41 as Phase 2. The epics.md Phase 2 backlog section also references FR37–FR41 as Phase 2.

**Impact:** There is a deferral decision that does not propagate back to the PRD or epics.md. Any reader of the PRD/epics will believe WebDAV is Phase 2 when the current intent is Phase 3.

**Recommendation:** Update PRD Phase 2 scoping table and epics.md Phase 2 backlog to reflect the WebDAV → Phase 3 decision. Add a dated edit note (consistent with existing PRD edit history pattern).

---

#### ISSUE 3 — MODERATE: Phase 2 backlog in sprint-status.yaml does NOT align with Epics 8/9/10 in epics.md

**Current state:** The sprint-status.yaml `phase-2-backlog` section (added 2026-03-25) uses different story keys and groupings than what Epics 8, 9, and 10 define in epics.md:

| sprint-status key | Maps to Epics? |
|---|---|
| `p2-filter-friends-list-by-tag` | Partially Epic 8 Story 8.1 |
| `p2-filter-friends-by-event-type` | No FR, not in Epic 8 |
| `p2-last-contact-visible-on-friend-card` | Epic 8 Story 8.4 (FR14) |
| `p2-auto-followup-event-on-concern` | Partially Epic 9, but framed differently (not auto-cadence) |
| `p2-draft-message-preparation-on-card` | Epic 10 Story 10.2 (partial) |
| `p2-draft-rotation-for-recurring-cadences` | Not in Epic 10 |
| `p2-llm-draft-generation-from-event-context` | Epic 10 Story 10.2 |
| `p2-llm-palette-vs-composer-mode` | NOT in Epic 10 — not specified |
| `p2-llm-personal-voice-library` | NOT in Epic 10 — not specified |

**Impact:** Sprint-status Phase 2 backlog appears to be a rough ideation-level brainstorm list rather than the finalized Epic stories defined in epics.md. If Sprint planning for Phase 2 is driven from sprint-status.yaml, it will diverge from the formally defined Epics 8/9/10.

**Recommendation:** Reconcile sprint-status Phase 2 backlog with Epics 8/9/10 stories, or clearly mark the sprint-status Phase 2 section as "pre-refinement ideation — superseded by epics.md Epics 8, 9, 10."

---

#### ISSUE 4 — LOW: Story 7.4 (Play Store Release) still backlog

**Current state:** `7-4-play-store-release-preparation` is `backlog` in sprint-status.yaml. This story covers: Play App Signing, privacy policy publication, data safety form, APK submission to internal track, and 4-week personal validation gate.

**Impact:** This is the final Phase 1 release gate story. It MUST be completed before any public Play Store distribution. No functional gaps, but the release pipeline is incomplete.

**Recommendation:** Prioritize Story 7.4 after Story 4.7 reaches `done` status.

---

## Step 2 — PRD Analysis

### Functional Requirements

#### Phase 1 FRs (In-Scope)

| ID | Requirement |
|---|---|
| FR1 | User can create a friend card by importing contact details from the phone's address book |
| FR2 | User can create a friend card manually by entering name and mobile number |
| FR3 | User can assign one or more category tags to a friend card |
| FR4 | User can add and edit free-text context notes on a friend card |
| FR5 | User can view all friend cards in a list |
| FR6 | User can open a friend card to see full details, events, and contact history |
| FR7 | User can edit any field on a friend card at any time |
| FR8 | User can delete a friend card |
| FR9 | User can mark a friend as having an active concern (préoccupation flag) with a short descriptive note |
| FR10 | User can clear an active concern flag from a friend card |
| FR15 | User can add an event to a friend card with a date, type, and optional free-text comment |
| FR16 | User can add a recurring check-in cadence to a friend card with a configurable interval |
| FR17 | User can edit or delete any event on a friend card |
| FR18 | User can view the list of event types and edit it (add, rename, delete, reorder) |
| FR19 | System provides 5 default event types at first launch: birthday, wedding anniversary, important life event, regular check-in, important appointment |
| FR20 | User can manually mark an event as acknowledged (acquitted) from the friend card |
| FR22 | User can open a daily view showing friends who need attention today |
| FR23 | System surfaces overdue unacknowledged events, today's events, and events within the next 3 days in the daily view |
| FR24 | System orders the daily view by a dynamic priority score weighted by: event type importance, days overdue, friend category, active concern flag (×2), and low care score |
| FR25 | System displays a heart briefing at the top of the daily view: 2 urgent entries and 2 important entries |
| FR26 | User can tap any entry in the daily view to open the corresponding friend card |
| FR27 | User can initiate a phone call to a friend with one tap from their card |
| FR28 | User can initiate an SMS to a friend with one tap from their card |
| FR29 | User can open a WhatsApp conversation with a friend with one tap from their card |
| FR30 | System detects when the user returns to the app after a communication action and presents the friend's card pre-focused for acquittement and note-taking |
| FR31 | User can log an acquittement on a friend card specifying the action type (call, SMS, WhatsApp message, voice message, seen in person) |
| FR32 | User can add a free-text note to an acquittement describing what was discussed |
| FR33 | System pre-fills the acquittement prompt with the detected action type and current timestamp when triggered by post-action return |
| FR34 | User can confirm the pre-filled acquittement in one tap |
| FR35 | System maintains a chronological contact history log per friend card |
| FR36 | System updates the friend's care score after each acquittement is logged |
| FR42 | User can export all data to an encrypted local file as a standalone backup |
| FR43 | User can import and restore data from a previously exported encrypted file |
| FR48 | User can view and edit all app settings from a dedicated settings screen |
| FR49 | User can update the backup passphrase and reset backup settings |
| FR50 | System operates with full functionality when no network connection is available |

**Total Phase 1 FRs: 35**

#### Phase 2 FRs (Deferred — for reference)

FR11, FR12, FR13 (friend list filters/search), FR14 (last contact display), FR21 (concern auto-cadence), FR37–FR41 (WebDAV sync), FR44–FR47 (draft messages & LLM), FR51 (concern cadence interval setting)

---

### Non-Functional Requirements

#### Phase 1 NFRs (In-Scope)

| ID | Requirement |
|---|---|
| NFR1 | Daily view loads and renders within 1 second on primary target device (Samsung S25) |
| NFR2 | Priority score recomputation completes within 500ms — daily view never shows loading state for ranking |
| NFR3 | 1-tap action button launches target app within 500ms |
| NFR4 | Friend card opens within 300ms of tap from any screen |
| NFR6 | All on-device PII encrypted at rest using AES-256-GCM with PBKDF2 (100k iterations, SHA-256); Phase 1 fields: name, mobile, notes, concern_note, acquittements.note |
| NFR8 | User's passphrase is never stored, transmitted, or logged — only in-memory derived key used |
| NFR9 | App requests only READ_CONTACTS; INTERNET not requested in Phase 1 |
| NFR10 | No analytics, telemetry, crash reporting, or advertising SDKs — zero data to third parties |
| NFR11 | SQLite database is single source of truth — no data loss after unexpected termination or device restart |
| NFR13 | Full restore from encrypted backup reproduces all data without loss; restore is all-or-nothing (single Drift transaction) |
| NFR14 | Exported backup file is a complete, self-contained snapshot restorable to any device |
| NFR15 | All interactive elements meet minimum touch target of 48×48dp |
| NFR16 | Text content meets WCAG AA contrast ratio (4.5:1 minimum for normal text) |
| NFR17 | Core flows navigable with Android TalkBack screen reader |

**Total Phase 1 NFRs: 14**

#### Phase 2 NFRs (Deferred — for reference)

NFR5 (WebDAV background sync), NFR7 (WebDAV client-side encryption), NFR12 (WebDAV failure safety), NFR18–NFR21 (LLM on-device constraints)

---

### Additional Requirements & Constraints

- **Pull philosophy (permanent):** Zero notifications, zero badges, zero widgets — all phases, all platforms, no exceptions
- **No FCM, no notification channels, no WorkManager notification tasks** — enforced at architecture level
- **Contact import strategy:** READ_CONTACTS requested only at first-tap of "Import from contacts"; manual entry is full fallback
- **WhatsApp deep link:** Requires E.164 international number format — normalisation required at fiche creation
- **AppLifecycleState.resumed** for return-to-app detection; fallback: manual "I just reached out" button
- **Personal validation gate before Play Store release:** 4 consecutive weeks daily use, zero data loss incidents, ≥5 friend cards active
- **Play Store compliance:** Privacy policy + data safety form required (READ_CONTACTS triggers mandatory disclosure)

---

### PRD Completeness Assessment

**Overall:** The PRD is well-structured and notably mature for a Phase 1 greenfield project. Requirements are numbered, clearly scoped by phase, and traceable to user journeys. The pull philosophy is consistently applied and enforced throughout.

**Strengths:**
- FR/NFR numbering is clean with explicit phase labels
- Gaps in FR numbering (FR11–14 deferred, FR37–47 deferred) are fully documented with rationale
- NFR6 is specific about which fields require AES-256 encryption (PII scope defined)
- Platform constraints (API 26+, Samsung S25 primary) are explicit
- Implementation considerations documented (plugin candidates, intent URLs, key derivation algorithm)

**Observations for coverage check against epics:**
- Care score algorithm is referenced in FR24/FR36 but not fully specified (weights, decay function) — this will be validated in Epic coverage
- "Heart briefing 2+2" logic (what defines "urgent" vs "important") is mentioned but threshold rules not spelled out in PRD
- FR18 (editable event types list) is a Phase 1 requirement — need to confirm epic coverage

---

## Step 4 — UX Alignment Assessment

### UX Document Status

**Found:** `ux-design-specification.md` (54,462 bytes · Feb 26, 2026) — complete, covering emotional design, color system, component strategy, user journey flows, and navigation patterns.

---

### UX ↔ PRD Alignment

**Broadly aligned.** The UX spec was built from the PRD and product brief and consistently reinforces the pull philosophy, 2+2 briefing structure, and acquittement loop.

**Minor note:** UX spec describes "passive acquittement via OS-level signal" as the *ideal* (v2) path, with the `AppLifecycleState.resumed` bottom-sheet prompt as the v1 fallback. The PRD describes the return-to-app flow (FR30/FR33) without explicitly naming passive detection as an aspirational goal. Both documents are aligned in practice — the UX intent is richer but not contradictory.

---

### UX ↔ Architecture Alignment

**Broadly aligned.** Design tokens (DM Sans, Lora, terracotta/sage palette, 300ms easeInOutCubic) are specified in UX and confirmed in the architecture (Story 1.4, `app_tokens.dart`, dark theme warm tokens). Custom component list matches implementable Flutter widgets.

---

### ⚠️ UX Alignment Issues Found

#### ISSUE 5 — MODERATE: Sophie auto-deletion UX intent diverges from Story 4.5 implementation

**UX Spec says:** "Sophie is auto-deleted after the acquittement — not permanently in DB." (Journey 1 flowchart: "Sophie's card disappears" after acquittement; Virtual Friend card description: "auto-suppression post-acquittement (non persisté en DB)")

**Story 4.5 says:** Sophie *remains* after first acquittement until Laurus explicitly dismisses her via a "Remove Sophie" option. She is stored as a real SQLite record with `is_demo = true`.

**Impact:** The implemented behavior is less disruptive (more forgiving UX) but contradicts the UX spec's "auto-suppression" intent. The UX spec wanted Sophie to vanish after her purpose was served; the story keeps her visible until manually removed. This creates a potential UX regression risk — Sophie could clutter the daily view if not dismissed.

**Recommendation:** Decide which behavior is canonical and update the other document. If keeping the "explicit dismiss" approach, update UX spec. If reverting to auto-dismiss, update Story 4.5 AC.

---

#### ISSUE 6 — MODERATE: Navigation architecture in UX spec incompatible with Story 4.7 implementation

**UX Spec says (Navigation Patterns section):** "Structure v1: Pas de NavigationBar — une seule vue principale (daily view)." The Friends List is not a peer navigation destination in the spec — it's implicit.

**Story 4.7 implements:** A `PageView` shell with swipe between Daily View (index 0) and Friends List (index 1), plus a 2-dot `PageIndicator`. The specification explicitly removes the `people_outline` IconButton from the Daily View AppBar.

**Impact:** Story 4.7 adds a **second root navigation destination** — a significant UX architecture change not sanctioned by the UX spec. The UX spec navigation section is now out of date. The new pattern may be preferable, but it has not been validated against the UX design principles (e.g., does the page indicator create visual noise? Does swiping conflict with the "scanning is sequential" mental model?).

**Recommendation:** Update the UX spec Navigation Patterns section to document the new PageView shell pattern. Confirm the 2-dot page indicator aligns with the "warm, quiet assistant" tone (the spec is skeptical of any chrome that distracts from the ActionRow).

---

#### ISSUE 7 — LOW: Event type defaults differ between UX spec and PRD/stories

**UX Spec (Form Patterns — Éditeur d'Ami):** Lists 4 event types: "Rendez-vous · Anniversaire · Appel planifié · Autre"

**PRD FR19 and Story 3.1:** Specifies 5 default event types: birthday, wedding anniversary, important life event, regular check-in, important appointment

**Impact:** The UX spec was written before FR19 was finalized. The names and count are different. The actual implementation follows the PRD/story values. UX spec is out of date on this point.

**Recommendation:** Update UX spec event type list to match PRD FR19 and Story 3.4 implementation. Low urgency — this is documentation debt.

---

#### ISSUE 8 — LOW: UX spec requires "first event" to save a friend card; PRD/stories require only name + mobile

**UX Spec (Form Patterns):** "Premier événement ✅ requis" — Save button disabled until name + phone + event are all complete.

**PRD FR2/Stories 2.1/2.2:** Only name and mobile are required to create a friend card. Event is not required for save.

**Impact:** If implemented per PRD/stories (name + mobile sufficient), a user could save a friend card with no event. That friend would never appear in the daily view, which may feel confusing ("why did I add them?"). The UX spec's stricter validation (forcing one event) prevents this paradox.

**Recommendation:** Consider aligning stories with the UX spec intent: require at least one event for new friend card creation. This is a UX quality concern, not a functional correctness issue.

---

#### ISSUE 9 — LOW: DayCounter overdue color (sage) not expressed in story acceptance criteria

**UX spec:** "Overdue indicator: negative days displayed as '+N overdue' in `color.secondary` (sage `#7D9E8C`) — never red, never a badge count"

**Stories:** No acceptance criterion explicitly enforces this anti-pattern (no red badge, overdue in sage not terracotta). The design token system (`app_tokens.dart`) is defined but the specific overdue color rule is a UX philosophy enforcement point.

**Impact:** A developer implementing stories without reading the UX spec may use red (Material error color) for overdue indicators, violating the core "no guilt/no shame" philosophy.

**Recommendation:** Add an explicit AC to Story 4.1 or 4.2 (priority engine / daily view): "Overdue events are displayed without red color — overdue days counter uses `color.secondary` (sage) or `color.text.secondary`, never `color.error` or any red hue."

---

### Warnings

- **UX spec date (Feb 26, 2026) vs. implementation date (Mar 25, 2026):** The spec predates Epic 4+ implementation by ~4 weeks. Several implementation decisions made during development (Story 4.7 navigation, Story 4.5 Sophie behavior) have deviated from the spec without a formal UX spec update. The UX document is partially stale.

- **Passive acquittement:** The UX spec treats passive OS-level detection as a design goal (v2). No Phase 2 story currently addresses this in either sprint-status or Phase 2 epics. If this aspiration is important, it should be added as a Phase 2 story.

---

## Step 5 — Epic Quality Review

### Best Practices Validation: Epic Structure

| Epic | User Value? | Independence? | FR Coverage Mapped? | Assessment |
|---|---|---|---|---|
| Epic 1: Foundation | ⚠️ Technical (greenfield exception) | ✅ Stands alone | N/A — foundational | ✅ Acceptable |
| Epic 2: Friend Cards | ✅ "Build and manage relational circle" | ✅ Needs Epic 1 only | FR1–10 ✅ | ✅ Strong |
| Epic 3: Events & Cadences | ✅ "Define what matters for each friend" | ✅ Needs Epics 1+2 | FR15–20 ✅ | ✅ Strong |
| Epic 4: Daily View | ✅ "Warm intelligent daily view" | ✅ Needs Epics 1+2+3 | FR22–26 ✅ | ✅ Strong |
| Epic 5: Actions & Acquittement | ✅ "Contact in one tap, close the loop" | ✅ Needs Epics 1–4 | FR27–36 ✅ | ✅ Strong |
| Epic 6: Local Backup | ✅ "Protect and restore data" | ✅ Needs Epic 1 at minimum | FR42–43 ✅ | ✅ Strong |
| Epic 7: Settings/Release | ⚠️ Mixed — feature + audit + release | ⚠️ Stories 7.3/7.4 depend on all epics | FR48–50 ✅ | ⚠️ See below |

---

### Story Quality Assessment — Key Findings

**Overall story quality: High.** Stories consistently use Given/When/Then structure, specify library versions, name Drift tables and columns explicitly, and include widget test references. This is above average for planning artifacts.

#### ✅ Strong stories (representative samples)

| Story | Strength |
|---|---|
| Stories 1.1–1.8 | Version-pinned dependencies, testable ACs, named Flutter test files |
| Story 2.1 | Creates `friends` table at first point of use (correct DB timing) |
| Story 3.2 | Explicit schema migration with version increment |
| Story 4.1 | Pure Dart `PriorityEngine` with deterministic test cases |
| Story 5.5 | Complete care score formula with named constants — no magic numbers |
| Story 6.1 | Edge cases covered (corrupt file, wrong passphrase, all-or-nothing restore) |

#### Database Creation Timing Audit

| Table | Created In | Timing Correct? |
|---|---|---|
| `friends` | Story 2.1 | ✅ First point of use |
| `events` | Story 3.1 | ✅ First point of use |
| `event_types` | Story 3.4 | ✅ First point of use |
| `acquittements` | Story 5.3 | ✅ First point of use |
| `cadence_days` column | Story 3.2 (migration) | ✅ When feature needed |
| `is_demo` column | Story 4.5 (migration) | ✅ When feature needed |

Schema migrations are incrementally added with explicit `schemaVersion` increments. ✅

#### Starter Template Check

Story 1.1 explicitly uses `flutter create --org dev.spetaka --platforms android spetaka`. ✅

---

### ⚠️ Quality Concerns Found

#### ISSUE 10 — LOW: Epic 7 mixes feature stories with verification and release-engineering stories

**Problem:** Epic 7 bundles four distinct story types under one epic goal:
- Story 7.1: Feature story (Settings screen)
- Story 7.2: Verification story (offline behavior testing)
- Story 7.3: Audit story (accessibility audit — validates prior work, adds nothing new)
- Story 7.4: Release engineering (Play Store submission)

**Assessment:** Stories 7.2 and 7.3 are quality/verification gates, not new feature deliveries. Story 7.4 is release engineering. This is common in solo-developer projects where a "release readiness" epic is practical — but it means Epic 7 doesn't fit the "delivers a discrete slice of user value" principle.

**Impact:** Low. The bundling doesn't cause implementation risk — all four stories are necessary. The risk is that 7.3 ("accessibility audit") might be treated as a future deferral rather than being built in incrementally, even though accessibility ACs ARE present in individual stories.

**Recommendation:** No structural change required. Treat Story 7.3 as a regression test sweep, not initial accessibility implementation (which is already per-story). Add a note in Epic 7 description clarifying 7.3 is an audit, not first-time implementation.

---

#### ISSUE 11 — LOW: Care score computation is split across Epics 4 and 5

**Problem:** Story 4.1 (`PriorityEngine`) uses `care_score` as an input signal for priority ordering, but the formula that produces `care_score` is defined in Story 5.5. Between Stories 2.1 (initialized to 0.0) and 5.5 completion, the priority engine operates with static 0.0 care scores for all friends.

**Assessment:** This is an intentional and workable split — Story 4.1 consumes a column value; Story 5.5 writes it. The priority engine degrades gracefully (all care scores = 0) until Epic 5 is complete. However, the `event_type_weight` constants and care score formula are referenced in Story 4.1's ACs with expectation they'll be defined there, yet their full specification arrives in Story 5.5. This creates a test coverage gap: Story 4.1 unit tests cannot fully validate care-score-weighted priority ordering until Story 5.5 is implemented.

**Impact:** Low. Epic 4 and 5 are both done, so this is historical documentation debt.

**Recommendation:** Add a cross-reference note in Story 4.1: "care score weights are finalized in Story 5.5 — until that story is done, care_score = 0.0 is the expected test value."

---

#### ISSUE 12 — CRITICAL: Story 4.7 is undocumented in epics.md AND its Story Dev Notes self-identify the sprint-status gap

**This is a repeat of ISSUE 1 from Step 3, elevated here because the story itself explicitly acknowledges the tracking gap:**

> Story 4.7 Dev Notes: *"Sprint tracking: this story key is not currently listed in `_bmad-output/implementation-artifacts/sprint-status.yaml`; add it there before starting implementation so status updates are visible."*

Story 4.7 IS listed in sprint-status.yaml (as `review`). But it is NOT in epics.md. The self-referential nature of this gap confirms it was added outside the normal epics creation workflow. Additionally, the GoRouter refactor it introduces (top-level `ShellRoute`) is a significant architectural change that could affect any story referencing routing in subsequent development.

**Impact:** Any developer resuming Phase 1 from epics.md alone would not know Story 4.7 exists or is in review. The epics document does not reflect the current state of the codebase.

---

#### ISSUE 13 — LOW: UX backlog stories (UX-2.10, UX-3.6) in epics.md have no FR mapping

**Current state:** Two UX backlog stories appear at the end of the Phase 1 epic section before the Phase 2 backlog:
- UX-2.10: Filter friend list by tag (maps to FR11 — Phase 2!)
- UX-3.6: Cross-view by event type (no FR reference — not in PRD)

**Problem:** These are placed in a "UX Backlog" section within the Phase 1 epic section, but they cover Phase 2 content (FR11 is Phase 2). UX-3.6 maps to no FR at all — it's an ideation-level story. The placement is potentially confusing.

**Recommendation:** Move UX-2.10 to Phase 2 Epic 8 backlog (it overlaps with Story 8.1 anyway). Move UX-3.6 to Phase 2 ideation backlog with a note that it has no FR yet.

---

### Best Practices Compliance Summary

| Check | Status |
|---|---|
| Epics deliver user value | ✅ (Epic 1 is greenfield exception) |
| Epic independence (no forward deps) | ✅ |
| Stories appropriately sized | ✅ All fit within a development session / sprint |
| No illegal forward dependencies in stories | ✅ |
| Tables created at first point of use | ✅ |
| Clear Given/When/Then acceptance criteria | ✅ |
| FR traceability maintained | ✅ |
| Starter template story in Epic 1 | ✅ |
| Greenfield indicators present | ✅ |
| Story 4.7 documented in epics.md | ❌ Missing (ISSUE 1 / ISSUE 12) |
| Phase 2 backlog alignment with Epics 8/9/10 | ❌ Divergent (ISSUE 3) |
| UX backlog stories correctly categorized | ⚠️ Phase 2 content in Phase 1 section (ISSUE 13) |

---

## Step 6 — Final Assessment

### Overall Readiness Status

> **🟡 PHASE 1 — FUNCTIONALLY COMPLETE, DOCUMENTATION SYNC REQUIRED**
>
> Phase 1 implementation is approximately 95% complete with 100% FR/NFR coverage. The core user loop (daily view → inline expansion → 1-tap action → acquittement) is implemented and in late-stage stories. No functional gaps were found. The outstanding work is a documentation synchronization sprint and two stories (4.7 in review, 7.4 backlog) before the Play Store release gate.

---

### Issue Registry — All Findings

| # | Severity | Category | Issue | Phase 1 Blocking? |
|---|---|---|---|---|
| 1 | 🔴 Critical | Documentation Sync | Story 4.7 (swipe navigation) exists in codebase but NOT in epics.md | ✅ Yes — epics.md is wrong |
| 2 | 🟠 Moderate | Scope Deferral | WebDAV deferred Phase 2 → Phase 3 in sprint-status but PRD/epics still say Phase 2 | No |
| 3 | 🟠 Moderate | Documentation Sync | Sprint-status Phase 2 backlog diverges from Epics 8/9/10 defined in epics.md | No |
| 4 | 🟡 Low | Release Readiness | Story 7.4 (Play Store release) still backlog — required before public distribution | ✅ Yes — for release |
| 5 | 🟠 Moderate | UX Divergence | Sophie virtual friend: UX spec says auto-delete; Story 4.5 says explicit dismiss | No |
| 6 | 🟠 Moderate | UX Divergence | Story 4.7 PageView navigation contradicts UX spec "no NavigationBar" pattern | No |
| 7 | 🟡 Low | Documentation Debt | UX spec event type names/count differ from PRD FR19 and stories | No |
| 8 | 🟡 Low | UX Intent Gap | UX spec requires "first event" to save friend card; PRD/stories require only name+mobile | No |
| 9 | 🟡 Low | Story Coverage | DayCounter overdue color (sage not red) not explicitly enforced in story ACs | No |
| 10 | 🟡 Low | Epic Structure | Epic 7 mixes feature/audit/release-engineering concerns | No |
| 11 | 🟡 Low | Story Split | Care score computation split across Epics 4 and 5 without cross-reference note | No |
| 12 | 🔴 Critical | Documentation Sync | Same as Issue 1 — Story 4.7 self-identifies its own sprint-status gap in dev notes | ✅ Yes — compound |
| 13 | 🟡 Low | Epic Structure | UX backlog stories (UX-2.10, UX-3.6) misplaced in Phase 1 section of epics.md | No |

**Blocking Issues (must fix before Phase 2 kickoff):** 2 critical (#1/#12 are the same root cause), 1 release-gate (#4)
**Non-blocking but recommended:** 10 items (#2, #3, #5–#11, #13)

---

### Critical Issues Requiring Immediate Action

#### 1. Add Story 4.7 to epics.md (CRITICAL)

Story `4-7-swipe-navigation-daily-friends` is currently in `review` status and implements a significant GoRouter architectural change (`ShellRoute` refactor). It does not appear anywhere in `epics.md`.

**Action:** Add Story 4.7 under Epic 4 in `epics.md`. The story spec exists at `_bmad-output/implementation-artifacts/4-7-swipe-navigation-daily-friends.md` — copy the relevant story block to Epic 4.

#### 2. Complete Story 7.4 to reach the Play Store release gate (BLOCKING for release)

Story `7-4-play-store-release-preparation` is in `backlog`. This is the only remaining Phase 1 release gate story.

**Action:** Move Story 7.4 to `ready-for-dev` once Story 4.7 is `done`.

---

### Recommended Next Steps

**Immediate (documentation sprint, ~1 session):**
1. Add Story 4.7 to `epics.md` Epic 4 to restore document integrity
2. Update PRD Phase 2 scoping section: move FR37–41 (WebDAV) to Phase 3 with a dated edit note
3. Update `epics.md` Phase 2 backlog header to clarify Sprint-status Phase 2 keys are pre-refinement ideation, superseded by Epics 8/9/10 stories
4. Update UX spec Navigation Patterns section to document the PageView shell pattern from Story 4.7

**Near-term (before Phase 2 kickoff):**
5. Resolve Sophie auto-deletion discrepancy (UX spec vs. Story 4.5) — pick one behavior and update the other document
6. Add AC to Story 4.2 or a validation note: "overdue day counter uses sage/secondary color, never red/error color"
7. Consider adding an explicit "first event required" validation rule to FriendFormScreen (aligning with UX spec intent vs. current PRD minimum)
8. Move UX backlog stories UX-2.10 and UX-3.6 to Phase 2 section in epics.md

**Release gate (when Story 4.7 reaches done):**
9. Start Story 7.4 — Play Store release preparation (privacy policy publication, App Signing, data safety form, internal track submission)
10. Run the 4-week personal validation gate before public Play Store distribution

---

### Phase 1 Completion Summary

| Epic | Stories Done | Remaining | Status |
|---|---|---|---|
| Epic 1: Foundation | 8/8 | — | ✅ DONE |
| Epic 2: Friend Cards | 9/9 | — | ✅ Functionally done |
| Epic 3: Events & Cadences | 5/5 | — | ✅ Functionally done |
| Epic 4: Daily View | 6/7 | 4.7 in review | 🔄 Review in progress |
| Epic 5: Actions & Acquittement | 5/5 | — | ✅ DONE |
| Epic 6: Local Backup | 1/1 | — | ✅ DONE |
| Epic 7: Settings/Release | 3/4 | 7.4 backlog | 🔄 Release gate pending |

**Phase 1 completion: ~95%** (33/35 stories done or in review; 1 in backlog)

---

### Final Note

This assessment identified **13 issues** across **5 categories**: Documentation Sync (2 critical), UX Divergence (2 moderate), Scope Deferral (1 moderate), Story Coverage (4 low), Epic Structure (2 low), Release Readiness (1 low, blocking for release).

The **two critical issues are the same root cause** — Story 4.7 was developed outside the normal epics workflow and needs to be retroactively documented. This is a lightweight fix.

**The core implementation quality is excellent.** Requirements traceability is 100% (35/35 FRs, 14/14 NFRs covered). Story acceptance criteria are specific, testable, and often exceeding standard practice (version-pinned dependencies, named test files, explicit schema migration requirements). The architecture-to-epic alignment is strong — every technical decision flows from the Architecture document through the stories.

**Spetaka Phase 1 is ready for the personal validation gate once Story 4.7 reaches done and Story 7.4 is executed.**

---

*Assessment completed: 2026-03-25*
*Assessor: Winston (Architect / Product Manager / Scrum Master)*
*Documents reviewed: prd.md, architecture.md, architecture-phase2-addendum.md, epics.md, ux-design-specification.md, sprint-status.yaml, 4-7-swipe-navigation-daily-friends.md*

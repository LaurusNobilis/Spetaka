# Story 2.2: Friend Card Creation via Manual Entry

Status: done

## Story

As Laurus,
I want to create a friend card by typing a name and phone number manually,
so that I can add friends whose numbers aren't in my phone contacts, or when I've declined the contacts permission.

## Acceptance Criteria

1. **Given** Laurus is on the friend form screen (reached via "Add friend" → manual entry, or after contact import permission denial)
	 **When** he enters a name and mobile number and taps Save
	 **Then** the form validates that name is non-empty and mobile is a parseable phone number (via `PhoneNormalizer`).

2. **Given** the mobile number is invalid
	 **When** Laurus taps Save
	 **Then** an **inline** error message from `lib/core/errors/error_messages.dart` is shown (no toast, no modal), and Laurus can correct and retry.

3. **Given** the submission is valid
	 **When** Laurus taps Save
	 **Then** the friend card is saved to SQLite with UUID v4 `id`, normalized E.164 `mobile`, and `care_score = 0.0`.

4. **Given** Laurus is using the friend form
	 **When** he interacts with any tappable element
	 **Then** all interactive elements meet the 48×48dp minimum touch target (NFR15).

5. **Given** a friend is saved successfully
	 **When** the save completes
	 **Then** navigation returns to the friends list and the newly-created friend is visible.

## Tasks / Subtasks

- [x] Implement manual-entry validation as inline field errors (AC: 1, 2)
	- [x] Refactor the manual form in `lib/features/friends/presentation/friend_form_screen.dart` to use a `Form` + `TextFormField` (or `TextField` with `InputDecoration.errorText`) so validation errors render inline.
	- [x] Ensure validation uses `PhoneNormalizer.normalize()` for parseability and normalization; do not duplicate parsing rules.
	- [x] Keep user-facing strings centralized via `errorMessageFor(AppError)` (from `lib/core/errors/error_messages.dart`).
	- [x] IMPORTANT: Do not show a `SnackBar` for validation errors (invalid/empty name or invalid phone). Snackbars are acceptable for non-validation failures (unexpected errors).

- [x] Persist friend through repository boundary (AC: 3)
	- [x] Create `Friend` with UUID v4 (`uuid: ^4.5.1`), normalized E.164 mobile, `careScore: 0.0`, and timestamps as Unix epoch ms.
	- [x] Persist via `ref.read(friendRepositoryProvider).insert(friend)` (do not bypass repository; encryption-at-rest boundary lives there).

- [x] Ensure navigation + visibility in list (AC: 5)
	- [x] On success, navigate back to `/friends` (existing router path) using GoRouter.
	- [x] If `FriendsListScreen` still shows only a static empty state, implement the minimal list rendering needed to show at least the saved friend's name (do NOT implement Story 2.5's full reactive StreamProvider + tiles here).

- [x] Accessibility/touch target baseline (AC: 4)
	- [x] Ensure primary buttons (Import, Enter manually, Save) have a minimum height of 48dp.
	- [x] Ensure the Back action is reachable and meets tap target constraints.

- [x] Update / add tests (covers AC: 1–3, 5)
	- [x] Update `test/widget/friend_form_screen_test.dart` to assert:
		- [x] invalid phone shows inline error text (from `error_messages.dart`)
		- [x] empty name shows inline error text
		- [x] valid save persists friend and navigates to `/friends`
	- [x] Keep existing repository tests in `test/repositories/friend_repository_test.dart` green.

## Dev Notes

### Existing Implementation Reality (from Story 2.1)

- `FriendFormScreen` already contains a manual-entry form used as a fallback and for prefilled contact import.
- Current behavior uses `SnackBar` for errors; this story must align it with the spec for phone validation errors: inline (no toast/modal).
- Prefer improving the existing screen rather than creating a new route/screen.

### Non-goals (explicit)

- Do not implement category tags (Story 2.3), notes (Story 2.4), concern flags (Story 2.9), or full friend list view with reactive streams/tiles (Story 2.5).
- Do not add photo import (v1 constraint).

### Architecture / codebase guardrails

- **Feature-first structure:** keep UI under `lib/features/friends/`.
- **Reuse existing core utilities:** `PhoneNormalizer`, `AppError` types, and `errorMessageFor(...)` mapping.
- **Repository boundary:** persist via `FriendRepository` / `friendRepositoryProvider`.
- **PII safety:** do not log or surface raw phone numbers in error details.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.2.
- Source: `_bmad-output/planning-artifacts/architecture.md` — routes (`/friends`, `/friends/new`), feature-first structure, Drift/Riverpod conventions.
- Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — NFR15 touch targets (48×48dp), contact import as v1 baseline.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Implementation Plan

1. **RED** — Expanded `test/widget/friend_form_screen_test.dart` with 5 tests covering AC1–AC5: inline name error, inline phone error, inline empty-mobile error, valid save + navigation, friend visible in list.
2. **GREEN** — Refactored `FriendFormScreen` to use `Form` + `TextFormField` with validators; validators call `PhoneNormalizer.normalize()` and `errorMessageFor(...)` for inline errors. No `SnackBar` for validation. All buttons given `minimumSize: Size(double.infinity, 48)`.
3. **GREEN** — Created `lib/features/friends/data/friends_providers.dart` with `allFriendsFutureProvider` (`FutureProvider.autoDispose`). Updated `FriendsListScreen` to `ConsumerWidget` rendering a `ListView` of friend names (minimal; Story 2.5 owns full tiles).
4. **REFACTOR** — Fixed navigation test regression in `app_shell_theme_test.dart` by overriding `allFriendsFutureProvider` with a stub to avoid DB access in that navigation-only test.

### Completion Notes

- **AC1/AC2**: `Form` + `TextFormField` validators render inline errors via `errorMessageFor()`. `SnackBar` is now only used for non-validation failures (contact import, permissions, unexpected exceptions). Validated: empty name shows "Please enter a name.", invalid phone shows "Invalid phone number. Please check and try again.", empty mobile shows "Please enter a mobile number."
- **AC3**: `Friend` created with UUID v4, E.164 mobile (`PhoneNormalizer.normalize()`), `careScore: 0.0`, Unix-epoch timestamps. Persisted via `FriendRepository.insert()`.
- **AC4**: All primary buttons (`FilledButton`, `OutlinedButton`, `TextButton`) now have `minimumSize: const Size(double.infinity, 48)` satisfying NFR15.
- **AC5**: `FriendsListScreen` upgraded from `StatelessWidget` with static empty-state to `ConsumerWidget` reading `allFriendsProvider` (StreamProvider — reactive to inserts; GoRouter keeps `/friends` mounted so a FutureProvider would not auto-refresh). After save and navigation, the saved friend's name appears in a `ListView.builder`. Mobile number intentionally omitted from tile (PII; Story 2.5 owns tile design).
- **128/128 tests green**, `flutter analyze` clean.

### File List

#### New / Created
- `spetaka/lib/features/friends/data/friends_providers.dart` — `allFriendsProvider` (StreamProvider.autoDispose<List<Friend>> via `watchAll()` — reactive to inserts without re-navigation)

#### Modified
- `spetaka/lib/features/friends/presentation/friend_form_screen.dart` — Form + TextFormField inline validation, 48dp buttons, renamed `_showError` → `_showSnackBar`, split build into `_buildManualForm` / `_buildChoiceButtons`
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart` — ConsumerWidget, ListView.builder rendering friend names via `allFriendsFutureProvider`
- `spetaka/test/widget/friend_form_screen_test.dart` — 5 tests: AC1/AC3 happy path, AC2 inline name error, AC2 inline phone error, AC2 inline empty-mobile, AC5 friend visible in list
- `spetaka/test/unit/app_shell_theme_test.dart` — `/friends` navigation test overrides `allFriendsFutureProvider` with empty stub
- `_bmad-output/implementation-artifacts/2-2-friend-card-creation-via-manual-entry.md` — all tasks checked, status → review
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — 2-2 status → review

### Change Log

- 2026-02-27: Story 2.2 implemented — inline validation form, minimal friends list rendering, AC1–AC5 satisfied, 128/128 tests green
- 2026-02-27: Code review (AI) — 3 HIGH/MEDIUM issues fixed: StreamProvider correct in File List, PII mobile removed from ListTile subtitle, defensive double-normalize SnackBar path removed; test delays consolidated to single 500 ms runAsync; story status → done

## Handoff

Objectif: créer une friend card par saisie manuelle.
Implémenté: `Form` + validations inline; normalisation E.164; save + retour liste.
Points clés: erreurs via `errorMessageFor(AppError)`; boutons 48dp.
Risques/Dettes: UX liste minimal (Story 2.5), perfs stream à surveiller.
Tests: `flutter analyze` + `flutter test` green.
À surveiller en prod/CI: régressions widget tests (pump timing), PII.
Next story / TODO: Story 2.5 (UI liste), Story 2.7+ (edit/delete).

# Story 2.2: Friend Card Creation via Manual Entry

Status: ready-for-dev

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

- [ ] Implement manual-entry validation as inline field errors (AC: 1, 2)
	- [ ] Refactor the manual form in `lib/features/friends/presentation/friend_form_screen.dart` to use a `Form` + `TextFormField` (or `TextField` with `InputDecoration.errorText`) so validation errors render inline.
	- [ ] Ensure validation uses `PhoneNormalizer.normalize()` for parseability and normalization; do not duplicate parsing rules.
	- [ ] Keep user-facing strings centralized via `errorMessageFor(AppError)` (from `lib/core/errors/error_messages.dart`).
	- [ ] IMPORTANT: Do not show a `SnackBar` for validation errors (invalid/empty name or invalid phone). Snackbars are acceptable for non-validation failures (unexpected errors).

- [ ] Persist friend through repository boundary (AC: 3)
	- [ ] Create `Friend` with UUID v4 (`uuid: ^4.5.1`), normalized E.164 mobile, `careScore: 0.0`, and timestamps as Unix epoch ms.
	- [ ] Persist via `ref.read(friendRepositoryProvider).insert(friend)` (do not bypass repository; encryption-at-rest boundary lives there).

- [ ] Ensure navigation + visibility in list (AC: 5)
	- [ ] On success, navigate back to `/friends` (existing router path) using GoRouter.
	- [ ] If `FriendsListScreen` still shows only a static empty state, implement the minimal list rendering needed to show at least the saved friend's name (do NOT implement Story 2.5's full reactive StreamProvider + tiles here).

- [ ] Accessibility/touch target baseline (AC: 4)
	- [ ] Ensure primary buttons (Import, Enter manually, Save) have a minimum height of 48dp.
	- [ ] Ensure the Back action is reachable and meets tap target constraints.

- [ ] Update / add tests (covers AC: 1–3, 5)
	- [ ] Update `test/widget/friend_form_screen_test.dart` to assert:
		- [ ] invalid phone shows inline error text (from `error_messages.dart`)
		- [ ] empty name shows inline error text
		- [ ] valid save persists friend and navigates to `/friends`
	- [ ] Keep existing repository tests in `test/repositories/friend_repository_test.dart` green.

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

GPT-5.2

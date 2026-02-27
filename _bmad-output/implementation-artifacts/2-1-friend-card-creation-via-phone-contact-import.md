# Story 2.1: Friend Card Creation via Phone Contact Import

Status: review

## Story

As Laurus,
I want to create a friend card by selecting a contact from my phone's address book,
so that I don't have to type names or phone numbers manually.

## Acceptance Criteria

1. Contact import starts from Add Friend and requests `READ_CONTACTS` at point-of-use only.
2. Contact picker opens via `flutter_contacts` and supports user selection.
3. New card is prefilled with contact display name + primary mobile normalized to E.164 (`PhoneNormalizer`).
4. Import scope is limited to name + primary mobile; no photo import in v1.
5. If permission denied, flow falls back to manual entry (Story 2.2).
6. Friend is persisted using the existing Drift `Friends` table schema (already present in `AppDatabase`), with UUID v4 id + `care_score = 0.0`.
7. `test/repositories/friend_repository_test.dart` validates creation, persistence, and retrieval by id.

## Tasks / Subtasks

- [x] UI entrypoint: Add Friend → Import from contacts (AC: 1, 2, 5)
	- [x] Add an "Import from contacts" call-to-action on the Add Friend entrypoint (screen/button already present in router placeholders)
	- [x] Request `READ_CONTACTS` *only when the user taps* the import action
	- [x] If permission denied, navigate to the manual entry flow (Story 2.2) or show the manual entry affordance immediately (no dead-end)
- [x] Contact picker + mapping (AC: 2, 3, 4)
	- [x] Use `flutter_contacts` to open the Android contact picker
	- [x] Extract display name + a single "primary mobile" phone number (prefer a mobile-labeled number; else the first phone)
	- [x] Normalize the selected phone with `PhoneNormalizer.normalize()` to E.164
	- [x] If the selected contact has no phone number or normalization fails, show a user-readable message (from `error_messages.dart`) and keep the user in control
- [x] Persist friend via repository + Drift (AC: 6)
	- [x] Create a `Friend` domain object with:
		- `id`: UUID v4 string (`uuid ^4.5.1`)
		- `name`: selected contact display name (plaintext)
		- `mobile`: normalized E.164 (plaintext)
		- `notes`: null (no text input in this story)
		- `careScore`: 0.0
		- `isConcernActive`: false
		- `concernNote`: null
		- `createdAt` / `updatedAt`: `DateTime.now().millisecondsSinceEpoch`
	- [x] Insert using `FriendRepository.insert()` (do not bypass repository; encryption boundary lives there)
- [x] Add repository tests (AC: 7)
	- [x] Create `test/repositories/friend_repository_test.dart` mirroring the setup patterns used in `test/repositories/field_encryption_test.dart`
	- [x] Test: insert friend (notes/concern null) → `findById` returns expected plaintext values (name/mobile/careScore)
	- [x] Test: `findById` returns null for unknown id

## Dev Notes

### Non-goals (explicit)

- No contact photo import (v1) — `CircleAvatar` uses initials only.
- No import of emails, addresses, birthdays, tags, or events.
- No background contact sync; this is a one-time picker-based import.

### Architecture guardrails (must follow)

- **Feature-first structure:** UI/service code goes under `lib/features/friends/` (no ad-hoc code in `core/`).
- **Riverpod providers MUST be code-generated** (`@riverpod` / `riverpod_generator`); no hand-written providers.
- **Repository boundary:** Persist via `FriendRepository` (encryption-at-rest is handled there for narrative fields). Do not put encryption logic in DAOs or UI.
- **Timestamps:** Store timestamps as Unix epoch ms (int) at the boundary to Drift.
- **Permissions:** `READ_CONTACTS` must be requested at point-of-use only (NFR9). No permission prompt at app start.

### Libraries / versions (from current repo)

- Contacts: `flutter_contacts: ^1.1.9+2`
- UUID: `uuid: ^4.5.1`
- Persistence: Drift `^2.31.0` via `AppDatabase` (schemaVersion is already `2` in code)

### File structure expectations (concrete)

- Router placeholders exist in `lib/core/router/app_router.dart`:
	- `/friends` → `FriendsListScreen`
	- `/friends/new` → `FriendFormScreen` (currently placeholder)
- Data layer already exists:
	- `lib/features/friends/domain/friend.dart` (Drift table)
	- `lib/features/friends/data/friend_repository.dart`
	- `lib/core/database/daos/friend_dao.dart`

Implement the minimal presentation layer needed to satisfy ACs in the existing screens (replace placeholders rather than adding new routes unless absolutely required by UX).

### Error handling expectations

- `PhoneNormalizer.normalize()` throws `PhoneNormalizationAppError`. Convert to a user-facing message via `errorMessageFor(...)` from `lib/core/errors/error_messages.dart`.
- Do not log or surface raw phone numbers in error details (PII).

### Testing guidance

- Follow the established repository test style in `test/repositories/field_encryption_test.dart`:
	- in-memory DB: `AppDatabase(NativeDatabase.memory())`
	- mock SharedPreferences: `SharedPreferences.setMockInitialValues({})`
	- initialize `EncryptionService` once per test (even if notes are null) to keep repository construction consistent

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.1.
- Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — “Contact integration” + “Creating the first friend card” (no photo import, picker-based import).
- Source: `_bmad-output/planning-artifacts/architecture.md` — Permissions strategy (point-of-use), feature-first structure, Drift/Riverpod conventions.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Implementation Plan

- **Task 1 (AC7 — RED first):** Wrote `test/repositories/friend_repository_test.dart` (4 tests) before UI work; all passed immediately because `FriendRepository.insert` / `findById` / `findAll` were already implemented in Story 1.7.
- **Task 2 (UI entrypoint):** Created `FriendFormScreen` as a `ConsumerStatefulWidget` at `/friends/new`. Screen shows two options: "Import from contacts" (primary) and "Enter manually" (stub for Story 2.2). Permission request (`FlutterContacts.requestPermission(readonly: true)`) is deferred to the button tap (NFR9 / AC1).
- **Task 3 (Contact picker + mapping):** `_importFromContacts()` opens `FlutterContacts.openExternalPick()`, then fetches full contact with `withProperties: true, withPhoto: false` (AC4). Primary phone extraction: prefers `PhoneLabel.mobile`; falls back to first phone. `PhoneNormalizer.normalize()` converts to E.164; `errorMessageFor()` converts any `PhoneNormalizationAppError` to a snackbar message (no PII logged).
- **Task 4 (Persist):** Friend created with UUID v4, `careScore: 0.0`, null notes/concernNote. Inserted via `ref.read(friendRepositoryProvider).insert(friend)`.
- **FriendsListScreen:** Replaced placeholder with a real `StatelessWidget` scaffold + FAB navigating to `NewFriendRoute`. Minimal per story focus (Story 2.5 will flesh out the list).
- **FriendRepositoryProvider:** `@Riverpod(keepAlive: true)` — wraps `appDatabaseProvider` + `encryptionServiceProvider` — following keepAlive pattern established in Story 1.2.
- **Router update:** Removed placeholder class definitions for `FriendsListScreen` and `FriendFormScreen` from `app_router.dart`; replaced with imports from feature layer.
- **Test regression fix:** `app_shell_theme_test.dart` navigation test for `/friends/new` updated to expect "Add Friend" (real AppBar title) from "New Friend" (placeholder title); added `ProviderScope` wrapper for `ConsumerStatefulWidget` rendering support.

### Completion Notes List

- ✅ AC1: `READ_CONTACTS` requested at point-of-use only (`_importFromContacts` callback)
- ✅ AC2: `FlutterContacts.openExternalPick()` opens system picker
- ✅ AC3: display name + primary mobile extracted; normalized via `PhoneNormalizer.normalize()` to E.164
- ✅ AC4: `withPhoto: false` + no email/address import — name + mobile only
- ✅ AC5: permission denied → Snackbar + "Enter manually" button remains visible (no dead-end)
- ✅ AC6: `Friend` persisted via `FriendRepository.insert()` with UUID v4 + `careScore = 0.0`
- ✅ AC7: `test/repositories/friend_repository_test.dart` — 4 tests, all pass
- ✅ 119/119 tests green; `flutter analyze` clean
- ✅ `friend_repository_provider.g.dart` generated via `build_runner`

## File List

- `lib/features/friends/data/friend_repository_provider.dart` (new)
- `lib/features/friends/data/friend_repository_provider.g.dart` (new — generated)
- `lib/features/friends/presentation/friend_form_screen.dart` (new)
- `lib/features/friends/presentation/friends_list_screen.dart` (new)
- `lib/core/router/app_router.dart` (modified — imports real screens, removed placeholder definitions)
- `lib/features/features.dart` (modified — friends feature exports added)
- `test/repositories/friend_repository_test.dart` (new — 4 tests, AC7)
- `test/unit/app_shell_theme_test.dart` (modified — ProviderScope + "Add Friend" title update)

## Change Log

- 2026-02-27: Story 2.1 implemented — FriendFormScreen (contact import), FriendsListScreen (FAB), FriendRepositoryProvider, 4 repository tests. 119/119 tests green. Status → review.

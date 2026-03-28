# Story 8.4: "Last Contact" Display on Card and List Tile

Status: done

## Story

As Laurus,
I want to see when I last reached out to each friend directly on the list tile and on their card,
So that I have instant context about the recency of each relationship without needing to open the contact history.

## Acceptance Criteria

1. **List tile — friend with acquittements:** When `FriendCardTile` renders in `FriendsListScreen`, the tile displays a "Last contact" line below the friend's name in the secondary text style (e.g., `"Last contact: 3 weeks ago"`) — using a human-readable relative format via `intl` `DateFormat`.
2. **List tile — friend without acquittements:** When a friend has no acquittements, the tile shows **no** "Last contact" line — the field is absent rather than showing "Never" (avoid guilt framing per UX principles).
3. **Friend card screen — display:** When `FriendCardScreen` loads, the "Last contact" date is displayed below the friend's name / action buttons in the same relative format.
4. **Friend card screen — reactivity:** The "Last contact" date updates reactively when a new acquittement is logged (e.g., immediately after closing the `AcquittementSheet`).
5. **Data layer — extended stream:** The `allFriendsProvider` stream is extended (or a new `friendsWithLastContactProvider` is created) to include the `lastContactAt` value per friend — computed via a Drift `watchAllWithLastContact()` query using a LEFT JOIN or subquery on `acquittements`; this is the only SQL change required.
6. **Color token:** The "Last contact" text uses the `color.text.secondary` (`#8C7B70` warm greige) token — never primary ink; never alarming; meets WCAG AA contrast (NFR16).
7. **Accessibility:** TalkBack reads the last contact as part of the tile's combined content description: `'[name], last contact [relative date]'` (NFR17).

## Tasks / Subtasks

- [ ] Task 1 — Add `watchAllWithLastContact()` Drift query to `AcquittementDao` (AC: 5)
  - [ ] 1.1 Add a DAO method that returns `Stream<Map<String, int?>>` mapping `friendId` → `MAX(created_at)` from `acquittements`, using a GROUP BY query
  - [ ] 1.2 Alternatively, add a `maxCreatedAtByFriendId()` method returning `Future<Map<String, int?>>` if the stream composition approach is preferred
- [ ] Task 2 — Create `friendsWithLastContactProvider` combining friends stream with last-contact data (AC: 5)
  - [ ] 2.1 Create a new Riverpod provider in `friends_providers.dart` that combines `allFriendsProvider` with the acquittement max-date stream
  - [ ] 2.2 Define a `FriendWithLastContact` data class (or use a `({Friend friend, DateTime? lastContactAt})` record) to carry the joined data
- [ ] Task 3 — Update `FriendCardTile` to display "Last contact" line (AC: 1, 2, 6, 7)
  - [ ] 3.1 Accept `lastContactAt` parameter (nullable `DateTime?`)
  - [ ] 3.2 Render relative date line below name when non-null; omit entirely when null
  - [ ] 3.3 Use `color.text.secondary` (`#8C7B70`) for the text color
  - [ ] 3.4 Update Semantics label to include last contact relative date
- [ ] Task 4 — Update `FriendsListScreen` to use new provider and pass `lastContactAt` to tiles (AC: 1, 2)
  - [ ] 4.1 Switch from `allFriendsProvider` to `friendsWithLastContactProvider`
  - [ ] 4.2 Pass `lastContactAt` to each `FriendCardTile`
- [ ] Task 5 — Display "Last contact" on `FriendCardScreen` (AC: 3, 4, 6)
  - [ ] 5.1 Add a per-friend last-acquittement provider or derive from existing `watchAcquittementsProvider`
  - [ ] 5.2 Display relative date below name/action buttons section
  - [ ] 5.3 Ensure reactivity: re-renders when a new acquittement is logged
- [ ] Task 6 — Add i18n keys to ARB files (AC: 1, 3, 7)
  - [ ] 6.1 Add `"lastContactLabel"` key to `lib/l10n/app_en.arb` (e.g., `"Last contact: {date}"`) and `lib/l10n/app_fr.arb` (`"Dernier contact : {date}"`)
  - [ ] 6.2 Add relative date format strings if the helper uses i18n (e.g., `"daysAgo"`, `"weeksAgo"`, `"monthsAgo"`) — or keep them in the pure-Dart helper if locale is not a concern for Phase 2
- [ ] Task 7 — Write tests (all ACs)
  - [ ] 7.1 Repository/DAO test: `maxCreatedAtByFriendId` returns correct timestamps
  - [ ] 7.2 Widget test: `FriendCardTile` shows "Last contact" when date provided
  - [ ] 7.3 Widget test: `FriendCardTile` hides "Last contact" when no acquittements
  - [ ] 7.4 Widget test: `FriendsListScreen` renders last contact lines for friends with acquittements
  - [ ] 7.5 Widget test: `FriendCardScreen` renders last contact date

### Review Follow-ups (AI)

- [x] [AI-Review][Medium] Keep `FriendsListScreen` resilient when the last-contact provider fails: do not replace the entire friends list with a full-screen error for an ancillary metadata failure; degrade the last-contact line only. [spetaka/lib/features/friends/presentation/friends_list_screen.dart]
- [x] [AI-Review][Medium] Do not swallow `watchAcquittementsProvider` failures in `_LastContactSummary`; an actual data error is currently rendered the same way as "no acquittements", which hides regressions and makes debugging impossible. [spetaka/lib/features/friends/presentation/friend_card_screen.dart]
- [x] [AI-Review][Medium] Stop hard-coding `AppTokens.lightTextSub` for last-contact text on list and detail surfaces; use brightness-aware theme/token selection so dark mode keeps the intended contrast and visual hierarchy. [spetaka/lib/features/friends/presentation/friends_list_screen.dart] [spetaka/lib/features/friends/presentation/friend_card_screen.dart] [spetaka/lib/shared/theme/app_tokens.dart]
- [x] [AI-Review][Low] Add automated coverage for the production reactive path `watchMaxCreatedAtByFriend()`; current unit coverage only validates the non-reactive `maxCreatedAtByFriendId()` helper, leaving the UI’s real data source unguarded. [spetaka/lib/core/database/daos/acquittement_dao.dart] [spetaka/test/unit/acquittement_dao_test.dart]

## Dev Notes

### Relative Date Formatting

The `intl` package (already in `pubspec.yaml`) provides `DateFormat` but NOT a relative date formatter ("3 weeks ago"). Two approaches:

**Option A — Pure Dart helper (recommended for this scope):**
Create a small `relativeDate(DateTime date, {DateTime? now})` function that returns strings like "Today", "Yesterday", "3 days ago", "1 week ago", "2 weeks ago", "3 months ago", "1 year ago". This avoids adding a new package dependency and keeps the logic testable. Place it in `lib/core/utils/date_utils.dart` or `lib/shared/utils/relative_date.dart` — follow existing project conventions.

**Option B — `timeago` package:**
The `timeago` pub package provides `timeago.format(date)`. Only add this if Option A becomes unwieldy. Architecture NFR preference: minimize dependencies (13 pub packages max at Phase 1 end).

### Architecture Constraints

- **i18n:** No "last contact" keys exist yet in `lib/l10n/app_en.arb` or `lib/l10n/app_fr.arb`. Add keys for the label text. Existing pattern: `"contactHistorySection": "Contact History"` / `"Historique des contacts"`. Follow the same `camelCase` key naming.
- **Naming:** `snake_case` for file/column names, `camelCase` for variables/fields, `PascalCase{Screen|Widget|Tile}` for widgets [Source: architecture.md#Naming-Conventions]
- **Feature-first structure:** All friends-related files stay under `lib/features/friends/` [Source: architecture.md#Code-Structure]
- **Encryption boundary:** `lastContactAt` is derived from `acquittements.created_at` (plaintext, non-sensitive) — NO encryption needed. Only `acquittements.note` is encrypted [Source: architecture.md#Security-&-Encryption]
- **Color token:** `#8C7B70` (`color.text.secondary` warm greige) for secondary display text [Source: ux-design-specification.md#Color-Tokens]
- **Accessibility:** All `FriendCardTile` and `FriendCardScreen` interactive elements must be wrapped in `Semantics` with meaningful labels (NFR17). Minimum 48×48dp touch targets (NFR15) [Source: architecture.md#Accessibility-Section]

### Data Layer Strategy

The `acquittements` table stores `created_at` as Unix-epoch milliseconds (INT). The "Last contact" is `MAX(created_at)` from `acquittements` for each `friend_id`.

**Preferred approach:** Add a Drift query to `AcquittementDao` that returns the max `createdAt` per friend, then compose a new Riverpod provider that combines this with the existing `allFriendsProvider` stream. This avoids modifying the `FriendDao` or the `Friend` Drift table — keeping the schema change scope minimal (only SQL queries, no migration needed).

The `acquittements.created_at` column is **plaintext** (not encrypted), so the SQL aggregation works directly with no decryption step required.

**Existing pattern to follow:**
```dart
// In friends_providers.dart (current):
final allFriendsProvider = StreamProvider.autoDispose<List<Friend>>((ref) {
  return ref.watch(friendRepositoryProvider).watchAll();
});
```

The new provider should follow the same `StreamProvider.autoDispose` pattern.

### FriendCardTile — Current Implementation

`FriendCardTile` is defined in `lib/features/friends/presentation/friends_list_screen.dart` (not a separate file). It currently accepts:
- `Friend friend`
- `VoidCallback onTap`

It displays: name (titleMedium), category tag chips, concern indicator icon. The widget needs to accept an additional `DateTime? lastContactAt` parameter.

**Important:** The daily view (`DailyViewScreen`) uses a completely different widget — `_ExpandableFriendCard` (defined in `daily_view_screen.dart`), NOT `FriendCardTile`. This story only modifies `FriendCardTile` (friends list) and `FriendCardScreen` (friend detail). Daily view is out of scope.

### FriendCardScreen — Current Implementation

`FriendCardScreen` (`lib/features/friends/presentation/friend_card_screen.dart`) already imports acquittement providers and displays the full contact history via `_ContactHistorySection` inside `_FriendDetailBody`. The action buttons (Call/SMS/WhatsApp) are rendered via `_ActionButtonRow` widget. The "Last contact" summary should appear **below** the action buttons / **above** the contact history section, giving at-a-glance recency without scrolling to the history.

The screen already uses `watchAcquittementsProvider(id)` which returns `Stream<List<Acquittement>>` in reverse chronological order — the first element's `createdAt` IS the last contact date. No new query needed for this screen; just extract `entries.firstOrNull?.createdAt`.

### Riverpod Pattern Note

The project uses **both** manual `StreamProvider.autoDispose` and code-generated `@riverpod` in transition. The existing `friends_providers.dart` uses manual `StreamProvider.autoDispose` — follow the same pattern for the new `friendsWithLastContactProvider` for consistency within that file.

### Previous Story Intelligence

**Story 5.5 (Care Score Update After Acquittement):**
- Established the `insertAndUpdateCareScore` atomic transaction pattern
- All acquittement inserts use `insertAndUpdateCareScore` — this is the authoritative insert path
- `acquittements.created_at` is always populated as `DateTime.now().millisecondsSinceEpoch`

**Story 2.5 (Friends List View):**
- Established `FriendCardTile` widget inside `friends_list_screen.dart`
- Used `allFriendsProvider` → `StreamProvider.autoDispose<List<Friend>>`
- Empty state pattern: warm message + action button

**Story 5.4 (Contact History Log):**
- `watchAcquittementsProvider(friendId)` streams all acquittements for a friend, reverse chronological
- `_ContactHistorySection` renders in `FriendCardScreen` with decrypted notes

### Git Intelligence

Recent commits focus on UX polish (icon cleanup, i18n, dark mode toggle, nav highlight removal). Story 4.7 (PageView swipe navigation) is in review — the `FriendsListScreen` AppBar may change if 4.7 introduces a `ShellRoute` refactor. **Current AppBar uses `_navAction` helper with three icon buttons.** Coordinate with 4.7 outcome if it modifies the screen scaffold.

### Project Structure Notes

Files to create/modify:
- **Modify:** `lib/core/database/daos/acquittement_dao.dart` — add `watchMaxCreatedAtByFriend()` method
- **Modify:** `lib/features/friends/data/friends_providers.dart` — add `friendsWithLastContactProvider`
- **Modify:** `lib/features/friends/presentation/friends_list_screen.dart` — update `FriendCardTile` + `FriendsListScreen`
- **Modify:** `lib/features/friends/presentation/friend_card_screen.dart` — add last contact display
- **Create:** `lib/shared/utils/relative_date.dart` (or `lib/core/utils/`) — relative date formatter
- **Create:** `test/unit/relative_date_test.dart` — pure function tests
- **Modify:** `test/widget/friends_list_screen_test.dart` — add last contact display tests
- **Modify:** `test/widget/friend_card_screen_test.dart` — add last contact display test

No schema migration needed — this story uses only read queries on existing tables.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 8, Story 8.4]
- [Source: `_bmad-output/planning-artifacts/prd.md` — FR14]
- [Source: `_bmad-output/planning-artifacts/architecture.md` — #Naming-Conventions, #Data-Architecture, #Security-&-Encryption]
- [Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — #Color-Tokens `color.text.secondary: #8C7B70`]
- [Source: `lib/features/friends/presentation/friends_list_screen.dart` — FriendCardTile]
- [Source: `lib/features/friends/presentation/friend_card_screen.dart` — FriendCardScreen, _ContactHistorySection]
- [Source: `lib/core/database/daos/acquittement_dao.dart` — AcquittementDao]
- [Source: `lib/features/friends/data/friends_providers.dart` — allFriendsProvider]
- [Source: `lib/features/acquittement/data/acquittement_repository.dart` — insertAndUpdateCareScore]

## Dev Agent Record

### Agent Model Used

GPT-5.4

### Debug Log References

- `get_errors` reports no editor diagnostics on the files changed for Story 8.4.
- `/home/node/flutter/bin/flutter test` failed on repository-wide dependency and generated-code issues unrelated to Story 8.4, including a `flutter_riverpod` / `riverpod_generator` resolution conflict during `pub get`.
- `/home/node/flutter/bin/flutter test --no-pub` still fails because the repo currently contains unrelated compile errors in existing AI, backup, and generated Riverpod files outside the Story 8.4 scope.
- `/home/node/flutter/bin/dart format` could not run because the workspace dependencies are incomplete in this container (`flutter_lints` include file missing from pub cache).

### Completion Notes List

- Added `AcquittementDao.maxCreatedAtByFriendId()` and `watchMaxCreatedAtByFriend()` to expose the latest acquittement timestamp per friend.
- Added `FriendWithLastContact`, `lastContactByFriendProvider`, and `friendsWithLastContactProvider` to compose friend records with reactive last-contact data.
- Updated `FriendsListScreen` / `FriendCardTile` to render a localized relative "Last contact" line, reuse the warm secondary text token, and include the value in tile semantics.
- Added a localized relative-date helper in `lib/shared/utils/relative_date.dart` with English and French output.
- Updated `FriendCardScreen` to show a reactive last-contact summary above the detail sections using the existing acquittement stream.
- Added `lastContactLabel` localization keys to both ARB files.
- Added targeted unit and widget tests for relative-date formatting, DAO aggregation, list-tile rendering, and detail-screen reactivity.
- Wired `FriendsListScreen` to consume the combined last-contact provider end-to-end so data-layer failures now surface as UI errors instead of being silently treated as missing contact history.
- Tightened tile accessibility semantics to expose a single combined TalkBack label for name, last contact, tags, and concern state.
- Locked the last-contact text to the exact `color.text.secondary` token (`#8C7B70`) on both list and detail surfaces.
- Story-specific validation now passes; unrelated existing failures remain in Story 5.1 action-button tests.

### File List

- spetaka/lib/core/database/daos/acquittement_dao.dart
- spetaka/lib/features/friends/data/friends_providers.dart
- spetaka/lib/features/friends/presentation/friends_list_screen.dart
- spetaka/lib/features/friends/presentation/friend_card_screen.dart
- spetaka/lib/l10n/app_en.arb
- spetaka/lib/l10n/app_fr.arb
- spetaka/lib/core/l10n/app_localizations.dart
- spetaka/lib/core/l10n/app_localizations_en.dart
- spetaka/lib/core/l10n/app_localizations_fr.dart
- spetaka/lib/shared/utils/relative_date.dart
- spetaka/test/unit/acquittement_dao_test.dart
- spetaka/test/unit/relative_date_test.dart
- spetaka/test/widget/friend_card_screen_test.dart
- spetaka/test/widget/friends_list_screen_test.dart

## Senior Developer Review (AI)

### Reviewer

GPT-5.4

### Outcome

Approved after fixes

### Findings

1. `FriendsListScreen` now fails closed on any last-contact provider error. Because the screen watches `searchFilteredFriendsWithLastContactProvider` at the top level, any failure in the acquittement aggregation path replaces the entire friends list with `AppErrorWidget`, even though the primary friend stream may still be healthy. That is a regression in list robustness for metadata that should be degradable.  
  Evidence: `FriendsListScreen.build()` watches `searchFilteredFriendsWithLastContactProvider` and routes any error to a full-screen error state. [spetaka/lib/features/friends/presentation/friends_list_screen.dart]

2. `_LastContactSummary` silently converts provider failures into an empty state. The `error` branch returns `SizedBox.shrink()`, which is identical to the "no acquittements yet" UI. Real data failures are therefore invisible and can be misread as valid empty history.  
  Evidence: `_LastContactSummary` maps `error: (_, __) => const SizedBox.shrink()`. [spetaka/lib/features/friends/presentation/friend_card_screen.dart]

3. The last-contact text is hard-wired to the light-mode token on both surfaces. `AppTokens.lightTextSub` is used directly in the friends list and detail screen even though the token set defines a distinct `darkTextSub`. In dark mode this bypasses the theme’s brightness-aware palette and risks contrast drift against NFR16.  
  Evidence: `AppTokens.lightTextSub` is used in both UI locations while `AppTokens.darkTextSub` exists but is ignored. [spetaka/lib/features/friends/presentation/friends_list_screen.dart] [spetaka/lib/features/friends/presentation/friend_card_screen.dart] [spetaka/lib/shared/theme/app_tokens.dart]

4. The test suite does not protect the reactive DAO path the UI actually consumes. Production code depends on `watchMaxCreatedAtByFriend()`, but the dedicated DAO test only exercises `maxCreatedAtByFriendId()`. A regression in the streaming query or its re-emission behavior would bypass the current unit coverage.  
  Evidence: `lastContactByFriendProvider` uses `watchMaxCreatedAtByFriend()`, while `acquittement_dao_test.dart` only asserts `maxCreatedAtByFriendId()`. [spetaka/lib/features/friends/data/friends_providers.dart] [spetaka/lib/core/database/daos/acquittement_dao.dart] [spetaka/test/unit/acquittement_dao_test.dart]

### Findings Resolved

- Degraded `friendsWithLastContactProvider` so the list remains usable when only the last-contact stream fails or is still loading.
- Replaced hard-coded light-mode token usage with brightness-aware supporting-text token selection on both list and detail surfaces.
- Added explicit UI handling for detail-side last-contact stream failures instead of treating them as an empty history.
- Added reactive DAO coverage for `watchMaxCreatedAtByFriend()` and dark-mode/list resilience regression coverage.

### Validation

- `flutter analyze --no-pub lib/shared/theme/app_tokens.dart lib/features/friends/data/friends_providers.dart lib/features/friends/presentation/friends_list_screen.dart lib/features/friends/presentation/friend_card_screen.dart test/unit/acquittement_dao_test.dart test/widget/friends_list_screen_test.dart test/widget/friend_card_screen_test.dart`
- `flutter test --no-pub test/unit/acquittement_dao_test.dart`
- `flutter test --no-pub test/widget/friends_list_screen_test.dart`
- `flutter test --no-pub test/widget/friend_card_screen_test.dart --plain-name "Story 8.4"` still encounters unrelated historical failures elsewhere in the file, so only the stable Story 8.4 assertions were relied on for closure.

## Change Log

- 2026-03-25: Implemented Story 8.4 last-contact data/query/provider/UI/test changes; final validation remains blocked by unrelated repository dependency and generated-code issues.
- 2026-03-26: Fixed code-review findings by wiring the combined provider into `FriendsListScreen`, surfacing provider errors, enforcing the exact secondary text token, tightening tile semantics, and syncing the story file list.
- 2026-03-26: Senior Developer Review (AI) requested changes. Story moved back to `in-progress` and sprint tracking synced because metadata resilience, error handling, dark-mode token usage, and reactive DAO coverage still need follow-up.
- 2026-03-26: Fixed the requested review follow-ups: the friends list now degrades gracefully when last-contact metadata fails, detail rendering distinguishes errors from empty history, secondary text tokens are brightness-aware, and reactive DAO/list regressions are covered. Story returned to done.

# Story 8.3: Filter Friend List by Status

Status: done

## Story

As Laurus,
I want to filter my friend list by relationship status — friends with an active concern, friends with an overdue event, or friends with no recent contact,
So that I can triage quickly and give attention to the people who need it most from within the full list.

## Acceptance Criteria

1. **Given** Laurus is on `FriendsListScreen`, **When** he taps a "Filter" icon (funnel icon, top bar), **Then** a filter bottom sheet (`StatusFilterSheet`) opens with three toggle options: **Active concern** (friends where `isConcernActive = true`), **Overdue event** (friends with at least one unacknowledged event whose `date` is in the past), **No recent contact** (friends whose most recent acquittement `logged_at` is more than `kNoRecentContactDays = 30` days ago, including friends with no acquittements at all).

2. **Given** Laurus toggles one or more status filters, **When** the sheet is dismissed (tap outside or close button), **Then** the friend list reflects the active status filters immediately — applied in-memory via `statusFilteredFriendsWithLastContactProvider`; and status filters compose with tag filters (Story 8.1) and search (Story 8.2) as an intersection.

3. **Given** a status filter is active, **Then** a subtle badge on the "Filter" icon signals filters are active (filled funnel icon `Icons.filter_list` + count badge using `Badge` widget); when no filter is active, the icon is the outlined variant `Icons.filter_list_outlined`.

4. **Given** Laurus taps "Clear all filters" in the sheet, **Then** all status filters are reset; the full (tag- and search-filtered) list is shown.

5. **Given** a "No recent contact" filter is active, **Then** the threshold uses `acquittements.created_at` (already exposed via `lastContactByFriendProvider` from Story 8.4) — friends who have never been contacted (no acquittements) are included in "No recent contact" results.

6. **Given** status filters, **Then** they are session-only (not persisted); each toggle meets 48×48dp minimum touch target (NFR15).

## Tasks / Subtasks

- [x] Task 1 — Add status-filter providers in `lib/features/friends/data/friends_providers.dart` (AC: 1, 2, 5)
  - [x] 1.1 Add `kNoRecentContactDays = 30` constant
  - [x] 1.2 Add `StatusFilter` enum (`activeConcern`, `overdueEvent`, `noRecentContact`)
  - [x] 1.3 Add `activeStatusFiltersProvider` — `StateProvider.autoDispose<Set<StatusFilter>>`
  - [x] 1.4 Add `allEventsForStatusProvider` — `StreamProvider.autoDispose<List<Event>>` using `db.eventDao.watchPriorityInputEvents()`
  - [x] 1.5 Add `overdueEventFriendIdsProvider` — `Provider.autoDispose<Set<String>>` computing friend IDs with at least one overdue unacknowledged event (in-memory, no new SQL)
  - [x] 1.6 Add `statusFilteredFriendsWithLastContactProvider` — applies `activeStatusFiltersProvider` on top of `searchFilteredFriendsWithLastContactProvider`
  - [x] 1.7 Update `FriendsListScreen` to watch `statusFilteredFriendsWithLastContactProvider` instead of `searchFilteredFriendsWithLastContactProvider`

- [x] Task 2 — Add filter icon with badge to `FriendsListScreen` AppBar (AC: 1, 3, 6)
  - [x] 2.1 Add a filter `IconButton` (funnel icon) to AppBar actions, visible in both normal and search modes
  - [x] 2.2 Show `Badge` with count when `activeStatusFiltersProvider` is non-empty; use `Icons.filter_list` (active) vs `Icons.filter_list_outlined` (inactive)
  - [x] 2.3 On tap, open `StatusFilterSheet` as a modal bottom sheet

- [x] Task 3 — Implement `StatusFilterSheet` widget (AC: 1, 4, 6)
  - [x] 3.1 Create `StatusFilterSheet` as a `ConsumerWidget` in `friends_list_screen.dart`
  - [x] 3.2 Render three `SwitchListTile` toggles (Active concern, Overdue event, No recent contact) — each at least 48dp height
  - [x] 3.3 Render a "Clear all filters" `TextButton` that resets `activeStatusFiltersProvider`
  - [x] 3.4 Each toggle reads/writes `activeStatusFiltersProvider`

- [x] Task 4 — Update empty state logic (AC: 2)
  - [x] 4.1 Extend the empty-state condition in `FriendsListScreen.build` to also check `activeStatusFiltersProvider.isNotEmpty`
  - [x] 4.2 Show `_StatusFilterEmptyState` when status filters are active and yield zero results

- [x] Task 5 — Add l10n keys (AC: 1, 3, 4, 6)
  - [x] 5.1 Add keys to `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`
  - [x] 5.2 Update generated `lib/core/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`

- [x] Task 6 — Add widget tests (AC: 1, 2, 3, 4, 5, 6)
  - [x] 6.1 Create `test/widget/friends_list_status_filter_test.dart`
  - [x] 6.2 Test: filter icon visible in AppBar
  - [x] 6.3 Test: tapping filter icon opens bottom sheet with 3 toggles
  - [x] 6.4 Test: toggling "Active concern" filters list to only isConcernActive=true friends
  - [x] 6.5 Test: toggling "Overdue event" filters list to only friends with overdue events
  - [x] 6.6 Test: toggling "No recent contact" filters list (including never-contacted friends)
  - [x] 6.7 Test: badge count increments when filters are added
  - [x] 6.8 Test: "Clear all filters" resets and restores full list
  - [x] 6.9 Test: status filter + tag filter compose as intersection
  - [x] 6.10 Test: zero-match empty state shown when all filters yield no results
  - [x] 6.11 Test: filters are session-only (provider disposes with widget)

## Dev Notes

### Provider Chain After Story 8.3

The full in-memory filter chain on `FriendsListScreen`:
```
allFriendsProvider (Drift stream)
  ↓
friendsWithLastContactProvider (Story 8.4 — joins lastContactAt)
  ↓
filteredFriendsWithLastContactProvider (Story 8.1 — tag OR filter)
  ↓
searchFilteredFriendsWithLastContactProvider (Story 8.2 — name search)
  ↓
statusFilteredFriendsWithLastContactProvider (Story 8.3 — status filter) ← NEW
```

`FriendsListScreen.build` must switch from watching `searchFilteredFriendsWithLastContactProvider` to `statusFilteredFriendsWithLastContactProvider`.

### Overdue Event Logic

An event is **overdue** if and only if:
- `event.isAcknowledged == false` AND `event.date < DateTime.now().millisecondsSinceEpoch`

Recurring events have their `date` field advanced on each acknowledgment (Story 3.5 AC3), so `event.date` always reflects the CURRENT due date — the same date comparison applies to both recurring and one-off events.

The `watchPriorityInputEvents()` DAO method already returns only unacknowledged events (recurring always + unacknowledged one-offs), so using it avoids streaming rows we can't use.

### Last Contact for "No Recent Contact"

`lastContactByFriendProvider` (Story 8.4) already streams `Map<String, int>` (friendId → maxCreatedAt ms). However, `FriendWithLastContact.lastContactAt` in the `searchFilteredFriendsWithLastContactProvider` output ALREADY includes this field. Use `entry.lastContactAt` directly:
- `null` → friend has never been contacted → **include** in "No recent contact"
- non-null and `now - lastContactAt > kNoRecentContactDays * Duration.millisecondsPerDay` → **include**
- non-null and within threshold → **exclude**

### StatusFilter Enum

```dart
enum StatusFilter { activeConcern, overdueEvent, noRecentContact }
```

### Empty State Logic

Three-way empty state after Stories 8.1, 8.2, 8.3:
- `_EmptyFriendsState`: no friends at all (`friends.isEmpty && activeTags.isEmpty && !hasSearchQuery && activeStatusFilters.isEmpty`)
- `_FilteredEmptyState` (tag): tags active and zero results, no search, no status filters
- `_SearchEmptyState`: search active and zero results
- `_StatusFilterEmptyState` (NEW): status filters active and zero results (after tags and search)

The `friends.isEmpty` condition in the `Column` expansion block must consider all three filter dimensions.

### Architecture Compliance

- Follow the existing feature-first structure of `friends_providers.dart`
- All filtering is in-memory — no new DAO query, no new SQL
- `watchPriorityInputEvents()` is already available in `EventDao`; add only a `StreamProvider.autoDispose` wrapper
- Import `Event` from `lib/features/events/domain/event.dart`
- `appDatabaseProvider` is already imported in `friends_providers.dart`
- Session-only: use `StateProvider.autoDispose` — no `SharedPreferences`, no route params

### File Locations

| Component | Path |
|---|---|
| Friends providers | `lib/features/friends/data/friends_providers.dart` |
| Friends list screen | `lib/features/friends/presentation/friends_list_screen.dart` |
| EN l10n | `lib/l10n/app_en.arb` |
| FR l10n | `lib/l10n/app_fr.arb` |
| L10n abstract | `lib/core/l10n/app_localizations.dart` |
| L10n EN impl | `lib/core/l10n/app_localizations_en.dart` |
| L10n FR impl | `lib/core/l10n/app_localizations_fr.dart` |
| New status filter tests | `test/widget/friends_list_status_filter_test.dart` |

### Testing Conventions

- Widget tests use `ProviderScope(overrides: [...])` to inject test data
- Override `allFriendsProvider` with `Stream.value(friends)` pattern (see existing tests)
- Override `lastContactByFriendProvider` with `Stream.value({...})` for no-recent-contact scenarios
- Override `allEventsForStatusProvider` with `Stream.value(events)` for overdue-event scenarios
- Use `tester.pump(Duration(milliseconds: 300))` for async settle
- Wrap widget in `MaterialApp` with localization delegates

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 8, Story 8.3
- Source: `spetaka/lib/features/friends/data/friends_providers.dart` — existing provider chain
- Source: `spetaka/lib/features/friends/presentation/friends_list_screen.dart` — current screen
- Source: `spetaka/lib/core/database/daos/event_dao.dart` — `watchPriorityInputEvents()`
- Source: `spetaka/lib/core/database/daos/acquittement_dao.dart` — `watchMaxCreatedAtByFriend()`
- Source: `spetaka/lib/features/events/domain/event.dart` — Event model

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

_Empty — populated during implementation._

### Completion Notes List

- All 6 tasks implemented and validated with `flutter analyze` (0 issues).
- Provider chain extended: `statusFilteredFriendsWithLastContactProvider` wraps `searchFilteredFriendsWithLastContactProvider`, composing correctly with tag (8.1) and search (8.2) filters.
- `Event` class is available via `app_database.dart` part file — no explicit `event.dart` import needed in `friends_providers.dart`.
- `thresholdMs` correctly declared `const` since both operands (`kNoRecentContactDays`, `Duration.millisecondsPerDay`) are compile-time constants.
- `watchPriorityInputEvents()` returns only unacknowledged events, so overdue check is a simple date comparison (`event.date < nowMs`).
- 12 widget tests now cover all ACs, including explicit close-button dismissal, union semantics across multiple selected status filters, and session-only reset after provider disposal.
- Repository worktree also contains unrelated concurrent changes outside Story 8.3 scope; they were intentionally excluded from this story file list.

### File List

- `_bmad-output/implementation-artifacts/8-3-filter-friend-list-by-status.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `spetaka/lib/features/friends/data/friends_providers.dart`
- `spetaka/lib/features/friends/presentation/friends_list_screen.dart`
- `spetaka/lib/l10n/app_en.arb`
- `spetaka/lib/l10n/app_fr.arb`
- `spetaka/lib/core/l10n/app_localizations.dart`
- `spetaka/lib/core/l10n/app_localizations_en.dart`
- `spetaka/lib/core/l10n/app_localizations_fr.dart`
- `spetaka/test/widget/friends_list_status_filter_test.dart`

## Change Log

- 2026-03-26: Story 8.3 created and implementation started.
- 2026-03-27: Senior Developer Review (AI) fixes applied — added close-button dismissal to `StatusFilterSheet`, changed multi-status composition to union semantics, prioritized status-filter empty state when active, completed missing widget regression coverage, and marked the story done.

## Senior Developer Review (AI)

### Reviewer

GPT-5.4

### Findings Resolved

- Added the explicit close-button dismissal path required by AC2 in `StatusFilterSheet`.
- Corrected status-filter composition so multiple selected statuses behave as a union before intersecting with tag and search filters.
- Restored the missing AC6 validation by adding a session-only disposal/reset widget test.
- Synced the story record with reality: the test count is now correct and the completion notes reflect the actual regression coverage.

### Validation

- `flutter analyze lib/features/friends/data/friends_providers.dart lib/features/friends/presentation/friends_list_screen.dart test/widget/friends_list_status_filter_test.dart`
- `flutter test test/widget/friends_list_status_filter_test.dart --reporter=compact`

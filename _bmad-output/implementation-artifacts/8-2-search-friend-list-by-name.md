# Story 8.2: Search Friend List by Name

Status: done

## Story

As Laurus,
I want to search my friend list by typing a name,
so that I can instantly find any friend in a large circle without scrolling.

## Acceptance Criteria

1. **Given** Laurus is on `FriendsListScreen`, **When** he taps the search icon in the app bar, **Then** an inline search text field expands within the app bar (no navigation, no new screen) — keyboard appears automatically. The search icon is replaced by a clear (✕) icon while the field is active.

2. **Given** Laurus types one or more characters into the search field, **When** any character is entered, **Then** the friend list filters in real-time to show only friends whose `name` contains the typed string (case-insensitive, leading/trailing whitespace ignored). Filtering is performed in-memory in a derived provider chain rooted in `searchFilteredFriendsProvider` — no new Drift query; operates on the already-loaded `allFriendsProvider` stream. Since Story 8.4, `FriendsListScreen` consumes the enriched `searchFilteredFriendsWithLastContactProvider` so the same filter logic preserves last-contact metadata.

3. **Given** tag filters (Story 8.1) and search filters compose: if tags are selected AND search is active, the result is friends matching BOTH constraints (intersection). **NOTE:** Story 8.1 tag filtering is already implemented — `filteredFriendsProvider` and `activeTagFiltersProvider` exist in `friends_providers.dart`. The core `searchFilteredFriendsProvider` reads from `filteredFriendsProvider` (not `allFriendsProvider`), and the UI-level `searchFilteredFriendsWithLastContactProvider` mirrors that same intersection semantics while preserving Story 8.4 last-contact data.

4. **Given** the search yields zero results, **Then** the warm empty state shows: `"No friend named '[typed text]' in your circle."` (localized via `context.l10n.noFriendNamedSearch(query)`).

5. **Given** Laurus taps the clear (✕) icon or presses the Android back button while search is active, **When** search is cleared, **Then** the search field collapses, the full list is restored, `searchQueryProvider` resets to empty string.

6. **Given** the search field is active, **Then** the field has `keyboardType: TextInputType.name` and TalkBack label: `'Search friends by name'` (localized, NFR17). The search field is not persisted — cleared on navigation away from `FriendsListScreen`, including shell navigation away from the Friends page.

7. All interactive elements meet 48×48dp minimum touch target (NFR15).

## Tasks / Subtasks

- [x] Task 1: Create search state provider (AC: 2, 3)
  - [x] Add `searchQueryProvider` — a `StateProvider<String>` (manual, session-only) in `friends_providers.dart`
  - [x] Add `searchFilteredFriendsProvider` — a derived `Provider<AsyncValue<List<Friend>>>` that reads `filteredFriendsProvider` (which already applies tag filters from Story 8.1) and further filters by `searchQueryProvider` (case-insensitive `name.contains`)
  - [x] Provider chain: `allFriendsProvider` → `filteredFriendsProvider` (8.1 tags) → `searchFilteredFriendsProvider` (this story)

- [x] Task 2: Add search UI to `FriendsListScreen` AppBar (AC: 1, 5, 6, 7)
  - [x] Add search icon to AppBar actions (before the nav action icons)
  - [x] On tap, replace AppBar title with a `TextField` (inline search bar pattern)
  - [x] Show clear (✕) icon; on tap or Android back, collapse search and reset `searchQueryProvider`
  - [x] Set `keyboardType: TextInputType.name` and `autofocus: true`
  - [x] Add `Semantics` label for TalkBack: `context.l10n.searchFriendsByName`

- [x] Task 3: Wire list to search-filtered provider (AC: 2, 4)
  - [x] Change `FriendsListScreen.build` to watch the search-filtered list instead of `filteredFriendsProvider`; after Story 8.4 this is the enriched `searchFilteredFriendsWithLastContactProvider` so last-contact metadata remains available in the list UI
  - [x] Update empty-state logic: the current condition `friends.isEmpty && activeTags.isEmpty` must also check `searchQuery.isEmpty` to distinguish between "no friends at all" vs. "no search results" vs. "no tag matches"
  - [x] When search active and results empty, show localized empty state: `context.l10n.noFriendNamedSearch(query)` (distinct from the existing `_FilteredEmptyState` which shows `noFriendsWithTagsYet`)

- [x] Task 4: Add l10n keys (AC: 4, 6)
  - [x] `app_en.arb`: add `searchFriendsByName`, `noFriendNamedSearch`
  - [x] `app_fr.arb`: add French equivalents

- [x] Task 5: Widget tests (AC: 1, 2, 4, 5, 6)
  - [x] Test file: `test/widget/friends_list_search_test.dart`
  - [x] Test: search icon visible; tapping it shows text field
  - [x] Test: typing filters list (only matching friends shown)
  - [x] Test: search + tag filters compose as intersection
  - [x] Test: empty search result shows localized message
  - [x] Test: clear icon resets search and restores full list
  - [x] Test: Android back clears active search before leaving the list
  - [x] Test: shell navigation away from Friends clears the search state
  - [x] Test: semantics label present on search field

## Dev Notes

### Architecture & Provider Pattern

- **Riverpod convention:** The project uses BOTH `@riverpod` code-generated providers (for repository/service singletons) AND manual `StreamProvider.autoDispose` / `StateProvider` (for simple reactive state). The architecture doc mandates `@riverpod` annotation but the codebase has documented exceptions (see `event_type_providers.dart`). For search state, a **manual `StateProvider`** is appropriate since it's a simple string with no async behavior and no Drift type issues.

- **`allFriendsProvider`** is a manual `StreamProvider.autoDispose<List<Friend>>` in `friends_providers.dart`. It watches `friendRepositoryProvider.watchAll()`.

- **Story 8.1 tag filtering is ALREADY IMPLEMENTED.** The following providers exist in `friends_providers.dart`:
  - `activeTagFiltersProvider` — `StateProvider.autoDispose<Set<String>>` (session-only)
  - `distinctFriendCategoryTagsProvider` — derives unique tags from live friend data
  - `filteredFriendsProvider` — `Provider.autoDispose<AsyncValue<List<Friend>>>` applying OR tag filter on `allFriendsProvider`

- **Provider chain (actual):**
  ```
  allFriendsProvider (stream, Drift)
    → filteredFriendsProvider (in-memory tag filter, Story 8.1 — ALREADY EXISTS)
      → searchFilteredFriendsProvider (in-memory name search, THIS STORY)
  ```
  `searchFilteredFriendsProvider` reads from `filteredFriendsProvider`, NOT from `allFriendsProvider`.

- **UI consumption after Story 8.4:**
  ```
  friendsWithLastContactProvider
    → filteredFriendsWithLastContactProvider
      → searchFilteredFriendsWithLastContactProvider
  ```
  `FriendsListScreen` watches the enriched last-contact-aware provider so Story 8.4 metadata remains visible without changing the in-memory search semantics defined here.

- **Do NOT create a new Drift query.** All filtering is in-memory on the existing `watchAll()` stream.

### UI Pattern — Inline Search Bar

- The `FriendsListScreen` currently uses a standard `AppBar` with `title: Text(context.l10n.friendsTitle)` and three `_navAction` icon buttons (Daily, Friends, Settings) in `actions`. The body contains `_TagFilterChipsBar` (Story 8.1 tag chips, already functional) above the friend list `ListView`.

- **Search icon placement:** Add a search `IconButton` (icon: `Icons.search`) as the FIRST item in the `actions` list, before the existing `_navAction` buttons.

- **Search mode:** When search is active, replace the `AppBar.title` with a `TextField`. Keep the `_navAction` buttons visible (they provide essential navigation). Replace only the search icon with a clear (✕) `IconButton`.

- **State management for search mode:** Use a local `bool _isSearchActive` managed via `StatefulWidget` conversion OR a separate `StateProvider<bool>`. Given the project's Riverpod-first pattern, prefer converting `FriendsListScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` so search UI state (field visibility, focus) stays local while filter state (`searchQueryProvider`) stays in Riverpod.

- **Back button behavior:** Wrap the search mode in the existing `PopScope` or add behavior: when search is active and Android back is pressed, collapse search instead of navigating away. The shell's `PopScope` (Story 4.7) handles page-level back; this is an additional inner handler. Search state must also reset when navigation leaves the Friends page so returning to Friends always shows the full list.

### File Locations

| Component | Path |
|---|---|
| Friends list screen | `lib/features/friends/presentation/friends_list_screen.dart` |
| Friends providers | `lib/features/friends/data/friends_providers.dart` |
| EN l10n | `lib/l10n/app_en.arb` |
| FR l10n | `lib/l10n/app_fr.arb` |
| Existing widget tests | `test/widget/friends_list_screen_test.dart` |
| **New** search widget tests | `test/widget/friends_list_search_test.dart` |
| Theme tokens | `lib/shared/theme/app_tokens.dart` |
| L10n extension | `lib/core/l10n/l10n_extension.dart` |
| Friend model (Drift) | `lib/core/database/app_database.dart` (generated `Friend` class) |

### Existing Code Context

```dart
// Current filteredFriendsProvider (Story 8.1) — DO NOT MODIFY, only consume
final filteredFriendsProvider =
    Provider.autoDispose<AsyncValue<List<Friend>>>((ref) {
  final asyncFriends = ref.watch(allFriendsProvider);
  final activeTags = ref.watch(activeTagFiltersProvider);
  return asyncFriends.whenData((friends) {
    if (activeTags.isEmpty) return friends;
    return friends.where((friend) {
      final friendTags = decodeFriendTags(friend.tags);
      return friendTags.any(activeTags.contains);
    }).toList();
  });
});
```

```dart
// Story 8.2 initially swapped filteredFriendsProvider for the search-aware list.
// After Story 8.4, FriendsListScreen consumes searchFilteredFriendsWithLastContactProvider
// so the same search semantics preserve last-contact metadata in the tile UI.
```

```dart
// FriendCardTile expects: Friend friend + VoidCallback onTap
// No changes needed to FriendCardTile itself
```

### Design Tokens (do not hard-code colors)

- Use `Theme.of(context).colorScheme.*` — never hex values
- The project uses `app_tokens.dart` for custom tokens; standard M3 `colorScheme` for everything else
- Search icon, clear icon: use default `IconButton` theming (inherits from AppBar)
- Search `TextField`: use default M3 styling (no custom decoration beyond removing the border for inline appearance)

### Testing Conventions

- Widget tests use `ProviderScope(overrides: [...])` to inject test data
- `allFriendsProvider` is overridden with `Stream.value(friends)` pattern
- Use `tester.pump()` + `tester.pump(Duration(milliseconds: 300))` for async settle (no `pumpAndSettle`)
- Wrap widget in `MaterialApp.router` or `GoRouter` harness with localization delegates
- See `test/widget/friends_list_screen_test.dart` for the established pattern

### Regression Watch-Outs

- **Do NOT break the existing `_EmptyFriendsState`** — the "no friends at all" empty state must still work when the list is truly empty (no friends in DB), distinct from the "no search results" empty state.
- **Do NOT break the existing `_FilteredEmptyState`** — the "no tags match" empty state (`noFriendsWithTagsYet`) must still work when tag filtering yields zero results with no search active.
- **Three-way empty-state logic:** `_EmptyFriendsState` (no friends, no filters, no search) vs. `_FilteredEmptyState` (tags active, no match) vs. new search empty state (search active, no match). The current condition `friends.isEmpty && activeTags.isEmpty` must be extended to also check `searchQuery.isEmpty`.
- **Do NOT modify `allFriendsProvider` or `filteredFriendsProvider`** — they are consumed by other parts of the app.
- **Do NOT break `FriendCardTile` tap navigation** — tapping a tile must still navigate to `FriendDetailRoute(friend.id)`.
- **Existing tests in `friends_list_screen_test.dart`** still override `allFriendsProvider` with `Stream.value(friends)`. Since `searchFilteredFriendsProvider` derives from `filteredFriendsProvider` which derives from `allFriendsProvider`, the existing override will propagate — no change needed to existing tests AS LONG AS `searchQueryProvider` defaults to empty string (which it does).
- **Story 4.7 shell navigation:** `FriendsListScreen` runs inside a `PageView` shell. The shell has its own `PopScope` that navigates from Friends (index 1) back to Daily (index 0). The search `PopScope` MUST be nested INSIDE `FriendsListScreen` with `canPop: !isSearchActive` so it intercepts back before the shell's handler when search is active.
- **Search reset on navigation away:** because `FriendsListScreen` stays mounted inside the shell `PageView`, the implementation must reset search state when the route leaves `/friends`; relying on widget disposal is insufficient.
- **FAB (FloatingActionButton)** for adding friends must remain visible during search mode.
- **`_TagFilterChipsBar`** must remain visible during search mode — tags and search compose as intersection.

### l10n Keys to Add

**`app_en.arb`:**
```json
"searchFriendsByName": "Search friends by name",
"@searchFriendsByName": {
  "description": "TalkBack label and hint for friend list search field"
},
"noFriendNamedSearch": "No friend named \"{query}\" in your circle.",
"@noFriendNamedSearch": {
  "description": "Empty state when friend search yields no results",
  "placeholders": {
    "query": {
      "type": "String"
    }
  }
}
```

**`app_fr.arb`:**
```json
"searchFriendsByName": "Rechercher des amis par nom",
"noFriendNamedSearch": "Aucun ami nommé « {query} » dans votre cercle."
```

### NFR Compliance

| NFR | Requirement | How Addressed |
|---|---|---|
| NFR15 | 48×48dp min touch targets | Search icon and clear icon inherit `IconButton` default (48dp) |
| NFR16 | WCAG AA contrast (4.5:1) | M3 theme tokens ensure contrast; no custom colors |
| NFR17 | TalkBack navigability | `Semantics(label: l10n.searchFriendsByName)` on search field |

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 8, Story 8.2](../planning-artifacts/epics.md)
- [Source: _bmad-output/planning-artifacts/prd.md — FR12](../planning-artifacts/prd.md)
- [Source: _bmad-output/planning-artifacts/architecture.md — Riverpod Patterns](../planning-artifacts/architecture.md)
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Navigation Patterns](../planning-artifacts/ux-design-specification.md)
- [Source: _bmad-output/implementation-artifacts/2-5-friends-list-view.md — FriendsListScreen patterns](2-5-friends-list-view.md)

## Dev Agent Record

### Agent Model Used

GPT-5.4

### Debug Log References

- `flutter gen-l10n`
- `flutter analyze lib/features/friends/data/friends_providers.dart lib/features/friends/presentation/friends_list_screen.dart test/widget/friends_list_search_test.dart`
- `flutter test test/widget/friends_list_search_test.dart test/widget/friends_list_screen_test.dart`

### Completion Notes List

- Added `searchQueryProvider` and `searchFilteredFriendsProvider` so name search composes in-memory with Story 8.1 tag filters.
- Converted `FriendsListScreen` to `ConsumerStatefulWidget` to support inline AppBar search UI, autofocus, and nested back-button interception via `PopScope`.
- Added a dedicated search empty state using `context.l10n.noFriendNamedSearch(query)` while preserving existing no-friends and tag-filter empty states.
- Added English and French localization keys, then regenerated Flutter localization classes.
- Added widget coverage for inline search activation, live filtering, empty results, clear/reset behavior, and localized semantics.
- Senior review follow-up: reset search state when shell navigation leaves Friends, and add regression coverage for tag+search intersection and Android/system back behavior.
- Deduplicated the in-memory name-match rule so both `searchFilteredFriendsProvider` and `searchFilteredFriendsWithLastContactProvider` share the same normalization and predicate.
- Added regression coverage for the real shell back path while search is active and for returning from a root-level settings overlay with search state correctly cleared.
- Editor diagnostics for the touched Dart files are clean. Flutter CLI validation could not be re-run in the current container because `flutter` is unavailable on `PATH`.

### File List

- spetaka/lib/features/friends/data/friends_providers.dart
- spetaka/lib/features/friends/presentation/friends_list_screen.dart
- spetaka/lib/l10n/app_en.arb
- spetaka/lib/l10n/app_fr.arb
- spetaka/lib/core/l10n/app_localizations.dart
- spetaka/lib/core/l10n/app_localizations_en.dart
- spetaka/lib/core/l10n/app_localizations_fr.dart
- spetaka/test/widget/friends_list_search_test.dart
- spetaka/test/widget/app_shell_screen_test.dart

### Change Log

- 2026-03-26: Implemented Story 8.2 inline friend-list search, localization, and widget tests; validated with Flutter analyze and widget tests.
- 2026-03-26: Applied senior review fixes for shell-navigation reset and added regression tests for intersection filtering and Android back handling.
- 2026-03-26: Deduplicated the search predicate implementation, added shell-back and settings-overlay regression coverage, and tightened the accessibility assertion to inspect the search field semantics directly.

## Senior Developer Review (AI)

### Reviewer

Laurus on 2026-03-26

### Outcome

Approved after fixes.

### Notes

- Fixed the navigation-away persistence bug by resetting search state when the shell leaves `/friends` while keeping Android back interception inside `FriendsListScreen`.
- Added regression coverage for tag + search intersection, Android back while search is active, and returning to Friends after leaving the shell page.
- Updated story wording to reflect the Story 8.4 last-contact-aware provider path used by the UI.
- Follow-up hardening: the shell-specific Android back path is now covered explicitly, overlay navigation back from Settings is covered, and the search semantics assertion now validates the editable field node instead of any matching semantics wrapper.

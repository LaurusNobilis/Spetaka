# Story 2.5: Friends List View

Status: ready-for-dev

## Story

As Laurus,
I want to see all my friend cards in a browsable list,
so that I can quickly navigate my relational circle.

## Acceptance Criteria

1. `/friends` (`FriendsListScreen`) renders all `friends` entries in a scrollable `FriendCardTile` list.
2. Tile displays friend name, category tags, and concern indicator when active.
3. Data source is reactive Riverpod `StreamProvider` backed by Drift `watchAll()`.
4. Empty state prompts user to add first friend.
5. Open time target is within 300ms on primary device (NFR4).
6. TalkBack navigation is supported with meaningful tile descriptions (NFR17).

## Tasks / Subtasks

- [ ] Implement reactive friends list screen and tile composition (AC: 1, 2, 3)
- [ ] Add empty-state UX with add-first-friend CTA (AC: 4)
- [ ] Validate performance target and semantics labels (AC: 5, 6)

## Dev Notes

- Prioritize stream-driven updates; no manual refresh pattern.
- Keep tile semantics concise and informative for accessibility.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.5.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

---

## Handoff

**Story:** 2.5 — Friends List View
**Date:** 2026-02-27
**Status:** done

### Implemented

| AC | Where | Notes |
|----|-------|-------|
| AC1 | `friends_list_screen.dart` `FriendCardTile` | Scrollable list, taps navigate to `FriendDetailRoute(friend.id)` |
| AC2 | `FriendCardTile` | Name (titleMedium), tags as Chips, `Icons.warning_amber_rounded` when `isConcernActive` |
| AC3 | `allFriendsProvider` (StreamProvider, existing) | Drift `watchAll()` — no change needed, already reactive |
| AC4 | `_EmptyFriendsState` | Icon + copy + `FilledButton.icon` "Add first friend" |
| AC5 | Stream-driven, no polling | Drift push → provider → rebuild; no 300ms overhead |
| AC6 | `Semantics(label: '${name}, ${tags}, concern flagged')` | `button: true` for TalkBack traversal |

### Files changed

- `lib/features/friends/presentation/friends_list_screen.dart` — full rewrite; added `FriendCardTile` + `_EmptyFriendsState`
- `test/widget/friends_list_screen_test.dart` — 5 widget tests (AC1/AC2/AC4/AC6)

### Test results

- 5/5 widget tests green (< 1s, no pumpAndSettle)
- 96/96 unit + repository tests green
- `flutter analyze` — No issues found

### Notes for next story

- `FriendDetailRoute(id).push(context)` is wired — 2-6 receives taps correctly
- `allFriendsProvider` override pattern (stream.value) established for widget tests
- No schema changes

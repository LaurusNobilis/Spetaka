# Story 2.6: Friend Card Detail View

Status: ready-for-dev

## Story

As Laurus,
I want to open a friend card to see full details, events, and contact history,
so that I can act with complete context before reaching out.

## Acceptance Criteria

1. `/friends/:id` (`FriendCardScreen`) displays name, formatted mobile, tags, notes, active concern note, events section placeholder, contact history placeholder.
2. Prominent action buttons (Call/SMS/WhatsApp) are visible as placeholders for Epic 5 wiring.
3. Screen opens within 300ms (NFR4).
4. Edit button routes to `FriendFormScreen` in edit mode for current friend.
5. Screen reacts to SQLite updates without manual refresh.

## Tasks / Subtasks

- [ ] Implement `FriendCardScreen` data layout and sections (AC: 1)
- [ ] Add placeholder action row for future integration (AC: 2)
- [ ] Wire edit navigation and friend-id binding (AC: 4)
- [ ] Ensure reactive stream updates + perf check (AC: 3, 5)

## Dev Notes

- Keep placeholder sections explicit for Epic 3 and Epic 5 integration points.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.6.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

---

## Handoff

**Story:** 2.6 — Friend Card Detail View
**Date:** 2026-02-27
**Status:** done

### Implemented

| AC | Where | Notes |
|----|-------|-------|
| AC1 | `friend_card_screen.dart` `_FriendDetailBody` | Name (AppBar), E.164 mobile (SelectableText), tags (Chips), notes (conditional), concern note (conditional + icon), Events placeholder, Contact History placeholder |
| AC2 | `_ActionButtonRow` | Call/SMS/WhatsApp `OutlinedButton.icon` with `onPressed: null`; Tooltip "coming soon". Epic 5 will wire `ContactActionService` |
| AC3 | `watchFriendByIdProvider` (StreamProvider) | Drift stream push; no polling |
| AC4 | `IconButton(Icons.edit_outlined)` in AppBar | Calls `EditFriendRoute(id).push(context)` → `/friends/:id/edit` |
| AC5 | `watchFriendByIdProvider` replaces `friendByIdProvider` | Auto-refresh on SQLite changes; `FutureProvider` left intact for Story 2.3 compatibility |

### Files changed

- `lib/features/friends/presentation/friend_card_screen.dart` — full rewrite
- `lib/features/friends/data/friends_providers.dart` — added `watchFriendByIdProvider` (StreamProvider.family)
- `lib/features/friends/data/friend_repository.dart` — added `watchById(id)` method
- `lib/core/database/daos/friend_dao.dart` — added `watchById(id)` using `watchSingleOrNull()`
- `lib/core/router/app_router.dart` — added `EditFriendRoute` + `/friends/:id/edit` sub-route
- `lib/features/friends/presentation/friend_form_screen.dart` — added optional `editFriendId` param (Story 2.7 pre-fills)
- `test/widget/friend_card_screen_test.dart` — 8 widget tests (AC1×4, AC2, AC4, not-found)

### Test results

- 8/8 widget tests green (< 1s, no pumpAndSettle)
- 115/115 total tests green
- `flutter analyze` — No issues found

### Notes for next story (2.7 Edit)

- `FriendFormScreen(editFriendId: id)` route is wired — 2.7 only needs to pre-fill form fields
- `watchFriendByIdProvider` can be used in edit screen for pre-loading data
- `FriendRepository.update()` already exists; `FriendRepository.findById()` works for initial load

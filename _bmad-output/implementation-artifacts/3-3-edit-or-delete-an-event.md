# Story 3.3: Edit or Delete an Event

Status: ready-for-dev

## Story
As Laurus, I want to edit or delete events so event data stays accurate over time.

## Acceptance Criteria
1. Event edit form opens prefilled with current values.
2. Save updates event record and timestamps where applicable.
3. Delete action requires confirmation dialog.
4. Events list updates reactively after edit/delete.

## Tasks
- [ ] Implement event edit flow and update mapping.
- [ ] Add delete confirmation and removal flow.
- [ ] Ensure reactive list refresh without manual reload.
- [ ] Add tests for update/delete scenarios.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.3)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

## Handoff

**Status:** done — commit `da742db` · 2026-02-28

### What was implemented
| Layer | File | Notes |
|---|---|---|
| Repository | `event_repository.dart` | `updateEvent()`, `findById()` added |
| Screen | `events/presentation/edit_event_screen.dart` | New — prefilled form (AC1), persists via `updateEvent` (AC2) |
| Router | `core/router/app_router.dart` | `EditEventRoute(friendId, eventId)` + GoRoute with `extra:Event` |
| UI | `friends/presentation/friend_card_screen.dart` | `_EventRow` gains `PopupMenuButton` → Edit / Delete / Mark done |
| UI | same | `_EventsSection._handleDelete` shows confirmation dialog (AC3) |
| Tests | `test/repositories/event_repository_test.dart` | 4 tests: update persists, delete removes, stream reactive, convert cadence |

### AC coverage
- AC1 ✅ `EditEventScreen` initialised from `Event` values  
- AC2 ✅ `EventRepository.updateEvent` writes all mutable fields  
- AC3 ✅ `AlertDialog` with Cancel/Delete before `deleteEvent()`  
- AC4 ✅ `watchByFriendId` stream — list refreshes without reload  

### Wiring note
`EditEventRoute.push` passes `Event` via GoRouter `extra`; the route builder casts `state.extra as Event` — no serialisation needed (in-memory navigation only).

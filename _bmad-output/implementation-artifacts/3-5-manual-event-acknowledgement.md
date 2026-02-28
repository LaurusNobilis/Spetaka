# Story 3.5: Manual Event Acknowledgement

Status: ready-for-dev

## Story
As Laurus, I want to mark events done manually so I can close loops even outside 1-tap action flows.

## Acceptance Criteria
1. Mark-as-done sets `is_acknowledged=true` and `acknowledged_at` timestamp.
2. Acknowledged events have clear visual state.
3. Recurring events compute next due date from acknowledgment + cadence.
4. Priority inputs exclude acknowledged one-time events and recompute recurring due state.

## Tasks
- [ ] Implement acknowledgment action and persistence.
- [ ] Add acknowledged UI styling and metadata display.
- [ ] Implement recurring next-due recomputation logic.
- [ ] Add tests for acknowledged and recurring behaviors.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.5)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

## Handoff

**Status:** done — commit `da742db` · 2026-02-28

### What was implemented
| Layer | File | Notes |
|---|---|---|
| DAO | `core/database/daos/event_dao.dart` | `watchPriorityInputEvents()` — excludes acknowledged one-time events (AC4) |
| Repository | `event_repository.dart` | `acknowledgeEvent(id)` — one-time: sets `isAcknowledged=true` + `acknowledgedAt=now` (AC1); recurring: advances `date += cadenceDays * ms` and resets (AC3) |
| Repository | same | `watchPriorityInputEvents()` proxy (AC4) |
| Provider | `events_providers.dart` | `watchPriorityInputEventsProvider` for Epic 4 engine |
| UI | `friend_card_screen.dart` | "Mark as done"/"Mark done (advance)" in popup menu (AC1) |
| UI | same | Acknowledged one-time events: 50% opacity chip + strikethrough + green check + "Done dd MMM" timestamp (AC2) |
| Tests | `event_repository_test.dart` | 4 tests: one-time ack, recurring advance+reset, no-op on unknown id, reactive stream |

### AC coverage
- AC1 ✅ `is_acknowledged=true` + `acknowledged_at` set for one-time events  
- AC2 ✅ Visual state: muted chip, strikethrough, green "Done …" label  
- AC3 ✅ Recurring events: `date` advanced by `cadenceDays`, acknowledged reset  
- AC4 ✅ `watchPriorityInputEventsProvider` exposes only pending events to Epic 4  

### Recurring logic note
Acknowledging a recurring event does **not** mark it permanently done — it advances the next due date by cadence so the event re-appears as pending. One-time events stay marked done permanently.

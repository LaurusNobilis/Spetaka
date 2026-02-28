# Story 3.2: Add a Recurring Check-in Cadence

Status: ready-for-dev

## Story
As Laurus, I want to set recurring check-in cadence so the daily view can detect due/overdue relationship touchpoints.

## Acceptance Criteria
1. Recurring events are saved with `is_recurring=true` and `cadence_days`.
2. Migration increments schema version and adds cadence field safely.
3. UI offers cadence options (7/14/21/30/60/90 days) with human labels.
4. Event list displays recurring interval label.
5. Priority engine input stream exposes recurring fields.

## Tasks
- [ ] Add migration + model updates for `cadence_days`.
- [ ] Implement recurring cadence picker and save flow.
- [ ] Update event rendering for recurring labels.
- [ ] Add tests for migration + recurring persistence.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

**Status:** done — commit `4ddc943`

### Files Modified
- `lib/features/events/domain/event.dart` — added `cadenceDays` nullable INT column
- `lib/core/database/app_database.dart` — schema v5, migration v4→v5 `addColumn(events.cadenceDays)`
- `lib/features/events/data/event_repository.dart` — `addRecurringEvent(cadenceDays)` method
- `lib/features/events/presentation/add_event_screen.dart` — recurring `SwitchListTile` + cadence `_TypeChip` row
- `lib/features/friends/presentation/friend_card_screen.dart` — `_EventRow` shows repeat icon + cadence label
- `test/repositories/event_repository_test.dart` — 3 new tests (Story 3.2 group)
- `test/unit/database_foundation_test.dart` — `schemaVersion == 5`

### AC Coverage
1. ✅ `addRecurringEvent` saves `is_recurring=true` + `cadence_days`
2. ✅ Migration v4→v5: `addColumn(events, events.cadenceDays)` (safe for fresh install)
3. ✅ UI: 6 options 7/14/21/30/60/90d with labels Every week / Every 2 weeks / Every 3 weeks / Monthly / Every 2 months / Every 3 months
4. ✅ `_EventRow` renders repeat icon + cadence label when `isRecurring=true`
5. ✅ `watchAllRecurringEventsProvider` stream exposes recurring fields for priority engine

### Next batch: 3-3 (edit/delete event) + 3-5 (manual acknowledgement)

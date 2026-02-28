# Story 3.1: Add a Dated Event to a Friend Card

Status: ready-for-dev

## Story
As Laurus, I want to add a dated event to a friend card so Spetaka can surface important dates at the right time.

## Acceptance Criteria
1. `events` table supports required columns for dated events (`id`, `friend_id`, `type`, `date`, `is_recurring`, `comment`, `is_acknowledged`, `acknowledged_at`, `created_at`).
2. Add-event flow from `FriendCardScreen` saves with UUID v4 and `is_recurring=false`.
3. Event list shows type, formatted date, optional comment.
4. Event type selector includes the 5 default types.
5. Date picker respects 48x48dp touch targets.

## Tasks
- [ ] Create/verify `events` schema and repository mapping.
- [ ] Build add-dated-event UI flow.
- [ ] Render event list row with formatted fields.
- [ ] Add tests for create/persist/read event path.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.1)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

**Status:** done — commit `b24e0c0`

### Files Created
- `lib/features/events/domain/event.dart` — `Events` Drift table (9 columns)
- `lib/features/events/domain/event_type.dart` — `EventType` enum, 5 FR15 types
- `lib/features/events/data/event_repository.dart` — `addDatedEvent`, `findByFriendId`, `watchByFriendId`, `watchAllRecurring`, `deleteEvent`, `deleteByFriendId`
- `lib/features/events/data/event_repository_provider.dart` — `@Riverpod(keepAlive:true)`
- `lib/features/events/data/events_providers.dart` — `watchEventsByFriendProvider`, `watchAllRecurringEventsProvider`
- `lib/features/events/presentation/add_event_screen.dart` — type chips (48dp), date picker, comment field
- `test/repositories/event_repository_test.dart` — 5 tests, all green

### Files Modified
- `lib/core/database/app_database.dart` — schema v4, Events table + migration
- `lib/core/database/daos/event_dao.dart` — full CRUD implementation
- `lib/core/router/app_router.dart` — `AddEventRoute` + `/friends/:id/events/new`
- `lib/features/friends/presentation/friend_card_screen.dart` — events section with `_EventsSection` + `_EventRow`; `_DetailSection` now accepts optional `trailing`
- `test/widget/friend_card_screen_test.dart` — stub `watchEventsByFriendProvider`
- `test/unit/app_shell_theme_test.dart` — stub same provider + schemaVersion → 4
- `test/unit/database_foundation_test.dart` — schemaVersion == 4

### AC Coverage
1. ✅ Events table: 9 columns (id/friend_id/type/date/is_recurring/comment/is_acknowledged/acknowledged_at/created_at)
2. ✅ `addDatedEvent` saves UUID v4, `is_recurring=false`
3. ✅ `_EventRow` shows type label, formatted date, optional comment
4. ✅ `EventType` 5 default types selector in `AddEventScreen`
5. ✅ Date picker `InkWell` container has `minHeight: 48, minWidth: 48`

### Next: Story 3-2 — add `cadence_days` column, schema v5, recurring picker UI

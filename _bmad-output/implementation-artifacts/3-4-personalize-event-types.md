# Story 3.4: Personalize Event Types

Status: review

## Story

As Laurus,
I want to view, add, rename, reorder, and delete event types,
So that my event vocabulary reflects my actual relationships, not a generic default list.

## Acceptance Criteria (BDD — from Epics)

**AC1 — Default types seeded in SQLite:**
**Given** the app launches for the first time (or the `event_types` table is empty)
**Then** 5 default event types are seeded: birthday, wedding anniversary, important life event, regular check-in, important appointment
**And** they are stored in a dedicated `event_types` Drift table (`id TEXT PK`, `name TEXT`, `sort_order INTEGER`, `created_at INTEGER`)
**And** `shared_preferences` is NOT used for event type storage

**AC2 — Add a new event type:**
**Given** Laurus is on the Event Type management screen
**When** he taps "Add type" and enters a name
**Then** a new row is inserted in `event_types` with `sort_order` = max+1 and the list updates reactively

**AC3 — Rename an existing event type:**
**Given** Laurus taps an event type in the management screen
**When** he edits the name inline and confirms
**Then** the `name` column is updated in `event_types`

**AC4 — Delete with warning:**
**Given** Laurus deletes an event type
**When** existing events reference that type
**Then** a warning is shown: "X events use this type — they will keep their current label"
**And** on confirm the type is removed from `event_types`

**AC5 — Reorder via drag-and-drop:**
**Given** Laurus drag-reorders types in the management screen
**Then** `sort_order` values are persisted and the custom order is reflected everywhere

**AC6 — Picker reflects personalized list:**
**Given** Laurus opens Add Event (3.1) or Edit Event (3.3)
**Then** the event type selector shows the personalized list from `event_types` (ordered by `sort_order`) instead of the hardcoded `EventType` enum

## Tasks / Subtasks

- [x] **Task 1 (AC1):** New `EventTypes` Drift table + migration v5→v6
  - [x] 1.1 — Define `EventTypes` table class in `lib/features/events/domain/event_type_entity.dart`
  - [x] 1.2 — Register table in `AppDatabase` tables list
  - [x] 1.3 — Add migration from v5 → v6: `createTable(eventTypes)`
  - [x] 1.4 — Seed 5 defaults in `beforeOpen` when table is empty
  - [x] 1.5 — Run `dart run build_runner build` to regenerate `.g.dart`
- [x] **Task 2 (AC1):** New `EventTypeDao` with CRUD + reorder
  - [x] 2.1 — `insertEventType()`, `updateName()`, `deleteById()`, `updateSortOrders()`, `watchAll()`
  - [x] 2.2 — `countEventsByType(typeName)` — for delete warning (AC4)
- [x] **Task 3 (AC1):** `EventTypeRepository` in `lib/features/events/data/event_type_repository.dart`
  - [x] 3.1 — CRUD methods + reorder persistence
  - [x] 3.2 — Riverpod providers: `eventTypeRepositoryProvider`, `watchEventTypesProvider`
- [x] **Task 4 (AC2, AC3, AC4, AC5):** Event Type Management Screen
  - [x] 4.1 — New `ManageEventTypesScreen` with `ReorderableListView`
  - [x] 4.2 — Add type: bottom TextField + add button
  - [x] 4.3 — Rename: inline edit on tap
  - [x] 4.4 — Delete: confirmation dialog with usage count (AC4)
  - [x] 4.5 — Route: `ManageEventTypesRoute` → `/settings/event-types` (or accessible from Add Event screen)
- [x] **Task 5 (AC6):** Migrate pickers from `EventType` enum to dynamic list
  - [x] 5.1 — `AddEventScreen`: replace `EventType.values` loop with `watchEventTypesProvider` stream
  - [x] 5.2 — `EditEventScreen`: same migration
  - [x] 5.3 — `FriendCardScreen._EventRow`: resolve type label from `event_types` table (fallback to raw string for orphan types)
- [x] **Task 6:** Repository + widget tests
  - [x] 6.1 — Repo tests: seed defaults, add, rename, delete, reorder, count usage
  - [x] 6.2 — Widget test: management screen renders, reorder works
  - [x] 6.3 — Verify picker shows dynamic list

## Dev Notes

### Critical Architecture Change: Enum → Dynamic Table

The current `EventType` Dart enum (`lib/features/events/domain/event_type.dart`) is hardcoded with 5 values. Story 3.4 requires a **dynamic** list stored in SQLite. This is a structural migration:

1. **Keep the enum temporarily** as a seed source for default names. It can remain as a helper for backward compatibility with events that already store `type` as `event.storedName` (e.g., `"birthday"`).
2. **The `events.type` column stores a string** — it already persists the enum `.name` (e.g., `"birthday"`). After 3.4, new custom types will store their `name` string in the same column. The join is implicit (string match), NOT a foreign key.
3. **`EventType.fromString()` fallback** — currently falls back to `regularCheckin` for unknown types. After 3.4, the picker should use dynamic data. The `fromString` can remain as a safety net for the UI label but should prefer looking up from the `event_types` table.

### Database Migration

- Current `schemaVersion` = **5** (last bump: Story 3.2 cadence_days column)
- Bump to **6**: `createTable(eventTypes)`
- Seed in `beforeOpen`: check if `event_types` is empty → insert 5 defaults with `sort_order` 0–4
- Architecture spec: "Default event types seeded via `AppDatabase.beforeOpen` migration callback" [Source: architecture.md#L740]

### File Locations (architecture-compliant)

| Layer | Path | Notes |
|---|---|---|
| Table def | `lib/features/events/domain/event_type_entity.dart` | New Drift table class `EventTypes` |
| DAO | `lib/core/database/daos/event_type_dao.dart` | New DAO, registered in AppDatabase |
| Repository | `lib/features/events/data/event_type_repository.dart` | Business logic |
| Provider | `lib/features/events/data/event_type_providers.dart` | Riverpod providers (`@riverpod`) |
| Screen | `lib/features/events/presentation/manage_event_types_screen.dart` | Management UI |
| Route | `lib/core/router/app_router.dart` | Add `ManageEventTypesRoute` |
| Existing enum | `lib/features/events/domain/event_type.dart` | Keep for seed data + backward compat |

### Naming Conventions

- Table class: `EventTypes` (plural, Drift convention)
- Entity: `EventTypeEntry` (avoid conflict with existing `EventType` enum)
- DAO: `EventTypeDao`
- Repository: `EventTypeRepository`

### Previous Story Intelligence (3-3, 3-5)

- **3-3 pattern:** Edit screen receives entity via GoRouter `extra` (in-memory, no serialization). Same pattern applies if management screen needs to pass data.
- **3-5 pattern:** `acknowledgeEvent()` does read-modify-write via DAO. Same pattern for reorder (read all → compute new sort_order → batch update).
- All tests use in-memory `AppDatabase([NativeDatabase.memory()])` — same for 3-4 tests.
- `pumpAndSettle` used cautiously in widget tests — avoid for Drift stream watchers; use `pump()` with explicit delays instead.

### Minimal Impact Strategy

- **DO NOT** remove the `EventType` enum yet — it's used in 5+ files. Instead, make the dynamic table the source of truth for pickers, and keep the enum as a backward-compat helper.
- **DO NOT** add a foreign key from `events.type` → `event_types.name`. The events table already stores type as a plain string. Orphan handling (AC4 warning) is purely informational.
- **DO NOT** change the events table schema — no new columns needed on `events`.

### Testing Standards

- Repository tests: in-memory DB, test CRUD + seed defaults + reorder persistence + count usage
- Widget tests: verify management screen renders list, add/rename/delete flows
- No `pumpAndSettle` with Drift stream providers — use `pump()` after state changes
- Run `flutter analyze` + `flutter test` before commit

## References

- [Epic 3, Story 3.4](../../_bmad-output/planning-artifacts/epics.md) — lines 524–545 — full BDD criteria
- [Architecture: migration strategy](../../_bmad-output/planning-artifacts/architecture.md) — lines 218–221
- [Architecture: event type seeding](../../_bmad-output/planning-artifacts/architecture.md) — line 740
- [Architecture: naming conventions](../../_bmad-output/planning-artifacts/architecture.md) — line 359
- Current schema: `app_database.dart` — `schemaVersion = 5`, tables: Friends, Acquittements, Events
- Current enum: `event_type.dart` — hardcoded 5 values, `storedName` = enum `.name`
- Current pickers: `add_event_screen.dart` line 133, `edit_event_screen.dart` line 139 — both iterate `EventType.values`

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (GitHub Copilot)

### Implementation Notes

- **Naming conflict resolved**: `@DataClassName('EventTypeEntry')` on `EventTypes` Drift table to avoid collision with existing `EventType` enum
- **Riverpod codegen limitation**: Used traditional `StreamProvider.autoDispose` for `watchEventTypesProvider` instead of `@riverpod` annotation — riverpod_generator throws `InvalidTypeException` on Drift-generated types
- **API migration**: `EventRepository` methods changed from `EventType` enum parameter to `String type` parameter — this is the core change enabling dynamic event types
- **Backward compatibility**: `_EventRow` in `FriendCardScreen` resolves type labels by trying `EventType.values` enum match first, then falls back to raw string
- **Orphan type handling**: `EditEventScreen` shows orphan type chip if event's type was deleted from `event_types` table
- **Deterministic seed IDs**: Default event types use stable IDs (`default-birthday`, `default-wedding-anniversary`, etc.) for idempotent seeding

### Completion Summary

- All 6 tasks completed (AC1–AC6)
- 199 tests pass (including 18 new repo tests + 7 new widget tests)
- `flutter analyze` — 0 issues
- No breaking changes to existing events — `events.type` column unchanged

### Files Created

| File | Purpose |
|---|---|
| `lib/features/events/domain/event_type_entity.dart` | Drift table definition for `event_types` |
| `lib/core/database/daos/event_type_dao.dart` | DAO with CRUD + reorder + countEventsByType |
| `lib/features/events/data/event_type_repository.dart` | Repository wrapping EventTypeDao |
| `lib/features/events/data/event_type_providers.dart` | Riverpod providers (repo + stream) |
| `lib/features/events/presentation/manage_event_types_screen.dart` | Management UI with ReorderableListView |
| `test/repositories/event_type_repository_test.dart` | 18 repository integration tests |
| `test/widget/manage_event_types_screen_test.dart` | 7 widget tests |

### Files Modified

| File | Changes |
|---|---|
| `lib/core/database/app_database.dart` | Added EventTypes table, EventTypeDao, schema v6, migration, seed defaults |
| `lib/features/events/data/event_repository.dart` | Changed EventType enum params to String type |
| `lib/features/events/presentation/add_event_screen.dart` | Dynamic type chips from watchEventTypesProvider |
| `lib/features/events/presentation/edit_event_screen.dart` | Dynamic type chips + orphan type support |
| `lib/features/friends/presentation/friend_card_screen.dart` | Backward-compatible type label resolution |
| `lib/core/router/app_router.dart` | Added ManageEventTypesRoute at /settings/event-types |
| `test/repositories/event_repository_test.dart` | Migrated EventType.X → EventType.X.storedName |
| `test/unit/database_foundation_test.dart` | Schema version assertion 5→6 |

### Change Log

| Date | Change |
|---|---|
| 2026-02-27 | Story 3.4 implemented — dynamic event types with CRUD management screen |

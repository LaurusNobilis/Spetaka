# Story 1.2: Drift Database Foundation & Migration Infrastructure

Status: review

## Story

As a developer,
I want an AppDatabase class with migration strategy and a clean DAO infrastructure in place,
so that all feature stories can add their entities and queries to a stable, well-structured database layer without conflicts.

## Acceptance Criteria

1. Given the Flutter project scaffold from Story 1.1 exists, when the Drift database foundation is set up, then `lib/core/database/app_database.dart` exists with `AppDatabase extends _$AppDatabase`, `schemaVersion = 1`, and `MigrationStrategy` with `onUpgrade` and `beforeOpen` hooks.
2. `lib/core/database/daos/` contains empty DAO stub files: `friend_dao.dart`, `event_dao.dart`, `acquittement_dao.dart`, `settings_dao.dart` — each with a class declaration and a placeholder for future queries.
3. `AppDatabase` is exposed as a Riverpod provider via `@riverpod` code generation, accessible from any feature.
4. `NativeDatabase.memory()` is confirmed working in tests for an in-memory database fixture.
5. `flutter test test/unit/database_foundation_test.dart` passes and verifies DB open, `schemaVersion = 1`, and migration hooks callable without error.

## Tasks / Subtasks

- [x] Implement AppDatabase foundation (AC: 1)
  - [x] Create `lib/core/database/app_database.dart`
  - [x] Configure `schemaVersion = 1`
  - [x] Implement `MigrationStrategy` with `onUpgrade` and `beforeOpen`
- [x] Create DAO stubs for future epics (AC: 2)
  - [x] Add `friend_dao.dart`
  - [x] Add `event_dao.dart`
  - [x] Add `acquittement_dao.dart`
  - [x] Add `settings_dao.dart`
- [x] Integrate Riverpod provider generation (AC: 3)
  - [x] Annotate database provider with `@riverpod`
  - [x] Run `build_runner` to generate provider code
- [x] Add in-memory DB verification tests (AC: 4, 5)
  - [x] Create `test/unit/database_foundation_test.dart`
  - [x] Validate database open, schema version, and migration strategy callbacks

## Dev Notes

- This story establishes the persistence backbone for all friend, event, acquittement, and settings features.
- Keep DAOs intentionally minimal at this stage: SQL queries are introduced in later stories.
- Follow repository layering constraints defined in architecture:
  - DAOs hold SQL concerns only.
  - Business logic remains outside DAOs.
  - Riverpod providers expose reactive access patterns.
- Preserve compatibility with planned timestamp storage strategy (Unix epoch milliseconds) and future migrations.

### Project Structure Notes

- Database concerns should stay under `lib/core/database/`.
- DAO stubs must be isolated in `lib/core/database/daos/` to prevent feature leakage and maintain clean architecture boundaries.
- Naming should match domain vocabulary from planning artifacts to reduce future refactor risk.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 1, Story 1.2.
- Source: `_bmad-output/planning-artifacts/architecture.md` — persistence, layering, and migration constraints.
- Source: `_bmad-output/planning-artifacts/prd.md` — reliability and data integrity context.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

- Riverpod v3 (riverpod_generator v4) generates `Ref` as the provider function parameter type instead of the legacy `XxxRef` pattern. Updated function signature to `AppDatabase appDatabase(Ref ref)` accordingly.
- All 5 story tests pass; full suite 33/33 green with no regressions.

### Completion Notes List

- ✅ AC1: `lib/core/database/app_database.dart` created — `AppDatabase extends _$AppDatabase`, `schemaVersion = 1`, `MigrationStrategy` with `onUpgrade` (no-op, ready for future migrations) and `beforeOpen` (enables `PRAGMA foreign_keys = ON`).
- ✅ AC2: Four DAO stubs created under `lib/core/database/daos/`: `friend_dao.dart`, `event_dao.dart`, `acquittement_dao.dart`, `settings_dao.dart` — each a `DatabaseAccessor<AppDatabase>` with `@DriftAccessor(tables: [])` + placeholder comment for the host epic.
- ✅ AC3: `@riverpod AppDatabase appDatabase(Ref ref)` annotation generates `appDatabaseProvider` via `build_runner`.  Provider calls `ref.onDispose(db.close)` for safe resource management.
- ✅ AC4: `AppDatabase([QueryExecutor? executor])` accepts `NativeDatabase.memory()` in tests; confirmed working in all 5 unit tests.
- ✅ AC5: `flutter test test/unit/database_foundation_test.dart` — 5/5 pass (DB open, `schemaVersion == 1`, `onUpgrade` hook non-null, `beforeOpen` hook non-null, `PRAGMA foreign_keys = 1`).
- `lib/core/core.dart` updated to barrel-export the new database layer.

### File List

- spetaka/lib/core/core.dart (modified)
- spetaka/lib/core/database/app_database.dart (created)
- spetaka/lib/core/database/app_database.g.dart (generated)
- spetaka/lib/core/database/daos/friend_dao.dart (created)
- spetaka/lib/core/database/daos/friend_dao.g.dart (generated)
- spetaka/lib/core/database/daos/event_dao.dart (created)
- spetaka/lib/core/database/daos/event_dao.g.dart (generated)
- spetaka/lib/core/database/daos/acquittement_dao.dart (created)
- spetaka/lib/core/database/daos/acquittement_dao.g.dart (generated)
- spetaka/lib/core/database/daos/settings_dao.dart (created)
- spetaka/lib/core/database/daos/settings_dao.g.dart (generated)
- spetaka/test/unit/database_foundation_test.dart (created)
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified)

### Change Log

- 2026-02-27: Implemented Story 1.2 — Drift database foundation. Created AppDatabase with schemaVersion=1 and MigrationStrategy, four DAO stubs, Riverpod @riverpod provider, barrel exports, and 5 passing unit tests. Status: ready-for-dev → review.
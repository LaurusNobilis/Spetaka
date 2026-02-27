# Story 1.2: Drift Database Foundation & Migration Infrastructure

Status: ready-for-dev

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

- [ ] Implement AppDatabase foundation (AC: 1)
  - [ ] Create `lib/core/database/app_database.dart`
  - [ ] Configure `schemaVersion = 1`
  - [ ] Implement `MigrationStrategy` with `onUpgrade` and `beforeOpen`
- [ ] Create DAO stubs for future epics (AC: 2)
  - [ ] Add `friend_dao.dart`
  - [ ] Add `event_dao.dart`
  - [ ] Add `acquittement_dao.dart`
  - [ ] Add `settings_dao.dart`
- [ ] Integrate Riverpod provider generation (AC: 3)
  - [ ] Annotate database provider with `@riverpod`
  - [ ] Run `build_runner` to generate provider code
- [ ] Add in-memory DB verification tests (AC: 4, 5)
  - [ ] Create `test/unit/database_foundation_test.dart`
  - [ ] Validate database open, schema version, and migration strategy callbacks

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

GPT-5.3-Codex

### Debug Log References

- Story generated from sprint backlog continuation after Story 1.1.

### Completion Notes List

- Story 1.2 context prepared for immediate `dev-story` execution.
- Acceptance criteria normalized and mapped to concrete implementation tasks.

### File List

- _bmad-output/implementation-artifacts/1-2-drift-database-foundation-migration-infrastructure.md
# Story 3.4: Personalize Event Types

Status: ready-for-dev

## Story
As Laurus, I want to manage event types so the app vocabulary reflects my real relationships.

## Acceptance Criteria
1. `event_types` table stores default types in SQLite (`id`, `name`, `sort_order`, `created_at`).
2. User can add, rename, delete, reorder event types.
3. Delete warns when types are referenced by existing events.
4. Picker in add-event flows reflects personalized list.
5. `shared_preferences` is not used for type storage.

## Tasks
- [ ] Implement event-type persistence in Drift.
- [ ] Build event-type management UI (CRUD + reorder).
- [ ] Add dependency warning on delete.
- [ ] Wire picker data source to personalized table.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.4)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

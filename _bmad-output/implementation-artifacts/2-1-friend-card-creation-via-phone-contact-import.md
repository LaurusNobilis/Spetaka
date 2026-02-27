# Story 2.1: Friend Card Creation via Phone Contact Import

Status: ready-for-dev

## Story

As Laurus,
I want to create a friend card by selecting a contact from my phone's address book,
so that I don't have to type names or phone numbers manually.

## Acceptance Criteria

1. Contact import starts from Add Friend and requests `READ_CONTACTS` at point-of-use only.
2. Contact picker opens via `flutter_contacts` and supports user selection.
3. New card is prefilled with contact display name + primary mobile normalized to E.164 (`PhoneNormalizer`).
4. Import scope is limited to name + primary mobile; no photo import in v1.
5. If permission denied, flow falls back to manual entry (Story 2.2).
6. `friends` table includes required columns and saves UUID v4 id + `care_score = 0.0`.
7. `friend_repository_test.dart` validates creation, persistence, and retrieval by id.

## Tasks / Subtasks

- [ ] Implement contact import entrypoint and permission gate (AC: 1, 5)
- [ ] Integrate `flutter_contacts` picker and mapping (AC: 2, 3, 4)
- [ ] Create/save friend record in Drift with required schema fields (AC: 6)
- [ ] Add repository tests for create/read path (AC: 7)

## Dev Notes

- Enforce strict point-of-use permission behavior.
- Reuse `PhoneNormalizer` for all number ingestion.
- Keep v1 import scope minimal by design (no photo).

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.1.
- Source: `_bmad-output/planning-artifacts/ux-design-specification.md` — v1 import scope constraints.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Completion Notes List

- Story prepared for immediate `dev-story` execution.

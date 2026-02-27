# Story 2.7: Edit Friend Card

Status: ready-for-dev

## Story

As Laurus,
I want to edit any field on a friend card at any time,
so that my relationship data stays accurate.

## Acceptance Criteria

1. Edit entry from `FriendCardScreen` opens prefilled `FriendFormScreen`.
2. Editable fields: name, mobile, tags, notes.
3. Save updates same UUID record and sets `updated_at`.
4. Return to detail screen shows updates immediately via reactive stream.
5. Mobile validation behavior matches Story 2.2 inline error handling.

## Tasks / Subtasks

- [ ] Implement edit mode prefill and update flow (AC: 1, 2, 3)
- [ ] Keep inline validation parity with manual create story (AC: 5)
- [ ] Verify immediate post-save reactive updates (AC: 4)

## Dev Notes

- Do not duplicate validation logic; reuse shared validators from create flow.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.7.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

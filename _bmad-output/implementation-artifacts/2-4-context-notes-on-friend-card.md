# Story 2.4: Context Notes on Friend Card

Status: ready-for-dev

## Story

As Laurus,
I want to add and edit a free-text note on a friend card,
so that I can preserve meaningful relational context over time.

## Acceptance Criteria

1. Notes field saves to `friends.notes` on submission.
2. Notes are displayed on `FriendCardScreen` as readable multiline text.
3. Notes can be edited at any time via card edit flow.
4. Notes remain optional; empty value is valid.

## Tasks / Subtasks

- [ ] Add note input/edit behavior in friend form (AC: 1, 3, 4)
- [ ] Persist note field in repository/Drift mapping (AC: 1)
- [ ] Render note block on detail screen with readable layout (AC: 2)

## Dev Notes

- Notes are narrative fields and should stay compatible with Story 1.7 repository-layer encryption policy.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.4.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

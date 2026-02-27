# Story 2.8: Delete Friend Card

Status: ready-for-dev

## Story

As Laurus,
I want to delete a friend card,
so that I can keep my circle relevant and clean.

## Acceptance Criteria

1. Delete action on `FriendCardScreen` opens `DeleteConfirmDialog`.
2. Confirmed deletion removes friend and cascades related events/acquittements from SQLite.
3. Dialog clearly states friend name and irreversible history loss warning.
4. Confirm returns to `FriendsListScreen`; cancel leaves detail view unchanged.
5. Deletion is persistent after app restart.

## Tasks / Subtasks

- [ ] Implement delete action and confirmation dialog (AC: 1, 3)
- [ ] Implement cascade delete at repository/database level (AC: 2)
- [ ] Wire navigation outcomes for confirm/cancel (AC: 4)
- [ ] Validate persistence behavior after restart scenario (AC: 5)

## Dev Notes

- Keep delete UX explicit and non-ambiguous to avoid accidental destructive actions.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.8.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

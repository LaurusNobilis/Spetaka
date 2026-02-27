# Story 2.8: Delete Friend Card

Status: done

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

Claude Sonnet 4.6

---

## Handoff

**Story 2.8 — Delete Friend Card — DONE**

**Files changed:**
- `lib/core/database/daos/acquittement_dao.dart` — `deleteByFriendId()` added (AC2)
- `lib/features/friends/data/friend_repository.dart` — `delete()` now async, cascades
  acquittements before deleting friend row (AC2, AC5)
- `lib/features/friends/presentation/friend_card_screen.dart` — `_FriendDetailBody`
  is now `ConsumerWidget`; delete `IconButton` in AppBar; `_confirmDelete()` AlertDialog
  with friend name + warning text (AC1, AC3); `_handleDelete()` → FriendsRoute() (AC4)

**Tests:** 4 new repo tests — friend removed from DB, 0 rows for unknown id,
acquittements cascade, cascade only own acquittements (AC2, AC5).

**AC coverage:** AC1 ✓ AC2 ✓ AC3 ✓ AC4 ✓ AC5 ✓

**103/103 tests green. flutter analyze clean.**

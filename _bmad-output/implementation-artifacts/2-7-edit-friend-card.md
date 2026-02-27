# Story 2.7: Edit Friend Card

Status: done

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

Claude Sonnet 4.6

---

## Handoff

**Story 2.7 — Edit Friend Card — DONE**

**Files changed:**
- `lib/features/friends/presentation/friend_form_screen.dart` — full edit mode:
  `editFriendId` triggers `_loadEditFriend()` (async prefill), `_saveFriend` calls
  `repo.update()` with preserved UUID+createdAt, notes field added (AC2), AppBar title
  "Edit Friend" (AC1), Back pops instead of resetting (AC4/navigation).

**Tests:** 3 new repo tests in `test/repositories/friend_repository_test.dart` —
`update` preserves UUID/createdAt, persists tags change, persists notes (encrypted field).

**AC coverage:** AC1 ✓ AC2 ✓ AC3 ✓ AC4 ✓ AC5 ✓

**103/103 tests green. flutter analyze clean.**

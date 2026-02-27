# Story 2.2: Friend Card Creation via Manual Entry

Status: ready-for-dev

## Story

As Laurus,
I want to create a friend card by typing a name and phone number manually,
so that I can add contacts not present in my phone or after permission denial.

## Acceptance Criteria

1. `FriendFormScreen` validates non-empty name and parseable phone via `PhoneNormalizer`.
2. Invalid phone displays inline message from `error_messages.dart` (no toast/modal).
3. Valid save persists UUID v4 id, normalized E.164 mobile, and `care_score = 0.0`.
4. All interactive elements respect 48x48dp minimum touch target.
5. On success, navigation returns to friends list and shows the new card.

## Tasks / Subtasks

- [ ] Build manual friend form with validation rules (AC: 1, 2)
- [ ] Persist friend card through repository/Drift (AC: 3)
- [ ] Validate touch-target accessibility baseline (AC: 4)
- [ ] Implement post-save navigation feedback (AC: 5)

## Dev Notes

- Keep validation and message mapping centralized.
- Form behavior should be identical whether entered directly or via import fallback.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.2.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

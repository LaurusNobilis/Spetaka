# Story 2.9: Concern / Préoccupation Flag

Status: done

## Story

As Laurus,
I want to mark a friend as having an active concern with a short note,
so that priority can be elevated when extra care is needed.

## Acceptance Criteria

1. On `FriendCardScreen`, setting concern stores `is_concern_active = true` and `concern_note`.
2. Concern indicator and note appear on detail screen and list tile with distinctive non-alarming style.
3. Clearing concern confirms then sets `is_concern_active = false` and clears `concern_note`.
4. Priority engine input stream exposes concern flag for Epic 4 multiplier use.
5. Repository tests cover set/clear concern transitions.

## Tasks / Subtasks

- [x] Implement concern set flow + note input (AC: 1)
- [x] Render concern state in detail/list UI (AC: 2)
- [x] Implement clear-concern confirmation and state reset (AC: 3)
- [x] Ensure concern fields are stream-exposed for ranking engine (AC: 4)
- [x] Add repository tests for concern toggling (AC: 5)

## Dev Notes

- Concern styling should remain warm/supportive and avoid alarm semantics.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.9.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

## Handoff

**Status:** Done — all 5 ACs implemented, 161 tests pass, flutter analyze clean.

**What was implemented:**

*Repository (`friend_repository.dart`):*
- `setConcern(id, {note})` — sets `isConcernActive=true`, encrypts `concernNote`, trims/nulls empty note.
- `clearConcern(id)` — sets `isConcernActive=false`, clears `concernNote`. Both are no-ops for missing IDs.

*UI (`friend_card_screen.dart`):*
- AC1: "Flag concern" `OutlinedButton` opens an `AlertDialog` with optional note field; calls `setConcern`.
- AC2: When `isConcernActive=true`: concern section with warm orange icon + label + note text rendered.
- AC3: "Clear concern" `TextButton` opens confirmation dialog; calls `clearConcern`.
- AC4: `watchAll()` / `watchById()` streams already expose `isConcernActive` + `concernNote` via Drift reactive streams — Epic 4 engine reads them directly.
- List tile: existing `FriendCardTile` already shows orange `warning_amber_rounded` icon when concern is active (Story 2.5).

*Tests:*
- `friend_repository_test.dart` — 6 new repo tests: setConcern set/empty/null note, clearConcern, encryption at rest, no-op for missing IDs.
- `friend_card_screen_test.dart` — 4 new widget tests: Flag concern button, concern section display, Clear concern button, mutual exclusion.

**No migration needed:** `is_concern_active` and `concern_note` columns existed since schema v2 (Story 1.7).

# Story 2.9: Concern / Préoccupation Flag

Status: ready-for-dev

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

- [ ] Implement concern set flow + note input (AC: 1)
- [ ] Render concern state in detail/list UI (AC: 2)
- [ ] Implement clear-concern confirmation and state reset (AC: 3)
- [ ] Ensure concern fields are stream-exposed for ranking engine (AC: 4)
- [ ] Add repository tests for concern toggling (AC: 5)

## Dev Notes

- Concern styling should remain warm/supportive and avoid alarm semantics.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.9.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

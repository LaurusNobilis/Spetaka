# Story 3.5: Manual Event Acknowledgement

Status: ready-for-dev

## Story
As Laurus, I want to mark events done manually so I can close loops even outside 1-tap action flows.

## Acceptance Criteria
1. Mark-as-done sets `is_acknowledged=true` and `acknowledged_at` timestamp.
2. Acknowledged events have clear visual state.
3. Recurring events compute next due date from acknowledgment + cadence.
4. Priority inputs exclude acknowledged one-time events and recompute recurring due state.

## Tasks
- [ ] Implement acknowledgment action and persistence.
- [ ] Add acknowledged UI styling and metadata display.
- [ ] Implement recurring next-due recomputation logic.
- [ ] Add tests for acknowledged and recurring behaviors.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.5)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

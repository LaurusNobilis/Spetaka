# Story 3.2: Add a Recurring Check-in Cadence

Status: ready-for-dev

## Story
As Laurus, I want to set recurring check-in cadence so the daily view can detect due/overdue relationship touchpoints.

## Acceptance Criteria
1. Recurring events are saved with `is_recurring=true` and `cadence_days`.
2. Migration increments schema version and adds cadence field safely.
3. UI offers cadence options (7/14/21/30/60/90 days) with human labels.
4. Event list displays recurring interval label.
5. Priority engine input stream exposes recurring fields.

## Tasks
- [ ] Add migration + model updates for `cadence_days`.
- [ ] Implement recurring cadence picker and save flow.
- [ ] Update event rendering for recurring labels.
- [ ] Add tests for migration + recurring persistence.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 3, Story 3.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

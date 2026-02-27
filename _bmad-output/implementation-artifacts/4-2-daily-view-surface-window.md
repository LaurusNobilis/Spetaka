# Story 4.2: Daily View Surface Window

Status: ready-for-dev

## Story
As Laurus, I want daily view to surface overdue, today, and +3 day events so focus stays actionable.

## Acceptance Criteria
1. `DailyViewScreen` pipeline includes overdue unacknowledged, today, and next 3 days.
2. Result list is ranked via `PriorityEngine.sort()`.
3. Drift + Riverpod streams update reactively.
4. Friends outside window do not appear in daily view.
5. Full render target is <=1s on primary device.

## Tasks
- [ ] Implement surface-window query logic.
- [ ] Integrate ranking step in provider pipeline.
- [ ] Verify reactive updates and timing target.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

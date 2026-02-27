# Story 5.5: Care Score Update After Acquittement

Status: ready-for-dev

## Story
As Laurus, I want care score to update after acquittement so priority uses fresh relationship-need signals.

## Acceptance Criteria
1. Logging acquittement and care-score update occur atomically in one transaction.
2. Care-need formula follows spec constants and expected intervals.
3. Constants live in `priority_engine.dart` (no magic numbers).
4. Updated score is persisted (`REAL`) and reflected reactively.
5. Repository tests validate score behavior and weighted comparisons.

## Tasks
- [ ] Implement atomic log + recompute transaction.
- [ ] Implement formula constants and computation.
- [ ] Persist score update and stream propagation.
- [ ] Add repository tests for key scenarios.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.5)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

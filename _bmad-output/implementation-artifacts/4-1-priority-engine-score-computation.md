# Story 4.1: Priority Engine — Score Computation

Status: ready-for-dev

## Story
As Laurus, I want a dynamic priority score so daily ranking highlights who needs care most.

## Acceptance Criteria
1. `priority_engine.dart` is pure Dart and returns sorted friends with `priorityScore`.
2. Formula includes event weight, overdue days, category weight, concern x2, and high care score boost.
3. Urgency tiers separate urgent (today/overdue) and important (next 3 days).
4. Computation target is <500ms for 100 cards.
5. Unit tests validate deterministic ranking rules.

## Tasks
- [ ] Implement pure scoring engine and constants.
- [ ] Implement urgency tiering rules.
- [ ] Add deterministic unit tests and perf benchmark test.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.1)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

# Story 7.2: Offline-First Verification & Graceful Degradation

Status: ready-for-dev

## Story
As Laurus, I want full offline usability so the app remains reliable in any network conditions.

## Acceptance Criteria
1. Core flows function identically in airplane mode.
2. Background sync skips silently when offline.
3. Manual sync while offline shows calm informational message.
4. End-to-end offline verification covers friend/event/acquittement/settings flows.
5. Tests confirm providers use local SQLite without network calls.

## Tasks
- [ ] Implement offline branching behavior for sync and UX.
- [ ] Run/automate offline e2e validation scenarios.
- [ ] Add tests guarding no-network dependency in core flows.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 7, Story 7.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

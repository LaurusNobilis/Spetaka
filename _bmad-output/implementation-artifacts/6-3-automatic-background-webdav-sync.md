# Story 6.3: Automatic Background WebDAV Sync

Status: ready-for-dev

## Story
As Laurus, I want background auto-sync so my data stays protected without manual routines.

## Acceptance Criteria
1. App launch/resume triggers background fire-and-forget sync when enabled.
2. UI remains fully responsive during sync.
3. Offline conditions skip silently unless user explicitly requests sync.
4. Explicit offline manual sync shows calm informational message.
5. Last successful sync timestamp is persisted and displayed.

## Tasks
- [ ] Wire lifecycle-triggered background sync.
- [ ] Ensure non-blocking execution pattern.
- [ ] Add offline/explicit-sync branching UX.
- [ ] Persist and display last successful sync time.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 6, Story 6.3)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

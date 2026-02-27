# Story 5.2: App Return Detection & Acquittement Trigger

Status: ready-for-dev

## Story
As Laurus, I want automatic acquittement prompt on app return so the loop closes without navigation burden.

## Acceptance Criteria
1. Resume lifecycle emits pending friend id.
2. Daily-view origin keeps expanded card and opens sheet over daily view.
3. Friend-card origin opens/stays on correct card and opens sheet.
4. Pending session state clears when sheet opens.
5. Trigger auto-expires after 30 minutes; manual fallback remains available.
6. OEM fallback button supports manual acquittement trigger.

## Tasks
- [ ] Implement resume detection + routing behavior.
- [ ] Differentiate origin context handling.
- [ ] Add timeout/expiry guard.
- [ ] Add OEM fallback control.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

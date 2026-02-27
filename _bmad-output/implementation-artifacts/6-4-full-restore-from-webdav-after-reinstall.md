# Story 6.4: Full Restore from WebDAV After Reinstall

Status: ready-for-dev

## Story
As Laurus, I want full restore after reinstall so my relationship history is never lost.

## Acceptance Criteria
1. Restore downloads encrypted backup and decrypts with user passphrase.
2. Wrong passphrase yields clear error and writes nothing.
3. Restore repopulates friends/events/acquittements/event_types/settings losslessly.
4. IDs are preserved and no conflicts introduced.
5. Daily view reflects restored data reactively.

## Tasks
- [ ] Implement download + decrypt restore flow.
- [ ] Add strict error-safe restore transaction behavior.
- [ ] Rehydrate all required datasets and settings.
- [ ] Add tests for wrong-passphrase and full-restore success.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 6, Story 6.4)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

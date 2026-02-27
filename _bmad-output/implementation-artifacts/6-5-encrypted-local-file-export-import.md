# Story 6.5: Encrypted Local File Export & Import

Status: ready-for-dev

## Story
As Laurus, I want encrypted local backup export/import so I keep portable recovery independent from WebDAV.

## Acceptance Criteria
1. Export creates encrypted `.enc` snapshot with required datasets.
2. Import decrypts selected file with passphrase and restores data.
3. Corrupt file/wrong passphrase fail safely with typed messages.
4. Export/import show progress/loading state.
5. Demo friends are excluded from backup payload.

## Tasks
- [ ] Implement encrypted export file creation.
- [ ] Implement import + decrypt + restore pipeline.
- [ ] Add safe-failure and error mapping behavior.
- [ ] Add loading-state UI and integration tests.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 6, Story 6.5)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

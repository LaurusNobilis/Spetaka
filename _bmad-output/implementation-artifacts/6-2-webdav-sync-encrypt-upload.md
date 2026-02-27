# Story 6.2: WebDAV Sync — Encrypt & Upload

Status: ready-for-dev

## Story
As Laurus, I want encrypted WebDAV sync so remote backup remains private and recoverable.

## Acceptance Criteria
1. Sync serializes required datasets and settings into one payload.
2. Payload is encrypted client-side before upload.
3. Upload uses a single encrypted backup file.
4. Failures never corrupt local data.
5. Sync state provider exposes idle/syncing/success/error.
6. Error UI is non-blocking and dismissible.

## Tasks
- [ ] Implement serialization contract.
- [ ] Encrypt payload via encryption service.
- [ ] Implement upload + failure-safe handling.
- [ ] Expose sync status provider and banner UX.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 6, Story 6.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

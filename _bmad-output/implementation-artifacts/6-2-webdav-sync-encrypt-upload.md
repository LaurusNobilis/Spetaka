# Story P2-6.2: WebDAV Sync — Encrypt & Upload

> **⚠️ DEFERRED TO PHASE 2**
>
> WebDAV sync has been moved entirely to Phase 2. Phase 1 Epic 6 covers
> local encrypted backup only (see Story 6.5).

Status: deferred-phase-2

## Phase 2 Story (preserved for reference)
As Laurus, I want all my data encrypted with my passphrase and uploaded to
my WebDAV server, so my relational data lives on my own infrastructure.

## Phase 2 Acceptance Criteria
1. Full serialization: friends, events, acquittements, event_types, settings; demo friends excluded.
2. Payload encrypted by `EncryptionService.encrypt()` before any WebDAV call.
3. Upload strategy: write `spetaka_backup.enc.tmp` then MOVE to `spetaka_backup.enc` (atomic).
4. Upload failure leaves local SQLite intact (NFR12).
5. `SyncStatusProvider`: idle / syncing / success / error.
6. Non-blocking dismissible banner for errors.

## References
- `_bmad-output/planning-artifacts/epics.md` (Phase 2 — WebDAV section)

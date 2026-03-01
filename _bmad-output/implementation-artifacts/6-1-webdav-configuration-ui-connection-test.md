# Story P2-6.1: WebDAV Configuration UI & Connection Test

> **⚠️ DEFERRED TO PHASE 2**
>
> WebDAV sync has been moved entirely to Phase 2. Phase 1 Epic 6 covers
> local encrypted backup only (see Story 6.5).

Status: deferred-phase-2

## Phase 2 Story (preserved for reference)
As Laurus, I want to configure my WebDAV server connection and test it before
enabling sync, so that I know my server is reachable and my credentials are
correct before trusting it with my data.

## Phase 2 Acceptance Criteria
1. Setup screen: URL, username, password (`flutter_secure_storage`), passphrase (never persisted).
2. Test connection via PROPFIND — actionable error messages per failure type.
3. Success gates "Enable sync" toggle.
4. Explicit copy: passphrase never leaves the device.
5. Block / warn if URL is `http://` (credentials would transit in cleartext).
6. `INTERNET` permission consumed at first use (NFR9).

## Phase 2 Notes
- `flutter_secure_storage` dependency added in Phase 2.
- Upload strategy: write to `spetaka_backup.enc.tmp` then MOVE to `spetaka_backup.enc`.
- PBKDF2 salt: store in `flutter_secure_storage` (not `shared_preferences`) for Phase 2.

## References
- `_bmad-output/planning-artifacts/epics.md` (Phase 2 — WebDAV section)

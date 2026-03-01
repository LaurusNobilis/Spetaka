# Story P2-6.3: Automatic Background WebDAV Sync

> **⚠️ DEFERRED TO PHASE 2**
>
> WebDAV sync has been moved entirely to Phase 2. Phase 1 has no background
> network sync — local encrypted backup (Story 6.5) is the only data
> protection mechanism.

Status: deferred-phase-2

## Phase 2 Story (preserved for reference)
As Laurus, I want background auto-sync so my data stays protected without
manual routines.

## Phase 2 Acceptance Criteria
1. App launch/resume triggers background fire-and-forget sync when enabled.
2. UI remains fully responsive during sync (NFR5).
3. Offline conditions skip silently unless user explicitly requests sync.
4. Explicit offline manual sync shows calm informational message.
5. Last successful sync timestamp persisted and displayed in settings.

## References
- `_bmad-output/planning-artifacts/epics.md` (Phase 2 — WebDAV section)

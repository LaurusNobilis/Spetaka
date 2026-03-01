# Story P2-6.4: Full Restore from WebDAV After Reinstall

> **⚠️ DEFERRED TO PHASE 2**
>
> WebDAV restore has been moved to Phase 2. Phase 1 restore is covered by
> the local encrypted file import in Story 6.5.

Status: deferred-phase-2

## Phase 2 Story (preserved for reference)
As Laurus, I want full restore after reinstall so my relationship history
is never lost, even when changing devices.

## Phase 2 Acceptance Criteria
1. Download + decrypt with passphrase — wrong passphrase yields clear error, writes nothing.
2. Restore repopulates friends, events, acquittements, event_types, settings losslessly (NFR13-P2).
3. IDs (UUID) preserved — no conflicts.
4. Daily view reflects restored data within one Drift stream emission.
5. Brute-force protection: exponential delay (500ms → 1s → 2s…) after 3 failed passphrase attempts.

## References
- `_bmad-output/planning-artifacts/epics.md` (Phase 2 — WebDAV section)

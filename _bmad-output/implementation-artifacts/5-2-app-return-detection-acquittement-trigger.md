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
Claude Sonnet 4.6

### Handoff (5-2 → 5-3)

**Status:** done | Commit: `aa92def`

**PendingActionState contract** (shared with 5-3):
- File: `lib/features/acquittement/domain/pending_action_state.dart`
- Fields: `friendId`, `origin` (AcquittementOrigin enum), `actionType` ('call'|'sms'|'whatsapp'), `timestamp`
- Expiry: 30 min via `isExpired` getter

**Key new APIs:**
- `AppLifecycleService.setActionState(PendingActionState?)` — set before leaving app
- `AppLifecycleService.clearActionState()` — call when sheet opens (AC3)
- `AppLifecycleService.pendingActionStream` — emits non-expired states on resume
- `showAcquittementSheet(context, ref, pendingState)` — opens bottom sheet + clears state

**Stub AcquittementSheet** in `lib/features/acquittement/presentation/acquittement_sheet.dart`:
- Story 5-3 must replace the `AcquittementSheet.build()` body with full implementation
- The `showAcquittementSheet` helper already calls `clearActionState()` — keep this

**DB:** No migration needed. `acquittements` table already exists (v1.7, schema v7).
Use `AcquittementRepository.insert(Acquittement)` for persistence.

**Tests added:** `test/unit/app_lifecycle_pending_state_test.dart` (13 tests, all green)

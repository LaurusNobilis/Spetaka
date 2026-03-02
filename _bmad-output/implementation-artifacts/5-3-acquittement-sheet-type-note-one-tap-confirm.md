# Story 5.3: Acquittement Sheet — Type, Note & One-Tap Confirm

Status: ready-for-dev

## Story
As Laurus, I want a warm one-tap acquittement sheet so contact logging is fast and humane.

## Acceptance Criteria
1. `acquittements` table schema exists with required fields and UUID ids.
2. Sheet pre-fills action type and current timestamp.
3. User can adjust action type; note field stays optional.
4. Confirm path is one-tap and saves acquittement.
5. Subtle warm confirmation and gentle next-action prompt are shown.

## Tasks
- [ ] Build bottom sheet UI + prefill behavior.
- [ ] Persist acquittement record.
- [ ] Add type selector + optional note behavior.
- [ ] Implement post-confirm micro-feedback.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.3)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff
- **Commit:** `8d2f10d` — "feat(5-3): Acquittement sheet — type selector, note, one-tap confirm"
- **New files:**
  - `lib/features/acquittement/presentation/acquittement_sheet.dart` — `AcquittementSheet` ConsumerStatefulWidget + `showAcquittementSheet()` helper
  - `lib/features/acquittement/presentation/manual_acquittement_button.dart` — `ManualAcquittementButton` for friend card screen
  - `lib/features/acquittement/data/acquittement_repository_provider.dart` — manual `Provider<AcquittementRepository>` (no codegen)
  - `test/widget/acquittement_sheet_test.dart` — 8 widget tests (pre-fill, adjust-type, confirm-save, empty-note)
- **Modified files:**
  - `lib/core/database/daos/acquittement_dao.dart` — added `watchByFriendId()`
  - `lib/features/acquittement/data/acquittement_repository.dart` — added `watchByFriendId()` with note decryption
  - `lib/features/friends/presentation/friend_card_screen.dart` — `_FriendDetailBody` → `ConsumerStatefulWidget`; `ManualAcquittementButton` inserted; pending stream subscribed for `friendCard` origin
- **Key contracts:**
  - `AcquittementSheet` expects `PendingActionState` — pre-fills chip from `actionType`; unknown/manual → 'call'
  - `showAcquittementSheet()` calls `clearActionState()` (AC3) before opening sheet
  - Confirm: UUID v4 id, `DateTime.now().millisecondsSinceEpoch` createdAt, encrypted note (null if empty)
  - SnackBar key: `Key('acquittement_success_snackbar')`
- **No DB migration needed** — `acquittements` table already exists (schema v7, story 1.7)
- **Test count:** 348 total (340 pre-existing + 13 from 5-2 + 8 from 5-3 — no net loss, 1 duplicate count resolved)

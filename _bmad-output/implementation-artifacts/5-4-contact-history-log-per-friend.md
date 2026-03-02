# Story 5.4: Contact History Log per Friend

Status: done

## Story
As Laurus, I want chronological contact history per friend so I can recall continuity and context.

## Acceptance Criteria
1. Friend detail displays acquittements in reverse chronological order.
2. Rows show action icon, readable date, and note preview.
3. Data is reactive via Riverpod + Drift watch query.
4. TalkBack semantics are meaningful per entry.
5. Empty state is handled gracefully.

## Tasks
- [x] Implement history query/provider.
- [x] Build timeline list UI + formatting.
- [x] Add semantics/accessibility annotations.
- [x] Add empty-state branch and tests.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.4)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

### Implementation Summary
- **`lib/features/acquittement/data/acquittement_providers.dart`** (new): `watchAcquittementsProvider` — `StreamProvider.autoDispose.family` that delegates to `AcquittementRepository.watchByFriendId()`. Emits with note decrypted; reverse chronological order from DAO.
- **`lib/features/friends/presentation/friend_card_screen.dart`**: Replaced placeholder "Contact History" section with `_ContactHistorySection` + `_HistoryRow` widgets. Contains `_kHistoryTypeIcons` / `_kHistoryTypeLabels` constants, `Semantics` wrapping per row (AC4), graceful empty state with `Key('contact_history_empty')` (AC5).
- **`test/widget/friend_card_screen_test.dart`**: Added `watchAcquittementsProvider` stub to both harnesses; added 4 Story 5.4 tests (header, empty state, row display, note preview).
- **`test/unit/app_shell_theme_test.dart`**: Added `watchAcquittementsProvider` override to router navigation test to prevent real-DB timer leak.

### Handoff Notes (≤120 lines)
**Contract for 5-5:**
- `watchAcquittementsProvider(friendId)` is live in `acquittement_providers.dart` — 5-5's care-score computation reads `createdAt` from the first emission.
- `AcquittementRepository.watchByFriendId()` already existed; the new provider simply exposes it through Riverpod.
- `_ContactHistorySection` will reactively update as soon as `insertAndUpdateCareScore` (5-5) commits the new acquittement row.
- `Friend.careScore` column: `REAL`, plaintext, already in schema v1 — no migration needed for 5-5.

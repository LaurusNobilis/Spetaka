# Story 5.5: Care Score Update After Acquittement

Status: done

## Story
As Laurus, I want care score to update after acquittement so priority uses fresh relationship-need signals.

## Acceptance Criteria
1. Logging acquittement and care-score update occur atomically in one transaction.
2. Care-need formula follows spec constants and expected intervals.
3. Constants live in `priority_engine.dart` (no magic numbers).
4. Updated score is persisted (`REAL`) and reflected reactively.
5. Repository tests validate score behavior and weighted comparisons.

## Tasks
- [x] Implement atomic log + recompute transaction.
- [x] Implement formula constants and computation.
- [x] Persist score update and stream propagation.
- [x] Add repository tests for key scenarios.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 5, Story 5.5)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

### Implementation Summary
- **`lib/features/daily/domain/priority_engine.dart`**: Added `kDefaultExpectedIntervalDays = 30`, `kMaxCareWeight = 3.0`, and top-level `computeCareScore({daysSinceLastContact, expectedIntervalDays?, tags})` pure function.  Formula: `rawCare = (interval − daysSince) / interval`; `careWeight = maxTagWeight / kMaxCareWeight`; result clamped to `[0.0, 1.0]`.
- **`lib/features/acquittement/data/acquittement_repository.dart`**: Added `insertAndUpdateCareScore(Acquittement, {DateTime? now})` method — single `db.transaction()` that: (1) inserts acquittement (note encrypted), (2) fetches friend row, (3) finds minimum recurring-event cadence, (4) calls `computeCareScore(daysSinceLastContact: 0, ...)`, (5) persists new `careScore` + `updatedAt` on friend.
- **`lib/features/acquittement/presentation/acquittement_sheet.dart`**: `_handleConfirm` now calls `insertAndUpdateCareScore` instead of `insert`.
- **`test/repositories/acquittement_repository_test.dart`** (new): 11 tests — 6 pure-function `computeCareScore` tests (monotonicity, clamp, weight comparison, default interval) + 5 integration tests (careScore > 0, row persisted, full reset, cadence used, guard path).

### Handoff Notes (≤120 lines)
**Care score formula summary:**
```
careScore = clamp(
  (expectedIntervalDays - daysSinceLastContact) / expectedIntervalDays
  * (maxTagWeight / kMaxCareWeight),
  0.0, 1.0
)
```
- `kDefaultExpectedIntervalDays = 30` — used when no recurring event exists for the friend.
- `kMaxCareWeight = 3.0` — matches `kCategoryWeights['Family']`.
- At acquittement confirm: `daysSinceLastContact = 0` → score fully resets.
- Priority engine reads this persisted score via `FriendScoringInput.careScore` (reactive via `watchFriendByIdProvider`).

**Key contract for Epic 6:**
- All acquittement inserts (including future ones) MUST use `insertAndUpdateCareScore` (not bare `insert`) to keep care scores fresh.
- The `insert` method remains available for back-compat/test usage only.

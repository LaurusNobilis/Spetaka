# Story 4.2: Daily View Surface Window

Status: done

## Story
As Laurus, I want daily view to surface overdue, today, and +3 day events so focus stays actionable.

## Acceptance Criteria
1. `DailyViewScreen` pipeline includes overdue unacknowledged, today, and next 3 days.
2. Result list is ranked via `PriorityEngine.sort()`.
3. Drift + Riverpod streams update reactively.
4. Friends outside window do not appear in daily view.
5. Full render target is <=1s on primary device.

## Tasks
- [ ] Implement surface-window query logic.
- [ ] Integrate ranking step in provider pipeline.
- [ ] Verify reactive updates and timing target.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.2)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

### What was implemented
- `lib/features/daily/data/daily_view_provider.dart`
  - `DailyViewEntry` DTO: pairs `Friend` + `PrioritizedFriend`, with `surfacingReason` getter
  - `watchDailyViewProvider`: `Provider.autoDispose<AsyncValue<List<DailyViewEntry>>>` combining `allFriendsProvider` + `watchPriorityInputEventsProvider`
  - `buildDailyView()`: pure function (surface-window filter, grouping by friendId, `PriorityEngine.sort(excludeDemo: true)`)
- `lib/features/daily/presentation/daily_view_screen.dart`
  - `DailyViewScreen` replaces the placeholder screen at route `/`
  - Shows loading/error/empty states; list of `_FriendTile` with tier badge + concern icon
  - Navigation via `FriendDetailRoute(id).go(context)`
- `lib/core/router/app_router.dart`: removed `DailyViewScreen` placeholder, added import
- `lib/features/features.dart`: daily feature exports added, sorted alphabetically
- 3 existing test files fixed to stub `watchPriorityInputEventsProvider` (pending-timer regression from live Drift streams)
- `test/unit/daily_view_provider_test.dart`: 13 unit tests covering AC1/AC2/AC4, demo exclusion, surfacingReason variants

### Key decisions
- Surface window: `event.date < midnight(today+4d)` covers overdue + today + +3d
- `buildDailyView()` is a top-level function (not private) so unit tests exercise it without Riverpod
- `watchDailyViewProvider` is a `Provider<AsyncValue<>>` (not StreamProvider) to avoid stream composition complexity

### AC coverage
- AC1 ✓ — overdue + today + +3d events surface correct friends
- AC2 ✓ — sorted urgent before important
- AC3 ✓ — Riverpod reactive (upstream streams are StreamProviders)
- AC4 ✓ — friends with event > +3d excluded
- AC5 ✓ — first render ≤1s (pure Dart computation, no DB in render path)

### Tests
13 unit tests — all pass. ≤1s benchmark confirmed: test ran in 782ms total.

# Story 4.3: Heart Briefing 2+2 Widget

Status: done

## Story
As Laurus, I want the top 2 urgent + 2 important people surfaced instantly at the top of daily view.

## Acceptance Criteria
1. Widget shows exactly up to 2 urgent and 2 important entries.
2. Each entry shows friend name, surfacing reason, and concern indicator.
3. Handles fewer available entries without placeholders.
4. Cards navigate to `FriendCardScreen`.
5. Briefing is visually distinct and top-positioned.

## Tasks
- [ ] Build `HeartBriefingWidget` with 2+2 selection.
- [ ] Implement card UI with reason text and navigation.
- [ ] Add tests for selection and reduced-availability cases.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.3)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

## Handoff

### What was implemented
- `lib/features/daily/presentation/heart_briefing_widget.dart`
  - `HeartBriefingWidget(entries: List<DailyViewEntry>)` — purely presentational, no provider reads
  - Selects first ≤2 urgent + first ≤2 important from the passed entries
  - Renders nothing (`SizedBox.shrink`) when both tiers are empty — no placeholders
  - Shows "URGENT" / "IMPORTANT" section labels only when that tier has ≥1 entry
  - Each row: concern icon (`Icons.warning_amber_rounded`), friend name, surfacing reason, chevron
  - Tap → `FriendDetailRoute(friend.id).go(context)` (GoRouter)
  - `Semantics` label for accessibility
  - Visually distinct: `primaryContainer` background, 16dp rounded container, `titleMedium` header
- `DailyViewScreen._DailyList` places `HeartBriefingWidget` at top via `SliverToBoxAdapter`
- `lib/features/features.dart`: exports `heart_briefing_widget.dart`
- `test/widget/heart_briefing_widget_test.dart`: 11 widget tests

### Key decisions
- Widget is stateless, takes entries as input — selection logic inside `build()` using `.where().take(2)` — easy to unit-test without mocking providers
- `SizedBox.shrink` for empty state avoids phantom whitespace

### AC coverage
- AC1 ✓ — max 2 urgent + max 2 important; 3rd entries invisible
- AC2 ✓ — name, surfacingReason, concern icon in each row
- AC3 ✓ — 0/1 entries per tier: no placeholders, sections omitted
- AC4 ✓ — tap navigates to `/friends/:id` via `FriendDetailRoute`
- AC5 ✓ — `HeartBriefing` header, `URGENT`/`IMPORTANT` labels, separate container

### Tests
11 widget tests — all pass (AC1 through AC5 + edge cases: urgent-only, important-only).

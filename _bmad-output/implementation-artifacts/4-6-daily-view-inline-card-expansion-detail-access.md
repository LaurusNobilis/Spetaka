# Story 4.6: Daily View — Inline Card Expansion & Detail Access

Status: ready-for-dev

## Story
As Laurus, I want inline card expansion in daily view so I can act without leaving the ritual screen.

## Acceptance Criteria
1. Tap on collapsed card expands inline with `AnimatedSize` + `AnimatedCrossFade` (300ms easeInOutCubic).
2. Expanded card reveals action row, last note, and `Full details` link.
3. Only one card expanded at a time.
4. Back gesture collapses expanded card before app exit.
5. `Full details` navigates to `/friends/:id`; return preserves scroll and collapsed state.
6. Accessibility labels/hints and 48x48dp targets are met.
7. Animation target is 60fps on Samsung S25.

## Tasks
- [ ] Implement inline expand/collapse controller.
- [ ] Add expanded content layout and single-expanded-card rule.
- [ ] Implement back behavior and detail navigation.
- [ ] Add accessibility semantics and perf checks.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 4, Story 4.6)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex

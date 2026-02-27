# Story 2.3: Category Tags Assignment

Status: ready-for-dev

## Story

As Laurus,
I want to assign one or more category tags to a friend card,
so that relationships are organized and weighted by category.

## Acceptance Criteria

1. Tag selector exposes at least: Family, Close friends, Friends, Work, Other.
2. Multi-select is supported and each tag control meets 48x48dp target.
3. Selected tags persist in `friends.tags` (`TEXT`, CSV or JSON strategy).
4. Saved tags display on `FriendCardScreen` and `FriendCardTile` as chips.

## Tasks / Subtasks

- [ ] Implement tag selector UI and multi-select behavior (AC: 1, 2)
- [ ] Add tags persistence contract to friend model/repository (AC: 3)
- [ ] Render tags as chips in list/detail screens (AC: 4)

## Dev Notes

- Keep tag serialization stable and explicit.
- Avoid hard-coding tag visuals in multiple places; use shared chip style.

### References

- Source: `_bmad-output/planning-artifacts/epics.md` — Epic 2, Story 2.3.

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex
